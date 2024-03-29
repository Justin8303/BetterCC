------------------------------------------------------------------ utils
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}
JSON = {} 

local function isArray(t)
    local max = 0
    for k,v in pairs(t) do
        if type(k) ~= "number" then
            return false
        elseif k > max then
            max = k
        end
    end
    return max == #t
end
 
local function removeWhite(str)
    local whites = {['\n']=true; ['\r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
    while whites[str:sub(1, 1)] do
        str = str:sub(2)
    end
    return str
end
 
------------------------------------------------------------------ encoding
 
local function encodeCommon(val, pretty, tabLevel, tTracking)
    local str = ""
 
    -- Tabbing util
    local function tab(s)
        str = str .. ("\t"):rep(tabLevel) .. s
    end
 
    local function arrEncoding(val, bracket, closeBracket, iterator, loopFunc)
        str = str .. bracket
        if pretty then
            str = str .. "\n"
            tabLevel = tabLevel + 1
        end
        for k,v in iterator(val) do
            tab("")
            loopFunc(k,v)
            str = str .. ","
            if pretty then str = str .. "\n" end
        end
        if pretty then
            tabLevel = tabLevel - 1
        end
        if str:sub(-2) == ",\n" then
            str = str:sub(1, -3) .. "\n"
        elseif str:sub(-1) == "," then
            str = str:sub(1, -2)
        end
        tab(closeBracket)
    end
 
    -- Table encoding
    if type(val) == "table" then
        assert(not tTracking[val], "Cannot encode a table holding itself recursively")
        tTracking[val] = true
        if isArray(val) then
            arrEncoding(val, "[", "]", ipairs, function(k,v)
                str = str .. encodeCommon(v, pretty, tabLevel, tTracking)
            end)
        else
            arrEncoding(val, "{", "}", pairs, function(k,v)
                assert(type(k) == "string", "JSON object keys must be strings", 2)
                str = str .. encodeCommon(k, pretty, tabLevel, tTracking)
                str = str .. (pretty and ": " or ":") .. encodeCommon(v, pretty, tabLevel, tTracking)
            end)
        end
    -- String encoding
    elseif type(val) == "string" then
        str = '"' .. val:gsub("[%c\"\\]", controls) .. '"'
    -- Number encoding
    elseif type(val) == "number" or type(val) == "boolean" then
        str = tostring(val)
    else
        error("JSON only supports arrays, objects, numbers, booleans, and strings", 2)
    end
    return str
end
 
local function encode(val)
    return encodeCommon(val, false, 0, {})
end
 
local function encodePretty(val)
    return encodeCommon(val, true, 0, {})
end
 
------------------------------------------------------------------ decoding
 
local decodeControls = {}
for k,v in pairs(controls) do
    decodeControls[v] = k
end
 
local function parseBoolean(str)
    if str:sub(1, 4) == "true" then
        return true, removeWhite(str:sub(5))
    else
        return false, removeWhite(str:sub(6))
    end
end
 
local function parseNull(str)
    return nil, removeWhite(str:sub(5))
end
 
local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
local function parseNumber(str)
    local i = 1
    while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
        i = i + 1
    end
    local val = tonumber(str:sub(1, i - 1))
    str = removeWhite(str:sub(i))
    return val, str
end
 
local function parseString(str)
    str = str:sub(2)
    local s = ""
    while str:sub(1,1) ~= "\"" do
        local next = str:sub(1,1)
        str = str:sub(2)
        assert(next ~= "\n", "Unclosed string")
 
        if next == "\\" then
            local escape = str:sub(1,1)
            str = str:sub(2)
 
            next = assert(decodeControls[next..escape], "Invalid escape character")
        end
 
        s = s .. next
    end
    return s, removeWhite(str:sub(2))
end
 
local function parseArray(str)
    str = removeWhite(str:sub(2))
 
    local val = {}
    local i = 1
    while str:sub(1, 1) ~= "]" do
        local v = nil
        v, str = JSON.parseValue(str)
        val[i] = v
        i = i + 1
        str = removeWhite(str)
    end
    str = removeWhite(str:sub(2))
    return val, str
end
 
local function parseObject(str)
    str = removeWhite(str:sub(2))
    local val = {}
    while str:sub(1, 1) ~= "}" do
        local k, v = nil, nil
        k, v, str = JSON.parseMember(str)
        val[k] = v
        str = removeWhite(str)
    end
    str = removeWhite(str:sub(2))
    return val, str
end
 
local function parseMember(str)
    local k = nil
    k, str = JSON.parseValue(str)
    local val = nil
    val, str = JSON.parseValue(str)
    return k, val, str
end
 
local function parseValue(str)
    local fchar = str:sub(1, 1)
    if fchar == "{" then
        return JSON.parseObject(str)
    elseif fchar == "[" then
        return JSON.parseArray(str)
    elseif tonumber(fchar) ~= nil or numChars[fchar] then
        return JSON.parseNumber(str)
    elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
        return JSON.parseBoolean(str)
    elseif fchar == "\"" then
        return JSON.parseString(str)
    elseif str:sub(1, 4) == "null" then
        return JSON.parseNull(str)
    end
    return nil
end
 
local function decode(str)
    str = removeWhite(str)
    t = JSON.parseValue(str)
    return t
end
 
local function decodeFromFile(path)
    local file = assert(fs.open(path, "r"))
    local decoded = JSON.decode(file.readAll())
    file.close()
    return decoded
end

JSON.encode = encode
JSON.encodePretty = encodePretty
JSON.parseBoolean = parseBoolean
JSON.parseNull = parseNull
JSON.parseNumber = parseNumber
JSON.parseString = parseString
JSON.parseArray = parseArray
JSON.parseObject = parseObject
JSON.parseMember = parseMember
JSON.parseValue = parseValue
JSON.decode = decode
JSON.decodeFromFile = decodeFromFile

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

args = {...}
content = nil
packages = {}
running = false

loaded = {}
cache = {}
repos = {
    "https://raw.githubusercontent.com/Justin8303/BetterCC/master/apt/list.json",
    "https://raw.githubusercontent.com/Justin8303/BetterCC/master/apt/system.json"
}

function table.getlength(t)
    c = 0
    for k,v in pairs(t) do c = c+1 end
    return c
end

function merge(t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

function get(url)
    if not cache[url] then
        content = http.get(url)
        cache[url] = content.readAll()
    end
    return cache[url]
end

function getData (url)
    if not running then
        write("Reading package lists... ")
    end
    if not content then
        content = http.get(url)
        content = content.readAll()
    end
    if not running then
        print("Done")
    end
    return content
end

function getTable (s, t)
    for i in s:gmatch("([^%.]+)") do
        if not t[i] then
            return false
        else
            t = t[i]
        end
    end
    return t
end

function getPackage(name)
    local data = getTable(name, getAllPackages())
    if not running then
        write("Building dependency tree... ")
        running = true
    end
    if data then
        if data.Directory then
            if not fs.exists(data.Directory) then
                packages[name] = data
            end
        else
            packages[name] = data
        end
        if type(data.Requirements) == "table" then
            for _,v in pairs(data.Requirements) do
                if not packages[v] then
                    if data.Directory then
                        if not fs.exists(data.Directory) then
                            getPackage(v)
                        end
                    else
                        getPackage(v)
                    end
                end
            end
        end
    end
end

function checkobj(obj)
    if obj.Url then return false end
    if obj.Source then return false end
    if obj.Date then return false end
    if obj.Requirements then return false end
    if obj.Docs then return false end
    if obj.Type then return false end
    if obj.Directory then return false end
    if obj.Compatibility then return false end
    return true
end

function getAllPackages()
    data = {}
    for k,v in pairs(repos) do
        data = merge(data,JSON.decode(get(v)))
    end
    return data
end

if table.getn(args) < 1 then
    error("show help!")
end

command = args[1]
if command == "get" then
    if args[2] == "install" then
        local dependencies = {}
        local incompatible = {}

        getPackage(args[3])
        running = false
        print("Done")
        if table.getlength(packages) == 0 then
            print("This package is empty or already exists...")
            print("Aborting")
            return
        end
        print("The following NEW packages will be installed")
        for k,v in pairs(packages) do
            if v.Compatibility then
                if not loadstring(v.Compatibility)() then
                    term.setTextColor(colors.red)
                    print(k.." ("..v.Type..")")
                    table.insert(incompatible, v)
                else
                    term.setTextColor(colors.lime)
                    print(k.." ("..v.Type..")")
                end
            end
            term.setTextColor(colors.lime)
            print(k.." ("..v.Type..")")
        end
        term.setTextColor(colors.white)
        print("0 upgraded, "..table.getlength(packages).." installed, "..table.getlength(incompatible).." incompatible")
        print("Would you like to continue [y/n] ?")
        c = read()
        if c == "y" then
            c = 1
            for k,v in pairs(packages) do
                if v.Url then
                    print("GET:"..c.." "..v.Url)
                    file = fs.open(v.Directory, "w")
                    file.write(get(v.Url))
                    file.close()
                    c = c + 1
                end
            end
            print("Done")
        else
            print("Aborted")
        end
    elseif args[2] == "list" then
        print("The following packages are found")
        local tb = getAllPackages()
        str = ""
        local function reloop(t, s)
            for k,v in pairs(t) do
                if type(v) == "table" and checkobj(v) then
                    if s == "" then
                        reloop(v, k)
                    else
                        reloop(v, s.."."..k)
                    end
                else
                    print("    "..s.."."..k)
                end
            end
            return true
        end
        reloop(tb, str)
    end
elseif command == "docs" then
    local data = getTable(args[2], getAllPackages())
    print("Docs for "..args[2])
    print(data.Docs)
elseif command == "info" then
    local data = getTable(args[2], getAllPackages())
    print("Info for "..args[2])
    for k,v in pairs(data) do
        if k == "Compatibility" then
            v = loadstring(v)
        end
        if k ~= "Requirements" and type(v) ~= "function" then
            print("    "..k..":",v)
        end
        if k == "Requirements" and type(v) ~= "functions" then
            print("    "..k..":")
            for k,v in pairs(v) do
                print("      "..v)
            end
        end
        if type(v) == "function" then
            if v() then
                print("    Compatible:","true")
            else
                print("    Compatible:","false")
            end
        end
    end
end

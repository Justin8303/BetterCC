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

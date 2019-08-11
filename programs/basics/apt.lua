args = {...}
content = nil
packages = {}
running = false

repo = "https://raw.githubusercontent.com/Justin8303/BetterCC/master/apt/list.json"

function get(url)
    content = http.get(url)
    return content.readAll()
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
    local data = getTable(name, JSON.decode(getData(repo)))
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
        if data.Requirements ~= "" then
            for _,v in pairs(data.Requirements) do
                if not packages[v] then
                    getPackage(v)
                end
            end
        end
    end
end

if table.getn(args) < 1 then
    error("show help!")
end

command = args[1]
if command == "get" then
    if args[2] == "install" then
        local dependencies = {}

        getPackage(args[3])
        running = false
        print("Done")
        print("The following NEW packages will be installed")
        c = 0
        for k,v in pairs(packages) do
            print("    "..k.." ("..v.Type..")")
            c = c + 1
        end
        print("0 upgraded, "..c.." installed")
        print("Would you like to continue [y/n] ?")
        c = read()
        if c == "y" then
            c = 1
            for k,v in pairs(packages) do
                if v.Url ~= "none" then
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
    end
end

local getFile = function ( url )
    return http.get(url).readAll()
end

local runFile = function ( url )
    dohttp.get(url)
end

local nversion = tonumber(getFile("https://raw.githubusercontent.com/Justin8303/BetterCC/master/VERSION"))
local cversion = settings.get("BetterCCVersion")

if nversion > cversion then
    print("Found new version for BetterCC ["..nversion.."], installing!")
    l = {}
    for i in tostring(nversion):gmatch("%d+") do table.insert(l,i) end
    local file = getFile("https://raw.githubusercontent.com/Justin8303/BetterCC/master/updates/"..l[1].."/"..l[2].."/Update.lua")
    local gfile, err = loadstring(file, "update["..nversion.."]", "t", _ENV)
    if not gfile then
        error(err, 0)
    end

    local s, m = pcall(gfile)
    if not s then
        error(m, 0)
    end
end

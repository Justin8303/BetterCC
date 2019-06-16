local tSettings = {}
settings = {}

settings.set = function( sName, value )
    if type(sName) ~= "string" or
       (type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" and type(value) ~= "table") then
        error( "Expected string, value", 2 )
    end
    if type(value) == "table" then
        -- Ensure value is serializeable
        value = textutils.unserialize( textutils.serialize(value) )
    end
    tSettings[ sName ] = value
end

settings.copy = function( value )
    if type(value) == "table" then
        local result = {}
        for k,v in pairs(value) do
            result[k] = settings.copy(v)
        end
        return result
    else
        return value
    end
end

settings.get = function( sName, default )
    if type(sName) ~= "string" then
        error( "Expected string", 2 )
    end
    local result = tSettings[ sName ]
    if result ~= nil then
        return settings.copy(result)
    else
        return default
    end
end

settings.unset = function( sName )
    if type(sName) ~= "string" then
        error( "Expected string", 2 )
    end
    tSettings[ sName ] = nil
end

settings.clear = function()
    tSettings = {}
end

settings.getNames = function()
    local result = {}
    for k,v in pairs( tSettings ) do
        result[ #result + 1 ] = k
    end
    return result
end

settings.load = function( sPath )
    if type(sPath) ~= "string" then
        error( "Expected string", 2 )
    end
    local file = fs.open( sPath, "r" )
    if not file then
        return false
    end

    local sText = file.readAll()
    file.close()

    local tFile = textutils.unserialize( sText )
    if type(tFile) ~= "table" then
        return false
    end

    for k,v in pairs(tFile) do
        if type(k) == "string" and
           (type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "table") then
            settings.set( k, v )
        end
    end

    return true
end

settings.save = function( sPath )
    if type(sPath) ~= "string" then
        error( "Expected string", 2 )
    end
    local file = fs.open( sPath, "w" )
    if not file then
        return false
    end

    file.write( textutils.serialize( tSettings ) )
    file.close()

    return true
end

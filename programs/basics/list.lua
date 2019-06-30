local tArgs = { ... }
local lall = false

-- Get all the files in the directory
local sDir = shell.dir()
if tArgs[1] ~= nil then
	if tArgs[1]:find("%-") then
		if tArgs[1] == "-a" then
			lall = true
		end
	else
		sDir = shell.resolve( tArgs[1] )
	end
end

-- Sort into dirs/files, and calculate column count
local tAll = fs.list( sDir )
local tFiles = {}

local tLuaFiles = {}
local startup = {}
local tDirslocked = {}

local tDirs = {}

local bShowHidden = settings.get( "list.show_hidden" )
for n, sItem in pairs( tAll ) do
	if bShowHidden or string.sub( sItem, 1, 1 ) ~= "." then
		local sPath = fs.combine( sDir, sItem )
		if fs.isDir( sPath ) then
			if sItem == "rom" or sItem == settings.get( "rootDir" ) then
				table.insert( tDirslocked, sItem )
			else
				table.insert( tDirs, sItem )
			end
		else
			if sItem:match("%.%blua$") then
				if not lall then
					table.insert( tLuaFiles, sItem:sub(1,#sItem-4) )
				else
					table.insert( tLuaFiles, sItem)
				end
			elseif sItem == "startup" then
				if fs.exists("startup") then
					table.insert( startup, sItem )
				end
			else
				table.insert( tFiles, sItem )
			end
		end
	end
end
table.sort( tDirs )
table.sort( tFiles )
table.sort( tLuaFiles )

if term.isColour() then
	textutils.pagedTabulate(
		colors.red,
		tDirslocked,

		colors.blue,
		tDirs,

		colors.lightGray,
		tFiles, 

		colors.green,
		tLuaFiles,

		colors.orange,
		startup
	)
else
	textutils.pagedTabulate(tDirslocked, tDirs, tFiles, tLuaFiles , startup)
end

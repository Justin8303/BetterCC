file = fs.open("/root/config/shortcuts.dat","r")
shortcuts = textutils.unserialize(file.readLine())
file.close()

function control(...)
	input = {...}
	input = unpack(input)
	for k,v in pairs(input) do
		if shortcuts[v] then
			input[k] = shortcuts[v]
		end
	end
	return input
end

beforefsopen = fs.open
fs.open = function(...)
	return beforefsopen(unpack(control({...})))
end

beforefslist = fs.list
fs.list = function(...)
	return beforefslist(unpack(control({...})))
end

beforefsexists = fs.exists
fs.exists = function(...)
	return beforefsexists(unpack(control({...})))
end

beforefsisDir = fs.isDir
fs.isDir = function(...)
	return beforefsisDir(unpack(control({...})))
end

beforefsisReadOnly = fs.isReadOnly
fs.isReadOnly = function(...)
	input = {...}
	if input[1]:match("^%b/"..settings.get( "rootDir" )) then	--set root directory to readonly
		return true
	end
	return beforefsisReadOnly(unpack(control({...})))
end

beforegetName = fs.getName
fs.getName = function(...)
	return beforegetName(unpack(control({...})))
end

beforefsgetSize = fs.getSize
fs.getSize = function(...)
	return beforefsgetSize(unpack(control({...})))
end

beforefsgetFreeSpace = fs.getFreeSpace
fs.getFreeSpace = function(...)
	return beforefsgetFreeSpace(unpack(control({...})))
end

beforefsmakeDir = fs.makeDir
fs.makeDir = function(...)
	return beforefsmakeDir(unpack(control({...})))
end

beforefsmove = fs.move
fs.move = function(...)
	return beforefsmove(unpack(control({...})))
end

beforefscopy = fs.copy
fs.copy = function(...)
	return beforefscopy(unpack(control({...})))
end

beforefsdelete = fs.delete
fs.delete = function(...)
	return beforefsdelete(unpack(control({...})))
end

beforefscombine = fs.combine
fs.combine = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	if shortcuts[input[2]] then
		input[2] = shortcuts[input[2]]
	end
	return beforefscombine(unpack(control({...})))
end

beforeloadfile = loadfile
loadfile = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforeloadfile(unpack(control({...})))
end

-- overwrite file system manager
shell.setAlias("list","/root/programs/basics/list.lua")

shell.clearAlias("ls")
shell.setAlias("ls","/root/programs/basics/list.lua")

shell.clearAlias("dir")
shell.setAlias("dir","/root/programs/basics/list.lua")

-- auto added commands


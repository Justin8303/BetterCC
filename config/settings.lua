file = fs.open("/root/config/shortcuts.dat","r")
shortcuts = textutils.unserialize(file.readLine())
file.close()

beforefsopen = fs.open
fs.open = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsopen(unpack(input))
end

beforefslist = fs.list
fs.list = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefslist(unpack(input))
end

beforefsexists = fs.exists
fs.exists = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsexists(unpack(input))
end

beforefsisDir = fs.isDir
fs.isDir = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsisDir(unpack(input))
end

beforefsisReadOnly = fs.isReadOnly
fs.isReadOnly = function(...)
	input = {...}
	if input[1]:match("^%b/"..settings.get( "rootDir" )) then	--set root directory to readonly
		return true
	end
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsisReadOnly(unpack(input))
end

beforegetName = fs.getName
fs.getName = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforegetName(unpack(input))
end

beforefsgetSize = fs.getSize
fs.getSize = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsgetSize(unpack(input))
end

beforefsgetFreeSpace = fs.getFreeSpace
fs.getFreeSpace = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsgetFreeSpace(unpack(input))
end

beforefsmakeDir = fs.makeDir
fs.makeDir = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsmakeDir(unpack(input))
end

beforefsmove = fs.move
fs.move = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	if shortcuts[input[2]] then
		input[2] = shortcuts[input[2]]
	end
	return beforefsmove(unpack(input))
end

beforefscopy = fs.copy
fs.copy = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	if shortcuts[input[2]] then
		input[2] = shortcuts[input[2]]
	end
	return beforefscopy(unpack(input))
end

beforefsdelete = fs.delete
fs.delete = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforefsdelete(unpack(input))
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
	return beforefscombine(unpack(input))
end

beforeloadfile = loadfile
loadfile = function(...)
	input = {...}
	if shortcuts[input[1]] then
		input[1] = shortcuts[input[1]]
	end
	return beforeloadfile(unpack(input))
end

-- overwrite file system manager
shell.setAlias("list","/root/programs/basics/list.lua")

shell.clearAlias("ls")
shell.setAlias("ls","/root/programs/basics/list.lua")

shell.clearAlias("dir")
shell.setAlias("dir","/root/programs/basics/list.lua")

-- auto added commands


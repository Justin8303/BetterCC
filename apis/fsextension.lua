local function listAll(_path, _files)
	local path = _path or ""
	local files = _files or {}
	if #path > 1 then table.insert(files, path) end
		for _, file in ipairs(fs.list(path)) do
		local path = fs.combine(path, file)
		if fs.isDir(path) then
			listAll(path, files)
		else
			table.insert(files, path)
		end
	end
	return files
end

fs.find = function(pattern)
	files = listAll()
	if not wildcard then
		error("wildcard extension is not installed!")
	else
		output = {}
		for k,v in pairs(listAll()) do
			if v:match(wildcard.parse(pattern)) then
				table.insert(output,v)
			end
		end
		return output
	end
end

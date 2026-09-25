local downloadLink = 'https://raw.githubusercontent.com/aTimmYm/Quark/refs/heads/build/'
local link = 'https://raw.githubusercontent.com/aTimmYm/Quark/refs/heads/main/'

local absPath = ...

local function updateError(err, current_files, new_files)
	for i = 1, #new_files do fs.delete(absPath .. new_files[i]) end

	for path, data in pairs(current_files) do
		local fd, l_err = io.open(absPath .. path, 'w')
		if fd then
			fd:write(data); fd:close()
		end
	end

	return nil, err
end

local function update()
	local local_manifest, server_manifest = {}, {}
	for line in io.lines(absPath .. 'manifest') do
		local_manifest[line:sub(65)] = line:sub(1, 64)
	end

	local response, err = http.get(link .. 'manifest')
	local server_manifest_sum
	if response then
		server_manifest_sum = response.readAll(); response.close()
	else
		return nil, err
	end
	for line in server_manifest_sum:gmatch('[^\n]+') do
		server_manifest[line:sub(65)] = line:sub(1, 64)
	end

	local delete, download = {}, {}
	for path, hash in pairs(local_manifest) do
		local server_hash = server_manifest[path]
		if not server_hash then
			delete[#delete + 1] = path
		end
	end
	for path, hash in pairs(server_manifest) do
		local local_hash = local_manifest[path]
		if local_hash ~= hash then
			download[#download + 1] = path
		end
	end

	local current_files, new_files = {}, {}
	for i = 1, #download do
		local path = download[i]
		if fs.exists(absPath .. path) then
			local fd, err = io.open(absPath .. path, 'r')
			if fd then
				current_files[path] = fd:read('a'); fd:close()
			end
		else
			new_files[#new_files + 1] = path
		end

		local request, h_err = http.get(downloadLink .. path)
		if request then
			local fd, err = io.open(absPath .. path, 'w')
			if fd then
				local write_ok, write_err = pcall(fd.write, fd, request.readAll())
				fd:close()
				if not write_ok then
					return updateError(write_err, current_files, new_files)
				end
			else
				return updateError(err, current_files, new_files)
			end
		else
			return updateError(h_err, current_files, new_files)
		end
	end

    for i = 1, #delete do
        fs.delete(absPath .. delete[i])
    end

    local fd = io.open(absPath .. 'manifest', 'w')
    if fd then
		fd:write(server_manifest_sum); fd:close()
	end

	return true
end


return { update = update }

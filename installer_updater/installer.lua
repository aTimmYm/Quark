local link = 'https://raw.githubusercontent.com/aTimmYm/Quark/refs/heads/main/'
local downloadLink = 'https://raw.githubusercontent.com/aTimmYm/Quark/refs/heads/build/'

local path = ''

while true do
	print('Enter the path where you want to install Quark.')
	path = io.read()
	if path:lower() == 'exit' or path:lower() == 'e' then
		return
	elseif fs.exists(path) and fs.isDir(path) then
		path = path:sub(-1, -1) == '/' and path or path .. '/'; break
	else
		print('The specified path does not exist or is not a directory.')
	end
end

path = path .. 'Quark/'
local response, err = http.get(link .. 'manifest')
local server_manifest_sum
if response then
	server_manifest_sum = response.readAll(); response.close()
else
	return print(err)
end
for line in server_manifest_sum:gmatch('[^\n]+') do
    local download_path = line:sub(65)
    local request, h_err = http.get(downloadLink .. download_path)
    if request then
        local fd, err = io.open(path .. download_path, 'w')
        if fd then
            local write_ok, write_err = pcall(fd.write, fd, request.readAll())
            fd:close()
            if not write_ok then
                return print(write_err)
            end
        else
            return print(err)
        end
    else
        return print(h_err)
    end
end

local fd = io.open(path .. 'manifest')
if fd then
	fd:write(server_manifest_sum); fd:close()
end

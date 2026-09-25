local _document = {}

local function getLine(self, y)
	return self.lines[y]
end

local function setLine(self, y, line)
	self.isModified = true
	self.lines[y] = line
	if self.onChange then self:onChange() end
end

local function moveLines(self, f, e, t)
	self.isModified = true
	if self.onChange then self:onChange() end
	return table.move(self.lines, f, e, t)
end

local function insertLine(self, y, line)
	self.isModified = true
	if self.onChange then self:onChange() end
	return table.insert(self.lines, y, line)
end

local function deleteLine(self, y)
	self.isModified = true
	if self.onChange then self:onChange() end
	return table.remove(self.lines, y)
end

local function getLinesSize(self) --может временно
	return #self.lines
end

local function save(self)
	if not self.path then return nil, 'no_path' end
	local file, err = io.open(self.path, 'w')
	if not file then return nil, err end

	if self.endl_option == 'enforce_lf' then
		self.line_ending = '\n'
	elseif self.endl_option == 'enforce_crlf' then
		self.line_ending = '\r\n'
	end

	-- local lines_size = #self.lines
	-- for n = lines_size, 1, -1 do
	-- 	if not self.lines[n]:match('%S') then
	-- 		self.lines[n] = nil
	-- 	else
	-- 		break
	-- 	end
	-- end
	-- self.lines[#self.lines + 1] = ''

	file:write(table.concat(self.lines, self.line_ending))
	file:close()
	self.isModified = false
	if self.onChange then self:onChange() end
	return true
end

local function saveAs(self, path)
	self.path = path
	return self:save()
end

local function open(self)
	local data = {}
	local crlf, lf, i = 0, 0, 1
	for line in io.lines(self.path, 'L') do
		if line:find('\r\n', 1, true) then
			data[i] = line:sub(1, -3)
			crlf = crlf + 1
		elseif line:find('\n', 1, true) then
			data[i] = line:sub(1, -2)
			lf = lf + 1
		else
			data[i] = line
		end
		i = i + 1
	end
	data[i] = ''
	self.lines = data
	self.line_ending = crlf > lf and '\r\n' or '\n'
end

local function addUndo(self, instruction)
	self.undo_history[#self.undo_history + 1] = instruction
	self.redo_history = {}
end

local function undo(self)
	local total_undo = #self.undo_history
	if total_undo == 0 then
		self.isModified = false
		if self.onChange then self:onChange() end
		return
	end
	if self.onChange then self:onChange() end
	local instruction = table.remove(self.undo_history, total_undo)
	local redo_history = {}
	self.redo_history[#self.redo_history + 1] = redo_history
	for i = #instruction, 1, -1 do
		local command = instruction[i]
		local name_command = command.name
		local local_redo = {}
		redo_history[#redo_history + 1] = local_redo
		if name_command == 'deleteLine' then
			local_redo.name = 'insertLine'
			local_redo.y = command.y
			local_redo.data = self.lines[command.y]
		elseif name_command == 'insertLine' then
			local_redo.name = 'deleteLine'
			local_redo.y = command.y
		elseif name_command == 'moveLines' then
			local delta = command.t - command.f
			local_redo.name = name_command
			local_redo.f = command.f
			local_redo.e = command.e
			local_redo.t = command.t
			-- local_redo.f = command.t
			-- local_redo.e = command.e - command.f + command.t
			-- local_redo.t = command.f
			self[name_command](self, command.t, command.e + delta, command.f, command.data)
			goto continue
		else
			local_redo.name = 'setLine'
			local_redo.y = command.y
			local_redo.data = self.lines[command.y]
		end
		self[name_command](self, command.y, command.data)
		::continue::
	end
end

local function redo(self)
	local total_redo = #self.redo_history
	if total_redo == 0 then
		self.isModified = true
		if self.onChange then self:onChange() end
		return
	end
	if self.onChange then self:onChange() end
	local instruction = table.remove(self.redo_history, total_redo)
	local undo_history = {}
	self.undo_history[#self.undo_history + 1] = undo_history
	for i = #instruction, 1, -1 do
		local command = instruction[i]
		local name_command = command.name
		local local_undo = {}
		undo_history[#undo_history + 1] = local_undo
		if name_command == 'deleteLine' then
			local_undo.name = 'insertLine'
			local_undo.y = command.y
			local_undo.data = self.lines[command.y]
		elseif name_command == 'insertLine' then
			local_undo.name = 'deleteLine'
			local_undo.y = command.y
		elseif name_command == 'moveLines' then
			local_undo.name = name_command
			local_undo.f = command.t
			local_undo.e = command.e - command.f + command.t
			local_undo.t = command.f
			self[name_command](self, command.f, command.e, command.t, command.data)
			goto continue
		else
			local_undo.name = 'setLine'
			local_undo.y = command.y
			local_undo.data = self.lines[command.y]
		end
		self[name_command](self, command.y, command.data)
		::continue::
	end
end

local function setLineEnding(self, option_state)
	self.endl_option = option_state
end

function _document.new(path)
	local instance = {}

	instance.path = path
	instance.isModified = false
	instance.lines = { '' }
	instance.undo_history = {}
	instance.redo_history = {}
	instance.endl_option = 'detect'
	instance.line_ending = '\n'

	instance.getLine = getLine
	instance.setLine = setLine
	instance.insertLine = insertLine
	instance.deleteLine = deleteLine
	instance.moveLines = moveLines
	instance.getLinesSize = getLinesSize
	instance.open = open
	instance.save = save
	instance.saveAs = saveAs
	instance.undo = undo
	instance.addUndo = addUndo
	instance.redo = redo
	instance.setLineEnding = setLineEnding

	return instance
end

return _document

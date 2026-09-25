local UI = require 'Data.UI'

local function sortList(list, path, onlyDir)
	local dirs = {}
	local files = {}
	for i = 1, #list do
		local v = list[i]
		if vfs.isDir(path .. '/' .. v) then
			dirs[#dirs + 1] = v
		elseif not onlyDir then
			files[#files + 1] = v
		end
	end
	list = {}
	table.sort(dirs, function(a, b)
		return a:lower() < b:lower()
	end)
	for i = 1, #dirs do
		list[#list + 1] = dirs[i]
	end
	if not onlyDir then
		table.sort(files, function(a, b)
			return a:lower() < b:lower()
		end)
		for i = 1, #files do
			list[#list + 1] = files[i]
		end
	end


	return list
end

local function new(args)
	local box = UI.Box(args)
	function box:onMouseScroll() return true end

	local history = {}
	local current_path = ''
	local root_list = sortList(vfs.list(''), current_path, args.onlyDir)

	box:addChild(UI.Label {
		text = args.header,
		x = 1, y = 1,
		w = args.w, h = 1,
		bg = args.bg, fg = colors.white
	})
	local btn_cancel = box:addChild(UI.Button {
		text = 'Cancel',
		x = args.w - 8, y = args.h - 1,
		w = 8, h = 1,
		bg = colors.lightGray, fg = colors.white
	})
	function btn_cancel:pressed()
		if box.onClose then
			return box:onClose()
		else
			local parent = box.parent
			parent:removeChild(box)
			parent:onLayout()
			self.root.focus = nil
		end
	end

	local btn_open = box:addChild(UI.Button {
		text = args.header == 'Save As' and 'Save' or 'Open',
		x = 2, y = args.h - 1,
		w = 6, h = 1,
		bg = colors.lightGray, fg = colors.white
	})
	function btn_open:pressed()
		if box.pressed then
			if box.list_ui.item then
				return box:pressed(current_path .. '/' .. box.list_ui.item)
			elseif current_path == '' then
				return box:pressed(current_path)
			end
		end
	end

	local btn_prev = box:addChild(UI.Button {
		text = '\27',
		x = 2, y = 2,
		w = 1, h = 1,
		bg = args.bg, fg = colors.white,
		disabled = true
	})
	function btn_prev:pressed()
		if current_path == '' then return end
		-- log(current_path:gsub("/[^/]+$", ""))
		history[#history + 1] = current_path
		current_path = current_path:match("^(.+)/[^/]+$") or ""
		root_list = sortList(vfs.list(current_path), current_path, args.onlyDir)
		box.list_ui:updateArr(root_list)
		box.list_ui:setScrollPosY(0)
		box.path_ui.text = '/' .. current_path
		box.path_ui.dirty = true
		box.btn_next:setDisabled()
		if current_path == '' then return self:setDisabled(true) end
	end

	local btn_next = box:addChild(UI.Button {
		text = '\26',
		x = 3, y = 2,
		w = 1, h = 1,
		bg = args.bg, fg = colors.white,
		disabled = true
	})
	box.btn_next = btn_next
	function btn_next:pressed()
		if #history == 0 then return end
		btn_prev:setDisabled()
		local path = table.remove(history)
		current_path = path
		root_list = sortList(vfs.list(current_path), current_path, args.onlyDir)
		box.list_ui:updateArr(root_list)
		box.list_ui:setScrollPosY(0)
		box.path_ui.text = '/' .. current_path
		box.path_ui.dirty = true
		if #history == 0 then
			return self:setDisabled(true)
		end
	end

	local path = box:addChild(UI.Textfield {
		x = 5, y = 2,
		w = args.w - 5, h = 1,
		bg = colors.lightGray, fg = colors.white,
	})
	path.text = '/'
	box.path_ui = path
	function path:pressed(path)
		self.root.focus = nil
		if not vfs.exists(path) and not args.header == 'Save As' then
			self.text = '/' .. current_path
			self.dirty = true
		elseif vfs.isDir(path) then
			history = {}
			current_path = path:sub(2)
			root_list = sortList(vfs.list(current_path), current_path, args.onlyDir)
			box.list_ui:updateArr(root_list)
			box.list_ui:setScrollPosY(0)
			self.text = '/' .. current_path
			self.scroll_x = math.max(0, #self.text - self.w)
			self.dirty = true
		elseif not args.onlyDir and box.pressed then
			return box:pressed(path)
		end
	end

	local list_ui = box:addChild(UI.List {
		x = 2, y = 4,
		w = args.w - 2, h = args.h - 6,
		bg = colors.white, fg = colors.black,
		items = root_list
	})
	list_ui.oldFocus = list_ui.onFocus
	box.list_ui = list_ui
	function list_ui:onFocus(bool)
		if self.root.focus == btn_open then return end
		if not bool then
			self.double = nil
			return self:oldFocus(bool)
		end
	end

	function list_ui:pressed(item, index, btn, x, y)
		if btn == 2 then
			local current_list = self
			root_list[#root_list + 1] = ''
			self:updateArr(root_list)
			local context = self.root:addChild(UI.ContextMenu {
				x = x, y = y + 1,
				w = 13, h = 5,
				bg = colors.lightGray, fg = colors.white
			})
			context:addItem('Create File', function()
				self:setScrollPosY(math.huge)
				local new_file = self.root:addChild(UI.Textfield {
					x = self.x, y = self.y + self.h - 1,
					w = self.w, h = 1,
					bg = colors.black, fg = colors.white
				})
				new_file.oldFocus = new_file.onFocus
				function new_file:onFocus(bool)
					if not bool then
						root_list = sortList(vfs.list(current_path), current_path, args.onlyDir)
						current_list:updateArr(root_list)
						current_list:setScrollPosY(math.huge)
						self.root:removeChild(self)
						self.root:onLayout()
						return self:oldFocus(bool)
					end
				end

				function new_file:pressed(text)
					if vfs.exists(current_path .. '/' .. text) then return end
					local fd, err = io.open(current_path .. '/' .. text, 'w')
					if fd then fd:close() end
					self.root.focus = nil
				end

				self.root.focus = new_file
			end)
			context:addItem('Create Folder', function()
				self:setScrollPosY(math.huge)
				local new_file = self.root:addChild(UI.Textfield {
					x = self.x, y = self.y + self.h - 1,
					w = self.w, h = 1,
					bg = colors.lightGray, fg = colors.white
				})
				new_file.oldFocus = new_file.onFocus
				function new_file:onFocus(bool)
					if not bool then
						root_list = sortList(vfs.list(current_path), current_path, args.onlyDir)
						current_list:updateArr(root_list)
						current_list:setScrollPosY(math.huge)
						self.root:removeChild(self)
						self.root:onLayout()
						return self:oldFocus(bool)
					end
				end

				function new_file:pressed(text)
					if vfs.exists(current_path .. '/' .. text) then return end
					vfs.makeDir(current_path .. '/' .. text)
					self.root.focus = nil
				end

				self.root.focus = new_file
			end)
			self.root.focus = context
			return
		end
		if self.double and index == self.double then
			current_path = current_path == '' and item or current_path .. '/' .. item
			if vfs.isDir(current_path) then
				history = {}
				if not btn_next.disabled then btn_next:setDisabled(true) end
				btn_prev:setDisabled()
				root_list = sortList(vfs.list(current_path), current_path, args.onlyDir)
				self:updateArr(root_list)
				self:setScrollPosY(0)
				path.text = '/' .. current_path
				path.dirty = true
				self.double = nil
			elseif box.pressed then
				box:pressed(current_path)
			end
		else
			self.double = index
		end
	end

	return box
end

return new

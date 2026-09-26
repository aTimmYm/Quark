local function _inspect(value, visited, path, result)
	local t = type(value)

	if t == "table" then
		if visited[value] then
			table.insert(result, path .. " = <cycle>")
			return
		end

		visited[value] = true

		for k, v in pairs(value) do
			local keyStr = "[" .. tostring(k) .. "]"
			_inspect(v, visited, path .. keyStr, result)
		end
	elseif t == "string" then
		table.insert(result, path .. " = \"" .. value .. "\"")
	elseif t == "number" or t == "boolean" then
		table.insert(result, path .. " = " .. tostring(value))
	elseif t == "function" then
		table.insert(result, path .. " = <function>")
	elseif t == "nil" then
		table.insert(result, path .. " = nil")
	else
		table.insert(result, path .. " = <" .. t .. ">")
	end
end

function log( --[[t,]] ...)
	local texts = { ... }
	local file = fs.open('log.txt', "a")
	-- file.write('[' .. os.date('%d.%m.%Y %H:%M:%S') .. ']\n')
	for i, v in ipairs(texts) do
		if type(v) == "table" --[[and type(v) ~= "thread"]] then
			-- v = textutils.serialise(v)
			local ret = {}
			_inspect(v, {}, '', ret)
			v = table.concat(ret, '\n')
		elseif type(v) == 'nil' then
			v = 'nil'
		else
			v = tostring(v)
		end
		file.write(v .. "; ")
	end
	if #texts == 0 then file.write('nil') end
	file.write("\n")
	-- file.write("\n\n")
	file.close()
end

vfs = fs or require 'syscalls'
if not fs then
	function vfs.exists(...)
		return vfs.stat(...)
	end

	function vfs.isDir(...)
		return vfs.stat(...).isDir
	end

	function vfs.makeDir(...)
		return vfs.mkdir(...)
	end
end
APPDIR = shell.getRunningProgram():match("(.*)/[^/]*$")

local w, h = term.getSize()
term.setBackgroundColor(colors.black)
term.clear()

local UI = require "Data.UI"
local user = require 'Data.Settings'
-- colors = UI.colors
local SearchPanel = require 'Data.search'
local SideBar = require 'Data.sidebar'
local Explorer = require 'Data.explorer'
local Document = require 'Data.document'
local Snippets = require 'Data.Snippets'
local start_page = require 'Data.start_page'
local About = require 'Data.about'
local options_init = require 'Data.options'
UI.Editor = require 'Data.editor'.new
local TabBar = require 'Data.tabbar_extended'.new
local updater
local link = 'https://raw.githubusercontent.com/aTimmYm/Quark/refs/heads/main/'

local function size_new_tabs(self)
	local i = 0
	for _, _ in pairs(self) do
		i = i + 1
	end
	return i - 1
end
local new_tabs = { __size = size_new_tabs }

local root = UI.Root(w, h)
-- root.modal = {}

-- function root:redraw()
-- 	for i = 1, #self.children do
-- 		self.children[i]:redraw()
-- 	end
-- 	if self.focus then
-- 		self.focus:focusPostDraw()
-- 	end
-- 	for i = 1, #self.modal do
-- 		local child = self.modal[i]
-- 		child:onLayout()
-- 		child:redraw()
-- 	end
-- end

local surface = root:addChild(UI.Box {
	x = 1, y = 1,
	w = root.w, h = root.h,
	bg = colors.black, fg = colors.white,
})

local Pane = UI.Container {
	x = 1, y = 1,
	w = surface.w, h = surface.h
}

local tabbar = Pane:addChild(TabBar {
	x = 1, y = 1,
	w = surface.w, h = 1,
	bg = colors.black, fg = colors.lightGray,
	bg_selected = colors.lightGray, fg_selected = colors.white,
	x_color = colors.gray
})
tabbar.pages = {}
function tabbar:pressed(index, btn, x, y)
	if btn == 1 or btn == 3 then
		local page = self.pages[index]

		if self.current_page and self.current_page ~= page then
			Pane:removeChild(self.current_page)
			self.current_page = nil
			surface:onLayout()
		end
		if index == 0 then
			root.pane = nil
			surface:removeChild(true)
			if root.start_page then
				root.start_page:onResize(surface.w, surface.h)
				surface:addChild(root.start_page)
			end
			return root:onLayout()
		end

		if page and not self.current_page then
			self.current_page = page
			Pane:addChild(page)
			root.focus = page.editor
			page.localY = root.find and 3 + root.find.h - 1 or 2
			surface:onResize(root.w, root.h)
			surface:onLayout()
		end

		if root.find and root.find.textfield1 then
			local current_search_query = root.find.textfield1.text
			if current_search_query ~= "" then
				root.find:find(current_search_query)
			end
		end
	end
end

function tabbar:onChangeTabs(index, new_index)
	self.pages[index], self.pages[new_index] = self.pages[new_index], self.pages[index]
end

function tabbar:onCloseTab(name, index)
	if new_tabs[name] then new_tabs[name] = nil end

	local page = self.pages[index]

	Pane:removeChild(page)
	table.remove(self.pages, index)
end

local sidebar = SideBar.init { x = 1, y = 1, w = 8, h = root.h, bg = colors.lightGray, fg = colors.black }

local btn_tree = root:addChild(UI.Button {
	text = '>',
	x = 1, y = root.h,
	w = 1, h = 1,
	bg = colors.gray, fg = colors.white,
})
function btn_tree:pressed()
	self.text = self.text == '>' and '<' or '>'
	if root.tree then
		root:removeChild(sidebar)
		root.tree = nil
		surface.localX = 1
		self.localX = 1
	else
		if root.h ~= sidebar.h then sidebar:onResize(root.w, root.h) end
		root:addChild(sidebar)
		root.tree = sidebar
		surface.localX = sidebar.localX + sidebar.w
		self.localX = surface.localX
	end
	surface:onResize(root.w, root.h)
	root:onLayout()
end

function btn_tree:onResize(width, height)
	self.localY = height
end

function sidebar:onChangeSize()
	surface.localX = self.x + self.w
	btn_tree.localX = surface.localX
	surface:onResize(root.w, root.h)
	root:onLayout()
end

function sidebar:pressed(btn, item)
	if btn ~= 1 then return end
	if item.is_case then return end
	local full_path = self.path .. '/' .. item.place .. item.name
	return self.openFile(full_path)
end

local placeholder = Pane:addChild(UI.Widget {
	x = 2, y = root.h,
	w = 4, h = 1,
})
function placeholder:draw()
	term.setCursorPos(self.x, self.y)
	term.blit('\160\160\160\149', 'fff7', '777f')
end

function Pane:onResize(width, height)
	self.w, self.h = width, height
	tabbar.w = self.w
	placeholder.localY = self.h
	local children = self.children
	for i = 1, #children do
		local child = children[i]
		if child.onResize then
			child:onResize(self.w, self.h)
		end
	end
end

local function save()
	if not tabbar.current_page then return end
	local doc = tabbar.current_page.editor.document
	for n = doc:getLinesSize(), 1, -1 do
		if not doc:getLine(n):match('%S') then
			doc:setLine(n, nil)
		else
			break
		end
	end
	doc:setLine(doc:getLinesSize() + 1, '')
	for n = 1, doc:getLinesSize() do
		doc:setLine(n, doc:getLine(n):gsub('[ \t]*$', ''))
	end
	local ok, err = doc:save()
	if not ok and err == 'no_path' then
		-- СПРОСИТЬ ПУТЬ (короче окно)
	end
	tabbar.current_page.editor:onSave()
end

local function empty() return false end

local onCommand = {
	['Find'] = function(editor)
		local cursor = editor.cursors.current
		local c_select = cursor.select
		if root.find then
			if c_select and c_select.sY == c_select.eY then
				editor.cursors = {
					cursor,
					blink = editor.cursors.blink,
					color = editor.cursors.color,
					panel = editor.cursors.panel,
					current = cursor
				}
				local text = editor:getLine(c_select.sY):sub(c_select.sX, c_select.eX)
				local textfield = root.find.textfield1
				textfield.text = text
				textfield:onLayout()
				textfield:setCursor(math.huge)
				root.find:find(text, c_select.sX, c_select.eX, c_select.sY)
			end
			return
		end

		local search_panel = Pane:addChild(SearchPanel.init { x = 1, y = 2, w = Pane.w, bg = colors.gray, fg = colors.white })
		function search_panel:onSelectResult(sX, eX, sY, query, case_sensitivity, whole_words, regular_expressions)
			local c_editor = tabbar.current_page.editor
			local c_cursor = c_editor.cursors.current
			if sX and sY then
				c_editor:setCursor(c_cursor, sX, sY)
			end

			if query and query ~= "" and sX then
				c_editor.search = { sX, eX, sY, query, case_sensitivity, whole_words, regular_expressions }
			else
				c_editor.search = nil
			end

			c_editor:onLayout()
		end

		function search_panel:onClose()
			local page = tabbar.current_page
			local c_editor = page.editor
			if page then
				root.find = nil
				page.localY = 2
				page:onResize(surface.w, surface.h)
			end
			root.focus = c_editor

			for i = 1, #tabbar.pages do
				local page = tabbar.pages[i]
				page.editor.search = nil
			end
			Pane:removeChild(search_panel)
			Pane:onLayout()
		end

		function search_panel:onReplace(s_x, e_x, y, text)
			local line = editor:getLine(y)
			editor:setLine(y, line:sub(1, s_x - 1) .. text .. line:sub(e_x + 1))
		end

		function search_panel:onReplaceAll(from, to)
			for i = 1, editor:getLinesSize() do
				local line = editor:getLine(i)
				editor:setLine(i, line:gsub(from, to))
			end
		end

		function search_panel:onExpand(box_h)
			local page = tabbar.current_page
			page.localY = box_h == 2 and 4 or 3
			page:onResize(Pane.w, Pane.h)
			-- for i = 1, #tabbar.pages do
			-- 	local page = tabbar.pages[i]
			-- 	page.localY = box_h == 2 and 4 or 3
			-- 	page:onResize(surface.w, surface.h)
			-- end
			Pane:onLayout()
		end

		function search_panel:getLines()
			local c_editor = tabbar.current_page.editor
			return c_editor.document.lines
		end

		local page = tabbar.current_page
		root.focus = search_panel.textfield1
		root.find = search_panel
		page.localY = 3
		page:onResize(surface.w, surface.h)
		-- for i = 1, #tabbar.pages do
		-- 	local page = tabbar.pages[i]
		-- 	page.localY = 3
		-- 	page:onResize(surface.w, surface.h)
		-- end

		if cursor and c_select and c_select.sY == c_select.eY then
			editor.cursors = {
				cursor,
				blink = editor.cursors.blink,
				color = editor.cursors.color,
				panel = editor.cursors.panel,
				current = cursor
			}
			local text = editor:getLine(c_select.sY):sub(c_select.sX, c_select.eX)
			local textfield = search_panel.textfield1
			textfield.text = text
			textfield:setCursor(math.huge)
			search_panel:find(text, c_select.sX, c_select.eX, c_select.sY)
		end
		root:onLayout()
	end,
	['Go To Line'] = function(editor)
		local cursor = editor.cursors.current
		local go_to_line = root:addChild(UI.Textfield {
			x = math.floor((root.w - 10) / 2) + 1, y = 2,
			w = 10, h = 1,
			bg = colors.lightGray, fg = colors.white,
			hint_col = colors.gray, hint = ('%d:%d'):format(cursor.x, cursor.y)
		})
		go_to_line.oldFocus = go_to_line.onFocus
		function go_to_line:onFocus(bool)
			local ret = self:oldFocus(bool)
			if not bool then
				self.parent.go_to_line = nil
				self.parent:onLayout()
				self.parent:removeChild(self)
			end
			return ret
		end

		function go_to_line:pressed(text)
			local y, x = text:match('(%d+)[ ]*:?[ ]*(%d*)')
			if y then
				local new_cursor = { x = tonumber(x) or 1, y = tonumber(y) }
				editor.cursors = {
					new_cursor,
					blink = editor.cursors.blink,
					color = editor.cursors.color,
					panel = editor.cursors.panel,
					current = new_cursor
				}
				editor:setCursor(new_cursor, new_cursor.x, new_cursor.y)
			end
			root.focus = editor
		end

		root.go_to_line = go_to_line
		root.focus = go_to_line
	end
}

local function add_tab(name, path, pos, document)
	local page = UI.Container {
		x = 1, y = 2, h = Pane.h - 1, w = Pane.w
	}
	page.onMouseDown = empty
	page.onMouseUp = empty
	page.onMouseDrag = empty
	local editor = page:addChild(UI.Editor {
		x = 1, y = 1,
		w = page.w - 1, h = page.h - 1,
		bg = colors.black, fg = colors.white, bg_selected = user.color_editor_selected_text,
		TabSize = user.tab_size, indent_tabs = user.indent_tabs,
		document = document
	})
	function editor:onCommand(command)
		if onCommand[command] then
			onCommand[command](self)
		end
	end

	function editor:onCharAction()
		local cursor = self.cursors.current
		local line = self:getLine(cursor.y)
		if not line then return end
		local word = line:sub(1, cursor.x - 1)
		local snips = Snippets.getSnippets(word)
		if #snips > 0 then
			self.snip = snips
			self.snip.select = 1
			self.snip.scroll = 0
		else
			self.snip = nil
		end
	end

	local scrollbar_v = page:addChild(UI.Scrollbar(editor))
	local scrollbar_h = page:addChild(UI.Scrollbar_Horizontal(editor))
	scrollbar_h.localX, scrollbar_h.w = scrollbar_h.x + 5, scrollbar_h.w - 5
	function page:onResize(width, height)
		self.w = width
		self.h = root.find and height - root.find.h - 1 or height - 1
		editor.w, editor.h = self.w - 1, self.h - 1
		scrollbar_v.localX, scrollbar_v.h = self.w, editor.h
		scrollbar_h.localY, scrollbar_h.w = self.h, editor.w - 5
		editor.scroll.max_x_cached = nil
		editor:setScrollPosX(editor.scroll.pos_x)
	end

	page.editor = editor
	page.path = path

	tabbar:addTab(name, pos)
	if pos then
		table.insert(tabbar.pages, pos, page)
		return editor
	end
	table.insert(tabbar.pages, page)
	return editor
end

local function settings_init()
	local container = root:addChild(UI.Container {
		x = 1, y = 1,
		w = root.w, h = root.h
	}) --80 70
	local sW, sH = math.floor(root.w * 0.8), math.floor(root.h * 0.7)
	local sX, sY = math.floor((root.w - sW) / 2) + 1, math.floor((root.h - sH) / 2) + 1
	local Settings = container:addChild(options_init(sX, sY, sW, sH))
	function Settings:onClose()
		root:removeChild(container)
		root:onLayout()
		user()
	end

	function Settings:onChangeSettings(setting, value, value2)
		if setting == 'editor.tab_size' then
			user.tab_size = value
			local pages = tabbar.pages
			for i = 1, #pages do
				local page = pages[i]
				local editor = page.editor
				editor.TabSize = value
				editor:invalidateCacheFrom(1)
				editor:cleanCache()
				editor:onLayout()
			end
		elseif setting == 'editor.line_ending' then
			local dependency = {
				['Auto'] = 'detect',
				['LF'] = 'enforce_lf',
				['CRLF'] = 'enforce_crlf',

				['detect'] = 'Auto',
				['enforce_lf'] = 'LF',
				['enforce_crlf'] = 'CRLF',
			}
			user.line_ending = dependency[value]
			local pages = tabbar.pages
			for i = 1, #pages do
				local page = pages[i]
				local document = page.editor.document
				document:setLineEnding(user.line_ending)
			end
		elseif setting == 'editor.indent_tabs' then
			if value == 'Tabs' then
				user.indent_tabs = true
			elseif value == 'Spaces' then
				user.indent_tabs = false
			end
		elseif setting == 'editor.color' then
			user[value] = value2
			local page = tabbar.current_page
			local editor = page.editor
			editor:onLayout()
		elseif setting == 'syntax_analyzer_enabled' then
			user.syntax_analyzer_enabled = value
		elseif setting == 'line_indents_enabled' then
			user.line_indents_enabled = value
		end
	end

	function container:onResize(width, height)
		self.w, self.h = width, height
		Settings:onResize(width, height)
	end
end

local function add_list(path, place)
	path = path == '/' and '' or path
	local list = vfs.list(path)
	if not list then return end

	local dirs = {}
	local files = {}
	for i = 1, #list do
		local v = list[i]
		if vfs.isDir(path .. '/' .. v) then
			dirs[#dirs + 1] = v
		else
			files[#files + 1] = v
		end
	end

	list = {}
	table.sort(dirs, function(a, b)
		return a:lower() < b:lower()
	end)

	table.sort(files, function(a, b)
		return a:lower() < b:lower()
	end)

	for i = 1, #dirs do
		list[#list + 1] = dirs[i]
	end

	for i = 1, #files do
		list[#list + 1] = files[i]
	end

	place = place or ''
	for i = 1, #list do
		local item = list[i]
		local isDir = vfs.isDir(path .. '/' .. item)
		if isDir then
			sidebar.treeview:addItem(place, item, isDir)
			local da = place .. '/' .. item
			add_list(path .. '/' .. item, da:sub(1, 1) == '/' and da:sub(2) or da)
		else
			sidebar.treeview:addItem(place, item, isDir)
		end
	end
	return true
end

local function documentChange(self)
	local id
	for i = 1, #tabbar.pages do
		local page = tabbar.pages[i]
		if page.editor.document == self then
			id = i; break
		end
	end
	if self.isModified then
		tabbar:setTabFg(id, colors.blue)
	else
		tabbar:setTabFg(id)
	end
end

local function openFile(path)
	if not path then return nil, 'Incorrect path' end
	if not vfs.exists(path) or vfs.isDir(path) then return nil, 'No such file' end
	path = path:sub(1, 1) == '/' and path or '/' .. path
	local name = path:match("([^/%\\]+)$")
	for i, v in pairs(tabbar.tabs) do
		if v == name and tabbar.pages[i].path == path then
			tabbar.selected = i
			tabbar:pressed(i, 1); return true
		end
	end
	local doc = Document.new(path)
	if user.line_ending ~= 'detect' then
		doc:setLineEnding(user.line_ending)
	end
	doc.onChange = documentChange
	doc:open()
	local new_selected = tabbar.selected + 1
	add_tab(name, path, new_selected, doc)
	tabbar.selected = new_selected
	tabbar:pressed(new_selected, 1)
	if not root.pane then
		root.pane = Pane
		surface:removeChild(true)
		surface:addChild(Pane)
		Pane:onResize(surface.w, surface.h)
		surface:onLayout()
	end
	return true
end

local function openDirectory(path)
	if not path then return nil, 'Incorrect path' end
	if not vfs.exists(path) or not vfs.isDir(path) then return nil, 'No such directory' end
	tabbar.tabs = {}
	tabbar.pages = {}
	tabbar.selected = 0
	root.start_page = nil
	surface:removeChild(true)
	if tabbar.current_page then Pane:removeChild(tabbar.current_page) end
	tabbar.current_page = nil

	root.pane = nil
	sidebar.treeview.tree = {}
	sidebar.openFile = openFile
	sidebar.path = path == '/' and '' or path
	root.workspace = true
	return add_list(path)
end

local function newFile()
	local str_new = "NEW - " .. tostring(new_tabs:__size() + 1)
	if new_tabs[str_new] then
		str_new = "NEW - " .. tostring(new_tabs:__size())
	end
	new_tabs[str_new] = true
	local new_selected = tabbar.selected + 1
	local doc = Document.new()
	if user.line_ending ~= 'detect' then
		doc:setLineEnding(user.line_ending)
	end
	doc.onChange = documentChange
	add_tab(str_new, nil, new_selected, doc)
	tabbar.selected = new_selected
	tabbar:pressed(new_selected, 1)
	if not root.pane then
		root.pane = Pane
		surface:removeChild(true)
		surface:addChild(Pane)
		-- Pane:onResize(surface.w, surface.h)
		root:onLayout()
	end
end

local function modalWindow(header, onlyDir)
	local container = UI.Container {
		x = 1, y = 1,
		w = root.w, h = root.h,
	}
	function container:onMouseScroll() return true end

	local explorer_ui = container:addChild(Explorer {
		x = math.floor((container.w - 25) / 2) + 1, y = math.floor((container.h - 13) / 2) + 1,
		w = 25, h = 13,
		bg = colors.gray, fg = colors.white,
		header = header, onlyDir = onlyDir
	})

	function container:onResize(width, height)
		self.w, self.h = width, height
		explorer_ui.localX, explorer_ui.localY = math.floor((self.w - 25) / 2) + 1, math.floor((self.h - 13) / 2) + 1
	end

	return container, explorer_ui
end

local function File_open()
	local modal_container, explorer_ui = modalWindow('Open File')
	root:addChild(modal_container)
	function explorer_ui:onClose()
		root:removeChild(modal_container); root:onLayout()
		root.focus = root.children[#root.children]
	end

	function explorer_ui:pressed(path)
		if text ~= '' then
			local ok, err = openFile(path)
			if not ok then
				-- return self.err_label:setText(err)
			end
		end
		self:onClose()
	end

	modal_container:onLayout()
end

local function save_as()
	if not tabbar.current_page then return end
	local modal_container, explorer_ui = modalWindow('Save As')
	root:addChild(modal_container)
	function explorer_ui:onClose()
		root:removeChild(modal_container); root:onLayout()
		root.focus = root.children[#root.children]
	end

	function explorer_ui:pressed(path)
		local page = tabbar.current_page
		if not page then return end
		local name = path:match("([^/%\\]+)$")
		new_tabs[tabbar.tabs[tabbar.selected]] = nil
		tabbar.tabs[tabbar.selected] = name
		local editor = page.editor
		local ok, err = editor.document:saveAs(path)
		if not ok then
			return --self.err_label:setText(err)
		end
		if not page.path then page.path = path end
		self:onClose()
	end

	modal_container:onLayout()
end

local btn_menu = root:addChild(UI.Button {
	text = '+',
	x = root.w, y = root.h,
	w = 1, h = 1,
	bg = colors.black, fg = colors.lightGray
})
function btn_menu:pressed()
	if self.text == '-' then
		self.text = '+'; return
	end
	self.text = '-'
	local menu = root:addChild(UI.ContextMenu {
		x = root.w - 11, y = root.h - 8,
		w = 1, h = 8,
		bg = colors.gray, fg = colors.white,
		items = {}
	})
	menu.old_focus = menu.onFocus
	function menu:onFocus(bool)
		if not bool and root.focus ~= btn_menu then
			btn_menu.text = '+'
			btn_menu:onLayout()
		end
		self:old_focus(bool)
	end

	menu:addItem('New', newFile)
	menu:addItem('Open File', File_open)
	menu:addItem('Open Folder', function()
		local modal_container, explorer_ui = modalWindow('Open Folder', true)
		root:addChild(modal_container)
		function explorer_ui:onClose()
			root:removeChild(modal_container); root:onLayout()
			root.focus = root.children[#root.children]
		end

		function explorer_ui:pressed(path)
			if text ~= '' then
				local ok, err = openDirectory(path)
				if not ok then
					-- return self.err_label:setText(err)
				end
			end
			self:onClose()
		end

		modal_container:onLayout()
	end)
	menu:addItem('Save', save)
	menu:addItem('Save As', save_as)
	menu:addItem('Settings', settings_init)
	menu:addItem('About', function()
		local container = root:addChild(UI.Container {
			x = 1, y = 1,
			w = root.w, h = root.h,
		})
		local about_view = container:addChild(About {
			x = math.floor((container.w - 21) / 2) + 1, y = math.floor((container.h - 8) / 2) + 1,
			w = 21, h = 8,
			bg = colors.gray, fg = colors.white
		})
		function about_view:onClose()
			root:removeChild(container)
			return root:onLayout()
		end

		function about_view:onUpdate(btn)
			if not updater then
				local response, err = http.get(link .. 'installer_updater/updater.lua')
				if response then
					local fun = load(response.readAll(), nil, 't', _ENV)
					if fun then updater = fun() end
				end
			end
			local ok, message = updater(APPDIR)
			if not ok then
				btn.text = message
				if message ~= 'No updates' then
					btn.bg = colors.red
				end
            else
				btn.bg = colors.green
				btn.text = 'Success'
			end
			btn.dirty = true
		end
	end)
	menu:addItem('Exit', function() return os.queueEvent('terminate') end)
	root.focus = menu
end

function btn_menu:onResize(width, height)
	self.localX, self.localY = width, height
end

surface.oldDraw = surface.draw
function surface:draw()
	if #self.children > 0 then return end
	return surface:oldDraw()
end

function surface:onResize(width, height)
	local tree = root.tree
	self.w = tree and width - tree.w or width
	self.h = height
	user.w, user.h = root.w, root.h
	local children = self.children
	for i = 1, #children do
		local child = children[i]
		if child.onResize then
			child:onResize(self.w, self.h)
		end
	end
end

function root:onKeyDown(key, held)
	if held then return end
	if key == keys.leftShift or key == keys.rightShift then
		self.shift_held = true
	elseif key == keys.leftAlt or key == keys.rightAlt then
		self.alt_held = true
	elseif key == keys.leftCtrl or key == keys.rightCtrl then
		self.ctrl_held = true
	elseif self.ctrl_held and key == keys.n then
		newFile()
	elseif self.ctrl_held and key == keys.o then
		File_open()
	elseif self.ctrl_held and self.shift_held and key == keys.s then
		save_as()
	elseif self.ctrl_held and key == keys.s then
		save()
	elseif self.ctrl_held and self.shift_held and key == keys.e then
		btn_tree:pressed()
	end
end

function root:onKeyUp(key, held)
	if held then return end
	if key == keys.leftShift or key == keys.rightShift then
		self.shift_held = nil
	elseif key == keys.leftAlt or key == keys.rightAlt then
		self.alt_held = nil
	elseif key == keys.leftCtrl or key == keys.rightCtrl then
		self.ctrl_held = nil
	end
end

function root:onTerminate()
	local path = APPDIR .. '/Data/projects'
	if root.workspace and sidebar.path then
		local file, err = io.open(path .. '/project.lua', 'w')
		if file then
			local tabs = {}
			for i, v in pairs(tabbar.tabs) do
				tabs[#tabs + 1] = { v, tabbar.pages[i].path }
			end
			local project = {
				sidebar_path = sidebar.path,
				sidebar_open = root.tree and true or false,
				tabs = tabs,
				selected = tabbar.selected
			}
			file:write('return' .. textutils.serialise(project, { compact = true }))
			file:close()
		end
	end
	user()
end

if vfs.exists(APPDIR .. '/Data/projects/project.lua') then
	local workspace = dofile(APPDIR .. '/Data/projects/project.lua')
	openDirectory(workspace.sidebar_path)
	for i, v in pairs(workspace.tabs) do
		if v[2] and not vfs.exists(v[2]) then
			workspace.selected = 1
			goto continue
		end
		local doc = Document.new(v[2])
		if user.line_ending ~= 'detect' then
			doc:setLineEnding(user.line_ending)
		end
		doc.onChange = documentChange
		if v[2] then doc:open() end
		add_tab(v[1], v[2], i, doc)
		::continue::
	end
	if not root.pane then
		root.pane = Pane
		surface:removeChild(true)
		surface:addChild(Pane)
		root:onLayout()
	end
	if workspace.sidebar_open then
		btn_tree.text = '<'
		btn_tree.localX = sidebar.x + sidebar.w
		if root.h ~= sidebar.h then sidebar:onResize(root.w, root.h) end
		root:addChild(sidebar)
		root.tree = sidebar
		surface.localX = sidebar.x + sidebar.w
		surface:onResize(root.w, root.h)
	end
	tabbar.selected = workspace.selected
	tabbar:pressed(tabbar.selected, 1)
else
	root.start_page = start_page(surface.w, surface.h)
	function root.start_page:pressed(button)
		if button == 'New File' then
			newFile()
		elseif button == 'Open Project' then
			local modal_container, explorer_ui = modalWindow('Open Project', true)
			root:addChild(modal_container)
			function explorer_ui:onClose()
				root:removeChild(modal_container); root:onLayout()
				root.focus = root.children[#root.children]
			end

			function explorer_ui:pressed(path)
				if text ~= '' then
					local ok, err = openDirectory(path)
					if not ok then
						-- return self.err_label:setText(err)
					end
				end
				self:onClose()
			end

			modal_container:onLayout()
		end
	end

	surface:addChild(root.start_page)
end

root:show()
root:mainloop()

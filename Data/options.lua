local UI = require 'Data.UI'
local user = require 'Data.Settings'

local colors_list = {
	{ 'Selected text', 'color_editor_selected_text' },
	{ 'Cursor',        'color_editor_cursor' },
	{ 'All found',     'color_editor_found_all' },
	{ 'Current found', 'color_editor_found_current' },

	{ 'Whitespace',    'color_whitespace' },
	{ 'Comment',       'color_comment' },
	{ 'String',        'color_string' },
	{ 'Escape',        'color_escape' },
	{ 'Keyword',       'color_keyword' },
	{ 'Value',         'color_value' },
	{ 'Ident',         'color_ident' },
	{ 'Number',        'color_number' },
	{ 'Symbol',        'color_symbol' },
	{ 'Operator',      'color_operator' },
	{ 'Unidentified',  'color_unidentified' },
	{ 'Function',      'color_function' },
	{ 'Function name', 'color_nfunction' },
	{ 'Equality',      'color_equality' },
	{ 'Arg',           'color_arg' },
}

local pages = {
	['Colors'] = function(container, selector)
		local x = selector.localX + selector.w
		local page_container = container:addChild(UI.Container {
			x = x, y = 2,
			w = container.w - x + 1, h = container.h - 1,
			-- bg = colors.gray, fg = colors.white
		})

		local page_box = page_container:addChild(UI.ScrollBox {
			x = 1, y = 1,
			w = page_container.w - 1, h = page_container.h,
			bg = colors.gray, fg = colors.white
		})
		page_container:addChild(UI.Scrollbar(page_box))
		local onScroll_closing_list = {}
		page_box.oldMouseScroll = page_box.onMouseScroll
		function page_box:onMouseScroll(dir)
			for i = 1, #onScroll_closing_list do
				local obj = onScroll_closing_list[i]
				if obj.close then obj:close() end
			end
			return page_box:oldMouseScroll(dir)
		end

		function page_box:onResize(w, h)
			for i = 1, #self.children do
				local child = self.children[i]
				if child.onResize then child:onResize(w, h) end
			end
		end

		local selector_x = page_box.w - 1
		local startY = 2
		local deltaY = 2

		for i = 1, #colors_list do
			local name, key = table.unpack(colors_list[i])
			local lY = startY + deltaY * (i - 1)

			page_box:addChild(UI.Label {
				text = name, align = 'left',
				x = 2, y = lY,
				w = 18, h = 1,
				bg = page_box.bg, fg = page_box.fg,
			})

			local scol_selector = page_box:addChild(UI.ColorSelector {
				x = selector_x, y = lY,
				w = 1, h = 1,
				bg = page_box.bg
			})

			scol_selector:setSelectedColor(user[key])
			function scol_selector:pressed(col)
				if container.onChangeSettings then
					container:onChangeSettings('editor.color', key, col)
				end
			end

			function scol_selector:onResize(w, h)
				self.localX = w - 1
			end

			onScroll_closing_list[#onScroll_closing_list + 1] = scol_selector
		end

		function page_container:onResize(width, height)
			self.localX = selector.localX + selector.w
			self.w, self.h = width - self.localX + 1, height - 1
			page_box.w, page_box.h = self.w - 1, self.h
			page_box.scrollbar_v.localX = self.w
			page_box.scrollbar_v.h = self.h
			page_box:onResize(page_box.w, page_box.h)
		end

		return page_container
	end,

	['Main'] = function(container, selector)
		local x = selector.localX + selector.w
		local page_container = container:addChild(UI.Container {
			x = x, y = 2,
			w = container.w - x + 1, h = container.h - 1,
			-- bg = colors.blue, fg = colors.white
		})

		local page_box = page_container:addChild(UI.ScrollBox {
			x = 1, y = 1,
			w = page_container.w - 1, h = page_container.h,
			bg = colors.gray, fg = colors.white
		})
		page_container:addChild(UI.Scrollbar(page_box))

		page_box:addChild(UI.Label {
			text = 'Tabsize', align = 'left',
			x = 2, y = 2,
			w = 7, h = 1,
			bg = page_box.bg, fg = colors.white
		})

		local dropdown = page_box:addChild(UI.Dropdown {
			x = page_box.w - 5, y = 2,
			w = 5, h = 1,
			bg = colors.white, fg = colors.black,
			defaultValue = tostring(user.tab_size), items = { '1', '2', '3', '4', '5', '6', '7', '8' }
		})
		function dropdown:pressed(item)
			if container.onChangeSettings then
				container:onChangeSettings('editor.tab_size', tonumber(item))
			end
		end

		page_box:addChild(UI.Label {
			text = 'Indent by',
			x = 2, y = 4,
			w = 9, h = 1,
			bg = page_box.bg, fg = colors.white
		})

		local indent_dropdown = page_box:addChild(UI.Dropdown {
			x = page_box.w - 7, y = 4,
			w = 6, h = 1,
			bg = colors.white, fg = colors.black,
			items = {
				'Tabs',
				'Spaces'
			},
			defaultValue = user.indent_tabs and 'Tabs' or 'Spaces'
		})
		function indent_dropdown:pressed(name)
			if container.onChangeSettings then
				container:onChangeSettings('editor.indent_tabs', name)
			end
		end

		page_box:addChild(UI.Label {
			text = 'Endl format', align = 'left',
			x = 2, y = 6,
			w = 9, h = 1,
			bg = page_box.bg, fg = colors.white,
		})
		local dependency = {
			['Auto'] = 'detect',
			['LF'] = 'enforce_lf',
			['CRLF'] = 'enforce_crlf',

			['detect'] = 'Auto',
			['enforce_lf'] = 'LF',
			['enforce_crlf'] = 'CRLF',
		}
		local endl_dropdown = page_box:addChild(UI.Dropdown {
			x = page_box.w - 5, y = 6,
			w = 5, h = 1,
			bg = colors.white, fg = colors.black,
			defaultValue = tostring(dependency[user.line_ending]),
			items = { 'Auto', 'LF', 'CRLF' }
		})
		function endl_dropdown:pressed(item_name)
			if container.onChangeSettings then
				container:onChangeSettings('editor.line_ending', item_name)
			end
		end

		-- page_box:addChild(UI.Label {
		-- 	text = 'Syntax analyzer', align = 'left',
		-- 	x = 2, y = 8,
		-- 	w = 15, h = 1,
		-- 	bg = page_box.bg, fg = colors.white,
		-- })

		-- local syntax_dropdown = page_box:addChild(UI.Dropdown {
		-- 	x = page_box.w - 9, y = 8,
		-- 	w = 9, h = 1,
		-- 	bg = colors.white, fg = colors.black,
		-- 	defaultValue = tostring(user.syntax_analyzer_enabled and 'Enabled' or 'Disabled'),
		-- 	items = { 'Enabled', 'Disabled' }
		-- })

		-- function syntax_dropdown:pressed(item_name)
		-- 	if container.onChangeSettings then
		-- 		container:onChangeSettings('syntax_analyzer_enabled', (item_name == 'Enabled'))
		-- 	end
		-- end

		page_box:addChild(UI.Label {
			text = 'Line indents', align = 'left',
			x = 2, y = 8,
			w = 15, h = 1,
			bg = page_box.bg, fg = colors.white,
		})

		local line_indents_dropdown = page_box:addChild(UI.Dropdown {
			x = page_box.w - 9, y = 8,
			w = 9, h = 1,
			bg = colors.white, fg = colors.black,
			defaultValue = tostring(user.line_indents_enabled and 'Enabled' or 'Disabled'),
			items = { 'Enabled', 'Disabled' }
		})

		function line_indents_dropdown:pressed(item_name)
			if container.onChangeSettings then
				container:onChangeSettings('line_indents_enabled', (item_name == 'Enabled'))
			end
		end

		function page_container:onResize(width, height)
			self.localX = selector.localX + selector.w
			self.w, self.h = width - self.localX + 1, height - 1
			page_box.w, page_box.h = self.w - 1, self.h
			page_box.scrollbar_v.localX, page_box.scrollbar_v.h = self.w, self.h
			dropdown.localX = page_box.w - 5
			indent_dropdown.localX = page_box.w - 7
			endl_dropdown.localX = page_box.w - 5
			-- syntax_dropdown.localX = page_box.w - 9
			line_indents_dropdown.localX = page_box.w - 9
		end

		return page_container
	end,
}

local function init(x, y, w, h)
	local settings_container = UI.Container {
		x = x, y = y,
		w = w, h = h,
		-- bg = colors.red
	}
	function settings_container:onMouseScroll() return true end

	local page_header = settings_container:addChild(UI.Label {
		x = 1, y = 1,
		w = w - 1, h = 1,
		text = 'Settings',
		bg = colors.gray, fg = colors.white,
	})

	local btn_close = settings_container:addChild(UI.Button {
		text = 'x',
		x = page_header.x + page_header.w, y = 1,
		w = 1, h = 1,
		bg = colors.gray, fg = colors.white,
		fg_click = colors.lightGray
	})
	function btn_close:pressed()
		if settings_container.onClose then
			settings_container:onClose()
		end
	end

	local page_selector = settings_container:addChild(UI.List {
		x = 1, y = 2,
		w = math.floor(w * 0.2), h = h - 1,
		fg = colors.white, bg = colors.lightGray,
		items = {
			'Main',
			'Colors',
		}
	})
	page_selector.current = 'Main'
	page_selector.item_index = 1
	page_selector.item = 'Main'
	function page_selector:onFocus() end

	settings_container.current_page = pages[page_selector.current](settings_container, page_selector)
	settings_container:onLayout()
	function page_selector:pressed(item_name, item_index)
		if item_name ~= self.current then
			settings_container:removeChild(settings_container.current_page)
			self.current = item_name
			settings_container.current_page = pages[item_name](settings_container, page_selector)
			settings_container:onLayout()
		end
	end

	function settings_container:onResize(width, height)
		self.w, self.h = math.floor(width * 0.8), math.floor(height * 0.7)
		self.localX, self.localY = math.floor((width - self.w) / 2) + 1, math.floor((height - self.h) / 2) + 1
		btn_close.localX = self.w
		page_header.w = self.w - 1
		page_selector.w, page_selector.h = math.floor(self.w * 0.2), self.h - 1
		for i = 1, #self.children do
			local child = self.children[i]
			if child.onResize then
				child:onResize(self.w, self.h)
			end
		end
	end

	return settings_container
end

return init

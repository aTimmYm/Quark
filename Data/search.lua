local UI = require 'Data.UI'
local _searchpanel = {}

-- %f[%a
local function finder(lines, search, case_sensitivity, whole_words, regular_expressions)
	if search == '' then return {} end
	-- if regular_expressions and not validate_pattern(search) then return {} end
	if regular_expressions then
		local ok = pcall(string.find, 'someText', search)
		if not ok then return {} end
	end
	search = case_sensitivity and search or search:lower()
	if whole_words and not regular_expressions then
		search = '%f[%w_]' .. search:gsub("([%^%$%(%)%%%.%[%]%*%+%-%.%?])", "%%%1") .. '%f[^%w_]'
	end
	local result = {}
	for i = 1, #lines do
		local line = case_sensitivity and lines[i] or lines[i]:lower()
		local pos = 1
		while pos <= #line do
			local found_start_x, found_end_x = line:find(search, pos, not (whole_words or regular_expressions))
			if not found_start_x or found_end_x == 0 then break end
			result[#result + 1] = { found_start_x, found_end_x, i }
			pos = found_end_x + 1
		end
	end
	return result
end

local function prev_find(self)
	local total = #self.findes
	if total == 0 then return end

	self.current_index = self.current_index - 1
	if self.current_index < 1 then self.current_index = total end
	self:update_info()

	if self.onSelectResult then
		local match = self.findes[self.current_index]
		self:onSelectResult(match[1], match[2], match[3], self.textfield1.text, self.case_sensitivity, self.whole_words,
			self.regular_expressions)
	end
end

local function next_find(self)
	local total = #self.findes
	if total == 0 then return end

	self.current_index = self.current_index + 1
	if self.current_index > total then self.current_index = 1 end
	self:update_info()

	if self.onSelectResult then
		local match = self.findes[self.current_index]
		self:onSelectResult(match[1], match[2], match[3], self.textfield1.text, self.case_sensitivity, self.whole_words,
			self.regular_expressions)
	end
end

local function find(self, query, sX, eX, y)
	local lines = self:getLines()
	if not lines then return end
	self.findes = finder(lines, query, self.case_sensitivity, self.whole_words, self.regular_expressions)
	local total = #self.findes
	self.current_index = total == 0 and 0 or 1
	if sX and eX and y then
		-- for index = 1, #self.findes do
		-- 	local find = self.findes[index]
		-- 	if find[1] == sX and find[2] == eX and find[3] == y then
		-- 		self.current_index = index; break
		-- 	end
		-- end
		local low = 1
		local high = #self.findes
		while low <= high do
			local mid = math.floor(low + (high - low) / 2)
			local guess = self.findes[mid]
			local f_sX, f_eX, f_y = guess[1], guess[2], guess[3]

			if f_sX == sX and f_eX == eX and f_y == y then
				self.current_index = mid; break
			elseif y < f_y or (y == f_y and sX < f_sX) then
				high = mid - 1
			else
				low = mid + 1
			end
		end
	end
	self:update_info()

	if self.onSelectResult then
		if total > 0 then
			local match = self.findes[self.current_index]
			self:onSelectResult(match[1], match[2], match[3], query, self.case_sensitivity, self.whole_words,
				self.regular_expressions)
		else
			self:onSelectResult(nil, nil, nil, query)
		end
	end
end

function _searchpanel.init(args)
	local box = UI.Box {
		x = args.x, y = args.y,
		w = args.w, h = 1,
		bg = args.bg, fg = args.fg
	}
	box.findes = {}

	local textfield1 = box:addChild(UI.Textfield {
		x = 1, y = 1,
		w = math.floor(box.w / 2) - 3, h = 1,
		bg = colors.lightGray, fg = colors.white,
		hint_col = colors.gray, hint = 'Search...'
	})
	textfield1.oldCharTyped = textfield1.onCharTyped
	function textfield1:onCharTyped(...)
		local ret = self:oldCharTyped(...)
		box:find(self.text)
		return ret
	end

	textfield1.oldKeyDown = textfield1.onKeyDown
	function textfield1:onKeyDown(...)
		local text = self.text
		local ret = self:oldKeyDown(...)
		if text ~= self.text then
			box:find(self.text)
		end
		return ret
	end

	textfield1.oldPaste = textfield1.onPaste
	function textfield1:onPaste(...)
		local text = self.text
		local ret = self:oldPaste(...)
		if text ~= self.text then
			box:find(self.text)
		end
		return ret
	end

	function textfield1:pressed()
		if self.root.SHIFT_HELD then
			box:prev_find()
		else
			box:next_find()
		end
	end

	local btn_case_sensitivity = box:addChild(UI.Button {
		text = '\198',
		x = textfield1.x + textfield1.w, y = 1,
		w = 1, h = 1,
		bg = colors.lightGray, fg = colors.white,
		bg_click = colors.lightGray, fg_click = colors.lightBlue
	})
	function btn_case_sensitivity:pressed()
		box.case_sensitivity = not box.case_sensitivity
		self.fg = self.fg == colors.blue and colors.white or colors.blue
		box:find(textfield1.text)
	end

	local btn_whole_words = box:addChild(UI.Button {
		text = '_',
		x = btn_case_sensitivity.x + btn_case_sensitivity.w, y = 1,
		w = 1, h = 1,
		bg = colors.lightGray, fg = colors.white,
		bg_click = colors.lightGray, fg_click = colors.lightBlue
	})
	function btn_whole_words:pressed()
		box.whole_words = not box.whole_words
		self.fg = self.fg == colors.blue and colors.white or colors.blue
		box:find(textfield1.text)
	end

	local btn_regular_expressions = box:addChild(UI.Button {
		text = '*',
		x = btn_whole_words.x + btn_whole_words.w, y = 1,
		w = 1, h = 1,
		bg = colors.lightGray, fg = colors.white,
		bg_click = colors.lightGray, fg_click = colors.lightBlue
	})
	function btn_regular_expressions:pressed()
		box.regular_expressions = not box.regular_expressions
		self.fg = self.fg == colors.blue and colors.white or colors.blue
		box:find(textfield1.text)
	end

	local btn_prev = box:addChild(UI.Button {
		text = '\27',
		x = btn_regular_expressions.x + btn_regular_expressions.w, y = 1,
		w = 1, h = 1,
		bg = box.bg, fg = colors.white
	})
	function btn_prev:pressed() box:prev_find() end

	local btn_next = box:addChild(UI.Button {
		text = '\26',
		x = btn_prev.x + btn_prev.w, y = 1,
		w = 1, h = 1,
		bg = box.bg, fg = colors.white
	})
	function btn_next:pressed()
		box:next_find()
	end

	local textfield2 = UI.Textfield {
		x = 1, y = 2,
		w = math.floor(box.w / 2), h = 1,
		bg = colors.lightGray, fg = colors.white,
		hint_col = colors.gray, hint = 'Replace with...'
	}

	local btn_replace = UI.Button {
		text = '\169',
		x = textfield2.x + textfield2.w, y = 2,
		w = 3, h = 1,
		bg = box.bg, fg = colors.white,
	}
	function btn_replace:pressed()
		if textfield1.text ~= '' and box.onReplace then
			local s_x, e_x, y = table.unpack(box.findes[box.current_index])
			box:onReplace(s_x, e_x, y, textfield2.text)
			box:find(textfield1.text)
		end
	end

	local btn_replace_all = UI.Button {
		text = '\64',
		x = btn_replace.x + btn_replace.w, y = 2,
		w = 3, h = 1,
		bg = box.bg, fg = colors.white,
	}
	function btn_replace_all:pressed()
		if textfield1.text ~= '' and box.onReplaceAll then
			box:onReplaceAll(textfield1.text, textfield2.text)
			box:find(textfield1.text)
		end
	end

	local btn_close = box:addChild(UI.Button {
		text = 'x',
		x = box.w, y = 1,
		w = 1, h = 1,
		bg = box.bg, fg = colors.white,
	})
	function btn_close:pressed()
		if box.onClose then
			box:onClose()
		else
			box.parent:onLayout()
			box.parent:removeChild(box)
		end
	end

	local btn_expand = box:addChild(UI.Button {
		text = '\31',
		x = box.w - 1, y = 1,
		w = 1, h = 1,
		bg = box.bg, fg = colors.white,
	})
	function btn_expand:pressed()
		self.text = self.text == '\31' and '\30' or '\31'
		if box.h == 1 then
			box:addChild(textfield2)
			box:addChild(btn_replace)
			box:addChild(btn_replace_all)
		else
			box:removeChild(textfield2)
			box:removeChild(btn_replace)
			box:removeChild(btn_replace_all)
		end
		box.h = box.h == 1 and 2 or 1
		if box.onExpand then box:onExpand(box.h) end
	end

	local totals_label = UI.Label {
		text = '0/0',
		x = btn_next.x + btn_next.w + 1, y = 1,
		w = 3, h = 1,
		bg = box.bg, fg = colors.white
	}
	box:addChild(totals_label)

	function box:update_info()
		local total = #self.findes
		local n_text = ('%d/%d'):format(self.current_index, total)
		totals_label:setText(n_text)
		if totals_label.w ~= #n_text then
			totals_label.w = #n_text
			self:onLayout()
		end
	end

	box.next_find = next_find
	box.prev_find = prev_find
	box.find = find
	box.getLines = function() end

	function box:onResize(width, height)
		self.w = width
		textfield1.w = math.floor(width / 2) - 3
		btn_case_sensitivity.localX = textfield1.localX + textfield1.w
		btn_whole_words.localX = btn_case_sensitivity.localX + btn_case_sensitivity.w
		btn_regular_expressions.localX = btn_whole_words.localX + btn_whole_words.w
		btn_prev.localX = btn_regular_expressions.localX + btn_regular_expressions.w
		btn_next.localX = btn_prev.localX + btn_prev.w
		textfield2.w = math.floor(width / 2)
		totals_label.localX = btn_next.localX + btn_next.w + 1
		btn_replace.localX = (textfield2.localX or textfield2.x) + textfield2.w
		btn_replace_all.localX = (btn_replace.localX or btn_replace.x) + btn_replace.w
		btn_close.localX = width
		btn_expand.localX = width - 1
	end

	box.textfield1 = textfield1

	return box
end

return _searchpanel

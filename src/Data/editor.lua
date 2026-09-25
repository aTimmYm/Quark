local UI = require 'Data.UI'
local _lex = require "Data.lex"
-- local Analyzer = require 'syntax_analyzer'
local ScrollMixin = require 'Mixins.ScrollMixin'
local clamp = UI.Utils.clamp
local expect = UI.Utils.expect
local to_hex = UI.Utils.to_hex
local expect_args = UI.Utils.expect_args
local user = require 'Data.Settings'

local function table_copy(tbl)
	if type(tbl) ~= 'table' then return end
	local copy = {}

	for key, value in pairs(tbl) do
		if type(value) ~= 'table' then
			copy[key] = value
		else
			copy[key] = table_copy(value)
		end
	end

	return copy
end

local function editor_checkCursor(self, x, y)
	return (
		x >= self.x + 5 and
		x < self.x + self.w and
		y >= self.y and
		y < self.y + self.h
	)
end

local function render_tabs(input, tab_size, start_x)
	local x = 1
	local output = {}
	while true do
		local pos = input:find('\t', x)
		if not pos then
			output[#output + 1] = input:sub(x); break
		else
			local spaces_count = tab_size - ((pos + start_x - 2) % tab_size) - 1
			output[#output + 1] = input:sub(x, pos - 1)
			x = pos + spaces_count + 1
			output[#output + 1] = '\26' .. (' '):rep(spaces_count)
		end
	end

	return table.concat(output)
end

-- local function check_syntax(Textbox)
-- 	if not Textbox then return end
-- 	local lines = Textbox.lines
-- 	local tokens
-- 	local LEX_prevState = { type = "normal", level = 0 }
-- 	local line_errors, prevState = nil, {}

-- 	for y = 1, #lines do
-- 		if Textbox.tokenCache[y] and not Textbox.dirtyLines[y] then
-- 			tokens = Textbox.tokenCache[y].tokens
-- 			LEX_prevState = Textbox.tokenCache[y].stateOut
-- 		else
-- 			tokens, LEX_prevState = _lex(Textbox:convert_tabs(lines[y] or ''), LEX_prevState)
-- 		end
-- 		line_errors, prevState = Analyzer.scan(tokens, prevState)

-- 		Textbox.tokenCache[y] = Textbox.tokenCache[y] or { tokens = tokens }
-- 		Textbox.tokenCache[y].tokens = tokens
-- 		Textbox.tokenCache[y].stateOut = Textbox.tokenCache[y].stateOut or LEX_prevState
-- 		Textbox.tokenCache[y].errors = line_errors
-- 		Textbox.tokenCache[y].analyzerStateOut = prevState
-- 		Textbox.dirtyLines[y] = nil
-- 	end
-- 	return true
-- end

local function finder_visible(lines, search, start_y, end_y, case_sensitivity, whole_words, regular_expressions)
	if search == '' then return {} end
	-- if regular_expressions then
	-- 	local ok = pcall(string.find, 'someText', search)
	-- 	if not ok then return {} end
	-- end
	if regular_expressions then
		local ok = pcall(string.find, 'someText', search)
		if not ok then return {} end
	end
	search = case_sensitivity and search or search:lower()
	if whole_words and not regular_expressions then
		search = '%f[%w_]' .. search:gsub("([%^%$%(%)%%%.%[%]%*%+%-%.%?])", "%%%1") .. '%f[^%w_]'
	end
	local result = {}
	for i = start_y, end_y do
		local line = case_sensitivity and lines[i] or lines[i]:lower()
		local pos = 1
		local add = {}
		result[i] = add
		while pos <= #line do
			local found_start_x, found_end_x = line:find(search, pos, not (whole_words or regular_expressions))
			if not found_start_x or found_end_x == 0 then break end
			add[#add + 1] = { found_start_x, found_end_x }
			pos = found_end_x + 1
		end
	end
	return result
end

local token_color = {
	["whitespace"] = 'color_whitespace',
	["comment"] = 'color_comment',
	["string"] = 'color_string',
	["escape"] = 'color_escape',
	["keyword"] = 'color_keyword',
	["value"] = 'color_value',
	["ident"] = 'color_ident',
	["number"] = 'color_number',
	["symbol"] = 'color_symbol',
	["operator"] = 'color_operator',
	["unidentified"] = 'color_unidentified',
	["function"] = 'color_function',
	["nfunction"] = 'color_nfunction',
	["equality"] = 'color_equality',
	["arg"] = 'color_arg'
}

local _editor = {}

local function editor_convert_tabs(self, str)
	return str:gsub("([^\t]*)\t", function(text)
		local spaces = self.TabSize - (#text % self.TabSize)
		return text .. '\t' .. (" "):rep(spaces - 1)
	end)
end

local function editor_getVisualX(self, line, physicalX)
	if type(line) ~= 'string' then return error('line must be string', 2) end
	-- expect(line, 'line', 'string')
	expect(physicalX, 'physicalX', 'number')
	if physicalX == 0 then return 0 end
	local visualX, currentIdx = 1, 1

	while currentIdx < physicalX do
		local tabIdx = string.find(line, "\t", currentIdx, true)

		if tabIdx and tabIdx < physicalX then
			visualX = visualX + (tabIdx - currentIdx)
			visualX = visualX + (self.TabSize - ((visualX - 1) % self.TabSize))
			currentIdx = tabIdx + 1
		else
			visualX = visualX + (physicalX - currentIdx); break
		end
	end

	return visualX
end

-- local function get_line_indent(raw_line, tab_size)
-- 	if not raw_line or #raw_line == 0 then return nil end
-- 	local visual_x = 0
-- 	local has_content = false
-- 	for i = 1, #raw_line do
-- 		local char = raw_line:sub(i, i)
-- 		if char == "\t" then
-- 			visual_x = visual_x + (tab_size - (visual_x % tab_size))
-- 		elseif char == " " then
-- 			visual_x = visual_x + 1
-- 		else
-- 			has_content = true
-- 			break
-- 		end
-- 	end
-- 	if not has_content then return nil end -- Пустая строка или строка только из пробелов
-- 	return math.floor(visual_x / tab_size)
-- end

local function get_line_indent(raw_line, tab_size)
	if not raw_line or raw_line == "" then return nil end

	-- Сразу вырезаем всю "белую" префикс-часть строки до первого символа кода
	local prefix, rest = raw_line:match("^([ \t]*)(.*)")
	if not rest or rest == "" then return nil end -- Строка пустая или состоит только из пробелов/табов

	local visual_x = 0
	for i = 1, #prefix do
		if prefix:byte(i) == 9 then
			visual_x = visual_x + (tab_size - (visual_x % tab_size))
		else
			visual_x = visual_x + 1
		end
	end

	return math.floor(visual_x / tab_size)
end

local function editor_draw(self)
	local scroll, document = self.scroll, self.document

	local visible_start = scroll.pos_y + 1
	local visible_end = math.min(self.h + scroll.pos_y, self:getLinesSize())

	local start_lex = visible_start
	while start_lex > 1 and (not self.tokenCache[start_lex - 1] or self.dirtyLines[start_lex - 1]) do
		start_lex = start_lex - 1
	end

	local prevState -- , prevAnalyzerState
	if start_lex == 1 then
		prevState = { type = "normal", level = 0 }
		-- prevAnalyzerState = {}
	else
		prevState = self.tokenCache[start_lex - 1].stateOut
		-- prevAnalyzerState = self.tokenCache[start_lex - 1].analyzerStateOut
	end
	for i = start_lex, visible_end do
		if not self.tokenCache[i] or self.dirtyLines[i] then
			local tokens, newState = _lex(self:convert_tabs(document:getLine(i)), prevState)
			-- local errors, newAnalyzerState = Analyzer.scan(tokens, prevAnalyzerState)
			self.tokenCache[i] = {
				tokens = tokens,
				stateIn = prevState,
				stateOut = newState,
				-- errors = errors,
				-- analyzerStateOut = newAnalyzerState,
			}
			self.dirtyLines[i] = nil
			prevState = newState
			-- prevAnalyzerState = newAnalyzerState
		else
			prevState = self.tokenCache[i].stateOut
			-- prevAnalyzerState = self.tokenCache[i].analyzerStateOut
		end
	end

	local draw_lines = {}
	local orig_lines = {}

	local self_fg = to_hex[self.fg]
	local self_bg = to_hex[self.bg]

	local line_indents = {}
	for i = visible_start, visible_end do
		line_indents[i] = get_line_indent(document:getLine(i), self.TabSize)
	end

	for i = visible_start, visible_end do
		if line_indents[i] == nil then
			local prev_indent = 0
			for p = i - 1, 1, -1 do
				local ind = line_indents[p] or get_line_indent(document:getLine(p), self.TabSize)
				if ind ~= nil then
					prev_indent = ind; break
				end
			end

			local next_indent = 0
			for n = i + 1, document:getLinesSize() do
				local ind = line_indents[n] or get_line_indent(document:getLine(n), self.TabSize)
				if ind ~= nil then
					next_indent = ind; break
				end
			end
			line_indents[i] = prev_indent >= next_indent and prev_indent or next_indent
		end
	end

	-- local guide_fg = '8'
	-- local guide_fg = '0'
	local guide_fg = '7'

	-- local guide_char = ':'
	-- local guide_char = '|'
	-- local guide_char = '\149'
	-- local guide_char = '\132'
	local guide_char = '\166'
	-- local guide_char = '\145'
	-- local guide_char = '\127'
	-- local guide_char = '\183'
	-- local guide_char = '\7'

	-- local line_indents_enabled = true
	local line_indents_enabled = user.line_indents_enabled

	for i = visible_start, visible_end do
		local blit_text, blit_fg, blit_bg = {}, {}, {}
		local tokens = self.tokenCache[i].tokens
		for j = 1, #tokens do
			local token = tokens[j]
			blit_text[j] = token.data
			blit_fg[j] = (user.lex_enabled and to_hex[user[token_color[token.type]] or colors.white] or self_fg):rep(#
				token.data)
			blit_bg[j] = self_bg:rep(#token.data)
		end

		local orig_line = table.concat(blit_text)
		local line_str = orig_line

		local orig_fg = table.concat(blit_fg)
		local fg_str = orig_fg

		local bg_str = table.concat(blit_bg)

		if line_indents_enabled then
			local line_indent = line_indents[i] or 0
			if line_indent > 0 then
				for k = 1, line_indent do
					local pos = (k - 1) * self.TabSize + 1

					if pos > #line_str then
						local pad = pos - #line_str
						local current_bg = #bg_str > 0 and bg_str:sub(-1, -1) or self_bg
						line_str = line_str .. (" "):rep(pad)
						fg_str = fg_str .. self_fg:rep(pad)
						bg_str = bg_str .. current_bg:rep(pad)
					end

					local char = line_str:sub(pos, pos)
					if char == ' ' or char == '\t' then
						line_str = line_str:sub(1, pos - 1) .. guide_char .. line_str:sub(pos + 1)
						fg_str = fg_str:sub(1, pos - 1) .. guide_fg .. fg_str:sub(pos + 1)
					end
				end
			end
		end

		draw_lines[i] = {
			line_str,
			fg_str,
			bg_str
		}

		orig_lines[i] = {
			orig_line,
			orig_fg
		}
	end

	-- if user.syntax_analyzer_enabled then
	-- 	for i = visible_start, visible_end do
	-- 		local current_line = document:getLine(i)
	-- 		local errors = self.tokenCache[i] and self.tokenCache[i].errors
	-- 		if current_line and errors and #errors > 0 then
	-- 			for _, word in pairs(errors) do
	-- 				local oBG = draw_lines[i][3]
	-- 				draw_lines[i][3] = oBG:sub(1, word.posFirst - 1) ..
	-- 					to_hex[colors.red]:rep(#word.data) .. oBG:sub(word.posLast + 1, -1)
	-- 			end
	-- 		end
	-- 	end
	-- end

	local selected_bg = to_hex[user.color_editor_selected_text]

	for id = 1, #self.cursors do
		local cursor = self.cursors[id]
		local select = cursor.select
		if select then
			local x1 = self:getVisualX(document:getLine(select.sY), select.sX)
			local x2 = self:getVisualX(document:getLine(select.eY), select.eX)

			for i = select.sY, select.eY do
				local line = draw_lines[i]
				if line then
					local line_str = line[1]
					local orig_str = orig_lines[i][1]

					local line_fg = line[2]
					local orig_fg = orig_lines[i][2]

					local line_bg = line[3]
					local sel_x_start = i == select.sY and x1 or 1
					local sel_x_end = i == select.eY and x2 or #line_str
					if sel_x_start <= sel_x_end + 1 then
						if document:getLine(select.eY):sub(select.eX, select.eX) == '\t' then
							sel_x_end = sel_x_end + (self.TabSize - ((sel_x_end - 1) % self.TabSize)) - 1
						end
						local sel_text = orig_str:sub(sel_x_start, sel_x_end)
						if #orig_str == 0 and select.eY ~= i then -- empty line select draw
							line[1] = '\149' .. line_str:sub(2)
							line[2] = selected_bg .. line_fg:sub(2)
							line[3] = self_bg .. line[3]:sub(2)
						else
							sel_text = sel_text:gsub(" ", "\183")
							sel_text = render_tabs(sel_text, self.TabSize, sel_x_start)

							local sub_start = sel_x_start - 1
							local sub_end = sel_x_end + 1

							local orig_fg_chunk = orig_fg:sub(sel_x_start, sel_x_end)
							if i ~= select.eY then
								line[1] = line_str:sub(1, sub_start) .. sel_text .. line_str:sub(sub_end, -1) .. '\149'
								line[2] = line_fg:sub(1, sub_start) .. orig_fg_chunk .. selected_bg
								line[3] = line_bg:sub(1, sub_start) ..
									selected_bg:rep(#sel_text) .. line_bg:sub(sub_end, -1) .. 'f'
							else
								line[1] = line_str:sub(1, sub_start) .. sel_text .. line_str:sub(sub_end, -1)
								line[2] = line_fg:sub(1, sub_start) .. orig_fg_chunk .. line_fg:sub(sub_end, -1)
								line[3] = line_bg:sub(1, sub_start) ..
									selected_bg:rep(#sel_text) .. line_bg:sub(sub_end, -1)
							end
						end
					end
				end
			end
		end
	end

	if self.search then
		local search_color = to_hex[user.color_editor_found_all]
		local current_search_color = to_hex[user.color_editor_found_current]
		local data = finder_visible(document.lines, self.search[4], visible_start, visible_end, self.search[5],
			self.search[6], self.search[7])
		for i = visible_start, visible_end do
			local line_data = data[i]
			if line_data then
				local line = draw_lines[i]
				local text = document:getLine(i)
				local original = line[3]
				for j = 1, #line_data do
					local match_start, match_end = line_data[j][1], line_data[j][2]
					local s = self:getVisualX(text, match_start)
					local e = self:getVisualX(text, match_end)
					local ser = self.search
					if ser[3] == i and ser[2] == match_end and ser[1] == match_start then
						original = original:sub(1, s - 1) ..
							current_search_color:rep(e - s + 1) .. original:sub(e + 1, -1)
					else
						original = original:sub(1, s - 1) .. search_color:rep(e - s + 1) .. original:sub(e + 1, -1)
					end
				end
				line[3] = original
			end
		end
	end

	local start_sub, end_sub = scroll.pos_x + 1, scroll.pos_x + self.w - 5
	local rep_len = scroll.pos_x + self.w
	local draw_y = self.y - visible_start

	local draw_str = (' '):rep(rep_len)
	local draw_fg = ('0'):rep(rep_len)
	local draw_bg = self_bg:rep(rep_len)

	for i = visible_start, visible_end do
		local num_line = tostring(i):sub(-4, -1)
		local line = draw_lines[i]
		term.setCursorPos(self.x, draw_y + i)
		term.blit((' '):rep(4 - #num_line) .. num_line .. '\149' .. (line[1] .. draw_str):sub(start_sub, end_sub),
			(self.cursors[1].y == i and '0' or '8'):rep(4) .. '7' .. (line[2] .. draw_fg):sub(start_sub, end_sub),
			'7777f' .. (line[3] .. draw_bg):sub(start_sub, end_sub))
	end

	local text, fg, bg = '    \149' .. (' '):rep(self.w - 5), ('7'):rep(self.w), '7777f' .. self_bg:rep(self.w - 5)
	for i = self.y + (visible_end - scroll.pos_y), self.y + self.h - 1 do
		term.setCursorPos(self.x, i)
		term.blit(text, fg, bg)
	end
end

local function editor_visualToPhysical(self, line, visual_x)
	expect(visual_x, 'visual_x', 'number')
	local visual_pos = 1
	local physical_pos = 1

	while physical_pos <= #line do
		local tab = line:find("\t", physical_pos, true)

		if not tab then
			local width = #line - physical_pos + 1

			if visual_x <= visual_pos + width then
				return physical_pos + (visual_x - visual_pos)
			end

			return #line + 1
		end

		local width = tab - physical_pos

		if visual_x < visual_pos + width then
			return physical_pos + (visual_x - visual_pos)
		end

		visual_pos = visual_pos + width

		local offset = (visual_pos - 1) % self.TabSize
		local tab_width = self.TabSize - offset

		if visual_x < visual_pos + tab_width then
			return tab
		end

		visual_pos = visual_pos + tab_width
		physical_pos = tab + 1
	end

	return #line + 1
end

local function editor_onMouseScroll(self, dir, x, y)
	if self.root.alt_held then dir = dir * 5 end
	if self.root.shift_held then
		return self:scrollX(dir)
	end
	return self:scrollY(dir)
end

local function editor_copySelected(self, cursor)
	local copy = {}
	local selected = cursor.select
	if not selected then return '' end
	if selected.sY ~= selected.eY then
		copy[1] = self:getLine(selected.sY):sub(selected.sX, -1)
		copy[2] = '\n'
		for i = selected.sY + 1, selected.eY - 1 do
			copy[#copy + 1] = self:getLine(i)
			copy[#copy + 1] = "\n"
		end
		copy[#copy + 1] = self:getLine(selected.eY):sub(1, selected.eX)
		-- copy[#copy + 1] = "\n" --?
	else
		copy[1] = self:getLine(selected.sY):sub(selected.sX, selected.eX)
	end
	-- TODO: maybe try to use table.concat(copy, '\n')?
	return table.concat(copy)
end

local function editor_invalidateCacheFrom(self, y)
	for i = y, self:getLinesSize() do
		self.tokenCache[i] = nil
		self.dirtyLines[i] = true
	end
end

local function editor_cleanCache(self)
	local max = 0
	for i in pairs(self.tokenCache) do
		if type(i) == "number" then
			max = max >= i and max or i
		end
	end
	for i = self:getLinesSize() + 1, max do
		self.tokenCache[i] = nil
		self.dirtyLines[i] = nil
	end
end

local function editor_moveCursor(self, cursor, deltaX, deltaY)
	local size = self:getLinesSize()

	local line = self:getLine(cursor.y)

	if deltaX ~= 0 then
		cursor.x = cursor.x + deltaX
		local len = #line + 1

		while cursor.x > len do
			cursor.x = cursor.x - len
			cursor.y = math.min(cursor.y + 1, size)
			line = self:getLine(cursor.y)
			len = #line + 1
		end

		while cursor.x < 1 do
			cursor.y = math.max(cursor.y - 1, 1)
			line = self:getLine(cursor.y)
			len = #line + 1
			cursor.x = cursor.x + len
		end
		cursor.preff_x = self:getVisualX(line, cursor.x)
	end

	if deltaY ~= 0 then
		cursor.y = clamp(cursor.y + deltaY, 1, size)
		local _line = self:getLine(cursor.y)
		cursor.x = clamp(self:visualToPhysical(_line, cursor.preff_x), 1, #_line + 1)
	end

	if cursor.y - self.scroll.pos_y > self.h then
		self:setScrollPosY(cursor.y - self.h)
	elseif cursor.y - self.scroll.pos_y < 1 then
		self:setScrollPosY(cursor.y - 1)
	end

	local visual_x = self:getVisualX(line, cursor.x)
	if visual_x - self.scroll.pos_x > (self.w - 5) then
		self:setScrollPosX(visual_x - (self.w - 5))
	elseif visual_x - self.scroll.pos_x < 1 then
		self:setScrollPosX(visual_x - 1)
	end
end

local function editor_setCursor(self, cursor, posX, posY)
	posY = clamp(posY, 1, self:getLinesSize())
	local line = self:getLine(posY)
	posX = clamp(posX, 1, #(line or "") + 1)

	cursor.y = posY
	if posY - self.scroll.pos_y > self.h then
		self:setScrollPosY(posY - self.h)
	elseif posY - self.scroll.pos_y < 1 then
		self:setScrollPosY(posY - 1)
	end

	cursor.x = posX
	local visual_x = self:getVisualX(line, posX)
	cursor.preff_x = visual_x
	if visual_x - self.scroll.pos_x > (self.w - 5) then
		self:setScrollPosX(visual_x - (self.w - 5))
	elseif visual_x - self.scroll.pos_x < 1 then
		self:setScrollPosX(visual_x - 1)
	end
end

local brackets_open = {
	['{'] = '}',
	['['] = ']',
	['('] = ')',
}

local brackets_close = {
	['}'] = true,
	[']'] = true,
	[')'] = true,
}

local quotes = {
	['"'] = '"',
	["'"] = "'",
}

local function isLetter(str)
	return str:match('[%w_]') ~= nil
end

local function isQuote(str)
	return (str == '"' or str == "'")
end

local function isClosableForBrackets(str)
	return ((str == '') or (str:match('[;:%.,=}%]%)> \n\t]') ~= nil))
end

local function editor_onCharTyped(self, chr)
	chr = chr == '\000' and '?' or chr -- kyryllic chars security

	local BRACKETS_AUTO_CLOSE = 'auto' -- 'auto' / 'always' / 'never'

	local cursors = self.cursors
	local instr, history = {}, {}
	local cursor_history = {}
	local saved_line = {}
	for id = #cursors, 1, -1 do
		local cursor = cursors[id]
		local select = cursor.select
		local cursor_copy = table_copy(cursor)
		cursor_copy.id = id
		cursor_history[#cursor_history + 1] = cursor_copy
		local instrID = { x = 0, y = 0 }
		instr[id] = instrID
		if select then
			if BRACKETS_AUTO_CLOSE ~= 'never' then
				local closing_char = brackets_open[chr] or quotes[chr]
				-- if BRACKETS_AUTO_CLOSE == 'always' or closing_char then
				if closing_char then
					if select.sY ~= select.eY then
						local end_line = self:getLine(select.eY)
						self:setLine(select.eY, end_line:sub(1, select.eX) .. closing_char .. end_line:sub(select.eX + 1))

						if not saved_line[select.eY] then
							saved_line[select.eY] = true
							history[#history + 1] = { name = 'setLine', y = select.eY, data = end_line }
						end

						local start_line = self:getLine(select.sY)
						self:setLine(select.sY, start_line:sub(1, select.sX - 1) .. chr .. start_line:sub(select.sX))

						if not saved_line[select.sY] then
							saved_line[select.sY] = true
							history[#history + 1] = { name = 'setLine', y = select.sY, data = start_line }
						end

						select.sX = select.sX + 1
					else
						local line = self:getLine(select.sY)
						if not saved_line[select.sY] then
							saved_line[select.sY] = true
							history[#history + 1] = { name = 'setLine', y = select.sY, data = line }
						end
						self:setLine(select.sY,
							line:sub(1, select.sX - 1) ..
							chr .. line:sub(select.sX, select.eX) .. closing_char .. line:sub(select.eX + 1))
						select.sX = select.sX + 1
						select.eX = select.eX + 1
						self:moveCursor(cursor, 1, 0)
						instrID.x = instrID.x + 1
					end
					instrID.cy = select.eY
					instrID.x = instrID.x + 1
					goto continue
				end
			end
			local sy, ey = select.sY, select.eY
			instrID.y = sy - ey
			instrID.x = instrID.x + select.sX - (select.eX + 1)
			local delete_history = self:deleteSelected(cursor)
			if sy ~= ey then
				if saved_line[sy] then
					table.remove(delete_history, 1)
				end
				if saved_line[ey] then
					table.remove(delete_history, #delete_history)
					history[#history].name = 'insertLine'
				end
			end
			saved_line[sy] = true
			-- history[#history+1] = delete_history
			for i = 1, #delete_history do
				history[#history + 1] = delete_history[i]
			end
		end

		local line = self:getLine(cursor.y)
		if not saved_line[cursor.y] then
			saved_line[cursor.y] = true
			history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
		end

		local is_quote = quotes[chr]
		local is_bracket_open = brackets_open[chr]
		local closing_char = is_quote or is_bracket_open
		if BRACKETS_AUTO_CLOSE ~= 'never' then
			local auto_closers = cursor.auto_closers or {}
			if closing_char then
				local next_char = line:sub(cursor.x, cursor.x)
				local prev_x = cursor.x - 1
				local prev_char = line:sub(prev_x, prev_x)
				-- кавычки: автозакрытие после слов

				-- прикольные символы
				-- ;:.,=}])> \n\t

				-- +если перед курсором стоит буква, мы не делаем автозакрытие для кавычек, но делаем для всех скобок
				-- +если перед курсором стоит кавычка, мы не делаем автозакрытие кавычек
				-- +если после курсора стоит буква, мы не делаем автозакрытие вообще
				-- +если после курсора стоит кавычка, мы не делаем автозакрытие кавычек, но делаем для всех скобок

				-- если мы автозакрыли символ, мы должны помнить, что мы его автозакрыли, и не дублировать символ, если
				-- пользователь вручную закрыл его, а также сбрасывать память о ней.

				-- не уверен, пока что попридержу в комменте:
				-- local can_auto_close = BRACKETS_AUTO_CLOSE == 'always' -- если always, делаем автозакрытие всегда, иначе проверяем
				-- 	or isClosableForBrackets(next_char) -- если пишем скобку или откр кавычку, проверяем следующий символ на ;:.,=}])> \n\t

				local can_auto_close = (BRACKETS_AUTO_CLOSE == 'always' -- если always, делаем автозакрытие всегда, иначе проверяем
						or isClosableForBrackets(next_char)) -- если пишем скобку или откр кавычку, проверяем следующий символ на ;:.,=}])> \n\t
					and not (
						isLetter(next_char)                 -- НЕ закрываем вообще, если после курсора стоит буква
						or (is_quote and isLetter(prev_char)) -- НЕ закрываем, если перед курсором стоит буква и пишем кавычку
						or (is_quote and isQuote(prev_char)) -- НЕ закрываем, если перед курсором стоит кавычка и пишем кавычку
						or (is_quote and isQuote(next_char)) -- НЕ закрываем, если после курсора стоит кавычка и пишем кавычку
					)

				if can_auto_close then
					self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. chr .. closing_char .. line:sub(cursor.x))

					auto_closers[#auto_closers + 1] = closing_char
					cursor.auto_closers = auto_closers

					self:moveCursor(cursor, 1, 0)
					goto continue
				end
			end

			if auto_closers[#auto_closers] == chr then
				table.remove(auto_closers, #auto_closers)
				cursor.auto_closers = auto_closers
				self:moveCursor(cursor, 1, 0)
				goto continue
			end
		end

		self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. chr .. line:sub(cursor.x))
		self:moveCursor(cursor, #chr, 0)
		instrID.x, instrID.cy = instrID.x + #chr, cursor.y
		::continue::
	end

	self:updateCursor(instr)
	self.dirty = true
	self:addUndo(history, cursor_history)

	if self.onCharAction then
		self:onCharAction()
	end
	return true
end


-- local function editor_onCharTyped(self, chr)
-- 	chr = chr == '\000' and '?' or chr

-- 	local BRACKETS_AUTO_CLOSE = 'auto' -- / 'always' / 'never'

-- 	local cursors = self.cursors
-- 	local instr = {}
-- 	for id = #cursors, 1, -1 do
-- 		local cursor = cursors[id]
-- 		local select = cursor.select
-- 		local intsrID = { x = 0, y = 0 }
-- 		instr[id] = intsrID
-- 		if select then
-- 			intsrID.y = select.sY - select.eY
-- 			intsrID.x = select.sX - (select.eX + 1)
-- 			self:deleteSelected(cursor)
-- 		end

-- 		local line = self:getLine(cursor.y)
-- 		self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. chr .. line:sub(cursor.x))
-- 		intsrID.x, intsrID.cy = intsrID.x + #chr, cursor.y
-- 	end

-- 	self:updateCursor(instr)
-- 	self.dirty = true

-- 	if self.onCharAction then
-- 		-- self:onCharAction()
-- 	end
-- end

-- local function editor_onCharTyped(self, chr)
-- 	chr = chr == '\000' and '?' or chr

-- 	local BRACKETS_AUTO_CLOSE = 'auto' -- / 'always' / 'never'

-- 	-- local delta = { delta = 0 }
-- 	local cursors, selected = self.cursors, self.select
-- 	local cursors_deltas = {}
-- 	for id = #cursors, 1, -1 do
-- 		local cursor = cursors[id]
-- 		-- cursor.y = cursor.y - delta.y
-- 		-- local line = self:getLine(cursor.y)

-- 		-- local next_char = line:sub(cursor.x, cursor.x)
-- 		-- local prev_char = line:sub(cursor.x - 1, cursor.x - 1)

-- 		-- local is_bracket_open = brackets_open[chr] ~= nil
-- 		-- local is_bracket_close = brackets_close[chr] ~= nil
-- 		-- local is_quote = quotes[chr] ~= nil

-- 		-- if is_bracket_close or is_quote then
-- 		-- 	local auto_index = findAutoCloser(self, cursor.y, cursor.x, chr)

-- 		-- 	if auto_index then
-- 		-- 		removeAutoCloser(self, auto_index)

-- 		-- 		self:setCursor(i, cursor.x + #chr, cursor.y)
-- 		-- 		self.dirty = true

-- 		-- 		if self.onCharAction then
-- 		-- 			self:onCharAction()
-- 		-- 		end

-- 		-- 		return true
-- 		-- 	end
-- 		-- end

-- 		-- if BRACKETS_AUTO_CLOSE ~= 'never' then
-- 		-- 	local close_char = nil
-- 		-- 	local can_auto_close = false
-- 		-- 	if is_bracket_open then
-- 		-- 		close_char = brackets_open[chr]
-- 		-- 		if BRACKETS_AUTO_CLOSE == 'always' then
-- 		-- 			can_auto_close = true
-- 		-- 		else
-- 		-- 			can_auto_close = not isLetter(next_char)
-- 		-- 		end
-- 		-- 	end

-- 		-- 	if is_quote then
-- 		-- 		close_char = quotes[chr]

-- 		-- 		if BRACKETS_AUTO_CLOSE == 'always' then
-- 		-- 			can_auto_close = true
-- 		-- 		else
-- 		-- 			can_auto_close =
-- 		-- 				not isLetter(prev_char) and not isLetter(next_char)
-- 		-- 				and not isQuote(prev_char) and not isQuote(next_char)
-- 		-- 		end
-- 		-- 	end

-- 		-- 	if (is_bracket_open or is_quote) and self.select.status then
-- 		-- 		self.auto_closers = {}

-- 		-- 		local end_line = self:getLine(self.select.eY)

-- 		-- 		self:setLine(self.select.eY,
-- 		-- 			end_line:sub(1, self.select.eX) .. close_char .. end_line:sub(self.select.eX + 1, -1))

-- 		-- 		self.select.eX = self.select.eX + 1

-- 		-- 		local start_line = self:getLine(self.select.sY)

-- 		-- 		self:setLine(self.select.sY,
-- 		-- 			start_line:sub(1, self.select.sX - 1) .. chr .. start_line:sub(self.select.sX, -1))

-- 		-- 		self.select.sX = self.select.sX + 1

-- 		-- 		self:setCursor(cursor.x + 1, cursor.y)
-- 		-- 		self.dirty = true

-- 		-- 		return true
-- 		-- 	end

-- 		-- 	if (is_bracket_open or is_quote) and can_auto_close then
-- 		-- 		local insert_len = #chr + #close_char

-- 		-- 		shiftAutoClosers(self, cursor.y, cursor.x, insert_len)

-- 		-- 		self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. chr .. close_char .. line:sub(cursor.x))

-- 		-- 		addAutoCloser(self, cursor.y, cursor.x + #chr, close_char)

-- 		-- 		self:setCursor(cursor.x + #chr, cursor.y)
-- 		-- 		self.dirty = true

-- 		-- 		return true
-- 		-- 	end
-- 		-- end

-- 		-- if self.select.status then
-- 		-- self.auto_closers = {}
-- 		if selected[id] then
-- 			local select = selected[id]
-- 			-- delta.y = delta.y + (select.eY - select.sY)
-- 			local deltas = cursors_deltas[#cursors_deltas]
-- 			local deltaX, deltaY, deltaNextX = 0, 0, 0
-- 			if select.eY > select.sY then
-- 			elseif select.eY == select.sY then
-- 				deltaX = select.eX - select.sX
-- 				deltaY = 0
-- 			-- else
-- 			-- 	deltaX = select.sX + (select.eX)
-- 			end
-- 			cursors_deltas[#cursors_deltas + 1] = {
-- 				y = deltas.y + (select.eY - select.sY),
-- 				current_x = deltaX,
-- 				next_x = 0,
-- 			}
-- 			self:deleteSelected(id)
-- 		end

-- 		-- cursor = self.cursors
-- 		-- line = self:getLine(cursor.y)
-- 		-- end
-- 		local line = self:getLine(cursor.y)

-- 		-- shiftAutoClosers(self, cursor.y, cursor.x, #chr)
-- 		-- if delta[cursor.y] then
-- 		-- 	cursor.x = cursor.x + delta[cursor.y]
-- 		-- 	delta[cursor.y] = delta[cursor.y] + #chr
-- 		-- else
-- 		-- 	delta[cursor.y] = #chr
-- 		-- end
-- 		self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. chr .. line:sub(cursor.x))

-- 		-- self:setCursor(id, cursor.x + #chr, cursor.y)
-- 	end
-- 	local deltas = {}
-- 	for id = 1, #cursors do

-- 	end
-- 	self.dirty = true

-- 	if self.onCharAction then
-- 		self:onCharAction()
-- 	end
-- end

local function editor_setLine(self, y, line)
	self:invalidateCacheFrom(y)
	self:cleanCache()
	self.scroll.max_x_cached = nil
	return self.document:setLine(y, line)
end

local function editor_getLine(self, y)
	return self.document:getLine(y)
end

local function editor_moveLines(self, f, e, t)
	self:invalidateCacheFrom(f <= t and f or t)
	self:cleanCache()
	return self.document:moveLines(f, e, t)
end

local function editor_deleteLine(self, y)
	self:invalidateCacheFrom(y)
	self:cleanCache()
	self.scroll.max_x_cached = nil
	-- table.insert(self.instructions, { name = 'insertLine', y = y, data = deletedLine })
	return self.document:deleteLine(y)
end

local function editor_insertLine(self, y, line)
	self:invalidateCacheFrom(y)
	self:cleanCache()
	self.scroll.max_x_cached = nil
	return self.document:insertLine(y, line)
end

local function editor_updateDirty(self)
	if self.scrollbar_v then
		self.scrollbar_v.dirty = true
	end
	if self.scrollbar_h then
		self.scrollbar_h.dirty = true
	end
	self.dirty = true
end

local function editor_onFocus(self, bool)
	if not bool then
		-- self.root.shift_held = nil
		-- self.root.ctrl_held = nil
		-- self.root.alt_held = nil
		self.dirty = true
	end
	self.cursors.blink = bool
end

local function editor_focusPostDraw(self)
	local scroll, cursors = self.scroll, self.cursors
	if cursors.blink then
		local line_cache = {}
		for id = 1, #cursors do
			local cursor = cursors[id]
			local select = cursor.select
			if not select then
				if not line_cache[cursor.y] then
					line_cache[cursor.y] = self:getLine(cursor.y)
				end
				local line = line_cache[cursor.y]
				local x, y = self:getVisualX(line, cursor.x), self.y + cursor.y - 1 - scroll.pos_y

				x = self.x + x - 1 - scroll.pos_x + 5
				if editor_checkCursor(self, x, y) then
					term.setCursorPos(x, y)
					term.setTextColor(self.bg)
					term.setBackgroundColor(user.color_editor_cursor)
					local text = line:sub(cursor.x, cursor.x)
					term.write(text == '' and ' ' or text)
					-- term.write(id)
				end
			end
		end

		local cursor = cursors.current
		local line = line_cache[cursor.y] or self:getLine(cursor.y)
		local x, y = self:getVisualX(line, cursor.x), self.y + cursor.y - 1 - scroll.pos_y

		-- if self.snip and self:check(x, y) then
		-- if self.snip then
		if self.snip and cursor.y >= self.y + self.scroll.pos_y - 1 and cursor.y < self.y + self.scroll.pos_y + self.h - 1 then
			term.setBackgroundColor(colors.white) -- КОСТЫЛИ
			term.setTextColor(colors.black) -- КОСТЫЛИ
			local up = self.h - (cursor.y - scroll.pos_y) < 4
			local dir = up and -1 or 1

			local n_x = clamp(
				self.x + x + 4 - scroll.pos_x,
				self.x + 5,
				self.x + self.w - 10
			)
			local t = math.min(#self.snip, 4)
			for i = self.snip.scroll + 1, self.snip.scroll + t do
				local index = up and (t + 1 - i) or i
				local snip = self.snip[index]

				local n_y = y + dir * (i - self.snip.scroll)

				term.setCursorPos(n_x, n_y)

				if index == self.snip.select then
					term.setBackgroundColor(colors.gray)
					term.setTextColor(colors.white)
				end

				term.write(snip:sub(1, 10) .. (" "):rep(math.max(0, 10 - #snip)))

				if index == self.snip.select then
					term.setBackgroundColor(colors.white)
					term.setTextColor(colors.black)
				end
			end
		end
	end
end

local function editor_onMouseDown(self, btn, x, y)
	if btn ~= 1 then return true end
	local cursors = self.cursors
	local current_cursor = cursors.current
	local lines_size = self:getLinesSize()
	local p_y = math.min(y - self.y + self.scroll.pos_y + 1, lines_size)
	local line = self:getLine(p_y)
	local p_x = self:visualToPhysical(line, x - self.x + self.scroll.pos_x + 1 - 5)

	if self.snip then self.snip = nil end

	if x - self.x + 1 < 6 then
		if #cursors > 1 then
			current_cursor = {
				cx = current_cursor.x,
				cy = current_cursor.y
			}
			cursors = {
				current_cursor,
				blink = cursors.blink,
				-- color = cursors.color,
				panel = cursors.panel,
				current = current_cursor
			}
			self.cursors = cursors
		end
		if not self.root.shift_held then current_cursor.cx, current_cursor.cy = 1, p_y end
		cursors.panel = true
		self:setCursor(current_cursor, 1, p_y + 1)
		self:selectText(current_cursor, current_cursor.cx, current_cursor.cy, current_cursor.x, current_cursor.y)
		self.dirty = true; return true
	end
	if cursors.panel and self.root.shift_held then
		local s_y = current_cursor.cy
		if p_y < s_y then
			s_y = math.min(lines_size, s_y + 1)
			self:setCursor(current_cursor, 1, p_y)
		else
			self:setCursor(current_cursor, 1, p_y + 1)
		end
		self:selectText(current_cursor, 1, s_y, current_cursor.x, current_cursor.y); return true
	end
	cursors.panel = nil

	if self.timer_id then
		os.cancelTimer(self.timer_id); self.timer_id = nil
		if current_cursor.cx == p_x and current_cursor.cy == p_y then
			local firstPos = line:sub(1, p_x):find("[%w_]+$")
			local relativeEnd = select(2, line:sub(p_x):find("^[%w_]+"))
			if firstPos and relativeEnd then
				local lastPos = p_x + relativeEnd - 1
				self:setCursor(current_cursor, lastPos + 1, current_cursor.y)
				self:selectText(current_cursor, firstPos, current_cursor.y, current_cursor.x, current_cursor.y)
			else
				self:setCursor(current_cursor, p_x + 1, current_cursor.y)
				self:selectText(current_cursor, p_x, current_cursor.y, current_cursor.x, current_cursor.y)
			end
			current_cursor.cx, current_cursor.cy = firstPos or p_x, current_cursor.y
			self.dirty = true; return true
		end
	end

	if self.root.alt_held then
		local index = #cursors + 1
		for id = 1, #cursors do
			local cursor = cursors[id]
			local select = cursor.select
			local in_selection = false
			if select then
				local after_start = (p_y > select.sY) or (p_y == select.sY and p_x >= select.sX)
				local before_end = (p_y < select.eY) or (p_y == select.eY and p_x <= select.eX + 1)
				in_selection = after_start and before_end
			end
			if in_selection or (p_y == cursor.y and p_x == cursor.x) then
				if #cursors ~= 1 then
					table.remove(cursors, id)
				else
					current_cursor = cursors[#cursors]
					cursors.current = current_cursor
				end
				cursor.select = nil
				self.dirty = true; return true
			elseif p_y < cursor.y or (p_y == cursor.y and p_x < cursor.x) then
				index = id; break
			end
		end
		current_cursor = {
			cx = p_x,
			cy = p_y
		}
		table.insert(cursors, index, current_cursor)
		cursors.current = current_cursor
	elseif #cursors > 1 then
		cursors = {
			current_cursor,
			blink = cursors.blink,
			panel = cursors.panel,
			-- color = cursors.color
			current = current_cursor
		}
		self.cursors = cursors
	end

	self:setCursor(current_cursor, p_x, p_y)
	if self.root.shift_held and not self.root.alt_held then
		self:selectText(current_cursor, current_cursor.cx, current_cursor.cy, current_cursor.x, current_cursor.y)
	elseif not self.root.alt_held then
		current_cursor.select = nil
		current_cursor.cx, current_cursor.cy = p_x, p_y
	end
	self.dirty = true
	self.timer_id = os.startTimer(0.5)
	return true
end

local function editor_onMouseDrag(self, btn, x, y)
	local cursor = self.cursors.current
	if not cursor then return true end
	local nY = math.max(y - self.y + 1 + self.scroll.pos_y, 1)
	if self.cursors.panel then
		local s_y = cursor.cy
		if nY < s_y then
			s_y = math.min(self:getLinesSize(), s_y + 1)
			self:setCursor(cursor, 1, nY)
		else
			self:setCursor(cursor, 1, nY + 1)
		end
		self:selectText(cursor, 1, s_y, cursor.x, cursor.y); return true
	end
	local line = self:getLine(nY)
	if not line then return true end
	local nX = self:visualToPhysical(line, x - self.x + 1 + self.scroll.pos_x - 5)
	self:setCursor(cursor, nX, nY)
	self:selectText(cursor, cursor.cx, cursor.cy, cursor.x, cursor.y); return true
end

local function editor_onMouseUp(self, btn, x, y)
	-- local lines_size = self:getLinesSize()
	-- local p_y = math.min(y - self.y + self.scroll.pos_y + 1, lines_size)
	-- local line = self:getLine(p_y)
	-- local p_x = self:visualToPhysical(line, x - self.x + self.scroll.pos_x + 1 - 5)
	self:updateCursor()
	-- self.cursors.current = nil
	-- if self.root.alt_held then
	-- 	local cursors, selected = self.cursors, self.select
	-- 	for id = 1, #cursors do
	-- 		local cursor, select = cursors[id], selected[id]
	-- 		local in_selection = false
	-- 		if select then
	-- 			local after_start = (p_y > select.sY) or (p_y == select.sY and p_x >= select.sX)
	-- 			local before_end = (p_y < select.eY) or (p_y == select.eY and p_x <= select.eX + 1)
	-- 			in_selection = after_start and before_end
	-- 		end
	-- 		if in_selection then
	-- 			if #cursors ~= 1 then table.remove(cursors, id) end
	-- 			if selected[id] then selected[id] = nil end
	-- 			self.dirty = true; return true
	-- 		elseif p_y == cursor.y and p_x == cursor.x then
	-- 			if #cursors ~= 1 then table.remove(cursors, id) end
	-- 			if selected[id] then selected[id] = nil end
	-- 			self.dirty = true; return true
	-- 		end
	-- 	end
	-- end
end

local function editor_getScrollMaxY(self)
	return math.max(0, self:getLinesSize() - 1)
end

local function editor_getScrollMaxX(self)
	if self.scroll.max_x_cached then
		return self.scroll.max_x_cached
	end
	local max = 0
	for i = 1, self:getLinesSize() do
		local line = self:getLine(i)
		local nLine = self:getVisualX(line, #line)
		max = max < nLine and nLine or max
	end
	max = max - (self.w - 5) + 1
	self.scroll.max_x_cached = max
	return max
end

local function editor_getLinesSize(self)
	return self.document:getLinesSize()
end

local function editor_deleteSelected(self, cursor)
	local selected = cursor.select
	-- if not selected then return false end
	local new_line = self:getLine(selected.sY)
	local history = {}
	history[#history + 1] = { name = 'setLine', y = selected.sY, data = new_line }
	if selected.sY ~= selected.eY then
		local end_line = self:getLine(selected.eY)
		new_line = new_line:sub(1, selected.sX - 1) .. end_line:sub(selected.eX + 1)
		local selected_plus_1 = selected.sY + 1
		for y = selected_plus_1, selected.eY do
			history[#history + 1] = { name = 'insertLine', y = selected_plus_1, data = self:deleteLine(selected_plus_1) }
		end
	else
		new_line = new_line:sub(1, selected.sX - 1) .. new_line:sub(selected.eX + 1)
	end
	self:setLine(selected.sY, new_line)
	self:setCursor(cursor, selected.sX, selected.sY)
	cursor.select = nil
	return history
end

-- local function editor_onKeyUp(self, key)
-- 	if key == keys.leftShift or key == keys.rightShift then
-- 		self.root.shift_held = nil
-- 	elseif key == keys.leftCtrl or key == keys.rightCtrl then
-- 		self.root.ctrl_held = nil
-- 	elseif key == keys.leftAlt or key == keys.rightAlt then
-- 		self.root.alt_held = nil
-- 	end
-- 	return true
-- end

local function editor_selectText(self, cursor, from_x, from_y, to_x, to_y)
	-- expect(from_x, 'from_x', 'number')
	-- expect(from_y, 'from_y', 'number')
	-- expect(to_x, 'to_x', 'number')
	-- expect(to_y, 'to_y', 'number')
	if from_x == to_x and from_y == to_y then
		cursor.select = nil
		self.dirty = true; return
	end
	if not cursor.select then cursor.select = {} end
	local selected = cursor.select
	if (to_x < from_x and to_y == from_y) or to_y < from_y then
		selected.sX, selected.sY = to_x, to_y
		selected.eX, selected.eY = from_x - 1, from_y
	else
		selected.sX, selected.sY = from_x, from_y
		selected.eX, selected.eY = to_x - 1, to_y
	end
	self.dirty = true
end

local function editor_updateCursor(self, instr)
	local cursors = self.cursors
	if #cursors == 1 then return end
	if instr then
		for id = 1, #cursors do
			local cursor = cursors[id]
			local select = cursor.select
			local ins, prev_ins = instr[id], instr[id - 1]
			if prev_ins then
				cursor.y = cursor.y + prev_ins.y
				if prev_ins.cy == cursor.y then
					self:moveCursor(cursor, prev_ins.x, 0)
					ins.x = ins.x + prev_ins.x
					if select then
						select.sX = select.sX + prev_ins.x
						if select.sY == select.eY then
							select.eX = select.eX + prev_ins.x
						end
					end
				end
				ins.cy = cursor.y
				ins.y = prev_ins.y + ins.y
			end
		end
	end
	for id = #cursors, 2, -1 do
		local prev_cursor = cursors[id - 1]
		local prev_select = prev_cursor.select
		local crnt_cursor = cursors[id]
		local crnt_select = crnt_cursor.select
		if prev_select and crnt_select then
			local after_start = (crnt_cursor.y > prev_select.sY) or
				(crnt_cursor.y == prev_select.sY and crnt_cursor.x >= prev_select.sX)
			local before_end = (crnt_cursor.y < prev_select.eY) or
				(crnt_cursor.y == prev_select.eY and crnt_cursor.x <= prev_select.eX)
			if after_start and before_end then
				if prev_select.sY > crnt_select.sY then
					prev_select.sY, prev_select.sX = crnt_select.sY, crnt_select.sX
				elseif prev_select.sY == crnt_select.sY then
					prev_select.sX = math.min(crnt_select.sX, prev_select.sX)
				end
				if prev_select.eY < crnt_select.eY then
					prev_select.eY, prev_select.eX = crnt_select.eY, crnt_select.eX
				elseif prev_select.eY == crnt_select.eY then
					prev_select.eX = math.max(crnt_select.eX, prev_select.eX)
				end
				if prev_cursor.y == prev_select.sY and prev_cursor.x == prev_select.sX then
					prev_cursor.cx, prev_cursor.cy = prev_select.eX + 1, prev_select.eY
				else
					prev_cursor.cx, prev_cursor.cy = prev_select.sX, prev_select.sY
				end
				table.remove(cursors, id)
				cursors.current = cursors[#cursors]
				self.dirty = true
			else
				after_start = (prev_cursor.y > crnt_select.sY) or
					(prev_cursor.y == crnt_select.sY and prev_cursor.x >= crnt_select.sX)
				before_end = (prev_cursor.y < crnt_select.eY) or
					(prev_cursor.y == crnt_select.eY and prev_cursor.x <= crnt_select.eX)
				if after_start and before_end then
					if crnt_select.sY > prev_select.sY then
						crnt_select.sY, crnt_select.sX = prev_select.sY, prev_select.sX
					elseif crnt_select.sY == prev_select.sY then
						crnt_select.sX = math.min(crnt_select.sX, prev_select.sX)
					end
					if crnt_select.eY < prev_select.eY then
						crnt_select.eY, crnt_select.eX = prev_select.eY, prev_select.eX
					elseif crnt_select.eY == prev_select.eY then
						crnt_select.eX = math.max(crnt_select.eX, prev_select.eX)
					end
					if crnt_cursor.y == crnt_select.sY and crnt_cursor.x == crnt_select.sX then
						crnt_cursor.cx, crnt_cursor.cy = crnt_select.eX + 1, crnt_select.eY
					else
						crnt_cursor.cx, crnt_cursor.cy = crnt_select.sX, crnt_select.sY
					end
					table.remove(cursors, id - 1)
					cursors.current = cursors[#cursors]
					self.dirty = true
				end
			end
		elseif crnt_select then
			local after_start = (prev_cursor.y > crnt_select.sY) or
				(prev_cursor.y == crnt_select.sY and prev_cursor.x >= crnt_select.sX)
			local before_end = (prev_cursor.y < crnt_select.eY) or
				(prev_cursor.y == crnt_select.eY and prev_cursor.x <= crnt_select.eX)
			if after_start and before_end then
				table.remove(cursors, id - 1)
				cursors.current = cursors[#cursors]
				self.dirty = true
			end
		elseif prev_select then
			local after_start = (crnt_cursor.y > prev_select.sY) or
				(crnt_cursor.y == prev_select.sY and crnt_cursor.x >= prev_select.sX)
			local before_end = (crnt_cursor.y < prev_select.eY) or
				(crnt_cursor.y == prev_select.eY and crnt_cursor.x <= prev_select.eX)
			if after_start and before_end then
				table.remove(cursors, id)
				cursors.current = cursors[#cursors]
				self.dirty = true
			end
		end

		if prev_cursor.y == crnt_cursor.y and prev_cursor.x == crnt_cursor.x then
			table.remove(cursors, id)
			cursors.current = cursors[#cursors]
		end
	end
end

local function editor_undo(self)
	self.document:undo()
	self:invalidateCacheFrom(1)
	self:cleanCache()
	local total_undo = #self.undo_history
	if total_undo == 0 then return end
	local cursors = self.cursors
	local instruction = table.remove(self.undo_history, total_undo)
	local redo_history = {}
	self.redo_history[#self.redo_history + 1] = redo_history
	for id = 1, #cursors do
		local cursor_copy = table_copy(cursors[id])
		cursor_copy.id = id
		redo_history[#redo_history + 1] = cursor_copy
	end
	cursors = {
		blink = cursors.blink,
		-- color = cursors.color,
		panel = cursors.panel,
		current = cursors.current
	}
	self.cursors = cursors
	for i = #instruction, 1, -1 do
		local instr = instruction[i]
		cursors[instr.id] = {
			x = instr.x,
			y = instr.y,
			cx = instr.cx,
			cy = instr.cy,
			preff_x = instr.preff_x,
			select = instr.select
		}
	end
	self.cursors.current = self.cursors
		[#self.cursors] -- как буд-то немного не правильно восстанавливает, но не вызывает багов
	self.dirty = true
end

local function editor_redo(self)
	self.document:redo()
	self:invalidateCacheFrom(1)
	self:cleanCache()
	local total_redo = #self.redo_history
	if total_redo == 0 then return end
	local instruction = table.remove(self.redo_history, total_redo)
	local cursors = self.cursors
	local undo_history = {}
	self.undo_history[#self.undo_history + 1] = undo_history
	for id = 1, #cursors do
		local cursor_copy = table_copy(cursors[id])
		cursor_copy.id = id
		undo_history[#undo_history + 1] = cursor_copy
	end
	cursors = {
		blink = cursors.blink,
		-- color = cursors.color,
		panel = cursors.panel,
		current = cursors.current
	}
	self.cursors = cursors
	for i = #instruction, 1, -1 do
		local instr = instruction[i]
		cursors[instr.id] = {
			x = instr.x,
			y = instr.y,
			cx = instr.cx,
			cy = instr.cy,
			preff_x = instr.preff_x,
			select = instr.select
		}
	end
	self.cursors.current = self.cursors
		[#self.cursors] -- как буд-то немного не правильно восстанавливает, но не вызывает багов
	self.dirty = true
end

local function editor_addUndo(self, history, cursor_history)
	self.document:addUndo(history)
	self.undo_history[#self.undo_history + 1] = cursor_history
	self.redo_history = {}
end

local function editor_onKeyDown(self, key, held)
	if key == keys.tab then
		local cursors = self.cursors
		local saved_line, history = {}, {}
		local cursor_history = {}
		local instr = {}
		if self.snip then
			local main_cursor = cursors.current
			local c_line = self:getLine(main_cursor.y)
			local s_x, e_x = c_line:sub(1, main_cursor.x - 1):find('[%w_]*$')
			local obrubok = e_x - s_x + 1
			local insert_str = self.snip[self.snip.select]:sub(obrubok + 1)
			for id = #cursors, 1, -1 do
				local cursor = cursors[id]
				local cursor_copy = table_copy(cursor)
				cursor_copy.id = id
				cursor_history[#cursor_history + 1] = cursor_copy
				local instrID = { x = 0, y = 0 }
				instr[id] = instrID
				local line = self:getLine(cursor.y)
				if not saved_line[cursor.y] then
					history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
					saved_line[cursor.y] = true
				end
				line = line:sub(1, cursor.x - 1) .. insert_str .. line:sub(cursor.x)
				self:setLine(cursor.y, line)
				self:moveCursor(cursor, #insert_str, 0)
				instrID.x, instrID.cy = instrID.x + #insert_str, cursor.y
			end
			self.snip = nil
			self:updateCursor(instr)
		else
			local tab_char = user.indent_tabs and '\t' or (' '):rep(self.TabSize)
			local tab_len = #tab_char
			if self.root.shift_held then -- SHIFT+TAB
				for id = #cursors, 1, -1 do
					local cursor = cursors[id]
					local cursor_copy = table_copy(cursor)
					cursor_copy.id = id
					cursor_history[#cursor_history + 1] = cursor_copy
					local select = cursor.select
					if select then --delete tabs of selected lines
						local move = false
						for i = select.sY, select.eY do
							local line = self:getLine(i)
							local tab_pos = line:match('^[ \t]*()')

							local tabs_count = math.floor(self:getVisualX(line, tab_pos) / self.TabSize) or 1
							self:setLine(i, (tab_char):rep(tabs_count - 1) .. line:sub(tab_pos))
							if not saved_line[i] then
								history[#history + 1] = { name = 'setLine', y = i, data = line }
								saved_line[i] = true
							end

							if tab_pos > 1 then --select correction
								if i == select.sY and select.sX >= tab_pos then
									select.sX = math.max(1, select.sX - tab_len)
									move = true
								end
								if i == select.eY then
									select.eX = math.max(1, select.eX - tab_len)
									move = true
								end
							end
						end
						if move then self:setCursor(cursor, cursor.x - tab_len, cursor.y) end
					else --delete tab at 1 line
						local line = self:getLine(cursor.y)
						if not saved_line[cursor.y] then
							history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
							saved_line[cursor.y] = true
						end
						local tab_pos = line:match('^[ \t]*()')

						local tabs_count = math.floor(self:getVisualX(line, tab_pos) / self.TabSize) or 1
						self:setLine(cursor.y, (tab_char):rep(tabs_count - 1) .. line:sub(tab_pos))

						if tab_pos > 1 then --cursor correction
							self:setCursor(cursor, cursor.x - tab_len, cursor.y)
						end
					end
				end
			else
				for id = #cursors, 1, -1 do
					local cursor = cursors[id]
					local cursor_copy = table_copy(cursor)
					cursor_copy.id = id
					cursor_history[#cursor_history + 1] = cursor_copy
					local select = cursor.select
					local instrID = { x = 0, y = 0 }
					instr[id] = instrID
					if select then --add tab to selected lines
						local move = false
						for i = select.sY, select.eY do
							local line = self:getLine(i)
							local tab_pos, have_text = line:match('^[ \t]*()(.)')
							if have_text then
								local tabs_count = math.floor(self:getVisualX(line, tab_pos) / self.TabSize) or 0
								self:setLine(i, (tab_char):rep(tabs_count + 1) .. line:sub(tab_pos))
								if not saved_line[i] then
									history[#history + 1] = { name = 'setLine', y = i, data = line }
									saved_line[i] = true
								end

								if i == select.sY and select.sX > tab_pos then --select correction
									select.sX = select.sX + tab_len
									move = true
								end
								if i == select.eY then --and self.selected.eX >= tab_pos then
									select.eX = select.eX + tab_len
									move = true
								end
							end
						end
						if move then self:moveCursor(cursor, tab_len, 0) end
					else
						local line = self:getLine(cursor.y)
						if not saved_line[cursor.y] then
							history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
							saved_line[cursor.y] = true
						end
						self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. tab_char .. line:sub(cursor.x))
						self:moveCursor(cursor, tab_len, 0)
						instrID.x, instrID.cy = instrID.x + tab_len, cursor.y
					end
				end
			end
			self:updateCursor(instr)
		end
		self:addUndo(history, cursor_history)
		self:setScrollPosX(self.scroll.pos_x)
		self.dirty = true; return true
	elseif key == keys.left then
		if self.snip then self.snip = nil end
		local cursors = self.cursors
		for id = 1, #cursors do
			local cursor = cursors[id]
			local selected = cursor.select
			if cursor.auto_closers then cursor.auto_closers = nil end
			local n_s
			if self.root.ctrl_held then
				local f = self:getLine(cursor.y):sub(1, cursor.x - 1):reverse()
				n_s = select(2, f:find('^%s*[%w_]+'))
				if not n_s then
					n_s = select(2, f:find('^%s*[^%w_%s]+'))
				end
			end
			if cursor.x > 1 or cursor.y > 1 then
				if selected and not self.root.shift_held then
					self:setCursor(cursor, selected.sX, cursor.y)
				else
					self:moveCursor(cursor, -1 - (n_s or 1) + 1, 0)
				end
			end
			if self.root.shift_held then
				self:selectText(cursor, cursor.cx, cursor.cy, cursor.x, cursor.y)
			else
				cursor.select = nil
			end
		end
		self.dirty = true
		self:updateCursor(); return true
	elseif key == keys.right then
		if self.snip then self.snip = nil end
		local cursors = self.cursors
		local lines_size = self:getLinesSize()
		for id = 1, #cursors do
			local cursor = cursors[id]
			local selected = cursor.select
			if cursor.auto_closers then cursor.auto_closers = nil end
			local n_s
			local line = self:getLine(cursor.y)
			if self.root.ctrl_held then
				local fragment = line:sub(cursor.x)
				n_s = select(2, fragment:find('^%s*[%w_]+'))
				if not n_s then
					n_s = select(2, fragment:find('^%s*[^%w_%s]+'))
				end
			end
			if cursor.x < #line + 1 or cursor.y < lines_size then
				if selected and not self.root.shift_held then
					self:setCursor(cursor, selected.eX + 1, cursor.y)
				else
					self:moveCursor(cursor, 1 + (n_s or 1) - 1, 0)
				end
			end
			if self.root.shift_held then
				self:selectText(cursor, cursor.cx, cursor.cy, cursor.x, cursor.y)
			else
				cursor.select = nil
			end
		end
		self.dirty = true
		self:updateCursor(); return true
	elseif key == keys.up then
		if self.snip then
			self.snip.select = math.max(1, self.snip.select - 1)
			self.snip.scroll = self.snip.select <= self.snip.scroll and self.snip.scroll - 1 or self.snip.scroll
			return true
		end
		local cursors = self.cursors
		-- local n = self:getLinesSize()
		if self.root.alt_held and self.root.ctrl_held then
			local total = #cursors
			local cursor = cursors[total]
			if total == 1 or cursors.current ~= cursor then
				local y = cursor.y - total
				if y == 1 then return true end
				local line = self:getLine(y)
				local x = self:visualToPhysical(line, cursor.x)
				-- local x = self:getVisualX(line, cursor.x)
				local new_cursor = {
					x = x,
					y = y,
					cx = cursor.cx,
					cy = cursor.y,
					preff_x =
						x
				}
				table.insert(cursors, 1, new_cursor)
				cursors.current = new_cursor
			else
				table.remove(cursors, total)
				cursors.current = cursors[#cursors]
				self.dirty = true
			end
			return true
		end
		local currentY
		local history, cursor_history = {}, {}
		local saved_lines = {}
		for id = 1, #cursors do
			local cursor = cursors[id]
			local select = cursor.select
			local cursor_copy = table_copy(cursor)
			cursor_copy.id = id
			cursor_history[#cursor_history + 1] = cursor_copy
			if cursor.auto_closers then cursor.auto_closers = nil end
			if cursor.y == 1 and cursor.x ~= 1 then cursor.preff_x = 1 end
			if self.root.alt_held then
				if self.root.shift_held then
					if select then
						local sY = currentY == select.sY and select.sY + 1 or select.sY
						local eY = currentY == select.sY and select.eY + 1 or select.eY
						for i = sY, select.eY do
							self:insertLine(sY, self:getLine(eY))
							history[#history + 1] = { name = 'deleteLine', y = sY }
						end
						currentY = select.eY
					elseif currentY ~= cursor.y then
						self:insertLine(cursor.y, self:getLine(cursor.y))
						history[#history + 1] = { name = 'deleteLine', y = cursor.y }
						currentY = cursor.y
					end
					goto continue
				else
					if select then
						if select.sY > 1 then
							local sY = select.sY == currentY and select.sY + 1 or select.sY
							local line = self:getLine(sY - 1)
							history[#history + 1] = { name = 'setLine', y = sY - 1, data = line }
							self:moveLines(sY, select.eY, sY - 1)
							history[#history + 1] = { name = 'moveLines', f = sY, e = select.eY, t = sY - 1, data = line }
							self:setLine(select.eY, line)
							currentY = select.eY
							select.sY, select.eY = select.sY - 1, select.eY - 1
							if select.sY < self.scroll.pos_y then
								self:scrollY(-1 / self.scroll.sens_y)
							end
						else
							goto continue
						end
					elseif cursor.y ~= 1 and cursor.y ~= currentY then
						local line = self:getLine(cursor.y - 1)
						history[#history + 1] = { name = 'setLine', y = cursor.y - 1, data = line }
						local _line = self:getLine(cursor.y)
						history[#history + 1] = { name = 'setLine', y = cursor.y, data = _line }
						self:setLine(cursor.y - 1, _line)
						self:setLine(cursor.y, line)
						currentY = cursor.y
					end
				end
			end
			self:moveCursor(cursor, 0, -1)
			if self.root.shift_held and not self.root.alt_held then
				self:selectText(cursor, cursor.x, cursor.y, cursor.cx, cursor.cy)
			elseif not self.root.alt_held then
				cursor.select = nil
			end
			::continue::
		end
		self.dirty = true
		self.scrollbar_v.dirty = true
		self.scrollbar_h.dirty = true
		if #history > 0 then self:addUndo(history, cursor_history) end
		self:updateCursor(); return true
	elseif key == keys.down then
		if self.snip then
			self.snip.select = math.min(#self.snip, self.snip.select + 1)
			local o = self.snip.scroll + 4
			self.snip.scroll = self.snip.select > o and self.snip.scroll + 1 or self.snip.scroll
			return true
		end
		local cursors = self.cursors
		local n = self:getLinesSize()
		if self.root.alt_held and self.root.ctrl_held then
			local total = #cursors
			local cursor = cursors[1]
			if total == 1 or cursors.current ~= cursor then
				local y = cursor.y + total
				if y == n then return true end
				local line = self:getLine(y)
				local x = self:visualToPhysical(line, cursor.x)
				local new_cursor = { x = x, y = y, cx = cursor.cx, cy = cursor.y, preff_x = x }
				cursors[total + 1] = new_cursor
				cursors.current = new_cursor
			else
				table.remove(cursors, 1)
				cursors.current = cursors[1]
				self.dirty = true
			end
			return true
		end
		local currentY, delta
		local instr = {}
		local history, cursor_history = {}, {}
		for id = #cursors, 1, -1 do
			local cursor = cursors[id]
			local select = cursor.select
			local cursor_copy = table_copy(cursor)
			cursor_copy.id = id
			cursor_history[#cursor_history + 1] = cursor_copy
			local instrID = { x = 0, y = 0 }
			instr[id] = instrID
			if cursor.auto_closers then cursor.auto_closers = nil end
			local last_line = self:getLine(n)
			if cursor.y == n and cursor.x ~= #last_line + 1 then cursor.preff_x = #last_line + 1 end
			if self.root.alt_held then
				if self.root.shift_held then
					if select then
						local eY = currentY == select.eY and select.eY - 1 or select.eY
						for i = eY, select.sY, -1 do
							self:insertLine(select.eY + 1, self:getLine(i))
							history[#history + 1] = { name = 'deleteLine', y = select.eY + 1 }
						end
						local deltaY = select.eY - select.sY + (delta or 1)
						if currentY ~= select.sY then
							delta = deltaY
							instrID.y = deltaY - 1
						end
						self:moveCursor(cursor, 0, deltaY)
						currentY = select.sY
						cursor.cy = cursor.cy + deltaY
						select.sY, select.eY = select.sY + deltaY, select.eY + deltaY
						goto continue
					else
						if currentY ~= cursor.y then
							self:insertLine(cursor.y + 1, self:getLine(cursor.y))
							history[#history + 1] = { name = 'deleteLine', y = cursor.y + 1 }
							currentY = cursor.y
						elseif delta then
							self:moveCursor(cursor, 0, delta - 1)
						end
					end
					self.scrollbar_v.dirty = true
					self.scrollbar_h.dirty = true
				else
					if select then
						if select.eY < n then
							local eY = currentY == select.eY and select.eY - 1 or select.eY
							local line = self:getLine(eY + 1)
							history[#history + 1] = { name = 'setLine', y = eY + 1, data = line }
							self:moveLines(select.sY, eY, select.sY + 1)
							history[#history + 1] = {
								name = 'moveLines', f = select.sY, e = eY, t = select.sY + 1, data = line }
							self:setLine(select.sY, line)
							if select.eY > self.h + self.scroll.pos_y then
								self:scrollY(1 / self.scroll.sens_y)
							end
							currentY = select.sY
							select.eY, select.sY = select.eY + 1, select.sY + 1
						else
							goto continue
						end
					elseif cursor.y ~= n and cursor.y ~= currentY then
						local line = self:getLine(cursor.y + 1)
						history[#history + 1] = { name = 'setLine', y = cursor.y + 1, data = line }
						local _line = self:getLine(cursor.y)
						history[#history + 1] = { name = 'setLine', y = cursor.y, data = _line }
						self:setLine(cursor.y + 1, _line)
						self:setLine(cursor.y, line)
						currentY = cursor.y
					end
				end
			end

			self:moveCursor(cursor, 0, 1)
			if self.root.shift_held and not self.root.alt_held then
				self:selectText(cursor, cursor.x, cursor.y, cursor.cx, cursor.cy)
			elseif not self.root.alt_held then
				cursor.select = nil
			end
			::continue::
		end
		self.dirty = true
		self.scrollbar_v.dirty = true
		self.scrollbar_h.dirty = true
		if #history > 0 then self:addUndo(history, cursor_history) end
		self:updateCursor(instr); return true
	elseif key == keys.backspace then
		local cursors = self.cursors
		local instr, history = {}, {}
		local saved_line = {}
		local cursor_history = {}
		for id = #cursors, 1, -1 do
			local cursor = cursors[id]
			local select = cursor.select
			if cursor.auto_closers then cursor.auto_closers = nil end
			local cursor_copy = table_copy(cursor)
			cursor_copy.id = id
			cursor_history[#cursor_history + 1] = cursor_copy
			local instrID = { x = 0, y = 0 }
			instr[id] = instrID
			if select then
				local sy, ey = select.sY, select.eY
				instrID.y = sy - ey
				instrID.x = instrID.x + select.sX - (select.eX + 1)
				local delete_history = self:deleteSelected(cursor)
				if sy ~= ey then
					if saved_line[sy] then
						table.remove(delete_history, 1)
					end
					if saved_line[ey] then
						table.remove(delete_history, #delete_history)
						history[#history].name = 'insertLine'
					end
				end
				saved_line[sy] = true
				for i = 1, #delete_history do
					history[#history + 1] = delete_history[i]
				end
			else
				local line = self:getLine(cursor.y)
				if cursor.x == 1 and cursor.y > 1 then
					self:setCursor(cursor, math.huge, cursor.y - 1)
					local current_line = self:getLine(cursor.y)
					self:setLine(cursor.y, current_line .. line)
					if not saved_line[cursor.y] then
						history[#history + 1] = { name = 'setLine', y = cursor.y, data = current_line }
						saved_line[cursor.y] = true
					end
					history[#history + 1] = { name = 'insertLine', y = cursor.y + 1, data = self:deleteLine(cursor.y + 1) }
					self:setScrollPosX(math.max(self.scroll.pos_x - 1, 0))
					instrID.y = instrID.y - 1
					instrID.x = instrID.x + cursor.x - 1
				elseif cursor.x > 1 then
					if not saved_line[cursor.y] then
						history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
						saved_line[cursor.y] = true
					end
					self:setLine(cursor.y, line:sub(1, math.max(cursor.x - 2, 0)) .. line:sub(cursor.x, #line))
					self:moveCursor(cursor, -1, 0)
					self:setScrollPosX(math.max(self.scroll.pos_x - 1, 0))
					if self.onCharAction then self:onCharAction() end
					instrID.x = instrID.x - 1
				end
			end
			instrID.cy = cursor.y
		end
		self:addUndo(history, cursor_history)
		self:updateCursor(instr)
		self.dirty = true; return true
	elseif key == keys.delete then
		-- self.auto_closers = {}
		local clipboard = {}
		local instr, history = {}, {}
		local cursors = self.cursors
		local saved_line = {}
		local cursor_history = {}
		local n = self:getLinesSize()
		for id = #cursors, 1, -1 do
			local cursor = cursors[id]
			local select = cursor.select
			if cursor.auto_closers then cursor.auto_closers = nil end
			local cursor_copy = table_copy(cursor)
			cursor_copy.id = id
			cursor_history[#cursor_history + 1] = cursor_copy
			local instrID = { x = 0, y = 0 }
			instr[id] = instrID
			local line = self:getLine(cursor.y)
			if self.root.shift_held then
				if select then
					local sy, ey = select.sY, select.eY
					instrID.y = instrID.y + (sy - ey)
					instrID.x = instrID.x + select.sX - (select.eX + 1)

					clipboard[#clipboard + 1] = self:copySelected(cursor)
					local deleted_history = self:deleteSelected(cursor)
					if sy ~= ey then
						if saved_line[sy] then
							table.remove(deleted_history, 1)
						end
						if saved_line[ey] then
							table.remove(deleted_history, #deleted_history)
							history[#history].name = 'insertLine'
						end
					end
					saved_line[sy] = true
					for i = 1, #deleted_history do
						history[#history + 1] = deleted_history[i]
					end
					n = self:getLinesSize()
				elseif line then
					if n <= 1 then
						self:setLine(cursor.y, '')
						history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
						clipboard[#clipboard + 1] = line
					else
						instrID.y = instrID.y - 1
						local deleted_line = self:deleteLine(cursor.y)
						history[#history + 1] = { name = 'insertLine', y = cursor.y, data = deleted_line }
						clipboard[#clipboard + 1] = deleted_line
						n = self:getLinesSize()
					end
					self:setCursor(cursor, 1, cursor.y)
				end
			elseif select then
				local sy, ey = select.sY, select.eY
				instrID.y = instrID.y + (sy - ey)
				instrID.x = instrID.x + select.sX - (select.eX + 1)
				local deleted_history = self:deleteSelected(cursor)
				if sy ~= ey then
					if saved_line[sy] then
						table.remove(deleted_history, 1)
					end
					if saved_line[ey] then
						table.remove(deleted_history, #deleted_history)
						history[#history].name = 'insertLine'
					end
				end
				saved_line[sy] = true
				for i = 1, #deleted_history do
					history[#history + 1] = deleted_history[i]
				end
			else
				if cursor.x == #line + 1 and self.document.lines[cursor.y + 1] then
					instrID.y = instrID.y - 1
					instrID.x = instrID.x + cursor.x - 1
					local prev_line = self:deleteLine(cursor.y + 1)
					history[#history + 1] = { name = 'insertLine', y = cursor.y + 1, data = prev_line }
					history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
					self:setLine(cursor.y, line .. prev_line)
					self:setScrollPosX(math.max(self.scroll.pos_x - 1, 0))
				else
					if not saved_line[cursor.y] then
						history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
						saved_line[cursor.y] = true
					end
					self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. line:sub(cursor.x + 1, #line))
					instrID.x = instrID.x - 1
				end
			end
			instrID.cy = cursor.y
		end
		if #clipboard > 0 then
			self.root.clipboard = {
				type = 'text',
				data = table.concat(clipboard, '\n')
			}
		end
		self:addUndo(history, cursor_history)
		self:updateCursor(instr)
		self.dirty = true; return true
	elseif key == keys.enter then
		local cursors = self.cursors
		local instr, history = {}, {}
		local saved_line = {}
		local cursor_history = {}
		if self.snip then
			local main_cursor = cursors.current
			local c_line = self:getLine(main_cursor.y)
			local s_x, e_x = c_line:sub(1, main_cursor.x - 1):find('[%w_]*$')
			local obrubok = e_x - s_x + 1
			local insert_str = self.snip[self.snip.select]:sub(obrubok + 1)
			for id = #cursors, 1, -1 do
				local cursor = cursors[id]
				local cursor_copy = table_copy(cursor)
				cursor_copy.id = id
				cursor_history[#cursor_history + 1] = cursor_copy
				local instrID = { x = 0, y = 0 }
				instr[id] = instrID
				local line = self:getLine(cursor.y)
				if not saved_line[cursor.y] then
					history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
					saved_line[cursor.y] = true
				end
				line = line:sub(1, cursor.x - 1) .. insert_str .. line:sub(cursor.x)
				self:setLine(cursor.y, line)
				self:moveCursor(cursor, #insert_str, 0)
				instrID.x, instrID.cy = instrID.x + #insert_str, cursor.y
			end
			self.snip = nil
		else
			local tab_char = user.indent_tabs and '\t' or (' '):rep(self.TabSize)
			for id = #cursors, 1, -1 do
				local cursor = cursors[id]
				local cursor_copy = table_copy(cursor)
				cursor_copy.id = id
				cursor_history[#cursor_history + 1] = cursor_copy
				local select = cursor.select
				local instrID = { x = 0, y = 0 }
				instr[id] = instrID
				if select then
					local sy, ey = select.sY, select.eY
					instrID.y = instrID.y + (sy - ey)
					-- instrID.x = select.sX - (select.eX + 1)
					local delete_history = self:deleteSelected(cursor)
					if sy ~= ey then
						if saved_line[sy] then
							table.remove(delete_history, 1)
						end
						if saved_line[ey] then
							table.remove(delete_history, #delete_history)
							history[#history].name = 'insertLine'
						end
					end
					saved_line[sy] = true
					for i = 1, #delete_history do
						history[#history + 1] = delete_history[i]
					end
				end
				instrID.y = instrID.y + 1
				local next_line = self:getLine(cursor.y + 1) or ''
				local line = self:getLine(cursor.y)
				if not saved_line[cursor.y] then
					history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
					saved_line[cursor.y] = true
				end
				history[#history + 1] = { name = 'deleteLine', y = cursor.y }

				local prev_tab_pos = line:match('^[ \t]*()') or 1
				local prev_tabs_count = math.floor(self:getVisualX(line, prev_tab_pos) / self.TabSize)

				local next_tab_pos = next_line:match('^[ \t]*()') or 1
				local next_tabs_count = math.floor(self:getVisualX(next_line, next_tab_pos) / self.TabSize)

				local tabs_count = math.max(prev_tabs_count, next_tabs_count)
				local insert_tabs = tab_char:rep(tabs_count)

				self:insertLine(cursor.y + 1, insert_tabs .. line:sub(cursor.x))
				local new_line = line:sub(1, cursor.x - 1)
				self:setLine(cursor.y, new_line)
				self:setCursor(cursor, tabs_count + 1, cursor.y + 1)
				instrID.cy = cursor.y
			end
		end
		self:addUndo(history, cursor_history)
		self:updateCursor(instr)
		self.dirty = true; return true
	elseif key == keys.leftShift or key == keys.rightShift then
		if held then return true end
		local cursors = self.cursors
		for id = 1, #cursors do
			local cursor = cursors[id]
			if not cursor.select then
				cursor.cx, cursor.cy = cursor.x, cursor.y
			end
		end
	elseif key == keys.home then
		if held then return true end
		local cursors = self.cursors
		for id = 1, #cursors do
			local cursor = cursors[id]
			self:setCursor(cursor, 1, cursor.y)
			if self.root.shift_held then
				self:selectText(cursor, 1, cursor.y, cursor.cx, cursor.cy)
			else
				cursor.select = nil
			end
		end
		self.dirty = true
	elseif key == keys["end"] then
		if held then return true end
		local cursors = self.cursors
		for id = 1, #cursors do
			local cursor = cursors[id]
			if cursor.auto_closers then cursor.auto_closers = nil end
			local line = self:getLine(cursor.y)
			self:setCursor(cursor, #line + 1, cursor.y)
			if self.root.shift_held then
				self:selectText(cursor, #line + 1, cursor.y, cursor.cx, cursor.cy)
			else
				cursor.select = nil
			end
		end
		self.dirty = true
	elseif key == keys.pageDown then
		local cursors = self.cursors
		local new_scroll = self:getScrollPosY() + self.h
		for id = 1, #cursors do
			local cursor = cursors[id]
			self:moveCursor(cursor, 0, self.h)
			if self.root.shift_held then
				self:selectText(cursor, cursor.cx, cursor.cy, cursor.x, cursor.y)
			else
				cursor.select = nil
			end
		end
		self:setScrollPosY(new_scroll)
		self:updateCursor()
		self.dirty = true
	elseif key == keys.pageUp then
		local cursors = self.cursors
		local new_scroll = self:getScrollPosY() - self.h
		for id = 1, #cursors do
			local cursor = cursors[id]
			self:moveCursor(cursor, 0, -self.h)
			if self.root.shift_held then
				self:selectText(cursor, cursor.cx, cursor.cy, cursor.x, cursor.y)
			else
				cursor.select = nil
			end
		end
		self:setScrollPosY(new_scroll)
		self:updateCursor()
		self.dirty = true
	elseif key == keys.f then
		if not self.root.ctrl_held then return true end
		if self.onCommand then self:onCommand('Find') end
		-- self.root.ctrl_held = nil
	elseif key == keys.g then
		if not self.root.ctrl_held then return true end
		if self.onCommand then self:onCommand('Go To Line') end
		-- self.root.ctrl_held = nil
	elseif key == keys.y then
		if not self.root.ctrl_held then return true end
		if self.snip then self.snip = nil end
		self:redo()
	elseif key == keys.z then
		if not self.root.ctrl_held then return true end
		if self.snip then self.snip = nil end
		self:undo()
	elseif key == keys.slash then
		if not self.root.ctrl_held then return true end
		local history, cursor_history = {}, {}
		local saved_line = {}
		local cursors = self.cursors
		for id = #cursors, 1, -1 do
			local cursor = cursors[id]
			local cursor_copy = table_copy(cursor)
			cursor_copy.id = id
			cursor_history[#cursor_history + 1] = cursor_copy
			local select = cursor.select
			if select then
				local have_commented = false
				local all_commented = true
				local minimal_pos = math.huge
				for i = select.sY, select.eY do
					local line = self:getLine(i)
					if not saved_line[i] then
						history[#history + 1] = { name = 'setLine', y = i, data = line }
						saved_line[i] = true
					end
					local fPos = line:match('^[ \t]*()%-%- ?')
					if fPos then
						minimal_pos = minimal_pos <= fPos and minimal_pos or fPos
						have_commented = true
					elseif line ~= '' then
						local value = line:find('[^ \t]') or 1
						minimal_pos = minimal_pos <= value and minimal_pos or value
						all_commented = false
					end
				end
				if have_commented and all_commented then
					for i = select.sY, select.eY do
						local line = self:getLine(i)
						if not saved_line[i] then
							history[#history + 1] = { name = 'setLine', y = i, data = line }
							saved_line[i] = true
						end
						local sub_start, sub_end = line:match('^[ \t]*()%-%- ?()')
						if sub_start and sub_end then
							if i == select.sY and sub_start <= select.sX then
								select.sX = select.sX - (sub_end - sub_start)
							end
							if i == select.eY and sub_start <= select.eX then
								select.eX = select.eX - (sub_end - sub_start)
							end
							if i == cursor.y and sub_start <= cursor.x then
								self:setCursor(cursor, cursor.x - (sub_end - sub_start), cursor.y)
							end
							if i == cursor.cy and sub_start <= cursor.cx then
								cursor.cx = cursor.cx - (sub_end - sub_start)
							end
							line = line:sub(1, sub_start - 1) .. line:sub(sub_end, -1)
							self:setLine(i, line)
						end
					end
				else
					for i = select.sY, select.eY do
						local line = self:getLine(i)
						if not saved_line[i] then
							history[#history + 1] = { name = 'setLine', y = i, data = line }
							saved_line[i] = true
						end
						if line ~= '' then
							line = line:sub(1, minimal_pos - 1) .. '-- ' .. line:sub(minimal_pos, -1)
							self:setLine(i, line)
						end
					end
					if minimal_pos <= select.sX then
						select.sX = select.sX + 3
					end
					if minimal_pos <= select.eX then
						select.eX = select.eX + 3
					end
					if minimal_pos <= cursor.x then
						self:moveCursor(cursor, 3, 0)
					end
					if minimal_pos <= cursor.cx then
						cursor.cx = cursor.cx + 3
					end
				end
			else
				local line = self:getLine(cursor.y)
				if not saved_line[cursor.y] then
					history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
					saved_line[cursor.y] = true
				end
				local start_x, end_x = line:match('^[ \t]*()%-%- ?()')
				if start_x then
					line = line:sub(1, start_x - 1) .. line:sub(end_x, -1)
					self:setLine(cursor.y, line)
					if cursor.x > end_x then
						self:setCursor(cursor, cursor.x - (end_x - start_x), cursor.y)
					elseif cursor.x >= start_x then
						self:setCursor(cursor, start_x, cursor.y)
					end
				else
					start_x = line:find('[^ \t]')
					if start_x then
						line = line:sub(1, start_x - 1) .. '-- ' .. line:sub(start_x, -1)
						if cursor.x >= start_x then
							self:setCursor(cursor, cursor.x + 3, cursor.y)
						end
					else
						line = line .. '-- '
						self:setCursor(cursor, cursor.x + 3, cursor.y)
					end
					self:setLine(cursor.y, line)
				end
			end
		end
		self:addUndo(history, cursor_history)
		self:updateCursor()
		self.dirty = true; return true
	elseif key == keys.a then
		if not self.root.ctrl_held then return true end
		local n_y = self:getLinesSize()
		local line = self:getLine(n_y)
		local x = #line + 1
		local cursor = { x = x, y = n_y, cx = x, cy = n_y, preff_x = self:getVisualX(line, x) }
		self.cursors = {
			cursor,
			blink = self.cursors.blink,
			-- color = self.cursors.color,
			panel = self.cursors.panel,
			current = cursor
		}
		self:selectText(cursor, 1, 1, cursor.x, cursor.y)
	elseif key == keys.insert then
		if not self.root.shift_held then return true end
		if self.root.clipboard.type == 'text' then self:onPaste(self.root.clipboard.data) end
	elseif key == keys.c then
		if not self.root.ctrl_held then return true end
		local cursors, clipboard = self.cursors, {}
		for id = 1, #cursors do
			clipboard[#clipboard + 1] = self:copySelected(cursors[id])
		end
		if #clipboard > 0 then
			self.root.clipboard = {
				type = 'text',
				data = table.concat(clipboard, '\n')
			}
		end
		return true
	elseif key == keys.x then
		if not self.root.ctrl_held then return true end
		local cursors = self.cursors
		local instr, clipboard, history = {}, {}, {}
		local cursor_history = {}
		for id = #cursors, 1, -1 do
			local cursor = cursors[id]
			local select = cursor.select
			local cursor_copy = table_copy(cursor)
			cursor_copy.id = id
			cursor_history[#cursor_history + 1] = cursor_copy
			local instrID = { x = 0, y = 0 }
			instr[id] = instrID
			clipboard[#clipboard + 1] = self:copySelected(cursor)
			if select then
				instrID.y = select.sY - select.eY
				instrID.x = instrID.x + select.sX - (select.eX + 1)
				local delete_history = self:deleteSelected(cursor)
				-- if sy ~= ey then
				-- if saved_line[sy] then
				-- table.remove(delete_history, 1)
				-- end
				-- if saved_line[ey] then
				-- table.remove(delete_history, #delete_history)
				-- history[#history].name = 'insertLine'
				-- end
				-- end
				-- saved_line[sy] = true
				for i = 1, #delete_history do
					history[#history + 1] = delete_history[i]
				end
			end
			instrID.cy = cursor.y
		end
		if #clipboard > 0 then
			self.root.clipboard = {
				type = 'text',
				data = table.concat(clipboard, '\n')
			}
		end
		self:addUndo(history, cursor_history)
		self:updateCursor(instr)
		self.dirty = true; return true
	-- elseif key == keys.s then
	-- 	if not self.root.ctrl_held then return true end


	-- 	-- self.lines[#self.lines + 1] = ''

	-- 	if self.onCommand then self:onCommand('Save') end
	-- 	self:onSave()
	end

	return true
end

local function editor_onPaste(self, char)
	self.scroll.max_x_cached = nil
	local cursors = self.cursors
	local instr, history = {}, {}
	local saved_line, cursor_history = {}, {}
	for id = #cursors, 1, -1 do
		local cursor = cursors[id]
		-- if cursor.auto_closers then cursor.auto_closers = nil end
		local select = cursor.select
		local cursor_copy = table_copy(cursor)
		cursor_copy.id = id
		cursor_history[#cursor_history + 1] = cursor_copy
		local instrID = { x = 0, y = 0 }
		instr[id] = instrID
		if select then
			local sy, ey = select.sY, select.eY
			instrID.y = sy - ey
			instrID.x = instrID.x + select.sX - (select.eX + 1)
			local delete_history = self:deleteSelected(cursor)
			if sy ~= ey then
				if saved_line[sy] then
					table.remove(delete_history, 1)
				end
				if saved_line[ey] then
					table.remove(delete_history, #delete_history)
					history[#history].name = 'insertLine'
				end
			end
			saved_line[sy] = true
			for i = 1, #delete_history do
				history[#history + 1] = delete_history[i]
			end
		end
		local line = self:getLine(cursor.y)
		local i = 0
		local reminder
		for t_line in char:gmatch("[^\n]+") do
			if i == 0 then
				reminder = line:sub(cursor.x)
				self:setLine(cursor.y, line:sub(1, cursor.x - 1) .. t_line)
				if not saved_line[cursor.y] then
					history[#history + 1] = { name = 'setLine', y = cursor.y, data = line }
					saved_line[cursor.y] = true
				end
			else
				instrID.y = instrID.y + 1
				self:insertLine(cursor.y + i, t_line)
				history[#history + 1] = { name = 'deleteLine', y = cursor.y + i }
			end
			i = i + 1
		end
		local prev_line = self:getLine(cursor.y + i - 1)
		if not prev_line then return true end
		local t = prev_line .. reminder
		self:setLine(cursor.y + i - 1, t)
		if not saved_line[cursor.y + i - 1] then
			history[#history + 1] = { name = 'setLine', y = cursor.y + i - 1, data = t }
			saved_line[cursor.y + i - 1] = true
		end
		local x = cursor.x
		self:setCursor(cursor, #prev_line + 1, cursor.y + i - 1)
		instrID.x, instrID.cy = instrID.x + cursor.x - x, cursor.y
	end
	self:addUndo(history, cursor_history)
	self:updateCursor(instr)
	self.dirty = true; return true
end

local function editor_onSave(self)
	self:invalidateCacheFrom(1)
	self:cleanCache()
	for i = #self.cursors, 1, -1 do
		local cursor = self.cursors[i]
		self:setCursor(cursor, cursor.x, cursor.y)
	end
	self.scrollbar_v.dirty = true
	self.scrollbar_h.dirty = true
	self.dirty = true
end

local function editor_setDisabled(self, bool)
	expect(bool, 'bool', 'boolean', 'nil')
	self.disabled = bool
	self.dirty = true
end

local function editor_onEvent(self, event, data)
	if event == 'timer' and data[1] == self.timer_id then
		self.timer_id = nil; return true
	end
	return self:oldEvent(event, data)
end

function _editor.new(args)
	local instance = UI.Widget(args)

	instance.tokenCache = {}                                                       -- { [lineNum] = {tokens = {}, stateIn = {}, stateOut = {} } }
	instance.dirtyLines = setmetatable({}, { __index = function() return false end }) -- Флаги dirty
	instance.indent_tabs = args.indent_tabs
	instance.document = args.document
	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.black
	-- instance.instructions = {}
	-- instance.fg_selected = expect_args(args, 'fg_selected', 'number', 'nil') or instance.fg
	-- instance.bg_selected = expect_args(args, 'bg_selected', 'number', 'nil') or colors.blue
	ScrollMixin.addMixin(instance)
	instance:initScroll(expect_args(args, 'sens_x', 'integer', 'nil'), expect_args(args, 'sens_y', 'integer', 'nil'))
	instance.TabSize = args.TabSize or 4
	instance.lines = { "" }
	instance.undo_history = {}
	instance.redo_history = {}
	local first_cursor = { x = 1, y = 1, cx = 1, cy = 1, preff_x = 1 }
	instance.cursors = {
		first_cursor,
		blink = true,
		color = (user.color_editor_cursor or colors.white),
		current = first_cursor
	}

	instance.draw = editor_draw
	instance.invalidateCacheFrom = editor_invalidateCacheFrom
	instance.getVisualX = editor_getVisualX
	instance.cleanCache = editor_cleanCache
	instance.selectText = editor_selectText
	instance.onFocus = editor_onFocus
	instance.moveCursor = editor_moveCursor
	instance.setCursor = editor_setCursor
	instance.updateCursor = editor_updateCursor
	instance.redo = editor_redo
	instance.undo = editor_undo
	instance.addUndo = editor_addUndo
	instance.deleteSelected = editor_deleteSelected
	instance.focusPostDraw = editor_focusPostDraw
	instance.copySelected = editor_copySelected
	instance.visualToPhysical = editor_visualToPhysical
	instance.convert_tabs = editor_convert_tabs
	instance.getLinesSize = editor_getLinesSize
	instance.oldEvent = instance.onEvent
	instance.onEvent = editor_onEvent
	instance.setLine = editor_setLine
	instance.moveLines = editor_moveLines
	instance.getLine = editor_getLine
	instance.deleteLine = editor_deleteLine
	instance.insertLine = editor_insertLine
	instance.getScrollMaxX = editor_getScrollMaxX
	instance.updateDirty = editor_updateDirty
	instance.setDisabled = editor_setDisabled
	instance.getScrollMaxY = editor_getScrollMaxY
	instance.onMouseDown = editor_onMouseDown
	instance.onMouseDrag = editor_onMouseDrag
	instance.onMouseUp = editor_onMouseUp
	instance.onMouseScroll = editor_onMouseScroll
	-- instance.onKeyUp = editor_onKeyUp
	instance.onKeyDown = editor_onKeyDown
	instance.onCharTyped = editor_onCharTyped
	instance.onPaste = editor_onPaste
	instance.onSave = editor_onSave

	return instance
end

return _editor

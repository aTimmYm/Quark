local Widget = require 'Text.Widget'
local Utils = require 'Utils'
local clamp = Utils.clamp
local expect_args = Utils.expect_args
local expect = Utils.expect
local ScrollMixin = require 'Mixins.ScrollMixin'

local TextBox = {}

function TextBox:convert_tabs(str)
	return str:gsub("([^\t]*)\t", function(text)
		local spaces = self.TabSize - (#text % self.TabSize)
		return text .. '\t' .. (" "):rep(spaces - 1)
	end)
end

function TextBox:getVisualX(line, physicalX)
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

local to_hex = {}
do
	local hex = '0123456789abcdef'
	for i = 1, 16 do
		to_hex[i - 1] = hex:sub(i, i)
	end
end

-- DEPRECATED: use self:copySelectedText()
-- function TextBox:getSelectedText()
-- 	if not self.selected.status then return false end
-- 	local selected_lines = {}
-- 	if self.selected.sY ~= self.selected.eY then
-- 		selected_lines[#selected_lines + 1] = self.lines[self.selected.sY]:sub(self.selected.sX, -1)
-- 		for line_index = self.selected.sY + 1, self.selected.eY - 1 do
-- 			selected_lines[#selected_lines + 1] = self.lines[line_index]
-- 		end
-- 		selected_lines[#selected_lines + 1] = self.lines[self.selected.eY]:sub(1, self.selected.eX)
-- 		-- return selected_lines
-- 		return table.concat(selected_lines, '\n')
-- 	else
-- 		-- return {self.lines[self.selected.sY]:sub(self.selected.sX, self.selected.eX)}
-- 		return self.lines[self.selected.sY]:sub(self.selected.sX, self.selected.eX)
-- 	end
-- end

function TextBox:deleteSelectedText()
	local selected = self.selected
	if selected.status and self.lines[1] then
		if selected.sY ~= selected.eY then
			local new_line = self.lines[self.selected.sY]:sub(1, selected.sX - 1)
			local line = self.lines[selected.eY]
			new_line = new_line .. line:sub(selected.eX + 1, #line)
			for i = selected.sY, selected.eY do
				table.remove(self.lines, selected.sY)
			end
			self:setLine(new_line, selected.sY)
		else
			local line = self.lines[selected.sY]
			self:setLine(line:sub(1, selected.sX - 1) .. line:sub(selected.eX + 1, #line), selected.sY)
		end
		self:moveCursorPos(selected.sX, selected.sY)
		selected.status = false
		return true
	end
	return false
end

function TextBox:selectText(from_x, from_y, to_x, to_y)
	local selected = self.selected
	if from_x == to_x and from_y == to_y then
		selected.status = false
		self.dirty = true; return
	end
	if (to_x < from_x and to_y == from_y) or to_y < from_y then
		selected.sX, selected.sY = to_x, to_y
		selected.eX, selected.eY = from_x - 1, from_y
	else
		selected.sX, selected.sY = from_x, from_y
		selected.eX, selected.eY = to_x - 1, to_y
	end
	if selected.eX == 0 then
		selected.eY = math.max(1, selected.eY - 1)
		selected.eX = #self.lines[selected.eY]
	end
	selected.status = true
	self.dirty = true
end

function TextBox:draw()
	local scroll = self.scroll

	local visible_start = scroll.pos_y + 1
	local visible_end = math.min(self.h + scroll.pos_y, #self.lines)

	local draw_lines = {}

	local self_fg = to_hex[self.fg]
	local self_bg = to_hex[self.bg]
	for i = visible_start, visible_end do
		local str = self:convert_tabs((self.lines[i] or ""))
		local nLine = #str
		draw_lines[i] = {
			str,
			self_fg:rep(nLine),
			self_bg:rep(nLine)
		}
	end

	if self.selected.status then
		local selected = self.selected
		local selected_fg = to_hex[self.fg_selected]
		local selected_bg = to_hex[self.bg_selected]
		local x1 = self:getVisualX(self.lines[selected.sY], selected.sX)
		local x2 = self:getVisualX(self.lines[selected.eY], selected.eX)
		for i = selected.sY, selected.eY do
			local line = draw_lines[i]
			if line then
				local line_str = line[1]
				local line_fg = line[2]
				local line_bg = line[3]

				local sel_x_start = i == selected.sY and x1 or 1
				local sel_x_end = i == selected.eY and x2 or #line_str
				if sel_x_start <= sel_x_end + 1 then
					if self.lines[selected.eY]:byte(selected.eX) == 9 then
						sel_x_end = sel_x_end + (self.TabSize - ((sel_x_end - 1) % self.TabSize)) - 1
					end
					local sel_text = line_str:sub(sel_x_start, sel_x_end)
					if #line_str == 0 and i ~= selected.eY and i ~= selected.sY then sel_text = " " end

					local sub_start = sel_x_start - 1
					local sub_end = sel_x_end + 1

					line[1] = line_str:sub(1, sub_start) .. sel_text .. line_str:sub(sub_end, -1)
					line[2] = line_fg:sub(1, sub_start) .. selected_fg:rep(#sel_text) .. line_fg:sub(sub_end, -1)
					line[3] = line_bg:sub(1, sub_start) .. selected_bg:rep(#sel_text) .. line_bg:sub(sub_end, -1)
				end
			end
		end
	end

	local start_sub, end_sub = scroll.pos_x + 1, scroll.pos_x + self.w
	local rep_len = scroll.pos_x + self.w
	local draw_y = self.y - visible_start

	local draw_str = (' '):rep(rep_len)
	local draw_fg = ('0'):rep(rep_len)
	local draw_bg = self_bg:rep(rep_len)
	for i = visible_start, visible_end do
		local line = draw_lines[i]
		term.setCursorPos(self.x, draw_y + i)
		term.blit((line[1] .. draw_str):sub(start_sub, end_sub),
			(line[2] .. draw_fg):sub(start_sub, end_sub),
			(line[3] .. draw_bg):sub(start_sub, end_sub))
	end

	if visible_end < self.h then
		local empty_str = (' '):rep(self.w)
		local empty_fg = self_fg:rep(self.w)
		local empty_bg = self_bg:rep(self.w)
		-- Тут должен быть for visible_end + 1, self.h do, но в математике внутри цикла получается i - 1
		-- так что я сдвигаю for на -1:
		for i = visible_end, self.h - 1 do
			term.setCursorPos(self.x, self.y + i)
			term.blit(empty_str, empty_fg, empty_bg)
		end
	end
end

function TextBox:setLine(string, number)
	self.lines[number] = string
	self:updateDirty()
end

function TextBox:moveCursorPos(posX, posY)
	posY = clamp(posY, 1, #self.lines)
	local current_lines = self.lines[posY]
	posX = clamp(posX, 1, #(current_lines or "") + 1)
	local cursor = self.cursor

	cursor.y = posY
	if posY - self.scroll.pos_y > self.h then
		self:setScrollPosY(posY - self.h)
	elseif posY - self.scroll.pos_y < 1 then
		self:setScrollPosY(posY - 1)
	end

	cursor.x = posX
	local visual_x = self:getVisualX(current_lines, posX)
	if visual_x - self.scroll.pos_x > self.w then
		self:setScrollPosX(visual_x - self.w)
	elseif visual_x - self.scroll.pos_x < 1 then
		self:setScrollPosX(visual_x - 1)
	end
end

function TextBox:clear()
	self.lines = { "" }
	self.cursor = { x = 1, y = 1 }
	self.scroll.pos_y = 0
	self.scroll.pos_x = 0
	self.dirty = true
end

function TextBox:focusPostDraw()
	local cursor = self.cursor
	local y = self.y - self.scroll.pos_y + cursor.y - 1
	local line = self.lines[cursor.y]
	local offset = self:getVisualX(line, cursor.x)
	local x = self.x - self.scroll.pos_x + offset - 1
	if not self:check(x, y) then
		term.setCursorBlink(false)
	else
		term.setCursorPos(x, y)
		term.setTextColor(self.selected.status and colors.red or colors.blue)
		term.setCursorBlink(true)
	end
end

function TextBox:onFocus(focused)
	term.setCursorBlink(focused)
	if not focused then
		self.selected.status = false
		self.dirty = true
	end
end

function TextBox:onCharTyped(chr)
	chr = chr == '\000' and '?' or chr
	self:deleteSelectedText()
	local y = self.cursor.y
	local x = self.cursor.x
	local line = self.lines[y]
	line = line or ""
	self.lines[y] = line:sub(1, x - 1) .. chr .. line:sub(x, #line)
	self.scroll.max_x_cached = nil
	self:moveCursorPos(x + #chr, y)
	self.dirty = true
	return true
end

function TextBox:visualToPhysical(line, visual_x)
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

function TextBox:onMouseDown(btn, x, y)
	local selected, cursor = self.selected, self.cursor
	local v_x = x - self.x + self.scroll.pos_x + 1
	local v_y = y - self.y + self.scroll.pos_y + 1
	local line = self.lines[v_y]
	if not line then
		self:moveCursorPos(math.huge, math.huge)
		self.click = { x = cursor.x, y = cursor.y }; return true
	end
	local p_x = self:visualToPhysical(line, v_x)
	self:moveCursorPos(p_x, v_y)

	if self.shift_held then
		self:selectText(self.click.x, self.click.y, cursor.x, cursor.y)
	else
		-- double click logic:
		if self.timer_id and self.click.x and self.click.y then
			os.cancelTimer(self.timer_id)
			self.timer_id = nil
			if self.click.x == p_x and self.click.y == cursor.y then
				local firstPos = line:sub(1, p_x):find("[%w_]+$")
				local relativeEnd = select(2, line:sub(p_x):find("^[%w_]+"))

				if firstPos and relativeEnd then
					local lastPos = p_x + relativeEnd - 1
					self:moveCursorPos(lastPos + 1, cursor.y)
					self:selectText(firstPos, cursor.y, cursor.x, cursor.y)
				else
					self:moveCursorPos(p_x + 1, cursor.y)
					self:selectText(p_x, cursor.y, cursor.x, cursor.y)
				end

				self.click = { x = firstPos or p_x, y = cursor.y }
				self.selected.status = true
				self.dirty = true
				return true
			end
		end
		local cx, cy = cursor.x, cursor.y
		self.click = { x = cx, y = cy }
		selected.sX, selected.sY = cx, cy
		selected.eX, selected.eY = cx, cy
		selected.status = false
	end
	self.dirty = true
	self.timer_id = os.startTimer(0.5) -- double click delay
	return true
end

function TextBox:onMouseDrag(btn, x, y)
	local click = self.click
	-- local nY = clamp(y - self.y + 1 + self.scroll.pos_y, 1, #self.lines)
	local nY = math.max(y - self.y + 1 + self.scroll.pos_y, 1)
	local line = self.lines[nY]
	if not line then return true end
	local nX = self:visualToPhysical(line, x - self.x + 1 + self.scroll.pos_x)

	self:moveCursorPos(nX, nY)
	self:selectText(click.x, click.y, self.cursor.x, self.cursor.y)
	return true
end

function TextBox:onMouseScroll(dir, x, y)
	if self.shift_held then
		return self:scrollX(dir)
	end
	return self:scrollY(dir)
end

function TextBox:onKeyUp(key)
	if key == keys.leftShift or key == keys.rightShift then
		self.shift_held = nil
	elseif key == keys.leftCtrl or key == keys.rightCtrl then
		self.ctrl_held = nil
	elseif key == keys.leftAlt or key == keys.rightAlt then
		self.alt_held = nil
	end
	return true
end

function TextBox:copySelectedText()
	local copy = {}
	local selected = self.selected
	if selected.sY ~= selected.eY then
		copy[1] = self.lines[selected.sY]:sub(selected.sX, -1)
		copy[2] = '\n'
		for i = selected.sY + 1, selected.eY - 1 do
			copy[#copy + 1] = self.lines[i]
			copy[#copy + 1] = "\n"
		end
		copy[#copy + 1] = self.lines[selected.eY]:sub(1, selected.eX)
		-- copy[#copy + 1] = "\n" --?
	else
		copy[1] = self.lines[selected.sY]:sub(selected.sX, selected.eX)
	end
	-- TODO: maybe try to use table.concat(copy, '\n')?
	return table.concat(copy)
end

function TextBox:onKeyDown(key, held)
	local cursor = self.cursor
	local line = self.lines[cursor.y] or ""
	if key == keys.backspace then
		self.scroll.max_x_cached = nil
		if self:deleteSelectedText() then
			self:updateDirty()
			return true
		end
		if line:sub(1, cursor.x - 1) == "" and self.lines[cursor.y - 1] then
			self:moveCursorPos(math.huge, cursor.y - 1)
			self.lines[cursor.y] = self.lines[cursor.y] .. line
			table.remove(self.lines, cursor.y + 1)
			self:setScrollPosX(math.max(self.scroll.pos_x - 1, 0))
		else
			self.lines[cursor.y] = line:sub(1, math.max(cursor.x - 2, 0)) .. line:sub(cursor.x, #line)
			self:setScrollPosX(math.max(self.scroll.pos_x - 1, 0))
			self:moveCursorPos(cursor.x - 1, cursor.y)
		end
	elseif key == keys.delete then
		self.scroll.max_x_cached = nil
		if self:deleteSelectedText() then
			self:updateDirty()
			return true
		end
		if cursor.x > #line and self.lines[cursor.y + 1] then
			self.lines[cursor.y] = line .. self.lines[cursor.y + 1]
			table.remove(self.lines, cursor.y + 1)
			self:setScrollPosX(math.max(self.scroll.pos_x - 1, 0))
		else
			self.lines[cursor.y] = line:sub(1, cursor.x - 1) .. line:sub(cursor.x + 1, #line)
		end
	elseif key == keys.left then
		local n_s
		local f = line:sub(1, cursor.x - 1):reverse()
		if self.ctrl_held then
			n_s = select(2, f:find('^%s*[%w_]+'))
			if not n_s then
				n_s = select(2, f:find('^%s*[^%w_%s]+'))
			end
		end
		local n_x = n_s and self.cursor.x - n_s or self.cursor.x - 1
		self:moveCursorPos(n_x, cursor.y)
		if cursor.x > n_x and cursor.y > 1 then
			self:moveCursorPos(math.huge, cursor.y - 1)
		end
		if self.shift_held then
			self:selectText(self.click.x, self.click.y, cursor.x, cursor.y)
		else
			self.selected.status = false
		end
	elseif key == keys.right then
		local n_s
		local f = line:sub(cursor.x)
		if self.ctrl_held then
			n_s = select(2, f:find('^%s*[%w_]+'))
			if not n_s then
				n_s = select(2, f:find('^%s*[^%w_%s]+'))
			end
		end
		local n_x = n_s and self.cursor.x + n_s or self.cursor.x + 1
		self:moveCursorPos(n_x, cursor.y)
		if cursor.x < n_x and cursor.y < #self.lines then
			self:moveCursorPos(1, cursor.y + 1)
		end
		if self.shift_held then
			self:selectText(self.click.x, self.click.y, cursor.x, cursor.y)
		else
			self.selected.status = false
		end
	elseif key == keys.c and self.ctrl_held and self.selected.status then
		self.root.clipboard = {
			type = 'text',
			data = self:copySelectedText()
		}
		return true
	elseif key == keys.x and self.ctrl_held and self.selected.status then
		self.root.clipboard = {
			type = 'text',
			data = self:copySelectedText()
		}
		self:deleteSelectedText()
		self.dirty = true
		return true
	elseif key == keys.v and self.alt_held then
		if self.root.clipboard.type == 'text' then self:onPaste(self.root.clipboard.data) end
	elseif key == keys.a and self.ctrl_held then
		cursor.y = #self.lines
		cursor.x = #self.lines[cursor.y] + 1
		self:selectText(1, 1, cursor.x, cursor.y)
	elseif key == keys.up then
		self:moveCursorPos(cursor.x, cursor.y - 1)
		if self.shift_held then
			self:selectText(self.click.x, self.click.y, cursor.x, cursor.y)
		else
			self.selected.status = false
		end
	elseif key == keys.down then
		self:moveCursorPos(cursor.x, cursor.y + 1)
		if self.shift_held then
			self:selectText(self.click.x, self.click.y, cursor.x, cursor.y)
		else
			self.selected.status = false
		end
	elseif key == keys.leftShift and not held then
		if not self.selected.status then
			local cx, cy = cursor.x, cursor.y
			self.click = { x = cx, y = cy }
			self.selected.sX, self.selected.sY = cx, cy
			self.selected.eX, self.selected.eY = cx, cy
		end
		self.shift_held = true
	elseif key == keys.leftCtrl and not held then
		self.ctrl_held = true
	elseif key == keys.leftAlt and not held then
		self.alt_held = true
	elseif key == keys.enter then
		self.scroll.max_x_cached = nil
		self:deleteSelectedText()
		local line = self.lines[self.cursor.y]
		table.insert(self.lines, cursor.y + 1, line:sub(cursor.x, #line))
		self:setLine(line:sub(1, cursor.x - 1), cursor.y)
		self:moveCursorPos(1, cursor.y + 1)
	elseif key == keys.tab then
		self:onCharTyped('\t')
	elseif key == keys.pageDown then
		self:scrollY(self.h / self.scroll.sens_y)
		self:moveCursorPos(cursor.x, cursor.y + self.h)
		self.selected.status = false
	elseif key == keys.pageUp then
		self:scrollY(-self.h / self.scroll.sens_y)
		self:moveCursorPos(cursor.x, cursor.y - self.h)
		self.selected.status = false
		-- elseif key == keys.home then
		-- 	self:moveCursorPos(1, cursor.y)
		-- 	self.selected.status = false
		-- elseif key == keys["end"] then
		-- 	self:moveCursorPos(#line + 1, cursor.y)
		-- 	self.selected.status = false
		-- end
	elseif key == keys.home then
		self:moveCursorPos(1, cursor.y)
		if self.shift_held then
			self:selectText(1, cursor.y, self.click.x, self.click.y)
		else
			self.selected.status = false
		end
	elseif key == keys["end"] then
		self:moveCursorPos(#line + 1, cursor.y)
		if self.shift_held then
			self:selectText(#line + 1, cursor.y, self.click.x, self.click.y)
		else
			self.selected.status = false
		end
	end
	self:updateDirty()
	return true
end

function TextBox:onPaste(char)
	self.scroll.max_x_cached = nil
	self:deleteSelectedText()
	local cursor = self.cursor
	local lines = self.lines
	local t_line = lines[cursor.y]
	local i = 0
	local reminder
	for line in char:gmatch("[^\n]+") do
		if i == 0 then
			reminder = t_line:sub(cursor.x, #t_line)
			t_line = t_line:sub(1, cursor.x - 1) .. line
			self:setLine(t_line, cursor.y)
		else
			table.insert(lines, cursor.y + i, line)
		end
		i = i + 1
	end
	local prev_line = lines[cursor.y + i - 1]
	if not prev_line then return end
	lines[cursor.y + i - 1] = prev_line:sub(1, #prev_line) .. reminder
	self:moveCursorPos(#prev_line + 1, cursor.y + i - 1)
	self.dirty = true
	return true
end

function TextBox:updateDirty()
	if self.scrollbar_v then
		self.scrollbar_v.dirty = true
	end
	if self.scrollbar_h then
		self.scrollbar_h.dirty = true
	end
	self.dirty = true
end

function TextBox:getScrollMaxX()
	if self.scroll.max_x_cached then
		return self.scroll.max_x_cached
	end
	local max = 0
	local lines = self.lines
	for i = 1, #lines do
		local line = lines[i]
		local nLine = self:getVisualX(line, #line)
		max = max < nLine and nLine or max
	end
	max = max - self.w + 1
	self.scroll.max_x_cached = max
	return max
end

function TextBox:getScrollMaxY()
	return math.max(0, #self.lines - self.h)
end

function TextBox:setDisabled(bool)
	expect(bool, 'bool', 'boolean', 'nil')
	self.disabled = bool
	self.dirty = true
end

function TextBox:onEvent(event, data)
	if event == 'timer' and data[1] == self.timer_id then
		self.timer_id = nil
		return true
	end
	return Widget.onEvent(self, event, data)
end

---@class TextBox
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field TabSize? number Tab width in spaces
---@field bg? color|number Background color
---@field fg? color|number Foreground/text color
---@field bg_selected? color|number Background selected color
---@field fg_selected? color|number Foreground/text selected color
---@field sens_x? color|number Scroll sensitivity for x
---@field sens_y? color|number Scroll sensitivity for y
---@param args TextBox Initialization table with fields above
---@return table object TextBox
function TextBox.new(args)
	local instance = Widget.new(args)

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.black

	instance.fg_selected = expect_args(args, 'fg_selected', 'number', 'nil') or instance.fg
	instance.bg_selected = expect_args(args, 'bg_selected', 'number', 'nil') or colors.blue

	-- add_mixin(instance, ScrollableMixin)
	-- instance:initScroll(3, 3)
	ScrollMixin.addMixin(instance)
	instance:initScroll(expect_args(args, 'sens_x', 'integer', 'nil'), expect_args(args, 'sens_y', 'integer', 'nil'))

	instance.TabSize = args.TabSize or 4
	instance.lines = { "" }
	instance.cursor = { x = 1, y = 1 }
	instance.click = {}
	instance.selected = {
		status = false,
		sX = 1,
		sY = 1,
		eX = 1,
		eY = 1
	}
	instance.scroll.max_x_cached = nil
	instance.timer_id = nil

	instance.draw = TextBox.draw
	instance.setLine = TextBox.setLine
	instance.onCharTyped = TextBox.onCharTyped
	instance.moveCursorPos = TextBox.moveCursorPos
	instance.onMouseDown = TextBox.onMouseDown
	instance.focusPostDraw = TextBox.focusPostDraw
	instance.onFocus = TextBox.onFocus
	instance.onMouseScroll = TextBox.onMouseScroll
	instance.onKeyUp = TextBox.onKeyUp
	instance.onKeyDown = TextBox.onKeyDown
	instance.clear = TextBox.clear
	instance.updateDirty = TextBox.updateDirty
	instance.onPaste = TextBox.onPaste
	instance.onMouseDrag = TextBox.onMouseDrag
	instance.getScrollMaxY = TextBox.getScrollMaxY
	instance.getScrollMaxX = TextBox.getScrollMaxX
	--instance.onMouseUp = TextBox_onMouseUp
	instance.setDisabled = TextBox.setDisabled
	instance.getVisualX = TextBox.getVisualX
	instance.visualToPhysical = TextBox.visualToPhysical
	instance.convert_tabs = TextBox.convert_tabs
	instance.selectText = TextBox.selectText
	instance.copySelectedText = TextBox.copySelectedText
	instance.deleteSelectedText = TextBox.deleteSelectedText
	instance.onEvent = TextBox.onEvent

	return instance
end

return TextBox

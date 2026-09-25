local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect
local clamp = require 'Utils'.clamp
local to_hex = require 'Utils'.to_hex

local Textfield = {}

function Textfield:draw()
	local self_fg = to_hex[self.fg]
	local self_bg = to_hex[self.bg]

	local line_str = self.text
	local nLine = #line_str

	if nLine == 0 and self.root.focus ~= self then --and #self.hint <= self.w then
		local str = (self.hint .. (" "):rep(self.w - #self.hint)):sub(1, self.w)
		term.setCursorPos(self.x, self.y)
		return term.blit(str, to_hex[self.hint_col]:rep(#str), self_bg:rep(#str))
	end

	local line_fg = self_fg:rep(nLine)
	local line_bg = self_bg:rep(nLine)

	local selected = self.selected
	if selected.status then
		local sel_text = line_str:sub(selected.sX, selected.eX)

		local sub_start = selected.sX - 1
		local sub_end = selected.eX + 1
		if self.fg_selected then
			local selected_fg = to_hex[self.fg_selected]
			line_fg = line_fg:sub(1, sub_start) .. selected_fg:rep(#sel_text)
				.. line_fg:sub(sub_end, -1)
		end

		local selected_bg = to_hex[self.bg_selected or colors.blue]
		line_bg = line_bg:sub(1, sub_start) .. selected_bg:rep(#sel_text)
			.. line_bg:sub(sub_end, -1)
	end

	local start_sub, end_sub = self.scroll_x + 1, self.scroll_x + self.w
	local rep_len = self.scroll_x + self.w

	local draw_str = (' '):rep(rep_len)
	local draw_fg = self_fg:rep(rep_len)
	local draw_bg = self_bg:rep(rep_len)

	term.setCursorPos(self.x, self.y)
	return term.blit((line_str .. draw_str):sub(start_sub, end_sub),
		(line_fg .. draw_fg):sub(start_sub, end_sub),
		(line_bg .. draw_bg):sub(start_sub, end_sub))
end

-- function Textfield:draw()
-- 	-- term.setBackgroundColor(self.bg)
-- 	local text = self.text
-- 	if self.hidden == true then
-- 		text = ("*"):rep(#self.text)
-- 	end
-- 	-- if self.root.focus ~= self and #self.text == 0 then --and #self.hint <= self.w then
-- 	-- 	local str = (self.hint .. (" "):rep(self.w - #self.hint)):sub(1, self.w)
-- 	-- 	return term.blit(str, to_hex[self.fg]:rep(#str), to_hex[self.bg]:rep(#str))
-- 	-- end

-- 	local sub_start, sub_end = self.scroll_x + 1, self.scroll_x + self.w
-- 	local str = text:sub(sub_start, sub_end)
-- 	str = str .. (" "):rep(self.w - #str)

-- 	local bg = to_hex[self.bg]:rep(self.w)
-- 	local fg = to_hex[self.fg]:rep(self.w)

-- 	local selected = self.selected
-- 	if selected.status then
-- 		local sel_bgcol = to_hex[self.bg_alt or colors.blue]:rep(selected.eX - selected.sX + 1)
-- 		bg = (bg:sub(1, selected.sX - 1 - sub_start + 1) .. sel_bgcol .. bg:sub(selected.eX - sub_end))

-- 		local sel_fgcol = to_hex[self.fg_alt or colors.white]:rep(selected.eX - selected.sX + 1)
-- 		fg = (fg:sub(1, selected.sX - 1 - sub_start + 1) .. sel_fgcol .. fg:sub(selected.eX - sub_end))
-- 		-- term.setBackgroundColor(self.bg_alt or colors.blue)
-- 		-- term.setTextColor(self.fg_alt or colors.white)
-- 		-- local sel_x_start = selected.sX
-- 		-- local draw_x = self.x + (sel_x_start - 1) - self.scroll_x
-- 		-- if draw_x < self.x then
-- 		-- 	sel_x_start = sel_x_start + (self.x - draw_x)
-- 		-- 	draw_x = self.x
-- 		-- end
-- 		-- local sel_x_end = math.min(self.w + self.scroll_x, selected.eX)
-- 		-- local sel_text = text:sub(sel_x_start, sel_x_end)
-- 		-- term.setCursorPos(draw_x, self.y)
-- 		-- term.write(sel_text)
-- 	else
-- 		-- bg = bg:sub(sub_start, sub_end)
-- 		-- fg = fg:sub(sub_start, sub_end)
-- 	end
-- 	log(str)
-- 	log(fg)
-- 	log(bg)
-- 	term.setCursorPos(self.x, self.y)
-- 	return term.blit(str, fg, bg)
-- end

-- function Textfield:draw()
-- 	term.setBackgroundColor(self.bg)
-- 	term.setCursorPos(self.x, self.y)
-- 	local text = self.text
-- 	if self.hidden == true then
-- 		text = ("*"):rep(#self.text)
-- 	end
-- 	if self.root.focus ~= self and #self.text == 0 then --and #self.hint <= self.w then
-- 		term.setTextColor(self.hint_col or colors.lightGray)
-- 		-- term.write(self.hint..(" "):rep(self.w - #self.hint))
-- 		term.write((self.hint .. (" "):rep(self.w - #self.hint)):sub(1, self.w))
-- 		return
-- 	end
-- 	term.setTextColor(self.fg)
-- 	local str = text:sub(self.scroll_x + 1, math.min(#self.text, self.scroll_x + self.w))
-- 	term.write(str .. (" "):rep(self.w - #str))
-- 	local selected = self.selected
-- 	if selected.status then
-- 		term.setBackgroundColor(self.bg_alt or colors.blue)
-- 		term.setTextColor(self.fg_alt or colors.white)
-- 		local sel_x_start = selected.sX
-- 		local draw_x = self.x + (sel_x_start - 1) - self.scroll_x
-- 		if draw_x < self.x then
-- 			sel_x_start = sel_x_start + (self.x - draw_x)
-- 			draw_x = self.x
-- 		end
-- 		local sel_x_end = math.min(self.w + self.scroll_x, selected.eX)
-- 		local sel_text = text:sub(sel_x_start, sel_x_end)
-- 		term.setCursorPos(draw_x, self.y)
-- 		term.write(sel_text)
-- 	end
-- end

function Textfield:focusPostDraw()
	local cursor = colors.blue
	if self.selected.status then cursor = colors.red end
	term.setTextColor(cursor)
	local x = self.x + self.cursor_x - self.scroll_x - 1
	term.setCursorPos(x, self.y)
	if x < self.x or x > self.x + self.w - 1 then
		term.setCursorBlink(false)
	else
		term.setCursorBlink(true)
	end
end

function Textfield:setScrollX(pos_x)
	self.scroll_x = clamp(pos_x, 0, #self.text - self.w + 1) -- [0; scroll_max]
end

function Textfield:deleteSelectedText()
	local sel = self.selected
	if sel.status and #self.text > 0 then
		self.text = self.text:sub(1, sel.sX - 1) .. self.text:sub(sel.eX + 1, #self.text)
		self:setCursor(sel.sX)
		sel.status = false
		self.dirty = true
		return true
	end
	return false
end

function Textfield:setCursor(pos)
	self.cursor_x = clamp(pos, 1, #self.text + 1)
	if self.cursor_x - self.scroll_x > self.w then
		self:setScrollX(self.cursor_x - self.w)
	elseif self.cursor_x - self.scroll_x < 1 then
		self:setScrollX(self.cursor_x - 1)
	end
end

function Textfield:onMouseScroll(dir, x, y)
	local old_scroll_x = self.scroll_x
	self:setScrollX(self.scroll_x - dir)
	if self.scroll_x ~= old_scroll_x then
		self.dirty = true
		return true
	end
	return false
end

function Textfield:onFocus(focused)
	if not focused then self.selected.status = false end
	term.setCursorBlink(focused)
	self.dirty = true
	return true
end

function Textfield:selectText(start_x, end_x)
	local sel = self.selected
	if start_x == end_x then
		sel.status = false
	elseif start_x < end_x then
		sel.sX = start_x
		sel.eX = end_x - 1
		sel.status = true
	else
		sel.sX = end_x
		sel.eX = start_x - 1
		sel.status = true
	end
	self.dirty = true
end

function Textfield:getSelectedText()
	return self.text:sub(self.selected.sX, self.selected.eX)
end

function Textfield:onMouseDown(btn, x, y)
	if self.disabled then return true end
	local lX = x - self.x + 1 + self.scroll_x
	self:setCursor(lX)
	local selected = self.selected

	-- double click logic:
	if self.timer_id and self.click_pos_x then
		os.cancelTimer(self.timer_id)
		self.timer_id = nil
		if self.click_pos_x == lX then
			local line = self.text
			local firstPos = line:sub(1, lX):find("[%w_]+$")
			local relativeEnd = select(2, line:sub(lX):find("^[%w_]+"))
			if firstPos and relativeEnd then
				local lastPos = lX + relativeEnd - 1
				self:setCursor(lastPos + 1)
				self:selectText(firstPos, self.cursor_x)
			else
				self:setCursor(lX + 1)
				self:selectText(lX, self.cursor_x)
			end
			-- self.click = { x = firstPos or p_x, y = cursor.y }
			self.click_pos_x = firstPos or lX
			-- self.selected.status = true
			self.dirty = true
			return true
		end
	end

	local cx = self.cursor_x
	self.click_pos_x = cx
	selected.sX = cx
	selected.eX = cx
	selected.status = false
	self.dirty = true
	self.timer_id = os.startTimer(0.5) -- double click delay
	return true
end

function Textfield:onMouseDrag(btn, x, y)
	if self.disabled then return true end
	self:setCursor(x - self.x + 1 + self.scroll_x)
	self:selectText(self.click_pos_x, self.cursor_x)
	return true
end

function Textfield:onCharTyped(chr)
	if self.disabled then return true end
	chr = chr == '\000' and '?' or chr
	self:deleteSelectedText()
	self.text = self.text:sub(1, self.cursor_x - 1) .. chr .. self.text:sub(self.cursor_x, #self.text)
	self:setCursor(self.cursor_x + 1)
	self.dirty = true
	return true
end

function Textfield:onPaste(text)
	if self.disabled then return true end
	self:deleteSelectedText()
	-- if self.root.clipboard.type == 'text' then text = self.root.clipboard.data end
	text = text:match("([^\n]*)")
	self.text = self.text:sub(1, self.cursor_x - 1) .. text .. self.text:sub(self.cursor_x, #self.text)
	self:setCursor(self.cursor_x + #text)
	self.dirty = true
	return true
end

function Textfield:onKeyUp(key)
	if self.disabled then return true end
	if key == keys.leftShift then
		self.shift_held = nil
	elseif key == keys.leftAlt then
		self.alt_held = nil
	elseif key == keys.leftCtrl then
		self.ctrl_held = nil
	end
	return true
end

function Textfield:onKeyDown(key, held)
	if self.disabled then return true end
	if key == keys.backspace then
		if self:deleteSelectedText() then return true end
		self.text = self.text:sub(1, math.max(self.cursor_x - 2, 0)) .. self.text:sub(self.cursor_x, #self.text)
		self:setCursor(self.cursor_x - 1)
		self:setScrollX(self.scroll_x - 1)
	elseif key == keys.delete then
		if self:deleteSelectedText() then return true end
		self.text = self.text:sub(1, self.cursor_x - 1) .. self.text:sub(self.cursor_x + 1, #self.text)
	elseif key == keys.left then
		self:setCursor(self.cursor_x - 1)
		if self.shift_held then
			self:selectText(self.click_pos_x, self.cursor_x)
		else
			self.selected.status = false
		end
	elseif key == keys.right then
		self:setCursor(self.cursor_x + 1)
		if self.shift_held then
			self:selectText(self.click_pos_x, self.cursor_x)
		else
			self.selected.status = false
		end
	elseif key == keys.enter then
		self.selected.status = false
		if self.pressed then self:pressed(self.text) end
	elseif key == keys.leftShift then
		if held then return true end
		if not self.selected.status then
			local cx = self.cursor_x
			self.click_pos_x = cx
			self.selected.sX = cx
			self.selected.eX = cx
		end
		self.shift_held = true
	elseif key == keys.leftCtrl then
		if held then return true end
		self.ctrl_held = true
	elseif key == keys.leftAlt then
		if held then return true end
		self.alt_held = true
	elseif key == keys.c then
		if not self.ctrl_held then return true end
		self.root.clipboard = {
			type = 'text',
			data = self:getSelectedText()
		}
		return true
	elseif key == keys.x then
		if not self.ctrl_held then return true end
		self.root.clipboard = {
			type = 'text',
			data = self:getSelectedText()
		}
		self:deleteSelectedText()
		return true
	elseif key == keys.insert then
		if not self.shift_held then return true end
		if self.root.clipboard.type == 'text' then self:onPaste(self.root.clipboard.data) end
	elseif key == keys.a then
		if not self.ctrl_held then return true end
		self:setCursor(math.huge)
		self:selectText(1, self.cursor_x)
	elseif key == keys['end'] then
		self:setCursor(math.huge)
		if self.shift_held then
			self:selectText(self.click_pos_x, self.cursor_x)
		else
			self.selected.status = false
		end
	elseif key == keys.home then
		self:setCursor(1)
		if self.shift_held then
			self:selectText(self.cursor_x, self.click_pos_x)
		else
			self.selected.status = false
		end
	end
	self.dirty = true
	return true
end

function Textfield:setText(string)
	self.text = expect(string, 'string', 'string', 'nil') or ''
	self.selected.status = false
	self:setCursor(math.huge)
	self.dirty = true
end

function Textfield:setDisabled(bool)
	self.disabled = expect(bool, 'bool', 'boolean', 'nil') or false
	self.dirty = true
end

function Textfield:onEvent(event, data)
	if event == 'timer' and data[1] == self.timer_id then
		self.timer_id = nil
		return true
	end
	return Widget.onEvent(self, event, data)
end

---Creating new *object* of *class*
---@class Textfield
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field text? string Default text in textfield. Default is nil
---@field hint? string Placeholder hint text
---@field hidden? boolean If true, hide input (password mode)
---@field bc? color|number Background color
---@field fc? color|number Foreground/text color
---@param args Textfield Initialization table with fields above
---@return table object Textfield
function Textfield.new(args)
	local instance = Widget.new(args)
	instance.h = 1

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.black

	instance.fg_selected = expect_args(args, 'fg_selected', 'number', 'nil')
	instance.bg_selected = expect_args(args, 'bg_selected', 'number', 'nil')

	instance.hint_col = expect_args(args, 'hint_col', 'number', 'nil') or colors.lightGray
	--TODO: more colors for select, hint_bg, cursor etc...
	instance.scroll_x = 0
	instance.hint = expect_args(args, 'hint', 'string', 'nil') or "Type here"
	instance.text = expect_args(args, 'text', 'string', 'nil') or ""
	instance.cursor_x = 1
	instance.click_pos_x = 1
	instance.hidden = expect_args(args, 'hidden', 'boolean', 'nil') or false
	instance.selected = {
		status = false,
		sX = 1,
		eX = 1
	}

	instance.draw = Textfield.draw
	instance.setCursor = Textfield.setCursor
	instance.onMouseScroll = Textfield.onMouseScroll
	instance.onMouseDrag = Textfield.onMouseDrag
	instance.onFocus = Textfield.onFocus
	-- instance.pressed = Widget.pressed
	instance.focusPostDraw = Textfield.focusPostDraw
	instance.onMouseDown = Textfield.onMouseDown
	instance.onCharTyped = Textfield.onCharTyped
	instance.onPaste = Textfield.onPaste
	instance.onKeyDown = Textfield.onKeyDown
	instance.onKeyUp = Textfield.onKeyUp
	instance.setDisabled = Textfield.setDisabled
	instance.selectText = Textfield.selectText
	instance.deleteSelectedText = Textfield.deleteSelectedText
	instance.getSelectedText = Textfield.getSelectedText
	instance.setScrollX = Textfield.setScrollX
	instance.onEvent = Textfield.onEvent

	return instance
end

return Textfield

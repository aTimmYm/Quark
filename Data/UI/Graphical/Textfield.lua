local g = require 'geometry'
local font = require 'Font'
local Widget = require 'Text.Widget'
local Utils = require 'Utils'
-- local L = require 'log'
-- local ins = require 'inspector'
local Textfield = {}

function Textfield.draw(self)
	-- local oldClip = Utils.graphSetClip(self.x, self.y, self.w, self.h)
	local padding = 1
	if self.radius then
		padding = self.radius
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, self.bc)
	else
		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	end
	local text = self.text
	if self.hidden == true then
		text = string.rep("*", #self.text)
	end
	if (self.disabled and #self.text == 0) or (self.root.focus ~= self and #self.text == 0 and #self.hint * 6 <= self.w) then
		font.simpleText(self.hint, self.x + padding, self.y, self.fc_alt)
		return
	end
	-- font.simpleText(text, self.x+offset, self.y, self.fc)
	-- font.simpleText(text:sub(self.offset + 1, math.min(#self.text, self.offset + math.ceil(self.w/6))), self.x+offset, self.y, self.fc)

	-- local visible_text = text:sub(self.offset + 1, math.min(#self.text, self.offset + math.ceil(self.w/6)))
	-- if not self.clickMap then Utils.graphUnsetClip(oldClip) return end
	-- local offset_index = self:clickMap_toN(self.offset)
	-- local endX = self.clickMap[1][2]
	-- for inx = 1, #self.clickMap do
	-- 	local new = self.clickMap[inx][2]
	-- 	if new >= self.w then
	-- 		break
	-- 	end
	-- 	endX = new
	-- end
	-- local index = self:clickMap_toN(endX) + offset_index
	-- local right = math.min(#self.text + 1, index)
	-- local visible_text = text:sub(offset_index, right)
	-- ins(#self.text + 1, index)
	-- -- '123456789012345'
	-- if self.selected.status then
	-- 	local sel_x_start = self.selected.pos1_x - offset_index
	-- 	local START, _ = self:clickMap_toPx(sel_x_start)
	-- 	-- START = START + self.offset
	-- 	local sel_x_end = self.selected.pos2_x - offset_index
	-- 	local _, END = self:clickMap_toPx(sel_x_end)
	-- 	-- sel_x_end = font.calcWidth(self.text:sub(sel_x_start, sel_x_end))
	-- 	term.drawPixels(self.x + START, self.y, colors.blue, END - START, self.h)
	-- end
	-- font.drawText(visible_text, self.x + padding, self.y, self.fc)

	local start_idx, startPx = self:clickMap_toN(self.offset)
	local end_idx = self:clickMap_toN(self.offset + self.w)

	start_idx = math.max(1, start_idx)
	end_idx = math.min(#text, end_idx)

	local visible_text = text:sub(start_idx, end_idx)

	if self.selected.status then
		local selStartPx, _ = self:clickMap_toPx(self.selected.pos1_x)
		local _, selEndPx = self:clickMap_toPx(self.selected.pos2_x)

		local screen_startX = self.x + padding + (selStartPx - self.offset)
		local screen_endX = self.x + padding + (selEndPx - self.offset)

		term.drawPixels(screen_startX, self.y, colors.blue, screen_endX - screen_startX, self.h)
	end
	local draw_x = self.x + padding + (startPx - self.offset)
	font.drawText(visible_text, draw_x, self.y, self.fc)

	-- Utils.graphUnsetClip(oldClip)
	-- UI.term_unsetClip(oldClip)
	-- if self.selected.status then
	-- 	term.setBackgroundColor(self.bc_alt or colors.blue)
	-- 	term.setTextColor(self.fc_alt or colors.white)
	-- 	local sel_x_start = self.selected.pos1_x
	-- 	local draw_x = self.x + (sel_x_start - 1) - self.offset
	-- 	if draw_x < self.x then
	-- 		sel_x_start = sel_x_start + (self.x - draw_x)
	-- 		draw_x = self.x
	-- 	end
	-- 	local sel_x_end = math.min(self.w + self.offset, self.selected.pos2_x)
	-- 	local sel_text = text:sub(sel_x_start, sel_x_end)
	-- 	term.setCursorPos(draw_x, self.y)
	-- 	term.write(sel_text)
	-- end
end

function Textfield.focusPostDraw(self)
	local cursor = colors.blue
	if self.selected.status then cursor = colors.red end
	-- term.setTextColor(cursor)
	-- local x = self.x + self.cursor_x - self.offset - 1
	-- term.setCursorPos(x, self.y)
	-- if x < self.x or x > self.x + self.w - 1 then
	-- 	term.setCursorBlink(false)
	-- else
	-- 	term.setCursorBlink(true)
	-- end
	local cursor_x = self.x + 1 + (font.calcWidth(self.text:sub(1, self.cursor_x - 1)))
	local cursor_y = self.y
	if self.need_to_blink then font.simpleText('|', cursor_x, cursor_y, colors.blue) end
end

local function delete_selected_tf(self)
	if self.selected.status and #self.text > 0 then
		local sel = self.selected
		self.text = self.text:sub(1, sel.pos1_x - 1) .. self.text:sub(sel.pos2_x + 1, #self.text)
		self:generate_clickMap()
		self:moveCursorPos(sel.pos1_x)
		self.selected.status = false
		self.dirty = true
		return true
	end
	return false
end

function Textfield.moveCursorPos(self, pos)
	self.cursor_x = math.min(math.max(pos, 1), #self.text + 1)

	local cursorPX1, cursorPX2 = self:clickMap_toPx(self.cursor_x)

	if cursorPX2 > self.offset + self.w then
		self.offset = self.offset + (cursorPX2 - self.offset - self.w)
	elseif cursorPX1 < self.offset then
		self.offset = cursorPX1 - (self.offset - cursorPX1)
	end
end

function Textfield.onMouseScroll(self, dir, x, y)
	local old_offset = self.offset
	self.offset = math.max(0, math.min(font.calcWidth(self.text) - self.w + 1, self.offset - dir))
	if self.offset ~= old_offset then
		self.dirty = true
		return true
	end
	return false
end

function Textfield.onMouseUp(self, btn, x, y)
	if not self:check(x, y) then
		self.dirty = true
	end
	return true
end

function Textfield.onFocus(self, focused)
	-- if focused and bOS.monitor[1] and bOS.monitor[2] then
	-- 	self.root:addChild(self.root.keyboard)
	-- 	self.root.keyboard:onLayout()
	-- elseif not focused and bOS.monitor[1] and bOS.monitor[2] then
	-- 	self.root:removeChild(self.root.keyboard)
	-- end
	if not focused then self.selected.status = false end
	term.setCursorBlink(focused)
	self.dirty = true
	-- self.blink_enable = true
	return true
end

local function select_tf(self, new_x)
	local oX = self.click_pos_x
	local sel = self.selected
	local line = #self.text + 1
	local nX = math.max(1, math.min(line, new_x))
	self:moveCursorPos(nX)
	if nX < oX then
		sel.pos1_x = self.cursor_x + 1 - 1
		sel.pos2_x = oX - 1
	else
		sel.pos1_x = oX + 1 - 1
		sel.pos2_x = self.cursor_x - 1
	end
	-- if nX < oX then
	-- 	sel.pos1_x = nX
	-- 	sel.pos2_x = oX - 1
	-- 	sel.status = true
	-- elseif nX > oX then
	-- 	sel.pos1_x = oX
	-- 	sel.pos2_x = nX - 1
	-- 	sel.status = true
	-- else
	-- 	sel.status = false
	-- end
	self.selected.status = true
	self.dirty = true
end

function Textfield.onMouseDown(self, btn, x, y)
	if self.disabled then return true end
	local rel_x = x - self.x + self.offset
	local valid_x, startPx, endPx = self:clickMap_toN(rel_x)

	self:moveCursorPos(valid_x or 1)

	local cx = self.cursor_x
	self.click_pos_x = cx
	self.selected.pos1_x = startPx
	self.selected.pos2_x = endPx
	self.selected.status = false
	self.dirty = true
	return true
end

function Textfield.onMouseDrag(self, btn, x, y)
	if self.disabled then return true end
	-- local rel_x = x - self.x + self.offset
	local rel_x = x - self.x + self.offset
	local nX = self:clickMap_toN(rel_x)
	-- local nX = x - self.x + self.offset
	select_tf(self, nX)
	-- select_tf(self, nX)
	-- ins(self.selected.pos1_x)
	-- ins(self.selected.pos2_x)
	return true
end

function Textfield.onCharTyped(self, chr)
	if self.disabled then return true end
	delete_selected_tf(self)
	local t = self.text
	self.text = t:sub(1, self.cursor_x - 1) .. chr .. t:sub(self.cursor_x, #self.text)
	self:generate_clickMap()
	self:moveCursorPos(self.cursor_x + 1)
	self.dirty = true
	return true
end

function Textfield.onPaste(self, text)
	if self.disabled then return true end
	delete_selected_tf(self)
	text = text:match("([^\n]*)")
	local t = self.text
	self.text = t:sub(1, self.cursor_x - 1) .. text .. t:sub(self.cursor_x, #self.text)
	self:generate_clickMap()
	self:moveCursorPos(self.cursor_x + #text)
	self.dirty = true
	return true
end

function Textfield.onKeyUp(self, key)
	if self.disabled then return true end
	-- self:generate_clickMap()
	if key == keys.leftShift then
		self.shift_held = nil
		return true
	elseif key == keys.leftCtrl then
		self.ctrl_held = nil
	end
	return true
end

function Textfield.onKeyDown(self, key, held)
	if self.disabled then return true end
	local t = self.text
	if key == keys.backspace then
		if delete_selected_tf(self) then return true end
		self.text = t:sub(1, math.max(self.cursor_x - 2, 0)) .. t:sub(self.cursor_x, #t)
		self.offset = math.max(self.offset - 1, 0)
		self:generate_clickMap()
		self:moveCursorPos(self.cursor_x - 1)
	elseif key == keys.delete then
		if delete_selected_tf(self) then return true end
		self.text = t:sub(1, self.cursor_x - 1) .. t:sub(self.cursor_x + 1, #t)
		self:generate_clickMap()
	elseif key == keys.left then
		self:moveCursorPos(self.cursor_x - 1)
		if self.shift_held then
			select_tf(self, self.cursor_x)
		else
			self.selected.status = false
		end
	elseif key == keys.right then
		self:moveCursorPos(self.cursor_x + 1)
		if self.shift_held then
			select_tf(self, self.cursor_x)
		else
			self.selected.status = false
		end
	elseif key == keys.enter then
		self.selected.status = false
		self:pressed(self.text)
	elseif key == keys.leftShift and not held then
		if not self.selected.status then
			local cx = self.cursor_x
			self.click_pos_x = cx
			self.selected.pos1_x = cx
			self.selected.pos2_x = cx
		end
		self.shift_held = true
	elseif key == keys.leftCtrl and not held then
		self.ctrl_held = true
	elseif key == keys.c and self.ctrl_held then
		local peremennaya = self.text:sub(self.selected.pos1_x, self.selected.pos2_x)
		if _G.sysclipboard then _G.sysclipboard = peremennaya end
		return true
	elseif key == keys.a and self.ctrl_held then
		self.selected.pos1_x = 1
		self.selected.pos2_x = #self.text
		self.selected.status = true
		self:moveCursorPos(#self.text)
	end
	self.dirty = true
	return true
end

function Textfield.refreshBlinkStatus(self)
	if self.blink_enable and not self.timer_id then
		self.timer_id = os.startTimer(self.blink_speed)
	end
end

-- function Textfield.onEvent(self, evt)
-- 	if evt[1] == "timer" and evt[2] == self.timer_id then
-- 		if self.blink_enable then
-- 			self.dirty = true
-- 			self.need_to_blink = not self.need_to_blink
-- 			self.timer_id = os.startTimer(self.blink_speed)
-- 		else
-- 			self.timer_id = nil
-- 		end
-- 		-- return true
-- 	end
-- 	-- self:refreshBlinkStatus()
-- 	return onEvent(self,evt)
-- end

function Textfield.generate_clickMap(self)
	if not self.text or self.text == '' then return end
	self.clickMap = {}
	local interval = font.interval
	local Width = 0

	-- local t = self.text
	local t = self.hidden and string.rep("*", #self.text) or self.text

	for i = 1, #t do
		local currentChar = t:sub(i, i)
		local charWidth = font.calcWidth(currentChar)
		local sx = Width
		local ex = Width + charWidth + interval
		Width = ex
		self.clickMap[i] = { sx, ex }
	end
end

function Textfield.clickMap_toPx(self, n)
	-- if type(n) ~= 'number' then return end
	local map = self.clickMap
	if n < 1 or not map then return 0, 0 end
	local mapSize = #map
	if n > mapSize then return map[mapSize][1], map[mapSize][2] end
	local pos = map[n]
	if not pos then return 0, 0 end
	return pos[1], pos[2]
end

function Textfield.clickMap_toN(self, px)
	-- if not px then error('tut', 2) end
	if px < 0 then return 1, 0, 0 end
	local map = self.clickMap
	if not map then return 1, 0, 0 end
	local mapSize = #map
	for n = 1, mapSize do
		local pos = map[n]
		if px >= pos[1] and px < pos[2] then
			return n, pos[1], pos[2]
		end
	end
	return mapSize + 1, map[mapSize][1], map[mapSize][2]
end

---Creating new *object* of *class*
---@class Textfield
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field hint? string Placeholder hint text
---@field hidden? boolean If true, hide input (password mode)
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Textfield Initialization table with fields above
---@return table object Textfield
function Textfield.new(args)
	args.fc_alt = args.fc_alt or colors.lightGray
	local instance = Widget.new(args)

	instance.offset = 0
	instance.hint = args.hint or "Type here"
	instance.text = ""
	instance.cursor_x = #(instance.text or '') + 1
	instance.hidden = args.hidden or false
	instance.need_to_blink = false
	instance.blink_enable = true
	instance.timer_id = nil
	instance.blink_speed = 0.5
	instance.selected = {
		status = false,
		pos1_x = 1,
		pos2_x = 1
	}
	instance.generate_clickMap = Textfield.generate_clickMap
	if instance.text and instance.text ~= '' then
		instance:generate_clickMap()
	end
	instance.clickMap_toN = Textfield.clickMap_toN
	instance.clickMap_toPx = Textfield.clickMap_toPx
	instance.draw = Textfield.draw
	instance.moveCursorPos = Textfield.moveCursorPos
	instance.onMouseScroll = Textfield.onMouseScroll
	instance.onMouseUp = Textfield.onMouseUp
	instance.onMouseDrag = Textfield.onMouseDrag
	instance.onFocus = Textfield.onFocus
	-- instance.pressed = Widget.pressed
	-- instance.focusPostDraw = Textfield.focusPostDraw
	instance.onMouseDown = Textfield.onMouseDown
	instance.onCharTyped = Textfield.onCharTyped
	instance.onPaste = Textfield.onPaste
	instance.onKeyDown = Textfield.onKeyDown
	instance.onKeyUp = Textfield.onKeyUp
	-- instance.refreshBlinkStatus = Textfield.refreshBlinkStatus
	-- instance.onEvent = Textfield.onEvent
	-- instance.onEvent = Widget.onEvent
	-- instance.setDisabled = Widget.setDisabled

	return instance
end

return Textfield

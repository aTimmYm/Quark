--TODO: vertical/horizontal slider separate objects
local Widget = require 'Text.Widget'
local drawFilledBox = require 'Utils'.drawFilledBox
local clamp = require 'Utils'.clamp
local expect = require 'Utils'.expect
local expect_args = require 'Utils'.expect_args

local Slider = {}

-- function Slider.draw(self)
-- 	local N = #self.arr
-- 	local W = self.w

-- 	if N > 0 then
-- 		local i = self.slidePosition
-- 		local offset = (N == 1) and 0 or math.min(math.floor((i - 1) / (N - 1) * (W - 1)), self.w - 1)
-- 		local thumb_x = self.x + offset

--  	if self.held and self.thumb_click then
-- 			term.setBackgroundColor(self.thumb_click)
-- 		else
-- 			term.setBackgroundColor(self.color_empty or self.bg)
-- 		end

--  		term.setCursorPos(thumb_x, self.y)
--  		term.write(" ")
--  		term.setBackgroundColor(self.bg)
--  		term.setTextColor(self.color_fill)
--  		term.setCursorPos(self.x, self.y)
--  		term.write(("\140"):rep(offset))
--  		term.setBackgroundColor(self.bg)
--  		term.setTextColor(self.fg)
--  		term.setCursorPos(thumb_x + 1, self.y)
--  		term.write(("\140"):rep(self.w - offset - 1))
-- 	else
--  		term.setBackgroundColor(self.bg)
--  		term.setTextColor(self.fg)
--  		term.setCursorPos(self.x, self.y)
--  		term.write(("\140"):rep(W))
-- 	end
-- end

function Slider:draw()
	local bg = self.bg or colors.black
	local filled = self.color_fill or colors.lightBlue
	local empty = self.color_empty or colors.white
	local cirCol = self.held and (self.thumb_click or colors.gray) or (self.thumb_color or colors.lightGray)

	local thumbSize = 1
	local sp = self.slidePosition

	drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, bg)

	if self.isHorizontal then
		local maxOffset = self.w - thumbSize
		local offset = math.floor(maxOffset * sp)

		term.setBackgroundColor(bg)
		term.setTextColor(empty)
		term.setCursorPos(self.x + offset + 1, self.y)
		term.write(("\140"):rep(self.w - offset - 1))

		local fillWidth = offset
		if fillWidth > 0 then
			term.setBackgroundColor(bg)
			term.setTextColor(filled)
			term.setCursorPos(self.x, self.y)
			term.write(("\140"):rep(fillWidth))
		end

		term.setBackgroundColor(cirCol)
		term.setCursorPos(self.x + offset, self.y)
		term.write(" ")
	else
		local maxOffset = self.h - thumbSize
		local offset = math.floor(maxOffset * sp)

		term.setBackgroundColor(filled)
		-- term.setTextColor(filled)
		-- term.setCursorPos(self.x, self.y + offset + 1)
		for n = 0, offset - 1 do
			-- term.setCursorPos(self.x, self.y + n)
			term.setCursorPos(self.x, self.y + self.h - 1 - n)
			term.write(" ")
		end
		-- g.draw_filled_rounded_rect(self.x + interval, self.y, self.w - doubleInt, self.h, thumbSize, filled)

		local emptyHeight = self.h - offset - thumbSize
		if emptyHeight > 0 then
			for n = 0, emptyHeight do
				term.setBackgroundColor(empty)
				-- term.setTextColor(empty)
				-- term.setCursorPos(self.x, self.y + self.h - 1 - n)
				term.setCursorPos(self.x, self.y + n)
				term.write(' ')
			end
			-- g.draw_filled_rounded_rect(self.x + interval, self.y, self.w - doubleInt, emptyHeight, thumbSize, empty)
		end

		-- Кружечок (offset 0 = самий низ, offset max = самий верх)
		-- term.setCursorPos(self.x, self.y + offset)
		term.setCursorPos(self.x, self.y + self.h - 1 - offset)
		term.setBackgroundColor(cirCol)
		term.write(' ')
		-- g.draw_filled_circle(self.x, self.y + self.h - thumbSize - offset, thumbSize, cirCol)
	end
end

function Slider:setValue(val)
	-- self.slidePosition = math.max(0, math.min(1, val))
	self.slidePosition = clamp(expect(val, 'val', 'number'), 0, 1)
	self.dirty = true
end

function Slider:updatePos(mousePos)
	local thumbSize = math.min(self.w, self.h)
	local relative_value, maxOffset
	if self.isHorizontal then
		maxOffset = self.w - thumbSize
		relative_value = mousePos
	else
		maxOffset = self.h - thumbSize
		relative_value = (self.h - mousePos - 1)
	end
	if maxOffset <= 0 then return end
	self.slidePosition = math.max(0, math.min(1, relative_value / maxOffset))
	self.dirty = true
end

function Slider:onMouseDown(btn, x, y)
	local pos = self.isHorizontal and (x - self.x) or (y - self.y)
	self:updatePos(pos)
	self.held = true
	if self.pressed then self:pressed(self.slidePosition) end
	return true
end

function Slider:onMouseScroll(dir, x, y)
	-- dir = 1 або -1. Змінюємо позицію на 5% за один клік коліщатка
	local step = 0.05
	self.slidePosition = math.max(0, math.min(1, self.slidePosition - (dir * step)))
	self.dirty = true
	if self.pressed then self:pressed(self.slidePosition) end
end

function Slider:onMouseUp(btn, x, y)
	self.held = false
	self.dirty = true
end

function Slider:onMouseDrag(btn, x, y)
	local pos = self.isHorizontal and (x - self.x) or (y - self.y)
	self:updatePos(pos)
	if self.pressed then self:pressed(self.slidePosition) end
	return true
end

---Creating new *object* of *class*
---@class Slider
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field slidePosition? number Current selected index
---@field thumb_color color|number Main slider glif color
---@field thumb_click? color|number Click slider glif color (optional)
---@field bg color|number Background color
---@field color_fill color|number Background filled color
---@field color_empty color|number Background empty color
---@param args Slider Initialization table with fields above
---@return table object slider
function Slider.new(args)
	local instance = Widget.new(args)
	instance.h = expect_args(args, 'h', 'integer', 'nil') or 1

	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.gray

	instance.color_fill = expect_args(args, 'color_fill', 'number', 'nil') or colors.blue
	instance.color_empty = expect_args(args, 'color_empty', 'number', 'nil') or colors.white

	instance.thumb_color = expect_args(args, 'thumb_color', 'number', 'nil') or colors.gray
	instance.thumb_click = expect_args(args, 'thumb_click', 'number', 'nil') or colors.white

	instance.isHorizontal = expect_args(args, 'isHorizontal', 'boolean', 'nil') ~= false
	instance.held = false
	instance.slidePosition = clamp((expect_args(args, 'slidePosition', 'number', 'nil') or 0), 0, 1)

	instance.draw = Slider.draw
	-- instance.pressed = Widget.pressed
	instance.updatePos = Slider.updatePos
	instance.setValue = Slider.setValue
	instance.onMouseDown = Slider.onMouseDown
	instance.onMouseScroll = Slider.onMouseScroll
	instance.onMouseDrag = Slider.onMouseDrag
	instance.onMouseUp = Slider.onMouseUp

	return instance
end

return Slider

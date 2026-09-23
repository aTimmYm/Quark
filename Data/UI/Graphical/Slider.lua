local Widget = require 'Text.Widget'
local g = require 'geometry'
local Slider = {}

function Slider.draw(self)
	local bg = self.bc or colors.black
	local filled = self.fc_alt or colors.lightBlue
	local empty = self.bc_alt or colors.white
	local cirCol = self.held and (self.fc_cl or colors.gray) or (self.fc or colors.lightGray)

	local thumbSize = math.min(self.h, self.w)
	local sp = self.slidePosition -- Тепер це значення від 0.0 до 1.0
	local interval = 1
	local doubleInt = interval * 2

	term.drawPixels(self.x, self.y, bg, self.w, self.h)

	if self.isHorizontal then
		local maxOffset = self.w - thumbSize
		local offset = math.floor(maxOffset * sp)

		g.draw_filled_rounded_rect(self.x, self.y + interval, self.w, self.h - doubleInt, thumbSize, empty)

		local fillWidth = offset + math.floor(thumbSize / 2)
		if fillWidth > 0 then
			-- if sp > 0 then
			g.draw_filled_rounded_rect(self.x, self.y + interval, fillWidth, self.h - doubleInt, thumbSize, filled)
		end

		g.draw_filled_circle(self.x + offset, self.y, thumbSize, cirCol)
	else
		-- Логіка для вертикального слайдера (зазвичай заповнюється знизу вгору)
		local maxOffset = self.h - thumbSize
		local offset = math.floor(maxOffset * sp)

		-- Порожній трек
		g.draw_filled_rounded_rect(self.x + interval, self.y, self.w - doubleInt, self.h, thumbSize, filled)

		-- Заповнений трек
		local emptyHeight = self.h - offset - math.floor(thumbSize / 2)
		if emptyHeight > 0 then
			g.draw_filled_rounded_rect(self.x + interval, self.y, self.w - doubleInt, emptyHeight, thumbSize, empty)
		end

		-- Кружечок (offset 0 = самий низ, offset max = самий верх)
		g.draw_filled_circle(self.x, self.y + self.h - thumbSize - offset, thumbSize, cirCol)
	end
end

function Slider.updatePos(self, mousePos)
	local thumbSize = math.min(self.w, self.h)

	if self.isHorizontal then
		local maxOffset = self.w - thumbSize
		if maxOffset <= 0 then return end
		local relativeX = mousePos - (thumbSize / 2)
		self.slidePosition = math.max(0, math.min(1, relativeX / maxOffset))
	else
		local maxOffset = self.h - thumbSize
		if maxOffset <= 0 then return end
		local relativeY = (self.h - mousePos) - (thumbSize / 2)
		self.slidePosition = math.max(0, math.min(1, relativeY / maxOffset))
	end

	self.dirty = true
end

function Slider.onMouseDown(self, btn, x, y)
	local pos = self.isHorizontal and (x - self.x) or (y - self.y)
	self:updatePos(pos)
	self.held = true
	if self.pressed then self:pressed(self.slidePosition) end
	return true
end

function Slider.onMouseDrag(self, btn, x, y)
	local pos = self.isHorizontal and (x - self.x) or (y - self.y)
	self:updatePos(pos)
	if self.pressed then self:pressed(self.slidePosition) end
	return true
end

function Slider.onMouseUp(self, btn, x, y)
	self.held = false
	self.dirty = true
end

function Slider.onMouseScroll(self, dir, x, y)
	-- dir = 1 або -1. Змінюємо позицію на 5% за один клік коліщатка
	local step = 0.05
	self.slidePosition = math.max(0, math.min(1, self.slidePosition - (dir * step)))
	self.dirty = true
	if self.pressed then self:pressed(self.slidePosition) end
end

---Creating new *object* of *class*
---@class Slider
---@field x number X pos in characters/pixels
---@field y number Y pos in characters/pixels
---@field w number Width in characters/pixels
---@field h number Height
---@field slidePosition? number Current normalized value (0.0 to 1.0)
---@field fc_cl? color|number Click slider glif color (optional)
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Slider Initialization table with fields above
---@return table object slider
function Slider.new(args)
	local instance = Widget.new(args)

	instance.isHorizontal = args.isHorizontal ~= false
	instance.held = false
	instance.slidePosition = args.slidePosition or 0

	instance.draw = Slider.draw
	instance.pressed = Widget.pressed
	instance.updatePos = Slider.updatePos
	instance.onMouseDown = Slider.onMouseDown
	instance.onMouseDrag = Slider.onMouseDrag
	instance.onMouseUp = Slider.onMouseUp
	instance.onMouseScroll = Slider.onMouseScroll

	return instance
end

return Slider

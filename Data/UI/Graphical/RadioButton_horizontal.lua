local Widget = require 'Text.Widget'
local font = require 'Font'
local g = require 'geometry'
local RadioButton_horizontal = {}

function RadioButton_horizontal.draw(self)
	term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	for i = 0, self.count - 1 do
		if self.item - 1 == i then
			g.draw_filled_circle(self.x + (i * 5), self.y, 4, self.fc)
		end
		g.draw_circle(self.x + (i * 5), self.y, 4, self.fc)
	end
end

function RadioButton_horizontal.changeCount(self, arg)
	self.count = arg
	self.w = arg
	self.dirty = true
end

function RadioButton_horizontal.onMouseDown(self, btn, x, y)
	if self.disabled then return true end
	-- if self:check(x,y) then
	local i = x - self.x + 1
	i = math.floor(i / 5) + 1
	self.item = i
	self.dirty = true
	self:pressed(i)
	-- end
	return true
end

---Creating new *object* of *class*
---@class RadioButtonHorizontal
---@field x number X pos in characters
---@field y number Y pos in characters
---@field count? number Number of radio items
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args RadioButtonHorizontal Initialization table with fields above
---@return table object radioButton_horizontal
function RadioButton_horizontal.new(args)
	local instance = Widget.new(args)

	instance.count = (args.count and args.count >= 1) and args.count or 1
	instance.w = instance.count * 5 - 1
	instance.h = 4
	instance.item = 1

	instance.draw = RadioButton_horizontal.draw
	instance.changeCount = RadioButton_horizontal.changeCount
	instance.pressed = Widget.pressed
	-- instance.onMouseUp = RadioButton_horizontal.onMouseUp
	instance.onMouseDown = RadioButton_horizontal.onMouseDown
	instance.setDisabled = Widget.setDisabled

	return instance
end

return RadioButton_horizontal

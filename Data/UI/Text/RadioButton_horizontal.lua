local Widget = require 'Text.Widget'
local expect = require 'Utils'.expect
local expect_args = require 'Utils'.expect_args

local RadioButton_horizontal = {}

function RadioButton_horizontal:draw()
	term.setBackgroundColor(self.bg)
	for i = 1, self.count do
		term.setCursorPos(self.x + i - 1, self.y)
		if self.item == i then
			term.setTextColor(self.active_color)
		else
			term.setTextColor(self.inactive_color)
		end
		term.write("\7")
	end
end

function RadioButton_horizontal:changeCount(arg)
	expect(arg, 'arg', 'integer')
	self.count = arg
	self.w = arg
	self.dirty = true
end

function RadioButton_horizontal:onMouseUp(btn, x, y)
	if self.disabled then return true end
	if self:check(x, y) then
		self.item = x - self.x + 1
		self.dirty = true
		if self.pressed then self:pressed() end
	end
	return true
end

function RadioButton_horizontal:setDisabled(bool)
	self.disabled = expect(bool, 'bool', 'boolean', 'nil') or false
	self.dirty = true
end

---Creating new *object* of *class*
---@class RadioButtonHorizontal
---@field x number X pos in characters
---@field y number Y pos in characters
---@field count? number Number of radio items. Default is 1
---@field bg? color|number Background color. Default is black
---@field active_color? color|number Foreground/text color. Default is white
---@field inactive_color? color|number Foreground/text color. Default is gray
---@param args RadioButtonHorizontal Initialization table with fields above
---@return table object radioButton_horizontal
function RadioButton_horizontal.new(args)
	args.w = 1
	args.h = 1
	local instance = Widget.new(args)

	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.lightGray
	instance.active_color = expect_args(args, 'active_color', 'number', 'nil') or colors.white
	instance.inactive_color = expect_args(args, 'inactive_color', 'number', 'nil') or colors.gray

	-- instance.count = (args.count and args.count >= 1) and args.count or 1
	instance.count = math.max(1, expect_args(args, 'count', 'integer', 'nil') or 1)
	instance.w = instance.count
	instance.item = 1

	instance.draw = RadioButton_horizontal.draw
	instance.changeCount = RadioButton_horizontal.changeCount
	-- instance.pressed = Widget.pressed
	instance.onMouseUp = RadioButton_horizontal.onMouseUp
	instance.setDisabled = RadioButton_horizontal.setDisabled

	return instance
end

return RadioButton_horizontal

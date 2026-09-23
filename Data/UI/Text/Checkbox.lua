local Widget = require 'Text.Widget'
local Button = require 'Text.Button'
local expect_args = require 'Utils'.expect_args

local Checkbox = {}

function Checkbox:draw()
	local bg, fg = self.bg, self.fg
	if self.disabled then
		bg = self.bg_disabled or colors.red
		fg = self.fg_disabled or colors.lightGray
	elseif self.held then
		bg = self.bg_click or self.fg
		fg = self.fg_click or self.bg
	elseif self.hovered then
		bg = self.bg_hovered or self.bg
		fg = self.fg_hovered or self.fg
	end
	term.setBackgroundColor(bg)
	term.setTextColor(fg)
	term.setCursorPos(self.x, self.y)
	if self.on then
		term.write("x")
	else
		term.write(" ")
	end
end

function Checkbox:onMouseUp(btn, x, y)
	if self:check(x, y) then
		if self.pressed then self:pressed() end
		self.on = not self.on
	end
	self.held = false
	self.dirty = true
	return true
end

---Creating new *object* of *class*
---@class Checkbox
---@field x number X pos in characters
---@field y number Y pos in characters
---@field on? boolean Initial checked state
---@field fg? color|number Foreground/text color. Default is black
---@field bg? color|number Background color. Default is white
---@field fg_disabled? color|number Disabled text color. Default is lightGray
---@field bg_disabled? color|number Disabled bg color, Default is gray
---@field fg_hovered? color|number Hover text color
---@field bg_hovered? color|number Hover bg color
---@field fg_click? color|number OnClick text color
---@field bg_click? color|number OnClick bg color
---@param args Checkbox Initialization table with fields above
---@return table object checkbox
function Checkbox.new(args)
	args.w = 1; args.h = 1

	local instance = Widget.new(args)

	--TO DO: check args
	instance.on = expect_args(args, 'on', 'boolean', 'nil') or false

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.black
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.white

	instance.fg_disabled = expect_args(args, 'fg_disabled', 'number', 'nil') or colors.lightGray
	instance.bg_disabled = expect_args(args, 'bg_disabled', 'number', 'nil') or colors.gray

	instance.fg_hovered = expect_args(args, 'fg_hovered', 'number', 'nil')
	instance.bg_hovered = expect_args(args, 'bg_hovered', 'number', 'nil')

	instance.fg_click = expect_args(args, 'fg_click', 'number', 'nil')
	instance.bg_click = expect_args(args, 'bg_click', 'number', 'nil')

	instance.draw = Checkbox.draw
	instance.pressed = Widget.pressed
	instance.onMouseDown = Button.onMouseDown
	instance.onMouseUp = Checkbox.onMouseUp

	return instance
end

return Checkbox

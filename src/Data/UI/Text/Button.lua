local Label = require 'Text.Label'
local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect

local Button = {}

function Button:draw()
	if self.disabled then
		if self.fg_disabled or self.bg_disabled then
			Label.draw(self, self.bg_disabled or self.bg, self.fg_disabled or self.fg)
		else
			Label.draw(self, colors.gray, colors.lightGray)
		end
	elseif self.held then
		if self.fg_click or self.bg_click then
			Label.draw(self, self.bg_click or self.bg, self.fg_click or self.fg)
		else
			Label.draw(self, self.fg, self.bg)
		end
	elseif self.hovered and (self.bg_hovered or self.fg_hovered) then
		Label.draw(self, self.bg_hovered or self.bg, self.fg_hovered or self.fg)
	else
		Label.draw(self, self.bg, self.fg)
	end
end

function Button:onMouseDown(btn, x, y)
	if self.disabled then return true end
	self.held = true
	self.dirty = true
	return true
end

function Button:onMouseUp(btn, x, y)
	if self.disabled then return true end
	if self.pressed and self:check(x, y) and self.held == true then self:pressed(btn, x, y) end
	self.held = false
	self.dirty = true
	return true
end

function Button:onMouseMove(btn, x, y)
	if self.disabled then return true end
	if self:check(x, y) then
		if not self.hovered then
			self.hovered = true
			self.dirty = true
		end
		return false
	end
	if self.hovered then
		self.hovered = nil
		self.dirty = true
	end
	return false
end

function Button:setDisabled(bool)
	self.disabled = expect(bool, 'bool', 'boolean', 'nil') or false
	self.dirty = true
end

---@class Button
---@field x number
---@field y number
---@field w number
---@field h number
---@field align? string Align for the text
---@field text? string The text which displayed on button
---@field bg color|number Main background color
---@field fg color|number Main text color
---@field bg_click? color|number OnClick bg color
---@field fg_click? color|number OnClick text color
---@field bg_disabled? color|number Disabled bg color
---@field fg_disabled? color|number Disabled text color
---@field bg_hovered? color|number Hover bg color
---@field fg_hovered? color|number Hover text color
---@param args Button
---@return table object Button
function Button.new(args)
	local instance = Widget.new(args)

	instance.disabled = expect_args(args, 'disabled', 'boolean', 'nil') or false

	instance.text = expect_args(args, 'text', 'string', 'nil') or ""

	--TODO?: check align better
	instance.align = expect_args(args, 'align', 'string', 'nil') or "center"

	instance.bg = expect_args(args, 'bg', 'number')
	instance.fg = expect_args(args, 'fg', 'number')

	instance.fg_click = expect_args(args, 'fg_click', 'number', 'nil')
	instance.bg_click = expect_args(args, 'bg_click', 'number', 'nil')

	instance.fg_disabled = expect_args(args, 'fg_disabled', 'number', 'nil') or colors.lightGray
	instance.bg_disabled = expect_args(args, 'bg_disabled', 'number', 'nil') or colors.gray

	instance.bg_hovered = expect_args(args, 'bg_hovered', 'number', 'nil')
	instance.fg_hovered = expect_args(args, 'fg_hovered', 'number', 'nil')

	instance.held = false
	instance.hovered = nil

	instance.draw = Button.draw
	instance.pressed = Widget.pressed
	instance.onMouseDown = Button.onMouseDown
	instance.onMouseUp = Button.onMouseUp
	instance.onMouseMove = Button.onMouseMove
	instance.setText = Label.setText
	instance.setDisabled = Button.setDisabled

	return instance
end

return Button

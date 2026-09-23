local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect

local Switch = {}

function Switch:draw()
	local frame = self.animation_frames[self.current_frame]
	for i = 1, 2 do
		local p = frame[i]
		term.setBackgroundColor(p.bgcol)
		term.setTextColor(p.txtcol)
		term.setCursorPos(self.x + i - 1, self.y)
		term.write(p.char)
	end
end

function Switch:startAnimation(direction)
	if self.animating then return end
	self.animating = true
	self.animation_direction = direction
	self.current_frame = (direction == "to_on") and "anim1" or "anim2"
	self.dirty = true
	self.timer_id = os.startTimer(self.animation_speed)
end

function Switch:updateAnimation()
	if self.animation_direction == "to_on" then
		if self.current_frame == "anim1" then
			self.current_frame = "anim2"
			self.timer_id = os.startTimer(self.animation_speed)
		elseif self.current_frame == "anim2" then
			self.current_frame = "on"
			self.animating = false
			self.on = true
		end
	elseif self.animation_direction == "to_off" then
		if self.current_frame == "anim2" then
			self.current_frame = "anim1"
			self.timer_id = os.startTimer(self.animation_speed)
		elseif self.current_frame == "anim1" then
			self.current_frame = "off"
			self.animating = false
			self.on = false
		end
	end
	self.dirty = true
end

function Switch:onMouseDown(btn, x, y)
	if self.disabled then return true end
	if not self.animating then
		self:startAnimation(self.on and "to_off" or "to_on")
		if self.pressed then self:pressed() end
	end
	return true
end

function Switch:onEvent(event, data)
	if event == "timer" and data[1] == self.timer_id then
		self:updateAnimation()
		return true
	end
	return Widget.onEvent(self, event, data)
end

function Switch:setDisabled(bool)
	self.disabled = expect(bool, 'bool', 'boolean', 'nil') or false
	self.dirty = true
end

---Creating new *object* of *class*
---@class Switch
---@field x number X pos in characters
---@field y number Y pos in characters
---@field on? boolean Initial on state
---@field thumb_color? color|number Color of the switch glyph
---@field bg_on? color|number Background color when on
---@field bg_off? color|number Background color when off
---@param args Switch Initialization table with fields above
---@return table object tumbler (switcher)
function Switch.new(args)
	args.w = 2
	args.h = 1
	local instance = Widget.new(args)

	instance.on = expect_args(args, 'on', 'boolean', 'nil') or false

	instance.thumb_color = expect_args(args, 'thumb_color', 'number', 'nil') or colors.white
	instance.bg_on = expect_args(args, 'bg_on', 'number', 'nil') or colors.blue
	instance.bg_off = expect_args(args, 'bg_off', 'number', 'nil') or colors.gray

	instance.animating = false
	instance.animation_frames = {
		off = {
			{ char = "\149", txtcol = instance.thumb_color, bgcol = instance.bg_off },
			{ char = " ",    txtcol = instance.bg_off,      bgcol = instance.bg_off }
		},
		anim1 = {
			{ char = "\149", txtcol = instance.bg_on,  bgcol = instance.thumb_color },
			{ char = " ",    txtcol = instance.bg_off, bgcol = instance.bg_off }
		},
		anim2 = {
			{ char = " ",    txtcol = instance.bg_on,       bgcol = instance.bg_on },
			{ char = "\149", txtcol = instance.thumb_color, bgcol = instance.bg_off }
		},
		on = {
			{ char = " ",    txtcol = instance.bg_on, bgcol = instance.bg_on },
			{ char = "\149", txtcol = instance.bg_on, bgcol = instance.thumb_color }
		}
	}
	instance.current_frame = instance.on and "on" or "off"
	instance.animation_speed = 0.05 -- Задержка между кадрами в секундах
	instance.timer_id = nil
	instance.animation_direction = nil -- "to_on" или "to_off"

	instance.draw = Switch.draw
	instance.startAnimation = Switch.startAnimation
	instance.updateAnimation = Switch.updateAnimation
	instance.onMouseDown = Switch.onMouseDown
	instance.onEvent = Switch.onEvent
	-- instance.pressed = Widget.pressed
	instance.setDisabled = Switch.setDisabled

	return instance
end

return Switch

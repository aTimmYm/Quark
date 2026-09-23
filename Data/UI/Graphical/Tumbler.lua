local g = require 'geometry'
local Widget = require 'Text.Widget'
local Tumbler = {}

function Tumbler.draw(self)
	-- local d = math.floor(self.h * 0.75)
	local d = self.h - math.floor(self.h * 0.175 + 0.5) * 2 -- (100% - 75%) / 2 = 0.125; diameter = 75% КАК ВАРИАНТ 0.175

	local bc = self.bc
	local tr = math.floor(self.h / 2)
	local cC = self.disabled and self.fc_dis or self.fc
	local x
	if self.on then
		x = self.x + self.w - tr - math.ceil(d / 2)
	else
		bc = self.bc_alt
		x = self.x + tr - math.floor(d / 2)
	end
	bc = self.disabled and self.bc_dis or bc
	g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, bc)
	g.draw_filled_circle(x, self.y + math.floor((self.h - d) / 2), d, cC)
end

function Tumbler.onMouseDown(self, btn, x, y)
	if self.disabled then return true end
	if not self.animating then
		self.on = not self.on
		self.dirty = true
		-- self:startAnimation(self.on and "to_off" or "to_on")
		self:pressed()
	end
	return true
end

function Tumbler.onEvent(self, event, data)
	if event == "timer" and data[1] == self.timer_id then
		self:updateAnimation()
		return true
	end
	onEvent(self, event, data)
end

---Creating new *object* of *class*
---@class Tumbler
---@field x number X pos in characters
---@field y number Y pos in characters
---@field bc? color|number Background color when off
---@field bc_alt? color|number Background color when on
---@field fc? color|number Color of the switch glyph
---@field on? boolean Initial on state
---@param args Tumbler Initialization table with fields above
---@return table object tumbler (switcher)
function Tumbler.new(args)
	local instance = Widget.new(args)

	instance.radius = args.h
	instance.bc = args.bc or colors.blue
	instance.fc = args.fc or colors.white
	instance.bc_alt = args.bc_alt or colors.lightGray
	instance.bc_dis = args.bc_dis or colors.lightGray
	instance.fc_dis = args.fc_dis or colors.gray
	instance.w = args.h * 2

	instance.draw = Tumbler.draw
	-- instance.startAnimation = Tumbler.startAnimation
	-- instance.updateAnimation = Tumbler.updateAnimation
	instance.onMouseDown = Tumbler.onMouseDown
	-- instance.onEvent = Tumbler.onEvent
	instance.pressed = Widget.pressed
	instance.setDisabled = Widget.setDisabled

	return instance
end

return Tumbler

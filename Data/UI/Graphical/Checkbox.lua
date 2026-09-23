local g = require 'geometry'
local Widget = require 'Text.Widget'
local Button = require 'Text.Button'
local Checkbox = {}

function Checkbox.draw(self)
	local bg_override, txtcol_override = colors.white, self.fc
	if self.on then
		bg_override = self.bc
	end
	if self.disabled then
		bg_override, txtcol_override = self.bc_dis or colors.gray, self.fc_dis or colors.lightGray
	end
	g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, bg_override)
	if self.on then
		local padding = 1
		local y1 = self.y + math.floor(self.h / 2) + padding
		local x2 = self.x + math.floor(self.w / 2)
		local y2 = self.y + self.h - padding
		paintutils.drawLine(self.x + 1 + padding, y1, x2, y2, txtcol_override)
		paintutils.drawLine(x2, y2, self.x + self.w - padding, self.y + 1 + padding, txtcol_override)
	end
end

function Checkbox.onMouseUp(self, btn, x, y)
	if self.disabled then return true end
	if self:check(x, y) then
		self.on = not self.on
		self:pressed(self.on)
	end
	-- self.held = nil
	self.dirty = true
	return true
end

---Creating new *object* of *class*
---@class Checkbox
---@field x number X pos in characters
---@field y number Y pos in characters
---@field on? boolean Initial checked state
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Checkbox Initialization table with fields above
---@return table object checkbox
function Checkbox.new(args)
	-- args.w = 1; args.h = 1
	local instance = Widget.new(args)

	instance.on = args.on or false

	instance.draw = Checkbox.draw
	instance.pressed = Widget.pressed
	instance.onMouseDown = Button.onMouseDown
	instance.onMouseUp = Checkbox.onMouseUp
	instance.setDisabled = Widget.setDisabled

	return instance
end

return Checkbox

-- local Widget = require 'Widget'
local _Button = require 'Text.Button'
local g = require 'geometry'
local font = require 'Font'

local Button = {}

function Button.draw(self)
	local bc = self.bc
	local fc = self.fc
	if self.held then
		bc = self.bc_cl or self.fc
		fc = self.fc_cl or self.bc
	end
	if self.disabled then
		bc = self.bc_dis or self.bc
		fc = self.fc_dis or self.fc
	end
	if self.radius then
		if self.outline then
			g.draw_rounded_rect_outline(self.x, self.y, self.w, self.h, self.radius, bc)
		else
			g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, bc)
		end
	else
		if self.outline then
			term.drawPixels(self.x, self.y, bc, self.w, 1)
			term.drawPixels(self.x, self.y + self.h, bc, self.w, 1)
			term.drawPixels(self.x, self.y, bc, 1, self.h)
			term.drawPixels(self.x + self.w - 1, self.y, bc, 1, self.h)
		else
			term.drawPixels(self.x, self.y, bc, self.w, self.h)
		end
	end
	font.simpleText(self.text, self.x, self.y, fc, self.w, self.h, self.align or 'center')
end

---@class Button
---@field x number
---@field y number
---@field w number
---@field h number
---@field align? string
---@field text? string
---@field bc color|number Main background color
---@field fc color|number Main text color
---@field bc_alt? color|number Disabled bg color
---@field fc_alt? color|number Disabled text color
---@field bc_hv? color|number Hover bg color
---@field fc_hv? color|number Hover text color
---@field bc_cl? color|number Pressed bg color
---@field fc_cl? color|number Pressed text color

---@param args Button
---@return object
function Button.new(args)
	local instance = _Button.new(args)

	instance.draw = Button.draw

	return instance
end

return Button

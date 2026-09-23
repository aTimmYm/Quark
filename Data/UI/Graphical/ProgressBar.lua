local g = require 'geometry'
local Widget = require 'Text.Widget'
local ProgressBar = {}

function ProgressBar.setValue(self, value)
	self.value = math.min(1, math.max(0, value))
	self:draw()
end

function ProgressBar.draw(self)
	local LoadX = math.floor(self.value * self.w)
	if self.radius then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, self.bc)
		g.draw_filled_rounded_rect(self.x, self.y, math.max(LoadX, self.h), self.h, self.radius, self.fc)
	else
		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
		term.drawPixels(self.x, self.y, self.fc, LoadX, self.h)
	end
end

---@class LoadingBar
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field bc color|number Main bg color
-- -@field orientation? string One of "center","top","bottom","filled"
---@field value? number Fill value between 0 and 1
-- -@field color_Loading color|number Color used for loaded portion
-- -@field color_NotLoaded color|number Color used for unloaded portion
---@param args LoadingBar Initialization table with fields above
function ProgressBar.new(args)
	local instance = Widget.new(args)

	instance.orientation = orientation or "center"
	instance.value = math.min(1, math.max(0, args.value or 0))

	instance.draw = ProgressBar.draw
	instance.setValue = ProgressBar.setValue

	return instance
end

return ProgressBar

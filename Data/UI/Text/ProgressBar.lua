local Widget = require 'Text.Widget'
local expect = require 'Utils'.expect
local expect_args = require 'Utils'.expect_args
local clamp = require 'Utils'.clamp

local ProgressBar = {}

function ProgressBar:setValue(value)
	expect(value, 'value', 'number')
	self.value = clamp(value, 0, 1) -- Is Utils.clamp a joke for you? -- no
	self:draw()
	-- screen.update()
end

function ProgressBar:draw()
	local LoadX = math.floor(self.value * self.w)
	if self.orientation == "top" then
		term.setBackgroundColor(self.bg)
		term.setTextColor(self.color_Loading)
		term.setCursorPos(self.x, self.y)
		term.write(('\131'):rep(LoadX))
		term.setTextColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(('\131'):rep(self.w - LoadX))
	elseif self.orientation == "center" then
		term.setBackgroundColor(self.bg)
		term.setTextColor(self.color_Loading)
		term.setCursorPos(self.x, self.y)
		term.write(('\140'):rep(LoadX))
		term.setTextColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(('\140'):rep(self.w - LoadX))
	elseif self.orientation == "bottom" then
		term.setBackgroundColor(self.color_Loading)
		term.setTextColor(self.bg)
		term.setCursorPos(self.x, self.y)
		term.write(('\143'):rep(LoadX))
		term.setBackgroundColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(('\143'):rep(self.w - LoadX))
	elseif self.orientation == "filled" then
		term.setBackgroundColor(self.color_Loading)
		term.setTextColor(self.bg)
		term.setCursorPos(self.x, self.y)
		term.write((' '):rep(LoadX))
		term.setBackgroundColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write((' '):rep(self.w - LoadX))
	end
end

---@class ProgressBar
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field bg? color|number Main bg color. Default is lightGray
---@field bg_fill? color|number Color used for loaded portion. Default is blue
---@field bg_empty? color|number Color used for unloaded portion. Default is white
---@field orientation? string One of "center","top","bottom","filled"
---@field value? number Progress value between 0 and 1. Default is 0
---@param args ProgressBar Initialization table with fields above
function ProgressBar.new(args)
	args.h = 1
	local instance = Widget.new(args)

	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.lightGray
	instance.bg_fill = expect_args(args, 'bg_fill', 'number', 'nil') or colors.blue
	instance.bg_empty = expect_args(args, 'bg_empty', 'number', 'nil') or colors.white

	instance.orientation = expect_args(args, 'orientation', 'string', 'nil') or "center"
	instance.value = expect_args(args, 'value', 'number', 'nil') and math.min(1, math.max(0, value)) or 0

	instance.draw = ProgressBar.draw
	instance.setValue = ProgressBar.setValue

	return instance
end

return ProgressBar

local Container = require 'Text.Container'
local drawFilledBox = require 'Utils'.drawFilledBox
local expect_args = require 'Utils'.expect_args

local Box = {}

function Box:onLayout()
	self.dirty = true
	Container.onLayout(self)
end

function Box:draw()
	drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bg)
end

---@class Box
---@field x number X pos: int
---@field y number Y pos: int
---@field w number Width: int
---@field h number Height: int
---@field bg color|number Background color
---@field fg? color|number Foreground/text color (optional)
---@param args Box Initialization table with fields above
---@return table object Box
function Box.new(args)
	local instance = Container.new(args)

	instance.bg = expect_args(args, 'bg', 'number')
	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white

	instance.draw = Box.draw
	instance.onLayout = Box.onLayout

	return instance
end

return Box

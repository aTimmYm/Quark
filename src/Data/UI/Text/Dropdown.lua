local Widget = require 'Text.Widget'
local Box = require 'Text.Box'
local Utils = require 'Utils'
local drawFilledBox = Utils.drawFilledBox
local expect_args = Utils.expect_args
local expect = Utils.expect

local Dropdown = {}

function Dropdown:draw()
	local element = self.items[self.item_index]
	term.setBackgroundColor(self.bg)
	term.setTextColor(self.fg)
	term.setCursorPos(self.x, self.y)
	if element then
		term.write(element:sub(1, self.w - 1) .. (' '):rep(self.w - 1 - #element) .. "\18")
	else
		term.write((' '):rep(self.w - 1) .. "\18")
	end
end

local function context_onFocus(self, focused)
	if not focused then
		self.root:removeChild(self)
		self.root:onLayout()
	end

	return true
end

local function contextMouseDown(self, btn, x, y)
	local dropdown = self.dropdown
	dropdown.item_index = y - self.y + 1
	if dropdown.pressed then dropdown:pressed(dropdown.items[dropdown.item_index]) end
	self.root:removeChild(self)
	self.root:onLayout()

	return true
end

local function contextDraw(self) -- ВРЕМЕННОЕ НАДО МЕНЯТЬ
	-- local dropdown = self.dropdown

	drawFilledBox(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1, self.bg)

	for i, v in ipairs(self.dropdown.items) do
		term.setCursorPos(self.x, self.y + i - 1)
		term.setBackgroundColor(self.bg)
		term.setTextColor(self.fg)
		term.write(v .. (''):rep(self.w - #v))
	end
end

function Dropdown:onMouseDown(btn, x, y)
	if self.disabled then return true end
	local box = Box.new { x = self.x, y = math.min(self.root.h - #self.items, math.max(1, self.y - (self.item_index - 1))), w = self.w, h = math.max(1, #self.items), bg = self.bg, fg = self.fg }
	box.dropdown = self
	self.root:addChild(box)
	self.root.focus = box
	box.draw = contextDraw
	box.onMouseDown = contextMouseDown
	box.onFocus = context_onFocus

	return true
end

function Dropdown:setDisabled(bool)
	self.disabled = expect(bool, 'bool', 'boolean', 'nil')
	self.dirty = true
end

---Creating new *object* of *class*
---@class Dropdown
---@field x number X pos in characters
---@field y number Y pos in characters
---@field items? string[] Options items
---@field maxSizeW? number Max value for width
---@field defaultValue? number Default selected index
---@field orientation? string "left" or "right"
---@field fg? color|number Foreground/text color
---@field bg? color|number Background color
---@param args Dropdown Initialization table with fields above
---@return table object dropdown
function Dropdown.new(args)
	local instance = Widget.new(args)
	instance.h = 1

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.gray
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.white

	instance.disabled = expect_args(args, 'disabled', 'boolean', 'nil') or false

	instance.items = expect_args(args, 'items', 'table', 'nil') or {}
	instance.item_index = 1
	if args.defaultValue then
		for i, v in ipairs(instance.items) do
			if tostring(v) == args.defaultValue then
				instance.item_index = i
				break
			end
		end
	end
	instance.orientation = orientation or "left"
	-- if type(maxSizeW) ~= "number" then maxSizeW = nil end
	instance.w = expect_args(args, 'maxSizeW', 'integer', 'nil') or math.max(5, Utils.getMaxListW(instance.items) + 1)

	instance.draw = Dropdown.draw
	-- instance.pressed = Widget.pressed
	instance.onMouseDown = Dropdown.onMouseDown
	instance.setDisabled = Dropdown.setDisabled

	return instance
end

return Dropdown

local g = require 'geometry'
local font = require 'Font'
local Widget = require 'Text.Widget'
local Box = require 'Graphical.Box'
local Dropdown = {}

function Dropdown.draw(self)
	local index_arr = self.array[self.item_index]
	local bc = self.disabled and self.bc_dis or self.bc
	local fc = self.disabled and self.fc_dis or self.fc

	if self.radius then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, 10, self.radius, bc)
	else
		term.drawPixels(self.x, self.y, bc, self.w, self.h)
	end
	font.simpleText('↕', self.x + self.w - 7, self.y, fc)
	if not index_arr then return end
	font.simpleText(index_arr, self.x + 3, self.y, fc)
end

local function context_onFocus(self, focused)
	-- local dropdown = self.dropdown
	if not focused then
		self.root:removeChild(self)
		self.root:onLayout()
	end

	return true
end

local function contextMouseDown(self, btn, x, y)
	local dropdown = self.dropdown
	local lY = y - self.y
	dropdown.item_index = math.floor(lY / 10) + 1
	dropdown:pressed(dropdown.array[dropdown.item_index])
	self.root:removeChild(self)
	self.root:onLayout()

	return true
end

local function contextDraw(self) -- ВРЕМЕННОЕ НАДО МЕНЯТЬ
	if self.radius then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, self.bc)
	else
		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	end
	local arr = self.dropdown.array
	for i = 1, #arr do
		font.simpleText(arr[i], self.x + 3, self.y + ((i - 1) * 10), self.fc)
	end
end

function Dropdown.onMouseDown(self, btn, x, y)
	if self.disabled then return true end

	local box = Box.new { x = self.x, y = math.min(self.root.h - #self.array * 10, math.max(0, self.y - ((self.item_index - 1) * 10))), w = self.w, h = math.max(10, #self.array * 10), bc = self.bc, fc = self.fc, radius = self.radius }
	box.dropdown = self
	self.root:addChild(box)
	self.root.focus = box
	box.draw = contextDraw
	box.onMouseDown = contextMouseDown
	box.onFocus = context_onFocus

	return true
end

---Creating new *object* of *class*
---@class Dropdown
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w? number Width in characters
---@field array? string[] Options array
---@field maxSizeW? number Max value for width
---@field defaultIndex? number Default selected index
---@field defaultValue? number Default selected value
---@field orientation? string "left" or "right"
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Dropdown Initialization table with fields above
---@return table object dropdown
function Dropdown.new(args)
	local instance = Widget.new(args)

	instance.array = args.items or args.array or {}
	instance.item_index = 1
	instance.fc_dis = args.fc_dis or colors.lightGray
	instance.bc_dis = args.bc_dis or colors.gray
	if args.defaultValue then
		for i = 1, #instance.array do
			if instance.array[i] == args.defaultValue then
				instance.item_index = i
				break
			end
		end
	elseif args.defaultIndex then
		if args.defaultIndex >= 1 and args.defaultIndex <= #instance.array then instance.item_index = args.defaultIndex end
	end
	instance.orientation = orientation or "left"
	if type(args.maxSizeW) ~= "number" then args.maxSizeW = nil end

	instance.draw = Dropdown.draw
	instance.pressed = Widget.pressed
	instance.onMouseDown = Dropdown.onMouseDown
	instance.setDisabled = Widget.setDisabled

	return instance
end

return Dropdown

local Widget = require 'Text.Widget'
local ScrollMixin = require 'Mixins.ScrollMixin'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect

local List = {}

function List:draw()
	term.setBackgroundColor(self.bg)
	term.setTextColor(self.fg)
	for i = self.scroll.pos_y + 1, math.min(self.h + self.scroll.pos_y, #self.items) do
		local index_arr = self.items[i]
		term.setCursorPos(self.x, (i - self.scroll.pos_y - 1) + self.y)
		term.write((index_arr .. (" "):rep(self.w - #index_arr)):sub(1, self.w))
	end
	if self.item and self.item_index then
		if (self.y + self.item_index - self.scroll.pos_y - 1) >= self.y and (self.y + self.item_index - self.scroll.pos_y - 1) <= (self.h + self.y - 1) then
			term.setBackgroundColor(self.fg)
			term.setTextColor(self.bg)
			term.setCursorPos(self.x, self.y + self.item_index - self.scroll.pos_y - 1)
			term.write((self.item .. (" "):rep(self.w - #self.item)):sub(1, self.w))
		end
	end
	if self.h > #self.items then
		term.setBackgroundColor(self.bg)
		term.setTextColor(self.fg)
		for i = #self.items, self.h - 1 do
			term.setCursorPos(self.x, i + self.y)
			term.write((" "):rep(self.w):sub(1, self.w))
		end
	end
end

function List:updateArr(array)
	expect(array, 'array', 'table')
	self.items = array
	self.item = nil
	self.item_index = nil
	self:updateDirty()
end

function List:onFocus(focused)
	if not focused then
		self.item = nil
		self.item_index = nil
		self.dirty = true
	end
	return true
end

function List:onMouseDown(btn, x, y)
	local i = y - self.y + 1 + self.scroll.pos_y
	if i <= #self.items then
		self.item = self.items[i]
		self.item_index = i
		if self.pressed then self:pressed(self.item, self.item_index, btn, x, y) end
		self.dirty = true
	end
	return true
end

function List:onKeyDown(key, held)
	if self.item then
		if key == keys.up then
			self.item_index = math.max(self.item_index - 1, 1)
			self.item = self.items[self.item_index]
			if self.item_index <= self.scroll.pos_y then
				self:scrollY(-(1 / self.scroll.sensitivity_y))
			end
		elseif key == keys.down then
			self.item_index = math.min(self.item_index + 1, #self.items)
			self.item = self.items[self.item_index]
			if self.item_index > math.min(self.h + self.scroll.pos_y, #self.items) then
				self:scrollY(1 / self.scroll.sensitivity_y)
			end
		elseif key == keys.home then
			self.scroll.pos_y = 0
			self.item_index = 1
			self.item = self.items[self.item_index]
		elseif key == keys['end'] then
			self.scroll.pos_y = self.scroll.max_y
			self.item_index = #self.items
			self.item = self.items[self.item_index]
		end
		self:updateDirty()
	end
	return true
end

function List:onMouseScroll(dir, x, y)
	return self:scrollY(dir)
end

function List:getScrollMaxY()
	return math.max(0, #self.items - self.h)
end

function List:updateDirty()
	if self.scrollbar_v then
		self.scrollbar_v.dirty = true
	end
	if self.scrollbar_h then
		self.scrollbar_h.dirty = true
	end
	self.dirty = true
end

function List:setDisabled(bool)
	self.disabled = expect(bool, 'bool', 'boolean', 'nil')
	self.dirty = true
end

---Creating new *object* of *class*
---@class List
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field items? table Array of strings to display
---@field bg? color|number Background color
---@field fg? color|number Foreground/text color
---@param args List Initialization table with fields above
---@return table object list
function List.new(args)
	local instance = Widget.new(args)

	instance.disabled = expect_args(args, 'disabled', 'boolean', 'nil') or false

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.black
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.white

	instance.items = expect_args(args, 'items', 'table', 'nil') or {}
	instance.item = nil
	instance.item_index = nil
	ScrollMixin.addMixin(instance)
	instance:initScroll(expect_args(args, 'sens_x', 'integer', 'nil'), expect_args(args, 'sens_y', 'integer', 'nil'))

	instance.draw = List.draw
	instance.updateArr = List.updateArr
	instance.updateDirty = List.updateDirty
	-- instance.pressed = Widget.pressed
	instance.onFocus = List.onFocus
	instance.onMouseScroll = List.onMouseScroll
	instance.onMouseDown = List.onMouseDown
	instance.onKeyDown = List.onKeyDown
	instance.getScrollMaxY = List.getScrollMaxY
	instance.setDisabled = List.setDisabled

	return instance
end

return List

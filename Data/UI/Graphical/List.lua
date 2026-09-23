-- local ScrollBox = require 'Text/'
local _List = require 'Text.List'
local font = require 'Font'

local List = {}

function List.draw(self)
	local scroll = self.scroll
	term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	for i = scroll.pos_y + 1, math.min(math.floor(self.h / 10) + scroll.pos_y, #self.items) do
		local index_arr = self.items[i]
		i = i - 1
		-- term.write(_sub(index_arr.._rep(" ", self.w - #index_arr), 1, self.w))
		font.simpleText(index_arr, self.x + 1, self.y + ((i - scroll.pos_y) * 10), self.fc)
	end
	if self.item and self.item_index then
		local iy = (self.y + (self.item_index - scroll.pos_y - 1) * 10)
		if iy >= self.y and iy <= (self.h + self.y - 1) then
			-- term.write(_sub(self.item.._rep(" ",self.w - #self.item), 1, self.w))
			local y = self.y + ((self.item_index - 1 - scroll.pos_y) * 10)
			term.drawPixels(self.x, y, self.bc_sel or self.fc, self.w, 10)
			font.simpleText(self.item, self.x + 1, y, self.bc_sel and self.fc or self.bc)
		end
	end
end

function List.onMouseDown(self, btn, x, y)
	local i = y - self.y + self.scroll.pos_y * 10
	i = math.floor(i / 10) + 1
	if i <= #self.items then
		self.item = self.items[i]
		self.item_index = i
		self.dirty = true
	end
	return true
end

function List.onMouseUp(self, btn, x, y)
	if not self:check(x, y) then
		self.item = nil
		self.item_index = nil
		self.dirty = true
		return
	else
		self:pressed(self.item, self.item_index)
	end
	return true
end

function List.onKeyDown(self, key, held)
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

function List.updateDirty(self)
	if self.scrollbar_v then
		self.scrollbar_v.dirty = true
	end
	if self.scrollbar_h then
		self.scrollbar_h.dirty = true
	end
	self.dirty = true
end

---Creating new *object* of *class*
---@class List
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field items table items of strings to display
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args List Initialization table with fields above
---@return table object list
function List.new(args)
	local instance = _List.new(args)

	function instance:getScrollMaxY()
		return math.max(0, #self.items - math.floor(self.h / 10))
	end

	instance.draw = List.draw
	instance.onMouseDown = List.onMouseDown
	instance.onMouseUp = List.onMouseUp
	instance.onKeyDown = List.onKeyDown

	return instance
end

return List

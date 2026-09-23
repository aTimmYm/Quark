local List = require 'Graphical.List'
local Font = require 'Font'

local CoontextMenu = {}

function CoontextMenu.onFocus(self, focused)
	if not focused then
		self.root:removeChild(self)
		self.item = nil
		self.item_index = nil
	end
end

function CoontextMenu.addItem(self, string, func)
	local wString = Font.calcWidth(string)
	self.w = self.w < wString and wString + 2 or self.w
	self.h = self.h + 10
	self.funcs[string] = func
	table.insert(self.items, string)
	self.dirty = true
end

function CoontextMenu.pressed(self, item)
	if self.funcs[item] then self.funcs[item]() end
	self:onFocus(false)
end

function CoontextMenu.new(args)
	local instance = List.new(args)

	instance.funcs = {}

	instance.addItem = CoontextMenu.addItem
	instance.pressed = CoontextMenu.pressed
	instance.onFocus = CoontextMenu.onFocus

	return instance
end

return CoontextMenu

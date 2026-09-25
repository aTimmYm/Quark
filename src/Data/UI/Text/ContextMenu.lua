local List = require 'Text.List'
local expect = require 'Utils'.expect

local ContextMenu = {}

function ContextMenu:onFocus(focused)
	if not focused then
		local parent = self.parent
		parent:removeChild(self)
		parent:onLayout()
		self.item = nil
		self.item_index = nil
	end
end

function ContextMenu:addItem(string, func)
	expect(string, 'string', 'string')
	expect(func, 'func', 'function')
	local wString = #string
	self.w = self.w < wString and wString or self.w
	self.funcs[string] = func
	table.insert(self.items, string)
	self.h = #self.items
	self.dirty = true
end

function ContextMenu:pressed(item)
	-- expect(item, 'item', 'integer')
	self.root.focus = nil
	if self.funcs[item] then self.funcs[item]() end
end

function ContextMenu.new(args)
	local instance = List.new(args)

	instance.funcs = {}

	instance.addItem = ContextMenu.addItem
	instance.pressed = ContextMenu.pressed
	instance.onFocus = ContextMenu.onFocus

	return instance
end

return ContextMenu

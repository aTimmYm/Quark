local Box = require 'Graphical.Box'
local Button = require 'Graphical.Button'
local Widget = require 'Text.Widget'
local font = require 'Font'
local ContextMenu = require 'Graphical.ContextMenu'

local Menu = {}

local childs = 0

local function addItem(self, string, func)
	return self.contextMenu:addItem(string, func)
end

function Menu.addMenu(self, string)
	local btn = Button.new { x = childs, y = 0, w = font.calcWidth(string), h = 9, text = string, bc = self.bc, fc = self.fc }
	self:addChild(btn)
	childs = childs + btn.w + 5

	btn.contextMenu = ContextMenu.new { x = 0, y = 0, w = 0, h = 0, bc = self.bc, fc = self.fc, items = {} }
	btn.addItem = addItem
	function btn:pressed()
		btn.parent:pressed(btn.contextMenu, self.x, self.y)
	end

	return btn
end

function Menu.new()
	local instance = Box.new { x = 20, y = 0, w = 100, h = 9, bc = colors.gray, fc = colors.white }

	instance.addMenu = Menu.addMenu
	instance.pressed = Widget.pressed

	return instance
end

return Menu

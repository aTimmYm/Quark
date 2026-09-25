local Box = require 'Text.Box'
local Button = require 'Text.Button'
local ContextMenu = require 'Text.ContextMenu'

local Menu = {}

local childs = 1

local function addItem(self, string, func)
	return self.contextMenu:addItem(string, func)
end

function Menu:addMenu(string)
	local btn = Button.new { x = childs, y = 1, w = #string, h = 1, text = string, bg = self.bg, fg = self.fg }
	self:addChild(btn)
	childs = childs + #string + 1

	btn.contextMenu = ContextMenu.new { x = 1, y = 1, w = 1, h = 1, bc = self.bg, fc = self.fg, items = {} }
	btn.addItem = addItem
	function btn:pressed()
		if btn.parent.pressed then btn.parent:pressed(btn.contextMenu, self.x, self.y) end
	end

	return btn
end

function Menu.new()
	local instance = Box.new { x = 4, y = 1, w = 20, h = 1, bg = colors.gray, fg = colors.white }

	instance.addMenu = Menu.addMenu

	return instance
end

return Menu

local UI = require 'Data.UI'
local drawFilledBox = UI.Utils.drawFilledBox
local clamp = UI.Utils.clamp
local _sidebar = {}

local function onResize(self, width, height)
	self.h = height
	self.treeview.h = self.h
end

local function onMouseDown(self, btn, x, y)
	if x == self.x + self.w - 1 then
		self.resize = true
	end
	return true
end

local function onMouseUp(self, btn, x, y)
	self.resize = nil
	return true
end

local function onMouseDrag(self, btn, x, y)
	if self.resize then
		local old_w = self.w
		self.w = clamp(x - self.x + 1, 4, self.root.w - 10)
		self.treeview.w = self.w - 1
		if self.onChangeSize and old_w ~= self.w then self:onChangeSize() end
	end
	return true
end

local function draw(self)
	local ey = self.h + self.y - 1
	local ex = self.x + self.w - 1
	drawFilledBox(self.x, self.y, ex, ey, self.bg)
	term.setTextColor(self.bg)
	term.setBackgroundColor(colors.white)
	for i = self.y, ey do
		term.setCursorPos(ex, i)
		term.write('\149')
	end
end

function _sidebar.init(args)
	local box = UI.Box {
		x = args.x, y = args.y,
		w = args.w, h = args.h,
		bg = args.bg, fg = args.fg
	}
	box.onResize = onResize
	box.onMouseDown = onMouseDown
	box.onMouseUp = onMouseUp
	box.onMouseDrag = onMouseDrag
	box.draw = draw

	local treeview = box:addChild(UI.TreeView {
		x = 1, y = 1,
		w = box.w - 1, h = box.h,
		bg = box.bg, fg = box.fg
	})
	function treeview:pressed(btn, item)
		if box.pressed then return box:pressed(btn, item) end
	end

	box.treeview = treeview

	return box
end

return _sidebar

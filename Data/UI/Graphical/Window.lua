local Box = require 'Graphical.Box'
local Widget = require 'Text.Widget'
local Button = require 'Graphical.Button'
local g = require 'geometry'
local font = require 'Font'
local Container = require 'Graphical.Container'

local Window = {}

function Window.draw(self)
	if not self.visible then return end
	local radius = self.maximized and 0 or self.radius
	if self.bordered ~= 0 then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.bordered + radius, radius, self.bc)
	end
	if self.bordered == 10 and font.calcWidth(self.title) < self.w - 48 then
		font.drawText(self.title, self.x + 24, self.y, self.fc, self.w - 48, self.bordered, 'center')
	end
	local buff = self.buffer
	buff.setVisible(true)
	buff.setVisible(false)
	-- term.drawPixels(self.x, self.y, colors.red, self.w, self.h)
	-- if self.bordered == 0 then return end
	-- term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
end

function Window.onMouseDown(self, btn, x, y)
	-- log('Y(W):'..tostring(y))
	-- local border = self.bordered == 0 and 0 or 11
	local cY = y - self.y
	local cX = x - self.x
	if self.bordered ~= 0 and cY < self.bordered then
		self.dragging = { offsetX = x - self.x, offsetY = cY }
	elseif cX >= self.w - 2 and cY >= self.h - 2 and not self.maximized and self.resizeble then
		self.resizing = 'wh'
		-- elseif x >= self.w + self.x and self.resizeble then
		-- 	self.resizing = 'w'
		-- elseif y >= self.h + self.y and self.resizeble then
		-- 	self.resizing = 'h'
	else
		-- log(x - self.x)
		-- log(cY - self.bordered)
		self:pressed('mouse_click', btn, x - self.x, cY - self.bordered)
		self:onLayout()
	end

	return true
end

function Window.onMouseUp(self, btn, x, y)
	self.dragging = nil
	self.resizing = nil
	self.offsetX = 0
	local cY = y - self.y
	if cY < self.bordered then return end
	self:pressed('mouse_up', btn, x - self.x, cY - self.bordered)
	self:onLayout()
	return true
end

function Window.onMouseScroll(self, dir, x, y)
	local cY = y - self.y
	if cY < self.bordered then return end
	self:pressed('mouse_scroll', dir, x - self.x, cY - self.bordered)
	self:onLayout()
	return true
end

function Window.onMouseDrag(self, btn, x, y)
	local cY = y - self.y
	if self.dragging and self.bordered ~= 0 then
		local drag = self.dragging
		if self.maximized then self:maximize(x) end
		self.localX = x - drag.offsetX + self.offsetX
		self.localY = y - drag.offsetY
	elseif self.resizing then
		local nW, nH = self.w, self.h
		if self.resizing == 'w' then
			nW = math.max(self.min_w, x - self.x + 1)
			-- self.w = math.max(self.min_w, x - self.x + 1)
			-- return
		elseif self.resizing == 'h' then
			nH = math.max(self.min_h, cY + 1)
		elseif self.resizing == 'wh' then
			nW = math.max(self.min_w, x - self.x + 1)
			nH = math.max(self.min_h, cY + 1)
			-- self.h = math.max(self.min_h, cY + 1)
			-- return
		end
		self.w = nW
		self.h = nH
		self:pressed('term_resize', self.w, self.h - self.bordered)
	else
		self:pressed('mouse_drag', btn, x - self.x, cY - self.bordered)
		return true
	end
	self.parent:onLayout()
	self.buffer.reposition(self.x, self.y + self.bordered, self.w, self.h - self.bordered)

	return true
end

function Window.close(self)
	-- self.removeChild(true)
	-- self = nil
	-- return true
	self:pressed('terminate')
end

function Window.maximize(self, cX)
	if self.maximized then
		if cX then self.offsetX = math.floor((self.oldW / self.w) * cX) end
		self.localX, self.localY = self.oldX + self.offsetX, self.oldY
		self.w, self.h = self.oldW, self.oldH
	else
		self.oldX, self.oldY = self.localX, self.localY
		self.oldW, self.oldH = self.w, self.h
		self.localX, self.localY = 0, 0
		self.w, self.h = self.root.w, self.root.h
	end
	self.maximized = not self.maximized
	self.buffer.reposition(self.localX, self.localY + self.bordered, self.w, self.h - self.bordered)
	self:pressed('term_resize', self.w, self.h - self.bordered)
	self.root:onLayout()
	return true
end

function Window.minimize(self)
	self.visible = false
	self.parent:onLayout()
	-- self.parent:removeChild(self)
	return true
end

function Window.sortLevel(self, p)
	for i = 1, #p.children do
		p.children[i]._index = i
	end

	table.sort(p.children,
		function(a, b)
			if a.level == b.level then
				return a._index < b._index
			end
			return a.level < b.level
		end
	)

	for i = 1, #p.children do
		p.children[i]._index = nil
	end
end

function Window.onFocus(self, focused)
	-- if self.level == 1 then return end
	local p = self.parent
	-- local root = self.root
	if focused then
		-- if root.modal then
		-- 	root:removeChild(root.modal)
		-- end
		self:pressed('menu_add')
		p:removeChild(self)
		p:addChild(self)
		p:onLayout()
		self.buttons.close.bc = colors.red
		self.buttons.minimize.bc = colors.orange
		self.buttons.maximize.bc = colors.green
	else
		self:pressed('menu_add')
		self.buttons.close.bc = colors.lightGray
		self.buttons.minimize.bc = colors.lightGray
		self.buttons.maximize.bc = colors.lightGray
	end
	self:pressed('wm_focus', focused)

	if p then self:sortLevel(p) end

	-- table.sort(p.children, function (a, b) return a.level < b.level end)
end

function Window.onKeyDown(self, key, held)
	self:pressed('key', key, held)
end

function Window.onKeyUp(self, key)
	self:pressed('key_up', key)
end

function Window.onPaste(self, text)
	self:pressed('paste', text)
end

function Window.onCharTyped(self, chr)
	self:pressed('char', chr)
end

function Window.setPosition(self, x, y)
	self.localX, self.localY = x, y
	self.buffer.reposition(x, y + self.bordered)
end

function Window.setResizeble(self, bool)
	self.resizeble = bool
end

function Window.setLevel(self, level)
	self.level = level
end

function Window.setSize(self, w, h)
	self.w, self.h = w, h + self.bordered
	self.buffer.reposition(self.x, self.y + self.bordered, w, h)
end

function Window.setBorder(self, bool)
	if bool then
		self.bordered = 10
	else
		self.h = self.h - 10
		self.bordered = 0
		self.children = {}
	end
	self.buffer.reposition(self.x, self.y + self.bordered, self.w, self.h - self.bordered)
	return true
end

function Window.onEvent(self, event, data)
	if not self.visible then return end
	return Container.onEvent(self, event, data)
end

local function onFocus(self, focused)
	if focused then
		self.parent:onFocus(true)
	end
end

function Window.new(args)
	local instance = Box.new(args)

	instance.dragging = false
	instance.min_w = args.min_w or 50
	instance.min_h = args.min_h or 25
	instance.title = args.title or 'Window'
	instance.visible = true
	instance.bordered = 10
	instance.resizeble = true
	instance.maximized = false
	instance.offsetX = 0
	instance.level = 2
	-- instance.buffer = {}
	-- instance.term = args.term

	instance.buttons = {}
	local old = Button.draw
	local btn_draw = function(self)
		if not instance.visible then return true end
		old(self)
	end
	local btnWH = 4

	instance.buttons.close = Button.new { x = 3, y = 3, w = btnWH, h = btnWH, radius = 6, fc = colors.lightGray, bc = colors.lightGray, fc_cl = colors.lightGray }
	instance.buttons.close.draw = btn_draw
	instance.buttons.close.onFocus = onFocus
	instance:addChild(instance.buttons.close)
	instance.buttons.close.pressed = function()
		instance:close()
	end

	instance.buttons.minimize = Button.new { x = 11, y = 3, w = btnWH, h = btnWH, radius = 4, fc = colors.lightGray, bc = colors.lightGray, fc_cl = colors.lightGray }
	instance.buttons.minimize.draw = btn_draw
	instance.buttons.minimize.onFocus = onFocus
	instance:addChild(instance.buttons.minimize)
	instance.buttons.minimize.pressed = function(self, btn, x, y)
		instance:minimize()
	end

	instance.buttons.maximize = Button.new { x = 19, y = 3, w = btnWH, h = btnWH, radius = 4, fc = colors.lightGray, bc = colors.lightGray, fc_cl = colors.lightGray }
	instance.buttons.maximize.draw = btn_draw
	instance.buttons.maximize.onFocus = onFocus
	instance:addChild(instance.buttons.maximize)
	instance.buttons.maximize.pressed = function(self, btn, x, y)
		instance:maximize()
	end
	instance:onLayout()

	instance.onMouseDown = Window.onMouseDown
	instance.onMouseUp = Window.onMouseUp
	instance.onMouseScroll = Window.onMouseScroll
	instance.onMouseDrag = Window.onMouseDrag
	instance.draw = Window.draw
	instance.minimize = Window.minimize
	instance.maximize = Window.maximize
	instance.close = Window.close
	instance.onFocus = Window.onFocus
	instance.setBorder = Window.setBorder
	instance.onKeyDown = Window.onKeyDown
	instance.onKeyUp = Window.onKeyUp
	instance.onPaste = Window.onPaste
	instance.onCharTyped = Window.onCharTyped
	instance.onEvent = Window.onEvent
	instance.setPosition = Window.setPosition
	instance.setResizeble = Window.setResizeble
	instance.setSize = Window.setSize
	instance.setLevel = Window.setLevel
	instance.sortLevel = Window.sortLevel
	instance.pressed = Widget.pressed

	return instance
end

return Window

local Box = require 'Text.Box'
local Button = require 'Text.Button'
local Container = require 'Text.Container'

local Window = {}

local hex = {}
do
	local hexicemal = '0123456789abcdef'
	for i = 1, 16 do
		hex[i - 1] = hexicemal:sub(i, i)
	end
end

function Window:draw()
	if not self.visible then return end
	-- Utils.drawFilledBox(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1, colors.purple)
	local tx = math.floor((self.w - #self.title - 3) / 2) + 1
	local text, fg = (' '):rep(self.w), ('0'):rep(self.w)
	local bg = hex[(self.titleTransparent and self.bg or colors.gray)]:rep(self.w)
	for i = 0, self.bordered - 1 do
		term.setCursorPos(self.x, self.y + i)
		term.blit(text, fg, bg)
	end
	if self.bordered == 1 and not self.titleHidden then
		term.setCursorPos(self.x + tx, self.y)
		term.setTextColor(self.title_color or colors.white)
		term.setBackgroundColor(self.bg)
		term.write(self.title)
	elseif self.bordered == 3 and not self.titleHidden then
		term.setBackgroundColor(self.bg)
		term.setTextColor(self.title_color or colors.white)
		term.setCursorPos(self.x + tx + 1, self.y + 1)
		term.write(self.title)
	end

	for i = 1, #self.buffer do
		local line = self.buffer[i]
		local y = self.fullSizeContentView and self.y + i - 1 or self.y + i - 1 + self.bordered
		term.setCursorPos(self.x, y)
		term.blit(line[1], line[2], line[3])
	end
end

function Window:onMouseDown(btn, x, y)
	-- local border = self.bordered == 0 and 1 or 0
	if y <= self.bordered + self.y - 1 and self.bordered > 0 then
		self.dragging = { offsetX = x - self.x, offsetY = y - self.y }
		return true
	elseif x == self.w + self.x - 1 and y == self.h + self.y - 1 and not self.maximized then
		self.resizing = true
		-- self.resizing_start = {x = x, y = y}
	end
	if self.pressed then self:pressed('mouse_click', btn, x - self.x + 1, y - self.y - self.bordered + 1) end
	self.sendMouseUp = true
	self:onLayout()
	return true
end

function Window:onMouseUp(btn, x, y)
	self.dragging = nil
	self.resizing = nil
	self.offsetX = 0
	if y < self.y + self.bordered and not self.sendMouseUp then return end
	self.sendMouseUp = nil
	-- local border = self.bordered == 0 and 1 or 0
	if self.pressed then self:pressed('mouse_up', btn, x - self.x + 1, y - self.y - self.bordered + 1) end
	-- self:onLayout()
	return true
end

function Window:onMouseScroll(dir, x, y)
	if y == self.y then return end
	if self.pressed then self:pressed('mouse_scroll', dir, x - self.x + 1, y - self.y) end
	-- self:onLayout()
	return true
end

function Window:onMouseDrag(btn, x, y)
	-- local border = self.bordered == 0 and 1 or 0
	if self.dragging and self.bordered ~= 0 then
		local drag = self.dragging
		if self.maximized then self:maximize(x) end
		self.localX = x - drag.offsetX + self.offsetX
		self.localY = y - drag.offsetY
	elseif self.resizing and self.resizeble then
		local oldW, oldH = self.w, self.h - self.bordered
		self.w = math.max(self.min_w, x - self.x + 1)
		self.h = math.max(self.min_h, y - self.y + 1)
		local text, fg, bg = (' '):rep(self.w), hex[self.buffer.colors.fg]:rep(self.w),
			hex[self.buffer.colors.bg]:rep(self.w)
		local rel_h = self.h - self.bordered
		if self.w > oldW then
			for i = 1, oldH do
				local line = self.buffer[i]
				line[1] = line[1] .. text:sub(oldW + 1)
				line[2] = line[2] .. fg:sub(oldW + 1)
				line[3] = line[3] .. bg:sub(oldW + 1)
			end
		elseif self.w < oldW then
			for i = 1, oldH do
				local line = self.buffer[i]
				line[1] = line[1]:sub(1, self.w)
				line[2] = line[2]:sub(1, self.w)
				line[3] = line[3]:sub(1, self.w)
			end
		end
		if rel_h > oldH then
			for i = oldH + 1, rel_h do
				self.buffer[i] = { text, fg, bg }
			end
		elseif rel_h < oldH then
			for i = rel_h + 1, oldH do
				self.buffer[i] = nil
			end
		end
		if self.pressed then self:pressed('term_resize', self.w, self.h - self.bordered) end
	else
		if self.pressed then self:pressed('mouse_drag', btn, x - self.x + 1, y - self.y - self.bordered + 1) end
		return true
	end
	self.parent:onLayout()
	-- self.buffer.reposition(self.x, self.y + self.bordered, self.w, self.h - self.bordered)

	return true
end

function Window:close()
	-- self.removeChild(true)
	-- self = nil
	-- return true
	if self.pressed then self:pressed('terminate') end
end

function Window:maximize(cX)
	if self.maximized then
		if cX then self.offsetX = math.floor((self.oldW / self.w) * cX) end
		self.localX, self.localY = self.oldX + self.offsetX, self.oldY
		self.w, self.h = self.oldW, self.oldH
	else
		self.oldX, self.oldY = self.localX, self.localY
		self.oldW, self.oldH = self.w, self.h
		self.localX, self.localY = 1, 2
		self.w, self.h = self.root.w, self.root.h - 1
	end
	self.maximized = not self.maximized
	-- self.buffer.reposition(self.localX, self.localY + self.bordered, self.w, self.h - self.bordered)
	if self.pressed then self:pressed('term_resize', self.w, self.h - self.bordered) end
	return true
end

function Window:minimize()
	-- self.visible = false
	-- -- self.parent:onLayout()
	-- -- self.parent:removeChild(self)
	-- return true
end

function Window:sortLevel(p)
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

function Window:onFocus(focused)
	-- if self.level == 1 then return end
	local p = self.parent
	local buttons = self.buttons
	if focused then
		-- self:pressed('menu_add')
		p:removeChild(self)
		p:addChild(self)
		if not buttons.close.disabled then buttons.close.fg = colors.red end
		if not buttons.minimize.disabled then buttons.minimize.fg = colors.orange end
		if not buttons.maximize.disabled then buttons.maximize.fg = colors.green end
	else
		-- self:pressed('menu_add')
		buttons.close.fg = colors.lightGray
		buttons.minimize.fg = colors.lightGray
		buttons.maximize.fg = colors.lightGray
	end
	self:onLayout()
	if self.pressed then self:pressed('wm_focus', focused) end

	if p then self:sortLevel(p) end

	-- table.sort(p.children, function (a, b) return a.level < b.level end)
end

function Window:onKeyDown(key, held)
	if self.pressed then self:pressed('key', key, held) end
end

function Window:onKeyUp(key)
	if self.pressed then self:pressed('key_up', key) end
end

function Window:onPaste(text)
	if self.pressed then self:pressed('paste', text) end
end

function Window:onCharTyped(chr)
	if self.pressed then self:pressed('char', chr) end
end

function Window:setPosition(x, y)
	self.localX, self.localY = x, y
	self.buffer.reposition(x, y)
end

function Window:setResizeble(bool)
	self.resizeble = bool
end

function Window:setLevel(level)
	self.level = level
end

function Window:setBorder(bool)
	if bool then
		self.bordered = 1
	else
		self.h = self.h - 1
		self.bordered = 0
		self.children = {}
	end
	-- self.buffer.reposition(self.x, self.y + self.bordered, self.w, self.h - self.bordered)
	return true
end

-- function Window.setSize(self, w, h)
-- 	self.w, self.h = w, h
-- end

function Window:onEvent(event, data)
	if not self.visible then return end
	return Container.onEvent(self, event, data)
end

local function onFocus(self, focused)
	if focused then
		self.parent:onFocus(true)
	end
end

function Window:focusPostDraw()
	local buff = self.buffer
	local cursor = buff.cursor
	local col = buff.colors
	term.setCursorPos(cursor.x + self.x - 1, cursor.y + self.y - 1 + self.bordered)
	term.setTextColor(col.fg)
	term.setCursorBlink(buff.blink)
end

-- local btn_draw = function(self)
-- 	if not self.parent.visible then return true end
-- 	self:oldDraw()
-- end

function Window.new(args)
	local instance = Box.new(args)

	instance.title_color = args.title_color
	-- instance.style = args.style
	instance.dragging = false
	-- instance.drag_start = { x = args.x or 1, y = args.y or 1 }
	instance.min_w = args.min_w or 5
	instance.min_h = args.min_h or 3
	instance.title = args.title or 'Window'
	instance.visible = true
	instance.bordered = args.style.toolbar and 3 or 1
	instance.resizeble = true
	instance.maximized = false
	instance.offsetX = 0
	-- instance.level = 2
	instance.titleHidden = args.style.titleHidden
	instance.titleTransparent = args.style.titleTransparent
	instance.fullSizeContentView = args.style.fullSizeContentView
	local buffer = {
		cursor = { x = 1, y = 1 },
		colors = { fg = 0, bg = args.bg or instance.bg },
		blink = false
	}
	instance.buffer = buffer
	for i = 1, args.h do
		buffer[i] = {
			(' '):rep(args.w),
			hex[buffer.colors.fg]:rep(args.w),
			hex[buffer.colors.bg]:rep(args.w)
		}
	end
	instance.term = {
		write = function(text)
			text = tostring(text)
			local col = buffer.colors
			local tLen = #text
			if not col.fg then log(debug.traceback()) end
			instance.term.blit(text, hex[col.fg]:rep(tLen), hex[col.bg]:rep(tLen))
		end,
		blit = function(sText, sTCol, sBCol)
			local tLen = #sText
			if tLen ~= #sTCol and tLen ~= #sBCol then return error('term.blit: args must be a same lenght') end

			local cursor = buffer.cursor
			local line = buffer[cursor.y]
			if not line then return end
			local sx = cursor.x - 1
			local ex = cursor.x + tLen
			line[1] = (line[1]:sub(1, sx) .. sText .. line[1]:sub(ex, -1)):sub(1,
				instance.w)
			line[2] = (line[2]:sub(1, sx) .. sTCol .. line[2]:sub(ex, -1)):sub(1,
				instance.w)
			line[3] = (line[3]:sub(1, sx) .. sBCol .. line[3]:sub(ex, -1)):sub(1,
				instance.w)
			cursor.x = ex
			-- instance:onLayout()
			-- instance.dirty = true

			if not instance.root.needRedraw then
				instance.root.needRedraw = true
				instance.onDirty()
			end
		end,
		clear = function()
			for i = 1, args.h do
				buffer[i] = {
					(' '):rep(args.w),
					('0'):rep(args.w),
					('f'):rep(args.w)
				}
			end
		end,
		setCursorPos = function(x, y)
			buffer.cursor.x, buffer.cursor.y = x, y
		end,
		setCursorBlink = function(bool)
			if type(bool) ~= 'boolean' then error('daun?') end
			buffer.blink = bool
		end,
		setBackgroundColor = function(color)
			buffer.colors.bg = color
		end,
		setTextColor = function(color)
			buffer.colors.fg = color
		end,
		getCursorPos = function()
			return buffer.cursor.x, buffer.cursor.y
		end,
		getBackgroundColor = function()
			return buffer.colors.bg
		end,
		getTextColor = function()
			return buffer.colors.fg
		end,
		getSize = function()
			return instance.w, instance.h - instance.bordered
		end
	}
	instance.term.setBackgroundColour = instance.term.setBackgroundColor
	instance.term.setTextColour = instance.term.setTextColor
	instance.term.getBackgroundColour = instance.term.getBackgroundColor
	instance.term.getTextColour = instance.term.getTextColor

	instance.buttons = {}
	-- local old = Button.draw
	local x, y = args.style.toolbar and 1 or 0, args.style.toolbar and 2 or 1
	for k, v in pairs { 'close', 'minimize', 'maximize' } do
		instance.buttons[v] = Button.new { x = x + k, y = y, w = 1, h = 1, text = '\7', fg = colors.lightGray, bg = colors.gray, fg_click = colors.lightGray, disabled = args.style[v .. 'Disable'] }
		instance.buttons[v].oldDraw = Button.draw
		-- instance.buttons[v].draw = btn_draw
		instance.buttons[v].onFocus = onFocus
		instance.buttons[v].focusPostDraw = function(self)
			instance:focusPostDraw()
		end
		instance:addChild(instance.buttons[v])
		instance.buttons[v].pressed = function()
			instance[v](instance)
		end
	end

	instance:onLayout()

	instance.onMouseDown = Window.onMouseDown
	instance.onDirty = function() end
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
	instance.setLevel = Window.setLevel
	instance.sortLevel = Window.sortLevel
	instance.focusPostDraw = Window.focusPostDraw

	return instance
end

return Window

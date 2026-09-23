local expect_args = require 'Utils'.expect_args

local Widget = {}

function Widget:check(x, y)
	return (x >= self.x and x < self.w + self.x and
		y >= self.y and y < self.h + self.y)
end

function Widget:onKeyDown(key, held) return true end

function Widget:onKeyUp(key) return true end

function Widget:onCharTyped(chr) return true end

function Widget:onPaste(text) return true end

function Widget:onMouseDown(btn, x, y) return true end

function Widget:onMouseMove(btn, x, y) return false end

function Widget:onMouseUp(btn, x, y) return true end

function Widget:onMouseScroll(dir, x, y) return false end

function Widget:onMouseDrag(btn, x, y) return true end

function Widget:onLayout()
	self.dirty = true
end

function Widget:draw() end

function Widget:redraw()
	if self.dirty then
		self:draw()
		self.dirty = false
	end
end

function Widget:onEvent(event, data)
	if event == "mouse_drag" then
		return self:onMouseDrag(data[1], data[2], data[3])
	elseif event == "mouse_up" then
		return self:onMouseUp(data[1], data[2], data[3])
	elseif event == "mouse_click" then
		if self.root then self.root.focus = self end
		return self:onMouseDown(data[1], data[2], data[3])
	elseif event == "mouse_scroll" then
		return self:onMouseScroll(data[1], data[2], data[3])
	elseif event == "mouse_move" then
		return self:onMouseMove(data[1], data[2], data[3])
	elseif event == "char" then
		return self:onCharTyped(data[1])
	elseif event == "key" then
		return self:onKeyDown(data[1], data[2])
	elseif event == "key_up" then
		return self:onKeyUp(data[1])
	elseif event == "paste" then
		return self:onPaste(data[1])
	end

	return false
end

---Basic *class*. Using automatically to create all another *classes*.
---@class Widget
---@field x number
---@field y number
---@field w number
---@field h number
---@param args Widget
---@return table object Widget
function Widget.new(args)
	local instance = {}

	instance.x = expect_args(args, 'x', 'integer')
	instance.y = expect_args(args, 'y', 'integer')
	instance.w = expect_args(args, 'w', 'integer')
	instance.h = expect_args(args, 'h', 'integer')
	instance.parent = nil
	instance.dirty = true

	instance.check = Widget.check
	instance.onKeyDown = Widget.onKeyDown
	instance.onKeyUp = Widget.onKeyUp
	instance.onCharTyped = Widget.onCharTyped
	instance.onPaste = Widget.onPaste
	instance.onMouseDown = Widget.onMouseDown
	instance.onMouseMove = Widget.onMouseMove
	instance.onMouseUp = Widget.onMouseUp
	instance.onMouseScroll = Widget.onMouseScroll
	instance.onMouseDrag = Widget.onMouseDrag
	instance.draw = Widget.draw
	instance.redraw = Widget.redraw
	instance.onLayout = Widget.onLayout
	instance.onEvent = Widget.onEvent

	return instance
end

return Widget

local Widget = require 'Text.Widget'
local clamp = require 'Utils'.clamp
local expect = require 'Utils'.expect

local Scrollbar = {}

function Scrollbar:draw()
	local slider_height = self:getSliderHeight()
	local slider_offset = self:getSliderOffset()
	local slider_y_start = self.y + 1 + slider_offset

	local bg = self.bg
	term.setBackgroundColor(bg)
	for y = self.y + 1, slider_y_start - 1 do
		term.setCursorPos(self.x, y)
		term.write(" ")
	end
	for y = slider_y_start + slider_height, self.y + self.h - 2 do
		term.setCursorPos(self.x, y)
		term.write(" ")
	end

	term.setTextColor(self.held == 1 and colors.lightGray or self.fg)
	term.setCursorPos(self.x, self.y)
	term.write("\30")

	term.setTextColor(self.held == 3 and colors.lightGray or self.fg)
	term.setCursorPos(self.x, self.y + self.h - 1)
	term.write("\31")

	term.setBackgroundColor(self.held == 2 and colors.lightGray or self.fg)
	term.setTextColor(bg)
	for y = slider_y_start, math.min(slider_y_start + slider_height - 1, self.y + self.h - 2) do
		term.setCursorPos(self.x, y)
		term.write("\149")
	end
end

function Scrollbar:setObj(obj)
	self.obj = expect(obj, 'obj', 'table')
	self.bg = self.obj.bg
	self.fg = self.obj.fg
	obj:attachScrollbar(self, "vertical")
	self.dirty = true
end

function Scrollbar:getTrackHeight()
	return self.h - 2
end

function Scrollbar:checkIn(x, y)
	if y == self.y then
		self.held = 1
		return true
	elseif y == self.y + self.h - 1 then
		self.held = 3
		return true
	end
	return false
end

function Scrollbar:isOnSlider(y)
	local slider_offset = self:getSliderOffset()
	local slider_height = self:getSliderHeight()
	local slider_y_start = self.y + 1 + slider_offset
	return y >= slider_y_start and y <= slider_y_start + slider_height - 1
end

function Scrollbar:onMouseUp(btn, x, y)
	if self.held == 1 and self:check(x, y) and y == self.y then
		self.obj:scrollY(-1)
	elseif self.held == 3 and self:check(x, y) and y == self.y + self.h - 1 then
		self.obj:scrollY(1)
	end
	self.held = 0
	self.dirty = true
	return true
end

function Scrollbar:onMouseScroll(dir, x, y)
	if self:check(x, y) then
		self.obj:scrollY(dir)
		return true
	end
	return false
end

function Scrollbar:getSliderHeight()
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return 0 end

	local total_items = self.obj:getScrollMaxY() + self.obj.h
	local visible_items = self.obj.h or 0

	if total_items <= 0 then
		return track_height
	end

	if visible_items >= total_items then
		return track_height
	end

	local raw = (visible_items * track_height) / total_items
	local h = math.floor(raw + 0.5)
	if h < 1 then h = 1 end
	if h > track_height then h = track_height end
	return h
end

function Scrollbar:getMaxSliderOffset()
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return 0 end
	local slider_height = self:getSliderHeight()
	return math.max(0, track_height - slider_height)
end

function Scrollbar:getSliderOffset()
	local max_offset = self:getMaxSliderOffset()
	if max_offset == 0 then return 0 end

	local scrollmax = self.obj:getScrollMaxY()
	if scrollmax <= 0 then return 0 end

	local pos = self.obj:getScrollPosY()
	pos = clamp(pos, 0, scrollmax)
	local frac = pos / scrollmax

	return clamp(math.floor(frac * max_offset + 0.5), 0, max_offset)
end

function Scrollbar:onMouseDown(btn, x, y)
	if self:checkIn(x, y) then
		self.dirty = true
		return true
	end
	self.held = 2

	if self:isOnSlider(y) then
		self.drag_offset = y - self:getSliderOffset() - self.y - 1
		self.dirty = true
		return true
	end

	local track_top = self.y + 1
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return true end

	local slider_height = self:getSliderHeight()
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxY()

	local click_rel = clamp(y - track_top, 0, track_height - 1)

	local half = (slider_height - 1) / 2
	local desired_offset_f = click_rel - half
	local desired_offset = math.floor(desired_offset_f + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = 0
	if max_offset > 0 then
		frac = desired_offset / max_offset
	end
	local pos = math.floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosY(pos)

	return true
end

function Scrollbar:onMouseDrag(btn, x, y)
	if self.held == 1 or self.held == 3 then return end
	local track_top = self.y + 1
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxY()

	local desired_offset = math.floor((y - track_top) - self.drag_offset + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = desired_offset / max_offset
	local pos = math.floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosY(pos)

	return true
end

---Creating new *object* of *class* "scrollbar" which connected at another *object*
---@class Scrollbar
---@param obj table Target object (expects fields like x,y,w,h,bc,fc and scroll methods)
---@return table return scrollbar
function Scrollbar.new(obj)
	expect(obj, 'obj', "table")

	local instance = Widget.new {
		x = obj.x + obj.w, y = obj.y,
		w = 1, h = obj.h,
	}
	instance.bg = obj.bg
	instance.fg = obj.fg
	instance.obj = obj
	instance.held = 0 -- 0: none, 1: up arrow, 2: slider, 3: down arrow
	instance.drag_offset = 0
	if obj.attachScrollbar then
		obj:attachScrollbar(instance, "vertical")
	end

	instance.draw = Scrollbar.draw
	instance.setObj = Scrollbar.setObj
	instance.getTrackHeight = Scrollbar.getTrackHeight
	instance.getSliderHeight = Scrollbar.getSliderHeight
	instance.getMaxSliderOffset = Scrollbar.getMaxSliderOffset
	instance.getSliderOffset = Scrollbar.getSliderOffset
	instance.checkIn = Scrollbar.checkIn
	instance.isOnSlider = Scrollbar.isOnSlider
	instance.onMouseDown = Scrollbar.onMouseDown
	instance.onMouseDrag = Scrollbar.onMouseDrag
	instance.onMouseUp = Scrollbar.onMouseUp
	instance.onMouseScroll = Scrollbar.onMouseScroll

	return instance
end

return Scrollbar

-- local expect = require 'cc.expect'.expect
local Widget = require 'Text.Widget'
local g = require 'geometry'
local Utils = require 'Utils'
local Scrollbar = {}

function Scrollbar.draw(self)
	term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	local slider_height = self:getSliderHeight()
	local slider_offset = self:getSliderOffset()
	g.draw_filled_rounded_rect(self.x, self.y + slider_offset, self.w, slider_height, 2, self.fc)
	-- local slider_height = self:getSliderHeight()
	-- local slider_offset = self:getSliderOffset()
	-- local slider_y_start = self.y + 1 + slider_offset

	-- term.setBackgroundColor(self.bc)
	-- for y = self.y + 1, slider_y_start - 1 do
	-- 	term.setCursorPos(self.x, y)
	-- 	term.write(" ")
	-- end
	-- for y = slider_y_start + slider_height, self.y + self.h - 2 do
	-- 	term.setCursorPos(self.x, y)
	-- 	term.write(" ")
	-- end

	-- local up_bg, up_fg = (self.held == 1 and self.fc or self.bc), (self.held == 1 and self.bc or self.fc)
	-- term.setBackgroundColor(up_bg)
	-- term.setTextColor(up_fg)
	-- term.setCursorPos(self.x, self.y)
	-- term.write("\30")

	-- local down_bg, down_fg = (self.held == 3 and self.fc or self.bc), (self.held == 3 and self.bc or self.fc)
	-- term.setBackgroundColor(down_bg)
	-- term.setTextColor(down_fg)
	-- term.setCursorPos(self.x, self.y + self.h - 1)
	-- term.write("\31")

	-- term.setBackgroundColor(self.fc)
	-- term.setTextColor(self.bc)
	-- for y = slider_y_start, math.min(slider_y_start + slider_height - 1, self.y + self.h - 2) do
	-- 	term.setCursorPos(self.x, y)
	-- 	term.write("\149")
	-- end
end

function Scrollbar.setObj(self, obj)
	self.obj = obj
	self.bc = self.obj.bg
	self.fc = self.obj.txtcol
	obj:attachScrollbar(instance, "vertical")
	self.dirty = true
end

function Scrollbar.getTrackHeight(self)
	return self.h
end

-- function Scrollbar.checkIn(self, x, y)
-- 	if y == self.y then
-- 		self.held = 1
-- 		return true
-- 	elseif y == self.y + self.h - 1 then
-- 		self.held = 3
-- 		return true
-- 	end
-- 	return false
-- end

function Scrollbar.isOnSlider(self, y)
	local slider_offset = self:getSliderOffset()
	local slider_height = self:getSliderHeight()
	local slider_y_start = self.y + slider_offset
	return y >= slider_y_start and y <= slider_y_start + slider_height
end

function Scrollbar.onMouseUp(self, btn, x, y)
	-- if self.held == 1 and self:check(x, y) and y == self.y then
	-- 	self.obj:scrollY(-1)
	-- elseif self.held == 3 and self:check(x, y) and y == self.y + self.h then
	-- 	self.obj:scrollY(1)
	-- end
	self.held = false
	self.dirty = true
	return true
end

function Scrollbar.onMouseScroll(self, dir, x, y)
	if self:check(x, y) then
		self.obj:scrollY(dir)
		return true
	end
	return false
end

function Scrollbar.getSliderHeight(self)
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

function Scrollbar.getMaxSliderOffset(self)
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return 0 end
	local slider_height = self:getSliderHeight()
	return math.max(0, track_height - slider_height)
end

function Scrollbar.getSliderOffset(self)
	local max_offset = self:getMaxSliderOffset()
	if max_offset == 0 then return 0 end

	local scrollmax = self.obj:getScrollMaxY()
	if scrollmax <= 0 then return 0 end

	local pos = self.obj:getScrollPosY()
	pos = Utils.clamp(pos, 0, scrollmax)
	local frac = pos / scrollmax

	return Utils.clamp(math.floor(frac * max_offset + 0.5), 0, max_offset)
end

function Scrollbar.onMouseDown(self, btn, x, y)
	if self:isOnSlider(y) then
		self.held = true
		self.drag_offset = y - self:getSliderOffset() - self.y
		return true
	end

	local track_top = self.y
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return true end

	local slider_height = self:getSliderHeight()
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxY()

	local click_rel = Utils.clamp(y - track_top, 0, track_height - 1)

	local half = slider_height / 2
	local desired_offset_f = click_rel - half
	local desired_offset = math.floor(desired_offset_f + 0.5)
	desired_offset = Utils.clamp(desired_offset, 0, max_offset)

	local frac = 0
	if max_offset > 0 then
		frac = desired_offset / max_offset
	end
	local pos = math.floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosY(pos)
	self.drag_offset = y - self:getSliderOffset() - self.y
	self.held = true
	self.dirty = true
	return true
end

function Scrollbar.onMouseDrag(self, btn, x, y)
	local track_top = self.y
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxY()

	local desired_offset = math.floor((y - track_top) - self.drag_offset + 0.5)
	desired_offset = Utils.clamp(desired_offset, 0, max_offset)

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
	-- expect(1, obj, "table")
	if type(obj) ~= 'table' then return error('Scrollbar sosal22', 1) end

	local instance = Widget.new({
		x = obj.x + obj.w,
		y = obj.y,
		w = 4,
		h = obj.h,
		bc = obj.bc,
		fc = obj.fc
	})
	instance.obj = obj
	instance.held = false -- 0: none, 1: up arrow, 2: slider, 3: down arrow
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

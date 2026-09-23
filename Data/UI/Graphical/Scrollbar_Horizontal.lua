local Widget = require 'Text.Widget'
local g = require 'geometry'
local Utils = require 'Utils'
local Scrollbar_Horizontal = {}

function Scrollbar_Horizontal.draw(self)
	term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	-- g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, 2, self.bc)
	local slider_width = self:getSliderWidth()
	local slider_offset = self:getSliderOffset()
	g.draw_filled_rounded_rect(self.x + slider_offset, self.y, slider_width, self.h, 2, self.fc)
	-- if self.buttons_enabled then
	-- 	-- if self.buttons_1.held then
	-- 	-- elseif self.buttons_2.held then
	-- 	-- end
	-- end
end

function Scrollbar_Horizontal.setObj(self, obj)
	self.obj = obj
	self.bc = self.obj.bg
	self.fc = self.obj.txtcol
	obj:attachScrollbar(instance, "horizontal")
	self.dirty = true
end

function Scrollbar_Horizontal.getTrackWidth(self)
	return self.w
end

function Scrollbar_Horizontal.isOnSlider(self, x)
	local slider_offset = self:getSliderOffset()
	local slider_width = self:getSliderWidth()
	local slider_x_start = self.x + slider_offset
	return x >= slider_x_start and x <= slider_x_start + slider_width
end

function Scrollbar_Horizontal.onMouseUp(self, btn, x, y)
	-- if self.held == 1 and self:check(x, y) and y == self.y then
	-- 	self.obj:scrollX(-1)
	-- elseif self.held == 3 and self:check(x, y) and y == self.y + self.h - 1 then
	-- 	self.obj:scrollX(1)
	-- end
	self.held = false
	self.dirty = true
	return true
end

function Scrollbar_Horizontal.onMouseScroll(self, dir, x, y)
	if self:check(x, y) then
		self.obj:scrollX(dir)
		return true
	end
	return false
end

function Scrollbar_Horizontal.getSliderWidth(self)
	local track_width = self:getTrackWidth()
	if track_width <= 0 then return 0 end

	local total_items = self.obj:getScrollMaxX() + self.obj.w
	local visible_items = self.obj.w or 0

	if total_items <= 0 then
		return track_width
	end

	if visible_items >= total_items then
		return track_width
	end

	local raw = (visible_items * track_width) / total_items
	local h = math.floor(raw + 0.5)
	if h < 1 then h = 1 end
	if h > track_width then h = track_width end
	return h
end

function Scrollbar_Horizontal.getMaxSliderOffset(self)
	local track_width = self:getTrackWidth()
	if track_width <= 0 then return 0 end
	local slider_width = self:getSliderWidth()
	return math.max(0, track_width - slider_width)
end

function Scrollbar_Horizontal.getSliderOffset(self)
	local max_offset = self:getMaxSliderOffset()
	if max_offset == 0 then return 0 end

	local scrollmax = self.obj:getScrollMaxX()
	if scrollmax <= 0 then return 0 end

	local pos = self.obj:getScrollPosX()
	pos = Utils.clamp(pos, 0, scrollmax)
	local frac = pos / scrollmax

	return Utils.clamp(math.floor(frac * max_offset + 0.5), 0, max_offset)
end

function Scrollbar_Horizontal.onMouseDown(self, btn, x, y)
	if self:isOnSlider(x) then
		self.held = true
		self.drag_offset = x - self:getSliderOffset() - self.x
		return true
	end

	local track_top = self.x
	local track_width = self:getTrackWidth()
	if track_width <= 0 then return true end

	local slider_width = self:getSliderWidth()
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxX()

	local click_rel = Utils.clamp(x - track_top, 0, track_width)

	local half = slider_width / 2
	local desired_offset_f = click_rel - half
	local desired_offset = math.floor(desired_offset_f + 0.5)
	desired_offset = Utils.clamp(desired_offset, 0, max_offset)

	local frac = 0
	if max_offset > 0 then
		frac = desired_offset / max_offset
	end
	local pos = math.floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosX(pos)
	self.drag_offset = x - self:getSliderOffset() - self.x
	self.held = true
	self.dirty = true
	return true
end

function Scrollbar_Horizontal.onMouseDrag(self, btn, x, y)
	local track_top = self.x
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxX()

	local desired_offset = math.floor((x - track_top) - self.drag_offset + 0.5)
	desired_offset = Utils.clamp(desired_offset, 0, max_offset)

	local frac = desired_offset / max_offset
	local pos = math.floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosX(pos)

	return true
end

function Scrollbar_Horizontal.new(obj)
	-- expect(1, obj, "table")
	if type(obj) ~= 'table' then return error('Scrollbar sosal22', 1) end

	local instance = Widget.new({
		x = obj.x,
		y = obj.y + obj.h,
		w = obj.w,
		h = 4,
		bc = obj.bc,
		fc = obj.fc
	})
	instance.obj = obj
	instance.held = false
	instance.drag_offset = 0
	instance.buttons_enabled = true
	instance.buttons_size = 10
	if obj.attachScrollbar then
		obj:attachScrollbar(instance, "horizontal")
	end

	instance.draw = Scrollbar_Horizontal.draw
	instance.setObj = Scrollbar_Horizontal.setObj
	instance.getTrackWidth = Scrollbar_Horizontal.getTrackWidth
	instance.getSliderWidth = Scrollbar_Horizontal.getSliderWidth
	instance.getMaxSliderOffset = Scrollbar_Horizontal.getMaxSliderOffset
	instance.getSliderOffset = Scrollbar_Horizontal.getSliderOffset
	-- instance.checkIn = Scrollbar_Horizontal.checkIn
	instance.isOnSlider = Scrollbar_Horizontal.isOnSlider
	instance.onMouseDown = Scrollbar_Horizontal.onMouseDown
	instance.onMouseDrag = Scrollbar_Horizontal.onMouseDrag
	instance.onMouseUp = Scrollbar_Horizontal.onMouseUp
	instance.onMouseScroll = Scrollbar_Horizontal.onMouseScroll

	return instance
end

return Scrollbar_Horizontal

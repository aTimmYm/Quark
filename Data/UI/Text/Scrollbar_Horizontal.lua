local Widget = require 'Text.Widget'
local clamp = require 'Utils'.clamp
local expect_args = require 'Utils'.expect_args
local to_hex = require 'Utils'.to_hex
local expect = require 'Utils'.expect

local Scrollbar_Horizontal = {}

function Scrollbar_Horizontal:getSliderWidth()
	local track_width = self:getTrackWidth()
	if track_width <= 0 then return 0 end

	local total_width = self.obj:getScrollMaxX() + self.obj.w
	local visible_width = self.obj.w or 0

	if total_width <= 0 or visible_width >= total_width then
		return track_width
	end

	local raw = (visible_width * track_width) / total_width
	local w = math.floor(raw + 0.5)
	if w < 1 then w = 1 end
	if w > track_width then w = track_width end
	return w
end

function Scrollbar_Horizontal:getSliderOffset()
	local max_offset = self:getMaxSliderOffset()
	if max_offset == 0 then return 0 end

	local scrollmax = self.obj:getScrollMaxX()
	if scrollmax <= 0 then return 0 end

	local pos = self.obj:getScrollPosX()
	pos = clamp(pos, 0, scrollmax)
	local frac = scrollmax > 0 and (pos / scrollmax) or 0
	return clamp(math.floor(frac * max_offset + 0.5), 0, max_offset)
end

function Scrollbar_Horizontal:getTrackWidth()
	return self.w - 2
end

function Scrollbar_Horizontal:getMaxSliderOffset()
	local track_width = self:getTrackWidth()
	if track_width <= 0 then return 0 end
	local slider_width = self:getSliderWidth()
	return math.max(0, track_width - slider_width)
end

function Scrollbar_Horizontal:onMouseDown(btn, x, y)
	if x == self.x then
		self.held = 1
		self.dirty = true
		return true
	elseif x == self.x + self.w - 1 then
		self.held = 3
		self.dirty = true
		return true
	end
	self.held = 2

	if self:isOnSlider(x) then
		local slider_offset = self:getSliderOffset()
		local slider_x_start = self.x + 1 + slider_offset
		self.drag_offset = x - slider_x_start
		self.dirty = true
		return true
	end

	local track_left = self.x + 1
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxX()

	if scrollmax <= 0 or max_offset == 0 then
		return true
	end

	local slider_width = self:getSliderWidth()
	local click_rel = clamp(x - track_left, 0, self:getTrackWidth() - 1)
	local half = (slider_width - 1) / 2
	local desired_offset = math.floor(click_rel - half + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = max_offset > 0 and (desired_offset / max_offset) or 0
	local pos = math.floor(frac * scrollmax + 0.5)
	self.obj:setScrollPosX(pos)

	self.dirty = true
	return true
end

function Scrollbar_Horizontal:onMouseUp(btn, x, y)
	if self.held == 1 and self:check(x, y) and x == self.x then
		self.obj:scrollX(-1)
	elseif self.held == 3 and self:check(x, y) and x == self.x + self.w - 1 then
		self.obj:scrollX(1)
	end
	self.held = 0
	self.dirty = true
	return true
end

function Scrollbar_Horizontal:onMouseDrag(btn, x, y)
	if self.held == 1 or self.held == 3 then return end
	local track_left = self.x + 1
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxX()

	local desired_offset = math.floor((x - track_left) - self.drag_offset + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = desired_offset / max_offset
	local pos = math.floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosX(pos)

	return true
end

function Scrollbar_Horizontal:onMouseScroll(dir, x, y)
	if self:check(x, y) then
		self.obj:scrollX(dir)
		return true
	end
	return false
end

function Scrollbar_Horizontal:isOnSlider(x)
	local slider_offset = self:getSliderOffset()
	local slider_width = self:getSliderWidth()
	local slider_x_start = self.x + 1 + slider_offset
	return x >= slider_x_start and x <= slider_x_start + slider_width - 1
end

function Scrollbar_Horizontal:draw()
	local slider_width = self:getSliderWidth()
	local slider_offset = self:getSliderOffset()

	local blit_str = {}
	local blit_fg = {}
	local blit_bg = {}

	local fg = to_hex[self.fg]
	local bg = to_hex[self.bg]

	-- left button
	do
		local n = #blit_str + 1
		blit_str[n] = '\17'
		blit_fg[n] = to_hex[(self.held == 1 and colors.lightGray or self.fg)]
		blit_bg[n] = bg
	end

	-- between left button and thumb
	if slider_offset > 0 then
		local n = #blit_str + 1
		blit_str[n] = (' '):rep(slider_offset)
		blit_fg[n] = fg:rep(slider_offset)
		blit_bg[n] = bg:rep(slider_offset)
	end

	-- thumb
	do
		local n = #blit_str + 1
		local slider_fg = to_hex[(self.held == 2 and colors.lightGray or self.fg)]
		blit_str[n] = ('\140'):rep(slider_width)
		blit_fg[n] = slider_fg:rep(slider_width)
		blit_bg[n] = bg:rep(slider_width)
	end

	-- between thumb and right button
	do
		local len = self.w - 2 - slider_width - slider_offset
		if len > 0 then
			local n = #blit_str + 1
			blit_str[n] = (' '):rep(len)
			blit_fg[n] = fg:rep(len)
			blit_bg[n] = bg:rep(len)
		end
	end

	-- right button
	do
		local n = #blit_str + 1
		blit_str[n] = '\16'
		blit_fg[n] = to_hex[(self.held == 3 and colors.lightGray or self.fg)]
		blit_bg[n] = bg
	end

	term.setCursorPos(self.x, self.y)
	term.blit(table.concat(blit_str), table.concat(blit_fg), table.concat(blit_bg))
end

-- function Scrollbar_Horizontal.draw(self)
-- 	local slider_width = self:getSliderWidth()
-- 	local slider_offset = self:getSliderOffset()
-- 	local slider_x_start = self.x + 1 + slider_offset

-- 	term.setBackgroundColor(self.bg)
-- 	for x = self.x + 1, slider_x_start - 1 do
-- 		term.setCursorPos(x, self.y)
-- 		term.write(" ")
-- 	end
-- 	for x = slider_x_start + slider_width, self.x + self.w - 2 do
-- 		term.setCursorPos(x, self.y)
-- 		term.write(" ")
-- 	end

-- 	local left_bg, left_fg = (self.held == 1 and self.fg or self.bg), (self.held == 1 and self.bg or self.fg)
-- 	term.setBackgroundColor(left_bg)
-- 	term.setCursorPos(self.x, self.y)
-- 	term.setTextColor(left_fg)
-- 	term.write("\17")

-- 	local right_bg, right_fg = (self.held == 3 and self.fg or self.bg), (self.held == 3 and self.bg or self.fg)
-- 	term.setBackgroundColor(right_bg)
-- 	term.setCursorPos(self.x + self.w - 1, self.y)
-- 	term.setTextColor(right_fg)
-- 	term.write("\16")

-- 	term.setBackgroundColor(self.bg)
-- 	term.setTextColor(self.fg)
-- 	for x = slider_x_start, math.min(slider_x_start + slider_width - 1, self.x + self.w - 2) do
-- 		term.setCursorPos(x, self.y)
-- 		term.write("\140")
-- 	end
-- end

---Creating new *object* of *class* "Scrollbar_Horizontal" which connected at another *object*
---@class ScrollbarHorizontal
---@param obj table Target object which the horizontal scrollbar will be attached to
---@return table return Scrollbar_Horizontal
function Scrollbar_Horizontal.new(obj)
	expect(obj, 'obj', 'table')
	local instance = Widget.new({
		x = obj.x,
		y = obj.y + obj.h,
		w = obj.w,
		h = 1,
	})
	instance.bg = expect_args(obj, 'bg', 'number')
	instance.fg = expect_args(obj, 'fg', 'number')

	instance.obj = obj
	instance.orientation = "horizontal"
	instance.held = 0
	instance.drag_offset = 0
	if obj.attachScrollbar then
		obj:attachScrollbar(instance, "horizontal")
	end

	instance.draw = Scrollbar_Horizontal.draw
	instance.getSliderWidth = Scrollbar_Horizontal.getSliderWidth
	instance.getSliderOffset = Scrollbar_Horizontal.getSliderOffset
	instance.getTrackWidth = Scrollbar_Horizontal.getTrackWidth
	instance.getMaxSliderOffset = Scrollbar_Horizontal.getMaxSliderOffset
	instance.onMouseDown = Scrollbar_Horizontal.onMouseDown
	instance.onMouseUp = Scrollbar_Horizontal.onMouseUp
	instance.onMouseDrag = Scrollbar_Horizontal.onMouseDrag
	instance.onMouseScroll = Scrollbar_Horizontal.onMouseScroll
	instance.isOnSlider = Scrollbar_Horizontal.isOnSlider

	return instance
end

return Scrollbar_Horizontal

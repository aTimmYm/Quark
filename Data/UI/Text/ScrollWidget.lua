-- --DEPRECATED

-- local Widget = require 'Text/Widget'
-- local clamp = require 'Utils'.clamp
-- -- local function clamp(val, minimum, maximum) return math.max(minimum, math.min(maximum, val)) end

-- local ScrollWidget = {}

-- function ScrollWidget.getScrollMaxY(self)
-- 	return self.scroll.max_y
-- end

-- function ScrollWidget.getScrollMaxX(self)
-- 	return self.scroll.max_x
-- end

-- function ScrollWidget.getScrollPosY(self)
-- 	return self.scroll.pos_y
-- end

-- function ScrollWidget.getScrollPosX(self)
-- 	return self.scroll.pos_x
-- end

-- function ScrollWidget.setScrollPosY(self, pos)
-- 	local old_pos = self.scroll.pos_y
-- 	self.scroll.pos_y = clamp(pos, 0, self:getScrollMaxY())

-- 	if old_pos ~= self.scroll.pos_y then
-- 		self:updateDirty()
-- 		return true
-- 	end
-- 	return false
-- end

-- function ScrollWidget.setScrollPosX(self, pos)
-- 	local old_pos = self.scroll.pos_x
-- 	self.scroll.pos_x = clamp(pos, 0, self:getScrollMaxX())

-- 	if old_pos ~= self.scroll.pos_x then
-- 		self:updateDirty()
-- 		return true
-- 	end
-- 	return false
-- end

-- function ScrollWidget.scrollX(self, direction)
-- 	local new_pos = self.scroll.pos_x + (direction * self.scroll.sensitivity_x)
-- 	return self:setScrollPosX(math.floor(new_pos + 0.5))
-- end

-- function ScrollWidget.scrollY(self, direction)
-- 	local new_pos = self.scroll.pos_y + (direction * self.scroll.sensitivity_y)
-- 	return self:setScrollPosY(math.floor(new_pos + 0.5))
-- end

-- function ScrollWidget.onMouseScroll(self, dir, x, y)
-- 	return self:scrollY(dir)
-- end

-- function ScrollWidget.updateDirty(self, dir, x, y)
-- 	if self.scrollbar_v then
-- 		self.scrollbar_v.dirty = true
-- 	end
-- 	if self.scrollbar_h then
-- 		self.scrollbar_h.dirty = true
-- 	end
-- 	self.dirty = true
-- end

-- function ScrollWidget.attachScrollbar(scrollbar, orientation)
-- 	if orientation == "horizontal" or orientation == "h" then
-- 		self.scrollbar_h = scrollbar
-- 	else
-- 		self.scrollbar_v = scrollbar
-- 	end
-- end

-- function ScrollWidget.new(args)
-- 	local instance = Widget.new(args)

-- 	instance.scroll = {
-- 		pos_x = 0,
-- 		pos_y = 0,
-- 		max_x = 0,
-- 		max_y = 0,
-- 		sens_x = args.sens_x or 3,
-- 		sens_y = args.sens_y or 3,
-- 	}

-- 	instance.getScrollMaxY = ScrollWidget.getScrollMaxY
-- 	instance.getScrollMaxX = ScrollWidget.getScrollMaxX
-- 	instance.getScrollPosY = ScrollWidget.getScrollPosY
-- 	instance.getScrollPosX = ScrollWidget.getScrollPosX
-- 	instance.scrollX = ScrollWidget.scrollX
-- 	instance.scrollY = ScrollWidget.scrollY
-- 	instance.setScrollPosX = ScrollWidget.setScrollPosX
-- 	instance.setScrollPosY = ScrollWidget.setScrollPosY
-- 	instance.onMouseScroll = ScrollWidget.onMouseScroll
-- 	instance.updateDirty = ScrollWidget.updateDirty
-- 	instance.attachScrollbar = ScrollWidget.attachScrollbar

-- 	return instance
-- end

-- return ScrollWidget
return {}
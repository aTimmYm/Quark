local ScrollableMixin = {}

local function clamp(val, a, b) return math.max(a, math.min(b, val)) end

function ScrollableMixin:initScroll(sens_x, sens_y)
	self.scroll = {
		pos_x = 0,
		pos_y = 0,
		max_x = 0,
		max_y = 0,
		sens_x = sens_x or 3,
		sens_y = sens_y or 3,
	}
	self.scrollbar_v = nil
	self.scrollbar_h = nil
end

function ScrollableMixin:getScrollMaxY()
	return self.scroll.max_y
end

function ScrollableMixin:getScrollPosY()
	return self.scroll.pos_y
end

function ScrollableMixin:setScrollPosY(pos)
	local old_pos = self.scroll.pos_y
	self.scroll.pos_y = clamp(pos, 0, self:getScrollMaxY())

	if old_pos ~= self.scroll.pos_y then
		if self.scrollbar_h then self.scrollbar_h.dirty = true end
		if self.scrollbar_v then self.scrollbar_v.dirty = true end
		self:onLayout()
		return true
	end
	return false
end

function ScrollableMixin:scrollY(direction)
	local new_pos = self.scroll.pos_y + (direction * self.scroll.sens_y)
	return self:setScrollPosY(math.floor(new_pos + 0.5))
end

function ScrollableMixin:getScrollMaxX()
	return self.scroll.max_x
end

function ScrollableMixin:getScrollPosX()
	return self.scroll.pos_x
end

function ScrollableMixin:setScrollPosX(pos)
	local old_pos = self.scroll.pos_x
	self.scroll.pos_x = clamp(pos, 0, self:getScrollMaxX())

	if old_pos ~= self.scroll.pos_x then
		if self.scrollbar_h then self.scrollbar_h.dirty = true end
		if self.scrollbar_v then self.scrollbar_v.dirty = true end
		self:onLayout()
		return true
	end
	return false
end

function ScrollableMixin:scrollX(direction)
	local new_pos = self.scroll.pos_x + (direction * self.scroll.sens_x)
	return self:setScrollPosX(math.floor(new_pos + 0.5))
end

function ScrollableMixin:getScrollMax()
	return self:getScrollMaxY()
end

function ScrollableMixin:getScrollPos()
	return self:getScrollPosY()
end

function ScrollableMixin:setScrollPos(pos)
	return self:setScrollPosY(pos)
end

function ScrollableMixin:attachScrollbar(scrollbar, orientation)
	if orientation == "horizontal" or orientation == "h" then
		self.scrollbar_h = scrollbar
	else
		self.scrollbar_v = scrollbar
	end
end

function ScrollableMixin.addMixin(object)
	for k, v in pairs(ScrollableMixin) do
		object[k] = v
	end
end

return ScrollableMixin

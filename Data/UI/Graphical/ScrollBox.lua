local g = require 'geometry'
local _Container = require 'Graphical.Container'
local ScrollMixin = require 'Mixins.ScrollMixin'
local Utils = require 'Utils'

local ScrollBox = {}

function ScrollBox.draw(self)
	if self.radius then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius)
	else
		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	end
end

function ScrollBox.redraw(self)
	if self.dirty then
		self:draw(); self.dirty = false
	end
	local old = Utils.graphSetClip(self.x, self.y, self.w, self.h)

	for i = 1, #self.visibleChild do
		local child = self.visibleChild[i]
		child:redraw()
	end

	Utils.graphUnsetClip(old)
end

function ScrollBox.layoutChild(self)
	local scroll = self.scroll
	self.visibleChild = {}
	local ins = 1
	for i = 1, #self.children do
		local child = self.children[i]
		child.x, child.y = (self.x + child.localX) - scroll.pos_x, (self.y + child.localY) - scroll.pos_y
		scroll.max_y = math.max(math.max(scroll.max_y, child.localY + child.h) - self.h, 0)
		scroll.max_x = math.max(math.max(scroll.max_x, child.localX + child.w) - self.w, 0)
		if child.y + child.h >= self.y and child.y <= self.y + self.h then
			self.visibleChild[ins] = child
			ins = ins + 1
		end
	end
end

function ScrollBox.onMouseScroll(self, dir, x, y)
	return self:scrollY(dir)
end

function ScrollBox.updateDirty(self)
	if self.scrollbar_v then
		self.scrollbar_v.dirty = true
	end
	if self.scrollbar_h then
		self.scrollbar_h.dirty = true
	end
	self.dirty = true
	self:onLayout()
end

---Creating new *object* of *class*
---@class ScrollBox
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field bc color|number Background color
---@field fc? color|number Foreground/text color (optional)
---@field sensitivity_x? number
---@field sensitivity_y? number
---@param args ScrollBox Initialization table with fields above
---@return table object ScrollBox
function ScrollBox.new(args)
	local instance = _Container.new(args)

	ScrollMixin.addMixin(instance)
	instance:initScroll(args.sens_x, args.sens_y)
	instance.visibleChild = {}

	instance.draw = ScrollBox.draw
	instance.redraw = ScrollBox.redraw
	instance.layoutChild = ScrollBox.layoutChild
	instance.onMouseScroll = ScrollBox.onMouseScroll
	instance.updateDirty = ScrollBox.updateDirty

	return instance
end

return ScrollBox

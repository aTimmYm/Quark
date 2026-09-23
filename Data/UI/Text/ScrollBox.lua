local Box = require 'Text.Box'
local Utils = require 'Utils'
local expect_args = Utils.expect_args
local ScrollMixin = require 'Mixins.ScrollMixin'

local ScrollBox = {}

function ScrollBox:redraw()
	local old = Utils.termSetClip(self.x, self.y, self.w, self.h)
	if self.dirty then
		self:draw(); self.dirty = false
	end
	for i = 1, #self.visibleChild do
		local child = self.visibleChild[i]
		child:redraw()
	end
	Utils.termUnsetClip(old)
end

function ScrollBox:layoutChild()
	local scroll = self.scroll
	self.visibleChild = {}
	local ins = 1
	for i = 1, #self.children do
		local child = self.children[i]
		child.x, child.y = (self.x + child.localX - 1) - scroll.pos_x, (self.y + child.localY - 1) - scroll.pos_y
		scroll.max_y = math.max(math.max(scroll.max_y, child.localY + child.h) - self.h, 0)
		scroll.max_x = math.max(math.max(scroll.max_x, child.localX + child.w) - self.w, 0)
		if child.y + child.h > self.y and child.y <= self.y + self.h - 1 then
			self.visibleChild[ins] = child
			ins = ins + 1
		end
	end
end

function ScrollBox:onMouseScroll(dir, x, y)
	return self:scrollY(dir)
end

---Creating new *object* of *class*
---@class ScrollBox
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field bg color|number Background color
---@field fg? color|number Foreground/text color (optional)
---@param args ScrollBox Initialization table with fields above
---@return table object ScrollBox
function ScrollBox.new(args)
	local instance = Box.new(args)

	instance.visibleChild = {}
	ScrollMixin.addMixin(instance)
	instance:initScroll(expect_args(args, 'sens_x', 'number', 'nil'), expect_args(args, 'sens_y', 'number', 'nil'))

	instance.redraw = ScrollBox.redraw
	instance.layoutChild = ScrollBox.layoutChild
	instance.onMouseScroll = ScrollBox.onMouseScroll

	return instance
end

return ScrollBox

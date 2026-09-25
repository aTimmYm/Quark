local Widget = require 'Text.Widget'
local expect = require 'Utils'.expect

local Container = {}

local EVENTS = {
	TOP = {
		["mouse_click"] = true,
		["mouse_scroll"] = true,
	},
	FOCUS = {
		["mouse_up"] = true,
		["mouse_drag"] = true,
		["char"] = true,
		["key"] = true,
		["key_up"] = true,
		["paste"] = true,
		["term_resize"] = true,
	}
}
Container.EVENTS = EVENTS

-- local function checkRects(x1, y1, w1, h1, x2, y2, w2, h2)
-- 	return x1 < x2 + w2 and
-- 		x1 + w1 > x2 and
-- 		y1 < y2 + h2 and
-- 		y1 + h1 > y2
-- end

function Container:layoutChild()
	for i = 1, #self.children do
		local child = self.children[i]
		child.x, child.y = self.x + child.localX - 1, self.y + child.localY - 1
	end
end

function Container:onLayout()
	self:layoutChild()
	-- self.dirty = true
	for i = 1, #self.children do
		self.children[i]:onLayout()
	end
end

function Container:addChild(child, pos)
	expect(child, 'child', 'table')
	expect(pos, 'pos', 'integer', 'nil')
	for i = 1, #self.children do
		if self.children[i] == child then
			return false
		end
	end
	local function addRoot(object, root)
		object.root = root

		if object.children then
			for i = 1, #object.children do
				addRoot(object.children[i], root)
			end
		end
	end

	addRoot(child, self.root or self)
	if not child.localX then child.localX = child.x end
	if not child.localY then child.localY = child.y end
	child.parent = self
	if pos then
		table.insert(self.children, pos, child)
	else
		self.children[#self.children + 1] = child
	end

	return child
end

function Container:removeChild(child)
	expect(child, 'child', 'table', 'boolean')
	if child == true then
		self.children = {}; return
	end
	for i = 1, #self.children do
		if self.children[i] == child then
			child.parent = nil
			-- child.localX, child.localY = nil, nil
			table.remove(self.children, i)
			return true
		end
	end
	return false
end

function Container:redraw()
	-- if self.dirty then
	-- 	self:draw()
	-- 	for i = 1, #self.children do
	-- 		local child = self.children[i]
	-- 		child:draw()
	-- 		child.dirty = false
	-- 	end
	-- 	self.dirty = false
	-- 	return
	-- end
	Widget.redraw(self)
	for i = 1, #self.children do
		-- local child = self.children[i]
		-- local nextChild = self.children[i + 1]
		-- if nextChild and child.dirty and checkRects(child.x, child.y, child.w, child.h, nextChild.x, nextChild.y, nextChild.w, nextChild.h) then
		-- 	nextChild.dirty = true
		-- end
		-- child:redraw()
		self.children[i]:redraw()
	end
end

function Container:onEvent(event, data)
	if self.custom_handlers[event] then
		return self.custom_handlers[event](table.unpack(data, 1))
	end

	-- local ret = Widget.onEvent(self, event, data)
	if EVENTS.TOP[event] then
		for i = #self.children, 1, -1 do
			local child = self.children[i]
			if child:check(data[2], data[3]) and child:onEvent(event, data) then
				return true
			end
		end
	elseif not EVENTS.FOCUS[event] then
		for i = 1, #self.children do
			if self.children[i]:onEvent(event, data) then
				return true
			end
		end
	end

	-- return ret
	return Widget.onEvent(self, event, data)
end

---Creating new *object* of *class*
---@class Container
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@param args Container Initialization table with fields above
---@return table object container
function Container.new(args)
	local instance = Widget.new(args)

	instance.children = {}
	instance.custom_handlers = {}

	instance.layoutChild = Container.layoutChild
	instance.onLayout = Container.onLayout
	instance.addChild = Container.addChild
	instance.removeChild = Container.removeChild
	instance.redraw = Container.redraw
	instance.onEvent = Container.onEvent

	return instance
end

return Container

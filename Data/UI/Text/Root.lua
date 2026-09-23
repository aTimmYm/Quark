local Container = require 'Text.Container'

local Root = {}

local EVENTS = Container.EVENTS

function Root:show()
	self:onLayout()
	self:redraw()
end

function Root:onResize(evt)
	if #evt > 1 then
		self.w, self.h = evt[1], evt[2]
	else
		self.w, self.h = term.getSize(self.gm)
	end

	for i = 1, #self.children do
		local child = self.children[i]
		if child.onResize then
			child:onResize(self.w, self.h)
		end
	end

	self:onLayout()
end

function Root:redraw()
	Container.redraw(self)
	if self.focus and self.focus.focusPostDraw then
		self.focus:focusPostDraw()
	end
end

function Root:onEvent(event, data)
	local focus = self.focus
	local ret = Container.onEvent(self, event, data)
	if self.focus and EVENTS.FOCUS[event] and self.focus:onEvent(event, data) then
		ret = true
	end
	if event == "term_resize" then
		self:onResize(data)
	end
	if self.focus ~= focus then
		if focus and focus.onFocus then
			focus:onFocus(false)
		end
		if self.focus and self.focus.onFocus then
			self.focus:onFocus(true)
		end
	end

	self:redraw()

	return ret
end

local function transferEvent(event, ...) return event, { ... } end

function Root:mainloop()
	self:show()
	while true do
		local event, data = transferEvent(coroutine.yield())
		if event == "terminate" then
			if self.onTerminate then self:onTerminate() end
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.setCursorPos(1, 1)
			term.clear()
			break
		end
		self:onEvent(event, data)
	end
end

-- local function onTerminate() end

---Creating new *object* of *class* root - event handler, to use root:mainloop()
---@class Root
---@return table object root
function Root.new(w, h)
	local gm = term.getGraphicsMode()
	-- local w, h = term.getSize(gm)
	local value = gm and 0 or 1
	local instance = Container.new { x = value, y = value, w = w, h = h }
	instance.gm = gm
	instance.focus = nil
	instance.clipboard = {}

	instance.onResize = Root.onResize
	instance.redraw = Root.redraw
	instance.onEvent = Root.onEvent
	instance.mainloop = Root.mainloop
	-- instance.onTerminate = onTerminate
	instance.show = Root.show

	return instance
end

return Root

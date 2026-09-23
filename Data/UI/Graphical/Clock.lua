local Widget = require 'Text.Widget'
local font = require 'Font'
local Clock = {}

function Clock.updateSize(self)
	-- local len = #os.date(self.format)
	-- self.w, self.h = len, 1
end

function Clock.draw(self)
	term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	-- font.drawText(os.date(self.format), self.x, self.y, self.fc, self.w, self.h, 'center')
	font.drawText(self.time, self.x, self.y, self.fc, self.w, self.h, 'center')
end

function Clock.updateTime(self)
	local now = os.epoch("utc") / 1000
	local delay
	if self.show_seconds then
		local frac = now - math.floor(now)
		delay = 1 - frac
	else
		local seconds_into_minute = now % 60
		delay = 60 - seconds_into_minute
	end
	self.time = os.date(self.format)
	self.timer = os.startTimer(delay)
end

function Clock.setFormat(self, Show_seconds, Is_24h)
	expect(1, Show_seconds, "boolean", "nil")
	expect(2, Is_24h, "boolean", "nil")

	self.show_seconds = Show_seconds ~= false
	self.is_24h = Is_24h ~= false
	updateFormat()
	self.time = os.date(self.format)
	self:updateSize()
	self.dirty = true
	if self.parent then
		self.parent:onLayout()
	end
end

function Clock.onEvent(self, event, data)
	if event == "timer" and data[1] == self.timer then
		self:updateTime()
		self.dirty = true
		return true
	end
	return false
end

---Creating new *object* of *class*
---@class Clock
---@field x number X pos in characters
---@field y number Y pos in characters
---@field show_seconds? boolean Show seconds in format
---@field is_24h? boolean Use 24-hour format if true
---@field updt_rate? number Update rate in seconds
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Clock Initialization table with fields above
---@return table object clock
function Clock.new(args)
	local instance = Widget.new(args)

	instance.show_seconds = args.show_seconds or false
	instance.is_24h = args.is_24h or true

	local function updateFormat()
		if instance.is_24h then
			instance.format = instance.show_seconds and "%H:%M:%S" or "%H:%M"
		else
			instance.format = instance.show_seconds and "%I:%M:%S %p" or "%I:%M %p"
		end
	end

	updateFormat()
	Clock.updateTime(instance)

	instance.updateSize = Clock.updateSize
	instance:updateSize()
	instance.draw = Clock.draw
	instance.updateTime = Clock.updateTime
	instance.setFormat = Clock.setFormat
	instance.onEvent = Clock.onEvent

	return instance
end

return Clock

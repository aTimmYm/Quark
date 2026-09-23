local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect

local Clock = {}

function Clock:updateSize()
	self.w, self.h = #os.date(self.format), 1
end

function Clock:draw()
	term.setBackgroundColor(self.bg)
	term.setTextColor(self.fg)
	term.setCursorPos(self.x, self.y)
	term.write(self.time)
end

local function updateFormat(self)
	if self.is_24h then
		self.format = self.show_seconds and "%H:%M:%S" or "%H:%M"
	else
		self.format = self.show_seconds and "%I:%M:%S %p" or "%I:%M %p"
	end
end

function Clock:updateTime()
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

function Clock:setFormat(Show_seconds, Is_24h)
	self.show_seconds = expect(Show_seconds, 'Show_seconds', 'boolean', 'nil') ~= false
	self.is_24h = expect(Is_24h, 'Is_24h', 'boolean', 'nil') ~= false

	updateFormat(self)
	self.time = os.date(self.format)
	self:updateSize()
	self.dirty = true
	if self.parent then
		self.parent:onLayout()
	end
end

function Clock:onEvent(event, data)
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
---@field fg color|number Foreground/text color
---@field bg color|number Background color
---@field show_seconds? boolean Show seconds in format
---@field is_24h? boolean Use 24-hour format if true
---@param args Clock Initialization table with fields above
---@return table object clock
function Clock.new(args)
	local instance = Widget.new(args)

	instance.fg = expect_args(args, 'fg', 'number')
	instance.bg = expect_args(args, 'bg', 'number')

	instance.show_seconds = expect_args(args, 'show_seconds', 'boolean', 'nil') or false
	instance.is_24h = expect_args(args, 'is_24h', 'boolean', 'nil') or true

	updateFormat(instance)
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

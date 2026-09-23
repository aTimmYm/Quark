local font = require 'Font'
local g = require 'geometry'
local Widget = require 'Text.Widget'
local Clock = require 'Text.Clock'
local Timer = {}

function Timer.getRemainingMs(self)
	if not self.running then
		return self.time * 1000 -- замороженное время
	end
	return self.expiration - os.epoch("utc")
end

function Timer.updateTime(self)
	if not self.running then return end

	local remainingMs = self:getRemainingMs()
	if remainingMs <= 0 then
		self:pause()
		self:pressed()
		return
	end

	self.time = math.floor((remainingMs / 1000) + 0.5)

	local remainingSec = remainingMs / 1000
	local frac = remainingSec % 1
	local delay = (frac == 0) and 1 or frac

	self.timer = os.startTimer(delay)
end

function Timer.pause(self)
	if not self.running then return false end

	os.cancelTimer(self.timer)
	self.timer = nil
	self.running = false

	local remainingMs = self:getRemainingMs()
	self.time = math.max(0, math.floor(remainingMs / 1000))

	return true
end

function Timer.unPause(self)
	if self.running then return false end

	self.running = true
	local now = os.epoch("utc")
	self.expiration = now + self.time * 1000

	return self:updateTime()
end

function Timer.setTime(self, sec)
	if type(sec) ~= "number" then return false end

	self.time = math.max(0, math.floor(sec))

	if self.running then
		local now = os.epoch("utc")
		self.expiration = now + self.time * 1000
		self:updateTime()
	end

	self.dirty = true
	return true
end

function Timer.addTime(self, sec)
	if not sec then return end
	return self:setTime(self.time + sec)
end

function Timer.draw(self)
	local offset = self.radius or 1
	if self.radius then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, self.bc)
	else
		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	end
	local time = self.time and os.date("!%X", self.time) or '--:--:--'
	font.drawText(time, self.x + offset, self.y, self.fc)
end

function Timer.new(args)
	local instance = Widget.new(args)

	instance.time = args.time
	instance.running = false
	instance.expiration = 0

	instance.draw = Timer.draw
	instance.updateTime = Timer.updateTime
	instance.onEvent = Clock.onEvent
	instance.pause = Timer.pause
	instance.setTime = Timer.setTime
	instance.addTime = Timer.addTime
	instance.unPause = Timer.unPause

	instance.getRemainingMs = Timer.getRemainingMs

	return instance
end

return Timer

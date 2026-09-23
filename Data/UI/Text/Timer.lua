local Widget = require 'Text.Widget'
local Clock = require 'Text.Clock'
local expect_args = require 'Utils'.expect_args

local Timer = {}

function Timer:getRemainingMs()
	if not self.running then
		return self.time * 1000 -- замороженное время
	end
	return self.expiration - os.epoch("utc")
end

function Timer:updateTime()
	if not self.running then return end

	-- local now = os.epoch("utc") / 1000
	-- local delay
	-- if self.show_seconds then
	-- local frac = now - _floor(now)
	-- delay = 1 - frac
	-- else
	-- 	local seconds_into_minute = now % 60
	-- 	delay = 60 - seconds_into_minute
	-- end
	-- self.timer = os.startTimer(delay)

	local remainingMs = self:getRemainingMs()
	if remainingMs <= 0 then
		self:pause()
		if self.pressed then self:pressed() end
		return
	end

	-- Обновляем отображаемое время (целые секунды)
	self.time = math.floor((remainingMs / 1000) + 0.5)
	-- self.time = (remainingMs / 1000)
	-- self.dirty = true

	-- Вычисляем точную задержку до следующей смены секунды на экране
	local remainingSec = remainingMs / 1000
	local frac = remainingSec % 1
	local delay = (frac == 0) and 1 or frac

	self.timer = os.startTimer(delay)
end

function Timer:pause()
	if not self.running then return false end

	os.cancelTimer(self.timer)
	self.timer = nil
	self.running = false

	-- Замораживаем ТОЧНОЕ оставшееся время (в секундах)
	local remainingMs = self:getRemainingMs()
	self.time = math.max(0, math.floor(remainingMs / 1000))

	return true
end

function Timer:unPause()
	if self.running then return false end

	self.running = true
	local now = os.epoch("utc")
	self.expiration = now + self.time * 1000

	return self:updateTime() -- сразу запустит таймер
end

function Timer:setTime(sec)
	if type(sec) ~= "number" then return false end

	self.time = math.max(0, math.floor(sec))

	if self.running then
		-- Если таймер уже запущен — перезапускаем с новым временем
		local now = os.epoch("utc")
		self.expiration = now + self.time * 1000
		self:updateTime()
	end
	-- Если на паузе — просто меняем замороженное значение

	self.dirty = true
	return true
end

function Timer:addTime(sec)
	return Timer_setTime(self, self.time + sec)
end

function Timer:draw()
	term.setCursorPos(self.x, self.y)
	term.setBackgroundColor(self.bg)
	term.setTextColor(self.fg)
	local time = self.time and os.date("!%X", self.time) or '--:--:--'
	term.write(time)
end

function Timer.new(args)
	local instance = Widget.new(args)

	instance.w = 8
	instance.h = 1

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.black

	instance.time = expect_args(args, 'time', 'number', 'nil') or false
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

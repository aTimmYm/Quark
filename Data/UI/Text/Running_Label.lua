local Widget = require 'Text.Widget'
local Label = require 'Text.Label'
local expect_args = require 'Utils'.expect_args

local Running_Label = {}

function Running_Label:draw(bg_override, txtcol_override)
	bg_override = bg_override or self.bg
	txtcol_override = txtcol_override or self.fg
	self:checkScrolling()
	if not self.scrolling then
		return Label.draw(self, bg_override, txtcol_override)
	end

	local segment = (self.text or "") .. (self.scroll_gap)
	local cycle_len = #segment
	if cycle_len == 0 then
		local visible_text = (' '):rep(self.w)
		term.setBackgroundColor(bg_override)
		term.setCursorPos(self.x, self.y)
		term.setTextColor(txtcol_override)
		term.write(visible_text)
		return
	end

	local pos = ((self.scroll_pos - 1) % cycle_len) + 1

	local visible_chars = {}
	for i = 0, self.w - 1 do
		local idx = ((pos - 1 + i) % cycle_len) + 1
		visible_chars[#visible_chars + 1] = segment:sub(idx, idx)
	end
	local visible_text = table.concat(visible_chars)

	local horiz_align = "center"
	if string.find(self.align, "left") then
		horiz_align = "left"
	elseif string.find(self.align, "right") then
		horiz_align = "right"
	end

	local x_pos = self.x
	if horiz_align == "left" then
		x_pos = self.x
	elseif horiz_align == "right" then
		x_pos = self.x + self.w - #visible_text
	else -- center
		x_pos = self.x + math.floor((self.w - #visible_text) / 2)
	end

	local left_pad = (' '):rep(x_pos - self.x)
	local right_pad = (' '):rep(self.w - (x_pos - self.x + #visible_text))
	local full_line = left_pad .. visible_text .. right_pad

	term.setBackgroundColor(bg_override)
	term.setCursorPos(self.x, self.y)
	term.setTextColor(txtcol_override)
	term.write(full_line)

	for i = self.y + 1, self.y + self.h - 1 do
		term.setBackgroundColor(bg_override)
		term.setCursorPos(self.x, i)
		term.setTextColor(txtcol_override)
		term.write((' '):rep(self.w))
	end
end

function Running_Label:setText(text)
	text = tostring(text)
	if self.text ~= text then self.scroll_pos = 1 end
	self.text = text
	self:checkScrolling()
	self.dirty = true
end

function Running_Label:checkScrolling()
	if #self.text > self.w then
		self.scrolling = true
		self:startTimer()
	else
		self.scrolling = false
		self:stopTimer()
		self.scroll_pos = 1
	end
end

function Running_Label:startTimer()
	if not self.timer_id then
		self.timer_id = os.startTimer(self.scroll_speed)
	end
end

function Running_Label:stopTimer()
	if self.timer_id then os.cancelTimer(self.timer_id) end
	self.timer_id = nil
end

function Running_Label:onEvent(event, data)
	if event == "timer" and data[1] == self.timer_id then
		if self.scrolling then
			self.scroll_pos = self.scroll_pos + 1
			local cycle_len = (#(self.text or "") + #(self.scroll_gap or ""))
			if cycle_len <= 0 then cycle_len = 1 end
			if self.scroll_pos > cycle_len then
				self.scroll_pos = 1
			end
			self.dirty = true
			self.timer_id = os.startTimer(self.scroll_speed)
		else
			self.timer_id = nil
		end
		return true
	end
	Widget.onEvent(self, event, data)
end

function Running_Label:onLayout()
	Widget.onLayout(self)
	self:checkScrolling()
end

---Creating new *object* of *class* "shortcut"
---@class Running_Label
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters (usually 1+)
---@field h number Height in characters (usually 1)
---@field text? string Text to scroll
---@field align? string Alignment (e.g. "center")
---@field scroll_speed? number Scroll step delay in seconds
---@field gap? string Gap string placed between cycles
---@field bg color|number Background color
---@field fg color|number Foreground/text color
---@param args Running_Label Initialization table with fields above
---@return table return Running_Label
function Running_Label.new(args)
	local instance = Label.new(args)

	instance.scroll_speed = math.max(0.05, (expect_args(args, 'scroll_speed', 'number', 'nil') or 0.5))
	instance.scroll_pos = 1
	instance.timer_id = nil
	instance.scrolling = false
	instance.scroll_gap = expect_args(args, 'gap', 'string', 'nil') or " "

	instance.draw = Running_Label.draw
	instance.setText = Running_Label.setText
	instance.checkScrolling = Running_Label.checkScrolling
	instance.startTimer = Running_Label.startTimer
	instance.stopTimer = Running_Label.stopTimer
	instance.onEvent = Running_Label.onEvent
	instance.onLayout = Running_Label.onLayout

	return instance
end

return Running_Label

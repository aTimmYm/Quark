local RadioButton_horizontal = require 'Graphical.RadioButton_horizontal'
local font = require 'Font'
-- local g = require 'geometry'
local RadioButton = {}

function RadioButton.draw(self)
	if self.bc then
		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
	end
	local text = self.text
	for i = 1, #text do
		local fc = self.fc_alt or colors.gray
		if self.item == i then
			fc = self.fc
		end
		font.drawText('•', self.x, self.y + ((i - 1) * 10), fc)
		font.drawText(text[i], self.x + 5, self.y + ((i - 1) * 10), self.fc)
	end
end

function RadioButton.onMouseDown(self, btn, x, y)
	if self.disabled then return true end
	local i = y - self.y + 1
	i = math.floor(i / 10) + 1
	self.item = i
	self.dirty = true
	self:pressed(self.text[self.item])
	return true
end

---Creating new *object* of *class*
---@class RadioButton
---@field x number X pos in characters
---@field y number Y pos in characters
---@field count? number Number of radio items
---@field text? string[] Array of labels for each item
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args RadioButton Initialization table with fields above
---@return table object radioButton
function RadioButton.new(args)
	local instance = RadioButton_horizontal.new(args)

	if args.text then
		instance.text = args.text
		instance.count = #instance.text
	else
		instance.text = {}
		for i = 1, instance.count do
			instance.text[i] = ""
		end
	end
	-- local t = getMaxListW(instance.text)
	-- instance.w = t == 0 and 1 or t + 2
	local max = 0
	for i = 1, #instance.text do
		max = math.max(max, font.calcWidth(instance.text[i]))
	end
	instance.w = max + 5
	instance.h = instance.count * 10 - 1

	instance.draw = RadioButton.draw
	instance.onMouseDown = RadioButton.onMouseDown

	return instance
end

return RadioButton

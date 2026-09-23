local getMaxListW = require 'Utils'.getMaxListW
local expect_args = require 'Utils'.expect_args

local RadioButton_horizontal = require 'Text/RadioButton_horizontal'

local RadioButton = {}

function RadioButton:draw()
	term.setBackgroundColor(self.bg)
	for i, v in ipairs(self.text) do
		term.setCursorPos(self.x, self.y + i - 1)
		term.setTextColor(colors.gray)
		if self.item == i then
			term.setTextColor(self.fg)
		end
		term.write("\7")
		term.setCursorPos(self.x + 1, self.y + i - 1)
		term.setTextColor(self.fg)
		term.write((" "):rep(math.min(#v, 1)) .. v)
	end
end

function RadioButton:onMouseUp(btn, x, y)
	if self.disabled then return true end
	if self:check(x, y) then
		self.item = y - self.y + 1
		self.dirty = true
		if self.pressed then self:pressed(self.text[self.item]) end
	end
	return true
end

---Creating new *object* of *class*
---@class RadioButton
---@field x number X pos in characters
---@field y number Y pos in characters
---@field count? number Number of radio items
---@field text? string[] Array of labels for each item
---@field bg? color|number Background color
---@field fg color|number Foreground/text color
---@param args RadioButton Initialization table with fields above
---@return table object radioButton
function RadioButton.new(args)
	local instance = RadioButton_horizontal.new(args)

	expect_args(args, 'text', 'table', 'nil')
	if args.text then
		-- for _, v in pairs(args.text) do
		-- 	if type(v) ~= 'string' then return error('RadioButton: args.text should be a index-based table of strings.') end
		-- end
		instance.text = args.text
		instance.count = #instance.text
	else
		instance.text = {}
		for i = 1, instance.count do
			instance.text[i] = ""
		end
	end
	local t = getMaxListW(instance.text)
	instance.w = t == 0 and 1 or t + 2
	instance.h = instance.count

	instance.draw = RadioButton.draw
	instance.onMouseUp = RadioButton.onMouseUp

	return instance
end

return RadioButton

local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect
local to_hex = require 'Utils'.to_hex
local drawFilledBox = require 'Utils'.drawFilledBox

local ColorSelector = {}
local function selector_widget_draw(self)
	-- drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bg)
	local chars = {}
	local blit_bg = {}
	local blit_fg = {}

	local hex_fg = to_hex[self.fg]
	local hex_bg = to_hex[self.bg]

	local items = self.connect.items
	for i = 1, self.w * self.h do
		local y = math.floor((i - 1) / self.w) + 1
		local x = i - ((y - 1) * self.w)
		local fg = items[i]
		if not chars[y] then
			chars[y] = {}
			blit_fg[y] = {}
			blit_bg[y] = {}
		end
		if fg then
			chars[y][x] = ' '
			blit_fg[y][x] = hex_fg
			blit_bg[y][x] = to_hex[fg]
		else
			chars[y][x] = '\127'
			blit_fg[y][x] = hex_fg
			blit_bg[y][x] = hex_bg
		end
	end

	for i = 1, #chars do
		term.setCursorPos(self.x, self.y + i - 1)
		term.blit(table.concat(chars[i]), table.concat(blit_fg[i]), table.concat(blit_bg[i]))
	end
end

local function selector_widget_onMouseDown(self, btn, x, y)
	local lX = x - self.x + 1
	local lY = y - self.y + 1

	local index = lX + (self.w * (lY - 1))
	local col = self.connect.items[index]
	if not col then return true end

	self.connect:setSelectedIndex(index)
	self.connect:close()
	if self.connect.pressed then self.connect:pressed(self.connect:getSelectedColor()) end
	return true
end

local function selector_widget_onFocus(self, focused)
	if self.connect and not focused then self.connect:close() end
end

function ColorSelector:draw()
	local color_index = self.selected_index
	local hex_bg = to_hex[self.bg]
	local hex_fg = to_hex[self.fg]
	if color_index and self.items[color_index] then
		local current_color = to_hex[self.items[color_index]]
		term.setCursorPos(self.x, self.y)
		if current_color ~= hex_bg then
			term.blit('\7', current_color, hex_bg)
		elseif current_color ~= '7' then
			term.blit('\7', current_color, '7')
		else
			term.blit('\7', current_color, '8')
		end
	else
		term.setCursorPos(self.x, self.y)
		term.blit('\127', hex_fg, hex_bg)
	end
end

function ColorSelector:close()
	if not self.connect then return false end
	if self.root.focus == self.connect then
		self.root.focus = nil
	end
	self.root:removeChild(self.connect)
	self.root:onLayout()
	self.connect = nil
	return true
end

function ColorSelector:openSelector()
	if self.connect then return false end
	self.connect = Widget.new {
		x = self.x, y = self.y,
		w = self.columns, h = self.rows,
	}
	self.connect.bg = self.bg
	self.connect.fg = self.fg

	self.connect.draw = selector_widget_draw
	self.connect.onFocus = selector_widget_onFocus
	self.connect.onMouseDown = selector_widget_onMouseDown

	self.root:addChild(self.connect)
	self.connect.connect = self
	self.root.focus = self.connect

	return true
end

function ColorSelector:onMouseDown(btn, x, y)
	if not self.connect then self:openSelector() end
	return true
end

function ColorSelector:setPossibleColors(table)
	self.items = expect(table, 'table', 'table')
end

function ColorSelector:setSelectedColor(col)
	expect(col, 'col', 'integer', 'nil')
	if not col then
		self.current_color = nil
		return
	end
	for i = 1, #self.items do
		if self.items[i] == col then
			self.selected_index = i
			return
		end
	end
	return error('setSelectedColor: Invalid color', 2)
end

function ColorSelector:setSelectedIndex(idx)
	if idx and not self.items[idx] then return error('setSelectedIndex: invalid idx', 2) end
	self.selected_index = idx
end

function ColorSelector:getSelectedIndex()
	return self.selected_index
end

function ColorSelector:getSelectedColor()
	if self.selected_index then return self.items[self.selected_index] end
end

function ColorSelector.new(args)
	local instance = Widget.new(args)

	instance.selected_index = expect_args(args, 'selected_index', 'integer', 'nil')

	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.black
	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white

	instance.items = expect_args(args, 'items', 'table', 'nil')
	instance.rows = expect_args(args, 'rows', 'integer', 'nil') or 4
	instance.columns = expect_args(args, 'columns', 'integer', 'nil') or 4
	instance.connect = nil

	instance.draw = ColorSelector.draw
	instance.onMouseDown = ColorSelector.onMouseDown
	instance.setPossibleColors = ColorSelector.setPossibleColors
	instance.setSelectedColor = ColorSelector.setSelectedColor
	instance.setSelectedIndex = ColorSelector.setSelectedIndex
	instance.getSelectedColor = ColorSelector.getSelectedColor
	instance.getSelectedIndex = ColorSelector.getSelectedIndex
	instance.openSelector = ColorSelector.openSelector
	instance.close = ColorSelector.close

	return instance
end

return ColorSelector

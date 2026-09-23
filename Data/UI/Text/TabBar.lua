local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect
local drawFilledBox = require 'Utils'.drawFilledBox
local ScrollMixin = require 'Mixins.ScrollMixin'

local TabBar = {}

local to_hex = {}
do
	local hex = '0123456789abcdef'
	for i = 1, 16 do
		to_hex[i - 1] = hex:sub(i, i)
	end
end

-- function TabBar.draw(self)
-- 	drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bg)

-- 	-- TODO: check for bugs
-- 	-- All tabs
-- 	local blit_text, blit_fg, blit_bg = {}, {}, {}
-- 	local tabs = self.tabs
-- 	for i = 1, #tabs do
-- 		local text = tabs[i]
-- 		local sub_x = self.max_w - 1
-- 		local str = text:sub(1, sub_x)
-- 		local rep_x = self.max_w - #str - 1
-- 		blit_text[i] = str .. (" "):rep(rep_x) .. "x"
-- 		blit_fg[i] = to_hex[self.fg]:rep(#str + rep_x) .. to_hex[self.x_color]
-- 		blit_bg[i] = to_hex[self.bg]:rep(#str + rep_x + 1)
-- 	end
-- 	term.setCursorPos(self.x, self.y)
-- 	term.blit(table.concat(blit_text), table.concat(blit_fg), table.concat(blit_bg))

-- 	-- Selected tab
-- 	term.setCursorPos(self.max_w * (self.selected - 1) + 1, self.y)
-- 	local text = tabs[self.selected]
-- 	if not text then return end
-- 	local sub_x = self.max_w - 1
-- 	local str = text:sub(1, sub_x)
-- 	local rep_x = self.max_w - #str - 1
-- 	blit_text = str .. (" "):rep(rep_x) .. "x"
-- 	blit_fg = to_hex[self.fg_selected]:rep(#str + rep_x) .. to_hex[self.x_color]
-- 	blit_bg = to_hex[self.bg_selected]:rep(#str + rep_x + 1)
-- 	term.blit(blit_text, blit_fg, blit_bg)
-- end

function TabBar:draw()
	drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bg)
	local scroll_pos_x = self:getScrollPosX()
	-- TODO: check for bugs
	-- All tabs
	local blit_text, blit_fg, blit_bg = {}, {}, {}
	local tabs = self.tabs
	for i = 1, #tabs do
		local text = tabs[i]
		local sub_x = self.max_w - 1
		local str = text:sub(1, sub_x)
		local rep_x = self.max_w - #str - 1
		blit_text[i] = str .. (" "):rep(rep_x) .. "x"
		if i == self.selected then
			blit_fg[i] = to_hex[self.fg_selected]:rep(#str + rep_x) .. to_hex[self.x_color]
			blit_bg[i] = to_hex[self.bg_selected]:rep(#str + rep_x + 1)
		else
			blit_fg[i] = to_hex[self.fg]:rep(#str + rep_x) .. to_hex[self.x_color]
			blit_bg[i] = to_hex[self.bg]:rep(#str + rep_x + 1)
		end
	end
	term.setCursorPos(self.x, self.y)
	local start_sub, end_sub = scroll_pos_x + 1, self.w + scroll_pos_x

	term.blit(
		table.concat(blit_text):sub(start_sub, end_sub),
		table.concat(blit_fg):sub(start_sub, end_sub),
		table.concat(blit_bg):sub(start_sub, end_sub)
	)
	-- Selected tab
	-- term.setCursorPos(self.max_w * (self.selected - 1) + 1, self.y)
	-- local text = tabs[self.selected]
	-- if not text then return end
	-- local sub_x = self.max_w - 1
	-- local str = text:sub(1, sub_x)
	-- local rep_x = self.max_w - #str - 1
	-- blit_text = str .. (" "):rep(rep_x) .. "x"
	-- blit_fg = to_hex[self.fg_selected]:rep(#str + rep_x) .. to_hex[self.x_color]
	-- blit_bg = to_hex[self.bg_selected]:rep(#str + rep_x + 1)
	-- term.blit(blit_text, blit_fg, blit_bg)
end

function TabBar:onMouseUp(btn, x, y)
	local click = self.click
	if not self:check(x, y) or not click.index then return end
	if click.close or btn == 3 then
		self:removeTab(click.index)

		if click.index < self.selected then
			self.selected = self.selected - 1
		elseif click.index == self.selected then
			self.selected = math.min(self.selected, #self.tabs)
			if self.pressed then self:pressed(self.selected) end
		end
	elseif self.selected ~= click.index then
		self.selected = click.index
		if self.pressed then self:pressed(self.selected) end
	end

	self.dirty = true
	self.click = nil

	return true
end

function TabBar:onMouseDown(btn, x, y)
	local l_x = x - self.x + 1 + self.scroll.pos_x
	local new_index = math.ceil(l_x / self.max_w)
	if new_index > #self.tabs then return end
	self.click = { index = new_index, close = l_x % self.max_w == 0 }

	return true
end

function TabBar:onMouseDrag(btn, x, y)
	if btn ~= 1 then return end
	local local_x = x - self.x + 1 + self.scroll.pos_x
	local new_index = math.ceil(local_x / self.max_w)
	local click = self.click

	if not click.index or click.index == new_index or new_index < 1 or new_index > #self.tabs then return end

	self.tabs[click.index], self.tabs[new_index] = self.tabs[new_index], self.tabs[click.index]
	self.pages[click.index], self.pages[new_index] = self.pages[new_index], self.pages[click.index]

	if self.selected == click.index then
		self.selected = new_index
	elseif self.selected == new_index then
		self.selected = click.index
	end

	click.index = new_index
	click.close = false
	self.dirty = true

	return true
end

function TabBar:onMouseScroll(dir, x, y)
	return self:scrollX(dir)
end

function TabBar:getScrollMaxX()
	self.scroll.max_x = math.max(0, #self.tabs * self.max_w - self.w)
	return self.scroll.max_x
end

-- function TabBar:updateDirty()
-- 	self.dirty = true
-- end

function TabBar:addTab(name, pos)
	expect(pos, 'pos', 'integer', 'nil')
	expect(name, 'name', 'string')
	if pos then
		table.insert(self.tabs, pos, name)
	else
		self.tabs[#self.tabs + 1] = name
	end
	self:getScrollMaxX()
	self.dirty = true
end

function TabBar:removeTab(pos)
	expect(pos, 'pos', 'integer', 'nil')
	local name = self.tabs[pos]
	table.remove(self.tabs, pos)
	self:getScrollMaxX()
	self.dirty = true
	if self.onCloseTab then self:onCloseTab(name, pos) end
end

---@class TabBar
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field fg? color|number Main text color
---@field bg? color|number Main bg color
---@param args TabBar Initialization table with fields above
---@return table object TabBar
function TabBar.new(args)
	local instance = Widget.new(args)

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.black
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.white

	instance.fg_selected = expect_args(args, 'fg_selected', 'number', 'nil') or colors.white
	instance.bg_selected = expect_args(args, 'bg_selected', 'number', 'nil') or colors.black

	instance.x_color = expect_args(args, 'x_color', 'number', 'nil') or colors.lightGray

	ScrollMixin.addMixin(instance)
	instance:initScroll(expect_args(args, 'sens_x', 'number', 'nil') or 4)

	instance.selected = 0
	instance.tabs = {}
	instance.max_w = 10

	instance.draw = TabBar.draw
	instance.addTab = TabBar.addTab
	instance.removeTab = TabBar.removeTab
	instance.getScrollMaxX = TabBar.getScrollMaxX
	instance.onMouseUp = TabBar.onMouseUp
	instance.onMouseDown = TabBar.onMouseDown
	instance.onMouseDrag = TabBar.onMouseDrag
	instance.onMouseScroll = TabBar.onMouseScroll
	-- instance.updateDirty = TabBar.updateDirty

	return instance
end

return TabBar

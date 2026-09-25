local UI = require 'Data.UI'
local drawFilledBox = UI.Utils.drawFilledBox
local expect = UI.Utils.expect
local to_hex = UI.Utils.to_hex

local _tabbar = {}

function _tabbar:draw()
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

		local fg, bg
		if i == self.selected then
			if self.tabs_color[i] == self.bg_selected then
				fg = self.fg_selected
			else
				fg = self.tabs_color[i]
			end
			bg = self.bg_selected
		else
			fg = self.tabs_color[i]
			bg = self.bg
		end

		blit_fg[i] = to_hex[fg]:rep(#str + rep_x) .. to_hex[self.x_color]
		blit_bg[i] = to_hex[bg]:rep(#str + rep_x + 1)
	end
	term.setCursorPos(self.x, self.y)
	local start_sub, end_sub = scroll_pos_x + 1, self.w + scroll_pos_x

	return term.blit(
		table.concat(blit_text):sub(start_sub, end_sub),
		table.concat(blit_fg):sub(start_sub, end_sub),
		table.concat(blit_bg):sub(start_sub, end_sub)
	)
end

function _tabbar:setTabFg(pos, color)
	local tab = self.tabs[pos]
	if not tab then return end
	self.tabs_color[pos] = color or self.fg
	self.dirty = true
end

function _tabbar:removeTab(pos)
	expect(pos, 'pos', 'integer', 'nil')
	local name = self.tabs[pos]
	table.remove(self.tabs, pos)
	table.remove(self.tabs_color, pos)
	self:getScrollMaxX()
	self.dirty = true
	if self.onCloseTab then self:onCloseTab(name, pos) end
end

function _tabbar:addTab(name, pos, color)
	expect(pos, 'pos', 'integer', 'nil')
	expect(name, 'name', 'string')
	expect(color, 'color', 'number', 'nil')
	color = color or self.fg
	if pos then
		table.insert(self.tabs, pos, name)
		table.insert(self.tabs_color, pos, color)
	else
		self.tabs[#self.tabs + 1] = name
		self.tabs_color[#self.tabs_color + 1] = color
	end
	self:getScrollMaxX()
	self.dirty = true
end

function _tabbar:onMouseDrag(btn, x, y)
	if btn ~= 1 then return end
	local local_x = x - self.x + 1 + self.scroll.pos_x
	local new_index = math.ceil(local_x / self.max_w)
	local click = self.click

	if not click or click.index == new_index or new_index < 1 or new_index > #self.tabs then return end

	self.tabs[click.index], self.tabs[new_index] = self.tabs[new_index], self.tabs[click.index]
	if self.onChangeTabs then self:onChangeTabs(click.index, new_index) end

	self.tabs_color[click.index], self.tabs_color[new_index] = self.tabs_color[new_index], self.tabs_color[click.index]

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

function _tabbar.new(args)
	local instance = UI.TabBar(args)

	instance.tabs_color = {}

	instance.draw = _tabbar.draw
	instance.setTabFg = _tabbar.setTabFg
	instance.addTab = _tabbar.addTab
	instance.onMouseDrag = _tabbar.onMouseDrag
	instance.removeTab = _tabbar.removeTab

	return instance
end

return _tabbar

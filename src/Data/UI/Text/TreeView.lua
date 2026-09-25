local Widget = require 'Text.Widget'
local ScrollMixin = require 'Mixins.ScrollMixin'
local drawFilledBox = require 'Utils'.drawFilledBox
local expect_args = require 'Utils'.expect_args
local expect = require 'Utils'.expect
local to_hex = require 'Utils'.to_hex

local TreeView = {}

function TreeView:onMouseScroll(dir, x, y)
	return self:scrollY(dir)
end

-- function TreeView:updateDirty()
-- 	if self.scrollbar_v then
-- 		self.scrollbar_v.dirty = true
-- 	end
-- 	if self.scrollbar_h then
-- 		self.scrollbar_h.dirty = true
-- 	end
-- 	self.dirty = true
-- end

function TreeView:tree_getHeight(arr, y, level)
	for i, target in ipairs(arr) do
		y = y + 1
		if target.is_open then
			y = self:tree_getHeight(target.items, y, level + 1)
		end
	end
	return y
end

function TreeView:tree_draw(arr, y, level)
	for i = 1, #arr do
		local target = arr[i]
		local nX, nY = self.x - self.scroll.pos_x, y - self.scroll.pos_y
		if nY >= self.y and nY < (self.y + self.h) then
			self.click_map[nY] = target
			local text = ''
			if target.is_case then
				text = target.is_open and "\31" or "\16"
			end

			text = (' '):rep(level) .. text .. target.name
			text = (text .. (' '):rep(self.w - #text)):sub(1, self.w)

			local bg = self.bg
			local fg = self.fg
			if self.hovered == target then
				fg = self.fg_hovered
				bg = self.bg_hovered
			elseif self.selected_target == target then
				fg = self.fg_selected
				bg = self.bg_selected
			end

			local nLine = #text
			bg = to_hex[bg]:rep(nLine)
			fg = to_hex[fg]:rep(nLine)

			term.setCursorPos(nX, nY)
			term.blit(text, fg, bg)
		end
		y = y + 1
		if target.is_open then
			y = self:tree_draw(target.items, y, level + 1)
		end
	end
	return y
end

-- function TreeView:onFocus(focused)
-- 	if not focused then
-- 		self.selected_target = nil; self.dirty = true
-- 	end
-- end

function TreeView:onMouseDown(btn, x, y)
	local item = self.click_map[y]
	if item then
		if item.is_case and btn == 1 then
			item.is_open = not item.is_open
		end
		self.selected_target = item
		if self.pressed then self:pressed(btn, item) end
	else
		self.selected_target = nil
	end
	self.click_map = {}
	self.dirty = true
	return true
end

function TreeView:onMouseMove(btn, x, y)
	local item = self.click_map[y]

	if item then
		self.hovered = item
	else
		self.hovered = nil
	end

	self.dirty = true
	return true
end

function TreeView:getScrollMaxY()
	return math.max(0, self:tree_getHeight(self.tree, self.y, 0) - self.h - self.y)
end

function TreeView:draw()
	drawFilledBox(self.x, TreeView.tree_draw(self, self.tree, self.y, 0), self.x + self.w - 1, self.y + self.h - 1,
		self.bg)
end

-- function TreeView:draw()
-- 	TreeView.tree_draw(self, self.tree, self.y, 0)
-- 	drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bg)
-- end

local function find_item(case, name)
	if not case then return end
	for i = 1, #case.items do
		local object = case.items[i]
		if object.name == name and not object.is_case then return object end
	end
end

local function find_case(search, tbl)
	local name, reminder = search:match('^([^/]+)/?(.*)$')
	if not name then return end
	for i = 1, #tbl do
		local object = tbl[i]
		if object.is_case then
			if name == object.name and object.is_case then
				if reminder == '' then
					return object
				else
					return find_case(reminder, object.items)
				end
			end
		end
	end
end

function TreeView:addItem(place, name, is_case)
	local target_tbl = self.tree

	if place ~= '' and place ~= '/' then
		local case = find_case(place, self.tree)
		if not case then return end
		target_tbl = case.items
	end

	for i = 1, #target_tbl do
		local target = target_tbl[i]
		if target.name == name and target.is_case == is_case then
			return
		end
	end

	if is_case then
		target_tbl[#target_tbl + 1] = {
			name = name,
			is_case = true,
			is_open = false,
			items = {},
			place = place
		}
	else
		target_tbl[#target_tbl + 1] = {
			name = name,
			is_case = false,
			place = place .. '/'
		}
	end
end

---@class TreeView
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field bg? color|number Main background color
---@field fg? color|number Main text color
---@field bg_click? color|number Click background color
---@field fg_click? color|number Click text color
---@field fg_selected? color|number Selected text color
---@field bg_selected? color|number Selected background color
---@field fg_hovered? color|number Hover text color
---@field bg_hovered? color|number Hover background color
---@param args TreeView Initialization table with fields above
---@return table object TreeView
function TreeView.new(args)
	local instance = Widget.new(args)

	ScrollMixin.addMixin(instance)
	instance:initScroll(args.sens_x, args.sens_y)

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.black
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.white

	instance.fg_click = expect_args(args, 'fg_click', 'number', 'nil') or colors.black
	instance.bg_click = expect_args(args, 'bg_click', 'number', 'nil') or colors.white

	instance.fg_selected = expect_args(args, 'fg_selected', 'number', 'nil') or instance.fg
	instance.bg_selected = expect_args(args, 'bg_selected', 'number', 'nil') or colors.lightBlue

	instance.fg_hovered = expect_args(args, 'fg_hovered', 'number', 'nil') or colors.lightGray
	instance.bg_hovered = expect_args(args, 'bg_hovered', 'number', 'nil') or instance.bg

	instance.tree = {}
	instance.click_map = {}
	instance.hovered = nil
	instance.selected_target = nil

	instance.draw = TreeView.draw
	instance.tree_draw = TreeView.tree_draw
	instance.tree_getHeight = TreeView.tree_getHeight
	instance.onMouseDown = TreeView.onMouseDown
	instance.onMouseMove = TreeView.onMouseMove
	instance.onMouseScroll = TreeView.onMouseScroll
	instance.getScrollMaxY = TreeView.getScrollMaxY
	-- instance.updateDirty = TreeView.updateDirty
	instance.addItem = TreeView.addItem
	-- instance.onFocus = TreeView.onFocus

	return instance
end

return TreeView

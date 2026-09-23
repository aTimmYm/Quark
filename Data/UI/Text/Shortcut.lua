--TODO: blittle
local Widget = require 'Text.Widget'
local Button = require 'Text.Button'
local drawFilledBox = require 'Utils'.drawFilledBox

local Shortcut = {}

function Shortcut:draw()
	drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bg)

	local text_h = self.text and 1 or 0

	local dX = math.floor((self.w - self.blittle_img.width) / 2) + self.x
	local dY = math.floor((self.h - text_h - self.blittle_img.height) / 2) + self.y
	-- Utils.blittle.draw(self.blittle_img, dX, dY)
	local txtcol_override = self.held and colors.lightGray or self.fg

	term.setBackgroundColor(self.bg)
	term.setTextColor(txtcol_override)
	local cY = dY + self.blittle_img.height
	term.setCursorPos(self.x, cY)

	if self.text then
		if #self.text >= self.w then
			-- term.write(self.text:sub(1, self.w - 2) .. "..")
			local w = self.w
			local part1 = self.text:sub(1, w)
			local part2 = self.text:sub(w + 1, -1)
			if #part2 > w then
				part2 = part2:sub(1, w - 2) .. '..'
			end
			term.write(part1)
			local offset = math.floor((w - #part2) / 2)
			term.setCursorPos(self.x + offset, cY + 1)
			term.write(part2)
		else
			term.write((" "):rep(math.floor((self.w - #self.text) / 2)) .. self.text ..
				(" "):rep(self.w - (math.floor((self.w - #self.text) / 2) + self.x + #self.text)))
		end
	end
end

---Creating new *object* of *class*
---@class Shortcut
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field text? string Optional label text
---@field filePath string Path to executable file
---@field icoPath string Path to icon file
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Shortcut Initialization table with fields above
---@return table object shortcut
function Shortcut.new(args)
	local instance = Button.new(args)

	instance.icoPath = (args.icoPath and fs.exists(args.icoPath)) and args.icoPath or "usr/icon_default.ico"
	instance.needArgs = {}
	instance.filePath = args.filePath
	if term.getGraphicsMode and term.getGraphicsMode() then
	else
		-- instance.blittle_img = Utils.blittle.load(instance.icoPath)
	end

	instance.draw = Shortcut.draw
	-- instance.pressed = Widget.pressed

	return instance
end

return Shortcut

local UI = require 'Data.UI'

local function logo_draw(self)
	for i = 1, #self.image do
		local blit_lines = self.image[i]
		term.setCursorPos(self.x, self.y + i - 1)
		term.blit(blit_lines[1], blit_lines[2], blit_lines[3])
	end
	term.setBackgroundColor(self.bg)
	term.setTextColor(self.fg)
	term.setCursorPos(self.x + 5, self.y + 1)
	term.write('Quark')
	term.setTextColor(colors.lightGray)
	term.setCursorPos(self.x + 5, self.y + 2)
	-- term.write('I D E')
	term.write('IDE')
end

local function _new(args)
	local box = UI.Box(args)

	local logo = box:addChild(UI.Widget{
		x = math.floor((box.w - 10)/2)+1, y = 2,
		w = 10, h = 3
	})
	logo.bg, logo.fg = box.bg, box.fg
	logo.draw = logo_draw
	logo.image = {
		{
			'\135\159\143\130\144',
			'70070',
			'07707'
		},
		{
			'  \131\154\149',
			'70700',
			'07077'
		},
		{
			'\139\130\137\144\148',
			'07770',
			'70007'
		},
	}

	local btn_close = box:addChild(UI.Button{
		text = 'x',
		x = box.w, y = 1,
		w = 1, h = 1,
		bg = box.bg, fg = colors.white
	})
	function btn_close:pressed()
		if box.onClose then return box:onClose() end
	end

	local version_label = box:addChild(UI.Label{
		text = 'Version 0.1',
		x = math.floor((box.w - 11)/2)+1, y = logo.y+logo.h + 1,
		w = 11, h = 1,
		bg = box.bg, fg = colors.white
	})

	local btn_update = box:addChild(UI.Button{
		text = 'Check updates',
		x = math.floor((box.w - 15)/2)+1, y = version_label.y + 1,
		w = 15, h = 1,
		bg = colors.lightGray, fg = colors.white
	})
	function btn_update:pressed()
		if box.onUpdate then return box:onUpdate(btn_update) end
	end

	return box
end

return _new

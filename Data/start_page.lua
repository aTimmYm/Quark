local UI = require 'Data.UI'

local function init(w, h)
	local start_page = UI.Box {
		x = 1, y = 1,
		w = w, h = h,
		bg = colors.black, fg = colors.white,
	}

	local logo = start_page:addChild(UI.Box {
		x = math.floor((w - 10) / 2) + 1, y = math.floor((h - 7) / 2) + 1,
		w = 10, h = 3,
		bg = start_page.bg, fg = colors.white
	})
	logo.image = {
		{
			'\135\159\143\130\144',
			'f00f0',
			'0ff0f'
		},
		{
			'  \131\154\149',
			'f0f00',
			'0f0ff'
		},
		{
			'\139\130\137\144\148',
			'0fff0',
			'f000f'
		},
	}
	function logo:draw()
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

	local new_file_btn = start_page:addChild(UI.Button {
		text = '+ New File', align = 'left',
		x = math.floor((w - 15) / 2) + 1, y = logo.y + logo.h + 1,
		w = 15, h = 1,
		bg = colors.black, fg = colors.white
	})
	function new_file_btn:pressed()
		if start_page.pressed then
			start_page:pressed('New File')
		end
	end

	local new_project_btn = start_page:addChild(UI.Button {
		text = '+ Open Project', align = 'left',
		x = math.floor((w - 15) / 2) + 1, y = new_file_btn.y + new_file_btn.h + 1,
		w = 15, h = 1,
		bg = colors.black, fg = colors.white
	})
	function new_project_btn:pressed()
		if start_page.pressed then
			start_page:pressed('Open Project')
		end
	end

	function start_page:onResize(width, height)
		self.w = width
		self.h = height
		logo.localX, logo.localY = math.floor((self.w - 10) / 2) + 1, math.floor((self.h - 7) / 2) + 1
		new_file_btn.localX, new_file_btn.localY = math.floor((self.w - 15) / 2) + 1, logo.localY + logo.h + 1
		new_project_btn.localX, new_project_btn.localY = math.floor((self.w - 15) / 2) + 1,
			new_file_btn.localY + new_file_btn.h + 1
	end

	return start_page
end


return init

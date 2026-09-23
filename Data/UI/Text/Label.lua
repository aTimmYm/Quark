local Widget = require 'Text.Widget'
local expect_args = require 'Utils'.expect_args

local Label = {}

local function split_paragraphs(text)
	local paragraphs = {}
	local start = 1
	while true do
		local pos = text:find("\n", start, true)
		if not pos then
			paragraphs[#paragraphs + 1] = text:sub(start)
			break
		end
		paragraphs[#paragraphs + 1] = text:sub(start, pos - 1)
		start = pos + 1
	end
	return paragraphs
end

local function split_words(str)
	local words = {}
	for w in str:gmatch("%S+") do
		words[#words + 1] = w
	end
	return words
end

local function push_wrapped_word(out_lines, word, max_w)
	local current = ""
	for ch in utf8_chars(word) do
		local candidate = current .. ch
		if current == "" or #candidate <= max_w then
			current = candidate
		else
			if current ~= "" then
				out_lines[#out_lines + 1] = current
			end
			current = ch
		end
	end
	if current ~= "" then
		out_lines[#out_lines + 1] = current
	end
end

local function wrap_text_to_width(text, max_w)
	local lines = {}

	for _, para in ipairs(split_paragraphs(text or "")) do
		if para == "" then
			lines[#lines + 1] = ""
		else
			local words = split_words(para)

			if #words == 0 then
				lines[#lines + 1] = ""
			else
				local current = ""

				for _, word in ipairs(words) do
					local word_w = #word

					if word_w > max_w then
						if current ~= "" then
							lines[#lines + 1] = current
							current = ""
						end
						push_wrapped_word(lines, word, max_w)
					else
						local candidate = (current == "") and word or (current .. " " .. word)
						if #candidate <= max_w then
							current = candidate
						else
							if current ~= "" then
								lines[#lines + 1] = current
							end
							current = word
						end
					end
				end

				if current ~= "" then
					lines[#lines + 1] = current
				end
			end
		end
	end

	if #lines == 0 then
		lines[1] = ""
	end

	return lines
end

-- UI.wrap_text_to_width = wrap_text_to_width

function Label:draw(bg_override, txtcol_override)
	if self.w < 1 then return end
	bg_override = bg_override or self.bg
	txtcol_override = txtcol_override or self.fg
	local lines = {}

	-- Split text into paragraphs based on explicit newlines
	local paragraphs = {}
	local start = 1
	local pos = self.text:find("\n", start, true)
	while pos do
		table.insert(paragraphs, self.text:sub(start, pos - 1))
		start = pos + 1
		pos = self.text:find("\n", start, true)
	end
	table.insert(paragraphs, self.text:sub(start))

	for i = 1, #paragraphs do
		local para = paragraphs[i]
		if #lines >= self.h then break end
		local mass = {}
		for w in para:gmatch("%S+") do
			table.insert(mass, w)
		end
		if #mass == 0 then
			-- Empty paragraph (or only whitespace), add a blank line
			if #lines < self.h then
				table.insert(lines, "")
			end
		else
			local row_txt = ""
			local iI = 1
			while iI <= #mass do
				if #lines >= self.h then break end
				local word = mass[iI]
				if #word > self.w then
					local remainder = word:sub(self.w + 1)
					if remainder ~= "" then
						table.insert(mass, iI + 1, remainder)
					end
					mass[iI] = word:sub(1, self.w)
					word = mass[iI]
				end
				local space_len = (row_txt == "" and 0 or 1)
				if #row_txt + space_len + #word <= self.w then
					row_txt = row_txt .. (row_txt == "" and "" or " ") .. word
					iI = iI + 1
				else
					if row_txt ~= "" then
						table.insert(lines, row_txt)
						row_txt = ""
					end
				end
			end
			if row_txt ~= "" and #lines < self.h then
				table.insert(lines, row_txt)
			end
		end
	end

	local horiz_align = "center"
	if self.align:find("left") then
		horiz_align = "left"
	elseif self.align:find("right") then
		horiz_align = "right"
	end

	local num_lines = #lines
	local vert_align = "center"
	if self.align:find("top") then
		vert_align = "top"
	elseif self.align:find("bottom") then
		vert_align = "bottom"
	end

	local start_y = self.y
	if vert_align == "top" then
		start_y = self.y
	elseif vert_align == "bottom" then
		start_y = self.y + self.h - num_lines
	else -- center
		start_y = self.y + math.floor((self.h - num_lines) / 2)
	end
	start_y = math.max(start_y, self.y)

	for i = self.y, start_y - 1 do
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, i); term.setTextColor(txtcol_override); term
			.write((" "):rep(self.w))
	end

	for j = 1, num_lines do
		local line = lines[j]
		local line_len = #line
		local x_pos = self.x
		if horiz_align == "left" then
			x_pos = self.x
		elseif horiz_align == "right" then
			x_pos = self.x + self.w - line_len
		else -- center
			x_pos = self.x + math.floor((self.w - line_len) / 2)
		end
		local left_pad = (" "):rep(x_pos - self.x)
		local right_pad = (" "):rep(self.w - (x_pos - self.x + line_len))
		local full_line = left_pad .. line .. right_pad
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, start_y + j - 1); term.setTextColor(
		txtcol_override); term.write(full_line)
	end

	local end_y = start_y + num_lines - 1
	for i = end_y + 1, self.y + self.h - 1 do
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, i); term.setTextColor(txtcol_override); term
			.write((" "):rep(self.w))
	end
end

function Label:setText(text)
	-- self.text = expect(text, 'text', 'string', 'nil') or ''
	self.text = tostring(text)
	self.dirty = true
end

---Creating new *object* of *class*
---@class Label
---@field x number X pos in characters
---@field y number Y pos in characters
---@field w number Width in characters
---@field h number Height in characters
---@field text? string Text content
---@field align? string Alignment string (e.g. "center", "left")
---@field fg color|number Foreground/text color
---@field bg color|number Background color
---@param args Label Initialization table with fields above
---@return table object label
function Label.new(args)
	local instance = Widget.new(args)

	instance.fg = expect_args(args, 'fg', 'number', 'nil') or colors.white
	instance.bg = expect_args(args, 'bg', 'number', 'nil') or colors.lightGray

	instance.text = expect_args(args, 'text', 'string', 'nil') or ''
	instance.align = expect_args(args, 'align', 'string', 'nil') or "center"

	instance.draw = Label.draw
	instance.setText = Label.setText

	return instance
end

return Label

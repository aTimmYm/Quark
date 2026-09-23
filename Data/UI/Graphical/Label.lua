local _Label = require 'Text.Label'
local font = require 'Font'
local g = require 'geometry'
local Label = {}

-- local function utf8_chars(str)
-- 	local i, n = 1, #str
-- 	return function()
-- 		if i > n then return nil end
-- 		local c = utf8.char(utf8.codepoint(str, i))
-- 		i = i + #c
-- 		return c
-- 	end
-- end
local function utf8_chars(str)
	-- if utf8 and utf8.codes and not jit then
	--   local iter, state, init = utf8.codes(str)
	--   return function()
	--     local byte_pos, codepoint = iter(state, init)
	--     init = byte_pos
	--     if not byte_pos then return nil end
	--     return utf8.char(codepoint)
	--   end
	-- end
	if utf8 and utf8.offset then
		local pos = 1
		local n = #str

		return function()
			if pos > n then
				return nil
			end

			local nextPos = utf8.offset(str, 2, pos)

			if nextPos then
				local ch = str:sub(pos, nextPos - 1)
				pos = nextPos
				return ch
			else
				local ch = str:sub(pos, n)
				pos = n + 1
				return ch
			end
		end
	end

	local pos, n = 1, #str
	return function()
		if pos > n then return nil end
		local b = str:byte(pos)
		local len = 1
		if b < 0x80 then
			len = 1
		elseif b < 0xE0 then
			len = 2
		elseif b < 0xF0 then
			len = 3
		else
			len = 4
		end
		local ch = str:sub(pos, pos + len - 1)
		pos = pos + len
		return ch
	end
end

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

local function clip_text_to_width(text, max_w, bold, scale)
	local out = {}
	local current = ""

	for ch in utf8_chars(text or "") do
		local candidate = current .. ch
		if font.calcWidth(candidate, bold, scale) <= max_w then
			current = candidate
		else
			break
		end
	end

	return current
end

local function push_wrapped_word(out_lines, word, max_w, bold, scale)
	local current = ""
	for ch in utf8_chars(word) do
		local candidate = current .. ch
		if current == "" or font.calcWidth(candidate, bold, scale) <= max_w then
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

local function wrap_text_to_width(text, max_w, bold, scale, wrap)
	if not wrap then
		local single = (text or ""):gsub("\n", " ")
		return { clip_text_to_width(single, max_w, bold, scale) }
	end

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
					local word_w = font.calcWidth(word, bold, scale)

					if word_w > max_w then
						if current ~= "" then
							lines[#lines + 1] = current
							current = ""
						end
						push_wrapped_word(lines, word, max_w, bold, scale)
					else
						local candidate = (current == "") and word or (current .. " " .. word)
						if font.calcWidth(candidate, bold, scale) <= max_w then
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

local function parse_align(align)
	align = align or "center"

	local h = "center"
	local v = "center"

	if align:find("left", 1, true) then
		h = "left"
	elseif align:find("right", 1, true) then
		h = "right"
	end

	if align:find("top", 1, true) then
		v = "top"
	elseif align:find("bot", 1, true) or align:find("bottom", 1, true) then
		v = "bottom"
	end

	return h, v
end

local function Label_rebuildLayout(self)
	local scale = self.scale or 1
	local bold = self.bold == true
	local line_gap = self.line_gap or 0
	local wrap = self.wrap ~= false

	local lines = wrap_text_to_width(self.text or "", self.w, bold, scale, wrap)
	local widths = {}

	for i = 1, #lines do
		widths[i] = font.calcWidth(lines[i], bold, scale)
	end

	self._layout_cache = {
		lines = lines,
		widths = widths,
		num_lines = #lines,
		line_h = font.charHeight * scale,
		block_h = #lines * (font.charHeight * scale) + math.max(0, #lines - 1) * line_gap,
		h_align = select(1, parse_align(self.align)),
		v_align = select(2, parse_align(self.align)),
		scale = scale,
		bold = bold,
		line_gap = line_gap,
	}
	self._layout_dirty = false
end

function Label.draw(self, bg_override, txtcol_override)
	bg_override = bg_override or self.bc
	txtcol_override = txtcol_override or self.fc

	if self._layout_dirty or not self._layout_cache then
		Label_rebuildLayout(self)
	end

	local layout = self._layout_cache

	if self.radius then
		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, bg_override)
	else
		term.drawPixels(self.x, self.y, bg_override, self.w, self.h)
	end

	local start_y
	if layout.v_align == "top" then
		start_y = self.y
	elseif layout.v_align == "bottom" then
		start_y = self.y + self.h - layout.block_h
	else
		start_y = self.y + math.floor((self.h - layout.block_h) / 2)
	end

	for i = 1, layout.num_lines do
		local line = layout.lines[i]
		local line_w = layout.widths[i]
		local x_pos

		if layout.h_align == "left" then
			x_pos = self.x
		elseif layout.h_align == "right" then
			x_pos = self.x + self.w - line_w
		else
			x_pos = self.x + math.floor((self.w - line_w) / 2)
		end

		local y_pos = start_y + (i - 1) * (layout.line_h + layout.line_gap)

		font.drawText(line, x_pos, y_pos, txtcol_override, nil, nil, nil, nil, nil, layout.bold, layout.scale) --, self.x, self.y, self.w, self.h, self.radius)
	end
end

-- local function Label_draw(self, bg_override, txtcol_override)
-- 	local offset = 0
-- 	if self.radius then
-- 		offset = self.radius
-- 		g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, self.bc)
-- 	else
-- 		term.drawPixels(self.x, self.y, self.bc, self.w, self.h)
-- 	end
-- 	if self.bold then
-- 		font.boldAlignedText(self.text, self.x + offset, self.y, self.fc)
-- 	else
-- 		font.simpleText(self.text, self.x + offset, self.y, self.fc, self.w, self.h, self.align)
-- 	end
-- end

function Label.setText(self, text)
	self._layout_dirty = true
	self.text = tostring(text)
	self.dirty = true
end

function Label.onLayout(self)
	self._layout_dirty = true
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
---@field bc color|number Background color
---@field fc color|number Foreground/text color
---@param args Label Initialization table with fields above
---@return table object label
function Label.new(args)
	local instance = _Label.new(args)

	instance.text = args.text or ""
	instance.align = args.align or "center"
	-- instance.bold = args.bold
	instance._layout_dirty = true
	instance._layout_cache = nil
	instance.wrap = args.wrap ~= false

	instance.draw = Label.draw
	instance.setText = Label.setText
	instance.onLayout = Label.onLayout

	return instance
end

return Label

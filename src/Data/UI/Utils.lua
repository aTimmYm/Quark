local Utils = {}

Utils.blittle = require 'blittle_extended'

local originalWrite = term.write
local function termWrite(string)
	local x, y = term.getCursorPos()

	if y < term.clipY or y >= term.clipH + term.clipY or x > term.clipW + term.clipX - 1 then return end

	local left = term.clipX - x
	local right = term.clipW - #string + left - 1
	if left > 0 then
		term.setCursorPos(term.clipX, y)
		string = string:sub(math.max(1, left + 1), math.min(-1, right))
	elseif right < -1 then
		string = string:sub(1, math.min(-1, right))
	end

	return originalWrite(string)
end

local originalBlit = term.blit
local function termBlit(text, textColour, backgroundColour)
	local x, y = term.getCursorPos()
	if y < term.clipY or y >= term.clipH + term.clipY or x > term.clipW + term.clipX - 1 then return end

	local left = term.clipX - x
	local right = term.clipW - #text + left - 1
	if left > 0 then
		term.setCursorPos(term.clipX, y)
		local a, b = math.max(1, left + 1), math.min(-1, right)
		text = text:sub(a, b)
		textColour = textColour:sub(a, b)
		backgroundColour = backgroundColour:sub(a, b)
	elseif right < -1 then
		local b = math.min(-1, right)
		text = text:sub(1, b)
		textColour = textColour:sub(1, b)
		backgroundColour = backgroundColour:sub(1, b)
	end

	return originalBlit(text, textColour, backgroundColour)
end

local original_setPixel = term.setPixel
local function term_setPixel(x, y, col)
	if x >= term.clip_x and
		x < term.clip_x + term.clip_w and
		y >= term.clip_y and
		y < term.clip_y + term.clip_h
	then
		return original_setPixel(x, y, col)
	end
end

local original_drawPixels = term.drawPixels
local function term_drawPixels(x, y, col, w, h)
	local x1 = math.max(x, term.clip_x)
	local y1 = math.max(y, term.clip_y)
	local x2 = math.min(x + w, term.clip_w + term.clip_x)
	local y2 = math.min(y + h, term.clip_h + term.clip_y)
	if x2 < x1 or y2 < y1 then return end
	return original_drawPixels(x1, y1, col, x2 - x1, y2 - y1)
end

function Utils.termSetClip(x, y, w, h)
	local old = {
		x = term.clipX,
		y = term.clipY,
		w = term.clipW,
		h = term.clipH
	}
	if old.x then
		local nx1 = math.max(x, old.x)
		local ny1 = math.max(y, old.y)
		local nx2 = math.min(x + w - 1, old.x + old.w - 1)
		local ny2 = math.min(y + h - 1, old.y + old.h - 1)

		if nx2 < nx1 or ny2 < ny1 then
			term.clipX, term.clipY, term.clipW, term.clipH = 0, 0, 0, 0
		else
			term.clipX = nx1
			term.clipY = ny1
			term.clipW = nx2 - nx1 + 1
			term.clipH = ny2 - ny1 + 1
		end
	else
		term.clipX, term.clipY, term.clipW, term.clipH = x, y, w, h
	end
	term.write = termWrite
	term.blit = termBlit
	return old
end

function Utils.termUnsetClip(old)
	term.clipX = old.x
	term.clipY = old.y
	term.clipW = old.w
	term.clipH = old.h
	if not old.x then
		term.blit = originalBlit
		term.write = originalWrite
	end
end

function Utils.graphSetClip(x, y, w, h)
	local old = {
		x = term.clip_x,
		y = term.clip_y,
		w = term.clip_w,
		h = term.clip_h
	}
	if old.x then
		local nx1 = math.max(x, old.x)
		local ny1 = math.max(y, old.y)
		local nx2 = math.min(x + w - 1, old.x + old.w - 1)
		local ny2 = math.min(y + h - 1, old.y + old.h - 1)

		if nx2 < nx1 or ny2 < ny1 then
			term.clip_x, term.clip_y, term.clip_w, term.clip_h = 0, 0, 0, 0
		else
			term.clip_x = nx1
			term.clip_y = ny1
			term.clip_w = nx2 - nx1 + 1
			term.clip_h = ny2 - ny1 + 1
		end
	else
		term.clip_x, term.clip_y, term.clip_w, term.clip_h = x, y, w, h
	end
	term.drawPixels = term_drawPixels
	term.setPixel = term_setPixel
	return old
end

function Utils.graphUnsetClip(old)
	term.clip_x = old.x
	term.clip_y = old.y
	term.clip_w = old.w
	term.clip_h = old.h
	if not old.x then
		term.drawPixels = original_drawPixels
		term.setPixel = original_setPixel
	end
end

function Utils.getMaxListW(array)
	local max = 0
	for _, v in pairs(array) do
		max = math.max(max, #v)
	end
	return max
end

function Utils.clamp(value, min, max)
	-- Utils.expect(value, 'value', 'number')
	-- Utils.expect(min, 'min', 'number')
	-- Utils.expect(max, 'max', 'number')
	return value <= min and min or (value >= max and max or value)
end

local to_hex = {}
local hex = '0123456789abcdef'
if not paintutils then
	for i = 1, 16 do
		to_hex[i - 1] = hex:sub(i, i)
	end
else
	for i = 1, 16 do
		to_hex[2^(i - 1)] = hex:sub(i, i)
	end
end
Utils.to_hex = to_hex

if not paintutils then
	function Utils.drawFilledBox(startX, startY, endX, endY, nColour)
		local width = endX - startX + 1
		local text, fg, bg = (' '):rep(width), ('1'):rep(width), to_hex[nColour]:rep(width)
		for i = startY, endY do
			term.setCursorPos(startX, i)
			term.blit(text, fg, bg)
		end
	end
else
	Utils.drawFilledBox = paintutils.drawFilledBox
end

function Utils.expect(arg, name, ...)
	local arg_type = type(arg)
	for i = 1, select('#', ...) do
		local expected = select(i, ...)
		if expected == arg_type or (expected == 'integer' and arg_type == 'number' and arg % 1 == 0) then
			return arg
		end
	end
	return error(
		'Unexpected argument \'' ..
		tostring(name) .. '\': expected [' .. table.concat({ ... }, ' | ') .. '], got \'' .. arg_type .. '\'', 2)
end

function Utils.expect_args(args, name, ...)
	local arg = args[name]
	local arg_type = type(arg)
	for i = 1, select('#', ...) do
		local expected = select(i, ...)
		if expected == arg_type or (expected == 'integer' and arg_type == 'number' and arg % 1 == 0) then
			return arg
		end
	end
	return error(
		'Unexpected argument \'' ..
		tostring(name) .. '\': expected [' .. table.concat({ ... }, ' | ') .. '], got \'' .. arg_type .. '\'', 2)
end

return Utils

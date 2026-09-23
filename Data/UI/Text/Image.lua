local Widget = require 'Text.Widget'

local Image = {}

local function loadImage(path)
	if not path or not fs.exists(path) then return end
	local image = {}
	local file = fs.open(path, 'r')
	local data = file.readAll()
	file.close()
	local index = 1
	for line in data:gmatch('([^\n]+)\n?') do
		image[index] = line
		index = index + 1
	end
	return image
end

local function imageToBlit(path)
	if not path or not fs.exists(path) then return end
	local file = fs.open(path, 'r')
	local image = file.readAll()
	file.close()
	return image
end

local function checkChunk(args)
	-- local function checkChunk(leftTop, rightTop, left, right, leftBot, rightBot)
	-- 	local args = {leftTop, rightTop, left, right, leftBot}
	local data = 128
	local inverse
	if rightBot then
		for i = 1, 5 do
			if args[i] then data = data + 2 ^ (i - 1) end
		end
	else
		for i = 1, 5 do
			if not args[i] then data = data + 2 ^ (i - 1) end
		end
		inverse = true
	end
	return { data, inverse }
end

local function checkImage(image)
	local bimg = {}
	local imgH = #image
	local imgW = 0
	for i = 1, imgH do
		local value = #image[i]
		imgW = value > imgW and value or imgW
	end
	local bH = math.ceil(imgH / 3)
	local bW = math.ceil(imgW / 2)
	for y = 1, bH, 3 do
		for x = 1, bW, 2 do
			local chunk = {}
			for j = 1, 3 do
				for i = 1, 2 do
					if (i + j) % 2 == 0 then
						table.insert(chunk, true)
					else
						table.insert(chunk, false)
					end
				end
			end
			local data = checkChunk(chunk)
			local char = data[1]
			local inv = data[2]
			if inv then
				if not bimg[y] then bimg[y] = '' end
				local line = bimg[y]
				line = line .. char
			end
		end
	end
	return bimg
end

function Image:draw()
	local emptyFg = ('1'):rep(self.w)
	local emptyText = (' '):rep(self.w)
	for i = 1, #self.image do
		term.setCursorPos(self.x, self.y + i - 1)
		term.blit(emptyText, emptyFg, self.image[i]:gsub(' ', colors.toBlit(self.bg)))
	end
end

function Image:changeImage()

end

function Image.new(args)
	local instance = Widget.new(args)

	instance.image = loadImage(args.path) --доделать станд. картинку

	if args.isBlit then
		instance.blitImage = imageToBlit()
	end

	instance.draw = Image.draw
	instance.changeImage = Image.changeImage

	return instance
end

return Image

local _Image = require 'Text.Image'

local Image = {}

local fromHex = {}
for n = 1, 16 do
	fromHex[("0123456789abcdef"):sub(n, n)] = string.char(n - 1)
end
fromHex[' '] = ' '

local function loadImage(path)
	if not path or not fs.exists(path) then return end
	local image = {}
	local file = fs.open(path, 'r')
	local data = file.readAll()
	file.close()
	local index = 1
	for line in data:gmatch('([^\n]+)\n?') do
		local string = ''
		for i = 1, #line do
			string = string .. fromHex[line:sub(i, i)]
		end
		image[index] = string
		index = index + 1
	end
	return image
end

function Image.draw(self)
	if not self.bc then
		paintutils.drawImage(self.image, self.x, self.y)
		return
	end
	local bc = string.char(math.log(self.bc, 2))
	for i = 1, self.h or #self.image do
		local line = self.image[i]
		if line then
			term.drawPixels(self.x, self.y + i - 1, { line:gsub(' ', bc) }, self.w, 1)
		end
	end
end

function Image.changeImage(self, path)
	self.image = loadImage(path)
end

function Image.new(args)
	local instance = _Image.new(args)
	if not args.bc then
		instance.image = paintutils.loadImage(args.path)
	else
		instance.image = loadImage(args.path) --доделать станд. картинку
	end

	instance.draw = Image.draw
	instance.changeImage = Image.changeImage

	return instance
end

return Image

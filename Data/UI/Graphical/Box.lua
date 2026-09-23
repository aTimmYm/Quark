local _Box = require 'Text.Box'
local _Container = require 'Graphical.Container'
local g = require 'geometry'

local Box = {}

function Box.draw(self)
	g.draw_filled_rounded_rect(self.x, self.y, self.w, self.h, self.radius, self.bc)
end

function Box.new(args)
	local instance = _Box.new(args)

	instance.draw = Box.draw
	instance.layoutChild = _Container.layoutChild

	return instance
end

return Box

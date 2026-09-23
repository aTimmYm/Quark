local _Root = require 'Text.Root'
local Container = require 'Graphical.Container'
local Root = {}

function Root.new(w, h)
	local instance = _Root.new(w, h)

	instance.layoutChild = Container.layoutChild

	return instance
end

return Root

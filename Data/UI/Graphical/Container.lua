local _Container = require 'Text.Container'
local Container = {}

for k, v in pairs(_Container) do
	Container[k] = v
end

function Container.layoutChild(self)
	for i = 1, #self.children do
		local child = self.children[i]
		child.x, child.y = self.x + child.localX, self.y + child.localY
	end
end

function Container.new(args)
	local instance = _Container.new(args)
	instance.layoutChild = Container.layoutChild
	return instance
end

return Container

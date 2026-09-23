local vfs = fs or require 'syscalls'
if not fs then
	function vfs.isDir(path)
		return vfs.stat(path).isDir
	end

	function vfs.exists(path)
		return vfs.stat(path) ~= nil
	end

	os.startTimer = vfs.timer_start
	os.cancelTimer = vfs.timer_cancel
end


local absPath = '/Quark/Data/'
local myPath = absPath .. 'UI/'
local oldPath = package.path
package.path = package.path .. ';' .. myPath .. '?;' .. myPath .. '?.lua;' .. myPath .. '?/init.lua'
local UI = {}
local T = 'Text'
local G = 'Graphical'

UI.Utils = require 'Utils'

-- local TPath = vfs.combine(myPath, T)
local TPath = myPath .. T
-- local GPath = vfs.combine(myPath, G)

local Telements = vfs.list(TPath)
-- local Gelements = fs.list(GPath)

local Gmode = false
if term.getGraphicsMode and term.getGraphicsMode() then
	-- Gmode = term.getGraphicsMode()
	-- if Gmode then
	for i = 1, #Telements do
		local className = Telements[i]:sub(1, -5)
		local classPath = G .. className
		if not vfs.exists(myPath .. classPath .. '.lua') then
			classPath = T .. className
		end
		UI[className] = require(classPath).new
	end
else
	for i = 1, #Telements do
		local className = Telements[i]:sub(1, -5)
		local classPath = T .. '/' .. className
		UI[className] = require(classPath).new
	end
	-- end
end


-- local valid = {
-- 	[myPath .. 'Text'] = true,
-- 	[myPath .. 'Mixins'] = true,
-- 	[myPath .. 'Graphical'] = true,
-- }

-- local function getFiles(path, tbl)
-- 	tbl = tbl or {}
-- 	local list = vfs.list(path)
-- 	for i = 1, #list do
-- 		local target = list[i]
-- 		local p = '/' .. vfs.combine(path, target)
-- 		if vfs.isDir(p) then
-- 			getFiles(p, tbl)
-- 		elseif valid[path] then
-- 			local s, e = p:find(myPath, 1, true)
-- 			table.insert(tbl, p:sub(e + 1, -5)) --xD
-- 		end
-- 	end
-- 	return tbl
-- end

-- local unload = getFiles(myPath)
-- for i = 1, #unload do
-- 	package.loaded[unload[i]] = nil
-- end

package.path = oldPath

UI.colors = {
	white = 0,
	orange = 1,
	magenta = 2,
	lightBlue = 3,
	yellow = 4,
	lime = 5,
	pink = 6,
	gray = 7,
	lightGray = 8,
	cyan = 9,
	purple = 10,
	blue = 11,
	brown = 12,
	green = 13,
	red = 14,
	black = 15
}

return UI

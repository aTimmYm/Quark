local settingsPath = APPDIR .. '/Data/Settings/user.json'
local defaultData = {
	tab_size = 3,             -- [1; 8]
	indent_tabs = true,       -- true = tabs, false = spaces
	line_indents_enabled = true, -- true / false
	line_ending = 'detect',   -- 'detect' / 'enforce_lf' / 'enforce_crlf'
	-- syntax_analyzer_enabled = true, -- true / false
	lex_enabled = true,       -- true / false

	-- colors
	color_editor_selected_text = colors.blue, -- colors.blue,
	color_editor_cursor = colors.white,      -- colors.white,
	color_editor_found_all = colors.white,   -- colors.white
	color_editor_found_current = colors.pink, -- colors.pink

	color_whitespace = colors.white,         -- colors.white,
	color_comment = colors.gray,            -- colors.gray,
	color_string = colors.green,            -- colors.green,
	color_escape = colors.white,             -- colors.white,
	color_keyword = colors.brown,           -- colors.brown,
	color_value = colors.white,              -- colors.white,
	color_ident = colors.lightBlue,              -- colors.lightBlue,
	color_number = colors.white,             -- colors.white,
	color_symbol = colors.yellow,             -- colors.yellow,
	color_operator = colors.white,           -- colors.white,
	color_unidentified = colors.red,      -- colors.red,
	color_function = colors.orange,           -- colors.orange,
	color_nfunction = colors.purple,         -- colors.purple,
	color_equality = colors.red,          -- colors.red,
	color_arg = colors.white,                -- colors.white,

	-- window size
	w = 51,
	h = 19,
}
local user

if vfs.exists(settingsPath) then
	local file = io.open(settingsPath, 'r')
	user = file:read('a')
	file:close()
else
	local jsonDefaultData = textutils.serialiseJSON(defaultData)
	local file = io.open(settingsPath, 'w')
	file:write(jsonDefaultData)
	file:close()
	user = jsonDefaultData
end
user = textutils.unserialiseJSON(user)

local function saveUserSettings()
	local file = io.open(settingsPath, 'w')
	file:write(textutils.serialiseJSON(user))
	file:close()
end
do
	user = user or {}
	local write = false
	for k, v in pairs(defaultData) do
		if type(user[k]) == 'nil' then
			user[k] = v
			write = true
		end
	end
	if write then saveUserSettings() end
end

return setmetatable(user, {
	__call = saveUserSettings,
	__metatable = false,
})

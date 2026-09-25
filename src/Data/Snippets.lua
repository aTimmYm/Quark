local _snippets = {}

local possible_commands = {
	no_context = {
		-- keywords
		'and',
		'break',
		'do',
		'else',
		'elseif',
		'end',
		'for',
		'function',
		'goto',
		'if',
		'in',
		'local',
		'not',
		'or',
		'repeat',
		'return',
		'then',
		'until',
		'while',

		-- values
		'true',
		'false',
		'nil',
		'self',

		-- Lua: global functions
		'assert',
		'error',
		'getmetatable',
		'ipairs',
		'load',
		'loadfile',
		'next',
		'pairs',
		'pcall',
		'rawequal',
		'rawget',
		'rawlen',
		'rawset',
		'select',
		'setmetatable',
		'tonumber',
		'tostring',
		'type',
		'xpcall',
		'require',

		-- Lua: global variables
		'_G',
		'_ENV',
		'_VERSION',

		-- Lua: libraries
		'coroutine',
		'debug',
		'io',
		'math',
		'os',
		'package',
		'string',
		'table',
		'utf8',
		'bit32',

		-- CC:Tweaked global functions
		'print',
		'printError',
		'read',
		'write',
		'sleep',

		-- CC:Tweaked global APIs
		'colors',
		'colours',
		'commands',
		'disk',
		'fs',
		'gps',
		'help',
		'http',
		'keys',
		'multishell',
		'paintutils',
		'parallel',
		'peripheral',
		'pocket',
		'rednet',
		'redstone',
		'settings',
		'shell',
		'term',
		'textutils',
		'turtle',
		'vector',
		'window',
	},

	coroutine = {
		'create',
		'isyieldable',
		'resume',
		'running',
		'status',
		'wrap',
		'yield',
	},

	math = {
		'abs',
		'acos',
		'asin',
		'atan',
		'ceil',
		'cos',
		'deg',
		'exp',
		'floor',
		'fmod',
		'huge',
		'log',
		'max',
		'min',
		'modf',
		'pi',
		'rad',
		'random',
		'randomseed',
		'sin',
		'sqrt',
		'tan',
	},

	string = {
		'byte',
		'char',
		'dump',
		'find',
		'format',
		'gmatch',
		'gsub',
		'len',
		'lower',
		'match',
		'rep',
		'reverse',
		'sub',
		'upper',
		'pack',
		'packsize',
		'unpack',
	},

	table = {
		'concat',
		'create',
		'insert',
		'move',
		'pack',
		'remove',
		'sort',
		'unpack',
	},

	utf8 = {
		'char',
		'charpattern',
		'codes',
		'codepoint',
		'len',
		'offset',
	},

	bit32 = {
		'arshift',
		'band',
		'bnot',
		'bor',
		'btest',
		'bxor',
		'lrotate',
		'lshift',
		'rrotate',
		'rshift',
	},

	debug = {
		'debug',
		'gethook',
		'getinfo',
		'getlocal',
		'getmetatable',
		'getregistry',
		'getupvalue',
		'sethook',
		'setlocal',
		'setmetatable',
		'setupvalue',
		'traceback',
		'upvalueid',
		'upvaluejoin',
	},

	io = {
		'close',
		'flush',
		'input',
		'lines',
		'open',
		'output',
		'read',
		'type',
		'write',
	},

	colors = { -- / colours
		'white',
		'orange',
		'magenta',
		'lightBlue',
		'yellow',
		'lime',
		'pink',
		'gray',
		'grey',
		'lightGray',
		'lightGrey',
		'cyan',
		'purple',
		'blue',
		'brown',
		'green',
		'red',
		'black',
		'combine',
		'subtract',
		'test',
		'pack',
		'unpack',
		'normalize',
		'toBlit',
		'fromBlit',
	},

	fs = {
		'complete',
		'find',
		'isDriveRoot',
		'list',
		'combine',
		'getName',
		'getDir',
		'getSize',
		'exists',
		'isDir',
		'isReadOnly',
		'makeDir',
		'move',
		'copy',
		'delete',
		'open',
		'getDrive',
		'getFreeSpace',
		'getCapacity',
		'attributes',
	},

	gps = {
		'locate',
	},

	help = {
		'path',
		'setPath',
		'lookup',
		'topics',
		'completeTopic',
	},

	http = {
		'get',
		'post',
		'request',
		'checkURL',
		'checkURLAsync',
		'websocket',
		'websocketAsync',
	},

	os = {
		'loadAPI',
		'unloadAPI',
		'pullEvent',
		'pullEventRaw',
		'sleep',
		'version',
		'run',
		'queueEvent',
		'startTimer',
		'cancelTimer',
		'getComputerID',
		'getComputerLabel',
		'setComputerLabel',
		'shutdown',
		'reboot',
		'day',
		'time',
		'clock',
		'epoch',
		'date',
	},

	parallel = {
		'waitForAny',
		'waitForAll',
		'invoke',
	},

	peripheral = {
		'getNames',
		'isPresent',
		'getType',
		'hasType',
		'getMethods',
		'getName',
		'call',
		'wrap',
		'find',
	},

	rednet = {
		'open',
		'close',
		'isOpen',
		'send',
		'broadcast',
		'receive',
		'host',
		'unhost',
		'lookup',
	},

	redstone = {
		'getSides',
		'getInput',
		'getOutput',
		'setOutput',
		'getAnalogInput',
		'getAnalogOutput',
		'setAnalogOutput',
		'getBundledInput',
		'getBundledOutput',
		'setBundledOutput',
		'testBundledInput',
	},

	settings = {
		'define',
		'undefine',
		'set',
		'get',
		'getDetails',
		'unset',
		'clear',
		'getNames',
		'load',
		'save',
	},

	shell = {
		'execute',
		'run',
		'exit',
		'dir',
		'setDir',
		'path',
		'setPath',
		'resolve',
		'resolveProgram',
		'programs',
		'complete',
		'completeProgram',
		'setCompletionFunction',
		'getCompletionInfo',
		'getRunningProgram',
		'setAlias',
		'clearAlias',
		'aliases',
		'openTab',
		'switchTab',
	},

	term = {
		'write',
		'scroll',
		'getCursorPos',
		'setCursorPos',
		'getCursorBlink',
		'setCursorBlink',
		'getSize',
		'clear',
		'clearLine',
		'setTextColor',
		'setTextColour',
		'getTextColor',
		'getTextColour',
		'setBackgroundColor',
		'setBackgroundColour',
		'getBackgroundColor',
		'getBackgroundColour',
		'isColor',
		'isColour',
		'nativePaletteColor',
		'nativePaletteColour',
		'getPaletteColor',
		'getPaletteColour',
		'setPaletteColor',
		'setPaletteColour',
		'screenshot',
		'current',
		'redirect',
		'redirect',
	},

	textutils = {
		'slowWrite',
		'slowPrint',
		'formatTime',
		'pagedPrint',
		'tabulate',
		'pagedTabulate',
		'serialize',
		'serialise',
		'unserialize',
		'unserialise',
		'serializeJSON',
		'serialiseJSON',
		'unserializeJSON',
		'unserialiseJSON',
		'urlEncode',
		'complete',
	},

	paintutils = {
		'drawPixel',
		'drawLine',
		'drawBox',
		'drawFilledBox',
		'fill',
		'drawImage',
		'loadImage',
	},

	turtle = {
		'craft',
		'forward',
		'back',
		'up',
		'down',
		'turnLeft',
		'turnRight',
		'dig',
		'digUp',
		'digDown',
		'place',
		'placeUp',
		'placeDown',
		'drop',
		'dropUp',
		'dropDown',
		'suck',
		'suckUp',
		'suckDown',
		'attack',
		'attackUp',
		'attackDown',
		'detect',
		'detectUp',
		'detectDown',
		'compare',
		'compareUp',
		'compareDown',
		'compareTo',
		'select',
		'getItemCount',
		'getItemSpace',
		'getItemDetail',
		'getSelectedSlot',
		'getFuelLevel',
		'getFuelLimit',
		'refuel',
		'equipLeft',
		'equipRight',
		'equip',
		'getEquippedLeft',
		'getEquippedRight',
		'inspect',
		'inspectUp',
		'inspectDown',
		'compareUp',
		'compareDown',
		'getSelectedSlot',
		'suck',
	},

	vector = {
		'new',
		'add',
		'subtract',
		'multiply',
		'divide',
		'dot',
		'cross',
		'length',
		'normalize',
		'round',
		'unpack',
	},

	multishell = {
		'getCurrent',
		'launch',
		'list',
		'getFocus',
		'setFocus',
		'getTitle',
		'setTitle',
		'getCount',
	},

	pocket = {
		'equipBack',
		'unequipBack',
		'getUpgrade',
	},

	commands = {
		'exec',
		'execAsync',
		'list',
		'getDimension',
		'getBlockPosition',
		'getBlockInfos',
		'getBlockInfo',
		'getEntities',
	},

	disk = {
		'isPresent',
		'getLabel',
		'setLabel',
		'getID',
		'hasData',
		'getMountPath',
		'getAudioTitle',
		'playAudio',
		'stopAudio',
		'eject',
	},

	window = {
		'create',
	},
}
possible_commands.colours = possible_commands.colors

function _snippets.getSnippets(str)
	if type(str) ~= 'string' then
		error('function getSnippets, bad argument #1: expected string, get \'' .. type(word) .. '\'', 2)
	end
	local snippets = {}

	local array_name = str:match('([%w_]+)%[#$')
	if array_name then
		return { array_name .. '+1' }
	end

	if not str:match('([%w_%.]+)$') then return snippets end

	local context, word = str:match('([%w_]+)%.([%w_]*)$')
	if not word then
		if str:sub(-1, -1) == '.' then
			context = str:match('([%w_]+)$')
		else
			word = str:match('([%w_]+)$')
		end
	end
	context = context or 'no_context'
	local context_commands = possible_commands[context]
	if context_commands then
		if word then
			for i = 1, #context_commands do
				local snip = context_commands[i]
				if snip:sub(1, #word) == word then
					snippets[#snippets + 1] = snip
				end
			end
		elseif context ~= 'no_context' then
			for i = 1, #context_commands do
				snippets[#snippets + 1] = context_commands[i]
			end
		end
	end
	return snippets
end

function _snippets.addSnippet(snip)
	if type(word) ~= 'string' then
		error(
			'function addSnippet, bad argument #1: expected string, get \'' .. type(word) .. '\'', 2)
	end

	for i = 1, #possible_commands do
		if snip == possible_commands[i] then
			return
		end
	end
	possible_commands[#possible_commands + 1] = snip
end

function _snippets.removeSnippet(snip)
	if type(word) ~= 'string' then
		error(
			'function removeSnippet, bad argument #1: expected string, get \'' .. type(word) .. '\'', 2)
	end

	for i = 1, #possible_commands do
		if snip == possible_commands[i] then
			table.remove(possible.possible_commands, i)
			return
		end
	end
end

return _snippets

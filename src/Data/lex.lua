-- Lex, by LoganDark
-- Can be loaded using os.loadAPI, has only a single function: lex.lex('code here')
-- If loaded using dofile(), it returns the lex function (for environments outside ComputerCraft)
-- It returns a list of lists, where each list is one line.
-- Each line contains tokens (in the order they are found), where each token is formatted like this:
-- {
--  type = one of the token types below,
--  data = the source code that makes up the token,
--  posFirst = the position (inclusive) within THAT LINE that the token starts
--  posLast = the position (inclusive) within THAT LINE that the token ends
-- }

-- Possible token types:
--  whitespace: Self-explanatory. Can match spaces, newlines, tabs, and carriage returns (although I don't know why anyone would use those... WINDOWS)
--  comment: Either multi-line or single-line comments.
--  string: A string. Usually the part of the string that is not an escape.
--  escape: Can only be found within strings (although they are separate tokens)
--  keyword: Keywords. Like "while", "end", "do", etc
--  value: Special values. Only true, false, and nil.
--  ident: Identifier. Variables, function names, etc..
--  number: Numbers!
--  symbol: Symbols, like brackets, parenthesis, ., .., ... etc
--  operator: Operators, like =, ==, >=, <=, ~=, etc
--  unidentified: Anything that isn't one of the above tokens. Consider them ERRORS.

local chars = {
	whitespace = {
		[' '] = true,
		['\n'] = true,
		['\t'] = true,
		['\r'] = true
	},

	validEscapes = {
		['a'] = true,
		['b'] = true,
		['f'] = true,
		['n'] = true,
		['r'] = true,
		['t'] = true,
		['v'] = true,
		['"'] = true,
		['\''] = true,
		['\\'] = true,
		['\n'] = true
	},

	ident = {
		['a'] = true,
		['b'] = true,
		['c'] = true,
		['d'] = true,
		['e'] = true,
		['f'] = true,
		['g'] = true,
		['h'] = true,
		['i'] = true,
		['j'] = true,
		['k'] = true,
		['l'] = true,
		['m'] = true,
		['n'] = true,
		['o'] = true,
		['p'] = true,
		['q'] = true,
		['r'] = true,
		['s'] = true,
		['t'] = true,
		['u'] = true,
		['v'] = true,
		['w'] = true,
		['x'] = true,
		['y'] = true,
		['z'] = true,
		['A'] = true,
		['B'] = true,
		['C'] = true,
		['D'] = true,
		['E'] = true,
		['F'] = true,
		['G'] = true,
		['H'] = true,
		['I'] = true,
		['J'] = true,
		['K'] = true,
		['L'] = true,
		['M'] = true,
		['N'] = true,
		['O'] = true,
		['P'] = true,
		['Q'] = true,
		['R'] = true,
		['S'] = true,
		['T'] = true,
		['U'] = true,
		['V'] = true,
		['W'] = true,
		['X'] = true,
		['Y'] = true,
		['Z'] = true,
		['_'] = true,
		['0'] = true,
		['1'] = true,
		['2'] = true,
		['3'] = true,
		['4'] = true,
		['5'] = true,
		['6'] = true,
		['7'] = true,
		['8'] = true,
		['9'] = true,

		start = {
			['a'] = true,
			['b'] = true,
			['c'] = true,
			['d'] = true,
			['e'] = true,
			['f'] = true,
			['g'] = true,
			['h'] = true,
			['i'] = true,
			['j'] = true,
			['k'] = true,
			['l'] = true,
			['m'] = true,
			['n'] = true,
			['o'] = true,
			['p'] = true,
			['q'] = true,
			['r'] = true,
			['s'] = true,
			['t'] = true,
			['u'] = true,
			['v'] = true,
			['w'] = true,
			['x'] = true,
			['y'] = true,
			['z'] = true,
			['A'] = true,
			['B'] = true,
			['C'] = true,
			['D'] = true,
			['E'] = true,
			['F'] = true,
			['G'] = true,
			['H'] = true,
			['I'] = true,
			['J'] = true,
			['K'] = true,
			['L'] = true,
			['M'] = true,
			['N'] = true,
			['O'] = true,
			['P'] = true,
			['Q'] = true,
			['R'] = true,
			['S'] = true,
			['T'] = true,
			['U'] = true,
			['V'] = true,
			['W'] = true,
			['X'] = true,
			['Y'] = true,
			['Z'] = true,
			['_'] = true
		},
	},

	digits = {
		['0'] = true,
		['1'] = true,
		['2'] = true,
		['3'] = true,
		['4'] = true,
		['5'] = true,
		['6'] = true,
		['7'] = true,
		['8'] = true,
		['9'] = true,

		hex = {
			['0'] = true,
			['1'] = true,
			['2'] = true,
			['3'] = true,
			['4'] = true,
			['5'] = true,
			['6'] = true,
			['7'] = true,
			['8'] = true,
			['9'] = true,
			['a'] = true,
			['b'] = true,
			['c'] = true,
			['d'] = true,
			['e'] = true,
			['f'] = true,
			['A'] = true,
			['B'] = true,
			['C'] = true,
			['D'] = true,
			['E'] = true,
			['F'] = true
		}
	},

	symbols = {
		['+'] = true,
		['-'] = true,
		['*'] = true,
		['/'] = true,
		['^'] = true,
		['%'] = true,
		[','] = true,
		['{'] = true,
		['}'] = true,
		['['] = true,
		[']'] = true,
		['('] = true,
		[')'] = true,
		[';'] = true,
		['#'] = true,
		['.'] = true,
		[':'] = true,

		equality = {
			['~'] = true,
			['='] = true,
			['>'] = true,
			['<'] = true
		},

		operators = {
			['+'] = true,
			['-'] = true,
			['*'] = true,
			['/'] = true,
			['^'] = true,
			['%'] = true,
			['#'] = true
		}
	}
}

local keywords = {
	structure = {
		['and'] = true,
		['break'] = true,
		['do'] = true,
		['else'] = true,
		['elseif'] = true,
		['end'] = true,
		['for'] = true,
		['function'] = true,
		['goto'] = true,
		['if'] = true,
		['in'] = true,
		['local'] = true,
		['not'] = true,
		['or'] = true,
		['repeat'] = true,
		['return'] = true,
		['then'] = true,
		['until'] = true,
		['while'] = true
	},

	values = {
		['true'] = true,
		['false'] = true,
		['nil'] = true,
		['self'] = true,
	}
}

local states = {
	NORMAL = "normal",
	STRING = "string",
	COMMENT = "comment"
}

local function lex(line, prevState)
	local pos = 1
	local start = 1
	local len = #line
	local buffer = {}
	local currentState = prevState or { type = states.NORMAL, level = 0 }

	local function look(delta)
		delta = pos + (delta or 0)
		return line:sub(delta, delta)
	end

	local function get()
		local char = line:sub(pos, pos)
		pos = pos + 1
		return char
	end

	local function getLevel()
		local num = 0
		while look(num) == '=' do
			num = num + 1
		end
		if look(num) == '[' then
			pos = pos + num
			return num
		else
			return nil
		end
	end

	local function token(type, text)
		local tk = buffer[#buffer]
		if not tk or tk.type ~= type then
			local tk = {
				type = type,
				data = text or line:sub(start, pos - 1),
				posFirst = start,
				posLast = pos - 1
			}
			if tk.data ~= '' then
				buffer[#buffer + 1] = tk
			end
		else
			tk.data = tk.data .. (text or line:sub(start, pos - 1))
			tk.posLast = tk.posFirst + #tk.data - 1
		end
		start = pos
		return tk
	end

	local function processMultiline(type_str)
		local level = currentState.level
		while pos <= len do
			local char = get()
			if char == ']' then
				local valid = true
				for i = 1, level do
					if look() == '=' then
						pos = pos + 1
					else
						valid = false
						break
					end
				end
				if valid and look() == ']' then
					pos = pos + 1
					token(type_str)
					currentState = { type = states.NORMAL, level = 0 }
					return true -- Closed
				end
			end
		end
		token(type_str)
		return false -- Not closed
	end

	while pos <= len do
		if currentState.type ~= states.NORMAL then
			processMultiline(currentState.type == states.STRING and 'string' or 'comment')
		else
			-- Нормальное состояние
			while true do
				local char = look()
				if chars.whitespace[char] then
					pos = pos + 1
				else
					break
				end
			end
			token('whitespace')

			if pos > len then break end

			char = get()

			if char == '-' and look() == '-' then
				pos = pos + 1
				if look() == '[' then
					pos = pos + 1
					local level = getLevel()
					if level then
						currentState = { type = states.COMMENT, level = level }
						processMultiline('comment')
					else
						-- Однострочный комментарий
						while pos <= len do get() end
						token('comment')
					end
				else
					-- Однострочный комментарий
					while pos <= len do get() end
					token('comment')
				end
			elseif char == '\'' or char == '"' then
				local quote = char
				while true do
					local char2 = get()
					if char2 == '\\' then
						pos = pos - 1
						token('string')
						get()
						local char3 = get()
						if chars.digits[char3] then
							for i = 1, 2 do
								if chars.digits[look()] then pos = pos + 1 end
							end
						elseif char3 == 'x' then
							if chars.digits.hex[look()] and chars.digits.hex[look(1)] then
								pos = pos + 2
							else
								token('unidentified')
							end
						elseif not chars.validEscapes[char3] then
							token('unidentified')
						end
						token('escape')
					elseif char2 == quote then
						break
					elseif pos > len then
						break
					end
				end
				token('string')
			elseif chars.ident.start[char] then
				while chars.ident[look()] do
					pos = pos + 1
				end
				local word = line:sub(start, pos - 1)
				if word == 'self' or word == '_ENV' or word == "_G" then
					token('arg')
				elseif word == 'function' then
					local findBracket = false
					local c = 0
					while true do
						local lChar = look(c)
						if lChar == " " or lChar == "\t" then
							c = c + 1
						elseif lChar == "(" then
							findBracket = true
							break
						else
							break
						end
					end
					if findBracket then
						local cbuf = #buffer
						local findEquals = false
						while true do
							if not buffer[cbuf] then
								break
							elseif buffer[cbuf].type == "whitespace" then
								cbuf = cbuf - 1
							elseif buffer[cbuf].data == "=" and not findEquals then
								cbuf = cbuf - 1
								findEquals = true
							elseif buffer[cbuf].type == "ident" and findEquals then
								buffer[cbuf].type = "nfunction"
								break
							else
								break
							end
						end
					end
					token('function')
				elseif keywords.structure[word] then
					token('keyword')
				elseif keywords.values[word] then
					token('value')
				else
					local findBracket = false
					local c = 0
					while true do
						local lChar = look(c)
						if lChar == " " or lChar == "\t" then
							c = c + 1
						elseif lChar == "(" then
							findBracket = true
							break
						else
							break
						end
					end
					if findBracket then
						if buffer[#buffer - 1] and buffer[#buffer - 1].data == "function" and buffer[#buffer].type == "whitespace" then
							token('nfunction')
						else
							token('function')
						end
					else
						local b = #buffer
						local isArg = true
						local closedArgs = false
						while true do
							local buf = buffer[b]
							if not buf then
								isArg = false
								break
							elseif buf.data == "(" or buf.type == "whitespace" or buf.data == "," or buf.type == "arg" then
								if buf.data == "(" then
									closedArgs = true
								end
								b = b - 1
							elseif (buf.data == "function" or buf.type == "nfunction") and closedArgs then
								token('arg')
								break
							else
								isArg = false
								break
							end
						end
						if not isArg then
							token('ident')
						end
					end
				end
			elseif chars.digits[char] or (char == '.' and chars.digits[look()]) then
				if char == '0' and look() == 'x' then
					pos = pos + 1
					while chars.digits.hex[look()] do
						pos = pos + 1
					end
				else
					while chars.digits[look()] do
						pos = pos + 1
					end
					if look() == '.' then
						pos = pos + 1
						while chars.digits[look()] do
							pos = pos + 1
						end
					end
					if look():lower() == 'e' then
						pos = pos + 1
						if look() == '-' then
							pos = pos + 1
						end
						while chars.digits[look()] do
							pos = pos + 1
						end
					end
				end
				token('number')
			elseif char == '[' then
				local level = getLevel()
				if level then
					currentState = { type = states.STRING, level = level }
					processMultiline('string')
				else
					token('symbol')
				end
			elseif char == '.' then
				if look() == '.' then
					pos = pos + 1
					if look() == '.' then
						pos = pos + 1
						token('value')
					else
						token('operator')
					end
				else
					token('symbol')
				end
			elseif chars.symbols.equality[char] then
				if look() == '=' then
					pos = pos + 1
				end
				token('operator')
			elseif chars.symbols[char] then
				if chars.symbols.operators[char] then
					token('operator')
				else
					token('symbol')
				end
			else
				token('unidentified')
			end
		end
	end

	return buffer, currentState
end

return lex

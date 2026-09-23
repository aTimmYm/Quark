local Analyzer = {}


-- Лексер (lex.lua) различает "идентификаторы" по их роли:
--   ident      — обычная переменная / поле
--   function   — имя ВЫЗЫВАЕМОЙ функции (сразу перед "(")
--   nfunction  — имя ОБЪЯВЛЯЕМОЙ функции (после "function" / "local function")
--   arg        — self, _ENV, _G
--
-- Раньше EXPECTS/FORBIDS знали только про "ident", поэтому:
--   - имя объявляемой функции (nfunction) считалось "неожиданным токеном"
--     (local function NAME — NAME не был среди ожидаемых типов);
--   - вызов функции после "=" (например, `local x = setmetatable(...)`)
--     тоже считался ошибкой, т.к. "function" не было среди ожидаемых
--     типов после "=";
--   - как следствие, скобки вызова так же попадали в список ошибок —
--     просто потому, что анализатор уже "сошёл с рельс" на самом имени
--     функции и это как-то размазывалось на соседние токены.

-- Строгие требования (что ОБЯЗАНО идти следом)
--
-- ВАЖНО про лексер: token() в lex.lua склеивает подряд идущие токены
-- ОДНОГО типа в один. Символы вроде "(", ")", "{", "}", "," все имеют
-- type = 'symbol', поэтому "({}," или "()" или "((" на деле прилетают
-- сюда как ОДИН токен ("(((", "()" и т.п.), а не по одному символу.
-- Поэтому проверять здесь конкретное значение data (например data=='(')
-- ненадёжно — вместо этого просто разрешаем ЛЮБОЙ 'symbol' после имени
-- функции: раз лексер присвоил токену type='function'/'nfunction', он
-- уже сам гарантировал, что дальше идёт "(" (возможно, слипшаяся с
-- соседними скобками/запятыми).
--
-- 'operator' тоже добавлен в EXPECTS['=']: унарные операторы вроде
-- "#" (взятие длины) и "-" (унарный минус) имеют type='operator',
-- а не 'symbol', и должны быть разрешены сразу после "=".
local EXPECTS                    = {
	['local']    = { type = { ident = true, arg = true }, data = { ['function'] = true } },
	['function'] = { type = { ident = true, nfunction = true, symbol = true }, data = { ['('] = true } },
	['=']        = {
		type = {
			ident = true,
			number = true,
			string = true,
			value = true,
			symbol = true,
			operator = true,
			['function'] = true,
			nfunction = true,
			arg = true
		}
	},
}

-- Множество типов, которые не могут идти друг за другом без оператора
-- между ними (например, "foo bar", "foo 5", "foo getSize()").
local FORBIDDEN_NEXT             = {
	ident = true,
	number = true,
	value = true,
	['function'] = true,
	nfunction = true,
	arg = true,
}

-- Запреты (чего НЕ МОЖЕТ быть следом, например, два числа подряд).
--
-- ВАЖНО: ключ 'function' сюда намеренно НЕ добавляется. Он бы совпал
-- с ключевым словом "function" в EXPECTS (у него и type, и data токена
-- равны "function"), и запрет срабатывал бы одновременно со строгим
-- ожиданием сразу после "local function" — то есть имя объявляемой
-- функции снова помечалось бы как ошибка, хоть EXPECTS его и разрешает.
local FORBIDS                    = {
	['ident']     = { type = FORBIDDEN_NEXT, data = { ['local'] = true, ['function'] = true } },
	['nfunction'] = { type = FORBIDDEN_NEXT, data = { ['local'] = true, ['function'] = true } },
	['arg']       = { type = FORBIDDEN_NEXT, data = { ['local'] = true, ['function'] = true } },
	['number']    = { type = FORBIDDEN_NEXT },
	['value']     = { type = FORBIDDEN_NEXT },
}

-- Токены этих типов МОГУТ быть началом statement'а, но только если он
-- в итоге превращается в вызов функции или присваивание (иначе это
-- просто "висящее" выражение без эффекта, см. LONE_INVALID_TYPES ниже).
local LONE_INVALID_TYPES         = { ident = true, nfunction = true, arg = true }

-- Токены этих типов вообще никогда не могут быть первым токеном statement'а
-- сами по себе — число, строковое/булево значение, "мусорный" символ.
local ALWAYS_INVALID_START_TYPES = { number = true, value = true, unidentified = true }

-- Токены, которыми может корректно ЗАКОНЧИТЬСЯ выражение (после них Lua
-- допускает перенос строки и продолжение бинарным оператором на новой
-- строке — Lua вообще не чувствителен к переносам строк в выражениях).
local ENDS_EXPRESSION_TYPES      = { ident = true, number = true, string = true, value = true, ['function'] = true, nfunction = true, arg = true }

local BRACKET_OPEN               = { ['('] = true, ['{'] = true, ['['] = true }
local BRACKET_CLOSE              = { [')'] = true, ['}'] = true, [']'] = true }

function Analyzer.scan(tokens, prev_state)
	local state = {
		expected_types = prev_state.expected_types,
		expected_data = prev_state.expected_data,
		block_depth = prev_state.block_depth or 0,
		bracket_depth = prev_state.bracket_depth or 0,
	}
	local errors = {}

	-- Был ли на входе "хвост" незавершённого выражения с прошлой строки
	-- (например, строка выше закончилась на "local x =") — если да, то
	-- эта строка на самом деле НЕ является отдельным statement'ом, а
	-- продолжает предыдущий, и проверять её как самостоятельную нельзя.
	local had_incoming_expectation = (prev_state.expected_types ~= nil) or (prev_state.expected_data ~= nil)
	-- Открыты ли скобки ( { [ на предыдущей строке и ещё не закрыты —
	-- многострочный конструктор таблицы, аргументы вызова и т.п. Внутри
	-- них проверки "с чего может начинаться statement" неприменимы.
	local incoming_bracket_depth = prev_state.bracket_depth or 0
	-- Заканчивалась ли предыдущая строка полноценным значением, после
	-- которого мог бы идти бинарный оператор (например "'a' .. 'b'" и
	-- перенос строки на "..'c'") — тогда ведущий оператор/символ на этой
	-- строке — не ошибка, а продолжение выражения.
	local incoming_allows_continuation = prev_state.ends_expression or false

	local first_real_tk = nil
	local last_real_tk = nil
	-- Встретили ли на строке "=" (присваивание) или вызов функции —
	-- то, что делает statement валидным в Lua.
	local seen_assign_or_call = false

	for i = 1, #tokens do
		local tk = tokens[i]

		if tk.type ~= 'whitespace' and tk.type ~= 'comment' then
			if not first_real_tk then first_real_tk = tk end
			last_real_tk = tk
			if tk.type == 'function' or (tk.type == 'operator' and tk.data == '=') then
				seen_assign_or_call = true
			end

			local errored_this_token = false

			-- 1. Проверка строгих ожиданий от предыдущего токена
			if state.expected_types or state.expected_data then
				local type_ok = state.expected_types and state.expected_types[tk.type]
				local data_ok = state.expected_data and state.expected_data[tk.data]

				if not (type_ok or data_ok) then
					table.insert(errors,
						{ posFirst = tk.posFirst, posLast = tk.posLast, msg = "Unexpected token", data = tk.data })
					errored_this_token = true
				end

				-- Строгое ожидание выполнено, сбрасываем его
				state.expected_types = nil
				state.expected_data = nil
			end

			-- 2. Проверка на недопустимое соседство (если нет строгих ожиданий)
			if state.forbidden_types or state.forbidden_data then
				local type_bad = state.forbidden_types and state.forbidden_types[tk.type]
				local data_bad = state.forbidden_data and state.forbidden_data[tk.data]

				if type_bad or data_bad then
					table.insert(errors,
						{
							posFirst = tk.posFirst,
							posLast = tk.posLast,
							msg = "Invalid syntax near token",
							data = tk
								.data
						})
					errored_this_token = true
				end
			end

			-- 3. Установка правил для следующего токена
			local exp = EXPECTS[tk.data] or EXPECTS[tk.type]
			if exp then
				state.expected_types = exp.type
				state.expected_data = exp.data
			end

			local fbd = FORBIDS[tk.data] or FORBIDS[tk.type]
			if fbd then
				state.forbidden_types = fbd.type
				state.forbidden_data = fbd.data
			else
				state.forbidden_types = nil
				state.forbidden_data = nil
			end

			-- "function" тоже открывает блок (тело функции), даже когда
			-- рядом нет "do"/"then" — иначе любой "end" функции без
			-- цикла/условия внутри выглядел бы как лишний/непарный.
			if tk.data == 'do' or tk.data == 'then' or tk.data == 'function' then
				state.block_depth = state.block_depth + 1
			end
			if tk.data == 'end' then
				state.block_depth = state.block_depth - 1
				if state.block_depth < 0 and not errored_this_token then
					table.insert(errors,
						{
							posFirst = tk.posFirst,
							posLast = tk.posLast,
							msg = "Unexpected 'end' (no matching block)",
							data =
								tk.data
						})
				end
				if state.block_depth < 0 then
					state.block_depth = 0 -- не размазываем ошибку на весь остальной код
				end
			end

			-- Токены-символы (и только они) могут содержать скобочные
			-- символы — в т.ч. СЛИПШИЕСЯ друг с другом из-за склейки
			-- одинаковых типов в token() (см. комментарий выше про "((").
			-- Поэтому смотрим на КАЖДЫЙ символ внутри data, а не на весь
			-- токен целиком.
			if tk.type == 'symbol' then
				for c = 1, #tk.data do
					local ch = tk.data:sub(c, c)
					if BRACKET_OPEN[ch] then
						state.bracket_depth = state.bracket_depth + 1
					elseif BRACKET_CLOSE[ch] then
						state.bracket_depth = math.max(0, state.bracket_depth - 1)
					end
				end
			end
		end
	end

	-- Запоминаем, чем закончилась строка — нужно следующей строке, чтобы
	-- понять, можно ли ей начинаться с оператора/символа-продолжения.
	local ends_expression = false
	if last_real_tk then
		if ENDS_EXPRESSION_TYPES[last_real_tk.type] then
			ends_expression = true
		elseif last_real_tk.type == 'symbol' then
			local lastChar = last_real_tk.data:sub(-1)
			if BRACKET_CLOSE[lastChar] then
				ends_expression = true
			end
		end
	end
	state.ends_expression = ends_expression

	-- Если строка начинается прямо ВНУТРИ скобок, открытых на предыдущей
	-- строке (многострочный конструктор таблицы, аргументы вызова,
	-- выражение в скобках) — это не начало нового statement'а, и все
	-- проверки "с чего может начинаться statement" здесь неприменимы.
	if first_real_tk and not had_incoming_expectation and incoming_bracket_depth == 0 then
		local t = first_real_tk.type
		local invalid_immediately = false

		if ALWAYS_INVALID_START_TYPES[t] then
			invalid_immediately = true
		elseif t == 'operator' then
			-- Оператор в начале строки МОЖЕТ быть валидным продолжением
			-- выражения с предыдущей строки (Lua не чувствителен к
			-- переносам строк): например конкатенация ".." или бинарный
			-- "+"/"-" в начале строки, когда предыдущая строка
			-- закончилась полноценным значением. Флагаем только если
			-- продолжать нечего.
			if not incoming_allows_continuation then
				invalid_immediately = true
			end
		elseif t == 'symbol' and first_real_tk.data:sub(1, 1) ~= '(' then
			if not incoming_allows_continuation then
				invalid_immediately = true
			end
		end

		if invalid_immediately then
			table.insert(errors,
				{
					posFirst = first_real_tk.posFirst,
					posLast = first_real_tk.posLast,
					msg =
					"Statement cannot start with this token",
					data = first_real_tk.data
				})
		elseif LONE_INVALID_TYPES[t] and not seen_assign_or_call then
			table.insert(errors,
				{
					posFirst = first_real_tk.posFirst,
					posLast = first_real_tk.posLast,
					msg = "Statement has no effect",
					data =
						first_real_tk.data
				})
		end
	end

	-- Очищаем локальные запреты при переносе на новую строку,
	-- но оставляем строгие ожидания (например, если строка закончилась знаком '=')
	state.forbidden_types = nil
	state.forbidden_data = nil

	return errors, state
end

return Analyzer

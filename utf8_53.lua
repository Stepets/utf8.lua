local function classMatchGenerator(class, plain)
	local codes = {}
	local ranges = {}
	local ignore = false
	local range = false
	local firstletter = true
	local unmatch = false

	local it = utf8gensub(class)

	local skip
	for c, _, be in it do
		skip = be
		if not ignore and not plain then
			if c == "%" then
				ignore = true
			elseif c == "-" then
				table.insert(codes, utf8unicode(c))
				range = true
			elseif c == "^" then
				if not firstletter then
					error('!!!')
				else
					unmatch = true
				end
			elseif c == ']' then
				break
			else
				if not range then
					table.insert(codes, utf8unicode(c))
				else
					table.remove(codes) -- removing '-'
					table.insert(ranges, {table.remove(codes), utf8unicode(c)})
					range = false
				end
			end
		elseif ignore and not plain then
			if c == 'a' then -- %a: represents all letters. (ONLY ASCII)
				table.insert(ranges, {65, 90}) -- A - Z
				table.insert(ranges, {97, 122}) -- a - z
			elseif c == 'c' then -- %c: represents all control characters.
				table.insert(ranges, {0, 31})
				table.insert(codes, 127)
			elseif c == 'd' then -- %d: represents all digits.
				table.insert(ranges, {48, 57}) -- 0 - 9
			elseif c == 'g' then -- %g: represents all printable characters except space.
				table.insert(ranges, {1, 8})
				table.insert(ranges, {14, 31})
				table.insert(ranges, {33, 132})
				table.insert(ranges, {134, 159})
				table.insert(ranges, {161, 5759})
				table.insert(ranges, {5761, 8191})
				table.insert(ranges, {8203, 8231})
				table.insert(ranges, {8234, 8238})
				table.insert(ranges, {8240, 8286})
				table.insert(ranges, {8288, 12287})
			elseif c == 'l' then -- %l: represents all lowercase letters. (ONLY ASCII)
				table.insert(ranges, {97, 122}) -- a - z
			elseif c == 'p' then -- %p: represents all punctuation characters. (ONLY ASCII)
				table.insert(ranges, {33, 47})
				table.insert(ranges, {58, 64})
				table.insert(ranges, {91, 96})
				table.insert(ranges, {123, 126})
			elseif c == 's' then -- %s: represents all space characters.
				table.insert(ranges, {9, 13})
				table.insert(codes, 32)
				table.insert(codes, 133)
				table.insert(codes, 160)
				table.insert(codes, 5760)
				table.insert(ranges, {8192, 8202})
				table.insert(codes, 8232)
				table.insert(codes, 8233)
				table.insert(codes, 8239)
				table.insert(codes, 8287)
				table.insert(codes, 12288)
			elseif c == 'u' then -- %u: represents all uppercase letters. (ONLY ASCII)
				table.insert(ranges, {65, 90}) -- A - Z
			elseif c == 'w' then -- %w: represents all alphanumeric characters. (ONLY ASCII)
				table.insert(ranges, {48, 57}) -- 0 - 9
				table.insert(ranges, {65, 90}) -- A - Z
				table.insert(ranges, {97, 122}) -- a - z
			elseif c == 'x' then -- %x: represents all hexadecimal digits.
				table.insert(ranges, {48, 57}) -- 0 - 9
				table.insert(ranges, {65, 70}) -- A - F
				table.insert(ranges, {97, 102}) -- a - f
			else
				if not range then
					table.insert(codes, utf8unicode(c))
				else
					table.remove(codes) -- removing '-'
					table.insert(ranges, {table.remove(codes), utf8unicode(c)})
					range = false
				end
			end
			ignore = false
		else
			if not range then
				table.insert(codes, utf8unicode(c))
			else
				table.remove(codes) -- removing '-'
				table.insert(ranges, {table.remove(codes), utf8unicode(c)})
				range = false
			end
			ignore = false
		end

		firstletter = false
	end

	table.sort(codes)

	local function inRanges(charCode)
		for _,r in ipairs(ranges) do
			if r[1] <= charCode and charCode <= r[2] then
				return true
			end
		end
		return false
	end
	if not unmatch then
		return function(charCode)
			return binsearch(codes, charCode) or inRanges(charCode)
		end, skip
	else
		return function(charCode)
			return charCode ~= -1 and not (binsearch(codes, charCode) or inRanges(charCode))
		end, skip
	end
end

local function symbol_len(byte)
    return (byte <= 0x7F and 1) or (byte <= 0xDF and 2) or (byte <= 0xEF and 3) or (byte <= 0xF7 and 4)
end

local function next(str, bs)
    return bs + symbol_len(string.byte(str, bs))
end

local function symbol_iterator(str, startpos)
    local max_len = #str
    return function(skip, bs)
        bs = bs or startpos or 1
        bs = bs + skip
        if bs > max_len then return nil end

        return next(str, bs), bs
    end
end

local function parseClass(regex, pos)
    local class = {}

    local skip = 0
    for nbs, bs in symbol_iterator(regex, pos), skip do
        skip = 0
        local c = string.sub(regex, bs, nbs-1)
        if c == "%" then
            local nnbs = next(regex, nbs)
            table.insert(class, c .. string.sub(regex, nbs, nnbs-1))
            skip = nnbs - nbs
        elseif c == "]" then
            return class, nbs - pos
        else
            table.insert(class, c)
        end
    end

    error("missing ] for ", string.sub(regex, pos))
end

local function matcherGenerator(regex, plain)

    local function copy(captbl)
        local cap = {
            s = {},
            e = {},
        }
        for i = 1, #captbl.s do cap.s[i] = captbl.s[i] end
        for i = 1, #captbl.e do cap.e[i] = captbl.e[i] end
        return cap
    end

    local ctx_decl = [[
local ctx = {
    capture = copy(ctx.capture),
    s = pos,
    e = nil,
}]]

    local function simple(class, prev)
        return [[
if not test(]] .. table.unpack(class) .. [[) then return else pos = next(str, pos) end
]] .. prev
    end

    local function star(class, prev)
        return [[
return merge(ctx, (function(str, pos)
    ]] .. ctx_decl .. [[
    while test(]] .. unpack(class) [[) do pos = next(str,pos) end
    repeat
        local result = (function(str, pos)
            ]] .. ctx_decl .. [[
            ]] .. prev .. [[
            return ctx
        end)(str, pos)
        pos = prev(str, pos)
    until result and pos >= ctx.s
    return merge(ctx, result)
end)(str, pos))
)]]
    end

    local function minus(class, prev)
        return [[
return merge(ctx, (function(str, pos)
    ]] .. ctx_decl .. [[
    repeat
        local result = (function(str, pos)
            ]] .. ctx_decl .. [[
            ]] .. prev .. [[
            return ctx
        end)(str, pos)
        ]] .. simple(class, "") [[
    until result and pos < utf8len(str)
    return merge(ctx, result)
end)(str, pos))
)]]
    end

    local function question(class, prev)
        return [[
return merge(ctx, (function(str, pos)
    ]] .. ctx_decl .. [[
    if test(]] .. unpack(class) [[) then pos = next(str,pos) end
    repeat
        local result = (function(str, pos)
            ]] .. ctx_decl .. [[
            ]] .. prev .. [[
            return ctx
        end)(str, pos)
        pos = prev(str, pos)
    until result and pos >= ctx.s
    return merge(ctx, result)
end)(str, pos))
)]]
    end

	local function capture(id, prev)
		return [[
for i = ctx.capture.s[]] .. id .. [[], ctx.capture.e[]] .. id .. [[] do
    if str[i] == str[pos] then
        pos = pos + 1
    else
        return
    end
end
]] .. prev
	end
    local function captureStart(prev)
        return [[
table.insert(ctx.capture.s, pos)
]] .. prev
    end
    local function captureStop(prev)
        return [[
table.insert(ctx.capture.e, pos)
]] .. prev
    end

    local function balancer(d, b, prev)
        return [[
if not test(]] .. d .. [[) then
    return
else
    pos = next(str, pos)
    local sum = 1
    while sum ~= 0 and pos < utf8len(str) do
        if test(]] .. d .. [[) then sum = sum + 1 end
        if test(]] .. b .. [[) then sum = sum - 1 end
        pos = next(str, pos)
    end
    if sum ~= 0 and pos >= utf8len(str) then
        return
    end
end
]] .. prev
    end

    local function regular(prev)
        return [[
function (str, pos)
    local result = {}
    while pos < #str and not result.e do
        result = (function(str, pos)
            local ctx = {
                capture = {
                    s = {},
                    e = {},
                },
                s = pos,
                e = nil,
            }
]] .. prev .. [[
        )(str, pos)
        pos = next(str, pos)
    end
    return result
end
]]
    end

    local function fromstart(prev)
        return [[
function (str, pos)
    local result = {}
    result = (function(str, pos)
        local ctx = {
            capture = {
                s = {},
                e = {},
            },
            s = pos,
            e = nil,
        }
]] .. prev .. [[
    )(str, pos)
    return result
end
]]
    end

    local matcher = {
        functions = {},
        captures = {},
        wrapper = regular
    }

    local class = {}
    local ignore = false
    local skip = 0
    for nbs, bs in symbol_iterator(regex), skip do
        skip = 0
        local c = string.sub(regex, bs, nbs-1)
        if ignore then
            if find('123456789', c, 1, true) then
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    class = {}
                end
                table.insert(matcher.functions, {capture, tonumber(c)})
            elseif c == 'b' then
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    class = {}
                end
                local d, b = nbs, next(regex, nbs)
                skip = next(regex, b)
                d = sub(regex, d, b-1)
                b = sub(regex, b, skip-1)
                skip = skip - nbs
                table.insert(matcher.functions, {balancer, d, b})
            else
                class = { '%' .. c }
            end
            ignore = false
        else
            if c == '*' then
                if #class > 0 then
                    table.insert(matcher.functions, {star, class})
                    class = {}
                else
                    error('invalid regex after ' .. sub(regex, 1, bs))
                end
            elseif c == '+' then
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    table.insert(matcher.functions, {star, class})
                    class = {}
                else
                    error('invalid regex after ' .. sub(regex, 1, bs))
                end
            elseif c == '-' then
                if #class > 0 then
                    table.insert(matcher.functions, {minus, class})
                    class = {}
                else
                    error('invalid regex after ' .. sub(regex, 1, bs))
                end
            elseif c == '?' then
                if #class > 0 then
                    table.insert(matcher.functions, {question, class})
                    class = {}
                else
                    error('invalid regex after ' .. sub(regex, 1, bs))
                end
            elseif c == '^' then
                if bs == 1 then
                    matcher.wrapper = fromstart
                else
                    error('invalid regex after ' .. sub(regex, 1, bs))
                end
            elseif c == '$' then
                if nbs == len(regex) then
                    table.insert(matcher.functions, {toend})
                else
                    error('invalid regex after ' .. sub(regex, 1, bs))
                end
            elseif c == '[' then
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    class = {}
                end
                class, skip = parseClass(regex, nbs)
            elseif c == '(' then
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    class = {}
                end
                table.insert(matcher.functions, {captureStart})
            elseif c == ')' then
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    class = {}
                end
                table.insert(matcher.functions, {captureEnd})
                -- todo: check captureStart/End balance
--                 if not cap then
--                     error('invalid capture: "(" missing')
--                 end
            elseif c == '%' then
                ignore = true
            else
                if #class > 0 then
                    table.insert(matcher.functions, {simple, class})
                    class = {}
                end
                class = { c }
            end
        end
    end
    -- todo: check captureStart/End balance
--     if #cs > 0 then
--         error('invalid capture: ")" missing')
--     end
    if #class > 0 then
        table.insert(matcher.functions, {simple, class})
        class = {}
    end



    return matcher
end

local function merge(ctx1, ctx2)
    if not ctx2 then return ctx1 end

    for i = 1, #ctx2.capture.s do
        table.insert(ctx1.capture.s, ctx2.capture.s[i])
    end
    for i = 1, #ctx2.capture.e do
        table.insert(ctx1.capture.e, ctx2.capture.e[i])
    end
    ctx1.e = ctx2.e
    return ctx1
end

function dump (tab, val)
	if type(val) == 'table' then
		for k,v in pairs(val) do
			print(tab, k)
			dump(tab .. '\t', v)
		end
	else
		print(tab, val)
	end
end

local matchers = {
	simple = function(class, name)
		return [[
			local class = ]] .. class:dump() .. [[
			function matcher]] .. name .. [[(ctx)
				local saved = ctx.clone()
				if class:test(ctx) then
					ctx:next_char()
					ctx:next_function()(ctx)
				end
				ctx = saved
				ctx:terminate()
			end
		]]
	end,
	star = function(class, name)
		return [[
			local class = ]] .. class:dump() .. [[
			function matcher]] .. name .. [[(ctx)
				local saved = ctx.clone()
				local function match_one()
					if class:test(ctx) then
						ctx:next_char()
						match_one()
					end
					ctx:next_function()(ctx)
				end
				match_one()
				ctx = saved
			end
		]]
	end,
	minus = function(class, name)
		return [[
			local class = ]] .. class:dump() .. [[
			function matcher]] .. name .. [[(ctx)
				local saved = ctx.clone()
				repeat
					ctx:next_char()
					ctx:next_function()(ctx)
				until class:test(ctx)
				ctx = saved
			end
		]]
	end,
	question = function(class, name)
		return [[
			local class = ]] .. class:dump() .. [[
			function matcher]] .. name .. [[(ctx)
				local saved = ctx.clone()
				if class:test(ctx) then
					ctx:next_char()
					ctx:next_function()(ctx)
				end
				ctx = saved.clone()
				ctx:next_function()(ctx)
				ctx = saved
			end
		]]
	end,
	--capture = simple(captureclass),
	capture = function(class, name) -- start|stop class
		return [[
			local class = ]] .. class:dump() .. [[
			function matcher]] .. name .. [[(ctx)
				local saved = ctx.clone()
				class:test(ctx)
				ctx:next_function()(ctx)
				ctx = saved
			end
		]]
	end,
	balancer = function(class, name)
		return [[
			local class = ]] .. class:dump() .. [[
			function matcher]] .. name .. [[(ctx)
				local saved = ctx.clone()
				while class:test(ctx) do
					ctx:next_char()
				end
				ctx:next_function()(ctx)
				ctx = saved
			end
		]]
	end,
}

local matcher = matcherGenerator('aaa', false)
dump('', matcher)

local prev = matcher.wrapper("")
for k,v in pairs(matcher.functions) do
	print(prev)
	prev = v[1](v[2], prev)
end
print("final")
print(prev)

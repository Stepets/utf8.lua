local utf8 = require ".utf8"
local utf8sub = utf8.sub
local utf8gensub = utf8.gensub
local get_matcher_function, get_matcher_source = (require 'matcher').get_matcher_function, (require 'matcher').get_matcher_source

debug = print or function() end

-- string.find
local function utf8find(str, regex, init, plain)
  local func = get_matcher_function(regex, plain)
  init = ((init or 1) < 0) and (utf8.len(str) + init + 1) or init
  local ctx, result, captures = func(str, init)
  if not ctx then return nil end

  dump('ctx:', ctx)
  dump('result:', result)
  dump('captures:', captures)

  return result.start, result.finish, table.unpack(captures)
end

-- string.match
local function utf8match(str, regex, init)
  local func = get_matcher_function(regex, plain)
  local ctx, result, captures = func(str, init)
  if not ctx then return nil end

  dump('ctx:', ctx)
  dump('result:', result)
  dump('captures:', captures)

  if #captures > 0 then return table.unpack(captures) end

  return utf8sub(str, result.start, result.finish)
end

-- string.gmatch
local function utf8gmatch(str, regex)
	regex = (utf8sub(regex,1,1) ~= '^') and regex or '%' .. regex
  local func = get_matcher_function(regex, plain)
  local ctx, result, captures
  local continue_pos = 1

	return function()
    ctx, result, captures = func(str, continue_pos)

    if not ctx then return nil end

    dump('ctx:', ctx)
    dump('result:', result)
    dump('captures:', captures)

    continue_pos = math.max(result.finish + 1, result.start + 1)
    if #captures > 0 then
      return table.unpack(captures)
    else
      return utf8sub(str, result.start, result.finish)
    end
	end
end

local function replace(repl, args)
	local ret = ''
	if type(repl) == 'string' then
		local ignore = false
		local num
		for c in utf8gensub(repl) do
			if not ignore then
				if c == '%' then
					ignore = true
				else
					ret = ret .. c
				end
			else
				num = tonumber(c)
				if num then
					ret = ret .. args[num]
				else
					ret = ret .. c
				end
				ignore = false
			end
		end
	elseif type(repl) == 'table' then
		ret = repl[args[1] or args[0]] or ''
	elseif type(repl) == 'function' then
		if #args > 0 then
			ret = repl(unpack(args, 1)) or ''
		else
			ret = repl(args[0]) or ''
		end
	end
	return ret
end
-- string.gsub
local function utf8gsub(str, regex, repl, limit)
	limit = limit or -1
	local subbed = ''
	local prev_sub_finish = 1

  regex = (utf8sub(regex,1,1) ~= '^') and regex or '%' .. regex
  local func = get_matcher_function(regex, plain)
  local ctx, result, captures
  local continue_pos = 1

  local n = 0
	while limit ~= n do
    ctx, result, captures = func(str, continue_pos)
    if not ctx then break end

    dump('ctx:', ctx)
    dump('result:', result)
    debug('result:', utf8sub(str, result.start, result.finish))
    dump('captures:', captures)

    continue_pos = math.max(result.finish + 1, result.start + 1)
    local args = {[0] = utf8sub(str, result.start, result.finish), table.unpack(captures)}

    subbed = subbed .. utf8sub(str, prev_sub_finish, result.start - 1)
    subbed = subbed .. replace(repl, args)
    prev_sub_finish = result.finish + 1
    n = n + 1

  end

	return subbed .. utf8sub(str, prev_sub_finish), n
end

local res = {}
res.len = utf8.len
res.sub = utf8.sub
res.reverse = utf8.reverse
res.char = utf8.char
res.unicode = utf8.unicode
res.gensub = utf8.gensub
res.byte = utf8.unicode
res.find    = utf8find
res.match   = utf8match
res.gmatch  = utf8gmatch
res.gsub    = utf8gsub
res.dump    = string.dump
res.format = string.format
res.lower = string.lower
res.upper = string.upper
res.rep     = string.rep
res.raw = {}
for k,v in pairs(string) do
  res.raw[k] = v
end
return res

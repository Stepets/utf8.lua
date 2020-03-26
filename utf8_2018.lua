local utf8 = require "utf8primitives"
local utf8sub = utf8.sub
local utf8gensub = utf8.gensub
local get_matcher_function = require 'regex_parser'--(require 'matcher').get_matcher_function

debug = print or function() end

function dump(tab, val)
  tab = tab or ''

  if type(val) == 'table' then
    for k,v in pairs(val) do
      print(tab .. tostring(k))
      dump(tab .. '\t', v)
    end
  else
    print(tab .. tostring(val))
  end
end


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
		for _, c in utf8gensub(repl) do
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

-- attaching high-level functions
utf8.find    = utf8find
utf8.match   = utf8match
utf8.gmatch  = utf8gmatch
utf8.gsub    = utf8gsub

return utf8

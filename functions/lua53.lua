return function(utf8)

local utf8sub = utf8.sub
local utf8gensub = utf8.gensub
local unpack = utf8.config.unpack
local generate_matcher_function = utf8:require 'regex_parser'

function get_matcher_function(regex, plain)
  local res
  if utf8.config.cache then
    res = utf8.config.cache[plain and "plain" or "regex"][regex]
  end
  if res then
    return res
  end
  res = generate_matcher_function(regex, plain)
  if utf8.config.cache then
    utf8.config.cache[plain and "plain" or "regex"][regex] = res
  end
  return res
end

local function utf8find(str, regex, init, plain)
  local func = get_matcher_function(regex, plain)
  init = ((init or 1) < 0) and (utf8.len(str) + init + 1) or init
  local ctx, result, captures = func(str, init, utf8)
  if not ctx then return nil end

  utf8.debug('ctx:', ctx)
  utf8.debug('result:', result)
  utf8.debug('captures:', captures)

  return result.start, result.finish, unpack(captures)
end

local function utf8match(str, regex, init)
  local func = get_matcher_function(regex, false)
  init = ((init or 1) < 0) and (utf8.len(str) + init + 1) or init
  local ctx, result, captures = func(str, init, utf8)
  if not ctx then return nil end

  utf8.debug('ctx:', ctx)
  utf8.debug('result:', result)
  utf8.debug('captures:', captures)

  if #captures > 0 then return unpack(captures) end

  return utf8sub(str, result.start, result.finish)
end

local function utf8gmatch(str, regex)
  regex = (utf8sub(regex,1,1) ~= '^') and regex or '%' .. regex
  local func = get_matcher_function(regex, false)
  local ctx, result, captures
  local continue_pos = 1

  return function()
    ctx, result, captures = func(str, continue_pos, utf8)

    if not ctx then return nil end

    utf8.debug('ctx:', ctx)
    utf8.debug('result:', result)
    utf8.debug('captures:', captures)

    continue_pos = math.max(result.finish + 1, result.start + 1)
    if #captures > 0 then
      return unpack(captures)
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
          ret = ret .. assert(args[num], "invalid capture index %" .. c)
        else
          ret = ret .. c
        end
        ignore = false
      end
    end
  elseif type(repl) == 'table' then
    ret = repl[args[1]] or args[0]
  elseif type(repl) == 'function' then
    ret = repl(unpack(args, 1)) or args[0]
  end
  return ret
end

local function utf8gsub(str, regex, repl, limit)
  limit = limit or -1
  local subbed = ''
  local prev_sub_finish = 1

  local func = get_matcher_function(regex, false)
  local ctx, result, captures
  local continue_pos = 1

  local n = 0
  while limit ~= n do
    ctx, result, captures = func(str, continue_pos, utf8)
    if not ctx then break end

    utf8.debug('ctx:', ctx)
    utf8.debug('result:', result)
    utf8.debug('result:', utf8sub(str, result.start, result.finish))
    utf8.debug('captures:', captures)

    continue_pos = math.max(result.finish + 1, result.start + 1)
    local args
    if #captures > 0 then
      args = {[0] = utf8sub(str, result.start, result.finish), unpack(captures)}
    else
      args = {[0] = utf8sub(str, result.start, result.finish)}
      args[1] = args[0]
    end

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

end

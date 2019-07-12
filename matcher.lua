local utf8 = require ".utf8"
local cl = require "class"
local utf8unicode = utf8.byte
local utf8sub = utf8.sub
local utf8gensub = utf8.gensub
local sub = string.sub
local find = string.find
local len = string.len
local byte = string.byte

debug = print or function() end

local matchers = {
  simple = function(class, name)
    local class_name = 'class' .. name
    return [[
    local ]] .. class_name .. [[ = ]] .. class .. [[

    add(function(ctx) -- simple
        debug(ctx, 'simple', ']] .. class_name .. [[')
        if ]] .. class_name .. [[:test(ctx:get_charcode()) then
            ctx:next_char()
            ctx:next_function()
            return ctx:get_function()(ctx)
        end
    end)
]]
  end,
  star = function(class, name)
    local class_name = 'class' .. name
    return [[
  local ]] .. class_name .. [[ = ]] .. class .. [[

  add(function(ctx) -- star
      debug(ctx, 'star', ']] .. class_name .. [[')
      local saved = {ctx:clone()}
      while ]] .. class_name .. [[:test(ctx:get_charcode()) do
        ctx:next_char()
        table.insert(saved, ctx:clone())
        debug('#saved', #saved)
      end
      while #saved > 0 do
          ctx = table.remove(saved)
          ctx:next_function()
          ctx:get_function()(ctx)
          debug('#saved', #saved)
      end
  end)
]]
  end,
  minus = function(class, name)
    local class_name = 'class' .. name
    return [[
    local ]] .. class_name .. [[ = ]] .. class .. [[

    add(function(ctx) -- minus
        debug(ctx, 'minus', ']] .. class_name .. [[')

        repeat
          local saved = ctx:clone()
          ctx:next_function()
          ctx:get_function()(ctx)
          ctx = saved
          local match = ]] .. class_name .. [[:test(ctx:get_charcode())
          ctx:next_char()
        until not match
    end)
]]
  end,
  question = function(class, name)
    local class_name = 'class' .. name
    return [[
    local ]] .. class_name .. [[ = ]] .. class .. [[

    add(function(ctx) -- question
        debug(ctx, 'question', ']] .. class_name .. [[')
        local saved = ctx:clone()
        if ]] .. class_name .. [[:test(ctx:get_charcode()) then
            ctx:next_char()
            ctx:next_function()
            ctx:get_function()(ctx)
        end
        ctx = saved
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
]]
  end,
  capture_start = function(number)
    return [[
    add(function(ctx)
        debug(ctx, 'capture_start', ']] .. tostring(number) .. [[')
        table.insert(ctx.captures.active, { id = ]] .. tostring(number) .. [[, start_byte = byte_pos, start = ctx.pos })
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
]]
  end,
  capture_finish = function(number)
    return [[
    add(function(ctx)
        debug(ctx, 'capture_finish', ']] .. tostring(number) .. [[')
        dump('ctx:', ctx)
        local cap = table.remove(ctx.captures.active)
        cap.finish_byte = byte_pos
        cap.finish = ctx.pos
        ctx.captures[cap.id] = utf8sub(ctx.str, cap.start, cap.finish - 1)
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
]]
  end,
  capture = function(number)
    return [[
    add(function(ctx)
        debug(ctx, 'capture', ']] .. tostring(number) .. [[')
        -- dump('ctx:', ctx)
        local cap = ctx.captures[ ]] .. tostring(number) .. [[ ]
        local len = utf8len(cap)
  			local check = utf8sub(ctx.str, ctx.pos, ctx.pos + len - 1)
        debug("capture check:", cap, check)
  			if cap == check then
  				ctx.pos = ctx.pos + len
  				ctx:next_function()
          return ctx:get_function()(ctx)
  			end
    end)
]]
  end,
  balancer = function(pair, name)
    local class_name = 'class' .. name
    return [[

    add(function(ctx) -- balancer
        local d, b = ]] .. tostring(utf8unicode(pair[1])) .. [[, ]] .. tostring(utf8unicode(pair[2])) .. [[
        if ctx:get_charcode() ~= d then return end
        local balance = 0
        repeat
          local c = ctx:get_charcode()
          if c == nil then return end

          if c == d then
            balance = balance + 1
          elseif c == b then
            balance = balance - 1
          end
          debug("balancer: balance=", balance, ", d=", d, ", b=", b, ", charcode=", ctx:get_charcode())
          ctx:next_char()
        until balance == 0
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
]]
  end,
  frontier = function(class, name)
    local class_name = 'class' .. name
    return [[
    local ]] .. class_name .. [[ = ]] .. class .. [[

    add(function(ctx) -- frontier
        ctx.pos = ctx.pos - 1
        local prev_charcode = ctx:get_charcode()
        ctx:next_char()
        debug("frontier pos", ctx.pos, "prev_charcode", prev_charcode, "charcode", ctx:get_charcode())
        if ]] .. class_name .. [[:test(prev_charcode) then return end
        if ]] .. class_name .. [[:test(ctx:get_charcode()) then
          ctx:next_function()
          return ctx:get_function()(ctx)
        end
    end)
]]
  end,
}

local begins = {
  sliding = function()
    return [[
    add(function(ctx) -- sliding
        local saved = ctx:clone()
        local start_pos = ctx.pos
        while ctx.pos <= 1 + utf8len(ctx.str) do
            debug('starting from', ctx, "start_pos", start_pos)
            ctx.result.start = ctx.pos
            ctx:next_function()
            ctx:get_function()(ctx)

            ctx = saved:clone()
            start_pos = start_pos + 1
            ctx.pos = start_pos
        end
        ctx:terminate()
    end)
]]
  end,
  fromstart = function(ctx)
    return [[
    add(function(ctx) -- fromstart
        local saved = ctx:clone()
        ctx.result.start = ctx.pos
        ctx:next_function()
        ctx:get_function()(ctx)
        ctx:terminate()
    end)
]]
  end,
}

local ends = {
  any = function()
    return [[
    add(function(ctx) -- any
        ctx.result.finish = ctx.pos - 1
        ctx:done()
    end)
]]
  end,
  toend = function(ctx)
    return [[
    add(function(ctx) -- toend
        ctx.result.finish = ctx.pos - 1
        if ctx.pos == #ctx.str then ctx:done() else ctx:terminate() end
    end)
]]
  end,
}

local function symbol_len(byte)
  return (byte <= 0x7F and 1) or (byte <= 0xDF and 2) or (byte <= 0xEF and 3) or (byte <= 0xF7 and 4)
end

local function next(str, bs)
  return bs + symbol_len(byte(str, bs))
end

local function symbol_iterator(str)
  local max_len = #str
  return function(skip_ptr, bs)
    bs = bs + skip_ptr[1]
    if bs > max_len then return nil end

    return next(str, bs), bs
  end
end

local function matcherGenerator(regex, plain)

  local matcher = {
    functions = {},
    starts = begins.sliding,
    ends = ends.any
  }

  if plain then
    local skip = {0}
    for nbs, bs in symbol_iterator(regex), skip, 1 do
      local c = string.sub(regex, bs, nbs-1)
      table.insert(matcher.functions, matchers.simple(cl.parse(c, plain), tostring(bs)))
    end

    return matcher
  end

  local capture_balance, capture_id = 0, 0
  local class = nil
  local ignore = false
  local skip = {0}
  for nbs, bs in symbol_iterator(regex), skip, 1 do
    skip[1] = 0
    local c = sub(regex, bs, nbs-1)
    debug('matcher:matcherGenerator', bs, nbs, c, skip)
    if ignore then
      if find('123456789', c, 1, true) then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        table.insert(matcher.functions, matchers.capture(tonumber(c)))
      elseif c == 'b' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        local d, b = nbs, next(regex, nbs)
        skip[1] = next(regex, b)
        d = sub(regex, d, b-1)
        b = sub(regex, b, skip[1]-1)
        skip[1] = skip[1] - nbs
        table.insert(matcher.functions, matchers.balancer({d, b}, tostring(bs)))
      elseif c == 'f' then
        assert(sub(regex, nbs, nbs) == '[', "missing '[' after '%f' in pattern")
        class, skip[1] = cl.parse(sub(regex, next(regex, nbs)))
        skip[1] = skip[1] + 1 -- for skipping '['
        table.insert(matcher.functions, matchers.frontier(class, tostring(bs)))
        class = nil
      else
        class = cl.parse('%' .. c)
        debug('matcher:matcherGenerator', 'ignoring skip')
      end
      ignore = false
    else
      if c == '*' then
        if class then
          table.insert(matcher.functions, matchers.star(class, tostring(bs)))
          class = nil
        else
          error('invalid regex after ' .. sub(regex, 1, bs))
        end
      elseif c == '+' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          table.insert(matcher.functions, matchers.star(class, tostring(bs)))
          class = nil
        else
          error('invalid regex after ' .. sub(regex, 1, bs))
        end
      elseif c == '-' then
        if class then
          table.insert(matcher.functions, matchers.minus(class, tostring(bs)))
          class = nil
        else
          error('invalid regex after ' .. sub(regex, 1, bs))
        end
      elseif c == '?' then
        if class then
          table.insert(matcher.functions, matchers.question(class, tostring(bs)))
          class = nil
        else
          error('invalid regex after ' .. sub(regex, 1, bs))
        end
      elseif c == '^' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        if bs == 1 then
          matcher.starts = begins.fromstart
        else
          class = 'cl.new():with_codes(' .. tostring(utf8unicode(c)) .. ')'
        end
      elseif c == '$' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        if nbs == len(regex) then
          matcher.ends = ends.toend
        else
          class = 'cl.new():with_codes(' .. tostring(utf8unicode(c)) .. ')'
        end
      elseif c == '[' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        class, skip[1] = cl.parse(sub(regex, nbs))
      elseif c == '(' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        capture_balance = capture_balance + 1
        capture_id = capture_id + 1
        table.insert(matcher.functions, matchers.capture_start(capture_id))
      elseif c == ')' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        table.insert(matcher.functions, matchers.capture_finish(-capture_balance))
        capture_balance = capture_balance - 1
        if capture_balance < 0 then
          error('invalid capture: "(" missing')
        end
      elseif c == '.' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        class = 'cl.new():invert()'
      elseif c == '%' then
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        ignore = true
      else
        if class then
          table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
          class = nil
        end
        class = 'cl.new():with_codes(' .. tostring(utf8unicode(c)) .. ')'
      end
    end
  end

  if capture_balance > 0 then
    error('invalid capture: ")" missing')
  end

  if class then
    table.insert(matcher.functions, matchers.simple(class, tostring(bs)))
    class = nil
  end

  return matcher
end

function dump (tab, val)
  if type(val) == 'table' then
    for k,v in pairs(val) do
      debug(tab, k)
      dump(tab .. '\t', v)
    end
  else
    debug(tab, val)
  end
end

local cache = setmetatable({},{
  __mode = 'kv'
})
local cachePlain = setmetatable({},{
  __mode = 'kv'
})

local function get_matcher_source(regex, plain)
  local matcher = matcherGenerator(regex, plain)

  local src = [[
  return function(str, init)
      local ctx = require("context").new({str = str, pos = init or 1})
      local cl = require("class")
      local utf8sub = require(".utf8").sub
      local utf8len = require(".utf8").len
      local function add(fun)
          ctx.functions[#ctx.functions + 1] = fun
      end
  ]] .. matcher.starts()
  for _, v in ipairs(matcher.functions) do src = src .. v end
  src = src .. matcher.ends() .. [[
      return coroutine.wrap(ctx:get_function())(ctx)
  end
  ]]

  return src
end

local function get_matcher_function(regex, plain)
  assert(regex, "bad argument 'regex' (string expected, got nil)")

  if plain and cachePlain[regex] then
    return cachePlain[regex]
  elseif not plain and cache[regex] then
    return cache[regex]
  end

  local src = get_matcher_source(regex, plain)
  local src_file = assert(io.open('matcher_src.lua', 'w'))
  src_file:write(src)
  src_file:close()

  -- local func = require 'matcher_src'
  local func = assert((loadstring or load)(src, (plain and "plain " or "") .. regex))()
  if plain then
    cachePlain[regex] = func
  else
    cache[regex] = func
  end

  return func
end

return {
  get_matcher_function = get_matcher_function,
  get_matcher_source = get_matcher_source,
}

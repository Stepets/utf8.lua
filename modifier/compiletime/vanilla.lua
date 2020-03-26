local base = require "utf8primitives"
local utf8unicode = base.byte
local sub = base.raw.sub

local matchers = {
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
  simple = require("modifier.compiletime.simple").simple,
}

local function next(str, bs)
  local nbs1 = base.next(str, bs)
  local nbs2 = base.next(str, nbs1)
  return sub(str, nbs1, nbs2 - 1), nbs1
end

local function parse(regex, c, bs, ctx)
  local functions, nbs = nil, bs
  if c == '%' then
    c, nbs = next(regex, bs)
    print("next", c, bs)
    if base.raw.find('123456789', c, 1, true) then
      functions = { matchers.capture(tonumber(c)) }
      nbs = base.next(regex, nbs)
    elseif c == 'b' then
      local d, b
      d, nbs = next(regex, nbs)
      b, nbs = next(regex, nbs)
      functions = { matchers.balancer({d, b}, tostring(bs)) }
      nbs = base.next(regex, nbs)
    end

    if functions and ctx.prev_class then
      table.insert(functions, 1, matchers.simple(ctx.prev_class, tostring(bs)))
    end
  elseif c == '*' and ctx.prev_class then
    functions = {
      matchers.star(
        ctx.prev_class,
        tostring(bs)
      )
    }
    nbs = bs + 1
  elseif c == '+' and ctx.prev_class then
    functions = {
      matchers.simple(
        ctx.prev_class,
        tostring(bs)
      ),
      matchers.star(
        ctx.prev_class,
        tostring(bs)
      )
    }
    nbs = bs + 1
  elseif c == '-' and ctx.prev_class then
    functions = {
      matchers.minus(
        ctx.prev_class,
        tostring(bs)
      )
    }
    nbs = bs + 1
  elseif c == '?' and ctx.prev_class then
    functions = {
      matchers.question(
        ctx.prev_class,
        tostring(bs)
      )
    }
    nbs = bs + 1
  elseif c == '(' then
    ctx.capture = ctx.capture or {balance = 0, id = 0}
    ctx.capture.balance = ctx.capture.balance + 1
    ctx.capture.id = ctx.capture.id + 1
    functions = { matchers.capture_start(ctx.capture.id) }
    if ctx.prev_class then
      table.insert(functions, 1, matchers.simple(ctx.prev_class, tostring(bs)))
    end
    nbs = bs + 1
  elseif c == ')' then
    ctx.capture = ctx.capture or {balance = 0, id = 0}
    functions = { matchers.capture_finish(ctx.capture.id) }

    ctx.capture.balance = ctx.capture.balance - 1
    assert(ctx.capture.balance >= 0, 'invalid capture: "(" missing')

    if ctx.prev_class then
      table.insert(functions, 1, matchers.simple(ctx.prev_class, tostring(bs)))
    end
    nbs = bs + 1
  end

  return functions, nbs - bs
end

local function check(ctx)
  if ctx.capture then assert(ctx.capture.balance == 0, 'invalid capture: ")" missing') end
end

return {
  parse = parse,
  check = check,
}

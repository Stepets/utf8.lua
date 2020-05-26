return function(utf8)

local utf8unicode = utf8.byte
local sub = utf8.raw.sub

local matchers = {
  star = function(class, name)
    local class_name = 'class' .. name
    return [[
  local ]] .. class_name .. [[ = ]] .. class .. [[

  add(function(ctx) -- star
    -- debug(ctx, 'star', ']] .. class_name .. [[')
    local clone = ctx:clone()
    while ]] .. class_name .. [[:test(clone:get_charcode()) do
      clone:next_char()
    end
    local pos = clone.pos
    while pos >= ctx.pos do
      clone.pos = pos
      clone.func_pos = ctx.func_pos
      clone:next_function()
      clone:get_function()(clone)
      if clone.modified then
        clone = ctx:clone()
      end
      pos = pos - 1
    end
  end)
]]
  end,
  minus = function(class, name)
    local class_name = 'class' .. name
    return [[
  local ]] .. class_name .. [[ = ]] .. class .. [[

  add(function(ctx) -- minus
    -- debug(ctx, 'minus', ']] .. class_name .. [[')

    local clone = ctx:clone()
    local pos
    repeat
      pos = clone.pos
      clone:next_function()
      clone:get_function()(clone)
      if clone.modified then
        clone = ctx:clone()
        clone.pos = pos
      else
        clone.pos = pos
        clone.func_pos = ctx.func_pos
      end
      local match = ]] .. class_name .. [[:test(clone:get_charcode())
      clone:next_char()
    until not match
  end)
]]
  end,
  question = function(class, name)
    local class_name = 'class' .. name
    return [[
  local ]] .. class_name .. [[ = ]] .. class .. [[

  add(function(ctx) -- question
    -- debug(ctx, 'question', ']] .. class_name .. [[')
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
    ctx.modified = true
    -- debug(ctx, 'capture_start', ']] .. tostring(number) .. [[')
    table.insert(ctx.captures.active, { id = ]] .. tostring(number) .. [[, start = ctx.pos })
    ctx:next_function()
    return ctx:get_function()(ctx)
  end)
]]
  end,
  capture_finish = function(number)
    return [[
  add(function(ctx)
    ctx.modified = true
    -- debug(ctx, 'capture_finish', ']] .. tostring(number) .. [[')
    local cap = table.remove(ctx.captures.active)
    cap.finish = ctx.pos
    local b, e = ctx.offsets[cap.start], ctx.offsets[cap.finish]
    if cap.start < 1 then
      b = 1
    elseif cap.start >= ctx.len then
      b = ctx.rawlen + 1
    end
    if cap.finish < 1 then
      e = 1
    elseif cap.finish >= ctx.len then
      e = ctx.rawlen + 1
    end
    ctx.captures[cap.id] = rawsub(ctx.str, b, e - 1)
    -- debug('capture#' .. tostring(cap.id), '[' .. tostring(cap.start).. ',' .. tostring(cap.finish) .. ']' , 'is', ctx.captures[cap.id])
    ctx:next_function()
    return ctx:get_function()(ctx)
  end)
]]
  end,
  capture_position = function(number)
    return [[
  add(function(ctx)
    ctx.modified = true
    -- debug(ctx, 'capture_position', ']] .. tostring(number) .. [[')
    ctx.captures[ ]] .. tostring(number) .. [[ ] = ctx.pos
    ctx:next_function()
    return ctx:get_function()(ctx)
  end)
]]
  end,
  capture = function(number)
    return [[
  add(function(ctx)
    -- debug(ctx, 'capture', ']] .. tostring(number) .. [[')
    local cap = ctx.captures[ ]] .. tostring(number) .. [[ ]
    local len = utf8len(cap)
		local check = utf8sub(ctx.str, ctx.pos, ctx.pos + len - 1)
    -- debug("capture check:", cap, check)
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
      -- debug("balancer: balance=", balance, ", d=", d, ", b=", b, ", charcode=", ctx:get_charcode())
      ctx:next_char()
    until balance == 0 or (balance == 2 and d == b)
    ctx:next_function()
    return ctx:get_function()(ctx)
  end)
]]
  end,
  simple = utf8:require("modifier.compiletime.simple").simple,
}

local next = utf8.util.next

local function parse(regex, c, bs, ctx)
  local functions, nbs = nil, bs
  if c == '%' then
    c, nbs = next(regex, bs)
    utf8.debug("next", c, bs)
    if c == '' then
      error("malformed pattern (ends with '%')")
    end
    if utf8.raw.find('123456789', c, 1, true) then
      functions = { matchers.capture(tonumber(c)) }
      nbs = utf8.next(regex, nbs)
    elseif c == 'b' then
      local d, b
      d, nbs = next(regex, nbs)
      b, nbs = next(regex, nbs)
      assert(d ~= '' and b ~= '', "unbalanced pattern")
      functions = { matchers.balancer({d, b}, tostring(bs)) }
      nbs = utf8.next(regex, nbs)
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
    ctx.capture.id = ctx.capture.id + 1
    local nc = next(regex, nbs)
    if nc == ')' then
      functions = {matchers.capture_position(ctx.capture.id)}
      nbs = bs + 2
    else
      ctx.capture.balance = ctx.capture.balance + 1
      functions = {matchers.capture_start(ctx.capture.id)}
      nbs = bs + 1
    end
    if ctx.prev_class then
      table.insert(functions, 1, matchers.simple(ctx.prev_class, tostring(bs)))
    end
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

end

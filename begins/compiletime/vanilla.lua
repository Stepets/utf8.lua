return function(utf8)

local matchers = {
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
        if ctx.pos > 1 + utf8len(ctx.str) then
          return
        end
        ctx.result.start = ctx.pos
        ctx:next_function()
        ctx:get_function()(ctx)
        ctx:terminate()
    end)
]]
  end,
}

local function default()
  return matchers.sliding()
end

local function parse(regex, c, bs, ctx)
  if bs ~= 1 then return end

  local functions
  local skip = 0

  if c == '^' then
    functions = matchers.fromstart()
    skip = 1
  else
    functions = matchers.sliding()
  end

  return functions, skip
end

return {
  parse = parse,
  default = default,
}

end

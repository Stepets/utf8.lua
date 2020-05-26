return function(utf8)

local matchers = {
  sliding = function()
    return [[
    add(function(ctx) -- sliding
      while ctx.pos <= ctx.len do
        local clone = ctx:clone()
        -- debug('starting from', clone, "start_pos", clone.pos)
        clone.result.start = clone.pos
        clone:next_function()
        clone:get_function()(clone)

        ctx:next_char()
      end
      ctx:terminate()
    end)
]]
  end,
  fromstart = function(ctx)
    return [[
    add(function(ctx) -- fromstart
        if ctx.byte_pos > ctx.len then
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

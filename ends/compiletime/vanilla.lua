local matchers = {
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
  simple = require("modifier.compiletime.simple").simple,
}

local len = require "utf8primitives".raw.len

local function default()
  return matchers.any()
end

local function parse(regex, c, bs, ctx)
  local functions
  local skip = 0

  if bs == len(regex) and c == '$' then
      functions = matchers.toend()
      skip = 1
  end

  return functions, skip
end

return {
  parse = parse,
  default = default,
}

return function(utf8)

local matchers = utf8:require("modifier.compiletime.simple")

local function parse(regex, c, bs, ctx)
  local functions

  if ctx.prev_class then
    functions = { matchers.simple(ctx.prev_class, tostring(bs)) }
    ctx.prev_class = nil
  end

  return functions, 0
end

local function check(ctx)
  if ctx.prev_class then
    table.insert(ctx.funcs, matchers.simple(ctx.prev_class, tostring(ctx.pos)))
    ctx.prev_class = nil
  end
end

return {
  parse = parse,
  check = check,
}

end

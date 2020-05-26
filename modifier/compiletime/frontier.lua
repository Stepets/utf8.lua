return function(utf8)

local matchers = {
  frontier = function(class, name)
    local class_name = 'class' .. name
    return [[
  local ]] .. class_name .. [[ = ]] .. class .. [[

  add(function(ctx) -- frontier
    ctx:prev_char()
    local prev_charcode = ctx:get_charcode() or 0
    ctx:next_char()
    local charcode = ctx:get_charcode() or 0
    -- debug("frontier pos", ctx.pos, "prev_charcode", prev_charcode, "charcode", charcode)
    if ]] .. class_name .. [[:test(prev_charcode) then return end
    if ]] .. class_name .. [[:test(charcode) then
      ctx:next_function()
      return ctx:get_function()(ctx)
    end
  end)
]]
  end,
  simple = utf8:require("modifier.compiletime.simple").simple,
}

local function parse(regex, c, bs, ctx)
  local functions, nbs, class

  if c == '%' then
    if utf8.raw.sub(regex, bs + 1, bs + 1) ~= 'f' then return end
    if utf8.raw.sub(regex, bs + 2, bs + 2) ~= '[' then error("missing '[' after '%f' in pattern") end

    functions = {}
    if ctx.prev_class then
      table.insert(functions, matchers.simple(ctx.prev_class, tostring(bs)))
      ctx.prev_class = nil
    end
    class, nbs = utf8.regex.compiletime.charclass.parse(regex, '[', bs + 2, ctx)
    nbs = nbs + 2
    table.insert(functions, matchers.frontier(class:build(), tostring(bs)))
  end

  return functions, nbs
end

return {
  parse = parse,
}

end

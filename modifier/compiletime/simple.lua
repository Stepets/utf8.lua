return function(utf8)

local matchers = {
  simple = function(class, name)
    local class_name = 'class' .. name
    return [[
  local ]] .. class_name .. [[ = ]] .. class .. [[

  add(function(ctx) -- simple
    -- debug(ctx, 'simple', ']] .. class_name .. [[')
    if ]] .. class_name .. [[:test(ctx:get_charcode()) then
      ctx:next_char()
      ctx:next_function()
      return ctx:get_function()(ctx)
    end
  end)
]]
  end,
}

return matchers

end

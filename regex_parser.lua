return function(utf8)

utf8:require "modifier.compiletime.parser"
utf8:require "charclass.compiletime.parser"
utf8:require "begins.compiletime.parser"
utf8:require "ends.compiletime.parser"

local gensub = utf8.gensub
local sub = utf8.sub

local parser_context = utf8:require "context.compiletime"

return function(regex, plain)
  utf8.debug("regex", regex)
  local ctx = parser_context:new()

  local skip = {0}
  for nbs, c, bs in gensub(regex, 0), skip do
    repeat -- continue
      skip[1] = 0

      c = utf8.raw.sub(regex, bs, utf8.next(regex, bs) - 1)

      local functions, move = utf8.regex.compiletime.begins.parse(regex, c, bs, ctx)
      if functions then
        ctx.begins = functions
        skip[1] = move
      end
      if skip[1] ~= 0 then break end

      local functions, move = utf8.regex.compiletime.ends.parse(regex, c, bs, ctx)
      if functions then
        ctx.ends = functions
        skip[1] = move
      end
      if skip[1] ~= 0 then break end

      local functions, move = utf8.regex.compiletime.modifier.parse(regex, c, bs, ctx)
      if functions then
        for _, f in ipairs(functions) do
          ctx.funcs[#ctx.funcs + 1] = f
        end
        skip[1] = move
      end
      if skip[1] ~= 0 then break end

      local charclass, move = utf8.regex.compiletime.charclass.parse(regex, c, bs, ctx)
      if charclass then skip[1] = move end
    until true -- continue
  end

  for _, m in ipairs(utf8.config.modifier) do
    if m.check then m.check(ctx) end
  end

  local src = [[
  return function(str, init, utf8)
      local ctx = utf8:require("context.runtime").new({str = str, pos = init or 1})
      local cl = utf8:require("charclass.runtime.init")
      local utf8sub = utf8.sub
      local rawsub = utf8.raw.sub
      local utf8len = utf8.len
      local utf8next = utf8.next
      local debug = utf8.debug
      local function add(fun)
          ctx.functions[#ctx.functions + 1] = fun
      end
  ]] .. ctx.begins
  for _, v in ipairs(ctx.funcs) do src = src .. v end
  src = src .. ctx.ends .. [[
      return coroutine.wrap(ctx:get_function())(ctx)
  end
  ]]

  utf8.debug(regex, src)

  return assert(utf8.config.loadstring(src, (plain and "plain " or "") .. regex))()
end

end

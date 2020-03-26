local base = require("utf8primitives")
local gensub = base.gensub
local sub = base.sub

local modifiers = {
  require "modifier.compiletime.vanilla",
  require "modifier.compiletime.frontier",
  require "modifier.compiletime.stub",
}

local begins = {
  require "begins.compiletime.vanilla"
}

local ends = {
  require "ends.compiletime.vanilla"
}

return function(regex, plain)
  print("regex", regex)
  local ctx = require 'parser_context':new()

  local skip = {0}
  for nbs, c, bs in gensub(regex, 0), skip do
    repeat -- continue
      skip[1] = 0
      -- c = base.raw.sub(regex, bs, bs)

      -- print("str:", tostring(base.raw.sub(str, nbs1, nbs2 - 1)), "bss", bs, nbs1, nbs2)
      c = base.raw.sub(regex, bs, base.next(regex, bs) - 1)

      for _, m in ipairs(begins) do
        local functions, move = m.parse(regex, c, bs, ctx)
        print("begins", _, c, bs, nbs, move, functions)
        if functions then
          skip[1] = move
          ctx.begins = functions
          break
        end
      end
      if skip[1] ~= 0 then break end

      for _, m in ipairs(ends) do
        local functions, move = m.parse(regex, c, bs, ctx)
        print("ends", _, c, bs, nbs, move, functions)
        if functions then
          skip[1] = move
          ctx.ends = functions
          break
        end
      end
      if skip[1] ~= 0 then break end

      for _, m in ipairs(modifiers) do
        local functions, move = m.parse(regex, c, bs, ctx)
        print("mod", _, c, bs, nbs, move, functions and table.unpack(functions))
        if functions then
          ctx.prev_class = nil
          mod_found = true
          skip[1] = move
          print(skip[1])
          for _, f in ipairs(functions) do
            ctx.funcs[#ctx.funcs + 1] = f
          end
          break
        end
      end
      if skip[1] ~= 0 then break end

      local charclass, move = ctx.parse(regex, c, bs, ctx)
      if charclass then
        skip[1] = move
      end
    until true -- continue
  end

  for _, m in ipairs(modifiers) do
    if m.check then m.check(ctx) end
  end

  local src = [[
  return function(str, init)
      local ctx = require("context").new({str = str, pos = init or 1})
      local cl = require("charclass.runtime")
      local utf8sub = require("utf8primitives").sub
      local utf8len = require("utf8primitives").len
      local function add(fun)
          ctx.functions[#ctx.functions + 1] = fun
      end
  ]] .. ctx.begins
  for _, v in ipairs(ctx.funcs) do src = src .. v end
  src = src .. ctx.ends .. [[
      return coroutine.wrap(ctx:get_function())(ctx)
  end
  ]]

  print(regex, src)

  return assert((loadstring or load)(src, (plain and "plain " or "") .. regex))()
end

function dump (tab, val)
  if type(val) == 'table' then
    for k,v in pairs(val) do
      print(tab, k)
      dump(tab .. '\t', v)
    end
  else
    print(tab, val)
  end
end

dump('',{(function(str)
  local ctx = require("context").new({str = str})
    local cl = require("class")
    local function add(fun)
        ctx.functions[#ctx.functions + 1] = fun
    end
    add(function(ctx) -- sliding
        local saved = ctx:clone()
        while ctx.pos < #ctx.str do
            local prev_pos = ctx.pos
            ctx.result.start = ctx.pos
            ctx:next_function()
            ctx:get_function()(ctx)

            ctx = saved:clone()
            ctx.pos = prev_pos
            ctx:next_char()
        end
        ctx:terminate()
    end)
    local class2 = cl.new():with_codes(97)
    add(function(ctx) -- simple
        print('simple', 'class2')
        --local saved = ctx:clone()
        if class2:test(ctx:get_charcode()) then
            ctx:next_char()
            ctx:next_function()
            ctx:get_function()(ctx)
        end
        --ctx = saved
    end)
    local class3 = cl.new():with_codes(97)
    add(function(ctx) -- simple
        print('simple', 'class3')
        --local saved = ctx:clone()
        if class3:test(ctx:get_charcode()) then
            ctx:next_char()
            ctx:next_function()
            ctx:get_function()(ctx)
        end
        --ctx = saved
    end)
    local classnil = cl.new():with_codes(97)
    add(function(ctx) -- simple
        print('simple', 'classnil')
        --local saved = ctx:clone()
        if classnil:test(ctx:get_charcode()) then
            ctx:next_char()
            ctx:next_function()
            ctx:get_function()(ctx)
        end
        --ctx = saved
    end)
    add(function(ctx) -- any
        ctx.result.finish = ctx.pos
        ctx:done()
    end)
    return coroutine.wrap(ctx:get_function())(ctx)
end)('aaaa')})

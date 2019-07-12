  return function(str, init)
      local ctx = require("context").new({str = str, pos = init or 1})
      local cl = require("class")
      local utf8sub = require(".utf8").sub
      local utf8len = require(".utf8").len
      local function add(fun)
          ctx.functions[#ctx.functions + 1] = fun
      end
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
    add(function(ctx)
        debug(ctx, 'capture_start', '1')
        table.insert(ctx.captures.active, { id = 1, start_byte = byte_pos, start = ctx.pos })
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
    add(function(ctx)
        debug(ctx, 'capture_start', '2')
        table.insert(ctx.captures.active, { id = 2, start_byte = byte_pos, start = ctx.pos })
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
    local class4 = cl.new():with_codes(98)
    add(function(ctx) -- simple
        debug(ctx, 'simple', 'class4')
        if class4:test(ctx:get_charcode()) then
            ctx:next_char()
            ctx:next_function()
            return ctx:get_function()(ctx)
        end
    end)
  local class4 = cl.new():with_codes(98)
  add(function(ctx) -- star
      debug(ctx, 'star', 'class4')
      local saved = {ctx:clone()}
      while class4:test(ctx:get_charcode()) do
        ctx:next_char()
        table.insert(saved, ctx:clone())
        debug('#saved', #saved)
      end
      while #saved > 0 do
          ctx = table.remove(saved)
          ctx:next_function()
          ctx:get_function()(ctx)
          debug('#saved', #saved)
      end
  end)
  local class6 = cl.new():with_codes(97)
  add(function(ctx) -- star
      debug(ctx, 'star', 'class6')
      local saved = {ctx:clone()}
      while class6:test(ctx:get_charcode()) do
        ctx:next_char()
        table.insert(saved, ctx:clone())
        debug('#saved', #saved)
      end
      while #saved > 0 do
          ctx = table.remove(saved)
          ctx:next_function()
          ctx:get_function()(ctx)
          debug('#saved', #saved)
      end
  end)
    add(function(ctx)
        debug(ctx, 'capture_finish', '-2')
        dump('ctx:', ctx)
        local cap = table.remove(ctx.captures.active)
        cap.finish_byte = byte_pos
        cap.finish = ctx.pos
        ctx.captures[cap.id] = utf8sub(ctx.str, cap.start, cap.finish - 1)
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
    local class9 = cl.new():invert()
    add(function(ctx) -- minus
        debug(ctx, 'minus', 'class9')

        repeat
          local saved = ctx:clone()
          ctx:next_function()
          ctx:get_function()(ctx)
          ctx = saved
          local match = class9:test(ctx:get_charcode())
          ctx:next_char()
        until not match
    end)
    add(function(ctx)
        debug(ctx, 'capture', '2')
        -- dump('ctx:', ctx)
        local cap = ctx.captures[ 2 ]
        local len = utf8len(cap)
  			local check = utf8sub(ctx.str, ctx.pos, ctx.pos + len - 1)
        debug("capture check:", cap, check)
  			if cap == check then
  				ctx.pos = ctx.pos + len
  				ctx:next_function()
          return ctx:get_function()(ctx)
  			end
    end)
    add(function(ctx)
        debug(ctx, 'capture_finish', '-1')
        dump('ctx:', ctx)
        local cap = table.remove(ctx.captures.active)
        cap.finish_byte = byte_pos
        cap.finish = ctx.pos
        ctx.captures[cap.id] = utf8sub(ctx.str, cap.start, cap.finish - 1)
        ctx:next_function()
        return ctx:get_function()(ctx)
    end)
    add(function(ctx) -- any
        ctx.result.finish = ctx.pos - 1
        ctx:done()
    end)
      return coroutine.wrap(ctx:get_function())(ctx)
  end
  
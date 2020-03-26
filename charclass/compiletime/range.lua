local base = require "utf8primitives"
local cl = require "charclass.compiletime.builder"

local function next(str, bs)
  local nbs1 = base.next(str, bs)
  local nbs2 = base.next(str, nbs1)
  -- print("str:", tostring(base.raw.sub(str, nbs1, nbs2 - 1)), "bss", bs, nbs1, nbs2)
  return base.raw.sub(str, nbs1, nbs2 - 1), nbs1
end

return function(str, c, bs, ctx)
  if not ctx.internal then return end

  local nbs = bs

  local r1, r2

  local c, nbs = c, bs
  if c == '%' then
    c, nbs = next(str, nbs)
    r1 = c
  else
    r1 = c
  end

  print("range r1", r1, nbs)

  c, nbs = next(str, nbs)
  if c ~= '-' then return end

  c, nbs = next(str, nbs)
  if c == '%' then
    c, nbs = next(str, nbs)
    r2 = c
  elseif c ~= '' then
    r2 = c
  end

  print("range r2", r2, nbs)

  if r1 and r2 then
    return cl.new():with_ranges{base.byte(r1), base.byte(r2)}, base.next(str, nbs) - bs
  else
    return
  end
end

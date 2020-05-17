return function(utf8)

local cl = utf8.regex.compiletime.charclass.builder

local next = utf8.util.next

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

  utf8.debug("range r1", r1, nbs)

  c, nbs = next(str, nbs)
  if c ~= '-' then return end

  c, nbs = next(str, nbs)
  if c == '%' then
    c, nbs = next(str, nbs)
    r2 = c
  elseif c ~= '' and c ~= ']' then
    r2 = c
  end

  utf8.debug("range r2", r2, nbs)

  if r1 and r2 then
    return cl.new():with_ranges{utf8.byte(r1), utf8.byte(r2)}, utf8.next(str, nbs) - bs
  else
    return
  end
end

end

return function(utf8)

local cl = utf8.regex.compiletime.charclass.builder

return function(str, c, bs, ctx)
  return cl.new():with_codes(c), utf8.next(str, bs) - bs
end

end

local base = require "utf8primitives"
local cl = require "charclass.compiletime.builder"

return function(str, c, bs, ctx)
  return cl.new():with_codes(c), base.next(str, bs) - bs
end

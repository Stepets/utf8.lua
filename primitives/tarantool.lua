return function(utf8)

utf8:require "primitives.dummy"

local tnt_utf8 = utf8.config.tarantool_utf8 or require("utf8")

utf8.lower = tnt_utf8.lower
utf8.upper = tnt_utf8.upper
utf8.len = tnt_utf8.len
utf8.char = tnt_utf8.char

return utf8
end

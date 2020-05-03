return function(utf8)

os.setlocale(utf8.config.locale, "ctype")

local ffi = require("ffi")
ffi.cdef[[
  int towupper(int c);
  int towlower(int c);
]]

utf8:require "primitives.dummy"

function utf8.lower(str)
  local bs = 1
  local nbs
  local bytes = utf8.raw.len(str)
  local res = {}

  while bs <= bytes do
    nbs = utf8.next(str, bs)
    local cp = utf8.unicode(str, bs, nbs)
    res[#res + 1] = ffi.C.towlower(cp)
    bs = nbs
  end

  return utf8.char(utf8.config.unpack(res))
end

function utf8.upper(str)
  local bs = 1
  local nbs
  local bytes = utf8.raw.len(str)
  local res = {}

  while bs <= bytes do
    nbs = utf8.next(str, bs)
    local cp = utf8.unicode(str, bs, nbs)
    res[#res + 1] = ffi.C.towupper(cp)
    bs = nbs
  end

  return utf8.char(utf8.config.unpack(res))
end

return utf8
end

return function(utf8)

local ffi = require("ffi")
if ffi.os == "Windows" then
  os.setlocale(utf8.config.locale or "english_us.65001", "ctype")
  ffi.cdef[[
    short towupper(short c);
    short towlower(short c);
  ]]
else
  os.setlocale(utf8.config.locale or "C.UTF-8", "ctype")
  ffi.cdef[[
    int towupper(int c);
    int towlower(int c);
  ]]
end

utf8:require "primitives.dummy"

if not utf8.config.conversion.uc_lc then
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
end

if not utf8.config.conversion.lc_uc then
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
end

return utf8
end

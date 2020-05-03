return function(utf8)

os.setlocale(utf8.config.locale, "ctype")

local ffi = require("ffi")
ffi.cdef[[
  int iswalnum(int c);
  int iswalpha(int c);
  int iswascii(int c);
  int iswblank(int c);
  int iswcntrl(int c);
  int iswdigit(int c);
  int iswgraph(int c);
  int iswlower(int c);
  int iswprint(int c);
  int iswpunct(int c);
  int iswspace(int c);
  int iswupper(int c);
  int iswxdigit(int c);
]]

local base = utf8:require "charclass.runtime.base"

local native = setmetatable({}, {__index = base})
local mt = {__index = native}

function native.new()
  return setmetatable({}, mt)
end

function native:is(class, char_code)
  if class == 'alpha' then return ffi.C.iswalpha(char_code) ~= 0
  elseif class == 'cntrl' then return ffi.C.iswcntrl(char_code) ~= 0
  elseif class == 'digit' then return ffi.C.iswdigit(char_code) ~= 0
  elseif class == 'graph' then return ffi.C.iswgraph(char_code) ~= 0
  elseif class == 'lower' then return ffi.C.iswlower(char_code) ~= 0
  elseif class == 'punct' then return ffi.C.iswpunct(char_code) ~= 0
  elseif class == 'space' then return ffi.C.iswspace(char_code) ~= 0
  elseif class == 'upper' then return ffi.C.iswupper(char_code) ~= 0
  elseif class == 'alnum' then return ffi.C.iswalnum(char_code) ~= 0
  elseif class == 'xdigit' then return ffi.C.iswxdigit(char_code) ~= 0
  end
end

return native

end

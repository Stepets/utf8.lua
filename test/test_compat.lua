local utf8 = require 'init'
utf8.config = {
  debug = nil, --utf8:require("util").debug
}
utf8:init()
print('testing utf8 library')

local LUA_51, LUA_53 = false, false
if "\xe4" == "xe4" then -- lua5.1
  LUA_51 = true
else -- luajit lua5.3
  LUA_53 = true
end

assert(utf8.sub("123456789",2,4) == "234")
assert(utf8.sub("123456789",7) == "789")
assert(utf8.sub("123456789",7,6) == "")
assert(utf8.sub("123456789",7,7) == "7")
assert(utf8.sub("123456789",0,0) == "")
assert(utf8.sub("123456789",-10,10) == "123456789")
assert(utf8.sub("123456789",1,9) == "123456789")
assert(utf8.sub("123456789",-10,-20) == "")
assert(utf8.sub("123456789",-1) == "9")
assert(utf8.sub("123456789",-4) == "6789")
assert(utf8.sub("123456789",-6, -4) == "456")
if not _no32 then
  assert(utf8.sub("123456789",-2^31, -4) == "123456")
  assert(utf8.sub("123456789",-2^31, 2^31 - 1) == "123456789")
  assert(utf8.sub("123456789",-2^31, -2^31) == "")
end
assert(utf8.sub("\000123456789",3,5) == "234")
assert(utf8.sub("\000123456789", 8) == "789")
print('+')

assert(utf8.find("123456789", "345") == 3)
a,b = utf8.find("123456789", "345")
assert(utf8.sub("123456789", a, b) == "345")
assert(utf8.find("1234567890123456789", "345", 3) == 3)
assert(utf8.find("1234567890123456789", "345", 4) == 13)
assert(utf8.find("1234567890123456789", "346", 4) == nil)
assert(utf8.find("1234567890123456789", ".45", -9) == 13)
assert(utf8.find("abcdefg", "\0", 5, 1) == nil)
assert(utf8.find("", "") == 1)
assert(utf8.find("", "", 1) == 1)
assert(not utf8.find("", "", 2))
assert(utf8.find('', 'aaa', 1) == nil)
assert(('alo(.)alo'):find('(.)', 1, 1) == 4)
print('+')

assert(utf8.len("") == 0)
assert(utf8.len("\0\0\0") == 3)
assert(utf8.len("1234567890") == 10)

assert(utf8.byte("a") == 97)
if LUA_51 then
  assert(utf8.byte("�") > 127)
else
  assert(utf8.byte("\xe4") > 127)
end
assert(utf8.byte(utf8.char(255)) == 255)
assert(utf8.byte(utf8.char(0)) == 0)
assert(utf8.byte("\0") == 0)
assert(utf8.byte("\0\0alo\0x", -1) == string.byte('x'))
assert(utf8.byte("ba", 2) == 97)
assert(utf8.byte("\n\n", 2, -1) == 10)
assert(utf8.byte("\n\n", 2, 2) == 10)
assert(utf8.byte("") == nil)
assert(utf8.byte("hi", -3) == nil)
assert(utf8.byte("hi", 3) == nil)
assert(utf8.byte("hi", 9, 10) == nil)
assert(utf8.byte("hi", 2, 1) == nil)
assert(utf8.char() == "")
if LUA_53 then
  assert(utf8.raw.char(0, 255, 0) == "\0\255\0") -- fails due 255 can't be utf8 byte
  assert(utf8.char(0, 255, 0) == "\0\195\191\0")
  assert(utf8.raw.char(0, utf8.byte("\xe4"), 0) == "\0\xe4\0")
  assert(utf8.char(0, utf8.byte("\xe4"), 0) == "\0\195\164\0")
  assert(utf8.raw.char(utf8.raw.byte("\xe4l\0�u", 1, -1)) == "\xe4l\0�u")
  assert(utf8.raw.char(utf8.raw.byte("\xe4l\0�u", 1, -1)) == "\xe4l\0�u")
  assert(utf8.raw.char(utf8.raw.byte("\xe4l\0�u", 1, 0)) == "")
  assert(utf8.raw.char(utf8.raw.byte("\xe4l\0�u", -10, 100)) == "\xe4l\0�u")
end

assert(utf8.upper("ab\0c") == "AB\0C")
assert(utf8.lower("\0ABCc%$") == "\0abcc%$")
assert(utf8.rep('teste', 0) == '')
assert(utf8.rep('t�s\00t�', 2) == 't�s\0t�t�s\000t�')
assert(utf8.rep('', 10) == '')
print('+')

assert(utf8.upper("ab\0c") == "AB\0C")
assert(utf8.lower("\0ABCc%$") == "\0abcc%$")

assert(utf8.reverse"" == "")
assert(utf8.reverse"\0\1\2\3" == "\3\2\1\0")
assert(utf8.reverse"\0001234" == "4321\0")

for i=0,30 do assert(utf8.len(string.rep('a', i)) == i) end

print('+')

do
  local f = utf8.gmatch("1 2 3 4 5", "%d+")
  assert(f() == "1")
  co = coroutine.wrap(f)
  assert(co() == "2")
end

print('OK')

local utf8 = require('init')
utf8.config = {
  debug = nil,
--   debug = utf8:require("util").debug,
}
utf8:init()

for k,v in pairs(utf8) do
  string[k] = v
end

local LUA_51, LUA_53 = false, false
if "\xe4" == "xe4" then -- lua5.1
  LUA_51 = true
else -- luajit lua5.3
  LUA_53 = true
end

local FFI_ENABLED = false
if pcall(require, "ffi") then
  FFI_ENABLED = true
end

local res = {}

local equals = require 'test.util'.equals
local assert = require 'test.util'.assert
local assert_equals = require 'test.util'.assert_equals

if FFI_ENABLED then
  assert_equals(("АБВ"):lower(), "абв")
  assert_equals(("абв"):upper(), "АБВ")
end

res = {}
for _, w in ("123456789"):gensub(2), {1} do res[#res + 1] = w end
assert_equals({"23", "56", "89"}, res)

assert_equals(0, ("фыва"):next(0))
assert_equals(100, ("фыва"):next(100))
assert_equals(#"ф" + 1, ("фыва"):next(1))
assert_equals("ыва", utf8.raw.sub("фыва", ("фыва"):next(1)))

res = {}
for p, c in ("абвгд"):codes() do res[#res + 1] = {p, c} end
assert_equals({
  {1, utf8.byte'а'},
  {#'а' + 1, utf8.byte'б'},
  {#'аб' + 1, utf8.byte'в'},
  {#'абв' + 1, utf8.byte'г'},
  {#'абвг' + 1, utf8.byte'д'},
}, res)

assert_equals(1, utf8.offset('abcde', 0))

assert_equals(1, utf8.offset('abcde', 1))
assert_equals(5, utf8.offset('abcde', 5))
assert_equals(6, utf8.offset('abcde', 6))
assert_equals(nil, utf8.offset('abcde', 7))

assert_equals(5, utf8.offset('abcde', -1))
assert_equals(1, utf8.offset('abcde', -5))
assert_equals(nil, utf8.offset('abcde', -6))

assert_equals(1, utf8.offset('abcde', 0, 1))
assert_equals(3, utf8.offset('abcde', 0, 3))
assert_equals(6, utf8.offset('abcde', 0, 6))

assert_equals(3, utf8.offset('abcde', 1, 3))
assert_equals(5, utf8.offset('abcde', 3, 3))
assert_equals(6, utf8.offset('abcde', 4, 3))
assert_equals(nil, utf8.offset('abcde', 5, 3))

assert_equals(2, utf8.offset('abcde', -1, 3))
assert_equals(1, utf8.offset('abcde', -2, 3))
assert_equals(5, utf8.offset('abcde', -1, 6))
assert_equals(nil, utf8.offset('abcde', -3, 3))

assert_equals(1, utf8.offset('абвгд', 0))

assert_equals(1, utf8.offset('абвгд', 1))
assert_equals(#'абвг' + 1, utf8.offset('абвгд', 5))
assert_equals(#'абвгд' + 1, utf8.offset('абвгд', 6))
assert_equals(nil, utf8.offset('абвгд', 7))

assert_equals(#'абвг' + 1, utf8.offset('абвгд', -1))
assert_equals(1, utf8.offset('абвгд', -5))
assert_equals(nil, utf8.offset('абвгд', -6))

assert_equals(1, utf8.offset('абвгд', 0, 1))
assert_equals(1, utf8.offset('абвгд', 0, 2))
assert_equals(#'аб' + 1, utf8.offset('абвгд', 0, #'аб' + 1))
assert_equals(#'аб' + 1, utf8.offset('абвгд', 0, #'аб' + 2))
assert_equals(#'абвгд' + 1, utf8.offset('абвгд', 0, #'абвгд' + 1))

assert_equals(#'аб' + 1, utf8.offset('абвгд', 1, #'аб' + 1))
assert_equals(#'абвг' + 1, utf8.offset('абвгд', 3, #'аб' + 1))
assert_equals(#'абвгд' + 1, utf8.offset('абвгд', 4, #'аб' + 1))
assert_equals(#'абвгд' + 1, utf8.offset('абвгд', 4, #'аб' + 2))
assert_equals(nil, utf8.offset('абвгд', 5, #'аб' + 1))

assert_equals(#'а' + 1, utf8.offset('абвгд', -1, #'аб' + 1))
assert_equals(1, utf8.offset('абвгд', -2, #'аб' + 1))
assert_equals(#'абвг' + 1, utf8.offset('абвгд', -1, #'абвгд' + 1))
assert_equals(nil, utf8.offset('абвгд', -3, #'аб' + 1))

assert(("фыва"):validate())
assert_equals({false, {{ pos = #"ф" + 1, part = 1, code = 255 }} }, {("ф\255ыва"):validate()})
if LUA_53 then
  assert_equals({false, {{ pos = #"ф" + 1, part = 1, code = 0xFF }} }, {("ф\xffыва"):validate()})
end

assert_equals(nil, ("aabb"):find("%bcd"))
assert_equals({1, 4}, {("aabb"):find("%bab")})
assert_equals({1, 2}, {("aba"):find('%bab')})

res = {}
for w in ("aacaabbcabbacbaacab"):gmatch('%bab') do res[#res + 1] = w end
assert_equals({"acaabbcabb", "acb", "ab"}, res)

assert_equals({1, 0}, {("aacaabbcabbacbaacab"):find('%f[acb]')})
assert_equals("a", ("aba"):match('%f[ab].'))

res = {}
for w in ("aacaabbcabbacbaacab"):gmatch('%f[ab]') do res[#res + 1] = w end
assert_equals({"", "", "", "", ""}, res)

assert_equals({"HaacHaabbcHabbacHbaacHab",	5}, {("aacaabbcabbacbaacab"):gsub('%f[ab]', 'H')})

res = {}
for w in ("Привет, мир, от Lua"):gmatch("[^%p%d%s%c]+") do res[#res + 1] = w end
assert_equals({"Привет", "мир", "от", "Lua"}, res)

res = {}
for k, v in ("从=世界, 到=Lua"):gmatch("([^%p%s%c]+)=([^%p%s%c]+)") do res[k] = v end
assert_equals({["到"] =	"Lua", ["从"] = "世界"}, res)

assert_equals("Ahoj Ahoj světe světe", ("Ahoj světe"):gsub("([^%p%s%c]+)", "%1 %1"))

assert_equals("Ahoj Ahoj světe", ("Ahoj světe"):gsub("[^%p%s%c]+", "%0 %0", 1))

assert_equals("κόσμο γεια Lua από", ("γεια κόσμο από Lua"):gsub("([^%p%s%c]+)%s*([^%p%s%c]+)", "%2 %1"))

assert_equals({8, 27, "ололоо я водитель э"}, {("пыщпыщ ололоо я водитель энло"):find("(.л.+)н")})

assert_equals({"пыщпыщ о보라보라 я водитель эн보라",	3}, {("пыщпыщ ололоо я водитель энло"):gsub("ло+", "보라")})

assert_equals("пыщпыщ ололоо я", ("пыщпыщ ололоо я водитель энло"):match("^п[лопыщ ]*я"))

assert_equals("в", ("пыщпыщ ололоо я водитель энло"):match("[в-д]+"))

assert_equals(nil, ('abc abc'):match('([^%s]+)%s%s')) -- https://github.com/Stepets/utf8.lua/issues/2

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("a+b") do res[#res + 1] = w end
assert_equals({"ab","aab"}, res)

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("a-b") do res[#res + 1] = w end
assert_equals({"ab","b","b","b","aab","b","b"}, res)

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("a*b") do res[#res + 1] = w end
assert_equals({"ab","b","b","b","aab","b","b"}, res)

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("ba+") do res[#res + 1] = w end
assert_equals({"ba","ba"}, res)

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("ba-") do res[#res + 1] = w end
assert_equals({"b","b","b","b","b","b","b"}, res)

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("ba*") do res[#res + 1] = w end
assert_equals({"b","ba","b","b","b","b","ba"}, res)

assert_equals({"bacbbcaabbcba", "ba"}, {("aacabbacbbcaabbcbacaa"):match("((ba+).*%2)")})
assert_equals({"bbacbbcaabbcb", "b"}, {("aacabbacbbcaabbcbacaa"):match("((ba*).*%2)")})

res = {}
for w in ("aacabbacbbcaabbcbacaa"):gmatch("((b+a*).-%2)") do res[#res + 1] = w end
assert_equals({"bbacbb", "bb"}, res)

assert_equals("a**", ("a**v"):match("a**+"))
assert_equals("a", ("a**v"):match("a**-"))

assert_equals({"test", "."}, {("test.lua"):match("(.-)([.])")})

-- https://github.com/Stepets/utf8.lua/issues/3
assert_equals({"ab", "c"}, {("abc"):match("^([ab]-)([^b]*)$")})
assert_equals({"ab", ""}, {("ab"):match("^([ab]-)([^b]*)$")})
assert_equals({"items.", ""}, {("items."):match("^(.-)([^.]*)$")})
assert_equals({"", "items"}, {("items"):match("^(.-)([^.]*)$")})

-- https://github.com/Stepets/utf8.lua/issues/4
assert_equals({"ab.123", 1}, {("ab.?"):gsub("%?", "123")})

-- https://github.com/Stepets/utf8.lua/issues/5
assert_equals({"ab", 1}, {("ab"):gsub("a", "%0")})
assert_equals({"ab", 1}, {("ab"):gsub("a", "%1")})

assert_equals("c", ("abc"):match("c", -1))

print("\ntests passed\n")

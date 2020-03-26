local utf8 = require '.utf8_2018'
for k,v in pairs(utf8) do
  string[k] = v
end

local res = {}

local equals = require 'test.util'.equals
local assert = require 'test.util'.assert
local assert_equals = require 'test.util'.assert_equals

res = {}
for _, w in ("123456789"):gensub(2), {1} do res[#res + 1] = w end
assert_equals({"23", "56", "89"}, res)

assert_equals(0, ("фыва"):next(0))
assert_equals(100, ("фыва"):next(100))
assert_equals(#"ф" + 1, ("фыва"):next(1))
assert_equals("ыва", utf8.raw.sub("фыва", ("фыва"):next(1)))

assert(("фыва"):validate())
assert_equals({false, {{ pos = #"ф" + 1, part = 1, code = 0xFF }} }, {("ф\xffыва"):validate()})

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

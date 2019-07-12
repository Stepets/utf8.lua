local utf8 = require '.utf8_2018'
for k,v in pairs(utf8) do
  string[k] = v
end

local res = {}

local function equals(t1, t2)
  for k,v in pairs(t1) do
    if not t2[k] or t2[k] ~= v then return false end
  end
  for k,v in pairs(t2) do
    if not t1[k] or t1[k] ~= v then return false end
  end
  return true
end

local old_assert = assert
local assert = function(cond, ...)
  if not cond then
    local data = {...}
    local msg = ""
    for _, v in pairs(data) do
      local type = type(v)
      if type == 'table' then
        local tbl = "{"
        for k,v in pairs(v) do
          tbl = tbl .. tostring(k) .. ' = ' .. tostring(v) .. ', '
        end
        msg = msg .. tbl .. '}'
      else
        msg = msg .. tostring(v)
      end
    end
    error(#data > 0 and msg or "assertion failed!")
  end
  return cond
end

local function assert_equals(a,b)
  assert(
    type(a) == 'table' and type(b) == 'table' and equals(a,b) or a == b,
    "expected: ", a and a or tostring(a), "\n",
    "got: ", b and b or tostring(b)
  )
end

assert_equals(nil, ("aabb"):find("%bcd"))
assert_equals({1, 4}, {("aabb"):find("%bab")})
assert_equals({1, 2}, {("aba"):find('%bab')})

res = {}
for w in ("aacaabbcabbacbaacab"):gmatch('%bab') do
  res[#res + 1] = w
end
assert_equals({"acaabbcabb", "acb", "ab"}, res)

assert_equals({1, 0}, {("aacaabbcabbacbaacab"):find('%f[acb]')})
assert_equals("a", ("aba"):match('%f[ab].'))

res = {}
for w in ("aacaabbcabbacbaacab"):gmatch('%f[ab]') do
  res[#res + 1] = w
end
assert_equals({"", "", "", "", ""}, res)

res = {}
for w in ("Привет, мир, от Lua"):gmatch("[^%p%d%s%c]+") do
  res[#res + 1] = w
end
assert_equals({"Привет", "мир", "от", "Lua"}, res)

res = {}
for k, v in ("从=世界, 到=Lua"):gmatch("([^%p%s%c]+)=([^%p%s%c]+)") do
  res[k] = v
end
assert_equals({["到"] =	"Lua", ["从"] = "世界"}, res)

assert_equals("Ahoj Ahoj světe světe", ("Ahoj světe"):gsub("([^%p%s%c]+)", "%1 %1"))

assert_equals("Ahoj Ahoj světe", ("Ahoj světe"):gsub("[^%p%s%c]+", "%0 %0", 1))

assert_equals("κόσμο γεια Lua από", ("γεια κόσμο από Lua"):gsub("([^%p%s%c]+)%s*([^%p%s%c]+)", "%2 %1"))

assert_equals({8, 27, "ололоо я водитель э"}, {("пыщпыщ ололоо я водитель энло"):find("(.л.+)н")})

assert_equals({"пыщпыщ о보라보라 я водитель эн보라",	3}, {("пыщпыщ ололоо я водитель энло"):gsub("ло+", "보라")})

assert_equals("пыщпыщ ололоо я", ("пыщпыщ ололоо я водитель энло"):match("^п[лопыщ ]*я"))

assert_equals(nil, ('abc abc'):match('([^%s]+)%s%s'))

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

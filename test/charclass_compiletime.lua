local utf8 = require "init"
utf8.config = {
  debug = nil, --utf8:require("util").debug
}
utf8:init()

local ctx = utf8:require("context.compiletime"):new()

local equals = require 'test.util'.equals
local assert = require 'test.util'.assert
local assert_equals = require 'test.util'.assert_equals
local parse = utf8.regex.compiletime.charclass.parse

assert_equals({parse("aabb", "a", 1, ctx)}, {{codes = {utf8.byte("a")}}, 1})
assert_equals({parse("aabb", "a", 2, ctx)}, {{codes = {utf8.byte("a")}}, 1})
assert_equals({parse("aabb", "b", 3, ctx)}, {{codes = {utf8.byte("b")}}, 1})
assert_equals({parse("aabb", "b", 4, ctx)}, {{codes = {utf8.byte("b")}}, 1})

assert_equals({parse("aa%ab", "%", 3, ctx)}, {{classes = {'alpha'}}, 2})
assert_equals({parse("aac%Ab", "%", 4, ctx)}, {{not_classes = {'alpha'}}, 2})
assert_equals({parse("aa.b", ".", 3, ctx)}, {{inverted = true}, 1})

assert_equals({parse("aa[c]b", "[", 3, ctx)}, {
  {codes = {utf8.byte("c")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[c]")
})

assert_equals({parse("aa[%A]b", "[", 3, ctx)}, {
  {codes = nil, ranges = nil, classes = nil, not_classes = {'alpha'}},
  utf8.raw.len("[%A]")
})

assert_equals({parse("[^%p%d%s%c]+", "[", 1, ctx)}, {
  {codes = nil, ranges = nil, classes = {'punct', 'digit', 'space', 'cntrl'}, not_classes = nil, inverted = true},
  utf8.raw.len("[^%p%d%s%c]")
})

assert_equals({parse("aa[[c]]b", "[", 3, ctx)}, {
  {codes = {utf8.byte("["), utf8.byte("c")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[[c]")
})

assert_equals({parse("aa[%a[c]]b", "[", 3, ctx)}, {
  {codes = {utf8.byte("["), utf8.byte("c")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  utf8.raw.len("[%a[c]")
})

assert_equals({parse("aac-db", "c", 3, ctx)}, {
  {codes = {utf8.byte("c")}},
  utf8.raw.len("c")
})

assert_equals({parse("aa[c-d]b", "[", 3, ctx)}, {
  {codes = nil, ranges = {{utf8.byte("c"),utf8.byte("d")}}, classes = nil, not_classes = nil},
  utf8.raw.len("[c-d]")
})
assert_equals(ctx.internal, false)

assert_equals({parse("aa[c-]]b", "[", 3, ctx)}, {
  {codes = {utf8.byte("-"), utf8.byte("c")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[c-]")
})
assert_equals(ctx.internal, false)

assert_equals({parse("aad-", "d", 3, ctx)}, {
  {codes = {utf8.byte("d")}},
  utf8.raw.len("d")
})
assert_equals(ctx.internal, false)

ctx.internal = false
assert_equals({parse(".", ".", 1, ctx)}, {
  {inverted = true},
  utf8.raw.len(".")
})

assert_equals({parse("[.]", "[", 1, ctx)}, {
  {codes = {utf8.byte(".")}},
  utf8.raw.len("[.]")
})

assert_equals({parse("%?", "%", 1, ctx)}, {
  {codes = {utf8.byte("?")}},
  utf8.raw.len("%?")
})

assert_equals({parse("[]]", "[", 1, ctx)}, {
  {codes = {utf8.byte("]")}},
  utf8.raw.len("[]]")
})

assert_equals({parse("[^]]", "[", 1, ctx)}, {
  {codes = {utf8.byte("]")}, inverted = true},
  utf8.raw.len("[^]]")
})

--[[--
multibyte chars
--]]--

assert_equals({parse("ббюю", "б", #"" + 1, ctx)}, {{codes = {utf8.byte("б")}}, utf8.raw.len("б")})
assert_equals({parse("ббюю", "б", #"б" + 1, ctx)}, {{codes = {utf8.byte("б")}}, utf8.raw.len("б")})
assert_equals({parse("ббюю", "ю", #"бб" + 1, ctx)}, {{codes = {utf8.byte("ю")}}, utf8.raw.len("ю")})
assert_equals({parse("ббюю", "ю", #"ббю" + 1, ctx)}, {{codes = {utf8.byte("ю")}}, utf8.raw.len("ю")})

assert_equals({parse("бб%aю", "%", #"бб" + 1, ctx)}, {{classes = {'alpha'}}, 2})
assert_equals({parse("ббц%Aю", "%", #"ббц" + 1, ctx)}, {{not_classes = {'alpha'}}, 2})
assert_equals({parse("бб.ю", ".", #"бб" + 1, ctx)}, {{inverted = true}, 1})

assert_equals({parse("бб[ц]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {utf8.byte("ц")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[ц]")
})

assert_equals({parse("бб[%A]ю", "[", #"бб" + 1, ctx)}, {
  {codes = nil, ranges = nil, classes = nil, not_classes = {'alpha'}},
  utf8.raw.len("[%A]")
})

assert_equals({parse("бб[[ц]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {utf8.byte("["), utf8.byte("ц")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[[ц]")
})

assert_equals({parse("бб[%a[ц]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {utf8.byte("["), utf8.byte("ц")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  utf8.raw.len("[%a[ц]")
})

ctx.internal = true
assert_equals({parse("ббц-ыю", "ц", #"бб" + 1, ctx)}, {
  {ranges = {{utf8.byte("ц"),utf8.byte("ы")}}},
  utf8.raw.len("ц-ы")
})

ctx.internal = false
assert_equals({parse("бб[ц-ы]ю", "[", #"бб" + 1, ctx)}, {
  {codes = nil, ranges = {{utf8.byte("ц"),utf8.byte("ы")}}, classes = nil, not_classes = nil},
  utf8.raw.len("[ц-ы]")
})

assert_equals({parse("бб[ц-]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {utf8.byte("-"), utf8.byte("ц")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[ц-]")
})

assert_equals({parse("ббы-", "ы", #"бб" + 1, ctx)}, {
  {codes = {utf8.byte("ы")}},
  utf8.raw.len("ы")
})

ctx.internal = true
assert_equals({parse("ббы-цю", "ы", #"бб" + 1, ctx)}, {
  {ranges = {{utf8.byte("ы"),utf8.byte("ц")}}},
  utf8.raw.len("ы-ц")
})

ctx.internal = false
assert_equals({parse("бб[ы]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {utf8.byte("ы")}, ranges = nil, classes = nil, not_classes = nil},
  utf8.raw.len("[ы]")
})

print "OK"

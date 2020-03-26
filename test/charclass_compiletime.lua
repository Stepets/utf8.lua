local base = require("utf8primitives")

local ctx = require 'parser_context':new()

local equals = require 'test.util'.equals
local assert = require 'test.util'.assert
local assert_equals = require 'test.util'.assert_equals

assert_equals({ctx.parse("aabb", "a", 1, ctx)}, {{codes = {base.byte("a")}}, 1})
assert_equals({ctx.parse("aabb", "a", 2, ctx)}, {{codes = {base.byte("a")}}, 1})
assert_equals({ctx.parse("aabb", "b", 3, ctx)}, {{codes = {base.byte("b")}}, 1})
assert_equals({ctx.parse("aabb", "b", 4, ctx)}, {{codes = {base.byte("b")}}, 1})

assert_equals({ctx.parse("aa%ab", "%", 3, ctx)}, {{classes = {'alpha'}}, 2})
assert_equals({ctx.parse("aac%Ab", "%", 4, ctx)}, {{not_classes = {'alpha'}}, 2})
assert_equals({ctx.parse("aa.b", ".", 3, ctx)}, {{inverted = true}, 1})

assert_equals({ctx.parse("aa[c]b", "[", 3, ctx)}, {
  {codes = {base.byte("c")}, ranges = nil, classes = nil, not_classes = nil},
  base.raw.len("[c]")
})

assert_equals({ctx.parse("aa[%A]b", "[", 3, ctx)}, {
  {codes = nil, ranges = nil, classes = nil, not_classes = {'alpha'}},
  base.raw.len("[%A]")
})

assert_equals({ctx.parse("[^%p%d%s%c]+", "[", 1, ctx)}, {
  {codes = nil, ranges = nil, classes = {'punct', 'digit', 'space', 'cntrl'}, not_classes = nil, inverted = true},
  base.raw.len("[^%p%d%s%c]")
})

assert_equals({ctx.parse("aa[[c]]b", "[", 3, ctx)}, {
  {codes = {base.byte("c")}, ranges = nil, classes = nil, not_classes = nil},
  base.raw.len("[[c]]")
})

assert_equals({ctx.parse("aa[%a[c]]b", "[", 3, ctx)}, {
  {codes = {base.byte("c")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  base.raw.len("[%a[c]]")
})

assert_equals({ctx.parse("aa[[c]%a]b", "[", 3, ctx)}, {
  {codes = {base.byte("c")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  base.raw.len("[[c]%a]")
})

assert_equals({ctx.parse("aac-db", "c", 3, ctx)}, {
  {ranges = {{base.byte("c"),base.byte("d")}}},
  base.raw.len("c-d")
})

assert_equals({ctx.parse("aa[c-d]b", "[", 3, ctx)}, {
  {codes = nil, ranges = {{base.byte("c"),base.byte("d")}}, classes = nil, not_classes = nil},
  base.raw.len("[c-d]")
})

assert_equals({ctx.parse("aa[c-]]b", "[", 3, ctx)}, {
  {codes = nil, ranges = {{base.byte("c"),base.byte("]")}}, classes = nil, not_classes = nil},
  base.raw.len("[c-]]")
})

assert_equals({ctx.parse("aad-", "d", 3, ctx)}, {
  {codes = {base.byte("d")}},
  base.raw.len("d")
})

--[[--
multibyte chars
--]]--

assert_equals({ctx.parse("ббюю", "б", #"" + 1, ctx)}, {{codes = {base.byte("б")}}, base.raw.len("б")})
assert_equals({ctx.parse("ббюю", "б", #"б" + 1, ctx)}, {{codes = {base.byte("б")}}, base.raw.len("б")})
assert_equals({ctx.parse("ббюю", "ю", #"бб" + 1, ctx)}, {{codes = {base.byte("ю")}}, base.raw.len("ю")})
assert_equals({ctx.parse("ббюю", "ю", #"ббю" + 1, ctx)}, {{codes = {base.byte("ю")}}, base.raw.len("ю")})

assert_equals({ctx.parse("бб%aю", "%", #"бб" + 1, ctx)}, {{classes = {'alpha'}}, 2})
assert_equals({ctx.parse("ббц%Aю", "%", #"ббц" + 1, ctx)}, {{not_classes = {'alpha'}}, 2})
assert_equals({ctx.parse("бб.ю", ".", #"бб" + 1, ctx)}, {{inverted = true}, 1})

assert_equals({ctx.parse("бб[ц]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ц")}, ranges = nil, classes = nil, not_classes = nil},
  base.raw.len("[ц]")
})

assert_equals({ctx.parse("бб[%A]ю", "[", #"бб" + 1, ctx)}, {
  {codes = nil, ranges = nil, classes = nil, not_classes = {'alpha'}},
  base.raw.len("[%A]")
})

assert_equals({ctx.parse("бб[[ц]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ц")}, ranges = nil, classes = nil, not_classes = nil},
  base.raw.len("[[ц]]")
})

assert_equals({ctx.parse("бб[%a[ц]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ц")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  base.raw.len("[%a[ц]]")
})

assert_equals({ctx.parse("бб[[ц]%a]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ц")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  base.raw.len("[[ц]%a]")
})

assert_equals({ctx.parse("ббц-ыю", "ц", #"бб" + 1, ctx)}, {
  {ranges = {{base.byte("ц"),base.byte("ы")}}},
  base.raw.len("ц-ы")
})

assert_equals({ctx.parse("бб[ц-ы]ю", "[", #"бб" + 1, ctx)}, {
  {codes = nil, ranges = {{base.byte("ц"),base.byte("ы")}}, classes = nil, not_classes = nil},
  base.raw.len("[ц-ы]")
})

assert_equals({ctx.parse("бб[ц-]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = nil, ranges = {{base.byte("ц"),base.byte("]")}}, classes = nil, not_classes = nil},
  base.raw.len("[ц-]]")
})

assert_equals({ctx.parse("ббы-", "ы", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ы")}},
  base.raw.len("ы")
})

assert_equals({ctx.parse("ббы-цю", "ы", #"бб" + 1, ctx)}, {
  {ranges = {{base.byte("ы"),base.byte("ц")}}},
  base.raw.len("ы-ц")
})

assert_equals({ctx.parse("бб[ы]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ы")}, ranges = nil, classes = nil, not_classes = nil},
  base.raw.len("[ы]")
})

assert_equals({ctx.parse("бб[[ц]%a[ы]]ю", "[", #"бб" + 1, ctx)}, {
  {codes = {base.byte("ц"), base.byte("ы")}, ranges = nil, classes = {'alpha'}, not_classes = nil},
  base.raw.len("[[ц]%a[ы]]")
})

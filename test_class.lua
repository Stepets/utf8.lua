local class = require('class')

local codes = class.new():with_codes(100, 10, 200)

test_binsearch = (function()
  assert(not codes.inverted)
  assert(codes:binsearch(10))
  assert(codes:binsearch(100))
  assert(codes:binsearch(200))

  assert(not codes:binsearch(101))
end)()

test_test = (function()
  assert(codes:test(10))
  assert(codes:test(100))
  assert(codes:test(200))

  assert(not codes:test(101))
end)()

local codes_ranges = class.new():with_codes(100, 10, 200):with_ranges({150, 160}, {2, 11})

test_binsearch = (function()
  assert(codes_ranges:binsearch(10))
  assert(codes_ranges:binsearch(100))
  assert(codes_ranges:binsearch(200))

  assert(not codes_ranges:binsearch(151))
end)()

test_test = (function()
  assert(codes_ranges:test(10))
  assert(codes_ranges:test(100))
  assert(codes_ranges:test(200))

  assert(not codes_ranges:test(101))
  assert(codes_ranges:test(151))
end)()

local codes_ranges_inverted = class.new():with_codes(100, 10, 200):with_ranges({150, 160}, {2, 11}):invert()

test_binsearch = (function()
  assert(codes_ranges_inverted.inverted)
  assert(codes_ranges_inverted:binsearch(10))
  assert(codes_ranges_inverted:binsearch(100))
  assert(codes_ranges_inverted:binsearch(200))

  assert(not codes_ranges_inverted:binsearch(151))
end)()

test_test = (function()
  assert(not codes_ranges_inverted:test(10))
  assert(not codes_ranges_inverted:test(100))
  assert(not codes_ranges_inverted:test(200))

  assert(codes_ranges_inverted:test(101))
  assert(not codes_ranges_inverted:test(151))
end)()

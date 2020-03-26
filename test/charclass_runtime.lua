local base = require("utf8primitives")

local cl = require("charclass.runtime")

local equals = require 'test.util'.equals
local assert = require 'test.util'.assert
local assert_equals = require 'test.util'.assert_equals

debug = print

assert_equals(true, cl.new()
:with_codes(base.byte' ')
:invert()
:in_codes(base.byte' '))

assert_equals(false, cl.new()
:with_codes(base.byte' ')
:invert()
:test(base.byte' '))

assert_equals(false, cl.new()
:with_codes()
:with_ranges()
:with_classes('space')
:without_classes()
:with_subs()
:invert()
:test(base.byte(' ')))

assert_equals(true, cl.new()
:with_codes()
:with_ranges()
:with_classes()
:without_classes('space')
:with_subs()
:invert()
:test(base.byte(' ')))

assert_equals(false, cl.new()
:with_codes()
:with_ranges()
:with_classes()
:without_classes()
:with_subs(cl.new():with_classes('space'))
:invert()
:test(base.byte(' ')))

assert_equals(true, cl.new()
:with_codes()
:with_ranges()
:with_classes()
:without_classes()
:with_subs(cl.new():with_classes('space'):invert())
:invert()
:test(base.byte(' ')))

assert_equals(true, cl.new()
:with_codes()
:with_ranges()
:with_classes('punct', 'digit', 'space', 'cntrl'    )
:without_classes()
:with_subs()
:invert()
:test(base.byte'П')
)

assert_equals(true, cl.new()
:with_codes(208)
:with_ranges()
:with_classes()
:without_classes()
:with_subs()
:test(base.char(208))
)

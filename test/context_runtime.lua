local utf8 = require("init"):init()

local context = utf8:require('context.runtime')

local equals = require('test.util').equals
local assert = require('test.util').assert
local assert_equals = require('test.util').assert_equals

local ctx_en
local ctx_ru
local function setup()
  ctx_en = context.new({str = 'asdf'})
  ctx_ru = context.new({str = 'фыва'})
end

local test_get_char = (function()
  setup()

  assert_equals('a', ctx_en:get_char())
  assert_equals('ф', ctx_ru:get_char())
end)()

local test_get_charcode = (function()
  setup()

  assert_equals(utf8.byte'a', ctx_en:get_charcode())
  assert_equals(utf8.byte'ф', ctx_ru:get_charcode())
end)()

local test_next_char = (function()
  setup()

  assert_equals(1, ctx_en.pos)
  assert_equals(1, ctx_ru.pos)

  ctx_ru:next_char()
  ctx_en:next_char()

  assert_equals(2, ctx_en.pos)
  assert_equals(2, ctx_ru.pos)

  assert_equals('s', ctx_en:get_char())
  assert_equals('ы', ctx_ru:get_char())
  assert_equals(utf8.byte's', ctx_en:get_charcode())
  assert_equals(utf8.byte'ы', ctx_ru:get_charcode())
end)()

local test_clone = (function()
  setup()

  local clone = ctx_en:clone()

  assert(getmetatable(clone) == getmetatable(ctx_en))
  assert_equals(clone, ctx_en)

  ctx_en:next_char()

  assert_equals('a', clone:get_char())
  assert_equals('s', ctx_en:get_char())

end)()

local test_last_char = (function()
  ctx_en = context.new({str = 'asdf', pos = 4})
  ctx_ru = context.new({str = 'фыва', pos = 4})

  assert_equals('f', ctx_en:get_char())
  assert_equals('а', ctx_ru:get_char())

  ctx_ru:next_char()
  ctx_en:next_char()

  assert_equals(5, ctx_en.pos)
  assert_equals(5, ctx_ru.pos)

  assert_equals("", ctx_en:get_char())
  assert_equals("", ctx_ru:get_char())
  assert_equals(nil, ctx_en:get_charcode())
  assert_equals(nil, ctx_ru:get_charcode())
end)()

print('OK')

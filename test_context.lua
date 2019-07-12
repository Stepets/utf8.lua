local context = require('context')

local ctx_en
local ctx_ru
local function setup()
  ctx_en = context.new()
  ctx_en.str = 'asdf'
  ctx_ru = context.new()
  ctx_ru.str = 'фыва'
end

test_get_char = (function()
  setup()

  assert(ctx_en:get_char() == 'a')
  assert(ctx_ru:get_char() == 'ф')
end)()

test_next_char = (function()
  setup()

  assert(ctx_en.pos == 1)
  assert(ctx_ru.pos == 1)

  ctx_ru:next_char()
  ctx_en:next_char()

  assert(ctx_ru.pos == 2)
  assert(ctx_en.pos == 2)

  assert(ctx_en:get_char() == 's')
  assert(ctx_ru:get_char() == 'ы')
end)()

test_clone = (function()
  setup()

  local clone = ctx_en:clone()

  assert(getmetatable(clone) == getmetatable(ctx_en))
  for k, v in pairs(clone) do
    assert(ctx_en[k] == v)
  end
  for k, v in pairs(ctx_en) do
    assert(clone[k] == v)
  end

  clone:next_char()
  assert(clone.pos ~= ctx_en.pos)
end)()

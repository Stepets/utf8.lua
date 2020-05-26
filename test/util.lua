require "test.strict"

local function equals(t1, t2)
  for k,v in pairs(t1) do
    if t2[k] == nil then return false end
    if type(t2[k]) == 'cdata' and type(v) == 'cdata' then
      return true -- don't know how to compare
    elseif type(t2[k]) == 'table' and type(v) == 'table' then
      if not equals(t2[k], v) then return false end
    else
      if t2[k] ~= v then return false end
    end
  end
  for k,v in pairs(t2) do
    if t1[k] == nil then return false end
    if type(t1[k]) == 'cdata' and type(v) == 'cdata' then
      return true -- don't know how to compare
    elseif type(t1[k]) == 'table' and type(v) == 'table' then
      if not equals(t1[k], v) then return false end
    else
      if t1[k] ~= v then return false end
    end
  end
  return true
end

local old_tostring = tostring
local function tostring(v)
  local type = type(v)
  if type == 'table' then
    local tbl = "{"
    for k,v in pairs(v) do
      tbl = tbl .. tostring(k) .. ' = ' .. tostring(v) .. ', '
    end
    return tbl .. '}'
  else
    return old_tostring(v)
  end
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

return {
  equals = equals,
  assert = assert,
  assert_equals = assert_equals,
}

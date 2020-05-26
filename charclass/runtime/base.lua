return function(utf8)

local class = {}
local mt = {__index = class}

local utf8gensub = utf8.gensub

function class.new()
  return setmetatable({}, mt)
end

function class:invert()
  self.inverted = true
  return self
end

function class:with_codes(...)
  local codes = {...}
  self.codes = self.codes or {}

  for _, v in ipairs(codes) do
    table.insert(self.codes, v)
  end

  table.sort(self.codes)
  return self
end

function class:with_ranges(...)
  local ranges = {...}
  self.ranges = self.ranges or {}

  for _, v in ipairs(ranges) do
    table.insert(self.ranges, v)
  end

  return self
end

function class:with_classes(...)
  local classes = {...}
  self.classes = self.classes or {}

  for _, v in ipairs(classes) do
    table.insert(self.classes, v)
  end

  return self
end

function class:without_classes(...)
  local not_classes = {...}
  self.not_classes = self.not_classes or {}

  for _, v in ipairs(not_classes) do
    table.insert(self.not_classes, v)
  end

  return self
end

function class:with_subs(...)
  local subs = {...}
  self.subs = self.subs or {}

  for _, v in ipairs(subs) do
    table.insert(self.subs, v)
  end

  return self
end

function class:in_codes(item)
  if not self.codes or #self.codes == 0 then return nil end

  local head, tail = 1, #self.codes
  local mid = math.floor((head + tail)/2)
  while (tail - head) > 1 do
    if self.codes[mid] > item then
      tail = mid
    else
      head = mid
    end
    mid = math.floor((head + tail)/2)
  end
  if self.codes[head] == item then
    return true, head
  elseif self.codes[tail] == item then
    return true, tail
  else
    return false
  end
end

function class:in_ranges(char_code)
  if not self.ranges or #self.ranges == 0 then return nil end

  for _,r in ipairs(self.ranges) do
    if r[1] <= char_code and char_code <= r[2] then
      return true
    end
  end
  return false
end

function class:in_classes(char_code)
  if not self.classes or #self.classes == 0 then return nil end

  for _, class in ipairs(self.classes) do
    if self:is(class, char_code) then
      return true
    end
  end
  return false
end

function class:in_not_classes(char_code)
  if not self.not_classes or #self.not_classes == 0 then return nil end

  for _, class in ipairs(self.not_classes) do
    if self:is(class, char_code) then
      return true
    end
  end
  return false
end

function class:is(class, char_code)
  error("not implemented")
end

function class:in_subs(char_code)
  if not self.subs or #self.subs == 0 then return nil end

  for _, c in ipairs(self.subs) do
    if not c:test(char_code) then
      return false
    end
  end
  return true
end

function class:test(char_code)
  local result = self:do_test(char_code)
  -- utf8.debug('class:test', result, "'" .. (char_code and utf8.char(char_code) or 'nil') .. "'", char_code)
  return result
end

function class:do_test(char_code)
  if not char_code then return false end
  local in_not_classes = self:in_not_classes(char_code)
  if in_not_classes then
    return not not self.inverted
  end
  local in_codes = self:in_codes(char_code)
  if in_codes then
    return not self.inverted
  end
  local in_ranges = self:in_ranges(char_code)
  if in_ranges then
    return not self.inverted
  end
  local in_classes = self:in_classes(char_code)
  if in_classes then
    return not self.inverted
  end
  local in_subs = self:in_subs(char_code)
  if in_subs then
    return not self.inverted
  end
  if (in_codes == nil)
  and (in_ranges == nil)
  and (in_classes == nil)
  and (in_subs == nil)
  and (in_not_classes == false) then
    return not self.inverted
  else
    return not not self.inverted
  end
end

return class

end

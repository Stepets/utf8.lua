return function(utf8)

local byte = utf8.byte
local unpack = utf8.config.unpack

local builder = {}
local mt = {__index = builder}

utf8.regex.compiletime.charclass.builder = builder

function builder.new()
  return setmetatable({}, mt)
end

function builder:invert()
  self.inverted = true
  return self
end

function builder:internal() -- is it enclosed in []
  self.internal = true
  return self
end

function builder:with_codes(...)
  local codes = {...}
  self.codes = self.codes or {}

  for _, v in ipairs(codes) do
    table.insert(self.codes, type(v) == "number" and v or byte(v))
  end

  table.sort(self.codes)
  return self
end

function builder:with_ranges(...)
  local ranges = {...}
  self.ranges = self.ranges or {}

  for _, v in ipairs(ranges) do
    table.insert(self.ranges, v)
  end

  return self
end

function builder:with_classes(...)
  local classes = {...}
  self.classes = self.classes or {}

  for _, v in ipairs(classes) do
    table.insert(self.classes, v)
  end

  return self
end

function builder:without_classes(...)
  local not_classes = {...}
  self.not_classes = self.not_classes or {}

  for _, v in ipairs(not_classes) do
    table.insert(self.not_classes, v)
  end

  return self
end

function builder:include(b)
  if not b.inverted then
    if b.codes then
      self:with_codes(unpack(b.codes))
    end
    if b.ranges then
      self:with_ranges(unpack(b.ranges))
    end
    if b.classes then
      self:with_classes(unpack(b.classes))
    end
    if b.not_classes then
      self:without_classes(unpack(b.not_classes))
    end
  else
    self.includes = self.includes or {}
    self.includes[#self.includes + 1] = b
  end
  return self
end

function builder:build()
  if self.codes and #self.codes == 1 and not self.inverted and not self.ranges and not self.classes and not self.not_classes and not self.includes then
    return "{test = function(self, cc) return cc == " .. self.codes[1] .. " end}"
  else
    local codes_list = table.concat(self.codes or {}, ', ')
    local ranges_list = ''
    for i, r in ipairs(self.ranges or {}) do ranges_list = ranges_list .. (i > 1 and ', {' or '{') .. tostring(r[1]) .. ', ' .. tostring(r[2]) .. '}' end
    local classes_list = ''
    if self.classes then classes_list = "'" .. table.concat(self.classes, "', '") .. "'" end
    local not_classes_list = ''
    if self.not_classes then not_classes_list = "'" .. table.concat(self.not_classes, "', '") .. "'" end

    local subs_list = ''
    for i, r in ipairs(self.includes or {}) do subs_list = subs_list .. (i > 1 and ', ' or '') .. r:build() .. '' end

    local src = [[cl.new():with_codes(
        ]] .. codes_list .. [[
      ):with_ranges(
        ]] .. ranges_list .. [[
      ):with_classes(
        ]] .. classes_list .. [[
      ):without_classes(
        ]] .. not_classes_list .. [[
      ):with_subs(
        ]] .. subs_list .. [[
      )]]

    if self.inverted then
      src = src .. ':invert()'
    end

    return src
  end
end

return builder

end

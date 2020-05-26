return function(utf8)

local utf8unicode = utf8.unicode
local utf8sub = utf8.sub
local sub = utf8.raw.sub
local byte = utf8.raw.byte
local utf8len = utf8.len
local utf8next = utf8.next
local rawgsub = utf8.raw.gsub
local utf8offset = utf8.offset
local utf8char = utf8.char

local util = utf8.util

local ctx = {}
local mt = {
  __index = ctx,
  __tostring = function(self)
    return rawgsub([[str: '${str}', char: ${pos} '${char}', func: ${func_pos}]], "${(.-)}", {
      str = self.str,
      pos = self.pos,
      char = self:get_char(),
      func_pos = self.func_pos,
    })
  end
}

function ctx.new(obj)
  obj = obj or {}
  local res = setmetatable({
    pos = obj.pos or 1,
    byte_pos = obj.pos or 1,
    str = assert(obj.str, "str is required"),
    len = obj.len,
    rawlen = obj.rawlen,
    bytes = obj.bytes,
    offsets = obj.offsets,
    starts = obj.starts or nil,
    functions = obj.functions or {},
    func_pos = obj.func_pos or 1,
    ends = obj.ends or nil,
    result = obj.result and util.copy(obj.result) or {},
    captures = obj.captures and util.copy(obj.captures, true) or {active = {}},
    modified = false,
  }, mt)
  if not res.bytes then
    local str = res.str
    local l = #str
    local bytes = utf8.config.int32array(l)
    local offsets = utf8.config.int32array(l)
    local c, bs, i = nil, 1, 1
    while bs <= l do
      bytes[i] = utf8unicode(str, bs, bs)
      offsets[i] = bs
      bs = utf8.next(str, bs)
      i = i + 1
    end
    res.bytes = bytes
    res.offsets = offsets
    res.byte_pos = res.pos
    res.len = i
    res.rawlen = l
  end

  return res
end

function ctx:clone()
  return self:new()
end

function ctx:next_char()
  self.pos = self.pos + 1
  self.byte_pos = self.pos
end

function ctx:prev_char()
  self.pos = self.pos - 1
  self.byte_pos = self.pos
end

function ctx:get_char()
  if self.len <= self.pos then return "" end
  return utf8char(self.bytes[self.pos])
end

function ctx:get_charcode()
  if self.len <= self.pos then return nil end
  return self.bytes[self.pos]
end

function ctx:next_function()
  self.func_pos = self.func_pos + 1
end

function ctx:get_function()
  return self.functions[self.func_pos]
end

function ctx:done()
  utf8.debug('done', self)
  coroutine.yield(self, self.result, self.captures)
end

function ctx:terminate()
  utf8.debug('terminate', self)
  coroutine.yield(nil)
end

return ctx

end

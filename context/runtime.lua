return function(utf8)

local utf8unicode = utf8.unicode
local utf8sub = utf8.sub
local sub = utf8.raw.sub
local byte = utf8.raw.byte
local utf8len = utf8.len
local utf8next = utf8.next
local rawgsub = utf8.raw.gsub
local utf8offset = utf8.offset

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
    byte_pos = obj.byte_pos,
    prev_byte_pos = obj.prev_byte_pos,
    str = assert(obj.str, "str is required"),
    len = obj.len or utf8.raw.len(obj.str),
    starts = obj.starts or nil,
    functions = obj.functions or {},
    func_pos = obj.func_pos or 1,
    ends = obj.ends or nil,
    result = obj.result and util.copy(obj.result) or {},
    captures = obj.captures and util.copy(obj.captures, true) or {active = {}},
  }, mt)
  if not res.byte_pos then
    res.pos = 0
    res.byte_pos = 0
    for i = 1, (obj.pos or 1) do
      res:next_char()
    end
  end

  return res
end

function ctx:clone()
  return self:new()
end

function ctx:next_char()
  self.pos = self.pos + 1
  self.prev_byte_pos = self.byte_pos
  self.byte_pos = math.max(utf8.next(self.str, self.byte_pos), self.byte_pos + 1)
end

function ctx:prev_char()
  self.pos = self.pos - 1
  if self.prev_byte_pos then
    self.byte_pos = self.prev_byte_pos
    self.prev_byte_pos = nil
  else
    self.byte_pos = self.byte_pos - 1
    while true do
      local b = byte(self.str, self.byte_pos)
      if not b or (0 < b and b < 127)
      or (194 < b and b < 244) then
        return
      end
      self.byte_pos = self.byte_pos - 1
      if self.byte_pos < 1 then
        return
      end
    end
  end
end

function ctx:get_char()
  return sub(self.str, self.byte_pos, utf8.next(self.str, self.byte_pos) - 1)
end

function ctx:get_charcode()
  if self.len < self.byte_pos then return nil end
  return utf8unicode(self.str, self.byte_pos, self.byte_pos)
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

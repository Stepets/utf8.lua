local utf8 = require "utf8primitives"
local utf8unicode = utf8.byte
local utf8sub = utf8.sub
local utf8len = utf8.len
local rawgsub = utf8.raw.gsub

local util = require "util"

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
  return setmetatable({
    pos = obj.pos or 1,
    str = obj.str or nil,
    starts = obj.starts or nil,
    functions = obj.functions or {},
    func_pos = obj.func_pos or 1,
    ends = obj.ends or nil,
    result = obj.result and util.copy(obj.result) or {},
    captures = obj.captures and util.copy(obj.captures, true) or {active = {}},
  }, mt)
end

function ctx:clone()
  return self:new()
end

function ctx:next_char()
  self.pos = self.pos + 1
end

function ctx:get_char()
  return utf8sub(self.str, self.pos, self.pos)
end

function ctx:get_charcode()
  if utf8len(self.str) < self.pos then return nil end
  return utf8unicode(self:get_char())
end

function ctx:next_function()
  self.func_pos = self.func_pos + 1
end

function ctx:get_function()
  return self.functions[self.func_pos]
end

function ctx:done()
  debug('done', self)
  coroutine.yield(self, self.result, self.captures)
end

function ctx:terminate()
  debug('terminate', self)
  coroutine.yield(nil)
end

return ctx

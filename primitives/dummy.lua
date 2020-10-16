-- $Id: utf8.lua 179 2009-04-03 18:10:03Z pasta $
--
-- Provides UTF-8 aware string functions implemented in pure lua:
-- * utf8len(s)
-- * utf8sub(s, i, j)
-- * utf8reverse(s)
-- * utf8char(unicode)
-- * utf8unicode(s, i, j)
-- * utf8gensub(s, sub_len)
-- * utf8find(str, regex, init, plain)
-- * utf8match(str, regex, init)
-- * utf8gmatch(str, regex, all)
-- * utf8gsub(str, regex, repl, limit)
--
-- If utf8data.lua (containing the lower<->upper case mappings) is loaded, these
-- additional functions are available:
-- * utf8upper(s)
-- * utf8lower(s)
--
-- All functions behave as their non UTF-8 aware counterparts with the exception
-- that UTF-8 characters are used instead of bytes for all units.

--[[
Copyright (c) 2006-2007, Kyle Smith
All rights reserved.

Contributors:
	Alimov Stepan

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be
      used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

-- ABNF from RFC 3629
--
-- UTF8-octets = *( UTF8-char )
-- UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
-- UTF8-1      = %x00-7F
-- UTF8-2      = %xC2-DF UTF8-tail
-- UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
--               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
-- UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
--               %xF4 %x80-8F 2( UTF8-tail )
-- UTF8-tail   = %x80-BF
--
return function(utf8)

local byte    = string.byte
local char    = string.char
local dump    = string.dump
local find    = string.find
local format  = string.format
local len     = string.len
local lower   = string.lower
local rep     = string.rep
local sub     = string.sub
local upper   = string.upper

local function utf8symbollen(byte)
  return not byte and 0 or (byte < 0x80 and 1) or (byte >= 0xF0 and 4) or (byte >= 0xE0 and 3) or (byte >= 0xC0 and 2) or 1
end

local head_table = utf8.config.int32array(256)
for i = 0, 255 do
  head_table[i] = utf8symbollen(i)
end
head_table[256] = 0

local function utf8charbytes(str, bs)
  return head_table[byte(str, bs) or 256]
end

local function utf8next(str, bs)
  return bs + utf8charbytes(str, bs)
end

-- returns the number of characters in a UTF-8 string
local function utf8len (str)
  local bs = 1
  local bytes = len(str)
  local length = 0

  while bs <= bytes do
    length = length + 1
    bs = utf8next(str, bs)
  end

  return length
end

-- functions identically to string.sub except that i and j are UTF-8 characters
-- instead of bytes
local function utf8sub (s, i, j)
  -- argument defaults
  j = j or -1

  local bs = 1
  local bytes = len(s)
  local length = 0

  local l = (i >= 0 and j >= 0) or utf8len(s)
  i = (i >= 0) and i or l + i + 1
  j = (j >= 0) and j or l + j + 1

  if i > j then
    return ""
  end

  local start, finish = 1, bytes

  while bs <= bytes do
    length = length + 1

    if length == i then
      start = bs
    end

    bs = utf8next(s, bs)

    if length == j then
      finish = bs - 1
      break
    end
  end

  if i > length then start = bytes + 1 end
  if j < 1 then finish = 0 end

  return sub(s, start, finish)
end

-- http://en.wikipedia.org/wiki/Utf8
-- http://developer.coronalabs.com/code/utf-8-conversion-utility
local function utf8char(...)
  local codes = {...}
  local result = {}

  for _, unicode in ipairs(codes) do

    if unicode <= 0x7F then
      result[#result + 1] = unicode
    elseif unicode <= 0x7FF then
      local b0 = 0xC0 + math.floor(unicode / 0x40);
      local b1 = 0x80 + (unicode % 0x40);
      result[#result + 1] = b0
      result[#result + 1] = b1
    elseif unicode <= 0xFFFF then
      local b0 = 0xE0 +  math.floor(unicode / 0x1000);
      local b1 = 0x80 + (math.floor(unicode / 0x40) % 0x40);
      local b2 = 0x80 + (unicode % 0x40);
      result[#result + 1] = b0
      result[#result + 1] = b1
      result[#result + 1] = b2
    elseif unicode <= 0x10FFFF then
      local code = unicode
      local b3= 0x80 + (code % 0x40);
      code       = math.floor(code / 0x40)
      local b2= 0x80 + (code % 0x40);
      code       = math.floor(code / 0x40)
      local b1= 0x80 + (code % 0x40);
      code       = math.floor(code / 0x40)
      local b0= 0xF0 + code;

      result[#result + 1] = b0
      result[#result + 1] = b1
      result[#result + 1] = b2
      result[#result + 1] = b3
    else
      error 'Unicode cannot be greater than U+10FFFF!'
    end

  end

  return char(utf8.config.unpack(result))
end


local shift_6  = 2^6
local shift_12 = 2^12
local shift_18 = 2^18

local utf8unicode
utf8unicode = function(str, ibs, jbs)
  if ibs > jbs then return end

  local ch,bytes

  bytes = utf8charbytes(str, ibs)
  if bytes == 0 then return end

  local unicode

  if bytes == 1 then unicode = byte(str, ibs, ibs) end
  if bytes == 2 then
    local byte0,byte1 = byte(str, ibs, ibs + 1)
    if byte0 and byte1 then
      local code0,code1 = byte0-0xC0,byte1-0x80
      unicode = code0*shift_6 + code1
    else
      unicode = byte0
    end
  end
  if bytes == 3 then
    local byte0,byte1,byte2 = byte(str, ibs, ibs + 2)
    if byte0 and byte1 and byte2 then
      local code0,code1,code2 = byte0-0xE0,byte1-0x80,byte2-0x80
      unicode = code0*shift_12 + code1*shift_6 + code2
    else
      unicode = byte0
    end
  end
  if bytes == 4 then
    local byte0,byte1,byte2,byte3 = byte(str, ibs, ibs + 3)
    if byte0 and byte1 and byte2 and byte3 then
      local code0,code1,code2,code3 = byte0-0xF0,byte1-0x80,byte2-0x80,byte3-0x80
      unicode = code0*shift_18 + code1*shift_12 + code2*shift_6 + code3
    else
      unicode = byte0
    end
  end

  if ibs == jbs then
    return unicode
  else
    return unicode,utf8unicode(str, ibs+bytes, jbs)
  end
end

local function utf8byte(str, i, j)
  if #str == 0 then return end

  local ibs, jbs

  if i or j then
    i = i or 1
    j = j or i

    local str_len = utf8len(str)
    i = i < 0 and str_len + i + 1 or i
    j = j < 0 and str_len + j + 1 or j
    j = j > str_len and str_len or j

    if i > j then return end

    for p = 1, i - 1 do
      ibs = utf8next(str, ibs or 1)
    end

    if i == j then
      jbs = ibs
    else
      for p = 1, j - 1 do
        jbs = utf8next(str, jbs or 1)
      end
    end

    if not ibs or not jbs then
      return nil
    end
  else
    ibs, jbs = 1, 1
  end

  return utf8unicode(str, ibs, jbs)
end

local function utf8gensub(str, sub_len)
  sub_len = sub_len or 1
  local max_len = #str
  return function(skip_ptr, bs)
    bs = (bs and bs or 1) + (skip_ptr and (skip_ptr[1] or 0) or 0)

    local nbs = bs
    if bs > max_len then return nil end
    for i = 1, sub_len do
      nbs = utf8next(str, nbs)
    end

    return nbs, sub(str, bs, nbs - 1), bs
  end
end

local function utf8reverse (s)
  local result = ''
  for _, w in utf8gensub(s) do result = w .. result end
  return result
end

local function utf8validator(str, bs)
  bs = bs or 1

  if type(str) ~= "string" then
    error("bad argument #1 to 'utf8charbytes' (string expected, got ".. type(str).. ")")
  end
  if type(bs) ~= "number" then
    error("bad argument #2 to 'utf8charbytes' (number expected, got ".. type(bs).. ")")
  end

  local c = byte(str, bs)
  if not c then return end

  -- determine bytes needed for character, based on RFC 3629

  -- UTF8-1
  if c >= 0 and c <= 127 then
    return bs + 1
  elseif c >= 128 and c <= 193 then
    return bs + 1, bs, 1, c
      -- UTF8-2
  elseif c >= 194 and c <= 223 then
    local c2 = byte(str, bs + 1)
    if not c2 or c2 < 128 or c2 > 191 then
      return bs + 2, bs, 2, c2
    end

    return bs + 2
      -- UTF8-3
  elseif c >= 224 and c <= 239 then
    local c2 = byte(str, bs + 1)

    if not c2 then
      return bs + 2, bs, 2, c2
    end

    -- validate byte 2
    if c == 224 and (c2 < 160 or c2 > 191) then
      return bs + 2, bs, 2, c2
    elseif c == 237 and (c2 < 128 or c2 > 159) then
      return bs + 2, bs, 2, c2
    elseif c2 < 128 or c2 > 191 then
      return bs + 2, bs, 2, c2
    end

    local c3 = byte(str, bs + 2)
    if not c3 or c3 < 128 or c3 > 191 then
      return bs + 3, bs, 3, c3
    end

    return bs + 3
      -- UTF8-4
  elseif c >= 240 and c <= 244 then
    local c2 = byte(str, bs + 1)

    if not c2 then
      return bs + 2, bs, 2, c2
    end

    -- validate byte 2
    if c == 240 and (c2 < 144 or c2 > 191) then
      return bs + 2, bs, 2, c2
    elseif c == 244 and (c2 < 128 or c2 > 143) then
      return bs + 2, bs, 2, c2
    elseif c2 < 128 or c2 > 191 then
      return bs + 2, bs, 2, c2
    end

    local c3 = byte(str, bs + 2)
    if not c3 or c3 < 128 or c3 > 191 then
      return bs + 3, bs, 3, c3
    end

    local c4 = byte(str, bs + 3)
    if not c4 or c4 < 128 or c4 > 191 then
      return bs + 4, bs, 4, c4
    end

    return bs + 4
  else -- c > 245
    return bs + 1, bs, 1, c
  end
end

local function utf8validate(str, byte_pos)
  local result = {}
  for nbs, bs, part, code in utf8validator, str, byte_pos do
    if bs then
      result[#result + 1] = { pos = bs, part = part, code = code }
    end
  end
  return #result == 0, result
end

local function utf8codes(str)
  local max_len = #str
  local bs = 1
  return function(skip_ptr)
    if bs > max_len then return nil end
    local pbs = bs
    bs = utf8next(str, pbs)

    return pbs, utf8unicode(str, pbs, pbs), pbs
  end
end


--[[--
differs from Lua 5.3 utf8.offset in accepting any byte positions (not only head byte) for all n values

h - head, c - continuation, t - tail
hhhccthccthccthcthhh
        ^ start byte pos
searching current charracter head by moving backwards
hhhccthccthccthcthhh
      ^ head

n == 0: current position
n > 0: n jumps forward
n < 0: n more scans backwards
--]]--
local function utf8offset(str, n, bs)
  local l = #str
  if not bs then
    if n < 0 then
      bs = l + 1
    else
      bs = 1
    end
  end
  if bs <= 0 or bs > l + 1 then
    error("bad argument #3 to 'offset' (position out of range)")
  end

  if n == 0 then
    if bs == l + 1 then
      return bs
    end
    while true do
      local b = byte(str, bs)
      if (0 < b and b < 127)
      or (194 < b and b < 244) then
        return bs
      end
      bs = bs - 1
      if bs < 1 then
        return
      end
    end
  elseif n < 0 then
    bs = bs - 1
    repeat
      if bs < 1 then
        return
      end

      local b = byte(str, bs)
      if (0 < b and b < 127)
      or (194 < b and b < 244) then
        n = n + 1
      end
      bs = bs - 1
    until n == 0
    return bs + 1
  else
    while true do
      if bs > l then
        return
      end

      local b = byte(str, bs)
      if (0 < b and b < 127)
      or (194 < b and b < 244) then
        n = n - 1
        for i = 1, n do
          if bs > l then
            return
          end
          bs = utf8next(str, bs)
        end
        return bs
      end
      bs = bs - 1
    end
  end

end

utf8.len       = utf8len
utf8.sub       = utf8sub
utf8.reverse   = utf8reverse
utf8.char      = utf8char
utf8.unicode   = utf8unicode
utf8.byte      = utf8byte
utf8.next      = utf8next
utf8.gensub    = utf8gensub
utf8.validator = utf8validator
utf8.validate  = utf8validate
utf8.dump      = dump
utf8.format    = format
utf8.lower     = lower
utf8.upper     = upper
utf8.rep       = rep
utf8.raw = {}
for k,v in pairs(string) do
  utf8.raw[k] = v
end

utf8.charpattern = '[\0-\127\194-\244][\128-\191]*'
utf8.offset = utf8offset
if _VERSION == 'Lua 5.3' then
  local utf8_53 = require "utf8"
  utf8.codes = utf8_53.codes
  utf8.codepoint = utf8_53.codepoint
  utf8.len53 = utf8_53.len
else
  utf8.codes = utf8codes
  utf8.codepoint = utf8unicode
end

return utf8

end

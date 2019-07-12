local class = {}
local mt = {__index = class}

local utf8gensub = require ".utf8".gensub
local utf8unicode = require ".utf8".unicode

function class.new()
  return setmetatable({}, mt)
end

function class:invert()
  self.inverted = true
  return self
end

function class:with_codes(...)
  self.codes = {...}
  table.sort(self.codes)
  return self
end

function class:with_ranges(...)
  self.ranges = {...}
  return self
end

function class:binsearch(item)
  if not self.codes then return false end

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

function class:inRanges(charCode)
  if not self.ranges then return false end

  for _,r in ipairs(self.ranges) do
    if r[1] <= charCode and charCode <= r[2] then
      return true
    end
  end
  return false
end

function class:test(charCode)
  local result = self:do_test(charCode)
  debug('class:test', result, "'" .. (charCode and utf8.char(charCode) or 'nil') .. "'")
  return result
end

function class:do_test(charCode)
  if not charCode then return false end
  if not self.inverted then
    return self:binsearch(charCode) or self:inRanges(charCode)
  else
    return not (self:binsearch(charCode) or self:inRanges(charCode))
  end
end

function class.parse(cl, plain)
  local res = {class.do_parse(cl, plain)}

  debug(table.unpack(res))

  return table.unpack(res)
end

function class.do_parse(class, plain)
	local codes = {}
	local ranges = {}
	local ignore = false
	local range = false
	local firstletter = true
	local unmatch = false

	local it = utf8gensub(class)

	local skip
	for c, _, be in it do
    debug('cl:parse', c, ignore, plain)
		skip = be
		if not ignore and not plain then
			if c == "%" then
				ignore = true
			elseif c == "-" then
				table.insert(codes, utf8unicode(c))
				range = true
			elseif c == "^" then
				if not firstletter then
					error('!!!')
				else
					unmatch = true
				end
			elseif c == ']' then
				break
			else
				if not range then
					table.insert(codes, utf8unicode(c))
				else
					table.remove(codes) -- removing '-'
					table.insert(ranges, {table.remove(codes), utf8unicode(c)})
					range = false
				end
			end
		elseif ignore and not plain then
			if c == 'a' then -- %a: represents all letters. (ONLY ASCII)
				table.insert(ranges, {65, 90}) -- A - Z
				table.insert(ranges, {97, 122}) -- a - z
			elseif c == 'c' then -- %c: represents all control characters.
				table.insert(ranges, {0, 31})
				table.insert(codes, 127)
			elseif c == 'd' then -- %d: represents all digits.
				table.insert(ranges, {48, 57}) -- 0 - 9
			elseif c == 'g' then -- %g: represents all printable characters except space.
				table.insert(ranges, {1, 8})
				table.insert(ranges, {14, 31})
				table.insert(ranges, {33, 132})
				table.insert(ranges, {134, 159})
				table.insert(ranges, {161, 5759})
				table.insert(ranges, {5761, 8191})
				table.insert(ranges, {8203, 8231})
				table.insert(ranges, {8234, 8238})
				table.insert(ranges, {8240, 8286})
				table.insert(ranges, {8288, 12287})
			elseif c == 'l' then -- %l: represents all lowercase letters. (ONLY ASCII)
				table.insert(ranges, {97, 122}) -- a - z
			elseif c == 'p' then -- %p: represents all punctuation characters. (ONLY ASCII)
				table.insert(ranges, {33, 47})
				table.insert(ranges, {58, 64})
				table.insert(ranges, {91, 96})
				table.insert(ranges, {123, 126})
			elseif c == 's' then -- %s: represents all space characters.
				table.insert(ranges, {9, 13})
				table.insert(codes, 32)
				table.insert(codes, 133)
				table.insert(codes, 160)
				table.insert(codes, 5760)
				table.insert(ranges, {8192, 8202})
				table.insert(codes, 8232)
				table.insert(codes, 8233)
				table.insert(codes, 8239)
				table.insert(codes, 8287)
				table.insert(codes, 12288)
			elseif c == 'u' then -- %u: represents all uppercase letters. (ONLY ASCII)
				table.insert(ranges, {65, 90}) -- A - Z
			elseif c == 'w' then -- %w: represents all alphanumeric characters. (ONLY ASCII)
				table.insert(ranges, {48, 57}) -- 0 - 9
				table.insert(ranges, {65, 90}) -- A - Z
				table.insert(ranges, {97, 122}) -- a - z
			elseif c == 'x' then -- %x: represents all hexadecimal digits.
				table.insert(ranges, {48, 57}) -- 0 - 9
				table.insert(ranges, {65, 70}) -- A - F
				table.insert(ranges, {97, 102}) -- a - f
			else
				if not range then
					table.insert(codes, utf8unicode(c))
				else
					table.remove(codes) -- removing '-'
					table.insert(ranges, {table.remove(codes), utf8unicode(c)})
					range = false
				end
			end
			ignore = false
		else
			if not range then
				table.insert(codes, utf8unicode(c))
			else
				table.remove(codes) -- removing '-'
				table.insert(ranges, {table.remove(codes), utf8unicode(c)})
				range = false
			end
			ignore = false
		end

		firstletter = false
	end

	table.sort(codes)

  local codes_list = table.concat(codes, ', ')
  local ranges_list = ''
  for i, r in ipairs(ranges) do ranges_list = ranges_list .. (i > 1 and ', {' or '{') .. tostring(r[1]) .. ', ' .. tostring(r[2]) .. '}' end

	if not unmatch then
		return [[cl.new():with_codes(
				]] .. codes_list .. [[
			):with_ranges(
				]] .. ranges_list .. [[
			)]]
		, skip
	else
		return [[cl.new():invert():with_codes(
				]] .. codes_list .. [[
			):with_ranges(
				]] .. ranges_list .. [[
			)]]
		, skip
	end
end

return class

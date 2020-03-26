local class = {}

function class.parse(cl, plain)
  local res = {class.do_parse(cl, plain)}

  debug(table.unpack(res))

  return table.unpack(res)
end

function class.do_parse(class, plain)
	local codes = {}
	local ranges = {}
  local classes = {}
	local ignore = false
	local range = false
	local firstletter = true
	local invert = false

	local skip
	for nbs, c in utf8gensub(class) do
    debug('cl:parse', c, ignore, plain)
		skip = nbs - 1
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
					invert = true
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
			if c == 'a' then
				table.insert(classes, 'alpha')
			elseif c == 'c' then
				table.insert(classes, 'cntrl')
			elseif c == 'd' then
				table.insert(classes, 'digit')
			elseif c == 'g' then
				table.insert(classes, 'graph')
			elseif c == 'l' then
				table.insert(classes, 'lower')
			elseif c == 'p' then
				table.insert(classes, 'punct')
			elseif c == 's' then
				table.insert(classes, 'space')
			elseif c == 'u' then
				table.insert(classes, 'upper')
			elseif c == 'w' then
				table.insert(classes, 'alnum')
			elseif c == 'x' then
				table.insert(classes, 'xdigit')
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
  local classes_list = "'" .. table.concat(classes, "', '") .. "'"

  local src = [[cl.new():with_codes(
      ]] .. codes_list .. [[
    ):with_ranges(
      ]] .. ranges_list .. [[
    ):with_classes(
      ]] .. classes_list .. [[
    )]]

	if invert then
		src = src .. ':invert()'
	end

  return src, skip
end

return class

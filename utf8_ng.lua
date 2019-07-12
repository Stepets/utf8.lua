local function switch(val, cases)
	(cases[val] or cases.default or function()end)(cases)
end

local MatchState = {
	new = function ()
		return {
			src = nil,
			src_init = 0,
			src_end = 0,
			p = nil,
			p_end = 0,
			level = 1,
			capture = {{
				init = 0,
				len = 0
			}}
		}
	end
}

local CAP_POSITION = {}
local CAP_UNFINISHED = {}

local FAIL = {}

local match

local function check_capture (ms, l)
	l = l - uchar('1');
	if (l < 0 or l >= ms.level or ms.capture[l].len == CAP_UNFINISHED) then
		return error([[invalid capture index %d]], l + 1);
	end
	return l;
end


local function capture_to_close (ms)
	local level = ms.level;
	for l = level, 1, -1 do
		if (ms.capture[l].len == CAP_UNFINISHED) then return l end
	end
	error("invalid pattern capture");
end


local function classend (ms, p)
	p = p + 1;
	local val = ms.p[p];
	if val == uchar('%') then
		if (p == ms.p_end) then
			error([[malformed pattern (ends with '%')]]);
		end
		return p + 1;
	elseif val == uchar('[') then
		if (ms.p[p] == '^') then
			p = p + 1
		end
		repeat -- look for a ']'
			if (p == ms.p_end) then
				error([[malformed pattern (missing ']')]]);
			end
			p = p + 1
			if (ms.p[p] == uchar('%') and p < ms.p_end) then
				p = p + 1 -- skip escapes (e.g. '%]')
			end
		until (ms.p[p] ~= uchar(']'));
		return p + 1;
	end
	return p;
end


local function match_class (c, cl) {
	local res;
	local plain = false
	local val = tolower(cl)
	if val == 'a' then
		res = isalpha(c)
	elseif val == 'c' then
		res = iscntrl(c)
	elseif val == 'd' then
		res = isdigit(c)
	elseif val == 'g' then
		res = isgraph(c)
	elseif val == 'l' then
		res = islower(c)
	elseif val == 'p' then
		res = ispunct(c)
	elseif val == 's' then
		res = isspace(c)
	elseif val == 'u' then
		res = isupper(c)
	elseif val == 'w' then
		res = isalnum(c)
	elseif val == 'x' then
		res = isxdigit(c)
	elseif val == 'z' then
		res = (c == 0) -- deprecated option
	else
		return cl == c
	end
	if islower(cl) then return res else return not res end
}


local function matchbracketclass (ms, c, p, ec) {
  local sig = true;
  if (ms.p[p+1] == '^') then
    sig = false;
    p = p + 1 -- skip the '^'
  end
  p = p + 1
  while (p < ec) do
    if (ms.p[p] == '%') then
      p = p + 1;
      if (match_class(c, uchar(ms.p[p]))) then
        return sig;
	  end
    elseif ((ms.p[p+1] == '-') and (p+2 < ec)) then
      p = p + 2;
      if (uchar(ms.p[p-2]) <= c and c <= uchar(ms.p[p])) then
        return sig;
	  end
    elseif (uchar(ms.p[p]) == c) then return sig; end
	p = p + 1
  end
  return not sig;
}


local function singlematch (ms, s, p, ep)
  if (s >= ms.src_end) then
    return 0;
  else
    local c = uchar(ms.src[s]);
	local val = ms.p[p];
	if val == '.' then return true -- matches any char
	elseif val == '%' then return match_class(c, uchar(ms.p[p+1]))
	elseif val == '[' then return matchbracketclass(ms, c, p, ep-1)
	else return (uchar(val) == c) end
  end
end


local function matchbalance (ms, s, p) {
  if (p >= ms.p_end - 1) then
    error("malformed pattern (missing arguments to '%%b')");
  end
  if (ms.src[s] ~= ms.p[p]) then
	  return FAIL;
  else
    local b = ms.p[p];
    local e = ms.[p+1];
    local cont = 1;
	s = s + 1
    while (s < ms->src_end) do
      if (ms.src[s] == e) then
		  cont = cont - 1
        if (cont == 0) then
			return s+1;
		end
	  elseif (ms.src[s] == b) then
		cont = cont + 1;
	  end
	  s = s + 1
	end
  end
  return FAIL;  -- string ends out of balance
}


local function max_expand (ms, s, p, ep) {
  local i = 0;  -- counts maximum expand for item
  while (singlematch(ms, s + i, p, ep)) do
    i = i + 1;
  end
  -- keeps trying to match with the maximum repetitions
  while (i>=0) {
    local res = match(ms, ms.str[s+i], ep+1);
    if (res) then return res; end
    i = i - 1;  -- else didn't match; reduce 1 repetition to try again
  }
  return FAIL;
}


local function min_expand (ms, s, p, ep)
	while (true) do
		local res = match(ms, s, ep+1);
		if (res ~= FAIL) then
			return res;
		elseif (singlematch(ms, s, p, ep)) then
			s = s + 1;  -- try with one more repetition */
		else
			return FAIL;
		end
	end
end


local function start_capture(match_state, src_pos, pat_pos, what)
	local level = match_state.level;
	match_state.capture[level].init = s;
	match_state.capture[level].len = what;
	match_state.level = level + 1;
	local res = match(match_state, src_pos, pat_pos;
	if (res == FAIL) then
		match_state.level = match_state.level - 1;  -- undo capture
	end
	return res;
end

local function end_capture (match_state, src_pos, pat_pos)
	local l = capture_to_close(match_state);
	match_state.capture[l].len = src_pos - match_state.capture[l].init; -- close capture
	local res = match(match_state, src_pos, pat_pos)
	if (res == FAIL) then
		match_state->capture[l].len = CAP_UNFINISHED -- undo capture
	end
	return res;
end


local function match_capture (match_state, src_pos, l)
	l = check_capture(match_state, l);
	local len = match_state.capture[l].len;
	if ((match_state.src_end - src_pos) >= len
	and equals(match_state.src, match_state->capture[l].init, src_pos, len)) then
		return src_pos + len;
	else
		return FAIL
	end
end


function match(match_state, src_pos, pat_pos)
	local function p(offset) return match_state.p[pat_pos + (offset or 0)] end
	local function s(offset) return match_state.src[src_pos + (offset or 0)] end
	if (pat_pos ~= match_state.p_end) then
		switch( p(), {
			'(' = function ()
				if (p(+1) == ')') then
					src_pos = start_capture(match_state, src_pos, pat_pos + 2, CAP_POSITION);
				else
					src_pos = start_capture(match_state, src_pos, pat_pos + 1, CAP_UNFINISHED);
				end
			end,
			')' = function ()
				src_pos = end_capture(match_state, src_pos, pat_pos + 1);
			end,
			'$' = function (self)
				if ((pat_pos + 1) ~= match_state.p_end) then -- is the '$' the last char in pattern?
					self:default()
				else
					src_pos = (src_pos == match_state.src_end) and src_pos or FAIL
				end
			end,
			'%' = function(self)  -- escaped sequences not in the format class[*+?-]?
				switch( p(+1), {
					'b' = function()
						src_pos = matchbalance(match_state, src_pos, pat_pos + 2);
						if (src_pos ~= FAIL) then
							src_pos = match(match_state, src_pos, pat_pos + 4);
						end
					end,
					'f' = function()
						local end_pat_pos
						local previous
						pat_pos = pat_pos + 2
						if (p() ~= '[') then
							error([[missing '[' after '%f' in pattern]]);
						end
						end_pat_pos = classend(match_state, pat_pos);  -- points to what is next
						previous_charcode = (src_pos == match_state.src_init) and 0 or uchar(s(-1))
						if (not matchbracketclass(match_state, previous_charcode, pat_pos, end_pat_pos - 1)
						and matchbracketclass(match_state, uchar(s()), pat_pos, end_pat_pos - 1)) then
							src_pos = match(match_state, src_pos, end_pat_pos)
						else
							src_pos = FAIL;
						end
					end,
					'0' = function(self) self['9'](self) end,
					'1' = function(self) self['9'](self) end,
					'2' = function(self) self['9'](self) end,
					'3' = function(self) self['9'](self) end,
					'4' = function(self) self['9'](self) end,
					'5' = function(self) self['9'](self) end,
					'6' = function(self) self['9'](self) end,
					'7' = function(self) self['9'](self) end,
					'8' = function(self) self['9'](self) end,
					'9' = function() -- capture results (%0-%9)
						src_pos = match_capture(match_state, src_pos, uchar(p(+1)));
						if (src_pos ~= FAIL) then
							 src_pos = match(match_state, src_pos, pat_pos + 2)
						end,
						default = function() self:default() end
					end,
				})
			end,
			default = function()   -- pattern class plus optional suffix
				local end_pat_pos = classend(match_state, pat_pos);  -- points to optional suffix
				local ep = function() return match_state.p[end_pat_pos] end

				if (not singlematch(match_state, src_pos, pat_pos, end_pat_pos)) then
					if (ep() == '*' or ep() == '?' or ep() == '-') then -- accept empty?
						src_pos = match(match_state, src_pos, end_pat_pos + 1);
					end -- '+' or no suffix
					s = FAIL
				else -- matched once
					switch( ep(), { -- handle optional suffix
						'?' = function() -- optional
							local res = match(match_state, src_pos + 1, end_pat_pos + 1)
							if (res ~= FAIL) then
								src_pos = res;
							else
								src_pos = match(match_state, src_pos, end_pat_pos + 1);
							end
						end,
						'+' = function (self) -- 1 or more repetitions
							src_pos = src_pos + 1 --  1 match already done
							self['*'](self)
						end,
						'*' = function () -- 0 or more repetitions
							src_pos = max_expand(match_state, src_pos, pat_pos, end_pat_pos);
						end,
						'-' = function () -- 0 or more repetitions (minimum)
							src_pos = min_expand(match_state, src_pos, pat_pos, end_pat_pos);
						end,
						default = function () -- no suffix
							src_pos = match(match_state, src_pos + 1, end_pat_pos);
						end
					})
				end
			end
        end
    })
  end
  return src_pos;
end

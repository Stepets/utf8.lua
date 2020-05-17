return function(utf8)

local cl = utf8:require "charclass.compiletime.builder"

local next = utf8.util.next

local token = 1

local function parse(str, c, bs, ctx)
  local tttt = token
  token = token + 1

  local class
  local nbs = bs
  utf8.debug("cc_parse", tttt, str, c, nbs, next(str, nbs))

  if c == '%' then
    c, nbs = next(str, bs)
    if c == '' then
      error("malformed pattern (ends with '%')")
    end
    local _c = utf8.raw.lower(c)
    local matched
    if _c == 'a' then
      matched = ('alpha')
    elseif _c == 'c' then
      matched = ('cntrl')
    elseif _c == 'd' then
      matched = ('digit')
    elseif _c == 'g' then
      matched = ('graph')
    elseif _c == 'l' then
      matched = ('lower')
    elseif _c == 'p' then
      matched = ('punct')
    elseif _c == 's' then
      matched = ('space')
    elseif _c == 'u' then
      matched = ('upper')
    elseif _c == 'w' then
      matched = ('alnum')
    elseif _c == 'x' then
      matched = ('xdigit')
    end

    if matched then
      if _c ~= c then
        class = cl.new():without_classes(matched)
      else
        class = cl.new():with_classes(matched)
      end
    elseif _c == 'z' then
      class = cl.new():with_codes(0)
      if _c ~= c then
        class = class:invert()
      end
    else
      class = cl.new():with_codes(c)
    end
  elseif c == '[' and not ctx.internal then
    local old_internal = ctx.internal
    ctx.internal = true
    class = cl.new()
    local firstletter = true
    while true do
      local prev_nbs = nbs
      c, nbs = next(str, nbs)
      utf8.debug("next", tttt, c, nbs)
      if c == '^' and firstletter then
        class:invert()
        local nc, nnbs = next(str, nbs)
        if nc == ']' then
          class:with_codes(nc)
          nbs = nnbs
        end
      elseif c == ']' then
        if firstletter then
          class:with_codes(c)
        else
          utf8.debug('] on pos', tttt, nbs)
          break
        end
      elseif c == '' then
        error "malformed pattern (missing ']')"
      else
        local sub_class, skip = utf8.regex.compiletime.charclass.parse(str, c, nbs, ctx)
        nbs = prev_nbs + skip
        utf8.debug("include", tttt, bs, prev_nbs, nbs, skip)
        class:include(sub_class)
      end
      firstletter = false
    end
    ctx.internal = old_internal
  elseif c == '.' then
    if not ctx.internal then
      class = cl.new():invert()
    else
      class = cl.new():with_codes(c)
    end
  end

  return class, utf8.next(str, nbs) - bs
end

return parse

end

--[[
    x: (where x is not one of the magic characters ^$()%.[]*+-?) represents the character x itself.
    .: (a dot) represents all characters.
    %a: represents all letters.
    %c: represents all control characters.
    %d: represents all digits.
    %g: represents all printable characters except space.
    %l: represents all lowercase letters.
    %p: represents all punctuation characters.
    %s: represents all space characters.
    %u: represents all uppercase letters.
    %w: represents all alphanumeric characters.
    %x: represents all hexadecimal digits.
    %x: (where x is any non-alphanumeric character) represents the character x. This is the standard way to escape the magic characters. Any non-alphanumeric character (including all punctuation characters, even the non-magical) can be preceded by a '%' when used to represent itself in a pattern.
    [set]: represents the class which is the union of all characters in set. A range of characters can be specified by separating the end characters of the range, in ascending order, with a '-'. All classes %x described above can also be used as components in set. All other characters in set represent themselves. For example, [%w_] (or [_%w]) represents all alphanumeric characters plus the underscore, [0-7] represents the octal digits, and [0-7%l%-] represents the octal digits plus the lowercase letters plus the '-' character.

    You can put a closing square bracket in a set by positioning it as the first character in the set. You can put a hyphen in a set by positioning it as the first or the last character in the set. (You can also use an escape for both cases.)

    The interaction between ranges and classes is not defined. Therefore, patterns like [%a-z] or [a-%%] have no meaning.
    [^set]: represents the complement of set, where set is interpreted as above.

For all classes represented by single letters (%a, %c, etc.), the corresponding uppercase letter represents the complement of the class. For instance, %S represents all non-space characters.
]]

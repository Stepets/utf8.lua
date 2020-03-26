local base = require "utf8primitives"
local cl = require "charclass.compiletime.builder"

local function next(str, bs)
  local nbs1 = base.next(str, bs)
  local nbs2 = base.next(str, nbs1)
  -- print("str:", tostring(base.raw.sub(str, nbs1, nbs2 - 1)), "bss", bs, nbs1, nbs2)
  return base.raw.sub(str, nbs1, nbs2 - 1), nbs1
end

local token = 1

local function parse(str, c, bs, ctx)
  local tttt = token
  token = token + 1

  local class
  local nbs = bs
  print("vp", tttt, str, c, nbs, next(str, nbs))

  if c == '%' then
    c, nbs = next(str, bs)
    local _c = base.raw.lower(c)
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
    end
  elseif c == '[' then
    local old_internal = ctx.internal
    ctx.internal = true
    class = cl.new()
    local firstletter = true
    while true do
      local prev_nbs = nbs
      c, nbs = next(str, nbs)
      print("next", tttt, c, nbs)
      if c == '^' and firstletter then
        class:invert()
      elseif c == ']' then
        print('] on pos', tttt, nbs)
        break
      elseif c == '' then
        error "malformed pattern (missing ']')"
      else
        local sub_class, skip = ctx.parse(str, c, nbs, ctx)
        nbs = prev_nbs + skip
        if sub_class then
          print("include", tttt, bs, prev_nbs, nbs, skip)
          class:include(sub_class)
        else
          error("cannot be")
        --   -- todo separate ranges parser
        --   local c0 = c
        --   local c1, nbs1 = next(str, nbs)
        --   print(">>>>range", c0, c1)
        --   if c1 == '-' then
        --     c, nbs = next(str, nbs1)
        --     if c then
        --       class:with_ranges({c1, c})
        --     else
        --       class:with_codes(c0, '-')
        --     end
        --   else
        --     class:with_codes(c0)
        --   end
        end
      end
      firstletter = false
    end
    ctx.internal = old_internal
    --nbs = base.next(str, nbs)
  elseif c == '.' then
    class = cl.new():invert()
  end

  return class, base.next(str, nbs) - bs
end

return parse

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

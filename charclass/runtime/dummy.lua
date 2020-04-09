return function(utf8)

local base = utf8:require "charclass.runtime.base"

local dummy = setmetatable({}, {__index = base})
local mt = {__index = dummy}

function dummy.new()
  return setmetatable({}, mt)
end

function dummy:with_classes(...)
  local classes = {...}
  for _, c in ipairs(classes) do
    if c == 'alpha' then self:with_ranges({65, 90}, {97, 122})
    elseif c == 'cntrl' then self:with_ranges({0, 31}):with_codes(127)
    elseif c == 'digit' then self:with_ranges({48, 57})
    elseif c == 'graph' then self:with_ranges({1, 8}, {14, 31}, {33, 132}, {134, 159}, {161, 5759}, {5761, 8191}, {8203, 8231}, {8234, 8238}, {8240, 8286}, {8288, 12287})
    elseif c == 'lower' then self:with_ranges({97, 122})
    elseif c == 'punct' then self:with_ranges({33, 47}, {58, 64}, {91, 96}, {123, 126})
    elseif c == 'space' then self:with_ranges({9, 13}):with_codes(32, 133, 160, 5760):with_ranges({8192, 8202}):with_codes(8232, 8233, 8239, 8287, 12288)
    elseif c == 'upper' then self:with_ranges({65, 90})
    elseif c == 'alnum' then self:with_ranges({48, 57}, {65, 90}, {97, 122})
    elseif c == 'xdigit' then self:with_ranges({48, 57}, {65, 70}, {97, 102})
    end
  end
  return self
end

function dummy:without_classes(...)
  local classes = {...}
  if #classes > 0 then
    return self:with_subs(dummy.new():with_classes(...):invert())
  else
    return self
  end
end

return dummy

end

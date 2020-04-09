return function(utf8)

local begins = utf8.config.begins
local ends = utf8.config.ends

return {
  new = function()
    return {
      prev_class = nil,
      begins = begins[1].default(),
      ends = ends[1].default(),
      funcs = {},
      internal = false, -- hack for ranges, flags if parser is in []
    }
  end
}

end

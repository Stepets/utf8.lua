return function(utf8)

local provided = utf8.config.primitives

if provided then
  if type(provided) == "table" then
    return provided
  elseif type(provided) == "function" then
    return provided(utf8)
  else
    return utf8:require(provided)
  end
end

return utf8:require("primitives.dummy")

end

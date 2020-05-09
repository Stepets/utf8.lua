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

if pcall(require, "tarantool") then
  return utf8:require "primitives.tarantool"
elseif pcall(require, "ffi") then
  return utf8:require "primitives.native"
else
  return utf8:require "primitives.dummy"
end

end

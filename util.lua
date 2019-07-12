local util = {}

function util.copy(obj, deep)
  if type(obj) == 'table' then
    local result = {}
    if deep then
      for k,v in pairs(obj) do
        result[k] = util.copy(v, true)
      end
    else
      for k,v in pairs(obj) do
        result[k] = v
      end
    end
    return result
  else
    return obj
  end
end

return util

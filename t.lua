local str = '12345678910121314151617181920'

local function skip_iterator(str)
  local max_len = #str
  return function(...)
    print('args', ...)
    local args = {...}
    local skip, bs = args[1], args[2]
    bs = bs or 1
    -- bs = bs + skip[1]
    if bs > max_len then return nil end

    return bs + 1, bs, str:sub(bs, bs)
  end
end

local skip = {0}
-- local ll = {0}
for nbs, bs, nn in skip_iterator(str), skip do
  --skip = 0
  print(nbs, bs, nn, str:sub(bs, nbs - 1))
  -- ll[1] = tonumber(str:sub(bs, nbs - 1))
  --skip[1] = tonumber(str:sub(bs, nbs - 1))
  -- error ""
end

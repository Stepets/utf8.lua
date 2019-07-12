local utf8 = ".utf8_2018"

local classes = {}
for i = 0, 9 do table.insert(classes, tostring(i)) end


local captures_placed = 0

local starts = {"", "^"}
local class_modificators = {
  star = function (cl) return cl end,
  star = function (cl) return cl .. "*" end,
  minus = function (cl) return cl .. "-" end,
  question = function (cl) return cl .. "?" end,
  capture = function (cl)
    captures_placed = captures_placed + 1
    return "(" .. cl .. ")"
  end,
  capture_ref = function (cl)
    if captures_placed == 0 then return cl end
    if math.random() > 0.5 then
      return "%" .. math.random(captures_placed) .. cl
    else
      return cl .. "%" .. math.random(captures_placed)
    end
  end,
  -- balancer = function (cl)
  --   local idx1 = math.random(#classes)
  --   local idx2 = (idx1 + 1) % #classes + 1
  --   if math.random() > 0.5 then
  --     return "b" .. classes[idx1] .. classes[idx2] .. cl
  --   else
  --     return cl .. "b" .. classes[idx1] .. classes[idx2]
  --   end
  -- end,
}
local ends = {"", "$"}

local modificators = {}
for k,v in pairs(class_modificators) do
  table.insert(modificators, v)
end

math.randomseed(os.time())

local function test(num)
  captures_placed = 0

  local r = ""
  for i = 1, 5 do
    r = r .. modificators[math.random(#modificators)](classes[math.random(#classes)])
  end
  local se = math.random(3)
  if se == 1 then
    r = "^" .. r
  elseif se == 2 then
    r = r .. "$"
  end
  print(num, r)

  for tries = 1, 1000 do
    local str = ""
    for i = 1, 125 do
      str = str .. classes[math.random(#classes)]
    end
    local matched = str:match(r)
    assert(matched == utf8.match(str, r), str)
    if matched then return end
  end
  print("skip")
end

for i = 1, 100000 do
  test(i)
end
print("OK")

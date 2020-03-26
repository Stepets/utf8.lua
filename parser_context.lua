local charclasses = {
  require "charclass.compiletime.vanilla",
  require "charclass.compiletime.range",
  require "charclass.compiletime.stub",
}

local begins = {
  require "begins.compiletime.vanilla"
}

local ends = {
  require "ends.compiletime.vanilla"
}

return {
  new = function()
    return {
      prev_class = nil,
      parse = function(regex, c, bs, ctx)
        print("parse():", regex, c, bs, regex[bs])
        for _, p in ipairs(charclasses) do
          local charclass, nbs = p(regex, c, bs, ctx)
          if charclass then
            ctx.prev_class = charclass:build()
            print("cc", ctx.prev_class, _, c, bs, nbs)
            return charclass, nbs
          end
        end
      end,
      begins = begins[1].default(),
      ends = ends[1].default(),
      funcs = {},
      internal = nil, -- hack for ranges
    }
  end
}

return function(utf8)

utf8.config.modifier = utf8.config.modifier or {
  utf8:require "modifier.compiletime.vanilla",
  utf8:require "modifier.compiletime.frontier",
  utf8:require "modifier.compiletime.stub",
}

function utf8.regex.compiletime.modifier.parse(regex, c, bs, ctx)
  for _, m in ipairs(utf8.config.modifier) do
    local functions, move = m.parse(regex, c, bs, ctx)
    utf8.debug("mod", _, c, bs, move, functions and utf8.config.unpack(functions))
    if functions then
      ctx.prev_class = nil
      return functions, move
    end
  end
end

end

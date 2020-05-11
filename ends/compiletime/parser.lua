return function(utf8)

utf8.config.ends = utf8.config.ends or {
  utf8:require "ends.compiletime.vanilla"
}

function utf8.regex.compiletime.ends.parse(regex, c, bs, ctx)
  for _, m in ipairs(utf8.config.ends) do
    local functions, move = m.parse(regex, c, bs, ctx)
    utf8.debug("ends", _, c, bs, move, functions)
    if functions then
      return functions, move
    end
  end
end

end

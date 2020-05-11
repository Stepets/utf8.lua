return function(utf8)

utf8.config.begins = utf8.config.begins or {
  utf8:require "begins.compiletime.vanilla"
}

function utf8.regex.compiletime.begins.parse(regex, c, bs, ctx)
  for _, m in ipairs(utf8.config.begins) do
    local functions, move = m.parse(regex, c, bs, ctx)
    utf8.debug("begins", _, c, bs, move, functions)
    if functions then
      return functions, move
    end
  end
end

end

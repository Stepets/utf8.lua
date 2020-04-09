return function(utf8)

utf8.config.compiletime_charclasses = utf8.config.compiletime_charclasses or {
  utf8:require "charclass.compiletime.vanilla",
  utf8:require "charclass.compiletime.range",
  utf8:require "charclass.compiletime.stub",
}

function utf8.regex.compiletime.charclass.parse(regex, c, bs, ctx)
  utf8.debug("parse charclass():", regex, c, bs, regex[bs])
  for _, p in ipairs(utf8.config.compiletime_charclasses) do
    local charclass, nbs = p(regex, c, bs, ctx)
    if charclass then
      ctx.prev_class = charclass:build()
      utf8.debug("cc", ctx.prev_class, _, c, bs, nbs)
      return charclass, nbs
    end
  end
end

end

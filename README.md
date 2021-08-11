# utf8.lua
pure-lua 5.3 regex library for Lua 5.3, Lua 5.1, LuaJIT

This library provides simple way to add UTF-8 support into your application.

#### Example:
```Lua
local utf8 = require('.utf8'):init()
for k,v in pairs(utf8) do
  string[k] = v
end

local str = "пыщпыщ ололоо я водитель нло"
print(str:find("(.л.+)н"))
-- 8	26	ололоо я водитель

print(str:gsub("ло+", "보라"))
-- пыщпыщ о보라보라 я водитель н보라	3

print(str:match("^п[лопыщ ]*я"))
-- пыщпыщ ололоо я
```

#### Usage:

This library can be used as drop-in replacement for vanilla string library. It exports all vanilla functions under `raw` sub-object.

```Lua
local utf8 = require('.utf8'):init()
local str = "пыщпыщ ололоо я водитель нло"
utf8.gsub(str, "ло+", "보라")
-- пыщпыщ о보라보라 я водитель н보라	3
utf8.raw.gsub(str, "ло+", "보라")
-- пыщпыщ о보라보라о я водитель н보라	3
```

It also provides all functions from Lua 5.3 UTF-8 [module](https://www.lua.org/manual/5.3/manual.html#6.5) except `utf8.len (s [, i [, j]])`. If you need to validate your strings use `utf8.validate(str, byte_pos)` or iterate over with `utf8.validator`.

Please note that library assumes regexes are valid UTF-8 strings, if you need to manipulate individual bytes use vanilla functions under `utf8.raw`.


#### Installation:

Download repository to your project folder. (no rockspecs yet)

Examples assume library placed under `utf8` subfolder not `utf8.lua`.

As of Lua 5.3 default `utf8` module has precedence over user-provided. In this case you can specify full module path (`.utf8`).

#### Configuration:

Library is highly modular. You can provide your implementation for almost any function used. Library already has several back-ends:
- [Runtime character class processing](charclass/runtime/init.lua) using hardcoded codepoint ranges or using native functions through `ffi`.
- [Basic functions](primitives/init.lua) for working with UTF-8 characters have specializations for `ffi`-enabled runtime and for tarantool.

Probably most interesting [customizations](init.lua) are `utf8.config.loadstring` and `utf8.config.cache` if you want to precompile your regexes.

```Lua
local utf8 = require('.utf8')
utf8.config = {
  cache = my_smart_cache,
}
utf8:init()
```

For `lower` and `upper` functions to work in environments where `ffi` cannot be used, you can specify substitution tables ([data example](https://github.com/artemshein/luv/blob/master/utf8data.lua))

```Lua
local utf8 = require('.utf8')
utf8.config = {
  conversion = {
    uc_lc = utf8_uc_lc,
    lc_uc = utf8_lc_uc
  },
}
utf8:init()
```
Customization is done before initialization. If you want, you can change configuration after `init`, it might work for everything but modules. All of them should be reloaded.

#### [Documentation:](test/test.lua)

#### Issue reporting:

Please provide example script that causes error together with environment description and debug output. Debug output can be obtained like:
```Lua
local utf8 = require('.utf8')
utf8.config = {
  debug = utf8:require("util").debug
}
utf8:init()
-- your code
```
Default logger used is [`io.write`](https://www.lua.org/manual/5.3/manual.html#pdf-io.write) and can be changed by specifying `logger = my_logger` in configuration

--local require = require; do local _p = (... or "."):match("(.-)[^%.]+$"); local r = require require = function(p) return r(_p .. p) end; end

local ffi = pcall(require, "ffi")
if not ffi then
  return require "charclass.runtime.dummy"
else
  return require "charclass.runtime.native"
end

local utf8uclc = require('init')
utf8uclc.config = {
  debug = nil,
--   debug = utf8:require("util").debug,
  conversion = {
    uc_lc = setmetatable({}, {__index = function(self, idx) return "l" end}),
    lc_uc = setmetatable({}, {__index = function(self, idx) return "u" end}),
  }
}
utf8uclc:init()

local assert_equals = require 'test.util'.assert_equals

assert_equals(utf8uclc.lower("фыва"), "llll")
assert_equals(utf8uclc.upper("фыва"), "uuuu")

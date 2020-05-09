#!/bin/sh

set -xe

lua53=$(which lua5.3 || which true)
lua51=$(which lua5.1 || which true)
luajit=$(which luajit || which true)

$lua53 test/charclass_compiletime.lua
$lua51 test/charclass_compiletime.lua
$luajit test/charclass_compiletime.lua

$lua53 test/charclass_runtime.lua
$lua51 test/charclass_runtime.lua
$luajit test/charclass_runtime.lua

$lua53 test/test_compat.lua
$lua51 test/test_compat.lua
$luajit test/test_compat.lua

$lua53 test/test.lua
$lua51 test/test.lua
$luajit test/test.lua

echo "tests passed"

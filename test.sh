#!/bin/sh

set -xe

lua53=$(which lua5.3 || which true)
lua51=$(which lua5.1 || which true)
luajit=$(which luajit || which true)

for test in \
  test/charclass_compiletime.lua \
  test/charclass_runtime.lua \
  test/context_runtime.lua \
  test/test.lua \
  test/test_compat.lua \
  test/test_pm.lua
do
  $lua53 $test
  $lua51 $test
  $luajit $test
done

echo "tests passed"

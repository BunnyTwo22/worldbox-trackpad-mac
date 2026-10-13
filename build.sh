#!/bin/zsh
set -eu
cd "${0:A:h}"
xcrun clang -dynamiclib -arch x86_64 -mmacosx-version-min=10.13 -fobjc-arc -fblocks \
  -Wall -Wextra -Wno-unused-parameter -framework Cocoa -framework Carbon \
  Trackpad.m -o Trackpad.dylib
codesign --force --sign - Trackpad.dylib

#!/bin/bash
set -eu
cd "$(dirname "$0")"
CHIBICC=${CHIBICC:-../../chibicc}
INCLUDE=${INCLUDE:-../../include}
mkdir -p build
for f in *.c; do
  "$CHIBICC" -I"$INCLUDE" -I. -include ../ppp-compat.h -c -o "build/${f%.c}.o" "$f"
done
"$CHIBICC" -o build/app build/*.o
exec ./build/app

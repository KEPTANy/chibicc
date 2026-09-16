#!/bin/bash
# Build and check the example programs with chibicc.
#
#   make examples
#   examples/run.sh
#   examples/run.sh figures composite
set -u
cd "$(dirname "$0")"
CHIBICC=${CHIBICC:-$PWD/../chibicc}
INCLUDE=${INCLUDE:-$PWD/../include}
export CHIBICC INCLUDE

if [ ! -x "$CHIBICC" ]; then
  echo "chibicc not built: run make first" >&2
  exit 1
fi

if [ $# -gt 0 ]; then
  names="$*"
else
  names=$(ls -d */ | tr -d /)
fi

pass=0
fail=0

for name in $names; do
  dir=$name
  if [ ! -x "$dir/build.sh" ]; then
    echo "no such example: $name" >&2
    fail=$((fail + 1))
    continue
  fi

  rm -rf "$dir/build"
  if ! out=$(cd "$dir" && ./build.sh 2>&1); then
    printf '%-14s FAILED\n%s\n' "$name" "$(echo "$out" | sed 's/^/    /' | tail -6)"
    fail=$((fail + 1))
    continue
  fi

  if [ -f "$dir/data/input1.txt" ]; then
    got=$dir/build/out.txt
  else
    got=$dir/build/stdout.txt
    printf '%s\n' "$out" > "$got"
  fi

  if diff -u "$dir/expected.txt" "$got" > "$dir/build/diff.txt" 2>&1; then
    printf '%-14s ok\n' "$name"
    pass=$((pass + 1))
  else
    printf '%-14s OUTPUT DIFFERS\n%s\n' "$name" \
      "$(head -12 "$dir/build/diff.txt" | sed 's/^/    /')"
    fail=$((fail + 1))
  fi
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]

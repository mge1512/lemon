#!/bin/sh
#
# Tests for the Lemon generator of this repository.
#
# Usage:   sh test/run.sh
#
# Part 1 compares the changed generator (tool/lemon.c) with the original
# generator (upstream/tool/lemon.c). Both run with the C template on the
# same grammars and with the same options. Every output file, the text on
# standard output and the exit status must be the same.
#
# The script needs a C compiler (CC, default cc) and standard shell tools.
# It writes only below the directory build/.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$ROOT/build"
CC=${CC:-cc}
FAILED=0
PASSED=0

fail() { echo "FAIL  $*"; FAILED=$((FAILED+1)); }
pass() { echo "ok    $*"; PASSED=$((PASSED+1)); }

rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "== build the generators"
"$CC" -O1 -o "$BUILD/lemon-orig" "$ROOT/upstream/tool/lemon.c" || { echo "cannot build the original generator"; exit 2; }
"$CC" -O1 -o "$BUILD/lemon"      "$ROOT/tool/lemon.c"          || { echo "cannot build the changed generator"; exit 2; }

# run_one NAME GENERATOR TEMPLATE GRAMMAR OPTIONS...
# Runs a generator in its own directory. The generator and the template are
# copied to bin/ there, so that both runs see the same file names.
run_one() {
  name=$1; gen=$2; tpl=$3; grammar=$4; shift 4
  dir="$BUILD/$name"
  mkdir -p "$dir/out" "$dir/bin"
  cp "$gen" "$dir/bin/lemon"
  cp "$tpl" "$dir/bin/lempar.c"
  ( cd "$dir" && ./bin/lemon "$@" -Tbin/lempar.c -dout "$grammar" >stdout.txt 2>stderr.txt; echo $? >status.txt )
}

# compare_c GRAMMAR OPTIONS...
compare_c() {
  grammar=$1; shift
  label="$(basename "$grammar") [$*]"
  id=$(echo "$(basename "$grammar")_$*" | tr -c 'A-Za-z0-9_\n' '_')
  run_one "c-orig/$id" "$BUILD/lemon-orig" "$ROOT/upstream/tool/lempar.c" "$grammar" "$@"
  run_one "c-new/$id"  "$BUILD/lemon"      "$ROOT/tool/lempar.c"          "$grammar" "$@"
  if diff -r -x bin "$BUILD/c-orig/$id" "$BUILD/c-new/$id" >"$BUILD/diff-$id.txt" 2>&1; then
    n=$(ls "$BUILD/c-new/$id/out" | wc -l)
    pass "C output identical: $label ($n files, status $(cat "$BUILD/c-new/$id/status.txt"))"
  else
    fail "C output differs: $label (see build/diff-$id.txt)"
  fi
}

echo "== part 1: C output of the changed generator against the original"
for grammar in "$ROOT/upstream/src/parse.y" "$ROOT/upstream/test/lemon-test01.y" "$ROOT"/test/grammars/*.y; do
  [ -f "$grammar" ] || continue
  compare_c "$grammar"
  compare_c "$grammar" -l
  compare_c "$grammar" -m
  compare_c "$grammar" -p -b
  compare_c "$grammar" -q
  compare_c "$grammar" -g
  compare_c "$grammar" -Z
  compare_c "$grammar" -s -S
done

echo "== result: $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]

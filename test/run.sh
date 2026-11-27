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
# Part 3 also uses a Go compiler (GO, default go) and a Rust compiler (RUSTC,
# default rustc) when they are there.
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

# expect_error LABEL EXPECTED-TEXT TEMPLATE-LINES...
# Puts the lines before the C template and expects that the generator stops
# with an error message that has the expected text, and that it writes no
# parser file. The report file (.out) can be there.
expect_error() {
  label=$1; expected=$2; shift 2
  dir="$BUILD/syntax-error"; rm -rf "$dir"; mkdir -p "$dir/out"
  { for l in "$@"; do printf "%s\n" "$l"; done; cat "$ROOT/tool/lempar.c"; } >"$dir/template"
  ( cd "$dir" && "$BUILD/lemon" ${EXTRA_OPTS:-} -Ttemplate -dout "$ROOT/test/grammars/calc.y" >stdout.txt 2>stderr.txt; echo $? >status.txt )
  if [ "$(cat "$dir/status.txt")" != 0 ] && grep -q -F "$expected" "$dir/stderr.txt" && [ -z "$(ls "$dir/out" | grep -v "\.out$")" ]; then
    pass "syntax line refused: $label"
  else
    fail "syntax line not refused: $label"
  fi
}

echo "== part 2: errors in %%syntax lines of a template"
expect_error "unknown name"      "Unknown name"            "%%syntax nonsense \"x\""
expect_error "text without quotes" "must be in double quotes" "%%syntax const x"
expect_error "open quote"        "no closing double quote" "%%syntax const \"x"
expect_error "destructor with template syntax" "A destructor needs" "%%syntax file-suffix \".x\""
EXTRA_OPTS=-m expect_error "option -m with template syntax" "The option -m needs" "%%syntax file-suffix \".x\""

# Part 3 builds the same calculator with each template and runs it on the
# same inputs. Every parser must print the lines of test/calc/expected.txt.
# A language without a compiler on this machine is skipped.
check_calc() {
  lang=$1; out=$2
  if [ -f "$out" ] && cmp -s "$out" "$ROOT/test/calc/expected.txt"; then
    pass "calculator in $lang: $(wc -l <"$out" | tr -d " ") results as expected"
  else
    fail "calculator in $lang (see $out)"
  fi
}

echo "== part 3: the same calculator with each template"
CALC="$BUILD/calc"
mkdir -p "$CALC/c" "$CALC/go" "$CALC/rust"

( cd "$CALC/c" &&
  "$BUILD/lemon" "-T$ROOT/tool/lempar.c" -d. "$ROOT/test/grammars/calc.y" &&
  "$CC" -o calc -I. "$ROOT/test/calc/main.c" &&
  ./calc "$ROOT/test/calc/inputs.txt" >result.txt ) >"$CALC/c/log.txt" 2>&1
check_calc C "$CALC/c/result.txt"

GO=${GO:-go}
if command -v "$GO" >/dev/null 2>&1; then
  ( cd "$CALC/go" &&
    "$BUILD/lemon" "-T$ROOT/tool/lempar.go" -d. "$ROOT/test/calc/calc-go.y" &&
    cp "$ROOT/test/calc/main.go" . &&
    printf "module calctest\n\ngo 1.20\n" >go.mod &&
    GOTOOLCHAIN=local GOFLAGS=-mod=mod "$GO" build -o calc . &&
    ./calc "$ROOT/test/calc/inputs.txt" >result.txt ) >"$CALC/go/log.txt" 2>&1
  check_calc Go "$CALC/go/result.txt"
else
  echo "skip  calculator in Go: no $GO command"
fi

RUSTC=${RUSTC:-rustc}
if command -v "$RUSTC" >/dev/null 2>&1; then
  ( cd "$CALC/rust" &&
    "$BUILD/lemon" "-T$ROOT/tool/lempar.rs" -d. "$ROOT/test/calc/calc-rs.y" &&
    cp "$ROOT/test/calc/main.rs" . &&
    "$RUSTC" --edition 2021 -o calc main.rs &&
    ./calc "$ROOT/test/calc/inputs.txt" >result.txt ) >"$CALC/rust/log.txt" 2>&1
  check_calc Rust "$CALC/rust/result.txt"
else
  echo "skip  calculator in Rust: no $RUSTC command"
fi

echo "== result: $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]

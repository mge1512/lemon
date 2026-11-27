#!/bin/sh
#
# Tests for the Lemon generator of this repository.
#
# Usage:   sh test/run.sh
#
# Part 1  The changed generator (tool/lemon.c) against the original generator
#         (upstream/tool/lemon.c). Both run with the C template on the same
#         grammars and with the same options. Every output file, the text
#         on standard output and standard error, and the exit status must
#         be the same.
# Part 2  Errors in the %%syntax lines of a template, and the limits of a
#         template that has such lines.
# Part 3  One calculator with each template (C, Go, Rust). The parsers run
#         on the same inputs and must print the same results.
# Part 4  Recognizers without actions with each template. The parsers must
#         accept the same statements and refuse the others at the same token.
#
# The script needs a C compiler (CC, default cc) and standard shell tools.
# Parts 3 and 4 use a Go compiler (GO, default go) and a Rust compiler
# (RUSTC, default rustc) when they are there. Without one of them, the
# script skips the tests for that language and says so.
#
# The script writes only below the directory build/.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$ROOT/build"
CC=${CC:-cc}
GO=${GO:-go}
RUSTC=${RUSTC:-rustc}
FAILED=0
PASSED=0
SKIPPED=0

fail() { echo "FAIL  $*"; FAILED=$((FAILED+1)); }
pass() { echo "ok    $*"; PASSED=$((PASSED+1)); }
skip() { echo "skip  $*"; SKIPPED=$((SKIPPED+1)); }
have() { command -v "$1" >/dev/null 2>&1; }

rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "== build the generators"
"$CC" -O1 -o "$BUILD/lemon-orig" "$ROOT/upstream/tool/lemon.c" || { echo "cannot build the original generator"; exit 2; }
"$CC" -O1 -o "$BUILD/lemon"      "$ROOT/tool/lemon.c"          || { echo "cannot build the changed generator"; exit 2; }

# ---------------------------------------------------------------------------
# Part 1

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
    n=$(ls "$BUILD/c-new/$id/out" | wc -l | tr -d ' ')
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

# ---------------------------------------------------------------------------
# Part 2

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
    pass "refused: $label"
  else
    fail "not refused: $label"
  fi
}

echo "== part 2: errors in %%syntax lines of a template"
expect_error "unknown name"        "Unknown name"             '%%syntax nonsense "x"'
expect_error "text without quotes" "must be in double quotes" '%%syntax const x'
expect_error "open quote"          "no closing double quote"  '%%syntax const "x'
expect_error "destructor with a custom template" "A destructor needs" '%%syntax file-suffix ".x"'
EXTRA_OPTS=-m expect_error "option -m with a custom template" "The option -m needs" '%%syntax file-suffix ".x"'

# ---------------------------------------------------------------------------
# Parts 3 and 4

# check_result LABEL RESULT-FILE EXPECTED-FILE
check_result() {
  if [ -f "$2" ] && cmp -s "$2" "$3"; then
    pass "$1: $(wc -l <"$2" | tr -d ' ') lines as expected"
  else
    fail "$1 (see $2 and log.txt beside it)"
  fi
}

# go_build OUTPUT
# Builds the Go files of the current directory as one program.
go_build() {
  printf "module lemontest\n\ngo 1.20\n" >go.mod &&
  GOTOOLCHAIN=local GOFLAGS=-mod=mod "$GO" build -o "$1" .
}

echo "== part 3: the same calculator with each template"
CALC="$BUILD/calc"
INPUTS="$ROOT/test/calc/inputs.txt"
EXPECTED="$ROOT/test/calc/expected.txt"
mkdir -p "$CALC/c" "$CALC/go" "$CALC/rust"

( cd "$CALC/c" &&
  "$BUILD/lemon" "-T$ROOT/tool/lempar.c" -d. "$ROOT/test/grammars/calc.y" &&
  "$CC" -o calc -I. "$ROOT/test/calc/main.c" &&
  ./calc "$INPUTS" >result.txt ) >"$CALC/c/log.txt" 2>&1
check_result "calculator in C" "$CALC/c/result.txt" "$EXPECTED"

if have "$GO"; then
  ( cd "$CALC/go" &&
    "$BUILD/lemon" "-T$ROOT/tool/lempar.go" -d. "$ROOT/test/calc/calc-go.y" &&
    cp "$ROOT/test/calc/main.go" . &&
    go_build calc &&
    ./calc "$INPUTS" >result.txt ) >"$CALC/go/log.txt" 2>&1
  check_result "calculator in Go" "$CALC/go/result.txt" "$EXPECTED"
else
  skip "calculator in Go: no $GO command"
fi

if have "$RUSTC"; then
  ( cd "$CALC/rust" &&
    "$BUILD/lemon" "-T$ROOT/tool/lempar.rs" -d. "$ROOT/test/calc/calc-rs.y" &&
    cp "$ROOT/test/calc/main.rs" . &&
    "$RUSTC" --edition 2021 -o calc main.rs &&
    ./calc "$INPUTS" >result.txt ) >"$CALC/rust/log.txt" 2>&1
  check_result "calculator in Rust" "$CALC/rust/result.txt" "$EXPECTED"
else
  skip "calculator in Rust: no $RUSTC command"
fi

# recognizer NAME
# Builds a recognizer for the rules in test/recognizer/NAME/rules.y with each
# template. Each line of statements.txt is a list of token names. The token
# numbers are the same for every template, so the script takes them from
# the header file that the generator writes for the C parser.
recognizer() {
  name=$1
  src="$ROOT/test/recognizer"
  dir="$BUILD/recognizer-$name"
  expected="$src/$name/expected.txt"
  mkdir -p "$dir/c" "$dir/go" "$dir/rust"

  ( cd "$dir/c" &&
    cat "$src/head-c.y" "$src/$name/rules.y" >aql.y &&
    "$BUILD/lemon" "-T$ROOT/tool/lempar.c" -d. aql.y &&
    "$CC" -o recognizer -I. "$src/main.c" &&
    awk 'NR==FNR { if ($1=="#define") num[substr($2,3)]=$3; next }
         { line=""
           for(i=1;i<=NF;i++){
             if( !($i in num) ){ print "unknown token " $i >"/dev/stderr"; exit 1 }
             line = line (i>1?" ":"") num[$i]
           }
           print line }' aql.h "$src/$name/statements.txt" >../numbers.txt &&
    ./recognizer ../numbers.txt >result.txt ) >"$dir/c/log.txt" 2>&1
  check_result "recognizer $name in C" "$dir/c/result.txt" "$expected"

  if have "$GO"; then
    ( cd "$dir/go" &&
      cat "$src/head-go.y" "$src/$name/rules.y" >aql.y &&
      "$BUILD/lemon" "-T$ROOT/tool/lempar.go" -d. aql.y &&
      cp "$src/main.go" . &&
      go_build recognizer &&
      ./recognizer ../numbers.txt >result.txt ) >"$dir/go/log.txt" 2>&1
    check_result "recognizer $name in Go" "$dir/go/result.txt" "$expected"
  else
    skip "recognizer $name in Go: no $GO command"
  fi

  if have "$RUSTC"; then
    ( cd "$dir/rust" &&
      cat "$src/head-rs.y" "$src/$name/rules.y" >aql.y &&
      "$BUILD/lemon" "-T$ROOT/tool/lempar.rs" -d. aql.y &&
      cp "$src/main.rs" . &&
      "$RUSTC" --edition 2021 -o recognizer main.rs &&
      ./recognizer ../numbers.txt >result.txt ) >"$dir/rust/log.txt" 2>&1
    check_result "recognizer $name in Rust" "$dir/rust/result.txt" "$expected"
  else
    skip "recognizer $name in Rust: no $RUSTC command"
  fi
}

echo "== part 4: recognizers without actions with each template"
recognizer query
recognizer fallback

echo "== result: $PASSED passed, $FAILED failed, $SKIPPED skipped"
[ "$FAILED" -eq 0 ]

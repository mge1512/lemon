# Changelog of lemongrass

## 0.1.1

Released on 2026-11-27. This release adds what a package needs. The
generator writes the same parser files as 0.1.0, and the templates are
unchanged.

- A `Makefile` builds the program `lemongrass`, runs the tests and installs
  the program, the three templates and the manual page.
- `doc/lemongrass.1` is the manual page. It has the options and the order
  in which the program looks for a template.
- The test script tests a program that is already built when the variable
  `LEMONGRASS` names it. The command `make check` uses this.
- The new option `--help` prints the form of a call and the list of the
  options on standard output. The exit status is 0. The original Lemon
  has no such option and reports an undefined option.
- The new option `--version` does the same as the option `-x`, which now
  prints the version 0.1.1.
- The two new options are not in the list that follows the message for an
  undefined option. That message is the message of the original Lemon,
  byte for byte.

## 0.1.0

Released on 2026-11-27. This is the first release, and it is a proof of
concept.

- The base is the Lemon parser generator of SQLite 3.54.1. The directory
  `upstream/` has the original files.
- A template can start with `%%syntax` lines. These lines give the syntax of
  the target language. The generator checks them before it reads the grammar.
- A template without such lines works as before. The generator then writes
  the same files as the original generator, byte for byte.
- There are two new templates: `tool/lempar.go` for Go and `tool/lempar.rs`
  for Rust. Both are translations of `tool/lempar.c`. A Go parser imports no
  package. A Rust parser uses the standard library and has no `unsafe` code.
- A template with `%%syntax` lines has limits: no destructors, no `%realloc`,
  no `%free`, no `%stack_size_limit` and no option `-m`. The templates for Go
  and Rust also have no error symbol and no `%extra_context`.
- The option `-x` prints the version of Lemon and, on a second line, the
  version of lemongrass.
- `doc/upstream-notes.md` describes two findings in the original files.

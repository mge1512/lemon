# Changelog of lemongrass

## 0.1.1

Released on 2026-11-27. This release adds what a package needs. The
generator and the templates are those of 0.1.0, and they write the same
parser files.

- A `Makefile` builds the program `lemongrass`, runs the tests and installs
  the program, the three templates and the manual page.
- `doc/lemongrass.1` is the manual page. It has the options and the order
  in which the program looks for a template.
- The test script tests a program that is already built when the variable
  `LEMONGRASS` names it. The command `make check` uses this.
- The option `-x` prints the version 0.1.1.

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

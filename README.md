# lemongrass

The Lemon parser generator, with templates for more than one target language.

## What this is

Lemon is the LALR(1) parser generator of the SQLite project. It reads a
grammar file and writes a parser in C. The program has two files: the
generator `lemon.c` and the parser template `lempar.c`.

The original generator prints C syntax itself: constants, tables, the type of
the value stack and the code around the actions. A different template can
change the parser driver, but it cannot change that syntax.

This repository changes the generator so that the template defines the syntax
of the target language. A new target language is then one new template file.
The first new templates are for Go and Rust.

The name lemongrass says that this is not the original Lemon. The letters
"gr" come from Go and Rust, the first two new target languages. The source
files keep their names, `lemon.c` and `lempar.c`, so that the changes to the
original are easy to see.

## Status

Started on 2026-11-27. The first release is 0.1.0, and `CHANGELOG.md` lists
the releases. This is a proof of concept. It passes its tests, and no product
uses it yet.

What works:

- With the C template, the changed generator writes the same files as the
  original generator of SQLite 3.54.1, byte for byte.
- `tool/lempar.go` and `tool/lempar.rs` are translations of `lempar.c`. For
  three grammars the Go and Rust parsers give the same results as the C
  parser. They also take the same steps: the trace messages are the same.
- The generator checks a template before it reads the grammar. It refuses a
  template with a wrong `%%syntax` line or without a required one.

What is not there:

- Destructors, `%realloc`, `%free`, `%stack_size_limit` and the option `-m`
  work only with the C template.
- The Go and Rust templates have no error symbol and no `%extra_context`.
- The original documentation `doc/lemon.html` does not describe the change.

## Use

    cc -O2 -o lemongrass tool/lemon.c
    ./lemongrass -Ttool/lempar.c  query.y
    ./lemongrass -Ttool/lempar.go query.y
    ./lemongrass -Ttool/lempar.rs query.y

The first command builds the generator. The examples call the program
`lemongrass`, so that nobody takes it for an original `lemon` on the same
machine. The other commands write a parser for the grammar `query.y`:
`query.c` with `query.h`, `query.go` or `query.rs`.

| Document | For |
|---|---|
| `doc/go-and-rust.md` | People who write a grammar for Go or Rust |
| `doc/template-syntax.md` | People who write a template for another language |
| `doc/lemon.html` | The grammar language. This is the original documentation. |
| `doc/upstream-notes.md` | Two things in the original files, with test cases |

The generator is a build tool for input that you trust, as the original is.
A grammar file and a template are code. Do not run the generator on files
from a source that you do not know.

## Test

    sh test/run.sh

The script needs a C compiler and standard shell tools. It uses a Go
compiler and a Rust compiler when they are there, and it says which tests
it skips without them. It writes only below `build/`. It has five parts:

1. It builds the original generator and the changed generator. It runs both
   on four grammars with eight sets of options. It compares all output
   files, the messages and the exit status. One of the grammars is the SQL
   grammar of SQLite.
2. It checks that the generator refuses wrong `%%syntax` lines, and
   grammars that a template with such lines cannot have.
3. It builds one calculator with each template and runs the parsers on the
   same inputs. The results must be the expected lines. The trace of the Go
   parser and of the Rust parser must be the trace of the C parser.
4. It does the same for two recognizers without actions. One has the 94
   rules of a query language. The other uses fallback tokens, a wildcard
   token and a token class.
5. It makes parsers for grammars with the error symbol and with
   `%extra_context`. The Go and Rust compilers must refuse them with a
   message that names the feature.

The last result with gcc 13.3.0, Go 1.24.7 and rustc 1.97.0 was "60 passed,
0 failed, 0 skipped".

One more run used the address sanitizer and the undefined behavior sanitizer
of gcc for both generators and the C test programs. It gave the same result
and no report of a sanitizer.

## Rules of this repository

1. With the C template, the changed generator writes the same bytes as the
   original generator. A test compares the two for several grammars.
2. `lemon.c` names no target language other than C, which stays the default.
3. The files in `upstream/` are never edited.
4. The templates for Go and Rust are translations of the original `lempar.c`,
   made in this repository. No code comes from other ports of Lemon.
5. One commit for each logical step.

## Layout

| Path | Content |
|---|---|
| `upstream/` | Unchanged files of SQLite, with a record of their origin |
| `tool/lemon.c` | The generator with the changes of this repository |
| `tool/lempar.c` | The C template, unchanged |
| `tool/lempar.go`, `tool/lempar.rs` | The new templates |
| `doc/` | The documents of the table above |
| `test/` | The test script, the grammars and the test programs |
| `CHANGELOG.md` | The releases and what they changed |
| `LICENSE.md` | The terms: public domain |

The command `diff -u upstream/tool/lemon.c tool/lemon.c` shows all changes
of the generator.

## Who made this

This repository belongs to Matthias G. Eckermann <mge@mailbox.org>.

An AI coding agent (Claude, by Anthropic) wrote the changes in this
repository, at his direction. The commits name the agent.

## Relation to SQLite

This repository is not part of SQLite, and the SQLite developers have not
reviewed it.

The SQLite project states two rules in its `AGENTS.md`. It takes no pull
requests without prior agreement and public-domain paperwork. And it does not
accept code written by AI agents. This repository is therefore a proof of
concept. It shows one way to make Lemon independent of the target language.
It is not a submission to SQLite.

## License

Public domain, after the example of the original Lemon.

The files in `upstream/` come from SQLite, which is in the public domain. This
repository keeps them unchanged, with their original header comments.

Matthias G. Eckermann, the owner of this repository, disclaims copyright to
all other files. Anyone can use them for any purpose. `LICENSE.md` has the
same statement.

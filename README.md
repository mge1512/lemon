# lemon

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

## Status

Started on 2026-11-27. This is work in progress.

- [x] Original files of SQLite 3.54.1 in `upstream/`
- [ ] Test: C output identical to the original generator
- [ ] Generator: syntax of the target language comes from the template
- [ ] Template for Go
- [ ] Template for Rust

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
| `doc/` | Documentation |
| `test/` | Tests |

## Relation to SQLite

This repository is not part of SQLite, and the SQLite developers have not
reviewed it.

An AI coding agent (Claude, by Anthropic) wrote the changes in this
repository, at the direction of the repository owner.

The SQLite project states two rules in its `AGENTS.md`. It takes no pull
requests without prior agreement and public-domain paperwork. And it does not
accept code written by AI agents. This repository is therefore a proof of
concept. It shows one way to make Lemon independent of the target language.
It is not a submission to SQLite.

## License

The files in `upstream/` come from SQLite, which is in the public domain. This
repository keeps them unchanged, with their original header comments.

The repository owner has not yet stated the terms for the files that this
repository adds. Until the owner adds that statement, only the files in
`upstream/` have clear terms.

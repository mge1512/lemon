# Origin of the files in this directory

The files in this directory are copies of files of SQLite, without any change.
Nobody edits them in this repository.

## Source

| | |
|---|---|
| Project | SQLite, <https://sqlite.org> |
| Canonical repository | <https://sqlite.org/src> (Fossil) |
| Release | 3.54.1 |
| Fossil check-in | `555e07ef33f69a0957d24d8e555b702464a131d6f1607f4c3c1e4551e8e6ca76` |
| Git mirror | <https://github.com/sqlite/sqlite>, tag `version-3.54.1` |
| Git commit | `57520227c95396ce39ba6ecaac8d475b78dd3964`, 2026-10-16 |
| Copied on | 2026-11-27 |

The Fossil check-in is the content of the file `manifest.uuid` at that tag.

## Files

| Path here | Path in SQLite | Bytes | Purpose here |
|---|---|---|---|
| `tool/lemon.c` | `tool/lemon.c` | 186846 | The original generator |
| `tool/lempar.c` | `tool/lempar.c` | 37398 | The original C template |
| `doc/lemon.html` | `doc/lemon.html` | 54293 | The original documentation |
| `src/parse.y` | `src/parse.y` | 76847 | Test input: the SQL grammar of SQLite |
| `test/lemon-test01.y` | `test/lemon-test01.y` | 1954 | Test input: a small grammar |

## Check

`SHA256SUMS` has the SHA-256 checksum of each file. To check the copies:

    cd upstream && sha256sum -c SHA256SUMS

## Terms

SQLite is in the public domain. The files keep their original header
comments.

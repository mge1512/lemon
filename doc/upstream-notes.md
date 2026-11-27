# Notes on the original files

The work on this repository found two things in the original files of
SQLite 3.54.1. This note records them with a test case for each, so that the
repository owner can report them to the SQLite project.

The file `AGENTS.md` of the SQLite source tree says that the project "will
accept agentic bug reports that include a reproducible test case". An AI
coding agent found both things, and the report must say so.

The test cases use only the files in `upstream/tool/`.

## 1. tplt_print() reads the byte before an empty string

Place: `lemon.c`, function `tplt_print()`, line 3841:

    if( str[-1]!='\n' ){

For a grammar without `%include`, `ReportTable()` sets the include code to
the string constant `""` and gives it to `tplt_print()`. The loop of
`tplt_print()` does not run for an empty string, and `str[-1]` is then the
byte before the string constant.

Test case:

    cd upstream/tool
    printf 'start ::= A.\n' > g.y
    gcc -g -fsanitize=address -o lemon lemon.c
    ./lemon g.y

Result:

    ERROR: AddressSanitizer: global-buffer-overflow
    READ of size 1
        #0 in tplt_print lemon.c:3841
        #1 in ReportTable lemon.c:4560
        #2 in main lemon.c:1885

The effect without the sanitizer: the parser file depends on the compiler
that built `lemon`. For the grammar above, `g.c` has 1167 lines when `lemon`
is built with `gcc -O0`. It has 1166 lines when `lemon` is built with
`gcc -O1`, `gcc -O2` or `clang -O0`. The difference is one empty line at the
place of the include code.

The same line also reads a byte of the header of `lemon_malloc()`. This
happens when a code block of the grammar is empty and has no line directive.
An example is `%stack_overflow {}` in the first line of a grammar. That byte
is inside the allocated memory.

This repository changed `ReportTable()` for the first case. The commit has
the title "Do not read the byte before a string constant".

## 2. A stack that can grow needs %realloc and %free to compile

Place: `lempar.c`, lines 112, 315, 319 and 472.

`lempar.c` makes the parser stack able to grow when `YYSTACKDEPTH` is 0 or
less:

    #if YYSTACKDEPTH<=0 || YYDYNSTACK
    # define YYGROWABLESTACK 1

The code for such a stack calls `YYREALLOC` with three arguments and
`YYFREE` with two arguments. The last argument is the context of the
parser. Without `%realloc` and `%free`, the generator defines the two names
as `realloc` and `free`, which take one argument less.

Test case:

    cd upstream/tool
    cc -o lemon lemon.c
    printf '%%stack_size 0\nstart ::= A.\n' > s.y
    ./lemon s.y
    cc -c s.c

Result:

    error: too many arguments to function 'realloc'
    error: too many arguments to function 'free'

The same happens for a grammar without `%stack_size` when the parser is
compiled with `-DYYSTACKDEPTH=0`.

The comment at the start of `lempar.c` describes `YYREALLOC` as the "Name of
the realloc() function to use". The documentation `lemon.html` says that the
functions of `%realloc` and `%free` take one more parameter. It asks for a
positive integer after `%stack_size`, so `%stack_size 0` is outside the
documented use. `lempar.c` has code for it.

This repository did not change `lempar.c`.

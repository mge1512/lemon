# Target language syntax from the template

This note describes the change that this repository makes to Lemon. It is
the reference for people who write a template for a new target language.
People who write a grammar for Go or Rust need `go-and-rust.md`.

## The problem

The original generator `lemon.c` reads a template file, `lempar.c`. The
template has the parser driver, with 15 places that are marked with `%%`.
At each place the generator inserts text: constants, tables, action code.

The generator writes that text in C syntax. Three examples:

    #define YYNSTATE             114
    static const YYACTIONTYPE yy_action[] = {
          case 12: /* expr ::= expr PLUS expr */

A template for another language can replace the driver. It cannot replace
these lines. For this reason every port of Lemon to another language changed
`lemon.c`.

## The change

A template can define the syntax of the inserted text. It does this with
lines of this form, before any other text of the template:

    %%syntax NAME "TEXT"

`NAME` is one of the 36 names in the tables below. `TEXT` is the text that
the generator writes. In `TEXT`:

- `\n`, `\t`, `\\` and `\"` have their usual meaning.
- `$WORD` or `${WORD}` is a placeholder. `WORD` has upper-case letters only.
  The generator puts a value there. The tables say which placeholders each
  name has.
- `$$` is one dollar sign.

The generator does not copy the `%%syntax` lines to the parser file. It
ignores text after the closing quote of a line.

A template without `%%syntax` lines gets the C syntax of the original
generator, byte for byte. This is the case for `lempar.c`. The generator
names no language other than C.

A template with at least one `%%syntax` line is called a custom template in
this note. The generator has no built-in syntax for a custom template. A
custom template must have a line for each of the 30 required names. It can
leave out the 6 optional names. The generator then writes nothing in their
place.

## Checks

The generator reads and checks the `%%syntax` lines before it reads the
grammar. It stops with a message, and writes no parser file, in these cases:

- A line has a name that is not in the tables.
- The text is not in double quotes.
- The text has a placeholder that the name does not have.
- A name has more than one line.
- A custom template has no line for a required name.

A template is therefore complete for every grammar, or the generator refuses
it for every grammar.

## What stays the same for every language

Some inserted text is the same for all templates:

- The parser file starts with a comment of the generator in the form
  `/* ... */`. The comments in the tables have the same form. The target
  language must accept such comments.
- A table entry is a number and a comma. A name in a table is a string in
  double quotes and a comma.
- The code blocks of the grammar (`%include`, `%syntax_error` and so on) and
  the action code are copied. They are in the target language.
- The generator puts the code of an action in braces: `{` and `}`.

## The marks of the template

A custom template has the same 15 marks as `lempar.c`, in the same order.
A mark is a line that starts with `%%`.

| Mark | The generator inserts |
|---|---|
| 1 | The code of `%include`. The text of the template before this mark is the header of the parser file. |
| 2 | The token numbers: `tokens-begin`, one `token` for each token, `tokens-end` |
| 3 | The constants and types of the grammar: `type`, `const`, the value stack, `extra-argument`, `extra-context` |
| 4 | The parsing tables: `const`, `array-begin`, the entries, `array-end` |
| 5 | The entries of the fallback table |
| 6 | The names of the symbols, as strings |
| 7 | The rules, as strings |
| 8 | The destructors. Nothing for a custom template. |
| 9 | The code of `%stack_overflow` |
| 10 | For each rule the number of the symbol on its left side |
| 11 | For each rule the negative number of symbols on its right side |
| 12 | The reduce actions, as cases |
| 13 | The code of `%parse_failure` |
| 14 | The code of `%syntax_error` |
| 15 | The code of `%parse_accept` |

After the last text of the template, the generator adds the code of `%code`.

In the text of the template, the generator replaces `Parse` with the name of
the parser (`%name`), if no letter is before it. This is the rule of the
original generator.

For C, the generator leaves out the header of the template if the code of
`%include` starts with `/`, the start of a comment. A custom template always
gets its header.

## Names for files, lines and code blocks

| Name | Placeholders | Meaning | C syntax |
|---|---|---|---|
| `file-suffix` | | Suffix of the parser file | `.c` |
| `line` | `$LINE`, `$FILE` | A line directive. An empty text means no line directives. | `#line $LINE "$FILE"` |
| `default-token-type` | | Type of a token when the grammar has no `%token_type` | `void*` |
| `literal-quotes` | | The characters that start a literal in a code block of the grammar | `"'` |

A custom template gets no separate header file with the token numbers. The
token numbers are in the parser file.

The generator must find the closing brace of each code block of the grammar.
It skips comments of the forms `/* ... */` and `// ...`. It also skips
literals: each character of `literal-quotes` starts a literal that ends at
the next same character. A backslash before a character is an escape. A
brace in a comment or a literal does not count.

## Names for constants and types

| Name | Placeholders | Meaning |
|---|---|---|
| `const` | `$NAME`, `$VALUE` | An integer constant |
| `type` | `$NAME`, `$TYPE` | A name for a type |
| `token` | `$NAME`, `$VALUE` | The number of a token. `$NAME` has the token prefix. |
| `tokens-begin`, `tokens-end` | | Text before and after the token numbers. Optional. |
| `type-uint8`, `type-uint16`, `type-uint32` | | Names of the unsigned integer types |
| `type-int8`, `type-int16`, `type-int32` | | Names of the signed integer types |
| `extra-argument` | `$NAME`, `$DECL`, `$ID` | The grammar has `%extra_argument {DECL}`. `$ID` is the last identifier of `DECL`. `$NAME` is the name of the parser. Optional. |
| `no-extra-argument` | `$NAME` | The grammar has no `%extra_argument`. Optional. |
| `extra-context` | `$NAME`, `$DECL`, `$ID` | The same for `%extra_context`. Optional. |
| `no-extra-context` | `$NAME` | The grammar has no `%extra_context`. Optional. |

For a custom template the generator writes these constants with `const`:

`YYNOCODE`, `YYWILDCARD`, `YYSTACKDEPTH`, `YYERRORSYMBOL`, `YYFALLBACK`,
`YYNSTATE`, `YYNRULE`, `YYNRULE_WITH_ACTION`, `YYNTOKEN`, `YY_MAX_SHIFT`,
`YY_MIN_SHIFTREDUCE`, `YY_MAX_SHIFTREDUCE`, `YY_ERROR_ACTION`,
`YY_ACCEPT_ACTION`, `YY_NO_ACTION`, `YY_MIN_REDUCE`, `YY_MAX_REDUCE`,
`YY_MIN_DSTRCTR`, `YY_MAX_DSTRCTR`, `YY_ACTTAB_COUNT`, `YY_SHIFT_COUNT`,
`YY_SHIFT_MIN`, `YY_SHIFT_MAX`, `YY_REDUCE_COUNT`, `YY_REDUCE_MIN`,
`YY_REDUCE_MAX`.

C has no value for `YYWILDCARD`, `YYERRORSYMBOL` and `YYFALLBACK` when the
grammar does not use the feature. A custom template gets the value 0 in that
case, so that the driver can test the value when the parser runs.
`YYSTACKDEPTH` is the value of `%stack_size`, or 100.

The generator writes these types with `type`: `YYCODETYPE`, `YYACTIONTYPE`
and the token type. The name of the token type is the parser name followed by
`TOKENTYPE`.

The C preprocessor lines of the original (`#undef`, `#ifndef`, `#endif`,
`#if INTERFACE`) and the macros `YYREALLOC`, `YYFREE`, `YYDYNSTACK` and
`YYSIZELIMIT` are written only for C.

## Names for the value stack

Each entry of the parser stack has a value. The type of the value depends on
the symbol. The generator gives every type a number N. Tokens have N = 0. A
symbol that has the type of the tokens also has N = 0.

| Name | Placeholders | Meaning |
|---|---|---|
| `union-begin` | `$NAME` | Start of the type `YYMINORTYPE`. This text also has the member for tokens. `$NAME` is the name of the parser. |
| `union-member` | `$TYPE`, `$N` | One member for the type with number N |
| `union-end` | | End of the type |

If the grammar uses the error symbol, the generator writes one more member
for it. Its type is the text of `type-int32`.

## Names for tables

| Name | Placeholders | Meaning |
|---|---|---|
| `array-begin` | `$NAME`, `$TYPE`, `$COUNT` | Start of a constant table of integers |
| `array-end` | | End of the table |

The tables are `yy_action`, `yy_lookahead`, `yy_shift_ofst`,
`yy_reduce_ofst` and `yy_default`. `$TYPE` is `YYACTIONTYPE`, `YYCODETYPE`
or one of the integer type names of the template.

The other tables (fallback, symbol names, rules, rule information) start and
end in the text of the template.

## Names for cases

The reduce actions are the cases of a selection. Several rules can share one
action.

| Name | Placeholders | Meaning |
|---|---|---|
| `case-first` | `$VALUE`, `$TEXT` | The first rule of an action. `$TEXT` is the rule, for a comment. |
| `case-next` | `$VALUE`, `$TEXT` | Another rule with the same action |
| `case-begin` | | Text between the last rule and the action |
| `case-end` | | Text after the action |
| `default-begin` | | Start of the case for all rules without an action |
| `default-item` | `$VALUE`, `$TEXT` | One rule without an action |
| `default-end` | | End of that case |

## Names for action code

In C, the generator replaces each label of a rule in the action code with an
expression that reads or writes the parser stack. Many languages need a
different way. A custom template gets this one:

- The action code is copied without change. Only `@X` is replaced.
- Before the action, the generator declares a local variable for each label.
- After the action, the generator stores the value of the left side.

| Name | Placeholders | Meaning |
|---|---|---|
| `rhs-fetch` | `$LABEL`, `$TYPE`, `$N`, `$OFFSET` | Declare the label of a right-side symbol and give it the value from the stack |
| `lhs-decl` | `$LABEL`, `$TYPE`, `$N`, `$OFFSET` | Declare the label of the left side |
| `lhs-fetch` | `$LABEL`, `$TYPE`, `$N`, `$OFFSET` | The left side and the first right-side symbol have the same label. Declare it with the value from the stack, so that the action can change it. |
| `lhs-store` | `$LABEL`, `$TYPE`, `$N`, `$OFFSET` | Put the value of the left side on the stack |
| `major-ref` | `$OFFSET` | The token number of a right-side symbol. It replaces `@X`. |

`$TYPE` is the type of the symbol and `$N` is the number of that type.
`$OFFSET` is the position of the stack entry relative to the top of the
stack. It is 0 or negative for right-side symbols. For the left side of a
rule without right-side symbols it is 1.

For a rule with labels the generator writes this, in this order:

    {
      the text of lhs-decl or lhs-fetch
      the text of rhs-fetch, for each label of the right side
      { the action code of the grammar }
      the text of lhs-store
    }

A rule without action code gets no text. The value of its first right-side
symbol stays at its place on the stack and becomes the value of the left
side.

## Limits of the first version

For a custom template the generator reports an error, and writes no parser
file, for each of these:

- A grammar with a destructor (`%destructor`, `%token_destructor`,
  `%default_destructor`)
- A grammar with `%realloc`, `%free` or `%stack_size_limit`
- The option `-m`

Each template decides what it does with the error symbol, with
`%extra_argument` and with `%extra_context`. The generator writes
`YYERRORSYMBOL` and the texts of `extra-argument` and `extra-context` for
every template.

In every code block of the grammar the generator reads `/*` and `//` as the
start of a comment. A target language that uses these characters for
something else needs a change of the generator.

In a line directive of C, the generator doubles each backslash of the file
name. `$FILE` has the file name without a change.

## Steps to a template for a new language

1. Copy `lempar.c` and translate the driver between the marks. Keep the
   marks and their order.
2. Write the `%%syntax` lines at the start of the file. Start from the lines
   of `lempar.go` or `lempar.rs`.
3. Decide what the template does with the error symbol, the extra argument
   and the extra context. If it does not support one of them, make the
   compiler of the target language refuse a grammar that uses it.
   `lempar.go` and `lempar.rs` show one way.
4. Add the language to the tests: the calculator in `test/calc/` and the
   recognizers in `test/recognizer/`. The parsers must print the lines that
   the C parser prints.

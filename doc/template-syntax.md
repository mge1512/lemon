# Target language syntax from the template

This note describes the change that this repository makes to Lemon. It is the
plan for the work and the reference for people who write a template.

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

`NAME` is one of the names in the tables below. `TEXT` is the text that the
generator writes. In `TEXT`:

- `\n`, `\t`, `\\` and `\"` have their usual meaning.
- `$WORD` or `${WORD}` is a placeholder. The generator puts a value there.
  The tables say which placeholders each name has.
- `$$` is one dollar sign.

The `%%syntax` lines are not copied to the parser file.

A template without `%%syntax` lines gets the C syntax of the original
generator, byte for byte. This is the case for `lempar.c`. The generator
names no language other than C.

A template with at least one `%%syntax` line is called a custom template in
this note. The generator has no built-in syntax for a custom template other
than what the tables say.

## What stays the same for every language

Some inserted text is the same for all templates:

- The comment at the top of the parser file and the comments in the tables
  have the form `/* ... */`. The target language must accept such comments.
- A table entry is a number and a comma. A name in a table is a string in
  double quotes and a comma.
- The code blocks of the grammar (`%include`, `%syntax_error` and so on) and
  the action code are copied. They are in the target language.
- The generator puts an action in braces: `{` and `}`.

## Names for files and lines

| Name | Placeholders | Meaning | C default |
|---|---|---|---|
| `file-suffix` | | Suffix of the parser file | `.c` |
| `line` | `$LINE`, `$FILE` | A line directive. An empty text means no line directives. | `#line $LINE "$FILE"` |
| `default-token-type` | | Type of a token when the grammar has no `%token_type` | `void*` |

A custom template gets no separate header file with the token numbers. The
token numbers are in the parser file.

## Names for constants and types

| Name | Placeholders | Meaning |
|---|---|---|
| `const` | `$NAME`, `$VALUE` | An integer constant |
| `type` | `$NAME`, `$TYPE` | A name for a type |
| `token` | `$NAME`, `$VALUE` | The number of a token. `$NAME` has the token prefix. |
| `tokens-begin`, `tokens-end` | | Text before and after the token numbers |
| `type-uint8`, `type-uint16`, `type-uint32` | | Names of the unsigned integer types |
| `type-int8`, `type-int16`, `type-int32` | | Names of the signed integer types |
| `extra-argument` | `$NAME`, `$DECL`, `$ID` | The grammar has `%extra_argument {DECL}`. `$ID` is the last identifier of `DECL`. `$NAME` is the name of the parser. |
| `no-extra-argument` | `$NAME` | The grammar has no `%extra_argument` |
| `extra-context`, `no-extra-context` | as above | The same for `%extra_context` |

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

The generator writes these types with `type`: `YYCODETYPE`, `YYACTIONTYPE`
and the token type. The name of the token type is the parser name followed by
`TOKENTYPE`.

The C preprocessor lines of the original (`#undef`, `#ifndef`, `#endif`,
`#if INTERFACE`) and the macros `YYREALLOC`, `YYFREE`, `YYDYNSTACK` and
`YYSIZELIMIT` are written only for C.

## Names for the value stack

Each entry of the parser stack has a value. The type of the value depends on
the symbol. The generator gives every type a number N. Tokens have N = 0.

| Name | Placeholders | Meaning |
|---|---|---|
| `union-begin` | `$NAME` | Start of the type `YYMINORTYPE`. This text also has the member for tokens. `$NAME` is the name of the parser. |
| `union-member` | `$TYPE`, `$N` | One member for the type with number N |
| `union-end` | | End of the type |

## Names for tables

| Name | Placeholders | Meaning |
|---|---|---|
| `array-begin` | `$NAME`, `$TYPE`, `$COUNT` | Start of a constant table of integers |
| `array-end` | | End of the table |

The tables are `yy_action`, `yy_lookahead`, `yy_shift_ofst`,
`yy_reduce_ofst` and `yy_default`. `$TYPE` is `YYACTIONTYPE`, `YYCODETYPE`
or one of the integer type names.

The other tables (fallback, token names, rule names, rule information) start
and end in the template text.

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
| `lhs-decl` | `$LABEL`, `$TYPE` | Declare the label of the left side |
| `lhs-fetch` | `$LABEL`, `$TYPE`, `$N`, `$OFFSET` | The left side and the first right-side symbol have the same label. Declare it with the value from the stack, so that the action can change it. |
| `lhs-store` | `$LABEL`, `$TYPE`, `$N`, `$OFFSET` | Put the value of the left side on the stack |
| `major-ref` | `$OFFSET` | The token number of a right-side symbol. It replaces `@X`. |

`$OFFSET` is the position of the stack entry relative to the top of the
stack. It is 0 or negative for right-side symbols. For the left side of a
rule without right-side symbols it is 1.

## Limits of the first version

- Destructors (`%destructor`, `%token_destructor`, `%default_destructor`)
  work only with C syntax. With a custom template the generator reports an
  error for a grammar that has one.
- The option `-m` works only with C syntax. With a custom template the
  generator reports an error.
- The generator supports the `error` symbol for every template: it writes
  `YYERRORSYMBOL`. Each template decides whether it supports the symbol.

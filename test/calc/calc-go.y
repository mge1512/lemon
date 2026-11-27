// The calculator of test/grammars/calc.y with actions in Go, for the
// template tool/lempar.go. It has no destructors, because that template
// does not support them.
%name Calc
%token_prefix TK_
%token_type {int}
%default_type {int}
%type exprlist {calcList}
%extra_argument {*calcState}
%include {
package main

type calcList struct{ n, sum int }
type calcState struct{ result, count, nError, accepted int }
}
%left PLUS MINUS.
%left TIMES DIVIDE.
%right POW.
%nonassoc UMINUS.

%syntax_error    { yyarg.nError++ }
%parse_failure   { yyarg.nError += 100 }
%parse_accept    { yyarg.accepted = 1 }
%stack_overflow  { yyarg.nError += 1000 }

program ::= exprlist(L).               { yyarg.result = L.sum; yyarg.count = L.n }
exprlist(A) ::= expr(B).               { A.n = 1; A.sum = B }
exprlist(A) ::= exprlist(A) COMMA expr(B).  { A.n++; A.sum += B }
exprlist ::= exprlist SEMI.
expr(A) ::= expr(B) PLUS|MINUS(OP) expr(C). { _ = OP; if @OP == TK_PLUS { A = B + C } else { A = B - C } }
expr(A) ::= expr(B) TIMES expr(C).     { A = B * C }
expr(A) ::= expr(B) DIVIDE expr(C).    { if C != 0 { A = B / C } else { A = 0 } }
expr(A) ::= expr(A) POW NUMBER(B).     { r := 1; for i := 0; i < B; i++ { r *= A }; A = r }
expr(A) ::= MINUS expr(B). [UMINUS]    { A = -B }
expr(A) ::= LPAREN expr(B) RPAREN.     { A = B }
expr(A) ::= NUMBER(B).                 { A = B }
expr(A) ::= ABS LPAREN expr(B) RPAREN. { if B < 0 { A = -B } else { A = B } }

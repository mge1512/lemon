// A calculator grammar for the tests of this repository. The actions are C.
// It uses many features of Lemon on purpose: typed symbols, precedence, a
// rule with two tokens in one place, the code of a token (@OP), a label that
// the left side shares with the right side, an extra argument, a destructor
// and the code blocks for errors.
%name Calc
%token_prefix TK_
%token_type {int}
%default_type {int}
%type exprlist {struct calc_list}
%extra_argument {struct calc_state *pState}
%include {
#include <assert.h>
struct calc_list { int n; int sum; };
struct calc_state { int result; int count; int nError; int accepted; };
}
%left PLUS MINUS.
%left TIMES DIVIDE.
%right POW.
%nonassoc UMINUS.

%syntax_error    { pState->nError++; (void)yymajor; (void)yyminor; }
%parse_failure   { pState->nError += 100; }
%parse_accept    { pState->accepted = 1; }
%stack_overflow  { pState->nError += 1000; }
%token_destructor { (void)pState; (void)$$; }
%destructor exprlist { (void)$$.n; }

program ::= exprlist(L).               { pState->result = L.sum; pState->count = L.n; }
exprlist(A) ::= expr(B).               { A.n = 1; A.sum = B; }
exprlist(A) ::= exprlist(A) COMMA expr(B).  { A.n++; A.sum += B; }
exprlist ::= exprlist SEMI.
expr(A) ::= expr(B) PLUS|MINUS(OP) expr(C). { A = @OP==TK_PLUS ? B+C : B-C; }
expr(A) ::= expr(B) TIMES expr(C).     { A = B*C; }
expr(A) ::= expr(B) DIVIDE expr(C).    { A = C ? B/C : 0; }
expr(A) ::= expr(A) POW NUMBER(B).     { int i, r = 1; for(i=0; i<B; i++) r *= A; A = r; }
expr(A) ::= MINUS expr(B). [UMINUS]    { A = -B; }
expr(A) ::= LPAREN expr(B) RPAREN.     { A = B; }
expr(A) ::= NUMBER(B).                 { A = B; }
expr(A) ::= ABS(X) LPAREN expr(B) RPAREN.  { (void)X; A = B<0 ? -B : B; /*A-overwrites-X*/ }

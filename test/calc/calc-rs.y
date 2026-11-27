// The calculator of test/grammars/calc.y with actions in Rust, for the
// template tool/lempar.rs. It has no destructors, because that template
// does not support them.
%name Calc
%token_prefix TK_
%token_type {i64}
%default_type {i64}
%type exprlist {CalcList}
%extra_argument {CalcState}
%include {
pub struct CalcList { n: i64, sum: i64 }

#[derive(Default)]
pub struct CalcState { pub result: i64, pub count: i64, pub nError: i64, pub accepted: i64 }

// A lifetime. The generator must not read an apostrophe as the start
// of a character literal to find the end of this code block.
pub fn calc_label<'a>(name: &'a str) -> &'a str { name }
}
%left PLUS MINUS.
%left TIMES DIVIDE.
%right POW.
%nonassoc UMINUS.

%syntax_error    { yyarg.nError += 1; }
%parse_failure   { yyarg.nError += 100; }
%parse_accept    { yyarg.accepted = 1; }
%stack_overflow  { yyarg.nError += 1000; }

program ::= exprlist(L).               { yyarg.result = L.sum; yyarg.count = L.n; }
exprlist(A) ::= expr(B).               { A = CalcList { n: 1, sum: B }; }
exprlist(A) ::= exprlist(A) COMMA expr(B).  { A.n += 1; A.sum += B; }
exprlist ::= exprlist SEMI.
expr(A) ::= expr(B) PLUS|MINUS(OP) expr(C). { let _ = OP; A = if @OP == TK_PLUS { B + C } else { B - C }; }
expr(A) ::= expr(B) TIMES expr(C).     { A = B * C; }
expr(A) ::= expr(B) DIVIDE expr(C).    { A = if C != 0 { B / C } else { 0 }; }
expr(A) ::= expr(A) POW NUMBER(B).     { let mut r = 1; for _ in 0..B { r *= A; } A = r; }
expr(A) ::= MINUS expr(B). [UMINUS]    { A = -B; }
expr(A) ::= LPAREN expr(B) RPAREN.     { A = B; }
expr(A) ::= NUMBER(B).                 { A = B; }
expr(A) ::= ABS LPAREN expr(B) RPAREN. { A = if B < 0 { -B } else { B }; }

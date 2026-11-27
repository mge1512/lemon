// A grammar for the tests of this repository. It uses the features that the
// calculator does not use: the error symbol, fallback tokens, a wildcard
// token, a token class, conditional parts, a context argument, a default
// destructor and rules without code.
%token_prefix T_
%token_type {const char*}
%default_type {int}
%extra_context {struct ctx *pCtx}
%include {
struct ctx { int nStmt; int nErr; };
}
%fallback ID ABORT ACTION AFTER.
%wildcard ANY.
%token_class number INTEGER|FLOAT.
%default_destructor { (void)pCtx; (void)$$; }
%syntax_error { pCtx->nErr++; }

input ::= stmtlist.
stmtlist ::= .
stmtlist ::= stmtlist stmt SEMI.
stmt ::= error.                         { pCtx->nErr++; }
stmt(A) ::= SET ID(N) EQ value(V).      { A = V + (N!=0); pCtx->nStmt++; }
stmt(A) ::= SHOW idlist(L).             { A = L; pCtx->nStmt++; }
%ifdef WITH_DROP
stmt(A) ::= DROP ID.                    { A = 0; pCtx->nStmt++; }
%endif
value(A) ::= number(N).                 { A = N!=0; }
value(A) ::= STRING.                    { A = 2; }
value(A) ::= LP ANY RP.                 { A = 3; }
idlist(A) ::= ID.                       { A = 1; }
idlist(A) ::= idlist(A) COMMA ID.       { A++; }

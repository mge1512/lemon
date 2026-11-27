// A small grammar without actions that uses fallback tokens, a wildcard
// token and a token class. The tests put a few lines in front of these
// rules, one set for each target language (../head-c.y, ../head-go.y,
// ../head-rs.y).

%fallback ID ABORT ACTION AFTER.
%wildcard ANY.
%token_class number INTEGER|FLOAT.

input ::= stmtlist.
stmtlist ::= .
stmtlist ::= stmtlist stmt SEMI.
stmt ::= SET ID EQ value.
stmt ::= SHOW idlist.
value ::= number.
value ::= STRING.
value ::= LP ANY RP.
idlist ::= ID.
idlist ::= idlist COMMA ID.

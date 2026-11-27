%name Aql
%token_prefix T_
%token_type {i32}
%extra_argument {i32}
%syntax_error { *yyarg = 1; }

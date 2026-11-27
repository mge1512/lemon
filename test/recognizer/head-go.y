%name Aql
%token_prefix T_
%token_type {int}
%extra_argument {*int}
%include { package main }
%syntax_error { *yyarg = 1 }

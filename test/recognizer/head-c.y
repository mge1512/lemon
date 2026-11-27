%name Aql
%token_prefix T_
%token_type {int}
%extra_argument {int *pError}
%syntax_error { *pError = 1; (void)yymajor; (void)yyminor; }

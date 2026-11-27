%%syntax file-suffix ".rs"
%%syntax line ""
%%syntax default-token-type "()"
%%syntax const "pub const $NAME: i32 = $VALUE;\n"
%%syntax type "pub type $NAME = $TYPE;\n"
%%syntax token "pub const $NAME: i32 = $VALUE;\n"
%%syntax type-uint8 "u8"
%%syntax type-uint16 "u16"
%%syntax type-uint32 "u32"
%%syntax type-int8 "i8"
%%syntax type-int16 "i16"
%%syntax type-int32 "i32"
%%syntax extra-argument "pub type ${NAME}ARGTYPE = $DECL;\n"
%%syntax no-extra-argument "pub type ${NAME}ARGTYPE = ();\n"
%%syntax extra-context "const _: () = ${NAME}_this_template_has_no_extra_context;\n"
%%syntax union-begin "pub enum YYMINORTYPE {\n    yyinit,\n    yy0(${NAME}TOKENTYPE),\n"
%%syntax union-member "    yy$N($TYPE),\n"
%%syntax union-end "}\n"
%%syntax array-begin "static $NAME: &[$TYPE] = &[\n"
%%syntax array-end "];\n"
%%syntax case-first "        $VALUE /* $TEXT */"
%%syntax case-next "\n        | $VALUE /* $TEXT */"
%%syntax case-begin " => {\n"
%%syntax case-end "        }\n"
%%syntax default-begin "        _ => {\n"
%%syntax default-item "            /* ($VALUE) $TEXT */\n"
%%syntax default-end "        }\n"
%%syntax rhs-fetch "    let $LABEL = match std::mem::replace(&mut yypParser.yystack[(yysp+($OFFSET)) as usize].minor, YYMINORTYPE::yyinit) { YYMINORTYPE::yy$N(v) => v, _ => unreachable!() };\n"
%%syntax lhs-decl "    let $LABEL: $TYPE;\n"
%%syntax lhs-fetch "    let mut $LABEL = match std::mem::replace(&mut yypParser.yystack[(yysp+($OFFSET)) as usize].minor, YYMINORTYPE::yyinit) { YYMINORTYPE::yy$N(v) => v, _ => unreachable!() };\n"
%%syntax lhs-store "    yypParser.yystack[(yysp+($OFFSET)) as usize].minor = YYMINORTYPE::yy$N($LABEL);\n"
%%syntax major-ref "(yypParser.yystack[(yysp+($OFFSET)) as usize].major as i32)"
/*
** Driver template for the LEMON parser generator, for the Rust language.
**
** This file is a translation of the C driver template lempar.c of SQLite
** 3.54.1.  The lines that start with "%%syntax" tell the generator how to
** write constants, types, tables, cases and the code around an action in
** Rust.  The generator does not copy these lines.
**
** Rules for a grammar that uses this template:
**
**   *  The parser file is one module.  Use it with "mod".  The code of
**      %include is at the start of the module.  It must not start with a
**      comment, because the generator then leaves out the lines up to the
**      mark below, with the allow attribute.
**   *  %token_type and the types of %type are Rust types.
**   *  %extra_argument has a type only, for example {State}.  The parser
**      owns a value of this type.  The code of the grammar reaches it under
**      the name yyarg, and the caller reaches it as the field yyarg.
**   *  The code blocks of the grammar must not have a lifetime such as 'a,
**      because the generator reads the apostrophe as the start of a
**      character.
**   *  The error symbol, destructors and %extra_context are not supported.
**      Rust drops the values on the stack by itself.
**
** The parser is used like the C parser: ParseAlloc() makes a parser, and
** Parse() takes one token for each call.  The token number 0 is the end of
** the input.
*/
#![allow(non_snake_case, non_camel_case_types, non_upper_case_globals)]
#![allow(dead_code, unused_variables, unused_mut, unused_braces)]
#![allow(unused_parens, unused_assignments, unreachable_patterns)]
%%
/* These constants are the numbers of the terminal symbols.
***************** Begin token definitions *************************************/
%%
/**************** End token definitions ***************************************/

/* The next section has the constants and types that the generator makes
** for one grammar.  The comment in lempar.c describes each name.
************* Begin control definitions ***************************************/
%%
/************* End control definitions *****************************************/

/* This template does not support the error symbol.  The next line does not
** compile for a grammar that uses it. */
const _: () = assert!(YYERRORSYMBOL == 0);

/* Next are the tables used to determine what action to take based on the
** current state and lookahead token.  The comment in lempar.c describes
** the tables.
**
*********** Begin parsing tables **********************************************/
%%
/********** End of lemon-generated parsing tables *****************************/

/* The next table maps tokens (terminal symbols) into fallback tokens.
** If a construct like the following:
**
**      %fallback ID X Y Z.
**
** appears in the grammar, then ID becomes a fallback token for X, Y,
** and Z.  Whenever one of the tokens X, Y, or Z is input to the parser
** but it does not parse, the type of the token is changed to ID and
** the parse is retried before an error is thrown.
*/
static yyFallback: &[YYCODETYPE] = &[
%%
];

/* The following structure represents a single element of the
** parser's stack.  Information stored includes:
**
**   +  The state number for the parser at this level of the stack.
**
**   +  The value of the token stored at this level of the stack.
**      (In other words, the "major" token.)
**
**   +  The semantic value stored at this level of the stack.  This is
**      the information used by the action routines in the grammar.
**      It is sometimes called the "minor" token.
**
** After the "shift" half of a SHIFTREDUCE action, the stateno field
** actually contains the reduce action for the second half of the
** SHIFTREDUCE.
*/
struct yyStackEntry {
    stateno: YYACTIONTYPE, /* The state-number, or reduce action in SHIFTREDUCE */
    major: YYCODETYPE,     /* The major token value */
    minor: YYMINORTYPE,    /* The user-supplied minor token value */
}

/* The state of the parser is completely contained in an instance of
** the following structure.  The last entry of yystack is the top of the
** stack.  The first entry is always there and has the state 0. */
pub struct yyParser {
    yyerrcnt: i32,               /* Shifts left before out of the error */
    pub yyarg: ParseARGTYPE,     /* A place to hold %extra_argument */
    yytrace: Option<fn(&str)>,   /* The function that gets trace messages */
    yystack: Vec<yyStackEntry>,  /* The parser stack */
}

/*
** Turn parser tracing on by giving a function that takes each message.
** Turn it off by giving None.
*/
pub fn ParseTrace(yypParser: &mut yyParser, trace: Option<fn(&str)>) {
    yypParser.yytrace = trace;
}

/* For tracing shifts, the names of all terminals and nonterminals
** are required.  The following table supplies these names */
static yyTokenName: &[&str] = &[
%%
];

/* For tracing reduce actions, the names of all rules are required.
*/
static yyRuleName: &[&str] = &[
%%
];

/* Initialize a parser again.  The value of %extra_argument stays.
*/
pub fn ParseInit(yypParser: &mut yyParser) {
    yypParser.yyerrcnt = -1;
    yypParser.yystack.clear();
    yypParser.yystack.push(yyStackEntry { stateno: 0, major: 0, minor: YYMINORTYPE::yyinit });
}

/*
** This function makes a new parser.  The parser owns the value of
** %extra_argument.
*/
pub fn ParseAlloc(yyarg: ParseARGTYPE) -> yyParser {
    let mut yypParser = yyParser { yyerrcnt: -1, yyarg, yytrace: None, yystack: Vec::new() };
    ParseInit(&mut yypParser);
    yypParser
}

/* This template has no destructors.  The generator puts nothing at the
** next mark for a template of this kind. */
%%

/*
** Pop the parser's stack once.
*/
fn yy_pop_parser_stack(yypParser: &mut yyParser) {
    if let Some(yytos) = yypParser.yystack.pop() {
        if let Some(trace) = yypParser.yytrace {
            trace(&format!("Popping {}", yyTokenName[yytos.major as usize]));
        }
    }
}

/*
** Clear all secondary memory allocations from the parser
*/
pub fn ParseFinalize(yypParser: &mut yyParser) {
    while yypParser.yystack.len() > 1 {
        yy_pop_parser_stack(yypParser);
    }
}

/*
** Find the appropriate action for a parser given the terminal
** look-ahead token iLookAhead.
*/
fn yy_find_shift_action(yypParser: &yyParser, iLookAhead: YYCODETYPE, stateno: YYACTIONTYPE) -> YYACTIONTYPE {
    if (stateno as i32) > YY_MAX_SHIFT {
        return stateno;
    }
    let mut iLookAhead = iLookAhead;
    loop {
        let i = yy_shift_ofst[stateno as usize] as i32 + iLookAhead as i32;
        if yy_lookahead[i as usize] != iLookAhead {
            if YYFALLBACK != 0 {
                let iFallback = yyFallback[iLookAhead as usize];
                if iFallback != 0 {
                    if let Some(trace) = yypParser.yytrace {
                        trace(&format!("FALLBACK {} => {}",
                            yyTokenName[iLookAhead as usize], yyTokenName[iFallback as usize]));
                    }
                    iLookAhead = iFallback;
                    continue;
                }
            }
            if YYWILDCARD > 0 {
                let j = i - iLookAhead as i32 + YYWILDCARD;
                if yy_lookahead[j as usize] as i32 == YYWILDCARD && iLookAhead > 0 {
                    if let Some(trace) = yypParser.yytrace {
                        trace(&format!("WILDCARD {} => {}",
                            yyTokenName[iLookAhead as usize], yyTokenName[YYWILDCARD as usize]));
                    }
                    return yy_action[j as usize];
                }
            }
            return yy_default[stateno as usize];
        } else {
            return yy_action[i as usize];
        }
    }
}

/*
** Find the appropriate action for a parser given the non-terminal
** look-ahead token iLookAhead.
*/
fn yy_find_reduce_action(stateno: YYACTIONTYPE, iLookAhead: YYCODETYPE) -> YYACTIONTYPE {
    let i = yy_reduce_ofst[stateno as usize] as i32 + iLookAhead as i32;
    yy_action[i as usize]
}

/*
** The following routine is called if the stack overflows.
*/
fn yyStackOverflow(yypParser: &mut yyParser) {
    if let Some(trace) = yypParser.yytrace {
        trace("Stack Overflow!");
    }
    while yypParser.yystack.len() > 1 {
        yy_pop_parser_stack(yypParser);
    }
    let yyarg = &mut yypParser.yyarg;
    /* Here code is inserted which will execute if the parser
    ** stack every overflows */
/******** Begin %stack_overflow code ******************************************/
%%
/******** End %stack_overflow code ********************************************/
}

/*
** Print tracing information for a SHIFT action
*/
fn yyTraceShift(yypParser: &yyParser, yyNewState: i32, zTag: &str) {
    if let Some(trace) = yypParser.yytrace {
        let zToken = yyTokenName[yypParser.yystack[yypParser.yystack.len() - 1].major as usize];
        if yyNewState < YYNSTATE {
            trace(&format!("{} '{}', go to state {}", zTag, zToken, yyNewState));
        } else {
            trace(&format!("{} '{}', pending reduce {}", zTag, zToken, yyNewState - YY_MIN_REDUCE));
        }
    }
}

/*
** Perform a shift action.
*/
fn yy_shift(yypParser: &mut yyParser, yyNewState: YYACTIONTYPE, yyMajor: YYCODETYPE, yyMinor: ParseTOKENTYPE) {
    if YYSTACKDEPTH > 0 && yypParser.yystack.len() as i32 >= YYSTACKDEPTH {
        yyStackOverflow(yypParser);
        return;
    }
    let mut yyNewState = yyNewState as i32;
    if yyNewState > YY_MAX_SHIFT {
        yyNewState += YY_MIN_REDUCE - YY_MIN_SHIFTREDUCE;
    }
    yypParser.yystack.push(yyStackEntry {
        stateno: yyNewState as YYACTIONTYPE,
        major: yyMajor,
        minor: YYMINORTYPE::yy0(yyMinor),
    });
    yyTraceShift(yypParser, yyNewState, "Shift");
}

/* For rule J, yyRuleInfoLhs[J] contains the symbol on the left-hand side
** of that rule */
static yyRuleInfoLhs: &[YYCODETYPE] = &[
%%
];

/* For rule J, yyRuleInfoNRhs[J] contains the negative of the number
** of symbols on the right-hand side of that rule. */
static yyRuleInfoNRhs: &[i16] = &[
%%
];

/*
** Perform a reduce action and the shift that must immediately
** follow the reduce.
**
** The yyLookahead and yyLookaheadToken parameters provide reduce actions
** access to the lookahead token (if any).  The yyLookahead will be YYNOCODE
** if the lookahead token has already been consumed.  As this procedure is
** only called from one place, optimizing compilers will in-line it, which
** means that the extra parameters have no performance impact.
*/
fn yy_reduce(yypParser: &mut yyParser, yyruleno: usize, yyLookahead: i32, yyLookaheadToken: &ParseTOKENTYPE) -> YYACTIONTYPE {
    /* yysp is the place of the top of the stack.  The action code reads
    ** the values of the right-hand side at yysp and below it. */
    let yysp: isize = yypParser.yystack.len() as isize - 1;
    if yyRuleInfoNRhs[yyruleno] == 0 {
        /* The value of a rule with an empty right-hand side goes into a
        ** new entry above the top of the stack. */
        yypParser.yystack.push(yyStackEntry { stateno: 0, major: 0, minor: YYMINORTYPE::yyinit });
    }
    {
        let yyarg = &mut yypParser.yyarg;
        match yyruleno {
        /* Beginning here are the reduction cases.  A typical example
        ** follows:
        **   0 => {
        **     { ... }           // User supplied code
        **   }
        */
/********** Begin reduce actions **********************************************/
%%
/********** End reduce actions ************************************************/
        };
    }
    let yygoto = yyRuleInfoLhs[yyruleno];
    let yysize = yyRuleInfoNRhs[yyruleno] as isize;
    let yyact = yy_find_reduce_action(yypParser.yystack[(yysp + yysize) as usize].stateno, yygoto);
    let yysp = yysp + yysize + 1;
    yypParser.yystack.truncate(yysp as usize + 1);
    yypParser.yystack[yysp as usize].stateno = yyact;
    yypParser.yystack[yysp as usize].major = yygoto;
    yyTraceShift(yypParser, yyact as i32, "... then shift");
    yyact
}

/*
** The following code executes when the parse fails
*/
fn yy_parse_failed(yypParser: &mut yyParser) {
    if let Some(trace) = yypParser.yytrace {
        trace("Fail!");
    }
    while yypParser.yystack.len() > 1 {
        yy_pop_parser_stack(yypParser);
    }
    let yyarg = &mut yypParser.yyarg;
    /* Here code is inserted which will be executed whenever the
    ** parser fails */
/************ Begin %parse_failure code ***************************************/
%%
/************ End %parse_failure code *****************************************/
}

/*
** The following code executes when a syntax error first occurs.
*/
fn yy_syntax_error(yypParser: &mut yyParser, yymajor: i32, yyminor: &ParseTOKENTYPE) {
    let yyarg = &mut yypParser.yyarg;
    let TOKEN = yyminor;
/************ Begin %syntax_error code ****************************************/
%%
/************ End %syntax_error code ******************************************/
}

/*
** The following is executed when the parser accepts
*/
fn yy_accept(yypParser: &mut yyParser) {
    if let Some(trace) = yypParser.yytrace {
        trace("Accept!");
    }
    yypParser.yyerrcnt = -1;
    let yyarg = &mut yypParser.yyarg;
    /* Here code is inserted which will be executed whenever the
    ** parser accepts */
/*********** Begin %parse_accept code *****************************************/
%%
/*********** End %parse_accept code *******************************************/
}

/* The main parser program.
** The first argument is a parser from ParseAlloc().  The second argument
** is the major token number.  The third is the minor token.
**
** Inputs:
** <ul>
** <li> The parser.
** <li> The major token number.
** <li> The minor token number.
** </ul>
**
** Outputs:
** None.
*/
pub fn Parse(yypParser: &mut yyParser, yymajor: i32, yyminor: ParseTOKENTYPE) {
    let yyendofinput = yymajor == 0; /* True if we are at the end of input */
    let mut yyact = yypParser.yystack[yypParser.yystack.len() - 1].stateno;
    if let Some(trace) = yypParser.yytrace {
        if (yyact as i32) < YY_MIN_REDUCE {
            trace(&format!("Input '{}' in state {}", yyTokenName[yymajor as usize], yyact));
        } else {
            trace(&format!("Input '{}' with pending reduce {}",
                yyTokenName[yymajor as usize], yyact as i32 - YY_MIN_REDUCE));
        }
    }
    loop { /* Exit by "break" */
        yyact = yy_find_shift_action(yypParser, yymajor as YYCODETYPE, yyact);
        if (yyact as i32) >= YY_MIN_REDUCE {
            let yyruleno = (yyact as i32 - YY_MIN_REDUCE) as usize; /* Reduce by this rule */
            if let Some(trace) = yypParser.yytrace {
                trace(&format!("Reduce {} [{}]", yyruleno, yyRuleName[yyruleno]));
            }
            /* Check that the stack is large enough to grow by a single entry
            ** if the RHS of the rule is empty.  This ensures that there is room
            ** enough on the stack to push the LHS value */
            if yyRuleInfoNRhs[yyruleno] == 0 && YYSTACKDEPTH > 0
                && yypParser.yystack.len() as i32 >= YYSTACKDEPTH
            {
                yyStackOverflow(yypParser);
                break;
            }
            yyact = yy_reduce(yypParser, yyruleno, yymajor, &yyminor);
        } else if (yyact as i32) <= YY_MAX_SHIFTREDUCE {
            yy_shift(yypParser, yyact, yymajor as YYCODETYPE, yyminor);
            yypParser.yyerrcnt -= 1;
            break;
        } else if (yyact as i32) == YY_ACCEPT_ACTION {
            yypParser.yystack.pop();
            yy_accept(yypParser);
            return;
        } else {
            /* A syntax error has occurred.  This template handles it in the
            ** way of lempar.c for a grammar without the error symbol:
            **
            **  * Report an error message, and throw away the input token.
            **
            **  * If the input token is $, then fail the parse.
            **
            ** As before, subsequent error messages are suppressed until
            ** three input tokens have been successfully shifted.
            */
            if let Some(trace) = yypParser.yytrace {
                trace("Syntax Error!");
            }
            if yypParser.yyerrcnt <= 0 {
                yy_syntax_error(yypParser, yymajor, &yyminor);
            }
            yypParser.yyerrcnt = 3;
            if yyendofinput {
                yy_parse_failed(yypParser);
                yypParser.yyerrcnt = -1;
            }
            break;
        }
    }
}

/*
** Return the fallback token corresponding to canonical token iToken, or
** 0 if iToken has no fallback.
*/
pub fn ParseFallback(iToken: i32) -> i32 {
    if YYFALLBACK != 0 {
        yyFallback[iToken as usize] as i32
    } else {
        0
    }
}

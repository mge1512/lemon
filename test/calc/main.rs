// Test program for the calculator parser in Rust.
//
// Usage:  calc INPUTFILE [trace]
// Each line of the input file is one input for the parser. The program
// prints one result line for each input line. With the word "trace" it
// also prints the trace messages of the parser.

#[path = "calc-rs.rs"]
mod calc;

use calc::*;
use std::io::BufRead;

fn print_trace(msg: &str) {
    println!("{}", msg);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 || args.len() > 3 {
        eprintln!("usage: calc INPUTFILE [trace]");
        std::process::exit(2);
    }
    let trace = args.len() == 3;
    let file = match std::fs::File::open(&args[1]) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("{}", e);
            std::process::exit(2);
        }
    };
    for line in std::io::BufReader::new(file).lines() {
        let line = line.unwrap();
        let b = line.as_bytes();
        let mut p = CalcAlloc(CalcState::default());
        if trace {
            CalcTrace(&mut p, Some(print_trace));
        }
        let mut i = 0;
        while i < b.len() {
            let c = b[i];
            if c.is_ascii_digit() {
                let mut v: i64 = 0;
                while i < b.len() && b[i].is_ascii_digit() {
                    v = v * 10 + (b[i] - b'0') as i64;
                    i += 1;
                }
                Calc(&mut p, TK_NUMBER, v);
                continue;
            }
            if line[i..].starts_with("abs") {
                Calc(&mut p, TK_ABS, 0);
                i += 3;
                continue;
            }
            let tok = match c {
                b'+' => TK_PLUS,
                b'-' => TK_MINUS,
                b'*' => TK_TIMES,
                b'/' => TK_DIVIDE,
                b'^' => TK_POW,
                b'(' => TK_LPAREN,
                b')' => TK_RPAREN,
                b',' => TK_COMMA,
                b';' => TK_SEMI,
                _ => 0,
            };
            if tok != 0 {
                Calc(&mut p, tok, 0);
            }
            i += 1;
        }
        Calc(&mut p, 0, 0);
        CalcFinalize(&mut p);
        let label = if line.len() > 24 { format!("{}...", &line[..24]) } else { line.clone() };
        println!(
            "{} => result={} count={} errors={} accepted={}",
            label, p.yyarg.result, p.yyarg.count, p.yyarg.nError, p.yyarg.accepted
        );
    }
}

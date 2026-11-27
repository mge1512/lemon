// Test program for the recognizer in Rust.
//
// Usage:  recognizer INPUTFILE
// Each line of the input file is a list of token numbers. The program
// prints "accept", or "refuse at N" where N is the place of the first
// token that the parser refuses. The end of the input counts as a token.

mod aql;

use aql::*;
use std::io::BufRead;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 2 {
        eprintln!("usage: recognizer INPUTFILE");
        std::process::exit(2);
    }
    let file = match std::fs::File::open(&args[1]) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("{}", e);
            std::process::exit(2);
        }
    };
    for line in std::io::BufReader::new(file).lines() {
        let line = line.unwrap();
        let mut p = AqlAlloc(0);
        let mut n = 0;
        for field in line.split_whitespace() {
            n += 1;
            Aql(&mut p, field.parse().unwrap(), 0);
            if p.yyarg != 0 {
                break;
            }
        }
        if p.yyarg == 0 {
            n += 1;
            Aql(&mut p, 0, 0);
        }
        if p.yyarg != 0 {
            println!("refuse at {}", n);
        } else {
            println!("accept");
        }
    }
}

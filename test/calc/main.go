// Test program for the calculator parser in Go.
//
// Usage:  calc INPUTFILE
// Each line of the input file is one input for the parser. The program
// prints one result line for each input line.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: calc INPUTFILE")
		os.Exit(2)
	}
	in, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	defer in.Close()
	single := map[byte]int{
		'+': TK_PLUS, '-': TK_MINUS, '*': TK_TIMES, '/': TK_DIVIDE, '^': TK_POW,
		'(': TK_LPAREN, ')': TK_RPAREN, ',': TK_COMMA, ';': TK_SEMI,
	}
	lines := bufio.NewScanner(in)
	for lines.Scan() {
		line := lines.Text()
		st := &calcState{}
		p := CalcAlloc()
		for i := 0; i < len(line); {
			c := line[i]
			switch {
			case c >= '0' && c <= '9':
				v := 0
				for i < len(line) && line[i] >= '0' && line[i] <= '9' {
					v = v*10 + int(line[i]-'0')
					i++
				}
				Calc(p, TK_NUMBER, v, st)
			case strings.HasPrefix(line[i:], "abs"):
				Calc(p, TK_ABS, 0, st)
				i += 3
			default:
				if tok, ok := single[c]; ok {
					Calc(p, tok, 0, st)
				}
				i++
			}
		}
		Calc(p, 0, 0, st)
		CalcFinalize(p)
		label := line
		if len(label) > 24 {
			label = label[:24] + "..."
		}
		fmt.Printf("%s => result=%d count=%d errors=%d accepted=%d\n",
			label, st.result, st.count, st.nError, st.accepted)
	}
}

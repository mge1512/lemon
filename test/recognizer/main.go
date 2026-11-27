// Test program for the recognizer in Go.
//
// Usage:  recognizer INPUTFILE [trace]
// Each line of the input file is a list of token numbers. The program
// prints "accept", or "refuse at N" where N is the place of the first
// token that the parser refuses. The end of the input counts as a token.
// With the word "trace" the program also prints the trace messages of the
// parser.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	if len(os.Args) < 2 || len(os.Args) > 3 {
		fmt.Fprintln(os.Stderr, "usage: recognizer INPUTFILE [trace]")
		os.Exit(2)
	}
	in, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	defer in.Close()
	if len(os.Args) == 3 {
		AqlTrace(func(msg string) { fmt.Println(msg) })
	}
	lines := bufio.NewScanner(in)
	for lines.Scan() {
		p := AqlAlloc()
		refused := 0
		n := 0
		for _, field := range strings.Fields(lines.Text()) {
			tok, _ := strconv.Atoi(field)
			n++
			Aql(p, tok, 0, &refused)
			if refused != 0 {
				break
			}
		}
		if refused == 0 {
			n++
			Aql(p, 0, 0, &refused)
		}
		AqlFinalize(p)
		if refused != 0 {
			fmt.Printf("refuse at %d\n", n)
		} else {
			fmt.Println("accept")
		}
	}
}

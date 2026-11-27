/*
** Test program for the calculator parser in C.
**
** The generated file calc.c is included here, so that this program sees
** the token numbers and the type of the parser state.
**
** Usage:  calc INPUTFILE [trace]
** Each line of the input file is one input for the parser.  The program
** prints one result line for each input line.  With the word "trace" it
** also prints the trace messages of the parser.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "calc.c"

int main(int argc, char **argv){
  static char line[4096];
  FILE *in;
  if( argc<2 || argc>3 || (in = fopen(argv[1],"r"))==0 ){
    fprintf(stderr,"usage: calc INPUTFILE [trace]\n");
    return 2;
  }
  if( argc==3 ) CalcTrace(stdout, "");
  while( fgets(line,sizeof(line),in) ){
    struct calc_state st = {0,0,0,0};
    void *p = CalcAlloc(malloc);
    int n = (int)strlen(line);
    int i = 0;
    while( n>0 && (line[n-1]=='\n' || line[n-1]=='\r') ) line[--n] = 0;
    while( i<n ){
      char c = line[i];
      if( c>='0' && c<='9' ){
        int v = 0;
        while( i<n && line[i]>='0' && line[i]<='9' ) v = v*10 + (line[i++]-'0');
        Calc(p, TK_NUMBER, v, &st);
        continue;
      }
      if( strncmp(&line[i],"abs",3)==0 ){
        Calc(p, TK_ABS, 0, &st);
        i += 3;
        continue;
      }
      switch( c ){
        case '+': Calc(p, TK_PLUS, 0, &st);   break;
        case '-': Calc(p, TK_MINUS, 0, &st);  break;
        case '*': Calc(p, TK_TIMES, 0, &st);  break;
        case '/': Calc(p, TK_DIVIDE, 0, &st); break;
        case '^': Calc(p, TK_POW, 0, &st);    break;
        case '(': Calc(p, TK_LPAREN, 0, &st); break;
        case ')': Calc(p, TK_RPAREN, 0, &st); break;
        case ',': Calc(p, TK_COMMA, 0, &st);  break;
        case ';': Calc(p, TK_SEMI, 0, &st);   break;
        default:  break;
      }
      i++;
    }
    Calc(p, 0, 0, &st);
    CalcFree(p, free);
    if( n>24 ){ line[24] = 0; printf("%s...", line); }else{ printf("%s", line); }
    printf(" => result=%d count=%d errors=%d accepted=%d\n",
           st.result, st.count, st.nError, st.accepted);
  }
  fclose(in);
  return 0;
}

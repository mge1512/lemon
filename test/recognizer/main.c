/*
** Test program for the recognizer in C.
**
** Usage:  recognizer INPUTFILE
** Each line of the input file is a list of token numbers.  The program
** prints "accept", or "refuse at N" where N is the place of the first
** token that the parser refuses.  The end of the input counts as a token.
*/
#include <stdio.h>
#include <stdlib.h>
#include "aql.c"

int main(int argc, char **argv){
  static char line[4096];
  FILE *in;
  if( argc!=2 || (in = fopen(argv[1],"r"))==0 ){
    fprintf(stderr,"usage: recognizer INPUTFILE\n");
    return 2;
  }
  while( fgets(line,sizeof(line),in) ){
    void *p = AqlAlloc(malloc);
    char *z = line;
    int err = 0, n = 0;
    for(;;){
      char *zEnd;
      long tok = strtol(z, &zEnd, 10);
      if( zEnd==z ) break;
      z = zEnd;
      n++;
      Aql(p, (int)tok, 0, &err);
      if( err ) break;
    }
    if( !err ){
      n++;
      Aql(p, 0, 0, &err);
    }
    AqlFree(p, free);
    if( err ) printf("refuse at %d\n", n); else printf("accept\n");
  }
  fclose(in);
  return 0;
}

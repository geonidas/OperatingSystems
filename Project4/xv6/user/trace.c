#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h" //code


int
main(int argc, char *argv[])
{
  int i;
  char *nargv[MAXARG];
  printf("DAA");
  if(argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9')){ //checks for correct arguments and if first arg is an int
    fprintf(2, "Usage: %s mask command\n", argv[0]);
    exit(1);
  }
  printf("FOO");
  if (trace(atoi(argv[1])) < 0) { //checks if mask number is negative
    printf("BAR");
    fprintf(2, "%s: trace failed\n", argv[0]);
    exit(1);
  }
  
  for(i = 2; i < argc && i < MAXARG; i++){ //stops after arg limit (additional args are ignored after MAXARG)
    nargv[i-2] = argv[i];
  }
  printf("before exec");
  exec(nargv[0], nargv);
  exit(0);
}

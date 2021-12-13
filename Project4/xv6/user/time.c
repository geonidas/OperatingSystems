#include "kernel/types.h"
#include "kernel/date.h"
#include "user/user.h"
#include "kernel/param.h"

int main (int argc, char *argv[])
{
	int startTime = uptime();
	int pid = fork();
	char* nargv[MAXARG];
	int i;

	for(i = 2; i < argc && i < MAXARG; i++)
	{
    	nargv[i-2] = argv[i];
  	} 

	if(pid > 0)
	{
		//printf("parent proc start \n");
		pid = wait((int *) 0);
	}
	else if(pid == 0)
	{
		//printf("child proc start \n");
		exec(argv[1], nargv);
		exit(0);
	}
	else
	{
		printf("fork error\n");
	}
	
	int endtime = uptime();
	int ticks = (endtime - startTime);
	printf("Real-time in ticks: %d\n", ticks);

	exit(0);
}

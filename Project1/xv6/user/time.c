#include "kernel/types.h"
#include "kernel/date.h"
#include "user/user.h"

int main (int argc, char *argv[])
{
	int current = uptime();
	int process = fork();

	if (process < 0) 
	{
		printf("error: invalid process\n", 2);
		exit(0);
	}
	
	if (process > 0)
		wait(0);
	if (process == 0) 
	{
		if (exec(argv[1], argv + 1) < 0) 
		{
			printf("error: Exec error\n", 2);
			exit(0);
		}
	}
	
	int endtime = uptime();
	int secs = (endtime - current)/100;
	int part = (endtime - current)%100;
	  
	printf("%s", argv[1], 1);
	printf(" ran in %d.", secs, 1);
	
	if (part < 10)
		printf("0", 1);
	printf("%d\n", part, 1);

	exit(0);
}
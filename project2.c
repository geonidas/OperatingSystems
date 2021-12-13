//Goal: find twin primes between 1 and n
//twin primes: a pair of numbers (n,k) are twin prime if n and k are prime for k = n+2 

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

//global variables
pthread_mutex_t   myLock;
int iCounter = 2;
int twinPrimeLimit;
int primeCount = 0;
int threads;
int cores;

int sqrt_f(int num) //function to find square root of a number
{
  int sqrt = num;
  int prevsqrt = 0;
  while(prevsqrt - sqrt > 1)
  {
    prevsqrt = sqrt;
    sqrt = ((num/sqrt)+sqrt)/2;

  }

  return sqrt;
}

int primeCheck(int num) //function to check for primes
{
  int k = sqrt_f(num); //square root of num
  int m = 3; // to find primes divisible by odds

  if (num == 2)
    return 1; //is prime

  else if(num%2 == 0)
    return 0; //not prime

  else
  {
    k = sqrt_f(num);
    m = 3;

    while(m < k)
    {
      if(num%m == 0)
        return 0; //not prime
      m = m+2;
    }
    return 1;
  }

  printf("Error: isPrime function");
  exit(0);
}

void twinPrims() //function to count number of primes from 1 to n
{
  printf("\nCS370 Twin Primes Program\n");
 
  int i = iCounter;
  int isPrime = 0;
  int plusTwo;

  while(i <= twinPrimeLimit)
  {
  
    isPrime = primeCheck(i);
  
    if (isPrime)
    {
      plusTwo = i+2;
      isPrime = primeCheck(plusTwo);
      if(isPrime)
        primeCount++;
    }
    i++;
  }

  //printf("Hardware Cores: %d \n", cores);
  //printf("Thread Count: %d \n", threads);
  printf("Prime Limit: %d \n", twinPrimeLimit);
  printf("Count of twin primes between 1 and %d is %d\n", twinPrimeLimit, primeCount);
  return;
}

int main(int argc, char * argv[])
{
  //threads = atoi(argv[2]);
  //cores = atoi(argv[3]);
  twinPrimeLimit = atoi(argv[1]);
  twinPrims();

  return(0);
}

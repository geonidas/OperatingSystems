#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <pthread.h>
#include <semaphore.h>
#include <time.h>
#include <stdbool.h>

#define STUDENT_COUNT_MIN   2
#define STUDENT_COUNT_MAX   10
#define CHAIR_COUNT         3
#define HELPS_MAX           3

//mutex
pthread_mutex_t professor_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t student_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t chair_mutex = PTHREAD_MUTEX_INITIALIZER; // needed?
//semaphore variables
sem_t sem_student; //counts students that need help
sem_t sem_professor; //prof is available or busy (binary)
sem_t sem_chairs[CHAIR_COUNT]; //binary sems for each chair
//global variables
int *helpArr;  //stores studentid ints
int *studentArr; //stores what student is doing (0 = default, 1 = doing assignment, 2 = waiting in chair, 3 = getting help from prof)
int chairArr[CHAIR_COUNT]; //holds studentid numbers (studentid == studentArrIndex+1)
int chairCtr; //counts number of chairs that are occupied
int studentCtr;
int profCtr;
intptr_t currentStudent;


void* professor(void* id)
{
    //professor can either be sleeping (= 0), helping students (= 1), or finished for the day (= 2)
    int prof_status = 0; //starts off sleeping
    //^old concept assuming prof goes back to sleep at some point

    //loop forever
    while(TRUE)
    {
        //professor sleeping
        if(prof_status == 0)
        {
            printf("Professor has been awakened by a student");
            prof_status = 1;
        }
        //if professor is done helping
        else if(prof_status == 2)
        {
            printf("All students assisted, professor is leaving.");
            //....
            return(0); //exit program
        }

        //assuming prof doesn't go back to sleep (new) [note* might want to put this out of the while loop]
        //prof sleeping
        sem_wait(&sem_student); //sem for students that need help (while <=0, wait)
        sleep(10);

        //loop for professor helping students
        while(TRUE)
        {
            if (chairCtr == 0)  //ends loop if chairs are empty (prof goes back to sleep)
                break;          //so we must fill chairs BEFORE professor thread is called

            pthread_mutex_lock(&professor_mutex);
            //critical section start

            //#####chair section
            chairCtr--; //decriment chair counter
            
            currentStudent = chairArr[0]; //grab first student available
            
            //@@@FIND A WAY TO IMPLEMENT CHAIR SEM
            //shift chairArr as like a queue
            int maxLoops = CHAIR_COUNT * CHAIR_COUNT; //goes through array multiple times to make sure everything is shifted
            for(int i = 0; i < maxLoops; i++)
            {
                int mod_i = i % CHAIR_COUNT; //use modded i for increments of CHAIR_COUNT
                if(mod_i == CHAIR_COUNT-1)
                {
                    chairArr[mod_i] = -1; //if (chairArr[i] < 0), then chairArr[i] is empty
                    break;
                }

                chairArr[mod_i] = chairArr[mod_i+1];
            }
            //@@@chairsem post/signal here?
            
            printf("Student frees chair and enters professors office. Remaining chairs %d", chairCtr);
            //#####chair section end
            
            //#####student help section
            printf("Professor is helping a student\n");
            //random amount of time professor helps student
            usleep(rand() % 1500000);
            
            //@@@signal for next student to enter
            //@@@SEM HERE?

            //#####student help section end

            pthread_mutex_unlock(&professor_mutex);
            //critical section end

        }//student help loop
        sem_post(&sem_student); //sem for when prof is done helping students (helpqueue--)

    }//first while loop

    pthread_exit(NULL);
    return;
}//end of prof function


void* student(void* id)
{
    //student id = (arrayIndex + 1)
    int sid = id+1;


    while(true)
    {
        //show student/process working
        printf("Student %d doing assignment", sid);

        //set student status to 'working'
        studentArr[(int)id] = 1; //status: working on assignment

        //if student no longer needs help, end thread
        if(helpNum <= 0)
            //exit loop
            break;

        //random time to work on assgn
        usleep(rand() % 2000000);

        //student decides to ask for help
        printf("Student %d needs help from the professor.\n", sid);

        //critical section
        pthread_mutex_lock(&student_mutex);
        int usedChairs = chairCtr; //get chair count
        pthread_mutex_unlock(&student_mutex);
        
        //when chairs are full
        if(usedChairs == CHAIR_COUNT)
        {
            printf("Chairs occupied, student %d will return later\n", sid);
        }
        else
        {
            //if all chairs are empty, prof will be sleeping
            if(usedChairs == 0)
            {
                //@@@wake up professor
            }

            //occupy chair
            pthread_mutex_lock(&student_mutex);
            chairArr[chairCtr]; //take seat
            pthread_mutex_unlock(&student_mutex);

            studentArr[(int)id] = 2; //status: waiting in chair

            //@@@wait until prof is available
            //@@@sem here

            helpArr[(int)id] = helpArr[(int)id] - 1; //decriment help count
            
            //exit thread if student doesn't need help
            if(helpArr[(int)id == 0])
                break;

        }//else


    }//while
    pthread_exit(NULL);
    return;
}//student()




int main()
{

    int stNum;  //number of students 
    time_t = t;
    intptr_t studentid;     //intptr for casting int to pointer
    intptr_t profid;
    int rc;

    //initialize chairArr[] (-1 means chair is empty and numbers 0-to-stNum are studentid nums [0 == studentID 1])
    for(int i = 0; i < CHAIR_COUNT; i++)
        chairArr[i] = -1;

    //input loop for student number
    do
    {
        printf("How many students coming to professor's office? ");
        scanf("%d", &stNum);
    }while(stuNum < STUDENT_COUNT_MIN && stNum > STUDENT_COUNT_MAX)
    
    //initialize array for num of help needed
    helpArr = (int *) malloc(stNum);
    //initialize student thread
    studentArr = (pthread_t *) malloc(stNum);

    if (helpArr == NULL || studentArr == NULL) 
    {
        printf("Memory not allocated. \n");
        exit(0);
    }
    
    //for random number of help needed
    srand((unsigned) time(&t));
    
    //loop to add random numbers to helpArray
    for(int i = 0; i < stNum; i++)
    {
        helpArr[i] = rand() % HELPS_MAX + 1;
    }

    //initialize semaphores
    sem_init(&sem_student, 1, 0);
    sem_init(&sem_professor, 1, 0);
    for(int i = 0; i < CHAIR_COUNT; i++)
        sem_init(sem_chairs[i], 1, 0);

    //create professor thread
    pthread_t prof_thread;
    rc = pthread_create(&prof_thread, NULL, &professor, (void*)profid);

    //create student threads
    pthread_t student_thread;
    for(int  = 0; i < stNum; i++)
    {
        studentid = i; //for readability
        rc = pthread_create(&student_thread[i], NULL, &student, (void*)studentid);
    }

    //join professor thread
    int join = pthread_join(prof_thread, NULL);

    //join student threads
    for(int = 0; i < stNum; i++)
        int join = pthread_join(student_thread[i], NULL);

    return(0);
}

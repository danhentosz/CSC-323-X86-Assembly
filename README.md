# Multitasking Operating System Simulator


**Daniel Hentosz, Scott Trunzo || GROUP 10**
__hen3883@calu.edu, tru1931@calu.edu__

1. Item 1
2. Item 2
3. Item 3
 * Item 3a
 * Item 3b
Accepts: QUIT HELP LOAD RUN HOLD KILL SHOW STEP CHANGE
;//10 jobs at a time. Each job has: name(up to 8 chars in length and unique), priority, status, run ;//time, start time
;//Each job starats in the HOLD mode, when a job is done, its removed from the queue
;//When a jobs time, status, or priority changes, a message of the jobs name and an explination is ;//printed to the screen with the system time of the event
;//____________________________________________________________
;//Commands:
;//QUIT HELP SHOW
;//RUN jobname HOLD jobname KILL jobname STEP n
;//CHNAGE jobname priority
;//LOAD jobname priority run_time.....LOAD job1 50 (can be 1-50..this really just sets a jobs priority, ;//run time, and places it in the hold mode)

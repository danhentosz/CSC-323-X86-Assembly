# Multitasking Operating System Simulator


**Daniel Hentosz, Scott Trunzo || GROUP 10**

**hen3883@calu.edu, tru1931@calu.edu**

  * __Accepts:__ *QUIT HELP LOAD RUN HOLD KILL SHOW STEP CHANGE*.
  * __10 jobs at a time__.
  * __Each job has:__ A *name*(up to 8 chars in length and unique), *priority*, *status*, *run_time*,  and a *start_time*.
  * Each job starts in the **HOLD** mode, when a job is done, its removed from the job queue.
  * When a jobs *priority*, *status*, or *run_time* changes, a message of the jobs name and an explination is printed to the screen with the system time of the event.
  * If a command is missing a parameter, the program will prompt for the missing information, otherwise the program will use the data given with the command.
  * One cycle will process the next job of the highest priority that is in the **RUN** mode. The highest *priority* is **0** and the lowest is **7**. The system clock is updated for each processing cycle. When a job is processed, it's *run_time* is decreased by one. When a job's *run_time* becomes zero, it is removed from the job queue.
## Commands:
Command | Operand 1 | Operand 2 | Operand 3
--------|-----------|-----------|-----------
 __QUIT__
 __HELP__
 __SHOW__
**RUN** | *jobname*
**HOLD** | *jobname*
**KILL** | *jobname*
**STEP** | _n_
**CHANGE** | _jobname_ | _priority_
**LOAD** | _jobname_ | _priority_ | _run_time_

 * __QUIT__
   * Terminates the program.
 * __HELP__
    * Provides help with the program.
 * __SHOW__
     * Shows the job queue.
  * __RUN__ _jobname_
     * Changes the mode of a job from **HOLD** to **RUN**
  * __HOLD__ _jobname_
      * Changes the mode of a jo from **HOLD** to **RUN**
   * __KILL__ _jobname_
       * Removes the job from the job queue. The job must be in the **HOLD** mose.
   * __STEP__ _n_
      * Processes n cycles of the simulation stepping the system clock. If n is ommited then one is used as the default value. n must be a positive number.
   * __CHANGE__ _jobname priority_
       * Updates a jobs priority. Must be a value 0-7.
   * __LOAD__ *jobname priority run_time*
       * Priority is 0-7 with 0 being the highest. *run_time* is the ammount of steps the job will take before its compleated, 1-50.


:shit: :shit: :shit: :sparkles: :sparkles: :sparkles: :full_moon: :full_moon: :full_moon:

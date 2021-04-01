TITLE The O.S.S Operating System Simulator    (G10P3.asm).
COMMENT !                                                .
.Created By:                                             .
.             - Daniel Hentosz (HEN3883@calu.edu),       .
.             - Scott Trunzo   (TRU1931@calu.edu)        .
.                                                        .
.Last Revised: April 1st, 2021.                (4/1/2021).
.Written for Assembly Language Programming  (CSC-323-R01).
Description:
	Simulates task-flow of an operating system,
	- this entails loading, running, and killing jobs,
	- the user can interface with the program via commands*
	*see the <...help...> strings under <...prompt...> for details.
!

; Defines various pieces of assembler meta-data,
; - includes redundant model declarations (for compatability).
.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD


; Includes Irvine32.inc, a library utilized throughout CSC-323. 
; - for implementation details, see http://asmirvine.com/.
INCLUDE irvine32.inc



.DATA
; Labels the data section of this program.
; - includes all memory values utlized by this program,
; - for implementation details, see the comment sections below. 




; STRINGS
; This section of code contains hard-coded string (and character) memory addresses,
; - for implementation details, see the comments below.


; Misc:
; Defines odds and ends used for formatting throughout the program,
; - meant to be used in conjunction with strings found below (see below).
str_pointer byte "> ", 0
str_line    byte "------------------------------------------------------------------------------------------------------------------------", 0dh, 0ah, 0
str_os      byte "Welcome to O. S. S. ...", 0dh, 0ah, "Type 'help' to see the list of commands. ", 0dh, 0ah, "Type 'quit' to exit the program.", 0dh, 0ah, 0


; Prompt:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.

str_prompt_run   byte "Enter a Run Time: ", 0
str_prompt_pri   byte "Enter a Priority: ", 0
str_prompt_name  byte "Enter a job name: ", 0

str_prompt_help1 byte "This program simulates the processing an OS's tasks (jobs), ", 0dh, 0ah,
"the process is meant to be similar to that of an OS processing tasks.", 0dh, 0ah,
"Through the use of various commands you can add, alter, and iterate through jobs currently loaded. ", 0dh, 0ah, 0
str_prompt_help2 byte "Available commands with no operands:", 0dh, 0ah,
"QUIT - terminates the program,", 0dh, 0ah,
"HELP - displays this message again,", 0dh, 0ah, 
"SHOW - lists all currently loaded jobs.", 0dh, 0ah, 0
str_prompt_help3_1 byte "Available commands with one operand:", 0dh, 0ah,
"RUN  <job name> - changes the status of <job name> from hold to run.", 0dh, 0ah,
"HOLD <job name> - changes the status of <job name> from run to hold.", 0dh, 0ah,
"KILL <job name> - removes a job from the loaded job queue*", 0dh, 0ah,
"*<job name> must be in HOLD mode.", 0dh, 0ah,
"STEP <cycles>*  - processes jobs for <cycles> iterations.", 0dh, 0ah, 0
str_prompt_help3_2 byte "*if <cycles> is not provided, processing occurs for 1 iteration.", 0dh, 0ah, 0
str_prompt_help4 byte "Available commands with two or more operands:", 0dh, 0ah,
"CHANGE <job name> <priority> - changes <job name>'s priority to <priority>.*", 0dh, 0ah,
"*<priority> must be an integer (0-7).", 0dh, 0ah,
"LOAD   <job name> <priority> <runtime>- appends a new job to the current job queue.*", 0dh, 0ah,
"*<job name> must be eight or less characters, <priority> must be an integer (0-7), <runtime> must be an integer (1-50).", 0dh, 0ah, 0

; Confirm:
; Labels <...confirm...>, a set of strings which tell the user input was accepted.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_confirm_change byte "Job Priority Changed.", 0dh, 0ah, 0
str_confirm_kill   byte "Job Killed.", 0dh, 0ah, 0
str_confirm_run    byte "Job Status Updated.", 0dh, 0ah, 0
str_confirm_empty  byte "Exiting step; no job records exist.", 0dh, 0ah, 0
goodbye byte "Goodbye, have a nice day.",0dh,0ah,0
showname     byte "Name:      ", 0
showpri      byte "Priority:  ", 0
showstat     byte "Status:    ", 0
showrt       byte "Run Time:  ", 0

; Error:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_error_badstat   byte "The Job Must Be In Hold Mode.", 0dh, 0ah, 0
str_error_run       byte "Job does not exist.", 0dh, 0ah, 0
str_error_toomuch   byte "Cannot load; job records full (10 entries).", 0dh, 0ah, 0
str_error_dup       byte "Cannot load; job name already exists.", 0dh, 0ah, 0
str_error_stepempty byte "Cannot step; no running job records are currently loaded.", 0dh, 0ah, 0



; Operator:
; Labels <op...>, a set of placeholder values which hold numerical operators.
; - used as temporary values command operands,
; - for a list of op usecases, see the string commands list above.
op1 byte 10 dup(? )
op2 sbyte - 1
op3 byte ?

inputsize byte 48
input     byte 48 dup(? )
spot      dword ?
command   byte 8 dup(? )
commandlen byte 0



; Key:
; Labels <...key...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_key_load   byte "LOAD", 0
str_key_show   byte "SHOW", 0
str_key_run    byte "RUN", 0
holdstr   byte "HOLD", 0
killstr   byte "KILL", 0
changestr byte "CHANGE", 0
helpstr   byte "HELP", 0
quitstr   byte "QUIT", 0
stepstr   byte "STEP", 0



; Job:
; Labels variables associated with job records, of various types,
; - this includes the unzeroed block of memory <jobs>.
jobs byte 140 dup(? )
jobsfull dword jobsfull
curjob dword jobs
totjobs byte 0
jobssize dword 140
jobnamepos dword ?
jobnamenum byte 9
; Defines constant values used as literals in association with <jobs>.
jobava  equ 0
jobrun  equ 1
jobhold equ 2



; Misc:
; Labels miscelaneous variables used as placeholders for user input, and information about job records.
dupnamecount byte 10
currentpostemp dword jobs
newrunbuf byte 4 dup(? )
newpribuf byte 3 dup(? )
newnamebuf byte 10 dup(? )
namelen byte 0
priposition dword ?
pausecount byte 0
steppriority  sbyte 0
stepplace     byte 0
steptotjobs   byte 0
findnextplace byte 0



; Empty,
; Labels a large, empty array, which is used for zeroing any memory in the program which must be reset.
empty byte 48 dup(? )
.CODE
; Labels the code section of the program.
; - includes all executable instructions written for this program,
; - for implementation details, see the comment sections below. 


; Labels main (the program body).
main PROC
	; Changes the command prompt's color using methods from IRVINE.inc.
	; - entirely cosmetic, but is mostly added to further sell the 'command line era Operating System' experience.
	mov eax, green + (black * 16)
	call settextcolor
	call clrscr

	; Draws the program's welcome message.
	mov edx, offset str_line
	call writeString
	mov edx, offset str_os
	call writeString

	; Serves as the program's main loop body.
	beginit :

		; Prints a prompt letting the user know they can enter input.
		mov edx, offset str_line
		call writeString
		mov edx, offset str_pointer
		call writeString
		
		; Prepares the [edx] and [ecx] registers for accepting input.
		mov edx, offset input
		mov ecx, 48
		
		; Calls readString, which reads user input into [eax].
		call readstring
		mov spot, offset input

		; Calls various procedures to:
		; - skip bad data,             (rem),
		; - collect the user's command (getcommand),
		; - compare the user's command (compare).
		call rem
		call getcommand
		call compare

		; Checks for the quit command (terminator for the program).
		cld
		mov esi, offset quitstr
		mov edi, offset command
		mov ecx, 5
		repe cmpsb
		jz  done



	; Serves as the main loop iterator.
	cont:
		call initstuff
		jmp beginit
	
	; Serves as a terminator for main (includes a goodbye message).
	done:
		mov edx, offset str_line
		call writeString

		mov edx,offset goodbye
		call writestring

		mov edx, offset str_line
		call writeString
		exit
main ENDP


; REM
; DESCRIPTION:    Skips any garbage information proceeding the user's command.
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address.
rem PROC

	; Fetches the current spot in memory (and the input array's size).
	mov esi, spot
	mov cl,  inputsize

	; Loops until a non-garbage character has been found.
	L1:
		; Fetches the current value pointed to by [esi]
		mov al, byte ptr[esi]

		; Preincrements [esi], in case either comparison below is true.
		inc esi

		; Compares against SPACE,
		; - iterates again if true.
		cmp al, ' '
		loope L1

		; Compares against TAB,
		; - iterates again if true.
		cmp al, '	'
		loope L1

	; Postdecrements [esi], since the stored value was off by 1.
	dec esi

	; Updates <spot> to be the location pointed to by [esi].
	mov spot, esi
	ret
rem ENDP


; SKIPCHARS
; DESCRIPTION:    Skips input to the next segment of whitespace,
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address.
skipchars PROC
	mov esi, spot
	mov cl,  inputsize

	L1:
		mov al, byte ptr[esi]
		cmp al, ' '
		je done
		cmp al, '	'
		je done
		cmp al, 0
		je done
		inc esi
		loop L1
	done :
		mov spot, esi
		ret
skipchars ENDP



; GETCOMMAND
; DESCRIPTION:    Fetches the user's command (and turns it into UPPERCASE),
; PRECONDITIONS:  <spot> has been initalized to point to the user's input.
; POSTCONDITIONS: Updates [spot]'s stored memory address, moves input into <command>.
getcommand PROC
	mov esi, spot
	mov edi, offset command
	mov ecx, 7
	L1:
		mov al, byte ptr[esi]
		cmp al, ' '
		je done
		cmp al, '	'
		je done
		cmp al, 0
		je done
		and al, 11011111b
		mov byte ptr [esi], al
		cld
		movsb
		loop L1

	done :
		mov spot, esi
		ret
getcommand ENDP


; GETOP1
; DESCRIPTION:    Grabs type 1 operators (strings),
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address, moves input into <op1>.
getop1 PROC
	mov esi, spot
	mov edi, offset op1
	mov ecx, 9
	L1:
		mov al, byte ptr[esi]
		cmp al, ' '
		je done
		cmp al, '	'
		je done
		cmp al, 0
		je done
		cld
		movsb
		inc namelen
		loop L1
	done :
		mov spot, esi
		ret
getop1 ENDP


; GETOP2
; DESCRIPTION:    Grabs type 2 operators (integers),
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address, moves input into <op2>*
; *if input is invalid, <op2> becomes -1.
getop2 PROC
	mov esi, spot
	inc esi
	mov al, byte ptr[esi]

	call isdigit
	jz bad
	cmp al, ' '
	je good1
	cmp al, '	'
	je good1
	cmp al, 0
	je good1
	jmp bad

	good1:
		dec esi
		mov al, byte ptr[esi]
		call isdigit
		jz good2
		jmp bad

	good2:
		mov edx, esi
		mov ecx, 1
		call parsedecimal32
		cmp al, 7
		jg bad
		cmp al, 0
		jl bad
		mov op2, al
		jmp done
	bad:
		mov op2, -1

	done :
		mov spot, esi
		ret
getop2 ENDP


; GETOP3
; DESCRIPTION:    Grabs type 3 operators (integers),
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address, moves input into <op2>.
; *if input is invalid, <op3> becomes 0.
getop3 PROC
	mov esi, spot
	mov al, byte ptr[esi]
	call isdigit
	je good1
	jmp bad

	good1:
		mov esi, spot
		inc esi
		mov al, byte ptr[esi]
		call isdigit
		jz good2dig
		cmp al, ' '
		je good1dig
		cmp al, '	'
		je good1dig
		cmp al, 0
		je good1dig
		jmp bad

	good2dig:
		mov esi, spot
		mov al, byte ptr[esi]
		and al, 00001111b
		mov dl, 10
		mul dl
		mov op3, al
		inc esi
		mov al, byte ptr[esi]
		and al, 00001111b
		add op3, al
		jmp done

	good1dig:
		mov esi, spot
		mov al, byte ptr[esi]
		and al, 00001111b
		mov op3, al
		jmp done

	bad:
		mov op3, 0
		jmp done2
	done:
		mov al, op3
		cmp al, 50
		ja bad
		cmp al, 1
		jb bad
	done2:
		ret
getop3 ENDP


; COMPARE
; DESCRIPTION:    Compares <command> against all strings within <...key...>,
; PRECONDITIONS:  <command> holds valid data. 
; POSTCONDITIONS: Calls subroutines depending on the <...key...> entry hit*
; *if <command> is invalid, COMPARE returns to MAIN.
compare PROC
	cld
	mov esi, offset str_key_load
	mov edi, offset command
	mov ecx, 5
	repe cmpsb
	jz load

	cld
	mov esi, offset str_key_show
	mov edi, offset command
	mov ecx, 5
	repe cmpsb
	jz showjobs

	cld
	mov esi, offset str_key_run
	mov edi, offset command
	mov ecx, 4
	repe cmpsb
	jz run

	cld
	mov esi, offset holdstr
	mov edi, offset command
	mov ecx, 5
	repe cmpsb
	jz hold

	cld
	mov esi, offset killstr
	mov edi, offset command
	mov ecx, 5
	repe cmpsb
	jz kill

	cld
	mov esi, offset changestr
	mov edi, offset command
	mov ecx, 7
	repe cmpsb
	jz change

	cld
	mov esi, offset helpstr
	mov edi, offset command
	mov ecx, 5
	repe cmpsb
	jz help

	cld
	mov esi, offset stepstr
	mov edi, offset command
	mov ecx, 5
	repe cmpsb
	jz step
	ret
compare ENDP


; STEP
; DESCRIPTION:    Iterates through entries in <jobs>
; PRECONDITIONS:  N/A (handles error cases)
; POSTCONDITIONS: Calls subroutines to iterate through <jobs>*
; *may terminate with no changes, kill job(s)**, or decrement multiple entries in jobs**
; **decrements/kills require RUNNING job entries to occur. 
; + this procedure prompts for missing input.
step PROC
	push ecx
	push eax
	push esi
	push edi

	; Checks to see if a priority can be found,
	; - if not, the procedure terminates prematurely.
	mov esi, offset jobs
	call stepfindpriority
	mov al, steppriority
	cmp al, 8
	je LTWE

	; Fetches the user's step command,
	call rem
	mov esi, spot
	call getop3

	; - if none was given, 1 is provided instead. 
	mov cl, al
	mov al, steppriority
	cmp cl, 0
	jle default
	mov stepplace, cl
	jmp LINIT


	default:
		mov cl, 1
		mov stepplace, cl
		jmp LINIT
	
	LINIT:
		mov findnextplace, 10
		mov esi, offset jobs
		call stepfindpriority
		mov al, steppriority
		cmp al, 8
		je LTE
		jmp L1
	L1:
		call stepfindnext
		jmp LC1
	LC1:
		; Checks to see if the job record has expired,
		; - if so, the record is killed.
		cmp cl, -2
		je LTK
		cmp cl, -1
		je LC2
		jmp LC3


	LC2:
		add esi, 14
		mov cl, stepplace
		dec cl
		cmp cl, 0
		jle done
		mov stepplace, cl

		mov cl, findnextplace
		dec cl
		cmp cl, 0
		jle LINIT
		mov findnextplace, cl
		jmp L1


	LC3:
		add esi, 14
		mov cl, findnextplace
		dec cl
		cmp cl, 0
		jle LINIT
		mov findnextplace, cl
		jmp L1
	
	LTK:

		cld
		mov edi, esi
		mov esi, offset empty
		mov ecx, 14
		rep movsb

		mov ch, totjobs
		dec ch
		mov totjobs, ch

		; decrements, then compares [ecx] to 0,
		; - if [ecx] is 0 or below, the procedure terminates.
		mov cl, stepplace
		dec cl
		cmp cl, 0
		jle done
		mov stepplace, cl

		jmp LINIT
		
	LTE:
		mov edx, offset str_confirm_empty
		call writeString
		jmp done

	LTWE:
		mov edx, offset str_error_stepempty
		call writeString
		jmp done

	done:
		pop edi
		pop esi
		pop eax
		pop ecx
		ret
step ENDP



; STEPFINDPRIORITY
; DESCRIPTION:    Iterates through <jobs> in order to retrieve the lowest priority.
; PRECONDITIONS:  N/A (sets it's own registers)
; POSTCONDITIONS: Updates the global label <steppriority>*
; *sends the error code 8 whenever no running job entries exist.
stepfindpriority proc
	push esi
	push ecx
	mov esi, offset jobs
	mov steppriority, 8
	mov cl, 10
	cmp cl, 0
	jle done
	jmp L1

	L1:
		mov al, byte ptr [esi + 10]
		cmp al, 0
		je LC

		cmp al, jobrun
		jne LC

		mov al, byte ptr [esi + 9]
		cmp al, steppriority
		jge LC
		mov steppriority, al
		jmp LC

	LC:
		add esi, 14
		dec cl
		cmp cl, 0
		jle done
		jmp L1
		
	done:
		pop ecx
		pop esi
		ret
stepfindpriority endp



; STEPFINDNEXT
; DESCRIPTION:    Iterates through <jobs>, trying to find running records with <steppriority> priority.
; PRECONDITIONS:  [esi] points to a valid job record.
; POSTCONDITIONS: decrements a job record's runtime if it meets the criteria above*
; *sends the codes '-2' (job should be killed), and '-1' (job was decremented).
stepfindnext PROC
	mov al, [esi + 10]
	cmp al, jobrun
	je good
	jmp done

	good:
		mov al, [esi + 9]
		cmp al, steppriority
		jne done

		mov al, [esi + 11]
		dec al
		cmp al, 0
		jle markaskill
		mov [esi + 11], al
		mov cl, -1
		jmp done


	markaskill:
		mov cl, -2
		jmp done

	done:
		ret
stepfindnext ENDP


; HELP
; DESCRIPTION:    Prints a list of strings that construct a mini-readme onto the screen.
; PRECONDITIONS:  N/A.
; POSTCONDITIONS: Leaves a list of all available commands on the screen.
help PROC
	mov edx,offset str_line
	call writestring
	mov edx,offset str_prompt_help1
	call writestring
	mov edx,offset str_line
	call writestring
	mov edx,offset str_prompt_help2
	call writestring
	mov edx,offset str_line
	call writestring
	mov edx,offset str_prompt_help3_1
	call writestring
	mov edx,offset str_prompt_help3_2
	call writestring
	mov edx,offset str_line
	call writestring
	mov edx,offset str_prompt_help4
	call writestring
	ret
help ENDP


; CHANGE
; DESCRIPTION:    Runs various subroutines to change the priority of a given job record,
; PRECONDITIONS:  N/A (should be called by COMPARE).
; POSTCONDITIONS: Attempts to change a job record's priority, if <op1> contains a valid job name.
; + this procedure prompts for missing input.
change PROC
	call skipchars
	call rem
	call getop1
	;//_______________________
	call skipchars
	call rem
	call getop2
	;//______________________
	mov al, namelen
	cmp al, 0
	je nameprompt
	cmp al, 9
	jae nameprompt
	jmp keepgoing

	nameprompt:
		mov namelen, 0
		cld
		mov edi, offset op1
		mov esi, offset empty
		mov ecx, 10
		rep movsb
		call getnewname
		mov al, namelen
		cmp al, 0
		jbe done
		cmp al, 9
		jae done

	keepgoing:
		call findjob
		mov al, jobnamenum
		cmp al, 0
		je done
		mov al, op2
		cmp al, 8
		jae priprompt
		jmp cont

	priprompt:
		call getnewpri
		mov al, op2
		cmp al, 7
		ja done

	cont:

		mov esi, jobnamepos
		add esi, 9
		movzx eax, op2
		mov byte ptr[esi], al
		mov edx, offset str_confirm_change
		call writestring
	done:
		ret
change ENDP


; KILL
; DESCRIPTION:    Clears a named record from <jobs>, should it exist.
; PRECONDITIONS:  N/A, (should be called by COMPARE)
; POSTCONDITIONS: Erases a record that <op1>'s input matches, should it exist.
; + this procedure prompts for missing input.
kill PROC
	call skipchars
	call rem
	call getop1
	mov al, namelen
	cmp al, 0
	je nameprompt
	cmp al, 9
	jae nameprompt
	jmp keepgoing
	nameprompt:
		mov namelen, 0
		cld
		mov edi, offset op1
		mov esi, offset empty
		mov ecx, 10
		rep movsb
		call getnewname
		mov al, namelen
		cmp al, 0
		jbe done
		cmp al, 9
		jae done

	keepgoing :
		call findjob
		mov al, jobnamenum
		cmp al, 0
		je done
		mov esi, jobnamepos
		add esi, 10
		mov al, byte ptr[esi]
		cmp al, 2
		je good
		jmp bad

	good:
		mov edx, offset str_confirm_kill
		call writestring
		cld
		mov edi, jobnamepos
		mov esi, offset empty
		mov ecx, 14
		rep movsb
		dec totjobs
		jmp done

	bad:
		mov edx, offset str_error_badstat
		call writestring
	done:
		ret
kill ENDP


; HOLD
; DESCRIPTION:    Changes the status of a valid job record to HOLD,
; PRECONDITIONS:  N/A (should be called by COMPARE).
; POSTCONDITIONS: Attempts to change a job record's status to HOLD, if possible.
; + this procedure prompts for missing input.
hold PROC
	call skipchars
	call rem
	call getop1
	
	mov al, namelen
	cmp al, 0
	je nameprompt
	cmp al, 9
	jae nameprompt
	jmp keepgoing

	nameprompt:
		mov namelen, 0
		cld
		mov edi, offset op1
		mov esi, offset empty
		mov ecx, 10
		rep movsb
		call getnewname
		mov al, namelen
		cmp al, 0
		jbe done
		cmp al, 9
		jae done

	keepgoing:
		call findjob
		mov al, jobnamenum
		cmp al, 0
		je done
		mov edx, offset str_confirm_run
		call writestring
		mov edi, jobnamepos
		add edi, 10
		mov byte ptr[edi], 2

	done:
		ret
hold ENDP



; RUN
; DESCRIPTION:    Changes the status of a valid job record to RUN,
; PRECONDITIONS:  N/A (should be called by COMPARE).
; POSTCONDITIONS: Attempts to change a job record's status to RUN, if possible.
; + this procedure prompts for missing input.
run PROC
	call skipchars
	call rem
	call getop1
	
	mov al, namelen
	cmp al, 0
	je nameprompt
	cmp al, 9
	jae nameprompt
	jmp keepgoing

	nameprompt:
		mov namelen, 0
		cld
		mov edi, offset op1
		mov esi, offset empty
		mov ecx, 10
		rep movsb
		call getnewname
		mov al, namelen
		cmp al, 0
		jbe done
		cmp al, 9
		jae done

	keepgoing:
		call findjob
		mov al, jobnamenum
		cmp al, 0
		je done
		mov edx, offset str_confirm_run
		call writestring
		mov edi, jobnamepos
		add edi, 10
		mov byte ptr[edi], 1
	done:
		ret
run ENDP



; FINDJOB
; DESCRIPTION:    Attempts to search <jobs> for a record, which matches <op1>,
; PRECONDITIONS:  <op1> must contain string data.
; POSTCONDITIONS: Attempts to match <op1> to a job record*
; *stores relevant values in jobnamepos, if found.
findjob PROC
	mov jobnamenum, 10
	mov jobnamepos, offset jobs
	again:
		mov al, jobnamenum
		cmp al, 0
		je nope
		cld
		mov esi, jobnamepos
		mov edi, offset op1
		mov ecx, 2
		repe cmpsd
		je found
		add jobnamepos, 14
		dec jobnamenum
		jmp again
	nope:
		mov edx, offset str_error_run
		call writestring
		jmp done
	found:
	done:
		ret
findjob ENDP



; LOAD
; DESCRIPTION:    Attempts to create a new job record, using all <...op...> labels,
; PRECONDITIONS:  N/A (should be called by COMPARE),
; POSTCONDITIONS: Creates a new job record (if space is available in <jobs>).
; + this procedure prompts for missing input.
load PROC
	push ecx
	mov cl, totjobs
	cmp totjobs, 10
	jge full

	call skipchars
	call rem
	call getop1
	call skipchars
	call rem
	call getop2

	call skipchars
	call rem
	call getop3
	
	mov al, namelen
	cmp al, 0
	je nameprompt
	cmp al, 9
	jae nameprompt
	call dupname
	mov al, dupnamecount
	cmp al, 0
	jne done
	jmp cont

	nameprompt:
		mov namelen, 0
		cld
		mov edi, offset op1
		mov esi, offset empty
		mov ecx, 10
		rep movsb
		call getnewname
		mov al, namelen
		cmp al, 0
		jbe done
		cmp al, 9
		jae done
		call dupname
		mov al, dupnamecount
		cmp al, 0
		jne done
		cont :
		mov al, op2
		cmp al, 8
		jae priprompt
		jmp cont2

	priprompt:
		call getnewpri
		mov al, op2
		cmp al, 7
		ja done

	cont2:
		mov al, op3
		cmp al, 50
		ja runprompt
		cmp al, 0
		jbe runprompt
		jmp cont3

	runprompt:
		call getnewrun
		mov al, op3
		cmp al, 50
		ja done
		cmp al, 0
		jbe done

	cont3:
		call loadfindempty
		inc totjobs
		cld
		mov edi, curjob
		mov esi, offset op1
		mov cl,  8
		rep movsb

		mov edi, curjob
		movzx eax, op2
		mov byte ptr[edi + 9], al
		mov byte ptr[edi + 10], 2
		movzx eax, op3
		mov byte ptr[edi + 11], al
		jmp done
	
	full:
		mov edx, offset str_error_toomuch
		call writestring

	done:
		pop ecx
		ret
load ENDP


; LOADFINDEMPTY
; DESCRIPTION:    Fetches the next empty record in <jobs> for LOAD,
; PRECONDITIONS:  <jobs> must not be full.
; POSTCONDITIONS: Changes <curjob> to a new, empty record.
loadfindempty proc
	push esi
	push eax
	mov esi, offset jobs
	mov ah, 10
	jmp L1
		
	L1:
		mov al, byte ptr [esi + 10]
		cmp al, 0
		je found
		jmp LC
	
	LC:
		dec ah
		cmp ah, 0
		jle done
		add esi, 14
		jmp L1
	
	found:
		mov curjob, esi
		jmp done

	done:
		pop eax
		pop esi
		ret
loadfindempty endp



; DUPNAME
; DESCRIPTION:    Validates <op1> against <jobs>, to ensure it is unique.
; PRECONDITIONS:  N/A (should be called by COMPARE).
; POSTCONDITIONS: Prematurely terminates if it finds a duplicate name. Otherwise, returns as normal.
dupname PROC
	mov currentpostemp, offset jobs
	mov edi, currentpostemp
	mov esi, offset op1
	mov dupnamecount, 10
	again:
		mov al, dupnamecount
		cmp al, 0
		je done
		mov esi, offset op1
		cld
		mov ecx, 2
		repe cmpsd
		jz bad
		add currentpostemp, 14
		mov edi, currentpostemp
		dec dupnamecount
		jmp again

	bad:
		mov edx, offset str_error_dup
		call writestring
	done:
		ret
dupname ENDP



; GETNEWRUN
; DESCRIPTION:    Fetches a new copy of <op1> for RUN,
; PRECONDITIONS:  N/A (should be called by RUN),
; POSTCONDITIONS: Alters <op1> to contain new user input.
getnewrun PROC
	mov edx, offset str_prompt_run
	call writestring
	mov edx, offset newrunbuf
	mov ecx, 3
	call readstring
	mov spot, offset newrunbuf
	call getop3
	ret
getnewrun ENDP


; GETNEWPRI
; DESCRIPTION:    Fetches a new copy of <op2> for LOAD, CHANGE,
; PRECONDITIONS:  N/A (should be called by LOAD or CHANGE),
; POSTCONDITIONS: Alters <op2> to contain new user input.
getnewpri PROC
	mov edx, offset str_prompt_pri
	call writestring
	mov edx, offset newpribuf
	mov ecx, 2
	call readstring
	mov spot, offset newpribuf
	call getop2
	ret
getnewpri ENDP


; GETNEWNAME
; DESCRIPTION:    Fetches a new copy of <op1> for CHANGE, HOLD, KILL, RUN, LOAD,
; PRECONDITIONS:  N/A (should be called by CHANGE, HOLD, KILL, RUN, and LOAD),
; POSTCONDITIONS: Alters <op1> to contain new user input.
getnewname PROC
	mov edx, offset str_prompt_name
	call writestring
	mov edx, offset newnamebuf
	mov ecx, 9
	call readstring
	mov spot, offset newnamebuf
	call getop1
	ret
getnewname ENDP


; SHOWJOBS
; DESCRIPTION:    Shows any job(s) that are currently loaded,
; PRECONDITIONS:  N/A (handles empty <jobs>),
; POSTCONDITIONS: Prints each job record to the screen, with a screen break included.
showjobs PROC
	mov pausecount,0
	mov ecx, 10
	mov priposition, offset jobs
	mov esi, priposition
	
	again:
		add esi, 10
		mov al, byte ptr[esi]
		cmp al, 0
		jne good
		add priposition, 14
		mov esi, priposition
		loop again
		jmp done
	
	good:
		call printnameneat
		mov edx, offset showpri
		call writestring
		dec esi
		movzx eax, byte ptr[esi]
		call writedec
		call crlf
		mov edx, offset showstat
		call writestring
		inc esi
		call disppri
		mov edx, offset showrt
		call writestring
		inc esi
		movzx eax, byte ptr[esi]
		call writedec
		call crlf
		call showlt
		add priposition, 14
		mov esi, priposition
		loop again
	done:
		ret
showjobs ENDP



; SHOWLT
; DESCRIPTION:    Serves as a break routine for SHOWJOBS,
; PRECONDITIONS:  N/A (should be called by SHOWJOBS),
; POSTCONDITIONS: Conditonally adds an extra line to cmd output.
showlt PROC
	mov al, pausecount
	cmp al, 30
	je cont
	cmp al, 60
	je cont
	call crlf
	cont:
		ret
showlt ENDP


; PRINTNAMENEAT
; DESCRIPTION:    Fetches, then prints a job record's associated name.
; PRECONDITIONS:  N/A (should be called by SHOWJOBS)
; POSTCONDITIONS: Conditionally calls WAITMSG, but otherwise prints valid job names.
printnameneat PROC
	add pausecount,6
	mov al,pausecount
	cmp al,36
	jne cont
	call crlf
	call waitmsg
	call crlf
	call crlf
	cont:
		mov edx, offset showname
		call writestring
		mov edx, priposition
		call writestring
		call crlf
		ret
printnameneat ENDP
	

; DISPPRI
; DESCRIPTION:    Transforms status values into readable text.
; PRECONDITIONS:  N/A (should be called by SHOW JOBS),
; POSTCONDITIONS: Prints the status of a job record.
disppri PROC
	push esi
	mov esi, priposition
	mov al, byte ptr[esi + 10]
	cmp al, 2
	je theholding
	jmp therunning
	theholding:
		mov edx, offset holdstr
		call writestring
		call crlf
		jmp done
	therunning:
		mov edx, offset str_key_run
		call writestring
		call crlf
	
	done:
		pop esi
		ret
disppri ENDP


; INITSTUFF
; DESCRIPTION:    Resets various constant values and accumulators.
; PRECONDITIONS:  N/A (only zeroes data).
; POSTCONDITIONS: Resets constant values used by procedures defined above.
initstuff PROC
	mov namelen, 0
	cld
	mov edi, offset command
	mov esi, offset empty
	mov ecx, 8
	rep movsb

	cld
	mov edi, offset op1
	mov esi, offset empty
	mov ecx, 10
	rep movsb

	mov op2, -1
	mov op3, null

	cld
	mov edi, offset input
	mov esi, offset empty
	mov ecx, 48
	rep movsb
	ret
initstuff ENDP
END main
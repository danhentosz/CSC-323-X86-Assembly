TITLE The O.S.S Operating System Simulator    (G10P3.asm).
COMMENT !                                                .
.Created By:                                             .
.             - Daniel Hentosz (HEN3883@calu.edu),       .
.             - Scott Trunzo   (TRU1931@calu.edu)        .
.			                                 .
.Last Revised: April 1st, 2021.                (4/1/2021).
.Written for Assembly Language Programming  (CSC-323-R01).
Description:
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



; Prompt:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.

str_prompt_run   byte "Enter a Run Time: ", 0
str_prompt_pri   byte "Enter a Priority: ", 0
str_prompt_name  byte "Enter a job name: ", 0

str_prompt_help1 byte "This program simulates the processing of job records, ", 0dh, 0ah,
"the process is meant to be similar to that of an OS processing tasks.", 0dh, 0ah,
"Through the use of various commands you can add, alter, and iterate through jobs currently loaded. ", 0dh, 0ah, 0dh, 0ah,
"Available commands with no operands:", 0dh, 0ah,
"QUIT - terminates the program,", 0dh, 0ah,
"HELP - displays this message again,", 0dh, 0ah, 
"SHOW - lists all currently loaded jobs.", 0dh, 0ah, 0dh, 0ah, 0

str_prompt_help2 byte "Available commands with one operand:", 0dh, 0ah,
"RUN  <job name> - changes the status of <job name> from hold to run.", 0dh, 0ah,
"HOLD <job name> - changes the status of <job name> from run to hold.", 0dh, 0ah,
"KILL <job name> - removes a job from the loaded job queue*", 0dh, 0ah,
"*<job name> must be in HOLD mode.", 0dh, 0ah,
"STEP <cycles>*  - processes jobs for <cycles> iterations.", 0dh, 0ah, 0


str_prompt_help3 byte "*if <cycles> is not provided, processing occurs for 1 iteration.", 0dh, 0ah, 0dh, 0ah,
"Available commands with two operands:", 0dh, 0ah,
"CHANGE <job name> <priority> - changes <job name>'s priority to <priority>.*", 0dh, 0ah,
"*<priority> must be an integer (0-7).", 0dh, 0ah,
"LOAD   <job name> <priority> - appends a new job to the current job queue.*", 0dh, 0ah,
"*<job name> must be eight or less characters, <priority> must be an integer (0-7).", 0dh, 0ah, 0

; Confirm:
; Labels <...confirm...>, a set of strings which tell the user input was accepted.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_confirm_change byte "Job Priority Changed.", 0dh, 0ah, 0
str_confirm_kill   byte "Job Killed.", 0dh, 0ah, 0
str_confirm_run    byte "Job Status Updated.", 0dh, 0ah, 0

; Error:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_error_badstat byte "The Job Must Be In Hold Mode.", 0dh, 0ah, 0
str_error_run     byte "Job does not exist.", 0dh, 0ah, 0
str_error_toomuch byte "Cannot load; job records full (1o entries).", 0dh, 0ah, 0
str_error_dup     byte "Cannot load; job name already exists.", 0dh, 0ah, 0
str_error_baddata byte "Unrecognized command.",0dh, 0ah, 0


inputsize byte 48
input     byte 48 dup(? )
spot      dword ?
command   byte 8 dup(? )

; Operator:
; Labels <op...>, a set of placeholder values which hold numerical operators.
; - used as temporary values command operands,
; - for a list of op usecases, see the string commands list above.
op1 byte 10 dup(? )
op2 sbyte - 1
op3 byte ?

showname     byte "Name:      ", 0
showpri      byte "Priority:  ", 0
showstat     byte "Status:    ", 0
showrt       byte "Run Time:  ", 0
showloadtime byte "Load Time: ", 0dh, 0ah, 0
jobnummsg2   byte "Info:      ", 0dh, 0ah, 0

goodbye byte "Goodbye, have a nice day.",0dh,0ah,0


; Key:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
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


jobnamepos dword ?
jobnamenum byte 9

jobs byte 140 dup(? )
jobsfull dword jobsfull
curjob dword jobs
totjobs byte 0

Sjobs_name      byte 0
Sjobs_priority  byte 10
Sjobs_status    byte 11
Sjobs_runtime   byte 12
Sjobs_startime  byte 13


jobava equ 0
jobrun equ 1
jobhold equ 2

dupnamecount byte 10
currentpostemp dword jobs

newrunbuf byte 4 dup(? )
newpribuf byte 3 dup(? )
newnamebuf byte 10 dup(? )
namelen byte 0


tempspot byte 2 dup(? )


; jmsg1 byte " ", 0dh, 0ah, 0dh, 0ah, 0
priposition dword ?
pausecount byte 0


stepjobname byte 10 dup(? )
stepjobtime byte ?
stepjobpri  byte 0


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


	beginit :
		; Draws the pointer onto the screen (used to signify where the user provides input).
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


;//We need to see if we should print a new line
;//We need this beacuse the show jobs procedure will 
;//run off the screen when there are 10 jobs

	mov al, pausecount
	cmp pausecount, 60
	je cont
	call crlf

	cont:
		call initstuff
		jmp beginit
	
	done:
		mov edx,offset goodbye
		call writestring
		exit
main ENDP


; REM
; TYPE: OPAQUE ([eax], [esi], [ecx]).
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
		cld
		movsb
		loop L1

	done :
		mov spot, esi
		ret
getcommand ENDP



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



getop2 PROC
	mov esi, spot
	inc esi
	mov al, byte ptr[esi]

	call isdigit
	jz bad
	cmp al, ' '
	je good1
	cmp al, tab
	je good1
	cmp al, null
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
		cmp al, tab
		je good1dig
		cmp al, null
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
		mov op3, null
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



step PROC
	call rem
	mov esi, spot
	call getop3
	;//If the user entered a valid run time it is in op3, otherwide op3 is null/0
	mov al, op3
	cmp al, 0
	je defaulttime
	;//If we get here, they entered a number, so step N ammount of time
	;//The number is in op3

	;//If the user didnt enter anything, just steep 1 time:
	defaulttime:
	mov op3,1

	;//_____________________________________________
	;//NEEDS TO BE IMPLEMENTED
	;//______________________________________
	done:
	ret
step ENDP



help PROC
	mov edx,offset str_prompt_help1
	call writestring
	mov edx,offset str_prompt_help2
	call writestring
	mov edx,offset str_prompt_help3
	call writestring
	ret
help ENDP



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
		;//Now just get the new priority, check it, and place it
		;//jobnamepos is pointing to the start of the record
		mov esi, jobnamepos
		add esi, 9
		movzx eax, op2
		mov byte ptr[esi], al
		mov edx, offset str_confirm_change
		call writestring
	done:
		ret
change ENDP



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
		jmp done

	bad:
		mov edx, offset str_error_badstat
		call writestring
	done:
		ret
kill ENDP



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



load PROC
	cld
	mov esi, curjob
	mov edi, jobsfull
	mov ecx, 2
	repe cmpsd
	je full

	call skipchars
	call rem
	call getop1
	call skipchars
	call rem
	call getop2
	
	;//Compare the priority here
	call skipchars
	call rem
	call getop3
	
	;//Compare the run time here
	;//Compare the name here
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
		inc totjobs
		cld
		mov esi, offset op1
		mov edi, curjob
		mov ecx, 8
		rep movsb
		mov edi, curjob
		add edi, 9
		movzx eax, op2
		mov byte ptr[edi], al
		mov edi, curjob
		add edi, 10
		mov byte ptr[edi], 2
		mov edi, curjob
		add edi, 11
		movzx eax, op3
		mov byte ptr[edi], al
		add curjob, 14
		jmp done
	
	full:
		mov edx, offset str_error_toomuch
		call writestring

	done:
		ret
load ENDP



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



showlt PROC
	mov edx, offset showloadtime
	call writestring
	mov al, pausecount
	cmp al, 30
	je cont
	cmp al, 60
	je cont
	call crlf
	cont:
		ret
showlt ENDP



maybewait PROC
	ret
maybewait ENDP



printnameneat PROC
	add pausecount,6
	mov al,pausecount
	cmp al,36
	jne cont
	call waitmsg
	call crlf
	cont:
	mov edx, offset showname
	call writestring
	mov edx, priposition
	call writestring
	call crlf
	ret
printnameneat ENDP
	


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

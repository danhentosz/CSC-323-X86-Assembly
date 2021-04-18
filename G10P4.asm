TITLE S. N. S. Simple Network Simulator       (G10P4.asm).
COMMENT !                                                .
.Created By:                                             .
.             - Daniel Hentosz (HEN3883@calu.edu),       .
.             - Scott Trunzo   (TRU1931@calu.edu),       .
.             - Josh Staffen   (STA9036@calu.edu)        .
.                                                        .
.Last Revised: April 29th, 2021.              (4/29/2021).
.Written for Assembly Language Programming  (CSC-323-R01).
Description:
Simulates a six node network topology (with real limitations),

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


; CONSTANTS
; - equate to ascii symbols checked for within the program.
TAB   equ '	'
SPACE equ ' '
NULL  equ 0
ZERO  equ '0'
NINE  equ '9'

; NODE
; Lables <...node...>, a set of records and metadata that represent a set of network nodes.
bR_nodes byte 100 dup (0)


; STRINGS
; This section of code contains hard-coded string (and character) memory addresses,
; - for implementation details, see the comments below.

; Key:
; Labels <...key...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_key_help   byte "HELP", 0
str_key_quit   byte "QUIT", 0
str_key_run    byte "RUN", 0


; Prompt:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_prompt_file    byte "Please enter an output file name (maximum of 260 characters): ",0dh,0ah,0



; Confirm:
; Labels <...confirm...>, a set of strings which tell the user input was accepted.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_confirm_quit   byte "Goodbye, have a nice day.",0dh,0ah,0


; Error:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_error_command1   byte "Unrecognized command, '", 0
str_error_command2   byte "' please enter something else.", 0dh,0ah,0

; Misc:
; Defines odds and ends used for formatting throughout the program,
; - meant to be used in conjunction with strings found below (see below).
str_pointer byte "> ", 0
str_line    byte "------------------------------------------------------------------------------------------------------------------------", 0dh, 0ah, 0
str_os      byte "Welcome to Net S. P. ...", 0dh, 0ah,
"- type 'help' for implementation details, ", 0dh, 0ah,
"- type 'run' to begin the simulation,", 0dh, 0ah,
"- type 'quit' to exit the program.", 0dh, 0ah, 0
str_help    byte "This program simulates the processing network packets, ", 0dh, 0ah,
"- the process uses minimal metadata, and explores the limitations of a real network,", 0dh, 0ah,
"- to begin configuring the simulation, type 'run'.", 0dh, 0ah, 0



; Empty,
; Labels a large, empty array, which is used for zeroing any memory in the program which must be reset.
empty byte 48 dup(0)


bA_inputbuffer       byte 48 dup(?)
bAs_inputbuffer      byte 48
bA_command           byte 6  dup(?)


; According to microsoft's suggestions, file names (plus their path) should total 260 characters or less,
; - while it is unlikely that a user WILL name their file something this long, choosing an arbitrary value is less consistent with the OS,
; - information cited under "Maximum Path Length Limitation".
; https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file?redirectedfrom=MSDN 
bA_file byte 260  dup(?)


b_hasQuit    byte 0
b_hasCommand byte 0

; temporary value for piecemeal* iteration
; *stepping where an iterator is shared between procedures. 
spot dword ?

spotCopy dword ?

.CODE
; Labels the code section of the program.
; - includes all executable instructions written for this program,
; - for implementation details, see the comment sections below. 


; Labels main (the program body).
main PROC

	;Changes the output colors of the screen (purely cosmetic).
	call makeScreen

	L1:
		; Gets user input for the function below.
		call getInput

		; Gets the command typed by the user.
		call getCommand

		; Reacts to that given command.
		call reactCommand

		; Resets the input line and temp variables.
		call resetInput
		
		; Checks to see if the loops termination state has been reached,
		; - not contained in a procedure, since the comparison is trivial.
		mov al, b_hasQuit
		cmp al, 0
		jne done
		jmp L1

	done:
		exit
main ENDP



makeScreen PROC
	push eax
	push edx


	; Changes the command prompt's color using methods from IRVINE.inc.
	; - entirely cosmetic, but is mostly added to further sell the 'command line era Operating System' experience.
	mov eax, white + (blue * 16)
	call setTextColor
	call clrScr

	; Prints the program title (and cosmetic ascii strings) to the screen.
	; - - - - - - - - - - - - - - - - - - - - - - -
	mov edx, offset str_os
	mov ecx, sizeof str_os
	call writeString
	; - - - - - - - - - - - - - - - - - - - - - - -
	
	pop edx
	pop eax
	ret
makeScreen ENDP

getInput PROC
	push esi
	push edx
	push ecx

	; Prints a formatting string that breaks up output. 
	mov edx, offset str_line
	mov ecx, sizeof str_line
	call writeString

	mov edx, offset str_pointer
	mov ecx, sizeof str_pointer
	call writeString

	mov edx, offset bA_inputbuffer
	mov ecx, sizeof bA_inputbuffer
	call readString
	
	mov bAs_inputbuffer, cl

	mov spot, offset bA_inputbuffer

	pop ecx
	pop edx
	pop esi
	ret
getInput ENDP



resetInput PROC
	mov eax, NULL
	mov spot, eax
		
	mov cl,  bAs_inputbuffer
	L2:
		mov esi, offset bAs_inputbuffer
		mov byte ptr[esi], 0
		loop L2
	
	ret
resetInput ENDP



; SKIPCHARS
; DESCRIPTION:    Skips input to the next segment of whitespace,
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address.
skipwhitespace PROC
	push ecx
	push eax

	mov esi, spot
	mov cl,  bAs_inputbuffer

	L1:
		mov al, byte ptr[esi]
		cmp al, SPACE
		jne done
		cmp al, TAB
		jne done
		cmp al, NULL
		je done
		inc esi
		loop L1

	done:
		mov spot, esi
		pop eax
		pop ecx
		ret
skipwhitespace ENDP



; GETCOMMAND
; DESCRIPTION:    Fetches the user's command (and turns it into UPPERCASE),
; PRECONDITIONS:  <spot> has been initalized to point to the user's input.
; POSTCONDITIONS: Updates [spot]'s stored memory address, moves input into <command>.
getcommand PROC
	push edi
	push esi
	push eax

	mov esi, spot
	mov edi, offset bA_command
	mov cl,  bAs_inputbuffer

	call skipwhitespace
	

	L1:
		mov al, byte ptr[esi]
		cmp al, SPACE
		je done
		cmp al, TAB
		je done
		cmp al, NULL
		je done
		
		; Transforms ASCII input into uppercase.
		; - this is done to simplify comparisons against key strings.
		mov byte ptr [esi], al
		cld
		movsb
		and byte ptr [edi - 1], 11011111b
		loop L1

	done:
		mov spot, esi
		pop eax
		pop esi
		pop edi
		ret
getcommand ENDP



; COMPARE (TRANSPARENT)
; DESCRIPTION:    Compares <command> against all strings within <...key...>,
; PRECONDITIONS:  <command> holds valid data. 
; POSTCONDITIONS: Calls subroutines depending on the <...key...> entry hit*
; *if <command> is invalid, COMPARE returns to MAIN.
reactCommand PROC

	; clears the movement direction for comparisons.
	cld
	
	; moves the first string to be compared (help).
	mov esi, offset str_key_help
	mov edi, offset bA_command
	mov ecx, sizeof str_key_help
	dec ecx
	repe cmpsb
	jz commandHelp


	cld
	mov esi, offset str_key_quit
	mov edi, offset bA_command
	mov ecx, sizeof str_key_quit
	dec ecx
	repe cmpsb
	jz commandQuit
	

	cld
	mov esi, offset str_key_run
	mov edi, offset bA_command
	mov ecx, sizeof str_key_run
	dec ecx
	repe cmpsb
	jz commandRun
	
	mov al, b_hasCommand
	cmp al, 0
	jne done


	; Prints a help message.
	mov edx, offset str_error_command1
	mov ecx, sizeof str_error_command1
	call writeString

	mov edx, offset bA_inputbuffer
	mov ecx, sizeof bA_inputbuffer
	call writeString

	mov edx, offset str_error_command2
	mov ecx, sizeof str_error_command2
	call writeString

	
	done:
		ret
reactCommand ENDP

commandHelp PROC
	push eax
	push edx
	push ecx
	
	mov al, 1
	mov b_hasCommand, al
	

	; Prints a help message.
	mov edx, offset str_help
	mov ecx, sizeof str_help
	call writeString
	
	pop eax
	pop edx
	pop eax
	ret
commandHelp ENDP


commandQuit PROC
	push edx
	push eax

	mov al, 1
	mov b_hasCommand, al

	; Prints a quit message.
	mov edx, offset str_confirm_quit
	mov ecx, sizeof str_confirm_quit
	call writeString
	
	mov al, 1
	mov b_hasQuit, al

	pop eax
	pop edx
	ret
commandQuit ENDP


commandRun PROC
	push edx
	push eax

	mov al, 1
	mov b_hasCommand, al

	call resetInput

	mov edx, offset str_prompt_file
	mov ecx, sizeof str_prompt_file
	call writeString

	call getInput

	; a procedure that opens a file should be called here.

	pop eax
	pop edx
	ret
commandRun ENDP
END main

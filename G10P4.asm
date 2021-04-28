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
TAB    equ '	'
SPACE  equ ' '
RETURN equ 0dh, 0ah
NULL   equ 0
ZERO   equ '0'
NINE   equ '9'


; Defines constants for each Node Record.
N_NAME             equ 0
N_CONNECTIONS      equ 1
N_INQUEUE          equ 2
N_OUTQUEUE         equ 6
N_CONNECTION_ONE   equ 10
N_CONNECTION_TWO   equ 14
N_CONNECTION_THREE equ 18
N_CONNECTION_FOUR  equ 22
N_CONNECTION_FIVE  equ 26

; Defines shorthands for the size of a connection and a Node Record.
CONNECTION_SIZE equ 4
NODE_SIZE       equ N_CONNECTION_ONE + (CONNECTION_SIZE * 5)

; Defines constants for each Message Packet.
M_NAME_FROM    equ 0
M_NAME_TO      equ 1
M_TIME_TO_LIVE equ 2
M_TIME_SENT    equ 3
M_SENDER       equ 4

; Defines shorthands for the size of a:
; - Message,
; - Message Queue (In/Out),
; - Message Record (Offset used for OUTQUEUE Entries).
MESSAGE_SIZE      equ 8
QUEUE_SIZE        equ (MESSAGE_SIZE * 5)
QUEUE_RECORD_SIZE equ QUEUE_SIZE * 6

; NODE
; Lables <...node...>, a set of records and metadata that represent a set of network nodes.
bR_nodes    byte NODE_SIZE * 6 dup(?)

bR_queues  byte QUEUE_RECORD_SIZE * 2 dup (0)

; STRINGS
; This section of code contains hard-coded string (and character) memory addresses,
; - for implementation details, see the comments below.

; Key:
; Labels <...key...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_key_help   byte "HELP", 0
str_key_map    byte "MAP", 0
str_key_quit   byte "QUIT", 0
str_key_run    byte "RUN", 0


; Prompt:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_prompt_file byte "Please enter an output file name,",0dh, 0ah,
" - maximum length is 260 characters,",0dh, 0ah,
" - file extension appended automatically (.txt):",0dh, 0ah,0
str_prompt_echo byte "Would you like to run the simulation in echo mode (Y/N): ",0dh, 0ah,0


; Confirm:
; Labels <...confirm...>, a set of strings which tell the user input was accepted.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_confirm_quit byte "Goodbye, have a nice day.",0dh,0ah,0
str_confirm_file byte "Output file opened successfully.",0dh,0ah,0
str_confirm_run  byte "Initalization finished; continuing to the simulator...",0dh,0ah,0

; Error:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_error_command1 byte "Unrecognized command, '", 0
str_error_command2 byte "' please enter something else.", 0dh,0ah,0

str_error_file1    byte "Invalid File Name, '", 0
str_error_file2    byte "' please enter something else.", 0dh,0ah,0

; Misc:
; Defines odds and ends used for formatting throughout the program,
; - meant to be used in conjunction with strings found above (see above).
str_extension byte ".txt", 0
str_pointer byte "> ", 0
str_line    byte "------------------------------------------------------------------------------------------------------------------------", 0dh, 0ah, 0
str_os      byte "Welcome to Net S. P. ...", 0dh, 0ah,
"- type 'help' for implementation details, ", 0dh, 0ah,
"- type 'map' to view the simulation's node mapping, ", 0dh, 0ah,
"- type 'run' to begin the simulation,", 0dh, 0ah,
"- type 'quit' to exit the program.", 0dh, 0ah, 0
str_help    byte "This program simulates the processing network packets, ", 0dh, 0ah,
"- the process uses minimal metadata, and explores the limitations of a real network,", 0dh, 0ah,
"- packets start at Node A, and make their way to Node D,", 0dh, 0ah,
"- to begin configuring the simulation, type 'run'.", 0dh, 0ah, 0
str_map byte "      [E]---[F]", 0dh, 0ah,
"       |     |", 0dh, 0ah,
"[B]---[C]---[D] <- Message Destination (D),", 0dh, 0ah,
"       |", 0dh, 0ah,
"      [A]       <- Starting Location   (A).", 0dh, 0ah, 0
str_temp byte "Z,", 0dh,0ah, 0



; According to microsoft's suggestions, file names (plus their path) should total 260 characters or less,
; - while it is unlikely that a user WILL name their file something this long, choosing an arbitrary value is less consistent with the OS,
; - information cited under "Maximum Path Length Limitation".
; https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file?redirectedfrom=MSDN 
bA_inputbuffer       byte 265 dup(?)

bAs_inputbuffer      word 265

bA_command           byte 265 dup(?)

; Empty "String" that is written to files.
bA_stringbuilder     byte 150 dup(0)

; The cumulitive size of entries currently in the string builder.
bAs_stringbuilder    byte 1


b_hasQuit    byte 0
b_hasCommand byte 0
b_isRunning  byte 0
b_hasEcho    byte 0


b_time               byte 0
b_messages_generated byte 0
b_hops_taken         byte 0
b_messages_recieved  byte 0


; temporary value for piecemeal* iteration
; *stepping where an iterator is shared between procedures. 
spot dword ?
hdl_outfile dword 0

.CODE
; Labels the code section of the program.
; - includes all executable instructions written for this program,
; - for implementation details, see the comment sections below. 


; Labels main (the program body).
main PROC

	; Changes the output colors of the screen (purely cosmetic).
	call makeScreen

	; Fills relevant records with the simulation's "network topology"
	call initNodes

	; Steps through and prints each node's name. - remove this from the final program.
	call nodeRoleCall

	; The main command prompt loop.
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

		mov al, b_isRunning
		cmp al, 0
		jne L2
		jmp L1

	; The main node-processing loop.
	L2:

		; code for maintaining L2 as a while loop.
		;mov al, b_isRunning
		;cmp al, 1
		;jne done
		;jmp L2


	; Cleanup and goodbyes.
	done:
		; Prints a quit message.
		mov edx, offset str_confirm_quit
		call writeString
		
		mov eax, hdl_outfile
		call closefile
		exit
main ENDP

; Writes contents from stringbuilder to the current outfile and the screen.
writeBuilt PROC
		push eax
		push edx
		push ecx
		
		mov eax, hdl_outfile
		mov edx, offset bA_stringbuilder
		mov ecx, sizeof bA_stringbuilder
		call WriteToFile
		
		; error code for bad writes.
		;cmp eax, 0
		;je ERR_write

		mov edx, offset bA_stringbuilder
		call writeString
		
		pop ecx
		pop edx
		pop eax
		ret
writeBuilt ENDP



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
	call writeString
	; - - - - - - - - - - - - - - - - - - - - - - -
	
	pop edx
	pop eax
	ret
makeScreen ENDP



nodeRoleCall PROC
	push edi
	push ebx
	push eax

	mov edi, offset bR_nodes
	mov edx, offset str_temp

	mov al, byte ptr [edi]
	mov byte ptr[edx], al
	call writeString

	mov edx, offset str_temp
	add edi, NODE_SIZE

	mov al, byte ptr [edi]
	mov byte ptr[edx], al
	call writeString

	mov edx, offset str_temp
	add edi, NODE_SIZE

	mov al, byte ptr [edi]
	mov byte ptr[edx], al
	call writeString

	mov edx, offset str_temp
	add edi, NODE_SIZE

	mov al, byte ptr [edi]
	mov byte ptr[edx], al
	call writeString
	
	mov edx, offset str_temp
	add edi, NODE_SIZE

	mov al, byte ptr [edi]
	mov byte ptr[edx], al
	call writeString
	
	mov edx, offset str_temp
	add edi, NODE_SIZE

	mov al, byte ptr [edi]
	mov byte ptr[edx], al
	call writeString
	
	pop eax
	pop ebx
	pop edi
	ret
nodeRoleCall ENDP



initNodes PROC
	push edi
	push esi
	push eax
	push ebx

	; Moves the offset of each record (nodes, queues) into both pointer registers.
	mov esi, offset bR_nodes
	mov edi, offset bR_queues
	

	; Defines metadata for Node A.
	mov byte ptr[esi + N_NAME], 'A'
	mov byte ptr[esi + N_CONNECTIONS], 1
	
	; Assigns a unique input queue memory block.
	mov eax, edi
	mov dword ptr[esi + N_INQUEUE],  eax

	; Assigns a unique output queue memory block.
	mov eax, [edi + QUEUE_RECORD_SIZE]
	mov dword ptr[esi + N_OUTQUEUE], eax
	
	; Connects 'C'
	mov ebx, esi
	add ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_ONE], ebx



	; Moves to the next available Node Slot
	add esi, NODE_SIZE
	add edi, QUEUE_SIZE



	; Defines metadata for Node C.
	mov byte ptr[esi + N_NAME], 'C'
	mov byte ptr[esi + N_CONNECTIONS], 4
	
	; Assigns a unique input queue memory block.
	mov eax, edi
	mov dword ptr[esi + N_INQUEUE],  eax

	; Assigns a unique output queue memory block.
	mov eax, [edi + QUEUE_RECORD_SIZE]
	mov dword ptr[esi + N_OUTQUEUE], eax
	
	; Connects 'A'
	mov ebx, esi
	sub ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_ONE], ebx

	; Connects 'E'
	add ebx, NODE_SIZE
	add ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_TWO], ebx

	; Connects 'D'
	add ebx, NODE_SIZE
	add ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_THREE], ebx

	; Connects 'B'
	add ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_FOUR], ebx



	; Moves to the next available Node Slot
	add esi, NODE_SIZE
	add edi, QUEUE_SIZE



	; Defines metadata for Node E.
	mov byte ptr[esi + N_NAME], 'E'
	mov byte ptr[esi + N_CONNECTIONS], 2
	
	; Assigns a unique input queue memory block.
	mov eax, edi
	mov dword ptr[esi + N_INQUEUE],  eax

	; Assigns a unique output queue memory block.
	mov eax, [edi + QUEUE_RECORD_SIZE]
	mov dword ptr[esi + N_OUTQUEUE], eax

	; Connects 'C'
	mov ebx, esi
	sub ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_ONE], ebx

	; Connects 'F'
	add ebx, NODE_SIZE
	add ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_TWO], ebx



	; Moves to the next available Node Slot
	add esi, NODE_SIZE
	add edi, QUEUE_SIZE



	; Defines metadata for Node F.
	mov byte ptr[esi + N_NAME], 'F'
	mov byte ptr[esi + N_CONNECTIONS], 2
	
	; Assigns a unique input queue memory block.
	mov eax, edi
	mov dword ptr[esi + N_INQUEUE],  eax

	; Assigns a unique output queue memory block.
	mov eax, [edi + QUEUE_RECORD_SIZE]
	mov dword ptr[esi + N_OUTQUEUE], eax

	; Connects 'E'
	mov ebx, esi
	sub ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_ONE], ebx

	; Connects 'D'
	add ebx, NODE_SIZE
	add ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_TWO], ebx



	; Moves to the next available Node Slot
	add esi, NODE_SIZE
	add edi, QUEUE_SIZE



	; Defines metadata for Node D.
	mov byte ptr[esi + N_NAME], 'D'
	mov byte ptr[esi + N_CONNECTIONS], 2
	
	; Assigns a unique input queue memory block.
	mov eax, edi
	mov dword ptr[esi + N_INQUEUE],  eax

	; Assigns a unique output queue memory block.
	mov eax, [edi + QUEUE_RECORD_SIZE]
	mov dword ptr[esi + N_OUTQUEUE], eax

	; Connects 'F'
	mov ebx, esi
	sub ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_ONE], ebx

	; Connects 'C'
	sub ebx, NODE_SIZE
	sub ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_TWO], ebx



	; Moves to the next available Node Slot
	add esi, NODE_SIZE
	add edi, QUEUE_SIZE



	; Defines metadata for Node B.
	mov byte ptr[esi + N_NAME], 'B'
	mov byte ptr[esi + N_CONNECTIONS], 1
	
	; Assigns a unique input queue memory block.
	mov eax, edi
	mov dword ptr[esi + N_INQUEUE],  eax

	; Assigns a unique output queue memory block.
	mov eax, [edi + QUEUE_RECORD_SIZE]
	mov dword ptr[esi + N_OUTQUEUE], eax
	
	; Connects 'C'
	mov ebx, esi
	sub ebx, NODE_SIZE
	sub ebx, NODE_SIZE
	sub ebx, NODE_SIZE
	sub ebx, NODE_SIZE
	mov dword ptr[esi + N_CONNECTION_TWO], ebx

	pop ebx
	pop eax
	pop esi
	pop edi
	ret
initNodes ENDP




getInput PROC
	push esi
	push edx
	push ecx

	; Prints a formatting string that breaks up output. 
	mov edx, offset str_line
	call writeString

	mov edx, offset str_pointer
	call writeString

	mov edx, offset bA_inputbuffer
	mov ecx, sizeof bA_inputbuffer
	sub ecx, 4
	call readString
	
	mov bAs_inputbuffer, cx

	mov spot, offset bA_inputbuffer

	pop ecx
	pop edx
	pop esi
	ret
getInput ENDP



resetInput PROC
	mov eax, NULL
	mov spot, eax
	
	mov ecx, 0
	mov cx,  bAs_inputbuffer
	mov esi, offset bA_inputbuffer
	L1:
		mov byte ptr[esi], 0
		inc esi
		loop L1

	mov cx,  sizeof bA_command
	mov esi, offset bA_command
	L2:
		mov byte ptr[esi], 0
		inc esi
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
	mov cx,  bAs_inputbuffer

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
	mov cx,  bAs_inputbuffer

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

	; resets a boolean used to determine whether or not a command was ran.
	mov al, 0
	mov b_hasCommand, al

	; clears the movement direction for comparisons.
	cld
	
	; moves the first string to be compared (help).
	mov esi, offset str_key_help
	mov edi, offset bA_command
	mov ecx, sizeof str_key_help
	repe cmpsb
	jz commandHelp

	cld
	mov esi, offset str_key_map
	mov edi, offset bA_command
	mov ecx, sizeof str_key_map
	repe cmpsb
	jz commandMap

	cld
	mov esi, offset str_key_quit
	mov edi, offset bA_command
	mov ecx, sizeof str_key_quit
	repe cmpsb
	jz commandQuit
	

	cld
	mov esi, offset str_key_run
	mov edi, offset bA_command
	mov ecx, sizeof str_key_run
	repe cmpsb
	jz commandRun
	
	mov al, b_hasCommand
	cmp al, 0
	jne done


	; Prints an error message.
	mov edx, offset str_error_command1
	call writeString

	mov edx, offset bA_inputbuffer
	call writeString

	mov edx, offset str_error_command2
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
	call writeString
	
	pop eax
	pop edx
	pop eax
	ret
commandHelp ENDP



commandMap PROC
	push eax
	push edx
	push ecx
	
	mov al, 1
	mov b_hasCommand, al
	
	mov edx, offset str_map
	call writeString
	
	pop eax
	pop edx
	pop eax
	ret
commandMap ENDP



commandQuit PROC
	push edx
	push eax

	mov al, 1
	mov b_hasCommand, al
	
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

	L1S:
		mov edx, offset str_prompt_file
		call writeString
		L1:
			call getInput
			call appendExtension

			mov edx, offset bA_inputbuffer
			call CreateOutputFile

			mov hdl_outfile, eax
			jmp V1
	
		V1:
			; Compares the created file against null,
			; - skips a warning message if EAX is a valid pointer.
			cmp eax, INVALID_HANDLE_VALUE
			jne LS2

			mov edx, offset str_error_file1
			call writeString
			
			mov edx, offset bA_inputbuffer
			call writeString

			mov edx, offset str_error_file2
			call writeString

			call resetInput
			jmp L1



	LS2:
		mov edx, offset str_prompt_echo
		call writeString
		mov al, 1
		mov b_isRunning, al
		L2:
			call getInput
			jmp V2

		V2:
			mov esi, offset bA_inputbuffer
			
			cmp byte ptr [esi + 1], NULL
			jne R2

			and byte ptr[esi], 11011111b
			
			; Checks for "YES"
			cmp byte ptr[esi], "Y"
			je YESECHO

			; Checks for "NO"
			cmp byte ptr[esi], "N"
			je NOECHO
			jmp R2
		
		R2:
			
			mov edx, offset str_error_command1
			call writeString
			
			mov edx, offset bA_inputbuffer
			call writeString

			mov edx, offset str_error_command2
			call writeString

			call resetInput
			jmp L2

	YESECHO:
		mov al, 1
		mov b_hasEcho, al

	NOECHO:
		mov edx, offset str_confirm_run
		call writeString
	pop eax
	pop edx
	ret
commandRun ENDP



; SKIPCHARS
; DESCRIPTION:    Skips input to the next segment of whitespace,
; PRECONDITIONS:  <spot> has been initalized to point to the user's input. 
; POSTCONDITIONS: Updates [spot]'s stored memory address.
appendExtension PROC
	push ecx
	push eax
	push esi
	push edi

	mov edi, spot
	mov cx,  bAs_inputbuffer

	L1:
		mov al, byte ptr[edi]
		cmp al, NULL
		je L2
		inc edi
		loop L1
	
	L2:
		mov esi, offset str_extension
		mov ecx, sizeof str_extension
		dec ecx
		rep movsb

	done:
		pop edi
		pop esi
		pop eax
		pop ecx
		ret
appendExtension ENDP
END main
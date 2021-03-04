TITLE R.P.N. Calculator                       (G10P2.asm).
COMMENT !                                                .
.Created By:                                             .
.             - Daniel Hentosz (HEN3883@calu.edu)        .
.             - Scott Trunzo   (TRU1931@calu.edu)        .
.			                                             .
.Last Revised: March 4rd, 2021.                (3/4/2021).
.Written for Assembly Language Programming  (CSC-323-R01).
Description:

Uses R.P.N. notation to quickly preform basic arithmetic:

 - this notation is preformed onto an 8 entry stack,

 - notation includes the following symbol cateogries:

   + " "   (SPACE, TAB)
     - ignored when taking user input.
	 - EX "   + ENTER" acts exactly like "+ ENTER".
  
   + "0-9" (DIGIT)
     - pushes a number into the stack,
	   + can be positive or negative (see "-"),
	 - EX "10 ENTER" adds 10d to the stack.
   
   + "+"   (ADD)
     - adds the first two entries on the stack together,
	 - EX "+" {stack: 10, 12}, the stack becomes {stack: 22}.

   + "-"*  (SUBTRACT & NEGATIVE*)
     - subtracts the first two entries on the stack from eachother,
	 - *if encountered before a digit that digit becomes negative, 
	 - EX "- ENTER" {stack: 10, 12}, the stack becomes {stack: -2}.

   + "*"   (MULTIPLY)
     - multiplies the first two entries on the stack together,
	 - EX "* ENTER" {stack: 10, 12}, the stack becomes {stack: 120}.

   + "/"   (DIVIDE)
     - divides the second entry on the stack by the first,
	 - EX "/ ENTER" {stack: 2, 4}, the stack becomes {stack: 2}.

   + "X"   (E(X)CHANGE)
     - swaps the first two values on the stack with eachother,
	 - EX "X ENTER" {stack: 2, 4}, the stack becomes {stack: 4, 2}.

   + "N"   ((N)EGATE)
     - swaps the sign for the first entry in the stack,
	 - EX "N ENTER" {stack: 2, 4}, the stack becomes {stack: -2, 4}.	
	
   + "V"   ((V)IEW)
     - displays the entire stack,
	 - EX "V ENTER" {stack: 2, 4}, prints +2 +4.

   + "C"   ((C)LEAR)
     - empties the entire stack,
	 - EX "C ENTER" {stack: 2, 4}, the stack is emptied.


   + "U"   (ROLL (U)P)
     - shifts all values on the stack UP by one,
	 - EX "U ENTER" {stack: 2, 4, 8}, the stack becomes {stack: 4, 8, 2}.
		
   + "D"   (ROLL (D)OWN)
     - shifts all values on the stack DOWN by one,
	 - EX "D ENTER" {stack: 2, 4, 8}, the stack becomes {stack: 8, 2, 4}.

   + "Q"   ((Q)UIT)
     - terminates the program.
   
   + After one of these character(s)* is found,
    - no other commands may be entered on that line (ignored),
	* excludes SPACE and TAB (see above).
	- EX "+ 1 ENTER" is equivalent to "+ ENTER".
   
   + Other forms of input will be ignored (BAD DATA).
!



.386
.MODEL flat, stdcall
.STACK 4096
; Defines information regarding the system stack,
; this is bundled alongside identification information for the program.



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
str_line         byte "|----------------------------------------------------------", 0dh, 0ah, 0
str_blank        byte "| ", 0
str_pointer      byte "> ", 0


; Prompt:
; Labels <...prompt...>, a set of strings which prompt the user to input data.
; - used in conjunction with <str_line>, <str_blank>, and <str_pointer>.
str_prompt      byte "| Please enter a valid value.", 0dh, 0ah, 0
str_prompt_help byte "| Valid value(s) include:",  0dh, 0ah,
"| - integers (positive or negative),",  0dh, 0ah,
"| - operands (+, -, *, /),",  0dh, 0ah,
"| - commands; which include:",  0dh, 0ah,
"|   + (X) Exchange,",  0dh, 0ah,
"|   + (N) Negate,",  0dh, 0ah,
"|   + (V) View,",  0dh, 0ah,
"|   + (C) Clear,",  0dh, 0ah,
"|   + (U) Roll Stack Up,", 0dh, 0ah,
"|   + (D) Roll Stack Down,", 0dh, 0ah,
"|   + (Q) Quit.", 0dh, 0ah, 0
str_prompt_accepted byte " is now the stack top.", 0dh, 0ah, 0
str_prompt_rejected byte " Procedure failed,",  0dh, 0ah, 0


; Error
; Labels <...error...>, a set of strings which inform the user of input/program errors.
; - used in conjunction with <str_line> and <str_blank>.
str_err_empty    byte "- not enough elements in the stack.", 0dh, 0ah, 0
str_err_full     byte "- stack is full.", 0dh, 0ah, 0
str_err_big      byte "- entered value larger than -/+ 1,000,000,000.", 0dh, 0ah, 0
str_err_bad      byte "- entered bad data.", 0dh, 0ah, 0
str_err_zero     byte "- cannot divide by zero.", 0dh, 0ah, 0


; Results
; Labels <...results...>, a set of strings which label data calculated by this program.
; - used in conjunction with <str_line>, <str_blank>.
str_results_total byte "| Displaying the stack... ", 0dh, 0ah, 0
str_results_clear byte "| The stack has been cleared. ", 0dh, 0ah, 0
str_results_up    byte "| The stack has been rolled up. ", 0dh, 0ah, 0
str_results_down  byte "| The stack has been rolle down. ", 0dh, 0ah, 0


; Quit
; Labels <...quit...>, a set of strings which inform the user that the program is quitting to desktop.
; - used in conjunction with <str_line>, <str_blank>.
str_quit1 byte "| Quitting to the command prompt...", 0dh, 0ah, 0
str_quit2 byte "| Be sure to stack again soon!", 0dh, 0ah, 0



; MISC
; Labels other data values (int, array, etc) labelled for use in this program.


; Labels <bA_choice>, a sbyte (8 bit) sized memory address array.
; - temporarily stores input typed by the user.
sbA_choice   sbyte 20 dup(?)


; Labels <b_len>, a byte (8 bit) sized memory address.
; - temporarily stores the length of input (typed by the user).
b_len      byte ?


; Labels <b_exp_len>, a byte (8 bit) sized memory address.
; - temporarily stores the length of input (typed by the user).
b_exp_len  byte ?


; Labels <b_num>, a signed doubleword (32 bit) sized memory address.
; - temporarily stores converted integer values typed by the user.
b_num      sdword ?


; Labels <b_is_num_negative>, a byte (8 bit) sized memory address.
; - acts as a flag for <num>, which accounts for '-' preceeding a converted integer (EX: '-12').
b_is_num_negative byte ?


; Labels <b_count>, a byte (8 bit) sized memory address.
; - stores the size of this programs internal array (stored in the system stack).
b_count byte 0



.CODE
; Labels the code section of the program.
; - includes all executable instructions written for this program,
; - for implementation details, see the comment sections below. 



; Labels main (the program body).
main PROC

	; The program's starting point.
	; Serves as a break from the main loop that asks for user input.
	Start:
	
		; Moves various strings into [edx],
		; - describe program functionality to the user.
		help:
			mov	edx, OFFSET str_line
			call WriteString
			mov	edx, OFFSET str_prompt
			call WriteString
			mov	edx, OFFSET str_line
			call WriteString
			mov	edx, OFFSET str_prompt_help
			call WriteString
			mov	edx, OFFSET str_line
			call WriteString


		; moves a '>' symbol to where data entry takes place.
		mov	edx, OFFSET str_pointer
		call WriteString

		; Prepares registers for calling readstring (see below).
		mov edx, offset sbA_choice
		mov ecx, 20
		
		; Zeroes [ebx], which is used to reset value(s) below.
		mov ebx, 0
		
		; Resets <b_num> and <b_num_negative>.
		mov b_num, ebx
		mov b_is_num_negative, bl
		
		; Reads input from the user.
		call readstring

		; Zeroes [ecx], since choice-length no longer needs to be stored there.
		mov ecx, 0

		; Copies the length from [al] to <b_len> for reuse.
		mov b_len, al
		
		; Assigns a pointer value to [esi].		
		mov esi, offset [sbA_choice]
		
		; Moves (with zeroes extended) the value [esi] points to.
		; This value is always written by readstring, even if input is blank.
		movzx eax, byte ptr[esi]
		
		; Jumps to LMainStart.
		jmp LMainStart
	
	
	;Landing pad for any bad data in the program. 
	BadData:
		; Moves (and prints) a prompt, informing the user that their data was invalid.
		mov	edx, OFFSET str_prompt_rejected
		call WriteString
		mov edx, offset str_err_bad
		call writestring
		
		; Jumps back to the Start label.
		jmp Start
	
	; Serves as a bridge between Start and Main
	LMainStart:

		; Jumps to Main.
		jmp LMain
	
	; serves as the main compare for the LMain loop.
	LMainComp:
		; Compares [cx] to the recorded <b_len>.
		; if [cx] is larger, then the data entered above was bad.
		cmp cl, b_len
		jge BadData
		
		; otherwise, increments [c], and fetches a new value for [eax].
		; - afterward, the loop iterates.
		inc cx
		movzx eax, byte ptr[esi + ecx]
		jmp LMain
	
	; Compares the value stored in [eax] against various datatypes.
	LMain:
	
		; Checks to see if the value stored in [eax] is NULL (end of a string).
		; If it is, program jumps to an error state (see BadData).
		cmp eax, 0
		je BadData
		
		; Checks to see if the value stored in [eax] is a space.
		; Iterates past that whitespace, if so (see LMainComp).
		cmp eax, ' '
		je LMainComp
		
		; Checks to see if the value stored in [eax] is a space.
		; Iterates past that whitespace, if so (see LMainComp).
		cmp eax, '	'
		je LMainComp

		; Checks to see if the value stored in [eax] is a dash.
		; Moves to a seperate handler, if so (see DashHandler).
		cmp eax, '-'
		je  DashHandler

		; Checks to see if the value stored in [eax] is a plus.
		; Moves to a seperate handler, if so (ad).
		cmp eax, '+'
		je ad
		
		; Checks to see if the value stored in [eax] is an asterix.
		; Moves to a seperate handler, if so (see mu).
		cmp eax, '*'
		je mu

		; Checks to see if the value stored in [eax] is a slash.
		; Moves to a seperate handler, if so (see divi).
		cmp eax, '/'
		je divi

		; Checks to see if the value stored in [eax] is alphabetic.
		; Moves to a seperate handler, if so (see Operators).
		cmp eax, 58
		jge Operators
		
		; Checks to see if the value stored in [eax] is a numeric.
		; Moves to a seperate handler, if so (see LDigitStartPositive).
		cmp eax, 57
		jle LDigitsStartPositive
		

		; Jumps to BadData, if none of these categories of symbol are found.
		jmp BadData
	
	
	;Serves as a sub-comparison that tries to find alphabetic symbols.
	Operators:
		
		;Transforms any incoming data into a capitalized form ('q' becomes 'Q'). 
		and al, 11011111b
		
		; Checks to see if the command is X (Exchange).
		; Moves to a seperate handler, if so (see ex).
		cmp eax, 'X'
		je ex


		; Checks to see if the command is N (Negate Top).
		; Moves to a seperate handler, if so (see negate).
		cmp eax, 'N'
		je negate
		
		; Checks to see if the command is V (View).
		; Moves to a seperate handler, if so (see view).
		cmp eax, 'V'
		je view

		; Checks to see if the command is C (Clear Stack).
		; Moves to a seperate handler, if so (see clear).
		cmp eax, 'C'
		je clear

		; Checks to see if the command is Q (Quit).
		; Terminates the program, if so (see quit).
		cmp eax, 'Q'
		je quit

		; Checks to see if the command is U (Roll Stack Up).
		; Moves to a seperate handler, if so (see up).
		cmp eax, 'U'
		je up

		; Checks to see if the command is D (Roll Stack Down).
		; Moves to a seperate handler, if so (see down).
		cmp eax, 'D'
		je down
		
		; Jumps to BadData, if none of these categories of symbol are found.
		jmp BadData
		
		
	; Begins the LDigitsComp loop for a positive number.
	LDigitsStartPositive:
	
		; Attempts to see if the stack is full,
		cmp b_count, 8
		; Jumps to Full, if so.
		jge full
		
		; Moves the current length into <b_exp_len> for comparisons below.
		mov b_exp_len, cl
		
		; Jumps to the main loop.
		jmp LDigits

	; Begins the LDigitsComp loop for a negative number.
	LDigitsStartNegative:
		; Attempts to see if the stack is full,
		cmp b_count, 8
		; Jumps to Full, if so.
		jge full
		
		
		; Moves the current length into <b_exp_len> for comparisons below.
		mov b_exp_len, cl
		
		; Moves fetches, increments, then sets <b_is_num_negative> to 1.
		mov cl, b_is_num_negative
		inc cl
		mov b_is_num_negative, cl
		
		
		; Moves the current length into <b_exp_len> for comparisons below.
		mov b_exp_len, cl
		
		; Jumps to the main loop.
		jmp LDigits
		
		
	; Compares for each step of the LDigitsComp loop.
	LDigitsComp:
	
		; Sees if this is the last loop iteration.
		cmp cl, b_len
		; Concludes the loop, if os.
		jge LDigitsDone
		
		; Uses <b_exp_len> (-offset) to see the amount of digits in the current number,
		sub cl, b_exp_len
		cmp cl, 10
		; Jumps to an error state if so (see LDigitsOverflow).
		jge LDigitsOverflow
		add cl, b_exp_len

		; Increments the loop counter.
		inc cl
		
		; Fetches the next value from esi.
		movzx eax, byte ptr[esi + ecx]

		; Compares [eax] against an upper and lower bound,
		; - If the value is not between 48 <= [eax] <= 47,
		;  + the loop terminates.
		cmp eax, 58
		jge LDigitsDone
		cmp eax, 47
		jle LDigitsDone
		
		; Otherwise, jumps to the main loop.
		jmp LDigits
	
	
	; Accounts for values that could cause an integer overflow.
	LDigitsOverflow:
		; Tells the user that they've entered an invalid integer.
		mov	edx, OFFSET str_prompt_rejected
		call WriteString
		mov edx, offset str_err_big
		call writestring
		
		; Jumps back to the beginning of the loop.
		jmp Start
	
	
	; The main section of the LDigits loop.
	LDigits:
		; Transforms [al] into a decimal value.
		and al, 00001111b
		
		; Compares [cl] against the initial length,
		; jumps past the next line of code, if so.
		cmp cl, b_exp_len
		je LDigitsLower
		
		; Otherwise, offsets the value currently in [ebx] by one decimal place.
		imul ebx, ebx, 10
		
		; Adds [eax] to [ebx].
		LDigitsLower:
			add ebx, eax
			
			; Jumps to the loop's comparison segment.
			jmp LDigitsComp
	
	
	; Concludes the LDigits loop.
	LDigitsDone:
	
		; Checks to see if the value not a negative number,
		; - skips the next few lines of code, if so.
		cmp b_is_num_negative, 0
		je LDigitsDoneLower
		
		; Negates the value currently stored in [ebx].
		neg ebx
		

		LDigitsDoneLower:		
			; moves the current count to [al],
			; increments, then stores that count back into <b_count>
			mov al, b_count
			inc al
			mov b_count, al
			
			; pushes [ebx] onto the system stack.
			push ebx
			
			; moves [ebx] into [eax] for display.
			mov eax, ebx
			
			; Afterward, ends the loop.
			jmp Done
	
	
	; Handles '-' symbols seperately, as they can be:
	; - subtraction, or,
	; - a negative number.
	DashHandler:
	
		; compares the current length,
		; if there are no other character(s) left, this is subtraction.
		cmp cl, b_len
		jge su
		
		; increments the loop counter,
		inc cx
		
		; moves the next value into [eax],
		movzx eax, byte ptr[esi + ecx]
		
		; checks to see if that value is within 0-9,
		; - if not, this is subtraction,     (su)
		; - if so, this is a negative number (LDigitsStartPositive)
		cmp eax, 57
		jge su
		cmp eax, 48
		jge LDigitsStartNegative
		jmp su
		
		
		
	; Calls the addtoptwo procedure.
	ad:
		; moves count into [ecx]
		movzx ecx, b_count
		
		; checks to see if the stack has enough entries,
		cmp ecx,1
		; jumps to an error state, if so.
		jle toosmall
		
		; otherwise, calls addtoptwo
		call addtoptwo
		
		; pushes the new value [eax], if so.
		push eax
		
		; ends this operation.
		jmp doneOperator


	; Calls the subtoptwo procedure.
	su:
		; moves count into [ecx]
		movzx ecx, b_count
		
		; checks to see if the stack has enough entries,
		cmp ecx,1
		; jumps to an error state, if so.
		jle toosmall
		
		; otherwise, calls subtoptwo
		call subtoptwo
		
		; pushes the new value [eax], if so.
		push eax
		
		; ends this operation.
		jmp doneOperator


	; Calls the multoptwo procedure.
	mu:
		; moves count into [ecx]
		movzx ecx, b_count
		
		; checks to see if the stack has enough entries,
		cmp ecx,1
		
		; jumps to an error state, if so.
		jle toosmall
		
		; otherwise, calls multoptwo
		call multoptwo
		
		; pushes the new value [eax], if so.
		push eax
		
		; ends this operation.
		jmp doneOperator


	; Calls the divtoptwo procedure.
	divi:
		; moves count into [ecx]
		movzx ecx, b_count
		
		; checks to see if the stack has enough entries,
		cmp ecx,1
		
		; jumps to an error state, if so.
		jle toosmall
		
		; otherwise, calls divtoptwo
		call divtoptwo
		cmp eax, 0
		je start
		
		; pushes the new value [eax], if so.
		push eax
		
		; ends this operation.
		jmp doneOperator


	; Calls the xchgtoptwo procedure.
	ex:
		; moves count into [ecx]
		movzx ecx, b_count
		
		; checks to see if the stack has enough entries,
		cmp ecx,1
		
		; jumps to an error state, if so.
		jle toosmall
		
		; otherwise, calls xchgtoptwo
		call xchgtoptwo
		
		; ends this operator (no decrement)
		jmp done
	
	; calls the negate procedure
	negate:
		cmp b_count, 0
		jle toosmall
		call negatetop
		jmp done
	
	; calls the view procedure
	view:
		cmp b_count, 0
		jle toosmall
		call viewstack
		; ends this operator (no decrement)
		jmp start

	; clears the stack.
	clear:
		; enters a new line when clearing.
		call crlf
		movzx ecx, b_count
		
		; determines which macro clear should branch onto,
		; is not a loop (since the stack has a set size).
		; - if the stack is empty, an error message is displayed.
		cmp ecx, 1
		je one
		cmp ecx, 2
		je two
		cmp ecx, 3
		je three
		cmp ecx, 4
		je four
		cmp ecx, 5
		je five
		cmp ecx, 6
		je six
		cmp ecx, 7
		je seven
		cmp ecx, 8
		je eight
		jmp toosmall

	; Serves as the branch(es) for the case statement above,
	; reduces count to zero, then moves to cleardone.
	one:
		add esp, 4
		dec b_count
		jmp cleardone
	two:
		add esp, 8
		sub b_count, 2
		jmp cleardone
	three:
		add esp, 12
		sub b_count, 3
		jmp cleardone
	four:
		add esp, 16
		sub b_count, 4
		jmp cleardone
	five:
		add esp, 20
		sub b_count, 5
		jmp cleardone
	six:
		add esp, 24
		sub b_count, 6
		jmp cleardone
	seven:
		add esp, 28
		sub b_count, 7
		jmp cleardone
	eight:
		add esp, 32
		sub b_count, 8
		jmp cleardone
	
	; Informs the user that clearing was successful.
	; Jumps to the start of the program, if so.
	cleardone:
			mov	edx, OFFSET str_line
			call WriteString
			mov	edx, OFFSET str_results_clear
			call WriteString
			jmp start
	
	; Calls the rollupstack procedure.
	; - rejects input if the stack is too small,
	; - prints a message when execution is successful.
	up:
		cmp b_count, 1
		jle toosmall
		call rollupstack
		mov	edx, OFFSET str_line
		call WriteString
		mov	edx, OFFSET str_results_up
		call WriteString
		jmp start

	; calls the rolldownstack procedure.
	; - rejects input if the stack is too small,
	; - prints a message when execution is successful.
	down:
		cmp b_count, 1
		jle toosmall
		call rolldownstack
		mov	edx, OFFSET str_line
		call WriteString
		mov	edx, OFFSET str_results_down
		jmp done


	; Displays an error message (if the stack lacks entries).
	toosmall:
		mov	edx, OFFSET str_prompt_rejected
		call WriteString
		mov edx,offset str_err_empty
		call writestring
		jmp start



		
	; Acts as a landing pad for prodecures/operators.
	; Informs the user that their value was accepted, before iterating again.
	done:
		call crlf
		mov edx,offset str_blank
		call writestring
		call writeint
		mov edx,offset str_prompt_accepted
		call writestring
		jmp start

	; Acts as a landing pad for operators,
	; decrements count before returning to the normal pad (done).
	doneOperator:
		dec b_count
		jmp done
	
	; Displays an error message when the stack is too full.
	; Afterward, iterates the loop.
	full:
		mov	edx, OFFSET str_prompt_rejected
		call WriteString
		mov edx,offset str_err_full
		call writestring
		jmp Start

	; Serves as the terminator for the program.
	; Prints an ending prompt upon termination.
	quit:
		mov	edx, OFFSET str_line
		call WriteString
		mov	edx, OFFSET str_quit1
		call WriteString
		mov	edx, OFFSET str_quit2
		call WriteString
		mov	edx, OFFSET str_line
		call WriteString
		exit
		
main ENDP



; ADDTOPTWO
; DESCRIPTION:    returns the top two entires of the stack added together.
; PRECONDITIONS:  stack has two entries, [eax] is available. 
; POSTCONDITIONS: returns esp[8] as [eax].
addtoptwo PROC
	mov eax, dword ptr[esp + 4]
	add eax, dword ptr[esp + 8]
	ret 8
addtoptwo ENDP



; SUBTOPTWO
; DESCRIPTION:    returns the top two entires of the stack subtracted from eachother.
; PRECONDITIONS:  stack has two entries, [eax] is available. 
; POSTCONDITIONS: returns esp[8] as [eax].
subtoptwo PROC
	mov eax, dword ptr[esp + 8]
	sub eax, dword ptr[esp + 4]
	ret 8
subtoptwo ENDP



; MULTOPTWO
; DESCRIPTION:    returns the top two entires of the stack subtracted from eachother.
; PRECONDITIONS:  stack has two entries, [eax] is available. 
; POSTCONDITIONS: returns esp[8] as [eax].
multoptwo PROC
	
	; moves, then compares the values for [ebx]/[eax],
	; if either is below 0, imul is used instead of mul.
	; regardless, the result of multiplication is stored in [eax].
	mov eax, dword ptr[esp + 4]
	mov ebx, dword ptr[esp + 8]
	cmp eax, 0
	jb negmul
	cmp ebx, 0
	jb negmul
	
	mul ebx
	jmp done
	
	; accounts for multiplication of negative numbers.
	negmul :
		imul eax, ebx
		
	; returns to the main procedure.
	done :
		ret 8
multoptwo ENDP



; DIVTOPTWO
; DESCRIPTION:    returns the top two entires of the stack divided (second by first).
; PRECONDITIONS:  stack has two entries, [eax] is available. 
; POSTCONDITIONS: returns esp[8] as [eax].
divtoptwo PROC
	mov edx, 0
	mov eax, dword ptr[esp + 8]
	cdq
	mov ebx, dword ptr[esp + 4]
	idiv ebx
	ret 8
divtoptwo ENDP



; XCHGTOPTWO
; DESCRIPTION:    exchanges the top two values in the stack.
; PRECONDITIONS:  stack has two entries, [eax] is available. 
; POSTCONDITIONS: esp[4] and esp[8] are exchanged.
xchgtoptwo PROC
	mov eax, dword ptr[esp + 4]
	xchg dword ptr[esp + 8], eax
	mov dword ptr[esp + 4], eax
	ret
xchgtoptwo ENDP



; NEGATETOP
; DESCRIPTION:    negates the top value of the stack.
; PRECONDITIONS:  stack has one entry, [eax] is available. 
; POSTCONDITIONS: esp[4] is negated.
negatetop PROC
	mov eax, dword ptr[esp]
	neg eax
	mov dword ptr[esp], eax
	ret
negatetop ENDP



; ROLLUPSTACK
; DESCRIPTION:    shifts all values in the stack upwards [-4].
; PRECONDITIONS:  stack has at least one entry.
; POSTCONDITIONS: esp[n] is shifted by -4 (n being any e(n)try).
rollupstack PROC

	; determines which macro rollupstack should branch onto,
	; is not a loop (since the stack has a set size).
	; - if the stack is below 2, the procedure below is ignored.
	movzx ecx, b_count
	cmp ecx, 1
	jbe done
	cmp ecx, 2
	je two
	cmp ecx, 3
	je three
	cmp ecx, 4
	je four
	cmp ecx, 5
	je five
	cmp ecx, 6
	je six
	cmp ecx, 7
	je seven
	cmp ecx, 8
	je eight



	; Serves as the branch(es) for the case statement above,
	; exchanges each value in the stack, rotating the values upward (towards top),
	; the value at the very top becomes the value at the very bottom.
	two :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	three :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	four :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	five :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	six :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 24]
		xchg eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	seven :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 28]
		xchg eax, dword ptr[esp + 24]
		xchg eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	eight :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 32]
		xchg eax, dword ptr[esp + 28]
		xchg eax, dword ptr[esp + 24]
		xchg eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		
	; returns to the main procedure.
	done :
		call crlf
		ret
rollupstack ENDP



; VIEWSTACK
; DESCRIPTION:    prints the stack to the console.
; PRECONDITIONS:  stack has at least one entry.
; POSTCONDITIONS: stack entries are printed to the console.
viewstack PROC
	; prints prompts, informing the user that data will be printed to the console.
	mov	edx, OFFSET str_line
	call WriteString
	mov	edx, OFFSET str_results_total
	call WriteString
	mov	edx, OFFSET str_blank
	call WriteString
	
	; compares the current count against zero,
	; - skips the loop below if equal.
	movzx ecx, b_count
	cmp ecx, 0
	jle done
	; moves 4 into [ebx], before continuing to the loop below.
	mov ebx, 4

	; Iterates through each value in the array using [ebx]
	; - prints whitespace between each value, also.
	L1:
		mov eax, dword ptr[esp + ebx]
		add ebx, 4
		call writeint
		mov al, 9
		call writechar
		loop L1
		; starts a new line after the value(s) have been printed.
		call crlf
	
	; returns to the main procedure.
	done :
		ret
viewstack ENDP



; ROLLDOWNSTACK
; DESCRIPTION:    shifts all values in the stack downwards [+4].
; PRECONDITIONS:  stack has at least one entry.
; POSTCONDITIONS: esp[n] is shifted by +4 (n being any e(n)try).
rolldownstack PROC
	
	; determines which macro rolldownstack should branch onto,
	; is not a loop (since the stack has a set size).
	; - if the stack is below 2, the procedure below is ignored.
	movzx ecx, b_count
	cmp ecx, 1
	jbe done
	cmp ecx, 2
	je two
	cmp ecx, 3
	je three
	cmp ecx, 4
	je four
	cmp ecx, 5
	je five
	cmp ecx, 6
	je six
	cmp ecx, 7
	je seven
	cmp ecx, 8
	je eight
	
	; Serves as the branch(es) for the case statement above,
	; exchanges each value in the stack, rotating the values downward (towards bottom),
	; the value at the very bottom becomes the value at the very top.
	two :
		mov eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 4], eax
		jmp done
	three :
		mov eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		mov dword ptr[esp + 12], eax
		jmp done
	four :
		mov eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		xchg eax, dword ptr[esp + 12]
		mov dword ptr[esp + 16], eax
		jmp done
	five :
		mov eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 16]
		mov dword ptr[esp + 20], eax
		jmp done
	six :
		mov eax, dword  ptr[esp + 24]
		xchg eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 20]
		mov dword ptr[esp + 24], eax
		jmp done
	seven :
		mov eax, dword ptr[esp + 28]
		xchg eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 24]
		mov dword ptr[esp + 28], eax
		jmp done
	eight :
		mov eax, dword ptr[esp + 32]
		xchg eax, dword ptr[esp + 4]
		xchg eax, dword ptr[esp + 8]
		xchg eax, dword ptr[esp + 12]
		xchg eax, dword ptr[esp + 16]
		xchg eax, dword ptr[esp + 20]
		xchg eax, dword ptr[esp + 24]
		xchg eax, dword ptr[esp + 28]
		mov dword ptr[esp + 32], eax

	; returns to the main procedure.
	done :
		call crlf
		ret
rolldownstack ENDP

END main
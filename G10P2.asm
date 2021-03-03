TITLE R.P.N. Calculator                       (G10P2.asm).
COMMENT !                                                .
.Created By:                                             .
.             - Daniel Hentosz (HEN3883@calu.edu)        .
.             - Scott Trunzo   (TRU1931@calu.edu)        .
.			                                 .
.Last Revised: March 3rd, 2021.                (3/3/2021).
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
	 - EX "U ENTER" {stack: 2, 4, 8}, the stack becomes {stack: 8, 2, 4}.

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

ExitProcess PROTO, dwExitCode:DWORD

INCLUDE irvine32.inc



.DATA



choice   sbyte 20 dup(? )
len      byte ?
len_temp byte ?

exp      dword 1d
exp_len  byte ?
num      sdword ?
num_negative byte ?
bigmsg byte "Enter a number greater than -1,000,000,000", 0dh, 0ah, 0
badmsg byte "Invalid Data", 0dh, 0ah, 0
temp sdword ?
count byte 0
status sbyte 1
smallmsg byte "Not enugh element in the stack", 0dh, 0ah, 0
fmsg byte "Stack Full", 0dh, 0ah, 0




.CODE



main PROC

	; The program's starting point.
	; Serves as a break from the main loop that asks for user input.
	Start:
	
		; Prepares registers for calling readstring (see below).
		mov edx, offset choice
		mov ecx, 20
		
		; Zeroes [ebx], which is used to reset value(s) below.
		mov ebx, 0
		
		; Resets <num> and <num_negative>.
		mov num, ebx
		mov num_negative, bl
		
		; Reads input from the user.
		call readstring

		; Zeroes [ecx], since choice-length no longer needs to be stored there.
		mov ecx, 0

		; Copies the length from [al] to <len> for reuse.
		mov len, al
		
		; Assigns a pointer value to [esi].		
		mov esi, offset [choice]
		
		; Moves (with zeroes extended) the value [esi] points to.
		; This value is always written by readstring, even if input is blank.
		movzx eax, byte ptr[esi]
		
		; Jumps to LMainStart.
		jmp LMainStart
	
	
	;Landing pad for any bad data in the program. 
	BadData:
		; Moves (and prints) a prompt, informing the user that their data was invalid.
		mov edx, offset badmsg
		call writestring
		
		; Jumps back to the Start label.
		jmp Start
	
	; Serves as a bridge between Start and Main
	LMainStart:

		; Jumps to Main.
		jmp LMain
	
	
	LMainComp:
		; Compares [cx] to the recorded <len>.
		; if [cx] is larger, then the data entered above was bad.
		cmp cl, len
		jge BadData
		
		; otherwise, increments [c].
		inc cx
		; make CL the same size as esi for this (probably move it to a temp, then copy with zeroes to ecx)
		movzx eax, byte ptr[esi + ecx]
		jmp LMain
	
	; Compares the value stored in [eax] against various datatypes.
	LMain:
	
		; Checks to see if the value stored in [eax] is NULL (end of a string).
		; If it is, program jumps to BadData.
		cmp eax, 0
		je BadData
		
		; Checks to see if the value stored in [eax] is a space.
		; Iterates past that whitespace, if so (jumps to LMainComp).
		cmp eax, ' '
		je LMainComp
		
		; Checks to see if the value stored in [eax] is a space.
		; Iterates past that whitespace, if so (jumps to LMainComp).
		cmp eax, '	'
		je LMainComp

		cmp eax, '-'
		je  DashHandler

		cmp eax, 57
		jge Operators
		
		cmp eax, 48
		jge LDigitsStartPositive
		

		jmp BadData
	
	Operators:

		cmp eax, '+'
		je ad
		
		cmp eax, '*'
		je mu
		
		cmp eax, '/'
		je divi
		
		and al, 11011111b
		
		cmp eax, 'X'
		je ex
		
		cmp eax, 'N'
		je negate
		
		cmp eax, 'V'
		je view

		cmp eax, 'C'
		je clear
	
		cmp eax, 'Q'
		je quit

		cmp eax, 'U'
		je up

		cmp eax, 'D'
		je down
		
		jmp BadData
		
		
	
	LDigitsStartPositive:
		mov exp_len, cl
		jmp LDigits

	LDigitsStartNegative:
		mov exp_len, cl
		
		mov cl, num_negative
		inc cl
		mov num_negative, cl
		
		mov cl, exp_len
		
		jmp LDigits
	
	LDigitsComp:
		cmp cl, len
		jge LDigitsDone
		
		inc cx
		movzx eax, byte ptr[esi + ecx]

		cmp eax, 57
		jge LDigitsDone
		cmp eax, 48
		jle LDigitsDone
		
		jmp LDigits
		
	
	LDigits:
		; Transforms al into a decimal value.
		and al, 00001111b
		
		cmp cl, exp_len
		je LDigitsLower
		imul ebx, ebx, 10
		LDigitsLower:
			add ebx, eax
			jmp LDigitsComp
	
	LDigitsDone:
		cmp num_negative, 0
		je LDigitsDoneLower
		neg ebx
		LDigitsDoneLower:
			push ebx
			jmp Done
	
	
	DashHandler:
		cmp cl, len
		jge su
		
		inc cx
		movzx eax, byte ptr[esi + ecx]
		
		cmp eax, 57
		jge su
		cmp eax, 48
		jge LDigitsStartNegative
		jmp su
		
	ad:
		movzx ecx, count
		;//Add procedure
		cmp ecx,1
		je toosmall
		call addtoptwo
		push eax
		jmp done


	mu:
		movzx ecx, count
		;//Multiply procedure
		movzx ecx, count
		cmp ecx, 1
		jbe toosmall
		call multoptwo
		push eax
		jmp done


	divi:
		movzx ecx, count
		;//Divide procedure
		movzx ecx, count
		cmp ecx, 1
		jbe toosmall
		call divtoptwo
		push eax
		jmp done


	ex:
		movzx ecx, count
		;//The rest of the procedures do not take an element off the stack, therefore we do not need to check the stack size
		mov al, count
		cmp al, 1
		je toosmall
		call xchgtoptwo
		jmp done
		negate:
		call negatetop
		jmp done
		view:
		;//View Procedure
		call viewstack
		jmp start


	clear:
		movzx ecx, count	
		;//Seeing how many elements are on the stack so we can add the apprpiate number to ESP
		call crlf
		movzx ecx, count
		
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
		
		jmp start;//If the stack is empty(count=0)
		;//Jumping to the correct location


	one:
		add esp, 4
		dec count
		jmp start


	two:
		add esp, 8
		sub count, 2
		jmp start


	three:
		add esp, 12
		sub count, 3
		jmp start


	four:
		add esp, 16
		sub count, 4
		jmp start


	five:
		add esp, 20
		sub count, 5
		jmp start


	six:
		add esp, 24
		sub count, 6
		jmp start


	seven:
		add esp, 28
		sub count, 7
		jmp start


	eight:
		add esp, 32
		sub count, 8
		jmp start


	quit:
		;//Quit procedure
		jmp done2


	up:
		;//Up procedure
		call rollupstack
		jmp start


	down:
		;//Down Procedure
		call rolldownstack
		jmp start


	toosmall:
		;//If there are not enugh elements in the stack
		mov edx,offset smallmsg
		call writestring
		jmp start


	;negitive:
		;movzx ecx, count
		;//If its a negitive number
		;mov al, byte ptr[choice + 1]
		;call isdigit
		;jnz su
		;mov esi, offset[choice + 1]
		;movzx ecx, len
		;dec ecx
		;//Converting each byte to a number using our BITWISE operation and
		;//We then negate each bit


	;L1 :
		;and byte ptr[esi], 00001111b
		;neg byte ptr[esi]
		;inc esi
		;loop L1
		
		
		;//Calculating the number(concatinating all the numbers)
		;mov esi, offset[choice + 1]
		;movzx ecx, len
		;call negnumcalc
		;//If the number is within the valid range
		;cmp status, -1
		;je start
		;mov status, 1
		;mov bl,count
		;cmp bl,8
		;jae full
		;mov eax, num
		;push eax
		;inc count
		;jmp start


	su:
		movzx ecx, count
		;//Subtraction procedure
		cmp count,1
		jbe toosmall
		call subtoptwo
		push eax
		jmp done
		
		
		done:
		call crlf
		call writeint
		call crlf
		dec count
		jmp start
	
	done2:;//To exit
		exit
		
main ENDP



;//_______________________________
;//RECIVES: The string offset in ESI and the string length in ECX
;//RETURNES: The number is EAX
;//REQUIRES: A string of type byte
;//_______________________________
negnumcalc PROC

	cmp ecx, 2
	je oneneg

	cmp ecx, 3
	je twoneg

	cmp ecx, 4
	je threeneg

	cmp ecx, 5
	je fourneg

	cmp ecx, 6
	je fiveneg

	cmp ecx, 7
	je sevenneg

	cmp ecx, 8
	je eightneg

	cmp ecx, 9
	je nineneg

	cmp ecx, 10
	je tenneg

	mov status, -1
	mov edx, offset bigmsg
	call writestring
	jmp doneneg


	oneneg :
		movsx eax, byte ptr[esi]
		mov num, eax
		jmp doneneg


	twoneg :
		movsx eax, byte ptr[esi]
		mov ebx, 10
		mul ebx
		movsx ebx, byte ptr[esi + 1]
		add eax, ebx
		mov num, eax
		jmp doneneg


	threeneg :
		movsx eax, byte ptr[esi]
		mov ebx, 100
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		add num, eax
		jmp doneneg


	fourneg :
		movsx eax, byte ptr[esi]
		mov ebx, 1000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		add num, eax
		jmp doneneg


	fiveneg :
		movsx eax, byte ptr[esi]
		mov ebx, 10000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 1000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 4]
		add num, eax
		jmp doneneg


	sevenneg :
		movsx eax, byte ptr[esi]
		mov ebx, 100000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 10000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 1000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 4]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 5]
		add num, eax
		jmp doneneg


	eightneg :
		movsx eax, byte ptr[esi]
		mov ebx, 1000000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 100000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 10000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		mov ebx, 1000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 4]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 5]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 6]
		add num, eax
		jmp doneneg


	nineneg :
		movsx eax, byte ptr[esi]
		mov ebx, 10000000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 1000000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 100000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		mov ebx, 10000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 4]
		mov ebx, 1000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 5]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 6]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 7]
		add num, eax
		jmp doneneg


	tenneg :
		movsx eax, byte ptr[esi]
		mov ebx, 100000000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 10000000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 1000000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		mov ebx, 100000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 4]
		mov ebx, 10000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 5]
		mov ebx, 1000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 6]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 7]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 8]
		add num, eax
		jmp doneneg


	elevenneg :
		movsx eax, byte ptr[esi]
		mov ebx, 1000000000
		mul ebx
		mov num, eax
		movsx eax, byte ptr[esi + 1]
		mov ebx, 100000000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 2]
		mov ebx, 10000000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 3]
		mov ebx, 1000000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 4]
		mov ebx, 100000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 5]
		mov ebx, 10000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 6]
		mov ebx, 1000
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 7]
		mov ebx, 100
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 8]
		mov ebx, 10
		mul ebx
		add num, eax
		movsx eax, byte ptr[esi + 9]
		add num, eax
		jmp doneneg

	doneneg:
		ret
negnumcalc ENDP



;//__________________________
;//RECIVES: 2 elements on the stack.
;//RETURNES: 1 element on the top of the stack.
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
addtoptwo PROC
	mov eax, dword ptr[esp + 4]
	add eax, dword ptr[esp + 8]
	ret 8
addtoptwo ENDP



;//__________________________
;//RECIVES: 2 elements on the stack.
;//RETURNES: 1 element on the top of the stack.
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
subtoptwo PROC
	mov eax, dword ptr[esp + 8]
	sub eax, dword ptr[esp + 4]
	ret 8
subtoptwo ENDP



;//__________________________
;//RECIVES: 2 elements on the stack.
;//RETURNES: 1 element on the top of the stack.
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
multoptwo PROC
	
	mov eax, dword ptr[esp + 4]
	mov ebx, dword ptr[esp + 8]
	cmp eax, 0
	jb negmul
	mul ebx
	jmp done
	
	negmul :
		imul eax, ebx
	
	done :
		ret 8
multoptwo ENDP



;//__________________________
;//RECIVES: 2 elements on the stack.
;//RETURNES: 1 element on the top of the stack.
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
divtoptwo PROC
	mov edx, 0
	mov eax, dword ptr[esp + 8]
	cdq
	mov ebx, dword ptr[esp + 4]
	idiv ebx
	ret 8
divtoptwo ENDP



;//__________________________
;//RECIVES: 2 elements on the stack.
;//RETURNES: 1 element on the top of the stack.
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
xchgtoptwo PROC
	inc count
	mov eax, dword ptr[esp + 4]
	xchg dword ptr[esp + 8], eax
	mov dword ptr[esp + 4], eax
	ret
xchgtoptwo ENDP



;//__________________________
;//RECIVES: 1 element on the stack.
;//RETURNES: The negation of the top element on the stack.
;//REQUIRES: 1+ elemt(s) on the stack.
;//__________________________
negatetop PROC
	inc count
	mov eax, dword ptr[esp + 4]
	neg eax
	mov dword ptr[esp + 4], eax
	ret
negatetop ENDP



;//__________________________
;//RECIVES: 2+ elements on the stack.
;//RETURNES: The stack, where each element is rotated up 1 position(bottom position becomes top position)
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
rollupstack PROC
	movzx ecx, count
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

	done :
		call crlf
		ret
rollupstack ENDP



;//__________________________
;//RECIVES: The stack length in ECX(min size=1, max size=8)
;//RETURNES: Nothing
;//REQUIRES: 1+ elemts on the stack.
;//__________________________
viewstack PROC

	call crlf
	movzx ecx, count
	cmp ecx, 0
	je done
	mov ebx, 4

	L1:
		mov eax, dword ptr[esp + ebx]
		add ebx, 4
		call writeint
		mov al, 9
		call writechar
		loop L1
		call crlf
		
	done :
		ret
viewstack ENDP



;//__________________________
;//RECIVES: 2+ elements on the stack.
;//RETURNES: The stack, where each element is rotated down 1 position(top position becomes bottom position)
;//REQUIRES: 2+ elemts on the stack.
;//__________________________
rolldownstack PROC
	
	movzx ecx, count
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


	done :
		call crlf
		ret
rolldownstack ENDP

END main

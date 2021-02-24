TITLE R.P.N. Calculator                       (G10P2.asm).
COMMENT !                                                
.Created By:                                             
.														                             
.             - Daniel Hentosz (HEN3883@calu.edu)        
.														                             
.             - Scott Trunzo   (TRU1931@calu.edu)        
.														                             
.Last Revised: Feburary 24th, 2021.           (2/24/2021).
.Written for Assembly Language Programming  (CSC-323-R01).





!
.386

.MODEL flat, stdcall

.STACK 4096

ExitProcess PROTO, dwExitCode:DWORD

INCLUDE irvine32.inc



.DATA


;// Template Strings (Pointer represents input line).
;str_line    byte "|----------------------------------------------------------", 0
;str_blank   byte "| ", 0
;str_pointer byte "> ", 0

choice sbyte 20 dup(? )
len byte ?
num sdword ?
bigmsg byte "Enter a number greater than -1,000,000,000", 0dh, 0ah, 0
badmsg byte "Invalid Data", 0dh, 0ah, 0
temp sdword ?
count byte 0
status sbyte 1
smallmsg byte "Not enugh element in the stack", 0dh, 0ah, 0
fmsg byte "Stack Full", 0dh, 0ah, 0




.CODE



main PROC



	;//The main loop
	start:
	
		;// Moves choice to 
		mov edx, offset choice
		mov ecx, 20
		
		;// Reads input from the user.
		call readstring
		
		;// Copies the length from al to <len> for reuse.
		mov len, al
		

		
		;//does the string star with '-'
		cmp byte ptr[choice], '-'
		je negitive
		
		;//We know its a positive number or operation
		mov al, byte ptr[choice]
		
		;//Is it a number
		call isdigit
		jnz op
		
		mov esi, offset[choice]
		movzx ecx, len



	;//Convering each char to a number using out BITWISE operation and
	L2:
		and byte ptr[esi], 00001111b
		inc esi
		loop L2
		mov esi, offset choice
		inc len
		movzx ecx, len
		call negnumcalc
		;//Is the stack full
		mov bl, count
		cmp bl, 8
		jae full
		;//Push the positive number on the stack
		inc count
		push eax
		jmp start


	full:
		;//If the stack is full
		mov edx,offset fmsg
		call writestring
		jmp start


	op:
		;//We know its an operation
		movzx ecx, count
		mov al, byte ptr[choice]
		
		cmp al, '+'
		je ad
		
		cmp al, '*'
		je mu
		
		cmp al, '/'
		je divi
		
		cmp al, 'X'
		je ex
		cmp al, 'x'
		je ex
		
		cmp al, 'N'
		je negate
		cmp al, 'n'
		je negate
		
		cmp al, 'V'
		je view
		cmp al, 'v'
		je view
		
		cmp al, 'C'
		je clear
		cmp al, 'c'
		je clear
		
		cmp al, 'Q'
		je quit
		cmp al, 'q'
		je quit
		
		cmp al, 'U'
		je up
		cmp al, 'u'
		je up
		
		cmp al, 'D'
		je down
		cmp al, 'd'
		je down
		
		;//if it makes it here, its bad data
		mov edx, offset badmsg
		call writestring
		jmp start


	ad:
		;//Add procedure
		cmp ecx,1
		je toosmall
		call addtoptwo
		push eax
		jmp done


	mu:
		;//Multiply procedure
		movzx ecx, count
		cmp ecx, 1
		jbe toosmall
		call multoptwo
		push eax
		jmp done


	divi:
		;//Divide procedure
		movzx ecx, count
		cmp ecx, 1
		jbe toosmall
		call divtoptwo
		push eax
		jmp done


	ex:
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


	negitive:
		;//If its a negitive number
		mov al, byte ptr[choice + 1]
		call isdigit
		jnz su
		mov esi, offset[choice + 1]
		movzx ecx, len
		dec ecx
		;//Converting each byte to a number using our BITWISE operation and
		;//We then negate each bit


	L1 :
		and byte ptr[esi], 00001111b
		neg byte ptr[esi]
		inc esi
		loop L1
		
		
		;//Calculating the number(concatinating all the numbers)
		mov esi, offset[choice + 1]
		movzx ecx, len
		call negnumcalc
		;//If the number is within the valid range
		cmp status, -1
		je start
		mov status, 1
		mov bl,count
		cmp bl,8
		jae full
		mov eax, num
		push eax
		inc count
		jmp start


	su:
		;//Subtraction procedure
		cmp count,1
		jbe toosmall
		call subtoptwo
		push eax
		jmp done
		done : ;//If they did an operation
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

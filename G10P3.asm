;//HentoszP3 || Assembly Language Programming CSC 323
;//Daniel Hentosz, Scott Trunzo || GROUP 10
;//hen3883@calu.edu, tru1931@calu.edu
.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD
INCLUDE irvine32.inc
.data
myptr dword ?
input byte 48 dup(? );//This size wors good beacuse when we reset the buffer, a dword fits in here evenly.
command byte 7 dup(? );//The biggest command size is 6("CHANGE") and we need a null char to end the string
op1 byte 9 dup(? );//Why size 9? Beacuse the Max name legth is 8, and we need a null terminating char.
op2 sbyte -1 ;//Hold the priority the user entered, 0-7.
op3 byte 3 dup('-');//Holds the run_time the user entered, which is a number 1-50.
msg1 byte "COMMAND: ",0
msg2 byte "Operand 1: ",0
msg3 byte "Operand 2: ",0
msg4 byte "Operand 3: ",0
.code
main PROC
start:
mov edx, offset input
mov ecx, lengthof input
call readstring
mov myptr, offset input
;//Putting the correct inforation in each varible.
call getcommand
call getop1
call getop2
call getop3
;//Shows what we have in each var(The Command,and operand 1, 2, and 3)
call showvars
;//Reset our vars so we can loop again:
call clear
jmp start
exit
main ENDP

;//Recives an address in myptr and removes whitespace until a character is hit
rem PROC
mov esi,myptr
L1:
mov al, byte ptr[esi]
inc esi
cmp al, ' '
je L1
cmp al, tab
je L1
dec esi
mov myptr, esi
ret
rem ENDP

skipchar PROC
mov esi,myptr
L1:
mov al,byte ptr [esi]
inc esi
cmp al,' '
je done
cmp al,tab
je done
cmp al,null
je done
jmp L1
done:
mov myptr,esi
ret
skipchar ENDP
;//Stores the command in the var command.
;//If they enter a command greater than 6 character's, the var command is to to null
getcommand PROC
.data
count byte 0
.code
call rem
mov esi,myptr
mov edi,offset command
mov ecx,7
L1:
mov al,byte ptr [esi]
inc esi
cmp al,' '
je done
cmp al,tab
je done
cmp al,null
je done
mov byte ptr [edi],al
inc edi
inc count
loop L1
done:
cmp count,7
jb good
mov edi,offset command
mov dword ptr [edi],null
mov word ptr [edi+4],null
good:
dec esi
;//Updating myptr top point to the next segment of information the user entered:
mov myptr, esi
call skipchar
call rem
ret
getcommand ENDP

;//Stores the first operand in the var op1
;//If they enter a operand greater than 8 character's, the var op1 is to to null
getop1 PROC
mov count,0
mov esi, myptr
mov edi, offset op1
mov ecx, 9
L1:
mov al, byte ptr[esi]
inc esi
cmp al, ' '
je done
cmp al, tab
je done
cmp al, null
je done
mov byte ptr[edi], al
inc edi
inc count
loop L1
done:
cmp count,9
jb good
mov edi, offset op1
mov dword ptr[edi], null
mov dword ptr[edi + 4], null
good:
dec esi
;//Updating myptr top point to the next segment of information the user entered:
mov myptr, esi
call skipchar
call rem
ret
getop1 ENDP

;//Stores the second operand in the var op2
;//If they enter a operand greater than 7 or less than 0, the var op2 is to to -1
getop2 PROC
mov esi,myptr
mov al,byte ptr [esi+1]
cmp al,' '
je good
cmp al,tab
je good
cmp al,null
je good
jmp bad
good:
mov al,byte ptr [esi]
call isdigit
jnz bad
and al,00001111b
cmp al,7
ja bad
cmp al,0
jb bad
cmp al,0
mov op2,al
jmp done
bad:
mov op2,-1
done:
call skipchar
call rem
ret
getop2 ENDP


;//Stores the third operand in the var op3
;//If they enter a operand greater than 50 or less than 1, the var op3 is to to null
getop3 PROC
mov esi, myptr
mov edi,offset op3
mov al, byte ptr[esi + 1]
cmp al, ' '
je good
cmp al, tab
je good
cmp al, null
je good
call isdigit
jz twolen
jmp bad
twolen:
mov al,byte ptr [esi+2]
cmp al,' '
je goodtwolen
cmp al,tab
je goodtwolen
cmp al,null
je goodtwolen
jmp bad
goodtwolen:
mov al, byte ptr[esi]
and al, 00001111b
mov dl, 10
mul dl
mov byte ptr[edi], al
mov al, byte ptr[esi + 1]
and al, 00001111b
add byte ptr[edi], al
;//Checking a valid range 1-50:
mov esi,offset op3 
mov al,byte ptr [esi]
cmp al,50
ja bad
cmp al,1
jb bad
jmp done
good :
mov al, byte ptr[esi]
call isdigit
jnz bad
and al, 00001111b
mov byte ptr [edi],al
jmp done
bad :
mov word ptr [edi],null
done:
ret
getop3 ENDP

;//Resets our varibles so can call the main loop again.
clear PROC
mov edi, myptr
mov dword ptr[edi], null
mov dword ptr[edi + 4], null
mov edi, offset command
mov dword ptr[edi], null
mov word ptr[edi + 4], null
mov byte ptr[edi + 6], null
mov ecx, 12
mov edi, offset input
L1 :
mov dword ptr[edi], null
add edi, 4
loop L1
mov edi, offset op1
mov dword ptr[edi], null
mov dword ptr[edi + 4], null
mov byte ptr[edi + 8], null
mov op2, -1
mov edi, offset op3
mov word ptr[edi], null
mov byte ptr[edi + 2], null
mov count, 0
ret
clear ENDP

;//Good for debuging.
;//Allows us to see what we have in each var.
;//If the user didnt ener anything for a var its set to null.
;//If the user enterd an invalid length its set to null
;//if the user entered an invalid range, its set to 0. Range applies to the priority(0-7) and run_time(1-50)
showvars PROC
mov edx, offset msg1
call writestring
mov edx, offset command
call writestring

call crlf
mov edx, offset msg2
call writestring
mov edx, offset op1
call writestring

call crlf
mov edx, offset msg3
call writestring
movsx eax, op2
call writeint

call crlf
mov edx, offset msg4
call writestring
movzx eax, op3
call writedec
call crlf
ret
showvars ENDP
END main
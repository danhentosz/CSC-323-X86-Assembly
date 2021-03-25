.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD
INCLUDE irvine32.inc
.data
input byte 48 dup(? )
spot dword ?
command byte 8 dup(? )
op1 byte 10 dup(? ) 
op2 sbyte -1
op3 byte ?
;//___________________
msg1 byte "Command: ", 0
msg2 byte "Name: ", 0
msg3 byte "Priority: ", 0
msg4 byte "Run Time: ", 0
.code
main PROC
mov eax,black+(gray*16)
call settextcolor
call clrscr
beginit:
mov edx, offset input
mov ecx, 48
call readstring
mov spot, offset input
call rem
call getcommand
call compare
call crlf
;//_________________________
call initstuff
jmp beginit
exit
main ENDP

rem PROC
mov esi,spot
mov ecx,48
L1:
mov al,byte ptr [esi]
inc esi
cmp al,' '
loope L1
cmp al,tab
loope L1
dec esi
mov spot,esi
ret
rem ENDP

skipchars PROC
mov esi,spot
mov ecx,48
L1:
mov al,byte ptr [esi]
cmp al,' '
je done
cmp al,tab
je done
cmp al,null
je done
inc esi
loop L1
done:
mov spot,esi
ret
skipchars ENDP

getcommand PROC
mov esi,spot
mov edi,offset command
mov ecx,7
L1:
mov al,byte ptr [esi]
cmp al,' '
je done
cmp al,tab
je done
cmp al,null
je done
cld
movsb
loop L1
done:
mov spot,esi
ret
getcommand ENDP

getop1 PROC
mov esi,spot
mov edi,offset op1
mov ecx,9
L1:
mov al,byte ptr [esi]
cmp al,' '
je done
cmp al,tab
je done
cmp al,null
je done
cld
movsb
inc namelen
loop L1
done:
mov spot,esi
ret
getop1 ENDP

getop2 PROC
mov esi,spot
inc esi
mov al,byte ptr [esi]
call isdigit
jz bad
cmp al,' '
je good1
cmp al,tab
je good1
cmp al,null
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
cmp al,7
jg bad
cmp al,0
jl bad
mov op2,al
jmp done
bad:
mov op2,-1
done:
	mov spot,esi
ret
getop2 ENDP

getop3 PROC
mov esi,spot
mov al,byte ptr [esi]
call isdigit
je good1
jmp bad
good1:
mov esi,spot
inc esi
mov al,byte ptr [esi]
call isdigit
jz good2dig
cmp al,' '
je good1dig
cmp al,tab
je good1dig
cmp al,null
je good1dig
jmp bad
good2dig:
mov esi,spot
mov al,byte ptr [esi]
and al,00001111b
mov dl,10
mul dl
mov op3, al
inc esi
mov al,byte ptr [esi]
and al,00001111b
add op3,al
jmp done
good1dig:
mov esi,spot
mov al,byte ptr [esi]
and al,00001111b
mov op3,al
jmp done
bad:
mov op3,null
jmp done2
done:
mov al,op3
cmp al,50
ja bad
cmp al,1
jb bad
done2:
ret
getop3 ENDP

compare PROC
.data
loadstr byte "LOAD", 0
showstr byte "SHOW", 0
runstr byte "RUN", 0
holdstr byte "HOLD", 0
killstr byte "KILL", 0
changestr byte "CHANGE", 0
badstatusmsg byte "The Job Must Be In Hold Mode.", 0dh, 0ah, 0
.code
cld
mov esi, offset loadstr
mov edi, offset command
mov ecx, 5
repe cmpsb
jz load

cld
mov esi, offset showstr
mov edi, offset command
mov ecx, 5
repe cmpsb
jz showjobs

cld
mov esi, offset runstr
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
ret
compare ENDP


change PROC
.data
foundchange byte "Job Priority Changed.",0dh,0ah,0
.code
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
nameprompt :
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
mov byte ptr[esi],al
mov edx,offset foundchange
call writestring
done:
ret
change ENDP
kill PROC
.data
foundkill byte "Job Killed.",0dh,0ah,0
.code
call skipchars
call rem
call getop1

mov al, namelen
cmp al, 0
je nameprompt
cmp al, 9
jae nameprompt
jmp keepgoing
nameprompt :
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
mov esi,jobnamepos
add esi,10
mov al,byte ptr [esi]
cmp al,2
je good
jmp bad
good:
mov edx, offset foundkill
call writestring
;//Call a kill procedure here.
;//We have the starting index of the job to kill
;//in jobnamepos
;//________________SHOULD WORK ONCE I FIX SHOW PROC_____________________
cld
mov edi, jobnamepos
mov esi, offset empty
mov ecx, 14
rep movsb
;//___________________________________________________
jmp done
bad:
mov edx,offset badstatusmsg
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
nameprompt :
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
mov edx, offset foundrun
call writestring
mov edi, jobnamepos
add edi, 10
mov byte ptr[edi], 2
done:
ret
hold ENDP

run PROC
.data
notfoundrun byte "Job doesn't exist.",0dh,0ah,0
foundrun byte "Job Status Updated.",0dh,0ah,0
.code
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
mov al,jobnamenum
cmp al,0
je done
mov edx,offset foundrun
call writestring
mov edi,jobnamepos
add edi,10
mov byte ptr [edi],1
done:
ret
run ENDP

findjob PROC
.data
jobnotfoundmsg byte "Job not found.",0dh,0ah,0
jobnamepos dword ?
jobnamenum byte 9
.code
mov jobnamenum,10
mov jobnamepos,offset jobs
again:
mov al,jobnamenum
cmp al,0
je nope
cld
mov esi,jobnamepos
mov edi,offset op1
mov ecx,2
repe cmpsd
je found
add jobnamepos,14
dec jobnamenum
jmp again
nope:
mov edx,offset jobnotfoundmsg
call writestring
jmp done
found:
done:
ret
findjob ENDP

load PROC
.data
jobs byte 140 dup(?)
jobsfull dword jobsfull
curjob dword jobs
totjobs byte 0
fullmsg byte "Job Record Full",0dh,0ah,0
jobava equ 0
jobrun equ 1
jobhold equ 2
.code
cld
mov esi,curjob
mov edi,jobsfull
mov ecx,2
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
mov al,namelen
cmp al,0
je nameprompt
cmp al,9
jae nameprompt
call dupname
mov al,dupnamecount
cmp al,0
jne done
jmp cont
nameprompt:
mov namelen,0
cld
mov edi,offset op1
mov esi,offset empty
mov ecx,10
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
cont:
mov al,op2
cmp al,8
jae priprompt
jmp cont2 
priprompt:
call getnewpri
mov al,op2
cmp al,7
ja done
cont2:
mov al,op3
cmp al,50
ja runprompt
cmp al,0
jbe runprompt
jmp cont3
runprompt:
call getnewrun
mov al,op3
cmp al,50
ja done
cmp al,0
jbe done
cont3:
inc totjobs
cld
mov esi,offset op1
mov edi,curjob
mov ecx,8
rep movsb
mov edi,curjob
add edi,9
movzx eax,op2
mov byte ptr [edi],al
mov edi,curjob
add edi,10
mov byte ptr [edi],2
mov edi,curjob
add edi,11
movzx eax,op3
mov byte ptr [edi],al
add curjob,14
jmp done
full:
mov edx,offset fullmsg
call writestring
done:
ret
load ENDP

dupname PROC
.data
dupnamecount byte 10
dupnamemsg byte "Job Name Already Exists.",0dh,0ah,0
currentpostemp dword jobs
.code
mov currentpostemp,offset jobs
mov edi,currentpostemp
mov esi,offset op1
mov dupnamecount,10
again:
mov al,dupnamecount
cmp al,0
je done
mov esi, offset op1
cld
mov ecx,2
repe cmpsd
jz bad
add currentpostemp,14
mov edi,currentpostemp
dec dupnamecount
jmp again
bad:
mov edx,offset dupnamemsg
call writestring
done:
ret
dupname ENDP
getnewrun PROC
.data
newrunmsg byte "Enter a Run Time: ", 0
newrunbuf byte 4 dup(? )
.code
mov edx, offset newrunmsg
call writestring
mov edx, offset newrunbuf
mov ecx, 3
call readstring
mov spot, offset newrunbuf
call getop3
ret
getnewrun ENDP

getnewpri PROC
.data
newprimsg byte "Enter a Priority: ", 0
newpribuf byte 3 dup(? )
.code
mov edx, offset newprimsg
call writestring
mov edx, offset newpribuf
mov ecx, 2
call readstring
mov spot, offset newpribuf
call getop2
ret
getnewpri ENDP

getnewname PROC
.data
newnamemsg byte "Enter a job name: ", 0
newnamebuf byte 10 dup(? )
namelen byte 0
.code
mov edx, offset newnamemsg
call writestring
mov edx, offset newnamebuf
mov ecx, 9
call readstring
mov spot, offset newnamebuf
call getop1
ret
getnewname ENDP
showjobs PROC
.data
totaljobs byte 1
tempspot byte 2 dup(? )
showname byte "Name: ", 0
showpri byte "Priority: ", 0
showstat byte "Status: ", 0
showrt byte "Run Time: ", 0
showloadtime byte "Load Time: ", 0dh, 0ah, 0
jobnummsg2 byte "Info:", 0dh, 0ah, 0
jmsg1 byte " ", 0dh, 0ah, 0dh, 0ah, 0
priposition dword ?
.code
mov ecx,10
mov priposition,offset jobs
mov esi,priposition
again:
add esi,10
mov al,byte ptr [esi]
cmp al,null
jne good
add priposition, 14
mov esi, priposition
loop again
jmp done
good:
call printnameneat
mov edx,offset showpri
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
mov edx, offset showloadtime
call writestring
call crlf
add priposition,14
mov esi,priposition
loop again
done:
ret
showjobs ENDP

printnameneat PROC
mov edx,offset showname
call writestring
mov edx, priposition
call writestring
call crlf
ret
printnameneat ENDP
disppri PROC uses esi
mov esi,priposition
mov al,byte ptr [esi+10]
cmp al,2
je theholding
jmp therunning
theholding:
mov edx,offset holdstr
call writestring
call crlf
jmp done
therunning:
mov edx, offset runstr
call writestring
call crlf
done:
ret
disppri ENDP
initstuff PROC
.data
empty byte 48 dup(?)
.code
mov namelen,0
cld
mov edi,offset command
mov esi,offset empty
mov ecx,8
rep movsb

cld
mov edi, offset op1
mov esi, offset empty
mov ecx, 10
rep movsb

mov op2,-1
mov op3,null

cld
mov edi, offset input
mov esi, offset empty
mov ecx,48
rep movsb
ret
initstuff ENDP
END main
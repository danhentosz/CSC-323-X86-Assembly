;//G10P3 || Multitasking Operating System Simulator || Assembly Language Programming CSC 323
;//Daniel Hentosz, Scott Trunzo || GROUP 10
;//hen3883@calu.edu, tru1931@calu.edu
;//Accepts: QUIT HELP LOAD RUN HOLD KILL SHOW STEP CHANGE
;//10 jobs at a time. Each job has: name(up to 8 chars in length and unique), priority, status, run time, start time
;//Each job starats in the HOLD mode, when a job is done, its removed from the queue
;//When a jobs time, status, or priority changes, a message of the jobs name and an explination is printed to the screen with the system time of the event
;//____________________________________________________________
;//Commands:
;//QUIT HELP SHOW
;//RUN jobname HOLD jobname KILL jobname STEP n
;//CHNAGE jobname priority
;//LOAD jobname priority run_time.....LOAD job1 50 (can be 1-50..this really just sets a jobs priority, run time, and places it in the hold mode)
TITLE
.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD
INCLUDE irvine32.inc
.data
stuff byte 50 dup(? )
len byte ?
thing1 dword ? ;//Address of the command
thing2 dword ? ;//Address of operand 1
thing3 dword ? ;//Address of operand 2
thing4 dword ? ;//Address of operand 3
quitc byte "QUIT", 0
helpc byte "HELP", 0
showc byte "SHOW", 0
runc byte "RUN", 0
holdc byte "HOLD", 0
killc byte "KILL", 0
stepc byte "STEP", 0
changec byte "CHANGE", 0
loadc byte "LOAD",0
hmsg byte "Enter a command: QUIT, HELP, SHOW, RUN, HOLD, KILL, STEP, CHNAGE, or LOAD.",0dh,0ah,0
showmsg byte "SHOW!!!!",0dh,0ah,0
runmsg byte "LETS RUN!!!!",0dh,0ah,0
holdmsg byte "AYY, ITS IN THE HOLD PROCEDURE!!",0dh,0ah,0
killmsg byte "Kill!!!",0dh,0ah,0
stepmsg byte "STEPING!!", 0dh, 0ah, 0
changemsg byte "CHANGING", 0dh, 0ah, 0
loadmsg byte "LOADING", 0dh, 0ah, 0
.code
main PROC
start:
mov edx, offset stuff
mov ecx, 50
call readstring
mov esi, offset stuff
call getstuff
mov esi,thing1
mov edi,offset quitc
cmpsd
je quit
mov esi,thing1
mov edi,offset helpc
cmpsd
je helpspot
mov esi, thing1
mov edi, offset showc
cmpsd
je showspot


mov esi, thing1
mov edi, offset runc
cld
mov ecx,3
repe cmpsb
jz runspot


mov esi, thing1
mov edi, offset holdc
cmpsd
je holdspot

mov esi, thing1
mov edi, offset killc
cmpsd
je killspot

mov esi, thing1
mov edi, offset stepc
cmpsd
je stepspot

mov esi, thing1
mov edi, offset changec
cld
mov ecx,3
repe cmpsw
jz changespot


mov esi, thing1
mov edi, offset loadc
cmpsd
je loadspot
jmp start
loadspot:
call load
jmp start
changespot:
call change
jmp start
stepspot:
call step
jmp start
killspot:
call kill
jmp start

holdspot:
call hold
jmp start
runspot:
call run
jmp start

jmp start
showspot:
call showp
jmp start
helpspot:
call help
jmp start
quit:
exit
main ENDP

;//________________________________________________
;//RECIVES: The offset of the string in ESI
;//RETURNES: The correct addresses for thing1, thing2,, thing3, and thing4
;//REQUIRES: Nothing
;//______________________________________________
getstuff PROC
call rem
mov thing1, esi
call skip
call rem
mov thing2, esi
call skip
call rem
mov thing3, esi
call skip
call rem
mov thing4, esi
ret
getstuff ENDP

rem PROC
L1:
mov al,byte ptr [esi]
inc esi
cmp al,' '
loope L1
cmp al,tab
loope L1
dec esi
ret
rem ENDP

skip PROC
L1:
mov al,byte ptr [esi]
inc esi
cmp al,' '
je invalid
cmp al,tab
je invalid
jmp L1
invalid:
dec esi
ret
skip ENDP

help PROC
mov edx,offset hmsg
call writestring
ret
help ENDP

showp PROC
mov edx,offset showmsg
call writestring
ret
showp ENDP

run PROC
mov edx,offset runmsg
call writestring
ret
run ENDP

hold PROC
mov edx,offset holdmsg
call writestring
ret
hold ENDP

kill PROC
mov edx,offset killmsg
call writestring
ret
kill ENDP

step PROC
mov edx,offset stepmsg
call writestring
ret
step ENDP

change PROC
mov edx,offset changemsg
call writestring
ret
change ENDP

load PROC
mov edx,offset loadmsg
call writestring
ret
load ENDP
END main
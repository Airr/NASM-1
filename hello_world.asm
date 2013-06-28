GLOBAL _start

SECTION .data
	msg:	DB "hello world!", 10
	len:	EQU $-msg
SECTION .bss

SECTION .text
	
_start:
	MOV	rax, 1		; sys_write
	MOV	rdi, 1		; stdout
	MOV	rsi, msg	; hallo welt nachricht
	MOV	rdx, len	; laenge der Nachricht

	MOV	rax, 60		; sys_exit
	MOV	rdi, 0		; kein Fehler
	SYSCALL

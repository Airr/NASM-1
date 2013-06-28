; nasm -f elf64 <Datei>
; ld -s -o <gewuenschter Dateiname> <Objectdatei>

SECTION .data

SECTION .bss

SECTION .text
	GLOBAL _start
	
_start:

	MOV	rax, 60	; sys_exit
	MOV	rdi, 0	; kein Fehler
	SYSCALL

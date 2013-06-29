; nasm -f elf64 i<Datei>
; ld -s -o <gewuenschter Dateiname> <Objectdatei>
; rax, rbx, rcx, rdx, rdi, rsi, rbp, rsp, r8 - r15

SECTION .data
	testD:		DB '2345'
	keks:		DB 12
	eol:		DB 10			; 'end of line' Zeichen ist in ASCII mit 10 codiert
SECTION .bss
	testB:		RESB 10			; TestZahl als String
	string:		RESB 10			; Speicher für unsere ASCII Zahl, fuehr jede Stelle der Zahl brauchts ein Byte
SECTION .text
	GLOBAL _start
	
	_start:
		;MOV	rax, 0
		;MOV	al, 49
		;MOV	[testB], al
		;MOV	al, 50
		;;MOV	[testB+1], al
		;MOV	[testB+2], BYTE 51
		;MOV	[testB+3], BYTE 52
		
		; String in Integer casten
		MOV	rax, testD		; Pointer auf String
		MOV	rbx, 4			; laenge des Strings
		CALL	strToInt

		; Integer in String casten
		MOV	rbx, string		; Pointer auf Ziel
		MOV	rcx, 10			; Basis zum Umrechnen 
		CALL	intToStr

		; Ausgabe auf Console
		MOV	rax, 1
		MOV	rdi, 1
		MOV	rsi, string
		MOV	rdx, 10
		SYSCALL
		
		MOV	rax, 1
		MOV	rdi, 1
		MOV 	rsi, eol
		MOV	rdx, 1
		SYSCALL

		; Exit syscall
		MOV	rax, 60	; sys_exit
		MOV	rdi, 0	; kein Fehler
		SYSCALL

; Funktion die den String aus rax in eine Zahl umrechnet
; rax : Pointer auf String
; rbx : Laenge des Strings
; Ergebnis liegt in rax
strToInt:
	; Register sichern
	PUSH	rcx
	PUSH	rdx
	PUSH	rdi
	PUSH	rsi
	PUSH	r8

	MOV	rsi, rax	; rax frei machen
	MOV	rcx, rbx	; Laenge des Strings in Schleifenzaehler laden

	MOV	rax, 0
	MOV	r8, 1		; aktuelle Stelle in unserer Zahl

	_stringLoop:
	MOV	rbx, 0			; es wird nur bl belegt, deswegen muss der Rest von rbx jedes mal freigeräumt werden
	MOV	bl, BYTE [rsi+rcx-1]	; wir nehmen das aktuelle char aus der String (angefangen beim letzten)
	CMP	rbx, 45			; vergeliche ob das Zeichen ein Minuszeichen ist (45 ASCII fuer -)
	JNE	_number			; wenn nicht spring weiter
	NEG	rax			; wenn Minuszeichen dann negiere Ergebnis
	JMP	_end			; und springe ans Ende
	_number:			
	SUB	rbx, 48			; ziehe vom ASCII Wert des chars 48 ab (48 ASCII fuer 0)
	IMUL	rbx, r8			; multipliziere mit dem Zahlwert des Chars mit der aktuellen Stelle (10 hoch x)
	ADD	rax, rbx		; addiere Ergebnis auf unser Ziel register
	IMUL	r8, 10			; multipliziere Wert unserer Stelle mit 10
	LOOP	_stringLoop		; Schleife
	
	_end:				; Label fuer Sprung von Minuszeichen

	; Register reloaden
	POP	r8
	POP	rsi
	POP	rdi
	POP	rdx
	POP	rcx

	RET

; Funktion die die Zahl die in rax steht in ASCII umrechnet
; rax : Zahl zum umrechnen
; rbx : Pointer auf Bytes wo das Ergebnis hingeschrieben wird
; rcx : Basis zum umrechnen (darf nicht 0 sein)
; rdx : sollte frei sein
intToStr:
	; Register sichern
        PUSH    rdx
        PUSH    rdi
        PUSH    rsi
	PUSH	r8
	
	; Sicherheitstest
	CMP	rcx, 0			; vergleiche gegebene Basis mit 0
	JE	_end			; wenn gegebene Basis 0 ist, terminiert die Funktion

	; initialisiere counter
	MOV	rsi, 0			; zaehlt wieviele Stellen die Zahl hat
	MOV	rdi, 0			; Index fuer position im Zeichen Array
	
	; test ob die Zahl negativ ist
	CMP	rax, 0			; vergleiche die Zahl mit 0
	JGE	_numberToZero		; wenn Zahl positiv ist springe ueber Spezialfall hinweg in Hauptroutine
	
	; Spezialfall: Zahl negativ
	MOV	r8, 45			; kann keine Konstante direkt in Speicher schreiben, Umweg ueber Register
	MOV	[rbx], r8		; schreibe 45 (ASCII fuer -) in das erst Byte 
	NEG	rax			; mache die Zahl positiv
	INC	rdi			; incrementiere den Speicherindex

	; Hauptroutine
	; Schleife: teilen die Zahl solange durch gewuenschte Basis bis sie 0 ist, schieben den ganzzahligen Rest auf den Stack
	_numberToZero:
	XOR	rdx, rdx		; rdx muss 0 sein wenn DIV verwendet wird (XOR mit sich selbst ist immer 0)
	DIV	rcx			; rdx:rax / rcx, ganzzahliges Ergebnis in rax, ganzzahliger Rest in rdx
	PUSH	rdx			; schieben den ganzahligen Rest der Division auf den Stack
	INC	rsi			; incrementieren den Schleifencounter (zaehlt wieviele Stellen die Zahl hat)
	CMP	rax, 0			; vergleiche Zahl mit 0
	JG	_numberToZero		; wenn groesser als 0 springe zu '_numberToZero'
	
	; Schleife: Ziehen die Reste nacheinander vom Stack, addiere 48 dazu und schreibe sie in das Zeichen array
	_restoreNumber:			
	POP	r8			; ziehe erste Zahl vom Stack in r8
	ADD	r8, 48			; 0 ist in ASCII 48, alle anderen Ziffern folgen, also auf die berechneten Zahlen 48 addieren
	MOV	[rbx+rdi], r8		; schieben die ASCII Zahl an die rdi'te Stelle im Zeichenarray
	INC	rdi			; incrementieren Index fuer Zeichen Array
	DEC	rsi			; decrementieren den Schleifencounter
	CMP	rsi, 0			; vergleiche Schleifenzaehler mit 0
	JG	_restoreNumber		; wenn groesser als 0 springe zu '_restoreNumber'
	
	_end:
	MOV	rax, rdi
	
	; Register reloaden
	POP	r8
        POP     rsi
        POP     rdi
        POP     rdx

	RET

; Funktion die, die laenge eines Strings (einer Zeichenkette bestimmt)
strLen:
	PUSH	rax
	PUSH	rbx
	PUSH	rcx
	PUSH	rdx
	PUSH	rdi
	PUSH	rsi
	


	POP	rsi
	POP	rdi
	POP	rdx
	POP	rcx
	POP	rbx
	POP	rax

	RET

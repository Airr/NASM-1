; alle Rueckgabewerte der Funktionen sind in rax

SECTION .data
	testD:		DB '2345', 0
	keks:		DB 12
	eol:		DB 10			; 'end of line' Zeichen ist in ASCII mit 10 codiert
SECTION .bss
	testB:		RESB 10			; TestZahl als String
	string:		RESB 10			; Speicher für unsere ASCII Zahl, fuehr jede Stelle der Zahl brauchts ein Byte
SECTION .text
	GLOBAL _start
	
	_start:
		MOV	[testB], BYTE 45
		MOV	[testB+1], BYTE 49
		MOV	[testB+2], BYTE 50
		MOV	[testB+3], BYTE 51
		MOV	[testB+4], BYTE 52
		
		; String in Integer casten
		MOV	rax, testD+4		; Pointer auf String
		MOV	rbx, 1			; laenge des Strings
		CALL	strToInt
		
		MOV	rax, testD
		CALL 	strLen

		; Integer in String casten
		MOV	rbx, string		; Pointer auf Ziel
		MOV	rcx, 10			; Basis zum Umrechnen 
		CALL	intToStr

		; Ausgabe auf Console
		MOV	rax, 1
		MOV	rdi, 1
		MOV	rsi, testD+3
		MOV	rdx, 9
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
	JMP	_endStrToInt		; und springe ans Ende
	_number:			
	SUB	rbx, 48			; ziehe vom ASCII Wert des chars 48 ab (48 ASCII fuer 0)
	IMUL	rbx, r8			; multipliziere mit dem Zahlwert des Chars mit der aktuellen Stelle (10 hoch x)
	ADD	rax, rbx		; addiere Ergebnis auf unser Ziel register
	IMUL	r8, 10			; multipliziere Wert unserer Stelle mit 10
	LOOP	_stringLoop		; Schleife
	
	_endStrToInt:			; Label fuer Sprung von Minuszeichen

	; Register reloaden
	POP	r8
	POP	rsi
	POP	rdi
	POP	rdx
	POP	rcx

	RET

; Funktion die die Zahl die in rax steht in ASCII Zeichen umrechnet
; rax : Zahl zum umrechnen
; rbx : Pointer auf Bytes wo das Ergebnis hingeschrieben wird
; rcx : Basis zum umrechnen (darf nicht 0 sein)
; Rueckgabewert : Pointer auf Ergebnisstring in rax
intToStr:
	; Register sichern
        PUSH    rdx
        PUSH    rdi
        PUSH    rsi
	
	; Sicherheitstest
	CMP	rcx, 0			; vergleiche gegebene Basis mit 0
	JE	_endIntToStr		; wenn gegebene Basis 0 ist, terminiert die Funktion

	; initialisiere counter
	MOV	rdi, rbx		; Zielpointer nach rdi verschieben
	MOV	rbx, rcx		; Umrechenbasis nach rbx verschieben
	MOV	rcx, 0			; zaehlt wieviele Stellen die Zahl hat
	MOV	rsi, 0			; Speicherposition
	
	; test ob die Zahl negativ ist
	CMP	rax, 0			; vergleiche die Zahl mit 0
	JGE	_numberToZero		; wenn Zahl positiv ist springe ueber Spezialfall hinweg in Hauptroutine
	
	; Spezialfall: Zahl negativ
	MOV	[rdi], BYTE 45		; schreibe 45 (ASCII fuer -) in das erst Byte 
	NEG	rax			; mache die Zahl positiv
	INC	rsi			; incrementiere den Speicherindex

	; Hauptroutine
	; Schleife: teilen die Zahl solange durch gewuenschte Basis bis sie 0 ist, schieben den ganzzahligen Rest auf den Stack
	_numberToZero:
	MOV	rdx, 0			; rdx muss 0 sein wenn DIV verwendet wird (XOR mit sich selbst ist immer 0)
	DIV	rbx			; rdx:rax / rcx, ganzzahliges Ergebnis in rax, ganzzahliger Rest in rdx
	PUSH	rdx			; schieben den ganzahligen Rest der Division auf den Stack
	INC	rcx			; incrementieren den Schleifencounter (zaehlt wieviele Stellen die Zahl hat)
	CMP	rax, 0			; vergleiche Zahl mit 0
	JG	_numberToZero		; wenn groesser als 0 springe zu '_numberToZero'
	
	; Schleife: Ziehen die Reste nacheinander vom Stack, addiere 48 dazu und schreibe sie in das Zeichen array
	_restoreNumber:			
	POP	rbx			; ziehe erste Zahl vom Stack in r8
	ADD	rbx, 48			; 0 ist in ASCII 48, alle anderen Ziffern folgen, also auf die berechneten Zahlen 48 addieren
	MOV	[rdi+rsi], rbx		; schieben die ASCII Zahl an die rdi'te Stelle im Zeichenarray
	INC	rsi			; incrementieren Index fuer Zeichen Array
	LOOP	_restoreNumber		; Schleifen ruecksprung 
	
	_endIntToStr:
	MOV	rax, rdi		; Pointer auf Ergebnisstring als Rueckgabewerte
	
	; Register reloaden
        POP     rsi
        POP     rdi
        POP     rdx

	RET

; Funktion die, die laenge eines !!!null-terminierten!!! Strings (einer Zeichenkette) bestimmt
; rax : Pointer auf String
; Rueckgabe : laenge des Strings
strLen:
	PUSH	rbx
	PUSH	rsi
	
	MOV	rbx, 0
	MOV	rsi, rax

	_untilNULL:
	MOV	rax, [rsi+rbx]	
	INC	rbx
	CMP	rax, 0
	JNE	_untilNULL
	
	DEC	rbx
	MOV	rax, rbx

	POP	rsi
	POP	rbx

	RET

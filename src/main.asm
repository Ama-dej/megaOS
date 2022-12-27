.INCLUDE "m328pdef.inc"
.INCLUDE "interrupt.asm"

.CSEG
.EQU CPU_FREQ = 16000000
.EQU BAUD = 9600 
.EQU BPS = (CPU_FREQ / 16 / BAUD) - 1

.EQU RX_BUFFER_SIZE = 2^6 ; More bit potenca dvojke!!!!!
.EQU BUFFER2_SIZE = 2^6

START:
	CLI

	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	CLR R16

	CALL  BUFFER2_SETUP

	LDI R16, LOW(BPS)
	LDI R17, HIGH(BPS)
	STS UBRR0L, R16
	STS UBRR0H, R17

	LDI R16, (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0) | (1 << TXCIE0) | (1 << UDRIE0)
	STS UCSR0B, R16

	CLR R16
	STS TX_BUSY, R16
	STS WRITE_HEAD_L, R16
	STS READ_HEAD_L, R16

	SEI

; Kot primer je tle en napisan echo loop.
LOOP:

	COPY_BUFFER:
	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI R18, BUFFER2_SIZE
	COPY_BUFFER2:
		CALL GETCHAR
		CPI R16, -1 ; TODO CE  ZASTACUICE  ZBRISI R16, -1
		BREQ COPY_BUFFER
		ST X+, R16
		CPI R16, 0x0A
		BRNE NAPREJ
		CALL LOCI_UKAZ
	NAPREJ:
	CALL PUTCHAR
	DEC R18
	BREQ COPY_BUFFER
	RJMP COPY_BUFFER2


	RJMP LOOP

HANG:
	RJMP HANG

; Pošlje znak v registru R16 po UART-u.
;
; R16 -> Znak, ki ga želimo poslati.
PUTCHAR:
	PUSH R17

PUTCHAR_WAIT:
	LDS R17, TX_BUSY
	CPI R17, 0 
	BRNE PUTCHAR_WAIT

	STS UDR0, R16

	LDI R17, 1 
	STS TX_BUSY, R17

	POP R17
	RET

; Dobi znak iz RX buffer-ja in ga da v R16.
; Zadevščina zna vrnit -1, kar pomeni da se write head in read head prekrivata (nimaš več kej za brat).
;
; R16 <- Znak, prebran iz RX buffer-ja. 
GETCHAR:
	PUSH R17
	PUSH XL
	PUSH XH

	LDS XL, READ_HEAD_L
	LDI XH, 0x01 

	LDS R17, WRITE_HEAD_L
	CP XL, R17
	BREQ GETCHAR_OVERLAP

	LD R16, X+
	ANDI XL, RX_BUFFER_SIZE - 1
	STS READ_HEAD_L, XL
	RJMP GETCHAR_OUT

GETCHAR_OVERLAP:
	LDI R16, -1 

GETCHAR_OUT:
	POP XH
	POP XL
	POP R17
	RET	

BUFFER2_SETUP:
	PUSH XL
	PUSH XH
	PUSH R16
	PUSH R17
	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI R17, 0x00
	LDI R16, BUFFER2_SIZE
	BUFFER2_CLEAR:
	ST X+, R17
	DEC R16
	BRNE BUFFER2_SETUP
	POP R17
	POP R16
	POP XH
	POP XL
	RET

; Loci ukaz na parameter in ukaz.
LOCI_UKAZ:
	PUSH XL
	PUSH XH
	PUSH YL
	PUSH YH
	PUSH R17
	PUSH R18

	LDI R18, 6
	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI YL, LOW(UKAZ)
	LDI YH, HIGH(UKAZ)

	LOCI_:
	LD R17, X+
	CPI R17,  0x20
	BREQ NAPREJ2
	ST Y+, R17
	DEC R18 
	BREQ KONEC
	RJMP LOCI_

	NAPREJ2:
	LDI R17, 0x00
	ST Y , R17
	LDI R18, BUFFER2_SIZE - 6
	LDI YL, LOW(PARAMETER)
	LDI YH, HIGH(PARAMETER)

	LOCI_PARAMETER2:
	DEC R18
	BREQ KONEC

	LD R17, X+
	ST Y+, R17

	CPI R17,  0X0A
	BRNE LOCI_PARAMETER2 

	LDI R17, 0x00
	ST Y, R17

	KONEC:
	CALL BUFFER2_SETUP
	POP R18
	POP R17
	POP YH
	POP YL
	POP XH
	POP XL
	RET


.DSEG
.ORG 0x0100
; Pred RX_BUFFER-jem mi ne vrivi nč.
RX_BUFFER: .BYTE RX_BUFFER_SIZE
; Tle naprej se lohk dela nove bufferje.
WRITE_HEAD_L: .BYTE 1
READ_HEAD_L: .BYTE 1
TX_BUSY: .BYTE 1

BUFFER2:	.BYTE BUFFER2_SIZE
PARAMETER:  .BYTE BUFFER2_SIZE - 6
UKAZ: 		.BYTE 6  ; MAKS DOLZINA UKAZA JE 5 KER PAC


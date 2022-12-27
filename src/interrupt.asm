.CSEG
.ORG 0x0000
RESET_INT: JMP START
.ORG 0x0024
RX_COMPLETE_INT: JMP RX_WRITE_TO_BUFFER 
.ORG 0x0028
TX_COMPLETE_INT: JMP TX_COMPLETE 
.ORG 0x0034

RX_WRITE_TO_BUFFER:
	PUSH R16
	IN R16, SREG
	PUSH R16
	PUSH XL
	PUSH XH

	LDS XL, WRITE_HEAD_L
	LDI XH, 0x01 ; Stvar je hardcodana na 256 byte-ni razpon (da ni treba gledat XH).

	LDS R16, UDR0
	ST X+, R16

	ANDI XL, RX_BUFFER_SIZE - 1 ; Če pride na konca XL postavimo na začetek.

	STS WRITE_HEAD_L, XL ; Shranimo pozicijo za pol.

	POP XH
	POP XL
	POP R16
	OUT SREG, R16
	POP R16
	RETI

TX_COMPLETE:
	PUSH R16

	LDI R16, 0
	STS TX_BUSY, R16 ; Samo pove če je UART pripravljen na pošiljanje.

	POP R16
	RETI

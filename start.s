.global _start
_start:
	BL  uart_init
	LDR r0, ='!'
	BL  uart_send
	.halt:
	B   .halt

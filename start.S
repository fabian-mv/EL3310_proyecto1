.global _start
_start:
	BL  rcc_init
	BL  uart_init

	LDR r0, =text
	BL  uart_send_str

	B   halt

.section .rodata
text: .asciz "!\n"

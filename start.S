.global _start
_start:
	BL  rcc_init
	BL  uart_init
	BL  systick_init

	.dbg_loop:
	LDR r0, =text
	BL  uart_send_str
	BL  systick_next
	B   .dbg_loop

.section .rodata
text: .asciz "!\n"

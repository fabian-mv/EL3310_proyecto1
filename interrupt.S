.section .interrupt_vector

stack_init:
	.word _stack_end

reset_handler:
	.word _start + 1

#ifdef QEMU
	# Vector máximo es 0x0000_0130, p. 133 de RM0041
	.fill (0x00000134 - (. - stack_init)) / 4, 4, 0
#else
	# Vector máximo es 0x0000_012C, p. 133 de RM0008
	.fill (0x00000130 - (. - stack_init)) / 4, 4, 0
#endif

.text

.global halt
halt:
	WFI
	B halt

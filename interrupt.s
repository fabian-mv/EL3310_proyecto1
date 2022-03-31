.section .interrupt_vector

stack_init:
	.word _stack_end

reset_handler:
	.word _start + 1

# Vector máximo es 0x0000_0130, p. 133 de RM0041
.fill (0x00000134 - (. - stack_init)), 1, 0

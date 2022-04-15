.section .interrupt_vector

stack_init:
	.word _stack_end

reset_handler:
	.word _start + 1

nmi_handler:
	.word 0

hard_fault_handler:
	.word 0

mem_manage_handler:
	.word 0

bus_fault_handler:
	.word 0

usage_fault_handler:
	.word 0

# Reservado
.word 0
.word 0
.word 0
.word 0

svc_handler:
	.word 0

dbg_monitor_handler:
	.word 0

# Reservado
.word 0

pendsv_handler:
	.word 0

systick_handler:
	.word systick_isr + 1

# EXTI3 en 0x00000064 (tabla 63)
.fill (0x00000064 - (. - stack_init)) / 4, 4, 0

exti3_handler:
	.word gpio_isr + 1

exti4_handler:
	.word gpio_isr + 1

# EXTI9_5 en 0x0000009C (tabla 63 cont.)
.fill (0x0000009c - (. - stack_init)) / 4, 4, 0

exti9_5_handler:
	.word gpio_isr + 1

# USART1 en 0x000000D4 (tabla 63 cont.)
.fill (0x000000d4 - (. - stack_init)) / 4, 4, 0

usart1_handle:
	.word uart_isr + 1

#ifdef QEMU
	# Vector máximo es 0x0000_0130, p. 133 de RM0041
	.fill (0x00000134 - (. - stack_init)) / 4, 4, 0
#else
	# Vector máximo es 0x0000_012C, p. 133 de RM0008
	.fill (0x00000130 - (. - stack_init)) / 4, 4, 0
#endif

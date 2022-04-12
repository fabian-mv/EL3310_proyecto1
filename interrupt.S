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
	#WFI
	B halt

#/ P. 36
.equ USART1, 0x40013800

# P. 640
.equ USART_SR_OFFSET, 0x00
.equ USART_SR_TXE,    1 << 7

# P. 643
.equ USART_DR_OFFSET, 0x04

.global uart_init
uart_init:
	LDR r0, =(USART1 + USART_DR_OFFSET)
	LDR r0, [r0]
	# Preserva bits reservados. Nota: `AND` con inmediato no existe en Thumb
	LDR r1, =0xff
	AND r0, r0, r1
	LDR r1, =usart_dr_mask
	STR r0, [r1]
	BX  lr

.global uart_send
uart_send:
	LDR r1, =~0xff
	AND r0, r0, r1
	LDR r1, =usart_dr_mask
	LDR r1, [r1]
	ORR r0, r0, r1

	LDR r1, =(USART1 + USART_SR_OFFSET)
	LDR r2, =USART_SR_TXE
	.wait_for_txe:
	LDR r3, [r1]
	TST r3, r2
	BEQ .wait_for_txe

	STR r0, [r1, #(USART_DR_OFFSET - USART_SR_OFFSET)]
	BX  lr

.data
usart_dr_mask: .word 0

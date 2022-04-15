# Base en p. 36, lo demás a partir de p. 640
.equ USART1, 0x40013800

.equ USART_SR_OFFSET, 0x00
.equ USART_SR_TXE,    1 << 7

.equ USART_DR_OFFSET,  0x04
.equ USART_BRR_OFFSET, 0x08

.equ USART_CR1_OFFSET, 0x0c
.equ USART_CR1_TE,     1 << 3
.equ USART_CR1_TXEIE,  1 << 7
.equ USART_CR1_UE,     1 << 13

# El registro BRR contiene una escala fraccional de punto fijo llamada USARTDIV,
# documentada en p. 617. USARTDIV ajusta el divisor de reloj aplicado a f_PCLK
# (reloj de APB) antes de sobremuestrar. Esta implementación configura
# USART1 con un factor de sobremuestro de 16, y además f_PCLK es 24MHz según la
# tabla 8 de la datasheet del STM32F100RB (p. 34). Buscamos un baud rate estándar
# de 115200 bauds, así que
# 
#   USARTDIV = 24MHz / (16 * 115200baud) ~ 13.0
# 
# Así que la mantisa es 13 y la fracción es 0/16. La tabla 127 del manual (p.
# 621) verifica este valor.
#
# Nota: Para STM32F103xx (lo que tenemos) USART1 está en APB2 (72MHz, ver rcc.S
# p. 799 de RM0008), por lo que se triplica.
#ifdef QEMU
	.equ USARTDIV, 13 << 4
#else
	.equ USARTDIV, 39 << 4 | 0b0001 << 0
#endif 

.global uart_init
uart_init:
	LDR r0, =USART1
	LDR r1, [r0, #USART_DR_OFFSET]
	# Preserva bits reservados. Nota: `AND` con inmediato no existe en Thumb
	LDR r2, =~0xff
	AND r1, r1, r2
	LDR r2, =usart_dr_mask
	STR r1, [r2]

	LDR r1, =USARTDIV
	STR r1, [r0, #USART_BRR_OFFSET]

	LDR r1, =(USART_CR1_UE | USART_CR1_TE)
	STR r1, [r0, #USART_CR1_OFFSET]
	BX  lr

.global uart_send_str
uart_send_str:
	PUSH {r4, lr}
	MOV  r4, r0

	.send_bytes:
	LDRB r0, [r4]
	CBZ  r0, .send_bytes.end
	BL   uart_send_char
	ADD  r4, r4, #1
	B    .send_bytes
	.send_bytes.end:

	POP  {r4, pc}

.global uart_send_char
uart_send_char:
	PUSH {r4}

	LDR  r1, =0xff
	AND  r0, r0, r1
	LDR  r1, =usart_dr_mask
	LDR  r1, [r1]
	ORR  r0, r0, r1

	LDR r1, =USART1
	LDR r2, =USART_SR_TXE
	LDR r4, =USART_CR1_TXEIE
	# TXE indica que se puede escribir al registro de salida.
	# TXEIE se levanta en caso que TXE no esté levantada, lo
	# cual permite al core suspender (WFI) hasta que el ISR
	# baje TXEIE, punto para el cual TXE debe estar levantada.
	.wait_for_txe:
	LDR r3, [r1, #USART_SR_OFFSET]
	TST r3, r2
	BNE .wait_for_txe.end
	LDR r3, [r1, #USART_CR1_OFFSET]
	ORR r3, r4
	STR r3, [r1, #USART_CR1_OFFSET]
	#WFI
	B   .wait_for_txe
	.wait_for_txe.end:

	STR r0, [r1, #USART_DR_OFFSET]
	POP {r4}
	BX  lr

.global uart_isr
uart_isr:
	# Baja TXEIE (sin esto el ISR entra en bucle por siempre)
	LDR r0, =USART1
	LDR r1, [r0, #USART_CR1_OFFSET]
	LDR r2, =~USART_CR1_TXEIE
	AND r1, r1, r2
	STR r1, [r0, #USART_CR1_OFFSET]
	BX  lr

.data
usart_dr_mask: .word 0

# Mapa de memoria en p. 51 RM0008
.equ AFIO,  0x40010000
.equ EXTI,  0x40010400
.equ GPIOA, 0x40010800
.equ GPIOB, 0x40010c00
.equ GPIOC, 0x40011000

# P. 171
.equ GPIO_CRL_OFFSET,         0x00
.equ GPIO_CRL_CNF_MODE_34567, 0xfff << 12

# P. 172
.equ GPIO_CRH_OFFSET,      0x04
.equ GPIO_CRH_CNF_MODE_9,  0b1111 << 4
.equ GPIO_CRH_CNF_MODE_13, 0b1111 << 20

.equ GPIO_IDR_OFFSET,      0x08
.equ GPIO_IDR_34567_SHIFT, 3

# P. 173
.equ GPIO_ODR_OFFSET, 0x0c

# P. 173
.equ GPIO_BSRR_OFFSET,      0x10
.equ GPIO_BSRR_34567,       0b11111 << 3
.equ GPIO_BSRR_13,          1       << 13
.equ GPIO_BSRR_34567_SHIFT, 3
.equ GPIO_BSRR_BR_SHIFT,    16

# P. 191
.equ AFIO_EXTICR1_OFFSET, 0x08
.equ AFIO_EXTICR2_OFFSET, 0x0C

# P. 211
.equ EXTI_IMR_OFFSET, 0x00
.equ EXTI_IMR_34567,  0b11111 << 3

# P. 212
.equ EXTI_FTSR_OFFSET, 0x0C
.equ EXTI_FTSR_34567,  0b11111 << 3

# P. 213
.equ EXTI_PR_OFFSET, 0x14

# p. 171
# PA9 en push-pull alternate function output.
# PA4-PA7 en push-pull output
# PB3-PB7 en pull-up input
# PC13 en push-pull output
.equ PA9_CNF_MODE,     0b1010  << 4
.equ PA34567_CNF_MODE, 0x22222 << 12
.equ PB34567_CNF_MODE, 0x88888 << 12
.equ PB34567_ODR,      0b11111 << 3
.equ PC13_CNF_MODE,    0b0010  << 20

# Esto pone PB3-PB7 como fuentes de flanco para las interrupciones
# EXTI3 a EXTI7 respectivamente (p. 191).
.equ EXTI3_PB,    0b0001 << 12
.equ EXTI4567_PB, 0x1111

.global gpio_init
gpio_init:
	# PA4-PA7 son salidas de LEDs
	LDR r0, =GPIOA
	LDR r1, [r0, #GPIO_CRL_OFFSET]
	LDR r2, =~GPIO_CRL_CNF_MODE_34567
	AND r1, r1, r2
	LDR r2, =PA34567_CNF_MODE
	ORR r1, r1, r2
	STR r1, [r0, #GPIO_CRL_OFFSET]

	# Apaga los LEDs externos
	LDR r1, =(GPIO_BSRR_34567 << GPIO_BSRR_BR_SHIFT)
	STR r1, [r0, #GPIO_BSRR_OFFSET]

	# Configura PA9 (TX) como alternate output push-pull. PA10 (RX)
	# está bien en la configuración de reset (floating input).
	LDR r1, [r0, #GPIO_CRH_OFFSET]
	LDR r2, =~GPIO_CRH_CNF_MODE_9
	AND r1, r1, r2
	LDR r2, =PA9_CNF_MODE
	ORR r1, r1, r2
	STR r1, [r0, #GPIO_CRH_OFFSET]

	# PB3-PB7 son botones
	LDR r0, =GPIOB
	LDR r1, [r0, #GPIO_CRL_OFFSET]
	LDR r2, =~GPIO_CRL_CNF_MODE_34567
	AND r1, r1, r2
	LDR r2, =PB34567_CNF_MODE
	ORR r1, r1, r2
	STR r1, [r0, #GPIO_CRL_OFFSET]

	# Según tabla 20 (p. 161) hay que poner bits respectivos de GPIOx_ODR
	# en 1 para tener pull-up input
	LDR r1, =#PB34567_ODR
	STR r1, [r0, #GPIO_ODR_OFFSET]

	# PC13 es el LED integrado
	LDR r0, =GPIOC
	LDR r1, [r0, #GPIO_CRH_OFFSET]
	LDR r2, =~GPIO_CRH_CNF_MODE_13
	AND r1, r1, r2
	LDR r2, =PC13_CNF_MODE
	ORR r1, r1, r2
	STR r1, [r0, #GPIO_CRH_OFFSET]

	# Apaga LED integrado (esto se hace poniendo PC13 en 1, no 0)
	LDR r1, =GPIO_BSRR_13
	STR r1, [r0, #GPIO_BSRR_OFFSET]

	# Asocia líneas de interrupción EXTI3-EXTI7 a GPIOB
	LDR r0, =AFIO
	LDR r1, =EXTI3_PB
	STR r1, [r0, #AFIO_EXTICR1_OFFSET]
	LDR r1, =EXTI4567_PB
	STR r1, [r0, #AFIO_EXTICR2_OFFSET]

	# Habilita dichas líneas de interrupción en flanco negativo.
	# Los botones están conectados en configuración pull-down, por
	# lo que al presionarlos ocurre un falling edge.
	LDR r0, =EXTI
	LDR r1, =EXTI_FTSR_34567
	STR r1, [r0, #EXTI_FTSR_OFFSET]
	# EXTI_FTSR_34567 == EXTI_IMR_34567
	STR r1, [r0, #EXTI_IMR_OFFSET]

	BX  lr

.global gpio_set_yellow
gpio_set_yellow:
	LDR r1, =0b1111
	LDR r2, =GPIO_BSRR_13
	TST r0, r1
	# Hay que poner PC13 en 0 para encenderlo, no 1
	BEQ .write_bsrr
	LSL r2, r2, #GPIO_BSRR_BR_SHIFT
	.write_bsrr:
	LDR r0, =GPIOC
	STR r2, [r0, #GPIO_BSRR_OFFSET]
	BX  lr

.global gpio_set_green
gpio_set_green:
	MVN  r1, r0
	UBFX r0, r0, #0, #5
	UBFX r1, r1, #0, #5
	LSL  r0, r0, #GPIO_BSRR_34567_SHIFT
	LSL  r1, r1, #(GPIO_BSRR_34567_SHIFT + GPIO_BSRR_BR_SHIFT)
	ORR  r1, r0, r1
	LDR  r0, =GPIOA
	STR  r1, [r0, #GPIO_BSRR_OFFSET]
	BX   lr

.global gpio_isr
gpio_isr:
	PUSH {r4}

	# Banderas de interrupción levantdas
	LDR  r0, =EXTI
	LDR  r4, [r0, #EXTI_PR_OFFSET]

	LDR  r0, =GPIOB
	LDR  r0, [r0, #GPIO_IDR_OFFSET]
	# Lógica negativa
	MVN  r0, r0
	UBFX r0, r0, #GPIO_IDR_34567_SHIFT, #5

	LDR  r1, =stpl_timers
	.raise_timers:
	UBFX r2, r0, #0, #1
	LDR  r3, [r1]
	ADD  r3, r3, #1
	CMP  r2, r3
	BNE  .raise_timers.continue
	STR  r3, [r1]
	.raise_timers.continue:
	ADD  r1, r1, #4
	LSR  r0, #1
	TST  r0, r0
	BNE .raise_timers

	LDR  r0, =EXTI
	# Un 1 en cada bitfield baja la respectiva línea de interrupción
	STR  r4, [r0, #EXTI_PR_OFFSET]
	POP  {r4}
	BX   lr

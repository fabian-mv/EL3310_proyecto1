# Mapa de memoria en p. 51 RM0008
.equ GPIOA,  0x40010800

# P. 172
.equ GPIO_CRH_OFFSET,     0x04
.equ GPIO_CRH_CNF_MODE_9, 0b1111 << 4

# PA9 en push-pull alternate function output
.equ PA9_CNF_MODE, 0b1010 << 4

.global gpio_init
gpio_init:
	# Configura PA9 (TX) como alternate output push-pull. PA10 (RX)
	# está bien en la configuración de reset (floating input).
	LDR r0, =GPIOA
	LDR r1, [r0, #GPIO_CRH_OFFSET]
	LDR r2, =~GPIO_CRH_CNF_MODE_9
	AND r1, r1, r2
	LDR r2, =PA9_CNF_MODE
	ORR r1, r1, r2
	STR r1, [r0, #GPIO_CRH_OFFSET]

	BX  lr

.global gpio_set_yellow
gpio_set_yellow:
	BX lr

.global gpio_set_green
gpio_set_green:
	BX lr

# Los STM32 involucran cuatro fuentes primarias de reloj:
#
# - HSI (high-speed internal): oscilador RC a 8MHz, incluido dentro del uC.
#   Este reloj es bastante inexacto y no se recomienda para controlar
#   periféricos como UART. La gente de ST hizo un intento para mejorarlo con
#   un registro de calibración cuyo valor se determina después de fabricar cada unidad,
#   pero sigue siendo poco confiable. También puede usarse como fallback de seguridad
#   por si el HSE falla.
#
# - HSE (high-speed external): Aquí se puede conectar un cristal de 4MHz-16MHz.
#   El uC trae el circuito oscilador para controlar el cristal. En la práctica,
#   las tarjetas con uCs STM32 ya traen un cristal de 8MHz aquí. El HSE es una
#   fuente preferible al HSI.
#
# Un circuito adicional y relevante es un PLL que permite escalar hacia arriba
# la frecuencia de el HSE o el HSI, lo cual permite llegar a frecuencias de
# hasta 72MHz sin invertir en cristales más rápidos pero más caros.
#
# Después están los relojes derivados:
#
# - SYSCLK: Reloj del sistema, todos los otros salen de este. Puede ser el HSI,
#   el HSE o el PLL (que puede tener a us vez al HSE o HSI de entrada). Ver
#   campo SW de RCC_CFGR y resto del registro, pp. 101-103 de RM0008.
#
# - HCLK: Reloj del AHB (y por tanto del CPU). Es una división configurable
#   (HPRE) de SYSCLK.
#
# - PCLK2: Reloj de APB2 (rápido). Otra división (PPRE2) de HCLK.
#
# - PCLK1: Reloj de APB1 (lento, PPRE1). No debe exceder 36MHz.
#
# También hay otros como USBCLK, ADCCLK, etc pero los de arriba son los que
# interesan. Utilizamos una configuración típica con SYSCLK = HCLK = PCLK2
# = PLLCLK = 9HSE. Esto se estabiliza a 72MHz con PCLK1 = HCLK/2 = 36MHz.

# Mapa de memoria en p. 50
.equ RCC,   0x40021000
.equ FLASH, 0x40022000

# p. 99
.equ RCC_CR_OFFSET, 0x00
.equ RCC_CR_PLLRDY, 1 << 25
.equ RCC_CR_PLLON,  1 << 24
.equ RCC_CR_HSERDY, 1 << 17
.equ RCC_CR_HSEON,  1 << 16

# p. 101
.equ RCC_CFGR_OFFSET, 0x04
.equ RCC_CFGR_PLLSRC, 1 << 16
.equ RCC_CFGR_SWS,    0b11 << 2

# Multiplicador de PLL de 9 (7 + 2) para pasar de 8MHz a 72MHz (p. 102).
.equ PLLMUL, 0b0111 << 18

# Divisor PCLK1 = HCLK/2 (ya que APB2 no puede exceder 36MHz, p. 103).
.equ PPRE1, 0b100 << 8

# Valores de SWS y SW que establecen al PLL como fuente de SYSCLK
.equ SWS_PLL, 0b10 << 2
.equ SW_PLL,  0b10 << 0

# p. 60
.equ FLASH_ACR_OFFSET, 0x00

# La memoria flash integrada tiene un tiempo de lectura de (24MHz)^-1, por lo
# que el controlador de flash conectado al AHB necesita esperar más de un ciclo
# cuando SYSCLK > 24MHz antes de muestrear los bancos. Si esto no se toma en
# cuenta, se arriesga leer valores incorrectos mientras la palabra leida de flash
# no se ha estabilizado, algo sumamente difícil de depurar si ocurre. "Reading the
# flash memory" en p. 58 describe esta situación y los wait states necesarios:
#
# - 0 wait states, if 0 < SYSCLK <= 24 MHz
# - 1 wait state, if 24 MHz < SYSCLK <= 48 MHz
# - 2 wait states, if 48 MHz < SYSCLK <= 72 MHz
.equ FLASH_WAIT_STATES, 2 << 0

.global rcc_init
rcc_init:
	LDR r0, =FLASH
	LDR r1, =(FLASH_WAIT_STATES)
	STR r1, [r0, #FLASH_ACR_OFFSET]

	# Al arranque, HSI está activo y es SYSCLK. Primero encendemos HSE,
	# pero sin asociarlo a SYSCLK todavía.
	LDR r0, =RCC
	LDR r1, [r0, #RCC_CR_OFFSET]
	LDR r2, =RCC_CR_HSEON
	ORR r1, r1, r2
	STR r1, [r0, #RCC_CR_OFFSET]

	# Esperamos a que la salida de HSE se estabilice
	LDR r2, =RCC_CR_HSERDY
	.hse_not_ready:
	LDR r1, [r0, #RCC_CR_OFFSET]
	TST r1, r2
	BEQ .hse_not_ready

	# Como el HSE ya es utilizable, se puede activar el PLL con HSE de entrada
	LDR r2, =(RCC_CFGR_PLLSRC | PLLMUL)
	STR r2, [r0, #RCC_CFGR_OFFSET]
	LDR r2, =RCC_CR_PLLON
	ORR r1, r1, r2
	STR r1, [r0, #RCC_CR_OFFSET]

	# Estabilización de PLL
	LDR r2, =RCC_CR_PLLRDY
	.pll_not_ready:
	LDR r1, [r0, #RCC_CR_OFFSET]
	TST r1, r2
	BEQ .pll_not_ready

	# Con tanto HSE como PLL estables, se cambia SYSCLK a PLL
	LDR r2, =(RCC_CFGR_PLLSRC | PLLMUL | PPRE1 | SW_PLL)
	STR r2, [r0, #RCC_CFGR_OFFSET]

	# Se espera a que RCC confirme el cambio
	LDR r2, =~RCC_CFGR_SWS
	.sysclk_is_hsi:
	LDR r1, [r0, #RCC_CFGR_OFFSET]
	AND r1, r2
	CMP r1, #SWS_PLL
	BNE .sysclk_is_hsi

	BX  lr

# El reloj de systick es HCLK/8 (9MHz, p. 197). Systick está escrito
# en B3.3 del manual de referencia de ARMv7-m (p. 620).
#
# Las demás números de página referenciados en este archivo corresponden
# a ese manual si no se indica lo contrario.

# p. 621 RM0008
.equ SYST, 0xE000E010

.equ SYST_CSR_OFFSET,  0x00
.equ SYST_CSR_TICKINT, 1 << 1
.equ SYST_CSR_ENABLE,  1 << 0

.equ SYST_RVR_OFFSET, 0x04
.equ SYST_CVR_OFFSET, 0x08

# 1s * 72MHz / 8. El "- 1" se debe a que systick cuenta hasta cero.
.equ ONE_SEC, 9000000 - 1

.global systick_init
systick_init:
	LDR r0, =0
	LDR r1, =systick_last
	STR r0, [r1]
	STR r0, [r1, #(systick_current - systick_last)]

	LDR r0, =SYST
	LDR r1, =ONE_SEC
	STR r1, [r0, #SYST_RVR_OFFSET]
	LDR r1, =0
	STR r1, [r0, #SYST_CVR_OFFSET]
	LDR r1, =(SYST_CSR_TICKINT | SYST_CSR_ENABLE)
	STR r1, [r0, #SYST_CSR_OFFSET]

	BX  lr

.global systick_next
systick_next:
	LDR r0, =1
	# Fall-through: equivale a "B systick_sleep" ya que esa es
	# la función inmediatamente posterior

.global systick_sleep
systick_sleep:
	LDR r1, =systick_last
	LDR r2, [r1]
	ADD r2, r0, r2

	LDR r3, =systick_current
	.sleep:
	LDR r0, [r3]
	CMP r0, r2
	BHS .sleep.end
	WFI
	B   .sleep
	.sleep.end:

    STR r0, [r1]
	BX  lr

.global systick_isr
systick_isr:
	LDR r0, =systick_current
	LDR r1, [r0]
	ADD r1, r1, #1
	STR r1, [r0]
	BX  lr

.data
systick_last:    .word 0
systick_current: .word 0

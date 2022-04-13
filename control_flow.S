.data
stpl_n: 
    .space 1		@ Reserve 1 byte for memory block “stpl_n”
stpl_o:
    .space 1		@ Reserve 1 byte for memory block “stpl_o”
stpl_s:
    .space 1		@ Reserve 1 byte for memory block “stpl_s”
stpl_e:
    .space 1		@ Reserve 1 byte for memory block “stpl_e”
stpl_p:
    .space 1		@ Reserve 1 byte for memory block “stpl_p”

stpl_n_tmr: 
    .space 1		@ Reserve 1 byte for memory block “stpl_n_tmr”
stpl_o_tmr:
    .space 1		@ Reserve 1 byte for memory block “stpl_o_tmr”
stpl_s_tmr:
    .space 1		@ Reserve 1 byte for memory block “stpl_s_tmr”
stpl_e_tmr:
    .space 1		@ Reserve 1 byte for memory block “stpl_e_tmr”
stpl_p_tmr:
    .space 1		@ Reserve 1 byte for memory block “stpl_p_tmr”

car_waiting:
    .space 1        @ Reserve 1 byte for memory block “stpl_p_tmr”
green_tmr:
    .space 1        @ Reserve 1 byte for memory block “green_tmr”

var: .word 20

.global _start
_start:

    LDR r4, =stpl_n_tmr
    LDR r0 , [r4]
    LDR r5, =stpl_o_tmr
    LDR r1 , [r5]
    BL compare_sptl
    MOV r2,r0
    LDR r4, =stpl_s_tmr
    LDR r0 , [r4]
    LDR r5, =stpl_e_tmr
    LDR r1 , [r5]
    BL compare_sptl
    MOV r1,r2
    BL compare_sptl

    #SWI 0

.global compare_sptl
compare_sptl:
    
    CMP r0,r1
    IT lo
    MOVLO r0,r1
    BX lr
    
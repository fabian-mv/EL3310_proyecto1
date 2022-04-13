.data
stpl_n: 
    .space 4		@ Reserve 4 bytes for memory block “stpl”
stpl_n_tmr: 
    .space 4		@ Reserve 4 byte for memory block “stpl_n_tmr”
stpl_o_tmr:
    .space 4		@ Reserve 4 byte for memory block “stpl_o_tmr”
stpl_s_tmr:
    .space 4		@ Reserve 4 byte for memory block “stpl_s_tmr”
stpl_e_tmr:
    .space 4		@ Reserve 4 byte for memory block “stpl_e_tmr”
stpl_p_tmr:
    .space 4		@ Reserve 4 byte for memory block “stpl_p_tmr”

car_waiting:
    .space 4        @ Reserve 4 byte for memory block “stpl_p_tmr”
green_tmr:
    .space 4        @ Reserve 4 byte for memory block “green_tmr”

.equ N_LIGHT, 1<<0
.equ O_LIGHT, 1<<1
.equ S_LIGHT, 1<<2
.equ E_LIGHT, 1<<3
.equ P_LIGHT, 1<<4


set_stpl_green:
    push {lr}
    bl gpio_set_leds
    bl sleep
    pop {pc}


.text
.global stpl_main
stpl_main:

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
    BL set_stpl_green

.global compare_sptl
compare_sptl:
    
    CMP r0,r1
    BLO switch
    B end

    .switch:
    MOV r0,r1

    .end
    BX lr

    


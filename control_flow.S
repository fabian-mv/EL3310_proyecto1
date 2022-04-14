.data
stpl: 
    .space 4		@ Reserve 4 bytes for memory block “stpl”
stpl_last: 
    .space 4		@ Reserve 4 bytes for memory block “stpl_last”

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


.equ N_LIGHT, 1<<0
.equ O_LIGHT, 1<<1
.equ S_LIGHT, 1<<2
.equ E_LIGHT, 1<<3
.equ P_LIGHT, 1<<4

.text
init_timers:
    MOV r0, #5
    LDR r1,=stpl_n_tmr
    STR r0, [r1]
    LDR r1,=stpl_o_tmr
    STR r0, [r1]
    LDR r1,=stpl_s_tmr
    STR r0, [r1]
    LDR r1,=stpl_e_tmr
    STR r0, [r1]
    LDR r1,=stpl_p_tmr
    STR r0, [r1]
    BX lr

increase_timer:

    LDR r1, [r0]
    ADD r1, #1 
    STR r1, [r0]
    BX lr

increase_timers:

    push {r4, lr}


    LDR r4,=stpl_n_tmr

    .loop:
    LDR r1, [r4]
    CMP r1, #0
    BLO .increase
    MOV r0, r4
    BL increase_timer

    .increase: 
    ADD R4, #4
    LDR r0, =stpl_p_tmr
    CMP r4, r0     
    BLS .loop

    pop {r4, pc}

compare_sptl:

    CMP r0, r1
    BLO .switch
    MOV r1, #2 
    BX lr

    .switch:
    MOV r0, r1
    MOV r1, #1
    BX lr

compare_sptl_final:

    CMP r0, r1
    BLO .shift_right
    MOV r2, r3
    BX lr

    .shift_right:
    LSL r2, #2
    BX lr



check_pedestrian:

    LDR r0, =stpl_p_tmr
    LDR r1, [r0]
    CMP r1, #20 
    BHS .set_p_sptl
    BX lr


    .set_p_sptl:
    LDR r0, =stpl
    MOV r1, #P_LIGHT
    STR r1, [r0]
    MOV r1, #0
    LDR r0, =stpl_p_tmr
    STR r1, [r0] 
    BX lr
    

.global _start
_start:

    BL init_timers

    .main_loop:

    BL check_pedestrian 
    LDR r0, =stpl
    LDR r1, [r0]

    CMP r1, #P_LIGHT
    BEQ .skip_compare
    
    # Comparacion N y O 
    LDR r4, =stpl_n_tmr
    LDR r0,  [r4]
    LDR r5, =stpl_o_tmr
    LDR r1, [r5]
    BL compare_sptl
    MOV r6, r1 
    MOV r2, r0

    # Comparacion S y E
    LDR r4, =stpl_s_tmr
    LDR r0, [r4]
    LDR r5, =stpl_e_tmr
    LDR r1, [r5]
    BL compare_sptl 
    MOV r7, r1

    # Ultima comaparacion
    MOV r1, r2
    MOV r2, r6
    MOV r3, r7
    BL compare_sptl_final
    LDR r5, =stpl_last
    LDR r6, =stpl
    STR r6, [r5]
    STR r2, [r6]

    
    @BL reset_timer  #*****

    .skip_compare:

    @BL change_leds  #*****

    BL increase_timers

    LDR r0, =stpl_n_tmr
    LDR r1, [r0]
    LDR r0, =stpl_o_tmr
    LDR r2, [r0]
    LDR r0, =stpl_s_tmr
    LDR r3, [r0]
    LDR r0, =stpl_e_tmr
    LDR r4, [r0]
    LDR r0, =stpl_p_tmr
    LDR r5, [r0]

    B .main_loop




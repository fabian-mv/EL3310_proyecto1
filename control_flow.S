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

.equ E_LIGHT, 1<<0  @ 00001 -> 1
.equ O_LIGHT, 1<<2  @ 00100 -> 4
.equ N_LIGHT, 1<<3  @ 01000 -> 8
.equ S_LIGHT, 1<<1  @ 00010 -> 2
.equ P_LIGHT, 1<<4  @ 10000 -> 16


# NOTAS PARA INTERRUPCIONES:
    # Cuando se toca un boton (cualqueira) este siempre carga 1 en el respectivo stlp_x_tmr
        ## Esto solo ocurre cuando el timer de es igual a 0. Si no, no hace nada. 


.text

init_splts:
    MOV r0, #0
    LDR r1, =stpl
    STR r0, [r1]
    MOV r0, #0
    LDR r1, =stpl_last
    STR r0, [r1]
    BX  lr
    

# Inicia todos los timers con un valor incial de 0
init_timers:

    MOV r0, #39
    LDR r1,=stpl_n_tmr
    STR r0, [r1]
    MOV r0, #38
    LDR r1,=stpl_o_tmr
    STR r0, [r1]
    MOV r0, #37
    LDR r1,=stpl_s_tmr
    STR r0, [r1]
    MOV r0, #36
    LDR r1,=stpl_e_tmr
    STR r0, [r1]
    MOV r0, #20
    LDR r1,=stpl_p_tmr
    STR r0, [r1]
    BX  lr


# Incrementa en 1 el valor de un timer especifico
# Param r0: direccion del timer a incrementar
increase_timer:

    LDR r1, [r0]
    ADD r1, #1
    STR r1, [r0]
    BX  lr

# Manda a incrementar todos los timers diferentes de 0
increase_timers:

    push {r4, lr}

    LDR r4,=stpl_n_tmr
    .loop:
    LDR r1, [r4]
    CMP r1, #0
    BEQ .continue
    MOV r0, r4
    BL  increase_timer

    .continue: 
    ADD r4, #4
    LDR r0, =stpl_p_tmr
    CMP r4, r0     
    BLS .loop

    pop {r4, pc}

# Compara el timer de dos semaforos y retorna aquel cuyo timer sea mayor
# Param r0, r1: timer de un semaforo 
# Return r0: valor de mayor entre r0,r1
compare_sptl:

    CMP r0, r1
    BLO .switch
    MOV r1, #2 
    BX  lr

    .switch:
    MOV r0, r1
    MOV r1, #1
    BX  lr

# Compara el timer de dos semaforos y retorna aquel cuyo timer sea mayor
# Param r0, r1: timer de un semaforo
# Param r2 ,r3: abstraccion de semaforo (comparaciones anteriores)  
# return r2: representacion numero del semaforo  
compare_sptl_final:

    CMP r0, r1
    BLO .shift_right
    BEQ .no_cars
    MOV r2, r3
    BX  lr

    .shift_right:
    LSL r2, #2
    BX  lr

    .no_cars:
    MOV r2, #P_LIGHT
    BX  lr

#
save_last_stpl:

    LDR r0, =stpl
    LDR r1, =stpl_last
    LDR r2, [r0]
    STR r2, [r1]
    BX lr

# Verifica si existe un peaton en alguno de los paso peatonales
check_pedestrian:

    LDR r0, =stpl_p_tmr
    LDR r1, [r0]
    CMP r1, #20 
    LDR r0, =stpl
    BHS .set_p_sptl
    MOV r1, #0
    STR r1, [r0]
    
    BX lr

    .set_p_sptl:
    MOV r1, #P_LIGHT
    STR r1, [r0]
    MOV r1, #0
    LDR r0, =stpl_p_tmr
    STR r1, [r0] 

    BX lr
    
# Rutina que se comunica con el microntrolador para actualizar los LEDS 
# Param: r0: representacion numerica de la luz que va a amarillo
# gpio_set_yellow:
    @Aqui va la magia de Soto


# Rutina que se comunica con el microntrolador para actualizar los LEDS 
# Param: r0: representacion numerica de la luz que va a verde
# gpio_set_green:
    @Aqui va la magia de Soto


# Actualiza los LEDS con la información más reciente de la situación de la via 
change_leds:

    PUSH {lr}

    LDR r1, =stpl
    LDR r0, =stpl_last
    LDR r2, [r1]
    LDR r3, [r0]
    CMP r2, r3
    BNE .gpio_set
    MOV r0, #0
    .gpio_set:
    @BL gpio_set_yellow
    MOV r0, #2
    BL  wait
    LDR r0, =stpl
    @ BL  gpio_set_green
    MOV r0, #3
    BL  wait

    POP {pc}



# Ciclo de espera de la luz en verde. Actualiza los contadores cada 1s
wait:

    PUSH {r4,lr}

    MOV r4, r0 
    
    .sleep:
    @BL  systick_next
    BL  increase_timers
    SUB r4, #1
    CMP r4, #0
    BNE .sleep

    POP {r4, pc}


# Resetea el timer del semaforo cuando se pone en verde 
reset_timers:

    LDR r0, =stpl
    LDR r1, [r0]
    MOV r2, #0

    CMP r1, #N_LIGHT
    BEQ .reset_timer_n
    
    CMP r1, #O_LIGHT
    BEQ .reset_timer_o

    CMP r1, #S_LIGHT
    BEQ .reset_timer_s
    
    CMP r1, #E_LIGHT
    BEQ .reset_timer_e

    .reset_timer_n:
    LDR r1, =stpl_n_tmr
    STR r2, [r1]
    BX lr

    .reset_timer_o:
    LDR r1, =stpl_o_tmr
    STR r2, [r1]
    BX lr

    .reset_timer_s:
    LDR r1, =stpl_s_tmr
    STR r2, [r1]
    BX lr

    .reset_timer_e:
    LDR r1, =stpl_e_tmr
    STR r2, [r1]
    BX lr

# Bucle principal del semaforo 
.global _start
_start:

    BL init_timers
    Bl init_splts

    .main_loop:

    BL save_last_stpl
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

    LDR r6, =stpl
    STR r2, [r6]

    BL reset_timers

    .skip_compare:

    LDR r3, =stpl
    LDR r0, [r3] 
    LDR r3, =stpl_last
    LDR r1, [r3] 

    BL change_leds 


    # Print light timers
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
#include <mips/regdef.h>

    .text                       # Indico al compilador que vienen instrucciones
    .abicalls                   # indico al gcc que uso funciones que soporta la ABI
    .align 2

    .globl matrix_multiply      # indico al compilador que es global
    .ent matrix_multiply        # indico al compilador que es una funcion

matrix_multiply:
    .frame $fp,40, ra
    .set noreorder
    .cpload t9
    .set reorder

    subu sp, sp, 40
    .cprestore 24               # guardo el gp y lo restaura al salir
    sw $fp, 28(sp)              # guardo el fp
    sw ra, 32(sp)               # guardo el ra
    
    move $fp, sp                # seteo fp local
    sw a0, 40($fp)             # guardo 1er argumento en la ABA de la funcion invocante
    sw a1, 44($fp)             # guardo 2do argumento en la ABA de la funcion invocante
    
    move t8, a0               # salvo en t8 puntero a m1
    move t7, a1               # salvo en t7 puntero a m2
    lw a0, 0(t8)              # guardo *m1->rows en a0
    lw a1, 4(t8)              # guardo *m1->cols en a1

    la t9,create_matrix       # guardo memdir de funcion create_matrix en t9
    jal ra,t9                 #invocamos la funcion, en v0 quedara el puntero *m3, que no volveremos a 

    lw t0, 0(t8)             # guardamos *m1->rows en t0 (dimension de la matriz)
    li t1, 0                   # inicializo la variable i del loop externo
    mul t2, t0,t0            # guardo en t2 el valor limite del loop dim*dim
    
loop1:
    bge t1,t2,ret              # salto si i >= a dim*dim
    li.d $f4,0                  # inicializamos el elemento a calcular de la matriz resultado
    li t4, 0                   # inicializo la variable j del loop interno
loop2:
    bge t4,t0,endloop2        # salto si j >= a dim
    
    div t5,t1,t0             # t5 = i/dim
    mult t5,t0               # t5 = (i/dim)*dim             Construccion del indice (i/dim)*dim + j
    add t5,t5,t4             # t5 = (i/dim)*dim + j
    sll t5,t5,3              # Por cada indice del array se guarda un flot (8bytes)
    
    addi t6,t8,8             # cargo en t6 el puntero al array de m1
    lw t6,0(t6)              # cargo la direccion efectiva donde reside el array    
    add t6,t5,t6              # a la direccion del array le sumo la cantidad de palabras hasta el elemento
    l.d $f6,0(t6)             # cargo elemento de la m1 
    
    rem t6,t1,t0             # t6 = i%dim
    mul t5,t4,t0             # t5 = j*dim             Construccion del indice (i%dim) + j*dim
    add t6,t6,t5             # t6 = (i%dim) + j*dim
    sll t6,t6,3              # Por cada indice del array, se guarda un float (8bytes)
        
    addi t3,t7,8            # cargo en t3 el puntero al array de m2    
    lw t3,0(t3)              # carga la direccion efectiva donde reside el array
    add t3,t6,t3             # a la direccoin del array le sumo la cantidad de palabras hasta el elemento
    l.d $f8,0(t3)            # cargo elemento de la m2
    mul.d $f6, $f6,$f8       # multiplico ambos elementos
    add.d $f4,$f4,$f6        # los acumulo en el nuevo elemento de la matriz resultado
    
    sll t3,t1,3              # i*8 = Por cada indice del array se guarda un float (8bytes)
    addi t6,v0,8             # cargo en t6 el puntero al array de m3
    lw t6,0(t6)              # cargo la direccion efectiva donde reside el array
    add t6,t6,t3             # a la direccion del array le sumo la cantidad de palabras hasta el elemento
    s.d $f4,0(t6)            # Insertamos en m3->array[i]
    addi t4,t4,1             # Sumamos 1 a j
    b loop2                  

endloop2:
    addi t1,t1,1            # Se incrementa i
    b loop1
ret:
    lw gp,24(sp)            # restauracion del stack frame
    lw $fp,28(sp)
    lw ra,32(sp)
    addu sp,sp,40
    jr ra
.end matrix_multiply

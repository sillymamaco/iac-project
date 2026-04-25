.text
.globl select

select:
    #verificar se ultrapassa os limites do vetor (...)
    blt a2, a1, exit
    #inicializar o contador
    mv t0, a0
    li t1,0
      
loop:
    beq t1,a1, result
    addi t0, t0, 4
    addi t1, t1, 1
    j loop
    
result:
    lw t2, 0(t0)
    mv a0, t2
    ret
    
exit:
    li a0, 50
    j exit_with_error
    

# You can change these values to test your solution.
.data
ARRAY: .word -6 -1 6 1
SIZE:  .word 4
INDEX: .word 2

.text
main:
  la a1, ARRAY      # a1 = pointer to array
  lw a2, SIZE       # a2 = array length
  lw a3, INDEX      # a3 = element index
  jal ra, select    # call select function
exit:
  li a7, 10         # exit syscall code
  ecall             # terminate the program

# ==========================================================================
# FUNCTION: select
#   This function selects an element from an integer array.
# Arguments:
#   a1 = pointer to int array
#   a2 = array length
#   a3 = element index
# Returns:
#   a0 = status code
#   a1 = value of the selected element
# ===========================================================================
select:
    #verifica se o indice é valido
    li t0, 0
    blt a3, t0, InvalidIndex
    #verificar se ultrapassa os limites do vetor
    bge a3, a2, OutOfBounds
    #inicializar o contador
    mv t0, a1
    slli t1, a3, 2
    add t0,t0,t1
    lw a1, 0(t0)
    li a0, 0
    j select_end
    
InvalidIndex:
    li a0, 51
    j select_end

OutOfBounds:
    li a0, 100
    j select_end

select_end:
  jr ra               # return to the caller

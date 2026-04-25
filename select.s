.data
# You can change this array to test other values
array: .word -3, 2, -1, 7, -2   # Initial array values				 

.text

main:
  la a0, array      # a0 = pointer to array
  li a1, 5          # a1 = array length
  li a2, 3          # a2 = element index

  jal ra, select      # Call select function

  # Result: a0 contains the value of the selected element

exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program


# ==========================================================================
# FUNCTION: select
#   This function selects an element from an integer array.
# Arguments:
#   a0 = pointer to int array
#   a1 = array length
#   a2 = element index
# Returns:
#   a0 = value of the selected element
# Exceptions:
#   - If invalid access (index out of bounds),
#     this function terminates the program with error code 51
# ===========================================================================
select:
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








loop_end:
  jr ra                  # normal return


# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a7, 93            # Exit system call
  ecall                # Terminate program


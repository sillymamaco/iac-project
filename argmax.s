.data
# You can change this array to test other values
array: .word -3, 2, -1, 7, -2   # Initial array values				 

.text

main:
  la a0, array      # a0 = pointer to array
  li a1, 5          # a1 = number of elements in the array

  jal ra, argmax      # Call argmax function

  # Result: a0 contains the index of the largest element

exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program


# ==========================================================================
# FUNCTION: argmax
#   Takes an array of integers and returns the index of the largest element.
#   If there are multiple elements with the same maximum value, 
#   it should return the smallest index among them.
# Arguments:
#   a0 = pointer to int array
#   a1 = array length
# Returns:
#   a0 = index of the largest element
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 50
# ===========================================================================
argmax:

    blez a1, invalid_length

    lw t0, 0(a0) #current biggest
    li t1, 0 #current max index
    li t2, 1 #current index

    loop_start:
        bge t2, a1, loop_end

        slli t4, t2, 2
        add t4, a0, t4
        lw t3, 0(t4)

        ble t3, t0, skip_update
        add t0, t3, x0
        add t1, t2, x0

    skip_update:
        addi t2, t2, 1
        j loop_start


    invalid_length:
        li a0, 50
        j exit_with_error

    loop_end:
        add a0, t1, x0
        jr ra                  # normal return


# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a7, 93            # Exit system call
  ecall                # Terminate program


# You can change these values to test your solution.
.data
ARRAY: .word -6 -1 6 1
SIZE:  .word 4

.text
main:
  la a1, ARRAY        # a1 = pointer to array
  lw a2, SIZE         # a2 = number of elements in the array
  jal ra, argmax      # call argmax function
exit:
  li a7, 10           # exit syscall code
  ecall               # terminate the program

# ==========================================================================
# FUNCTION: argmax
#   Takes an array of integers and returns the index of the largest element.
#   If there are multiple elements with the same maximum value, 
#   it should return the smallest index among them.
# Arguments:
#   a1 = pointer to int array
#   a2 = array length
# Returns:
#   a0 = status code
#   a1 = index of the largest element
# ===========================================================================
argmax:
  # TODO: Implement the argmax function here
   blez a2, invalid_length

    lw t0, 0(a1) #current biggest
    li t1, 0 #current max index
    li t2, 1 #current index

    loop_start:
        bge t2, a2, loop_end

        slli t4, t2, 2
        add t4, a1, t4
        lw t3, 0(t4)

        ble t3, t0, skip_update
        add t0, t3, x0
        add t1, t2, x0

    skip_update:
        addi t2, t2, 1
        j loop_start
    loop_end:
        mv a1, t1
        li a0, 0
        j argmax_end
    invalid_length:
        li a0, 50
        j argmax_end

              

argmax_end:
    jr ra               # return to the caller



# You can change these values to test your solution.
.data
A:    .word 6, 1, 3, 9, 12, 4, 13, 153
B:    .word 6, 1, 3, 9, 12, 4, 13, 153
SIZE: .word 8

.text
main:
  la a1, A          # a1 = pointer to array A
  la a2, B          # a2 = pointer to array B
  lw a3, SIZE       # a3 = number of elements in each array
  jal ra, dot       # call dot function
exit:
  li a7, 10         # exit syscall code
  ecall             # terminate the program

# ==========================================================================
# FUNCTION: dot
#   This function computes the dot product of two integer arrays.
# Arguments:
#   a1 = pointer to first array
#   a2 = pointer to second array
#   a3 = array length
# Returns:
#   a0 = status code
#   a1 = dot product result
# ===========================================================================
dot:
  	li t0, 1
	blt a3, t0, invalid_length

	li t0, 0 		# accumulator
	li t1, 0 		# index

	loop_start:
		bge t1, a3, dot_end

		slli t2, t1, 2

		# A
		add t3, a1, t2 			# t3 = A[i]'s address
        lw t3, 0(t3) 			# t3 = A[i]'s value
		# B
		add t4, a2, t2 			# t4 = B[i]'s address
        lw t4, 0(t4) 			# t4 = B[i]'s value

		mul t5, t3, t4 			
        mulh t6, t3, t4        # check for overflow (MSB different than expected) 
        srai a4, t5, 31                 
        bne t6, a4, overflow_error 

		add a4, t0, t5 			# adds it to the result
        xor a5, t0, a4          # check for overflow (different sign than expected)
        xor t6, t5, a4
        and a5, a5, t6         
        bltz a5, overflow_error
        
        mv t0, a4

		addi t1, t1, 1 			# increments
		j loop_start			# repeat

    invalid_length: 
		li a0, 50
		li a1, 0
		jr ra


    overflow_error:
        li a0, 200           
        li a1, 0             
        jr ra

dot_end:
	li a0, 0
	mv a1, t0
	jr ra               # return to the caller

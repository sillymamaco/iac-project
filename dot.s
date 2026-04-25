.data
# You can change these arrays to test other values
A: .word -3, 2, -1, 7, -2   # Initial array A values				 
B: .word 6, 1, -1, 3, 2   # Initial array B values

.text

main:
  la a0, A          # a0 = pointer to array A
  la a1, B          # a1 = pointer to array B
  li a2, 5          # a2 = number of elements in each array

  jal ra, dot      # Call dot function

  # Result: a0 contains the dot product of the two integer arrays

exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program


# ==========================================================================
# FUNCTION: dot
#   This function computes the dot product of two integer arrays.
# Arguments:
#   a0 = pointer to first array
#   a1 = pointer to second array
#   a2 = array length
# Returns:
#   a0 = dot product result
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 50
# ===========================================================================
dot:
	li t0, 1
    blt a2, t0, invalid_length
	blez a2, invalid_length

	li t0, 0 		# accumulator
	li t1, 0 		# index

	loop_start:
		bge t1, a2, loop_end

		slli t2, t1, 2

		# A
		add t3, a0, t2 			# t3 = A[i]'s address
        lw t3, 0(t3) 			# t3 = A[i]'s value
		# B
		add t4, a1, t4 			# t4 = A[i]'s address
        lw t4, 0(t4) 			# t4 = A[i]'s value

		mul t5, t3, t4 			# multiplies the values
		add t0, t0, t5 			# adds it to the result

		addi t1, t1, 1 			# increments
		j loop_start			# repeat

    invalid_length: 
		li a0, 50
		j exit_with_error

loop_end:
	mv a0, t0
    jr ra                  # normal return


# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a7, 93            # Exit system call
  ecall                # Terminate program



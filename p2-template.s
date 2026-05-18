###########################################################################
# Upper bound constants for static memory reservation
###########################################################################
.equ CONST_DIMENSION 4
.equ CONST_BUFFER_SIZE 1024
.equ CONST_MAX_VOCAB_TOKENS 100
.equ CONST_MAX_INPUT_TOKENS 10

###########################################################################
# System call constants
###########################################################################
.equ CONST_SYSCALL_PRINT_INT 1
.equ CONST_SYSCALL_PRINT_STRING 4
.equ CONST_SYSCALL_PRINT_CHAR 11
.equ CONST_SYSCALL_EXIT 10
.equ CONST_SYSCALL_EXIT2 93
.equ CONST_SYSCALL_OPEN 1024
.equ CONST_SYSCALL_CLOSE 57
.equ CONST_SYSCALL_READ 63
.equ CONST_SYSCALL_WRITE 64

###########################################################################
# ASCII character constants
###########################################################################
.equ CONST_CHAR_EOF 0
.equ CONST_CHAR_SPACE 32
.equ CONST_CHAR_NEWLINE 10
.equ CONST_CHAR_HYPHEN 45
.equ CONST_CHAR_ZERO 48

.data
###########################################################################
# Data section with static memory reservations.
###########################################################################
VOCABULARY_FILENAME:     .string "/home/sillymamaco/iac-project/vocab.txt"
EMBEDDINGS_FILENAME:     .string "/home/sillymamaco/iac-project/embeddings.txt"
INPUT_FILENAME:          .string "/home/sillymamaco/iac-project/input.txt"

W_Q_FILENAME:            .string "/home/sillymamaco/iac-project/W_Q.txt"
W_K_FILENAME:            .string "/home/sillymamaco/iac-project/W_K.txt"
W_V_FILENAME:            .string "/home/sillymamaco/iac-project/W_V.txt"

VOCAB_BUFFER:            .zero CONST_BUFFER_SIZE                              # Contents of the vocabulary file
INPUT_BUFFER:            .zero CONST_BUFFER_SIZE                              # Contents of the input file
MATRIX_BUFFER:           .zero CONST_BUFFER_SIZE                              # Contents of a matrix file (used for W_Q, W_K, W_V, and embeddings)

INPUT_INDICES_VECTOR:    .zero (CONST_MAX_INPUT_TOKENS * 4)                   # Vector of input token indices (#inputs x 4 bytes)
SCORES_VECTOR:           .zero (CONST_MAX_INPUT_TOKENS * 4)                   # Vector of scores (#tokens x 4 bytes)

INPUT_TOTAL_TOKENS:      .word 0                                              # Number of tokens in the input
VOCAB_TOTAL_TOKENS:      .word 0                                              # Number of tokens in the vocabulary

VOCAB_EMBEDDINGS_MATRIX: .zero (CONST_MAX_VOCAB_TOKENS * CONST_DIMENSION * 4) # Embedding matrix (#tokens x dimension x 4 bytes)
INPUT_EMBEDDINGS_MATRIX: .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # Embedding matrix (#tokens x dimension x 4 bytes)
W_Q_MATRIX:              .zero (CONST_DIMENSION * CONST_DIMENSION * 4)        # W_Q matrix (dimension x dimension x 4 bytes)
W_K_MATRIX:              .zero (CONST_DIMENSION * CONST_DIMENSION * 4)        # W_K matrix (dimension x dimension x 4 bytes)
W_V_MATRIX:              .zero (CONST_DIMENSION * CONST_DIMENSION * 4)        # W_V matrix (dimension x dimension x 4 bytes)
Q_MATRIX:                .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # Q matrix (#tokens x dimension x 4 bytes)
K_MATRIX:                .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # K matrix (#tokens x dimension x 4 bytes)
V_MATRIX:                .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # V matrix (#tokens x dimension x 4 bytes)

.text
main:
    # Read vocabulary
    la a0, VOCABULARY_FILENAME
    la a1, VOCAB_BUFFER 
    li a2, CONST_BUFFER_SIZE
    jal ra, read_file
    
    addi sp, sp, -64
    sw a1, 0(sp)                     # vocabulary buffer

    # Read input
    la a0, INPUT_FILENAME
    la a1, INPUT_BUFFER 
    li a2, CONST_BUFFER_SIZE
    jal ra, read_file
    sw a1, 4(sp)                     # input buffer

    # Read W_Q matrix
    la a0, W_Q_FILENAME
    la a1, MATRIX_BUFFER 
    li a2, CONST_BUFFER_SIZE
    jal ra, read_file
    
    # Parse W_Q matrix
    la a0, W_Q_MATRIX
    jal ra, parse_matrix_buffer
    la t0, W_Q_MATRIX                # Restore base pointer
    sw t0, 8(sp)                     
    sw a1, 12(sp)                    

    # Read W_K matrix
    la a0, W_K_FILENAME
    la a1, MATRIX_BUFFER 
    li a2, CONST_BUFFER_SIZE
    jal ra, read_file
    
    # Parse W_K matrix
    la a0, W_K_MATRIX
    jal ra, parse_matrix_buffer
    la t0, W_K_MATRIX                # Restore base pointer
    sw t0, 16(sp)                    
    sw a1, 20(sp)                    

    # Read W_V matrix
    la a0, W_V_FILENAME
    la a1, MATRIX_BUFFER 
    li a2, CONST_BUFFER_SIZE
    jal ra, read_file
    
    # Parse W_V matrix
    la a0, W_V_MATRIX
    jal ra, parse_matrix_buffer
    la t0, W_V_MATRIX                # Restore base pointer
    sw t0, 24(sp)                    
    sw a1, 28(sp)                    

    # Read embeddings matrix
    la a0, EMBEDDINGS_FILENAME
    la a1, MATRIX_BUFFER 
    li a2, CONST_BUFFER_SIZE
    jal ra, read_file
    
    # Parse vocabulary embeddings matrix
    la a0, VOCAB_EMBEDDINGS_MATRIX
    jal ra, parse_matrix_buffer 
    la t0, VOCAB_EMBEDDINGS_MATRIX   # Restore base pointer
    sw t0, 32(sp)                    
    sw a1, 36(sp)                    

    # Convert input tokens to indices
    la a0, INPUT_INDICES_VECTOR
    lw a2, 4(sp)
    lw a3, 0(sp)
    jal ra, tokens_to_indices
    sw a0, 40(sp)                    # array address
    sw a1, 44(sp)                    # token count

    # Build input embeddings matrix
    la a0, INPUT_EMBEDDINGS_MATRIX
    lw a1, 32(sp)
    lw a2, 40(sp)
    lw a3, 44(sp)
    jal ra, build_input_embeddings_matrix
    sw a0, 48(sp)

    # Build matrix Q
    la a0, Q_MATRIX
    lw a1, 48(sp)                    
    lw a2, 44(sp)                    
    li a3, CONST_DIMENSION
    lw a4, 8(sp)                     
    lw a5, 12(sp)                    
    li a6, CONST_DIMENSION
    jal ra, matrix_multiply
    sw a0, 52(sp)

    # Build matrix K
    la a0, K_MATRIX
    lw a1, 48(sp)                    
    lw a2, 44(sp)                    
    li a3, CONST_DIMENSION
    lw a4, 16(sp)                    
    lw a5, 20(sp)                    
    li a6, CONST_DIMENSION
    jal ra, matrix_multiply
    sw a0, 56(sp)

    # Build matrix V
    la a0, V_MATRIX
    lw a1, 48(sp)                    
    lw a2, 44(sp)                    
    li a3, CONST_DIMENSION
    lw a4, 24(sp)                    
    lw a5, 28(sp)                    
    li a6, CONST_DIMENSION
    jal ra, matrix_multiply
    sw a0, 60(sp)

    # Compute scores for the last input token
    la a0, SCORES_VECTOR
    lw a1, 52(sp)                    
    lw a2, 56(sp)                    
    lw a3, 44(sp)                    
    li a4, CONST_DIMENSION           
    lw t0, 44(sp)                    
    addi t0, t0, -1                  
    mv a5, t0
    jal ra, compute_scores

    # Get the highest score index using argmax
    mv a1, a0
    lw a2, 44(sp)     
    jal ra, argmax

    # Select chosen vector in V using the index from argmax
    mv a4, a1
    lw a1, 60(sp)

    mv a2, s0
    li a3, CONST_DIMENSION
    jal ra, select_vector_in_matrix

    # Pick the next token in the vocabulary with the highest score
    lw a1, 32(sp)                    
    lw a2, 36(sp)
    jal ra, decide_next_token

    # Terminate program successfully
    addi sp, sp, 64
    li a0, 0
    j exit_with_code                 

# Read from a text file into a buffer.
# (in)     a0: filename address (char*)
# (in/out) a1: destination buffer
# (in)     a2: maximum number of bytes to read
read_file:
    mv t1, a1
    mv t2, a2
    li a1, 0
    li a7, CONST_SYSCALL_OPEN
    ecall

    mv t0, a0
    mv a1, t1
    mv a2, t2
    li a7, CONST_SYSCALL_READ
    ecall

    mv t1, a0
    mv a0, t0
    li a7, CONST_SYSCALL_CLOSE
    ecall

    mv a0, t1
    jr ra
    
# Assumes the matrix is stored in the buffer as space-separated integers.
# Assumes columns are separated by 1 space (' '), and rows by 1 newline ('\n').
# Assumes only signed integers are provided.
# (in/out) a0: address of the matrix to fill (int*)
# (out)    a1: number of rows in the matrix (int)
# (in)     a1: address of the buffer containing the matrix data (char*)
parse_matrix_buffer:
    addi sp, sp, -4
    sw s0, 0(sp)

    li t1, 0                                        
    li t2, CONST_CHAR_NEWLINE                       
    li t3, CONST_CHAR_ZERO                          
    li t4, 0x39                                     
    li t5, 0                                        
    li t6, 10
    li s0, 0
    li a2, 0

    loop_parse_matrix_buffer: 
        lbu t0, 0(a1)                               
        beq t0, x0, end_of_buffer

        li t2, CONST_CHAR_HYPHEN                    
        beq t0, t2, negative
        li t2, CONST_CHAR_NEWLINE                     

        bgt t0, t4, not_num
        blt t0, t3, not_num

        mul t1, t1, t6                              
        addi t0, t0, -48                            
        add t1, t1, t0                              
        
        li a2, 1

        addi a1, a1, 1
        j loop_parse_matrix_buffer

    not_num:                                        
        beq a2, x0, check_new_line                      
        beq s0, x0, saves_in_matrix
        neg t1, t1

    saves_in_matrix: 
        sw t1, 0(a0)                                
        addi a0, a0, 4                      
        li t1, 0
        li s0, 0
        li a2, 0

        beq t0, t2, new_line

        check_new_line:
            beq t0, t2, new_line
            addi a1, a1, 1
            j loop_parse_matrix_buffer

    not_in_num:                                     
        addi a1, a1, 1
        j loop_parse_matrix_buffer

    negative:                                       
        li s0, 1
        addi a1, a1, 1
        j loop_parse_matrix_buffer

    new_line:                                       
        addi a1, a1, 1
        addi t5, t5, 1                              
        j loop_parse_matrix_buffer

    end_of_buffer:                                  
        beq a2, x0, the_end
        beq s0, x0, save_last
        neg t1, t1
    
    save_last:                                      
        sw t1, 0(a0)
        addi t5, t5, 1

    the_end:                                        
        mv a1, t5
        lw s0, 0(sp)
        addi sp, sp, 4
        jr ra

# Converts the input tokens into their corresponding indices in the vocabulary.
# (in/out) a0: address of input indices vector to fill (int*)
# (out)    a1: size of input indices vector (number of tokens in input)
# (in)     a2: address to input buffer
# (in)     a3: address to vocabulary buffer
tokens_to_indices:
    addi sp, sp, -32                                
    sw ra, 28(sp)         
    sw s0, 24(sp)         
    sw s1, 20(sp)         
    sw s2, 16(sp)         
    sw s3, 12(sp)         

    mv s0, a0                                       
    li s1, 0                                        
    mv s2, a2                                       
    mv s3, a3                                       

    loop_token_to_indices: 
        lbu t0, 0(s2)                               
        beq t0, x0, end_tokens_function             

        li t1, CONST_CHAR_SPACE 
        beq t0, t1, skip_char                       
        li t1, CONST_CHAR_NEWLINE
        beq t0, t1, skip_char                       
        
        # prepare for jal
        mv a0, s2               
        mv a1, s3
        jal compare_vocab

        # Bounds and Error Checking
        li t6, -1
        beq a0, t6, skip_unknown_token
        
        # Store Index
        slli t4, s1, 2
        add t5, s0, t4
        sw a0, 0(t5)
        addi s1, s1, 1
        
        li t6, CONST_MAX_INPUT_TOKENS
        beq s1, t6, end_tokens_function

    skip_unknown_token:

    advance_to_next_word:
        lbu t0, 0(s2)                               
        beq t0, x0, end_tokens_function             
        li t1, CONST_CHAR_SPACE     
        beq t0, t1, skip_char                       
        li t1, CONST_CHAR_NEWLINE
        beq t0, t1, skip_char                       
        
        addi s2, s2, 1
        j advance_to_next_word

    skip_char: 
        addi s2, s2, 1                              
        j loop_token_to_indices

    end_tokens_function: 
        mv a1, s1
        lw ra, 28(sp)
        lw s0, 24(sp)
        lw s1, 20(sp)
        lw s2, 16(sp)
        lw s3, 12(sp)
        addi sp, sp, 32         
        jr ra 

    compare_vocab:
        mv t1, a1
        li t4, 0

    retry:
        mv t0, a0

    compare_caracters:
        lbu t2, 0(t0)
        lbu t3, 0(t1)

        li t5, CONST_CHAR_SPACE
        beq t2, t5, end_of_token
        li t5, CONST_CHAR_NEWLINE
        beq t2, t5, end_of_token            
        beq t2, x0, end_of_token

        bne t2, t3, failed_token                    

        addi t0, t0, 1
        addi t1, t1, 1
        j compare_caracters

    end_of_token:
        li t5, CONST_CHAR_NEWLINE
        beq t3, t5, found_yey
        beq t3, x0, found_yey

    failed_token:

    next_vocab:
        lbu t3, 0(t1)
        beq t3, x0, end_of_vocab
        addi t1, t1, 1
        li t5, CONST_CHAR_NEWLINE
        bne t3, t5, next_vocab

        addi t4, t4, 1 
        j retry

    found_yey:
        mv a0, t4                                   
        jr ra

    end_of_vocab:
        li a0, -1
        jr ra

# (in/out) a0: address of the output matrix to fill (int*)
# (in)     a1: address of the vocabulary embeddings matrix (int*)
# (in)     a2: address of the input indices array (int*)
# (in)     a3: number of tokens in the input (int)
build_input_embeddings_matrix: 
    li t0, CONST_DIMENSION
    li t6, CONST_DIMENSION
    slli t0, t0, 2

    mv t1, x0
    build_input_embeddings_matrix_ext_loop: beq t1, a3, build_input_embeddings_matrix_ext_loop_end
        lw t2, 0(a2)
        mul t3, t0, t2
        add t3, t3, a1
        mv t4, x0
        build_input_embeddings_matrix_int_loop: beq t4, t6, build_input_embeddings_matrix_end_int_loop
            lw t5, 0(t3)
            sw t5, 0(a0)
            addi t3, t3, 4
            addi a0, a0, 4
            addi t4, t4, 1
            j build_input_embeddings_matrix_int_loop
        build_input_embeddings_matrix_end_int_loop:
            addi a2, a2, 4
            addi t1, t1, 1
            j build_input_embeddings_matrix_ext_loop
    build_input_embeddings_matrix_ext_loop_end: jr ra


# (in/out) a0: address of the output matrix to fill (int*)
# (in)     a1: address of the first matrix (int*)
# (in)     a2: #rows of the first matrix (int)
# (in)     a3: #columns of the first matrix (int)
# (in)     a4: address of the second matrix (int*)
# (in)     a5: #rows of the second matrix (int)
# (in)     a6: #columns of the second matrix (int)
matrix_multiply: 
    addi sp, sp, -16
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    mv s0, x0
    matrix_multiply_ext_loop: beq s0, a2, matrix_multiply_end_ext_loop
        mv s1, x0
        matrix_multiply_mid_loop: beq s1, a6, matrix_multiply_end_mid_loop
            mv s2, x0
            mv s3, x0
            matrix_multiply_int_loop: beq s2, a3, matrix_multiply_end_int_loop
                mul t0, s0, a3 
                add t0, s2, t0
                slli t0, t0, 2
                add t0, t0, a1

                mul t1, s2, a6 
                add t1, t1, s1
                slli t1, t1, 2
                add t1, t1, a4

                lw t2, 0(t0)
                lw t3, 0(t1)
                mul t2, t2, t3 
                add s3, s3, t2

                addi s2, s2, 1
                j matrix_multiply_int_loop
            matrix_multiply_end_int_loop: mul t4, s0, a6
                add t4, t4, s1
                slli t4, t4, 2
                add t4, t4, a0
                sw s3, 0(t4)
                addi s1, s1, 1
                j matrix_multiply_mid_loop
            matrix_multiply_end_mid_loop: addi s0, s0, 1
                j matrix_multiply_ext_loop
    matrix_multiply_end_ext_loop:
        lw s0, 12(sp)
        lw s1, 8(sp)
        lw s2, 4(sp)
        lw s3, 0(sp)
        addi sp, sp, 16
        jr ra

# (in/out) a0: address of the output scores vector to fill (int*)
# (in)     a1: address of Q matrix (int*)
# (in)     a2: address of K matrix (int*)
# (in)     a3: #rows of Q and K (int)
# (in)     a4: #columns of Q and K (int)
# (in)     a5: target token index for which we want to compute the score (int)
compute_scores:
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)

    mv s0, a0
    mv s1, a2
    mv s2, a3
    mv s3, a4
    mv s4, a5
    
    mul t0, s3, s4 
    slli t0, t0, 2
    add  a1, a1, t0
    mv s7, a1
    mv s5, x0
    mv s6, a0
    compute_scores_loop: beq s5, s2, compute_scores_end_loop
        mv a2, s1
        mv a3, s3
        mv a1, s7
        jal dot
        sw a1, 0(s6)
        addi s6, s6, 4
        slli t0, s3, 2
        add s1, s1, t0
        addi s5, s5, 1
        j compute_scores_loop
    compute_scores_end_loop:
        lw ra, 0(sp)
        lw s0, 4(sp) 
        lw s1, 8(sp)
        lw s2, 12(sp)
        lw s3, 16(sp)
        lw s4, 20(sp)
        lw s5, 24(sp)
        lw s6, 28(sp)
        lw s7, 32(sp)
        addi sp, sp, 36
        mv a0, s0
        jr ra

# (out) a0: address of the selected vector (int*)
# (in)  a1: address of matrix (int*)
# (in)  a2: #rows (int)
# (in)  a3: #cols (int)
# (in)  a4: target row
select_vector_in_matrix:
    mul a4, a4, a3
    slli a4, a4, 2
    add a0, a4, a1
    jr ra

# (out) a0: index of the predicted token in the vocabulary (int)
# (in)  a0: address of target vector (int*)
# (in)  a1: vocabulary embeddings address (int*)
# (in)  a2: number of tokens in vocabulary (int)
decide_next_token:   
    addi sp, sp, -28
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)

    mv s0, a0
    mv s1, a1
    mv s2, a2

    li s3, -2147483648
    mv s4, zero
    mv s5, zero

decide_next_token_loop:
    beq s5, s2, decide_next_token_end

    mv a1, s0
    mv a2, s1
    li a3, 4
    jal dot

    bgt a1, s3, decide_next_token_is_bigger
    j decide_next_token_increment

decide_next_token_is_bigger:
    mv s3, a1
    mv s4, s5

decide_next_token_increment:
    addi s1, s1, 16
    addi s5, s5, 1
    j decide_next_token_loop

decide_next_token_end:
    mv a0, s4
    
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    addi sp, sp, 28
    jr ra

# Dot product and argmax helper functions.

# (in)  a1: address of first vector (int*)
# (in)  a2: address of second vector (int*)
# (in)  a3: length of the vectors (int)
# (out) a0: status code (0 for success, non-zero for error)
# (out) a1: dot product result (int)
dot:
    addi sp, sp, -4
    sw ra, 0(sp)                                    
    mv t0, zero                                     
    mv t1, zero                                     
    slti t2, a3, 1                                  
    beq t2, zero, dot_loop                          
    li a0, 50                                       
    j dot_end                                       
dot_loop:
    beq t1, a3, dot_end_loop                        
    lw t2, 0(a1)                                    
    lw t3, 0(a2)                                    
    mul t4, t2, t3                                  
    mulh t5, t2, t3                                 
    srai t6, t4, 31                                 
    bne t5, t6, overflow                            
    mv t6, t0                                       
    add t0, t0, t4                                  
    bgt t6, zero, check_positive_overflow           
    blt t6, zero, check_negative_overflow           
    j dot_continue_loop
check_positive_overflow:
    blt t4, zero, dot_continue_loop                 
    blt t0, zero, overflow                          
    j dot_continue_loop
check_negative_overflow:
    bgt t4, zero, dot_continue_loop                 
    bgt t0, zero, overflow                          
    j dot_continue_loop
dot_continue_loop:
    addi a1, a1, 4                                  
    addi a2, a2, 4                                  
    addi t1, t1, 1                                  
    j dot_loop                                      
dot_end_loop:
    li a0, 0                                        
    mv a1, t0                                       
    j dot_end                                       
overflow:
    li a0, 200                                      
    j dot_end                                       
dot_end:
    lw ra, 0(sp)                                    
    addi sp, sp, 4                                  
    ret                                             

# (in)  a1: pointer to int array
# (in)  a2: array length
# (out) a0: status code
# (out) a1: index of the largest element
argmax:
    addi sp, sp, -4
    sw ra, 0(sp)                                    
    lw t0, 0(a1)                                    
    mv t1, zero                                     
    mv t2, zero                                     
    slti t3, a2, 1                                  
    beq t3, zero, argmax_loop                       
    li a0, 50                                       
    j argmax_end                                    
argmax_loop:
    beq t2, a2, argmax_end_loop                     
    lw t3, 0(a1)                                    
    ble t3, t0, argmax_next                         
    mv t0, t3                                       
    mv t1, t2                                       
argmax_next:
    addi a1, a1, 4                                  
    addi t2, t2, 1                                  
    j argmax_loop                                   
argmax_end_loop:
    mv a1, t1                                       
    li a0, 0                                        
argmax_end:
    lw ra, 0(sp)                                    
    addi sp, sp, 4                                  
    ret                                             

exit_with_code:
    li a7, CONST_SYSCALL_EXIT2
    ecall

# Helper functions for printing and debugging.
.data
PRINT_HEADER_VOCABULARY:    .string "=== Vocabulary ==="
PRINT_HEADER_INPUT:         .string "=== Input ==="
PRINT_HEADER_INPUT_INDICES: .string "=== Input Indices ==="
PRINT_HEADER_MATRIX:        .string "=== Matrix ==="
PRINT_HEADER_SCORES:        .string "=== Scores ==="
PRINT_HEADER_NEXT_TOKEN:    .string "=== Decision ==="
PRINT_VECTOR_LB:            .string "[ "
PRINT_VECTOR_RB:            .string "]"

.text
# Prints a null-terminated string followed by a newline.
# (in) a0: buffer to print (char*)
println:
    li a7, CONST_SYSCALL_PRINT_STRING
    ecall
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    ret

# Prints the vocabulary buffer.
# (in) a0: address of the vocabulary buffer (char*)
print_vocabulary:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la a0, PRINT_HEADER_VOCABULARY
    jal println
    mv a0, s0
    jal println
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

# Prints the input buffer as a string.
# (in) a0: address of the input buffer (char*)
print_input:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la a0, PRINT_HEADER_INPUT
    jal println
    mv a0, s0
    jal println
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

# Prints the input indices vector.
# (in) a0: address of the input indices vector (int*)
# (in) a1: size of the input indices vector (int)
print_indices:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    mv s0, a0
    mv s1, a1
    la a0, PRINT_HEADER_INPUT_INDICES
    jal println
    mv a0, s0
    mv a1, s1
    jal print_vector
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret

print_scores:
    addi sp, sp, -4
    sw ra, 0(sp)
    la a0, PRINT_HEADER_SCORES
    jal println
    la a0, SCORES_VECTOR
    lw a1, INPUT_TOTAL_TOKENS
    jal print_vector
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# a0: address of matrix to print (int*)
# a1: number of rows
# a2: number of columns
print_matrix:
    addi sp, sp, -24
    sw ra, 0(sp)                                    
    sw s0, 4(sp)                                    
    sw s1, 8(sp)                                    
    sw s2, 12(sp)                                   
    sw s3, 16(sp)                                   
    sw s4, 20(sp)                                   
    mv s0, a0                                       
    mv s3, a1                                       
    mv s4, a2                                       
    li s1, 0                                        
    la a0, PRINT_HEADER_MATRIX
    jal println
print_matrix_row_loop:
    beq s1, s3, print_matrix_done
    li s2, 0
print_matrix_col_loop:
    beq s2, s4, print_matrix_next_row
    lw a0, 0(s0)
    li a7, CONST_SYSCALL_PRINT_INT
    ecall
    addi s0, s0, 4
    addi s2, s2, 1
    li a0, CONST_CHAR_SPACE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    j print_matrix_col_loop
print_matrix_next_row:
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    addi s1, s1, 1
    j print_matrix_row_loop
print_matrix_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24
    ret

# a0: address of vector to print (int*)
# a1: number of elements (int)
print_vector:
    addi sp, sp, -8
    sw s0, 0(sp)
    sw s1, 4(sp)
    mv s0, a0                                       
    mv s1, a1                                       
    la a0, PRINT_VECTOR_LB                          
    li a7, CONST_SYSCALL_PRINT_STRING
    ecall
print_vector_loop:
    beq s1, zero, print_vector_done
    lw a0, 0(s0)
    li a7, CONST_SYSCALL_PRINT_INT
    ecall
    li a0, CONST_CHAR_SPACE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    addi s0, s0, 4
    addi s1, s1, -1
    j print_vector_loop
print_vector_done:
    la a0, PRINT_VECTOR_RB                          
    li a7, CONST_SYSCALL_PRINT_STRING
    ecall
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    lw s0, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
    ret

# (in) a0: address of the predicted token (char*)
print_predicted_token:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la a0, PRINT_HEADER_NEXT_TOKEN
    jal println
print_predicted_token_char:
    lb t0, 0(s0)
    beq t0, zero, print_predicted_token_nl          
    li t1, CONST_CHAR_NEWLINE
    beq t0, t1, print_predicted_token_nl            
    mv a0, t0
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    addi s0, s0, 1
    j print_predicted_token_char
print_predicted_token_nl:
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

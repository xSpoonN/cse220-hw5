############## Kevin Tao ##############
############## 170154879 #################
############## ktao ################

############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
.text:
.globl create_term
create_term:                      # a0 = coeff, a1 = exp
	beqz $a0 ctermerror           # Errors if coefficient is 0
	blt $a1 $0 ctermerror         # Errors is exponent is negative
	move $t0 $a0                  # Preserves a0 (used for syscall)
	li $a0 12
	li $v0 9                      # Syscall, allocates 12 bytes of heap memory
	syscall                       # Syscall 9 returns address of allocated heap in v0
	move $a0 $t0                  # Restore a0
	sw $a0 0($v0)                 # Stores coeff into node
	sw $a1 4($v0)                 # Stores exponent in node
	sw $0 8($v0)                  # Zeroes the pointer in node
	jr $ra                        # Address of node is already in v0, so just return at this point

ctermerror:
	li $v0 -1                     # Arguments violated a condition, returns -1 in v0
	jr $ra

.globl create_polynomial
create_polynomial: # a0 = int[] terms
	# Iterate through the entire terms[] up to (0, -1) to get the array length; this makes later procedures less messy.
	# Iterate through terms[], checking if the exponent is already found in the polynomial.
	# If it is, then skip it, otherwise add up all coefficients with that exponent and add it as a new term in the polynomial.
	addi $sp $sp -24           # Allocate stack
	sw $s0 0($sp)              # Preserve s0 on stack
	sw $s1 4($sp)              # Preserve s1 on stack
	sw $s2 8($sp)              # Preserve s2 on stack
	sw $s3 12($sp)             # Preserve s3 on stack
	sw $s4 16($sp)             # Preserve s4 on stack
	sw $s5 20($sp)             # Preserve s5 on stack
	move $s0 $a0               # Moves a0 to s0 to use as counter when iterating through the array.
	li $t0 -1                  # For use of comparison
	li $t1 1                   # For use of comparison
	li $s1 0                   # Zeroes s1
	cploop:                    # Finds length of array.
		lw $t2 0($s0)          # Loads coefficient (Only used to check array termination)
		lw $t3 4($s0)          # Loads exponent
		beq $t2 $0 cpmaybeend  # Branches if coefficient = 0.
		blt $t3 $0 cpnull      # If exponent is less than 0 and it did not branch in the previuos statement ( coeff != 0 ), then it is an invalid term and NULL is returned.
		addi $s0 $s0 8         # Goes to next pair
		addi $s1 $s1 1         # Increments length counter
		j cploop
	cpmaybeend:                # Checks if the exponent is -1, if so, the array is terminated. Otherwise, return to the original loop.
		beq $t3 $t0 cpactuallyend
		j cpnull               # If the term does not also have a -1 exponent, then it is an invalid term and NULL is returned.
	cpactuallyend:             # Array is iterated through, array size is in s1
		beqz $s1 cpnull
		move $s0 $a0               # Moves a0 to s0 to use as counter when iterating through the array.
		li $t6 0               # Previous node (used to update pointers)
		li $s5 0               # Start of polynomial, starts off as 0
		li $s4 0               # Zeroes s4, this is used as a counter for the number of terms in the polynomial.
	cploop2:                   # Iterates through all terms in terms[]
		beqz $s1 cploop2done   # Loop has gone through all terms in the array.
		lw $t2 0($s0)          # Loads coefficient
		lw $t3 4($s0)          # Loads exponent
		addi $s0 $s0 8         # Goes to next pair
		addi $s1 $s1 -1        # Decrements length counter
		move $s2 $a0           # Preserves a0
		move $s3 $ra           # Preserves ra
		move $a0 $s5           # arg0 = polynomial addr
		move $a1 $t3           # arg1 = exponent
		jal findterm           # Checks if this term already exists in the polynomial
		move $ra $s3           # Restores ra
		move $a0 $s2           # Restores a0
		bnez $v0 cploop2       # If the term already exists, then skip and go to the next term
		move $t8 $s0           # Makes note of current location in array
		move $t9 $s1           # Makes note of current pairs remaining in the input
		cploop3: #Otherwise, loop through the entire rest of the array to find any matching exponents. If they match then add it to the coefficient.
			beqz $t9 cploop3end         # The loop has gone through all remaining terms in the input array
			lw $t4 4($t8)      # Loads the exponent
			beq $t4 $t3 cpaddcoeff      # If the exponents match, then add the coeff to the current running sum.
			addi $t8 $t8 8     # Increments inner array pointer
			addi $t9 $t9 -1    # Decrements inner length counter
			j cploop3
			cpaddcoeff:
				lw $t4 0($t8)  # Loads the coefficient
				add $t2 $t2 $t4         # Adds coefficient to running sum
				addi $t8 $t8 8     # Increments inner array pointer
				addi $t9 $t9 -1    # Decrements inner length counter
				j cploop3
		cploop3end:
			move $s2 $a0       # Preserves a0
			move $s3 $ra       # Preserves ra
			move $a0 $t2       # arg0 = coefficient
			move $a1 $t3       # arg1 = exponent
			jal create_term
			move $a0 $s2       # Restores a0
			move $ra $s3       # Restores ra
			bnez $v0 cpsucc
			j cploop2
			cpsucc:
				addi $s4 $s4 1  # Increments num of terms.
				beqz $t6 cpfirstterm
				sw $v0 8($t6)  # Updates the pointer of the previous node to the current node.
				move $t6 $v0    # Sets the previous node (used for future iterations) to the current node
				j cploop2
			cpfirstterm:
				move $s5 $v0    # Sets the start of the polynomial as this is the first term.
				move $t6 $v0    # Sets the previous node (used for future iterations) to the current node
				j cploop2
	cploop2done:
		li $a0 8
		li $v0 9                      # Syscall, allocates 8 bytes of heap memory
		syscall                       # Syscall 9 returns address of allocated heap in v0
		sw $s5 0($v0)                 # Saves start of polynomial into the structure
		sw $s4 4($v0)                 # Saves num of terms into the structure
		lw $s0 0($sp)              # Restores s0 from stack
		lw $s1 4($sp)              # Restores s1 from stack
		lw $s2 8($sp)              # Restores s2 from stack
		lw $s3 12($sp)             # Restores s3 from stack
		lw $s4 16($sp)             # Restores s4 from stack
		lw $s5 20($sp)             # Restores s5 from stack
		addi $sp $sp 24            # Deallocate stack
		jr $ra
	cpnull:
		lw $s0 0($sp)              # Restores s0 from stack
		lw $s1 4($sp)              # Restores s1 from stack
		lw $s2 8($sp)              # Restores s2 from stack
		lw $s3 12($sp)             # Restores s3 from stack
		lw $s4 16($sp)             # Restores s4 from stack
		lw $s5 20($sp)             # Restores s5 from stack
		addi $sp $sp 24            # Deallocate stack
		li $v0 0
		jr $ra

findterm: #a0 = start of polynomial, a1 = exponent to find
	addi $sp $sp -8           # Allocate stack
	sw $s0 0($sp)              # Preserve s0 on stack
	sw $s1 4($sp)              # Preserve s1 on stack
	move $s0 $a0               # Make a copy of polynomial addr
	beqz $a0 ftend             # If the polynomial does not exist, return false
	ftloop:
		beqz $s0 ftend         # If a null pointer is found, then the list is terminated.
		lw $s1 4($s0)          # Loads exponent
		beq $s1 $a1 ftfound    # Branches if the argument matches the term's exponent
		lw $s0 8($s0)          # Loads to next term by loading the pointer into s0
		j ftloop
	ftend:
		li $v0 0               # No addr found.
		lw $s0 0($sp)          # Restores s0 from stack
		lw $s1 4($sp)          # Restores s1 from stack
		addi $sp $sp 8         # Deallocates stack
		jr $ra
	ftfound:
		move $v0 $s0           # Move the addr into return reg
		lw $s0 0($sp)          # Restores s0 from stack
		lw $s1 4($sp)          # Restores s1 from stack
		addi $sp $sp 8         # Deallocates stack
		jr $ra


.globl sort_polynomial
sort_polynomial:







  jr $ra

.globl add_polynomial
add_polynomial:
  jr $ra

.globl mult_polynomial
mult_polynomial:
  jr $ra

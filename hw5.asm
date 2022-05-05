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
		move $s0 $a0           # Moves a0 to s0 to use as counter when iterating through the array.
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
		
		# If the term is cancelled out, then there is no way to check if it already exists. Therefore, it will just add it regardless cause it couldn't find a preexisting occurance.
		# How to fix this: Loop through the previous terms in the input array to see if the exponent existed previously. If it occurred before, that means
		# it must have been cancelled out, and this term is not to be considered.
		move $t5 $a0           # Makes a copy of the terms[] start to use as a counter
		addi $t8 $s0 -8        # Function previously goes to the next pair immediately. This would cause errors so it is adjusted.
		cpcancelled:
			beq $t8 $t5 cpsafe # If the loop has reached the current term and not found any matches, then it is safe to continue.
			lw $t7 4($t5)      # Loads the exponent of the term
			beq $t7 $t3 cploop2         # An exponent of a previous pair has matched the current exponent, therefore it has previously been cancelled out.
			addi $t5 $t5 8     # Goes to check the next pair
			j cpcancelled
			
		cpsafe:
		move $t8 $s0
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
				addi $t8 $t8 8          # Increments inner array pointer
				addi $t9 $t9 -1         # Decrements inner length counter
				j cploop3
		cploop3end:
			move $s2 $a0       # Preserves a0
			move $s3 $ra       # Preserves ra
			move $a0 $t2       # arg0 = coefficient
			move $a1 $t3       # arg1 = exponent
			jal create_term
			move $a0 $s2       # Restores a0
			move $ra $s3       # Restores ra
			bgtz $v0 cpsucc
			j cploop2
			cpsucc:
				addi $s4 $s4 1  # Increments num of terms.
				beqz $t6 cpfirstterm
				sw $v0 8($t6)   # Updates the pointer of the previous node to the current node.
				move $t6 $v0    # Sets the previous node (used for future iterations) to the current node
				j cploop2
			cpfirstterm:
				move $s5 $v0    # Sets the start of the polynomial as this is the first term.
				move $t6 $v0    # Sets the previous node (used for future iterations) to the current node
				j cploop2
	cploop2done:
		li $a0 8
		li $v0 9                   # Syscall, allocates 8 bytes of heap memory
		syscall                    # Syscall 9 returns address of allocated heap in v0
		sw $s5 0($v0)              # Saves start of polynomial into the structure
		sw $s4 4($v0)              # Saves num of terms into the structure
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
	addi $sp $sp -8            # Allocate stack
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
sort_polynomial: # a0 = polynomial addr
	# Bubble sort. Keep looping through the list until nothing is changed. (use a flag) Exchange terms by copying the values and swapping them. The pointer is not touched.
	li $t5 1                   # t5 = flag for how many swaps are performed. This flag is reset every pass and the loop ends when this flag is 0 at the end of the loop.
	lw $a0 0($a0)              # Loads the addr for the start of the polynomial
	beqz $a0 spend             # If the polynomial is null, do nothing.
	move $t8 $a0               # Make a copy of a0 to use for iteration
	spmain:
		beqz $t5 spend         # If no swaps are performed, then exit the loop
		move $t8 $a0           # Resets polynomial base pointer
		li $t5 0               # Resets swap counter
		spsub:
			lw $t9 8($t8)      # Loads the pointer field of the node
			beqz $t9 spmain    # If no pointer exists, then this is the final node of the polynomial
			lw $t3 4($t8)      # Loads exponent of the current node
			lw $t4 4($t9)      # Loads exponent of next node.
			blt $t3 $t4 spswap # If this node's exponent is less than the next's, perform a swap
			spback:
			move $t8 $t9       # Moves to next node in linked list
			j spsub
			spswap:
				lw $t0 0($t8)  # Loads coefficent of current node
				lw $t1 0($t9)  # Loads coefficent of next node
				sw $t1 0($t8)  # Saves next coefficent as this coefficent
				sw $t0 0($t9)  # Saves this coefficent as next coefficent
				sw $t4 4($t8)  # Saves next exponent as this exponent
				sw $t3 4($t9)  # Saves this exponent as next exponent
				addi $t5 $t5 1 # Increments swap counter
				j spback
	spend:
  		jr $ra

.globl add_polynomial
add_polynomial:  #a0 = polynomial 1, a1 = polynomial 2
	# Write both polynomials to the stack, with a (0, -1) term at the end. Call create_polynomial on the stack. Then call sort_polynomial to sort it.
	addi $sp $sp -12           # Allocate stack
	sw $s0 0($sp)              # Preserve s0 on stack
	sw $s1 4($sp)              # Preserve s1 on stack
	sw $s2 8($sp)              # Preserve s2 on stack
	beqz $a0 apnullcheck1      # arg0 is 0
	beqz $a1 apnullcheck2      # arg1 is 0
	j apnullpass
	apnullcheck1:
		beqz $a1 apbothnull
		move $a0 $a1                  # arg1 = polynomial
		move $s0 $ra                  # Preserves ra
		jal sort_polynomial
		move $ra $s0                  # Restores ra
		move $v0 $a1                  # Return second polynomial if the second is not null
		jr $ra
	apnullcheck2:
		move $s0 $ra                  # Preserves ra
		move $s1 $a0                  # Preserves a0
		jal sort_polynomial
		move $ra $s0                  # Restores ra
		move $v0 $s1                  # Return first polynomial, since at this point the first polynomial is known to be not null
		jr $ra
	apbothnull:
		li $a0 8
		li $v0 9                      # Syscall, allocates 8 bytes of heap memory
		syscall                       # Syscall 9 returns address of allocated heap in v0
		sw $0 0($v0)                  # Sets head pointer to null
		sw $0 4($v0)                  # Sets num of terms to null
		jr $ra
	apnullpass:
	li $s0 0                   # Zeroes s0. It is used as a counter for the amount of memory allocated in the stack.
	addi $sp $sp -8            # Allocate another 8 bytes for the terminating term
	addi $s0 $s0 8             # Increments memory used by 8 bytes
	sw $0 0($sp)               # Stores 0
	li $t0 -1
	sw $t0 4($sp)              # Stores -1
	move $s1 $a0               # Makes a copy of a0 to use as an address pointer counter
	lw $s1 0($s1)              # Loads the actual start of polynomial
	apstorefirst:
		addi $sp $sp -8        # Allocates 8 bytes to stack
		addi $s0 $s0 8         # Increments stack memory used counter
		lw $t1 0($s1)          # Loads first field of the node (Coefficient)
		lw $t2 4($s1)          # Loads second field of the node (Exponent)
		sw $t1 0($sp)          # Saves it to stack
		sw $t2 4($sp)          # Saves it to stack
		lw $t0 8($s1)          # Loads third field of the node, which is the pointer
		beqz $t0 apfirstdone   # If no pointer is given, then the polynomial is complete.
		move $s1 $t0           # Goes to next node in polynomial otherwise
		j apstorefirst
	apfirstdone:
	move $s1 $a1               # Makes a copy of a1 to use as an address pointer counter
	lw $s1 0($s1)              # Loads the actual start of polynomial
	apstoresecond:
		addi $sp $sp -8        # Allocates 8 bytes to stack
		addi $s0 $s0 8         # Increments stack memory used counter
		lw $t1 0($s1)          # Loads first field of the node (Coefficient)
		lw $t2 4($s1)          # Loads second field of the node (Exponent)
		sw $t1 0($sp)          # Saves it to stack
		sw $t2 4($sp)          # Saves it to stack
		lw $t0 8($s1)          # Loads third field of the node, which is the pointer
		beqz $t0 apseconddone  # If no pointer is given, then the polynomial is complete.
		move $s1 $t0           # Goes to next node in polynomial otherwise
		j apstoresecond
	apseconddone:
	move $a0 $sp               # Sets arg0 = sp
	move $s2 $ra               # Preserves ra
	jal create_polynomial      # Creates the polynomial
	move $ra $s2               # Restores ra
	move $a0 $v0               # Sets arg0 = polynomial
	move $s2 $ra               # Preserves ra
	jal sort_polynomial        # Sorts the polynomial
	move $ra $s2               # Restores ra
	add $sp $sp $s0            # Deallocates stack
	lw $s0 0($sp)              # Restore s0 from stack
	lw $s1 4($sp)              # Restore s1 from stack
	lw $s2 8($sp)              # Restore s2 from stack
	addi $sp $sp 12            # Deallocate stack
	jr $ra

.globl mult_polynomial
mult_polynomial: #a0 = polynomial 1, a1 = polynomial 2
	# This function should be the same idea as add_polynomial, only that it multiplies the terms with each other first before storing them in the stack.
	addi $sp $sp -12           # Allocate stack
	sw $s0 0($sp)              # Preserve s0 on stack
	sw $s1 4($sp)              # Preserve s1 on stack
	sw $s2 8($sp)              # Preserve s2 on stack
	beqz $a0 mpnull            # If arg0 is null, return a null polynomial
	beqz $a1 mpnull            # If arg1 is null, return a null polynomial
	lw $t0 0($a0)              # Loads polynomial start of arg0
	beqz $t0 mpnull            # If arg0 is null, return a null polynomial
	lw $t0 0($a1)              # Loads polynomial start of arg0
	beqz $t0 mpnull            # If arg0 is null, return a null polynomial
	li $s0 0                   # Zeroes s0. It is used as a counter for the amount of memory allocated in the stack.
	addi $sp $sp -8            # Allocate another 8 bytes for the terminating term
	addi $s0 $s0 8             # Increments memory used by 8 bytes
	sw $0 0($sp)               # Stores 0
	li $t0 -1
	sw $t0 4($sp)              # Stores -1
	move $s1 $a0               # Makes a copy of a0 to use as an address pointer counter
	lw $s1 0($s1)              # Loads the actual start of polynomial
	mpmain:
		lw $t0 0($s1)          # Loads the coefficent of a term in a0
		lw $t1 4($s1)          # Loads the exponent of a term in a0
		move $s2 $a1           # Makes a copy of a1 to use as an address pointer counter
		lw $s2 0($s2)              # Loads the actual start of polynomial
		mpsub:
			addi $sp $sp -8        # Allocates 8 bytes to stack
			addi $s0 $s0 8         # Increments stack memory used counter
			lw $t2 0($s2)          # Loads coefficent of a1
			lw $t3 4($s2)          # Loads exponent of a1
			mul $t8 $t2 $t0        # Multiplies the coefficents
			add $t9 $t1 $t3        # Adds the exponents.
			sw $t8 0($sp)          # Stores coefficent in stack
			sw $t9 4($sp)          # Stores exponent in stack
			lw $t4 8($s2)          # Loads pointer value of the a1 term
			beqz $t4 mpsubdone     # If the pointer is 0, then the polynomial is terminated.
			move $s2 $t4           # Goes to next term in the a1 polynomial
			j mpsub
		mpsubdone:
			lw $t4 8($s1)          # Loads pointer value of a0 term
			beqz $t4 mpmaindone    # If the pointer is 0, then the polynomial is terminated.
			move $s1 $t4           # Goes to next term in the a0 polynomial
			j mpmain
	mpmaindone:
	move $a0 $sp               # Sets arg0 = sp
	move $s2 $ra               # Preserves ra
	jal create_polynomial      # Creates the polynomial
	move $ra $s2               # Restores ra
	move $a0 $v0               # Sets arg0 = polynomial
	move $s2 $ra               # Preserves ra
	jal sort_polynomial        # Sorts the polynomial
	move $ra $s2               # Restores ra
	add $sp $sp $s0            # Deallocates stack
	lw $s0 0($sp)              # Restore s0 from stack
	lw $s1 4($sp)              # Restore s1 from stack
	lw $s2 8($sp)              # Restore s2 from stack
	addi $sp $sp 12            # Deallocate stack
	jr $ra
	mpnull:
		lw $s0 0($sp)              # Restore s0 from stack
		lw $s1 4($sp)              # Restore s1 from stack
		lw $s2 8($sp)              # Restore s2 from stack
		addi $sp $sp 12            # Deallocate stack
		li $a0 8
		li $v0 9                      # Syscall, allocates 8 bytes of heap memory
		syscall                       # Syscall 9 returns address of allocated heap in v0
		sw $0 0($v0)                  # Sets head pointer to null
		sw $0 4($v0)                  # Sets num of terms to null
		jr $ra

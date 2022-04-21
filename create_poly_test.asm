############################ CHANGE THIS FILE AS YOU DEEM FIT ############################
.data
pairs: .word 2 3 7 1 3 3 0 -1

.text
main:
 la $a0, pairs
 jal create_polynomial
 #write test code


exit:
 li $v0, 10
 syscall
.include "hw5.asm"

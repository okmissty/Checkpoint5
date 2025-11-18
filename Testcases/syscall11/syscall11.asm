# test_print_char.asm
# Test syscall 11 - Print character

.text
    # Print 'H' (ASCII 72)
    addi $a0, $zero, 72       # 'H' 
    addi $v0, $zero, 11       # syscall 11 = print character
    syscall
    
    # Print 'i' (ASCII 105)
    addi $a0, $zero, 105      # 'i'
    addi $v0, $zero, 11       # syscall 11
    syscall
    
    # Print newline (ASCII 10)
    addi $a0, $zero, 10       # '\n'
    addi $v0, $zero, 11
    syscall
    
    # Exit
    addi $v0, $zero, 10
    syscall
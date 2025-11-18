# test_syscalls.asm - Test all syscalls
# Assemble with: ./assemble kernel.asm test_syscalls.asm static.bin inst.bin

.text
main:
    # Test syscall 11 - Print character
    addi $a0, $zero, 72       # 'H'
    addi $v0, $zero, 11
    syscall
    
    addi $a0, $zero, 105      # 'i'
    syscall
    
    addi $a0, $zero, 10       # '\n'
    syscall
    
    # Test syscall 1 - Print integer (positive)
    addi $a0, $zero, 123
    addi $v0, $zero, 1
    syscall
    
    addi $a0, $zero, 10       # '\n'
    addi $v0, $zero, 11
    syscall
    
    # Test syscall 1 - Print integer (negative)
    addi $a0, $zero, -456
    addi $v0, $zero, 1
    syscall
    
    addi $a0, $zero, 10       # '\n'
    addi $v0, $zero, 11
    syscall
    
    # Test syscall 9 - Heap allocation
    addi $a0, $zero, 12       # Allocate 12 bytes
    addi $v0, $zero, 9
    syscall
    add $t0, $v0, $zero       # Save pointer
    
    # Store some values in heap
    addi $t1, $zero, 42
    sw $t1, 0($t0)
    addi $t1, $zero, 100
    sw $t1, 4($t0)
    
    # Allocate more heap
    addi $a0, $zero, 8
    addi $v0, $zero, 9
    syscall
    add $t2, $v0, $zero       # Save second pointer
    
    # Verify pointers are different
    # $t2 should be $t0 + 12
    
    # Test syscall 12 - Read character
    # (This will wait for keyboard input)
    addi $v0, $zero, 12
    syscall
    
    # Echo the character back
    add $a0, $v0, $zero
    addi $v0, $zero, 11
    syscall
    
    # Test syscall 5 - Read integer
    # Type a number and press enter
    addi $v0, $zero, 5
    syscall
    
    # Print the integer back
    add $a0, $v0, $zero
    addi $v0, $zero, 1
    syscall
    
    addi $a0, $zero, 10       # '\n'
    addi $v0, $zero, 11
    syscall
    
    # Test syscall 10 - Exit
    addi $v0, $zero, 10
    syscall
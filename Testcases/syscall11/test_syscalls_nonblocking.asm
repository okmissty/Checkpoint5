# test_syscalls_nonblocking.asm
# Non-blocking syscall test: prints characters and integers,
# performs a heap allocation and stores/loads values, then halts in user space.

.text
main:
    # Build terminal MMIO address in $t2 (0x03FFFF00)
    lui  $t2, 0x03FF
    ori  $t2, $t2, 0xF000
    addi $t2, $t2, 0xF00

    # Print "TEST\n" by direct MMIO writes (uses $t2 and $t3)
    addi $t3, $zero, 84       # 'T'
    sw   $t3, 0($t2)
    addi $t3, $zero, 69       # 'E'
    sw   $t3, 0($t2)
    addi $t3, $zero, 83       # 'S'
    sw   $t3, 0($t2)
    addi $t3, $zero, 84       # 'T'
    sw   $t3, 0($t2)
    addi $t3, $zero, 10       # '\n'
    sw   $t3, 0($t2)

    # Print integer 42 and newline
    addi $a0, $zero, 42
    addi $v0, $zero, 1
    syscall
    # newline via direct MMIO
    addi $t3, $zero, 10
    sw   $t3, 0($t2)

    # Allocate 8 bytes on heap (syscall 9)
    addi $a0, $zero, 8
    addi $v0, $zero, 9
    syscall
    add $t0, $v0, $zero       # Save pointer to $t0

    # Store two words: 7 and 13
    addi $t1, $zero, 7
    sw $t1, 0($t0)
    addi $t1, $zero, 13
    sw $t1, 4($t0)

    # Load first stored word and print
    lw $a0, 0($t0)
    addi $v0, $zero, 1
    syscall
    # space via direct MMIO
    addi $t3, $zero, 32
    sw   $t3, 0($t2)

    # Load second stored word and print
    lw $a0, 4($t0)
    addi $v0, $zero, 1
    syscall
    # newline via direct MMIO
    addi $t3, $zero, 10
    sw   $t3, 0($t2)

    # End: loop in user space (do not call syscall 10)
done:
    j done

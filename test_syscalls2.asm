# kernel.asm - CMSC 301 Project Checkpoint 5
# This file must be assembled FIRST before any user program
# Usage: ./assemble kernel.asm myprogram.asm static.bin inst.bin

# ============================================================================
# SYSCALL DISPATCHER - Line 0 starts here
# ============================================================================
# When syscall instruction executes:
#   - PC jumps to address 0 (here)
#   - Return address (PC+4) stored in $k0
#   - Syscall code in $v0
#   - Arguments in $a0, $a1, $a2, $a3
# 
# IMPORTANT: Your CPU does jalr $0, $k0 which means:
#   - $k0 = PC + 4 (next instruction after syscall)
#   - PC = 0 (jump to kernel)

    # Branch to appropriate syscall handler based on $v0
    # DEBUG: Try to set LED at 0x3FFFF10 to show we reached here
    addi $k1, $zero, 0xFF
    lui $at, 0x3FFF
    ori $at, $at, 0xF10
    sw $k1, 0($at)
    
    beq $v0, $zero, Syscall0     # Boot/initialization
    addi $k1, $zero, 1
    beq $v0, $k1, Syscall1        # Print integer
    addi $k1, $zero, 5
    beq $v0, $k1, Syscall5        # Read integer
    addi $k1, $zero, 9
    beq $v0, $k1, Syscall9        # Heap allocation
    addi $k1, $zero, 10
    beq $v0, $k1, Syscall10       # Exit program
    addi $k1, $zero, 11
    beq $v0, $k1, Syscall11       # Print character
    addi $k1, $zero, 12
    beq $v0, $k1, Syscall12       # Read character
    
    # If invalid syscall code, just return
    jr $k0

# ============================================================================
# SYSCALL 0: INITIALIZATION (Boot)
# ============================================================================
# Called automatically on reset when $v0 = 0
# Sets up stack pointer and heap pointer
Syscall0:
    # Set stack pointer to 0xFFFFF000 (-4096)
    lui $sp, 0xFFFF
    ori $sp, $sp, 0xF000
    
    # Initialize heap pointer
    # Heap starts where static memory ends
    la $k1, _END_OF_STATIC_MEMORY_
    sw $k1, __HEAP_POINTER__      # Store heap pointer in OS memory
    
    # Jump to user program
    j __SYSCALL_EndOfFile__

# ============================================================================
# SYSCALL 1: PRINT INTEGER
# ============================================================================
# Input: $a0 = integer to print (signed)
# Output: Prints integer to terminal
# Terminal address: 0x3FFFF00 (data)
Syscall1:
    # Save registers (all except $k0, $k1)
    addi $sp, $sp, -24
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $a0, 20($sp)
    
    # Check if negative
    add $t0, $a0, $zero          # $t0 = number to print
    slt $t1, $t0, $zero           # $t1 = 1 if negative
    beq $t1, $zero, Syscall1_Positive
    
    # Print minus sign
    addi $t2, $zero, 45           # ASCII '-'
    lui $t3, 0x3FFF
    ori $t3, $t3, 0x0F00
    sw $t2, 0($t3)                # Write to terminal
    
    # Make number positive
    sub $t0, $zero, $t0           # $t0 = -$t0

Syscall1_Positive:
    # Convert to ASCII string (stored on stack)
    addi $t1, $zero, 10           # Divisor = 10
    add $t2, $sp, $zero           # $t2 = stack pointer for digits
    
Syscall1_ConvertLoop:
    # Divide by 10 to get last digit
    divu $t0, $t1                 # $t0 / 10
    mflo $t0                      # $t0 = quotient
    mfhi $t3                      # $t3 = remainder (digit)
    
    # Convert digit to ASCII
    addi $t3, $t3, 48             # Add '0'
    
    # Push digit onto stack
    addi $t2, $t2, -1
    sb $t3, 0($t2)
    
    # Continue if quotient > 0
    bne $t0, $zero, Syscall1_ConvertLoop
    
    # Now print digits from stack
    lui $t3, 0x3FFF
    ori $t3, $t3, 0x0F00          # Terminal data address
    
Syscall1_PrintLoop:
    lb $t4, 0($t2)                # Load digit
    sw $t4, 0($t3)                # Write to terminal
    addi $t2, $t2, 1              # Move to next digit
    bne $t2, $sp, Syscall1_PrintLoop
    
    # Restore registers
    lw $a0, 20($sp)
    lw $t4, 16($sp)
    lw $t3, 12($sp)
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 24
    
    # Return
    jr $k0

# ============================================================================
# SYSCALL 5: READ INTEGER
# ============================================================================
# Input: Reads from keyboard until newline
# Output: $v0 = integer read (signed)
# Keyboard address: 0x3FFFF10 (data), 0x3FFFF14 (control)
Syscall5:
    # Save registers
    addi $sp, $sp, -28
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $t5, 20($sp)
    sw $t6, 24($sp)
    
    add $t0, $zero, $zero         # $t0 = result integer
    add $t1, $zero, $zero         # $t1 = is_negative flag
    addi $t2, $zero, 10           # $t2 = multiplier (10)
    
    lui $t3, 0x3FFF
    ori $t3, $t3, 0x0F10          # $t3 = keyboard data address
    lui $t4, 0x3FFF
    ori $t4, $t4, 0x0F14          # $t4 = keyboard control address

Syscall5_ReadLoop:
    # Wait for character
Syscall5_Wait:
    lw $t5, 0($t4)                # Read control register
    beq $t5, $zero, Syscall5_Wait # Wait until ready
    
    # Read character
    lw $t5, 0($t3)                # Read data register
    
    # Check for newline (ASCII 10)
    addi $t6, $zero, 10
    beq $t5, $t6, Syscall5_Done
    
    # Check for minus sign (ASCII 45)
    addi $t6, $zero, 45
    bne $t5, $t6, Syscall5_NotMinus
    addi $t1, $zero, 1            # Set negative flag
    j Syscall5_ReadLoop

Syscall5_NotMinus:
    # Check if digit (ASCII 48-57)
    addi $t6, $zero, 48           # '0'
    slt $t6, $t5, $t6
    bne $t6, $zero, Syscall5_ReadLoop  # Not a digit, skip
    
    addi $t6, $zero, 58           # '9' + 1
    slt $t6, $t5, $t6
    beq $t6, $zero, Syscall5_ReadLoop  # Not a digit, skip
    
    # Convert ASCII to digit
    addi $t5, $t5, -48            # Subtract '0'
    
    # result = result * 10 + digit
    mult $t0, $t2                 # result * 10
    mflo $t0
    add $t0, $t0, $t5             # + digit
    
    j Syscall5_ReadLoop

Syscall5_Done:
    # Apply negative sign if needed
    beq $t1, $zero, Syscall5_Positive
    sub $t0, $zero, $t0

Syscall5_Positive:
    add $v0, $t0, $zero           # Return result in $v0
    
    # Restore registers
    lw $t6, 24($sp)
    lw $t5, 20($sp)
    lw $t4, 16($sp)
    lw $t3, 12($sp)
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 28
    
    jr $k0

# ============================================================================
# SYSCALL 9: HEAP ALLOCATION
# ============================================================================
# Input: $a0 = number of bytes to allocate
# Output: $v0 = pointer to allocated memory
Syscall9:
    # Save registers
    addi $sp, $sp, -12
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $a0, 8($sp)
    
    # Load current heap pointer
    la $t0, __HEAP_POINTER__
    lw $t1, 0($t0)                # $t1 = current heap pointer
    
    # Return current heap pointer
    add $v0, $t1, $zero
    
    # Increment heap pointer by requested bytes
    add $t1, $t1, $a0
    sw $t1, 0($t0)                # Store new heap pointer
    
    # Restore registers
    lw $a0, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 12
    
    jr $k0

# ============================================================================
# SYSCALL 10: EXIT PROGRAM
# ============================================================================
Syscall10:
Syscall10_Loop:
    j Syscall10_Loop              # Infinite loop

# ============================================================================
# SYSCALL 11: PRINT CHARACTER
# ============================================================================
# Input: $a0 = character to print (ASCII)
# Output: Prints character to terminal
# Terminal is at 0x3FFFF00 (data register only)
Syscall11:
    # Save registers
    addi $sp, $sp, -8
    sw $t0, 0($sp)
    sw $a0, 4($sp)
    
    # Write to terminal data register
    lui $t0, 0x3FFF
    ori $t0, $t0, 0xF00          # Terminal data address
    sw $a0, 0($t0)                # Write character
    
    # Restore registers
    lw $a0, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 8
    
    jr $k0

# ============================================================================
# SYSCALL 12: READ CHARACTER
# ============================================================================
# Input: Waits for keyboard input
# Output: $v0 = character read (ASCII)
# Keyboard data at 0x3FFFF10, control/status at 0x3FFFF14
Syscall12:
    # Save registers
    addi $sp, $sp, -8
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    
    lui $t0, 0x3FFF
    ori $t0, $t0, 0xF10           # Keyboard data address
    lui $t1, 0x3FFF
    ori $t1, $t1, 0xF14           # Keyboard control address
    
    # Wait for character
Syscall12_Wait:
    lw $v0, 0($t1)                # Read control register
    beq $v0, $zero, Syscall12_Wait # Wait until ready
    
    # Read character
    lw $v0, 0($t0)                # Read data register
    
    # Restore registers
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 8
    
    jr $k0

# ============================================================================
# OS DATA SECTION
# ============================================================================
# This section stores kernel data in OS memory space (0x3FFF000 - 0x3FFFFEFC)

.data 0x3FFF000
__HEAP_POINTER__:
    .word 0                       # Heap pointer storage

# ============================================================================
# END OF KERNEL - User program starts here
# ============================================================================
__SYSCALL_EndOfFile__:
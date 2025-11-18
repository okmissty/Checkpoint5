# kernel.asm - CMSC 301 Project Checkpoint 5
# This file must be assembled FIRST before any user program
# Usage: ./assemble kernel.asm myprogram.asm static.bin inst.bin

    .text 0x00000000

# ============================================================================
# SYSCALL DISPATCHER - Line 0 starts here
# ============================================================================
# When syscall instruction executes:
#   - PC jumps to address 0 (here)
#   - Return address stored in $k0
#   - Syscall code in $v0
#   - Arguments in $a0, $a1, $a2, $a3

__SYSCALL_Dispatcher__:
    beq  $v0, $zero, Syscall0       # Boot/initialization
    addi $k1, $zero, 1
    beq  $v0, $k1, Syscall1         # Print integer
    addi $k1, $zero, 5
    beq  $v0, $k1, Syscall5         # Read integer
    addi $k1, $zero, 9
    beq  $v0, $k1, Syscall9         # Heap allocation
    addi $k1, $zero, 10
    beq  $v0, $k1, Syscall10        # Exit program
    addi $k1, $zero, 11
    beq  $v0, $k1, Syscall11        # Print character
    addi $k1, $zero, 12
    beq  $v0, $k1, Syscall12        # Read character
    
    # If invalid syscall code, just return
    jr   $k0

# ============================================================================
# SYSCALL 0: INITIALIZATION (Boot)
# ============================================================================
# Called automatically on reset when $v0 = 0
# Sets up stack pointer and heap pointer
Syscall0:
    # Set stack pointer to 0x03FFF000 (top of RAM below devices)
    lui  $sp, 0x03FF
    ori  $sp, $sp, 0xF000

    # Initialize heap pointer
    # Heap starts where static memory ends (small address computed by assembler)
    la   $k1, _END_OF_STATIC_MEMORY_   # end of static
    # __HEAP_POINTER__ lives in kernel .data at 0x03FFF000 — build that address
    lui  $k0, 0x03FF
    ori  $k0, $k0, 0xF000
    sw   $k1, 0($k0)                   # heap_ptr = end_of_static

    # Jump to user program
    j    __SYSCALL_EndOfFile__

# ============================================================================
# SYSCALL 1: PRINT INTEGER
# ============================================================================
# Input:  $a0 = integer to print (signed)
# Output: Prints integer to terminal
# Terminal address: -256($zero) = 0x3FFFF00
Syscall1:
    # Save registers (all except $k0, $k1)
    addi $sp, $sp, -24
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    sw   $t2, 8($sp)
    sw   $t3, 12($sp)
    sw   $t4, 16($sp)
    sw   $a0, 20($sp)
    
    # Check if negative
    add  $t0, $a0, $zero          # $t0 = number to print
    slt  $t1, $t0, $zero          # $t1 = 1 if negative
    beq  $t1, $zero, Syscall1_Positive
    
    # Print minus sign '-'
    addi $t2, $zero, 45           # ASCII '-'
    addi $t3, $zero, -256         # TERMINAL address
    sw   $t2, 0($t3)              # Write to terminal
    
    # Make number positive
    sub  $t0, $zero, $t0          # $t0 = -$t0

Syscall1_Positive:
    # Special case: 0
    beq  $t0, $zero, Syscall1_PrintZero

    # Convert to ASCII string (store digits on stack below saved regs)
    addi $t1, $zero, 10           # Divisor = 10
    add  $t2, $sp, $zero          # $t2 = starting pointer for digits
    
Syscall1_ConvertLoop:
    # Divide by 10 to get last digit
    div  $t0, $t1                 # $t0 / 10 (signed, but t0 >= 0 here)
    mflo $t0                      # $t0 = quotient
    mfhi $t3                      # $t3 = remainder (digit)
    
    # Convert digit to ASCII
    addi $t3, $t3, 48             # add '0'
    
    # Push digit onto stack (growing downward)
    addi $t2, $t2, -1
    sb   $t3, 0($t2)
    
    # Continue if quotient > 0
    bne  $t0, $zero, Syscall1_ConvertLoop
    
    # Now print digits from stack back up to $sp
    addi $t3, $zero, -256         # TERMINAL address
    
Syscall1_PrintLoop:
    lb   $t4, 0($t2)              # Load digit
    sw   $t4, 0($t3)              # Write to terminal
    addi $t2, $t2, 1              # Move to next digit
    bne  $t2, $sp, Syscall1_PrintLoop
    j    Syscall1_Restore

Syscall1_PrintZero:
    addi $t4, $zero, 48           # '0'
    sw   $t4, -256($zero)         # write directly to TERMINAL

Syscall1_Restore:
    # Restore registers
    lw   $a0, 20($sp)
    lw   $t4, 16($sp)
    lw   $t3, 12($sp)
    lw   $t2, 8($sp)
    lw   $t1, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 24
    
    # Return
    jr   $k0

# ============================================================================
# SYSCALL 5: READ INTEGER
# ============================================================================
# Input:  Reads from keyboard until newline
# Output: $v0 = integer read (signed)
# Keyboard STATUS: -240($zero) = 0x3FFFF10
# Keyboard DATA:   -236($zero) = 0x3FFFF14
Syscall5:
    # Save registers
    addi $sp, $sp, -28
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    sw   $t2, 8($sp)
    sw   $t3, 12($sp)
    sw   $t4, 16($sp)
    sw   $t5, 20($sp)
    sw   $t6, 24($sp)
    
    add  $t0, $zero, $zero         # $t0 = result integer
    add  $t1, $zero, $zero         # $t1 = is_negative flag
    addi $t2, $zero, 10            # $t2 = base 10
    
Syscall5_ReadLoop:
    # Wait for character
Syscall5_Wait:
    lw   $t5, -240($zero)          # Read KEYBOARD STATUS
    beq  $t5, $zero, Syscall5_Wait # Wait until ready
    
    # Read character
    lw   $t5, -236($zero)          # Read KEYBOARD DATA
    
    # Check for newline (ASCII 10)
    addi $t6, $zero, 10
    beq  $t5, $t6, Syscall5_Done
    
    # Check for minus sign (ASCII 45)
    addi $t6, $zero, 45
    bne  $t5, $t6, Syscall5_NotMinus
    addi $t1, $zero, 1             # Set negative flag
    j    Syscall5_ReadLoop

Syscall5_NotMinus:
    # Check if digit (ASCII 48-57)
    addi $t6, $zero, 48            # '0'
    slt  $t6, $t5, $t6
    bne  $t6, $zero, Syscall5_ReadLoop  # Not a digit, below '0'
    
    addi $t6, $zero, 58            # '9' + 1
    slt  $t6, $t5, $t6
    beq  $t6, $zero, Syscall5_ReadLoop  # Not a digit, above '9'
    
    # Convert ASCII to digit
    addi $t5, $t5, -48             # digit = char - '0'
    
    # result = result * 10 + digit
    mult $t0, $t2
    mflo $t0
    add  $t0, $t0, $t5
    
    j    Syscall5_ReadLoop

Syscall5_Done:
    # Apply negative sign if needed
    beq  $t1, $zero, Syscall5_Positive
    sub  $t0, $zero, $t0

Syscall5_Positive:
    add  $v0, $t0, $zero           # Return result in $v0
    
    # Restore registers
    lw   $t6, 24($sp)
    lw   $t5, 20($sp)
    lw   $t4, 16($sp)
    lw   $t3, 12($sp)
    lw   $t2, 8($sp)
    lw   $t1, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 28
    
    jr   $k0

# ============================================================================
# SYSCALL 9: HEAP ALLOCATION
# ============================================================================
# Input:  $a0 = number of bytes to allocate (multiple of 4)
# Output: $v0 = pointer to allocated memory
Syscall9:
    # Save registers
    addi $sp, $sp, -12
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    sw   $a0, 8($sp)
    
    # Load current heap pointer
    la   $t0, __HEAP_POINTER__
    lw   $t1, 0($t0)               # $t1 = current heap pointer
    
    # Return current heap pointer
    add  $v0, $t1, $zero
    
    # Increment heap pointer by requested bytes
    add  $t1, $t1, $a0
    sw   $t1, 0($t0)               # Store new heap pointer
    
    # Restore registers
    lw   $a0, 8($sp)
    lw   $t1, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 12
    
    jr   $k0

# ============================================================================
# SYSCALL 10: EXIT PROGRAM
# ============================================================================
Syscall10:
Syscall10_Loop:
    j    Syscall10_Loop            # Infinite loop

# ============================================================================
# SYSCALL 11: PRINT CHARACTER
# ============================================================================
# Input:  $a0 = character to print (ASCII)
# Output: Prints character to terminal at -256($zero)
Syscall11:
    # Save registers
    addi $sp, $sp, -8
    sw   $t0, 0($sp)
    sw   $a0, 4($sp)
    
    # Write to terminal
    sw   $a0, -256($zero)          # TERMINAL (0x3FFFF00)
    
    # Restore registers
    lw   $a0, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 8
    
    jr   $k0

# ============================================================================
# SYSCALL 12: READ CHARACTER
# ============================================================================
# Output: $v0 = character read (ASCII)
# Keyboard STATUS: -240($zero), DATA: -236($zero)
Syscall12:
    # Save registers
    addi $sp, $sp, -8
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    
Syscall12_Wait:
    lw   $t1, -240($zero)          # KEYBOARD STATUS
    beq  $t1, $zero, Syscall12_Wait
    
    lw   $v0, -236($zero)          # KEYBOARD DATA
    
    # Restore registers
    lw   $t1, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 8
    
    jr   $k0

# ============================================================================
# OS DATA SECTION
# ============================================================================
# This section stores kernel data in OS memory space (0x3FFF000 - 0x3FFFFEFC)

    .data 0x3FFF000
__HEAP_POINTER__:
    .word 0                        # Heap pointer storage

# ============================================================================
# END OF KERNEL - User program starts here
# ============================================================================
__SYSCALL_EndOfFile__:

# Tyeon Ford & Andy Quach
# kernel.asm - CMSC 301 Project Checkpoint 5
# This file must be assembled FIRST before any user program
# Usage: ./assemble kernel.asm myprogram.asm static.bin inst.bin

    .text 

# When syscall instruction executes:
#   - PC jumps to address 0 (aka syscall dispatcher)
#   - Return address stored in $k0
#   - Syscall code in $v0
#   - Arguments in $a0, $a1, $a2, $a3

# Line 0 starts here
__SYSCALL_Dispatcher__:
    # Adjust return address: some CPU implementations store the address
    # of the `syscall` instruction in $k0 instead of PC+4. Ensure $k0
    # points to the instruction after the `syscall` so `jr $k0` returns
    # to the correct place in user code.
    beq $v0, $zero, Syscall0       # Boot/initialization
    addi $k1, $zero, 1
    beq $v0, $k1, Syscall1     # Print integer

    # Device syscalls grouped in block 16..22
    addi $k1, $zero, 16
    beq $v0, $k1, Syscall16        # Hex: set display

    addi $k1, $zero, 17
    beq $v0, $k1, Syscall17        # Hex: get display

    addi $k1, $zero, 4
    beq $v0, $k1, Syscall4     # 4 = print string

    addi $k1, $zero, 5
    beq $v0, $k1, Syscall5     # Read integer

    addi $k1, $zero, 18
    beq $v0, $k1, Syscall18        # Joystick: read X

    addi $k1, $zero, 19
    beq $v0, $k1, Syscall19        # Joystick: read Y

    addi $k1, $zero, 8
    beq $v0, $k1, Syscall8     # 8 = read string

    addi $k1, $zero, 9
    beq $v0, $k1, Syscall9     # Heap allocation

    addi $k1, $zero, 10
    beq $v0, $k1, Syscall10        # Exit program

    addi $k1, $zero, 11
    beq $v0, $k1, Syscall11        # Print character

    addi $k1, $zero, 12
    beq $v0, $k1, Syscall12        # Read character

    addi $k1, $zero, 20
    beq $v0, $k1, Syscall20        # Joystick: read both X and Y

    addi $k1, $zero, 21
    beq $v0, $k1, Syscall21        # LED: set

    addi $k1, $zero, 22
    beq $v0, $k1, Syscall22        # LED: get
    
    # If invalid syscall code, it just returns
    jr $k0

# SYSCALL 0: Initalization
# This is called automatically on reset when $v0 = 0
# Sets up stack pointer and heap pointer
Syscall0:
    # Set stack pointer to 0x03FFF000 (top of RAM below devices)
    lui $sp, 0x03FF
    ori $sp, $sp, 0xF000

    # Initialize heap pointer:
    #   __HEAP_POINTER__ = _END_OF_STATIC_MEMORY_
    la $k0, __HEAP_POINTER__       # address of heap pointer variable (in .data)
    la $k1, _END_OF_STATIC_MEMORY_ # first free byte after all static data
    sw $k1, 0($k0)

    # Jump to user program
    j  __SYSCALL_EndOfFile__

# SYSCALL 1: Prints an Integer
# Input:  $a0 = integer to print
# Output: Prints integer to terminal
# Terminal address: -256($zero) = 0x3FFFF00
Syscall1:
    # Save registers (all except $k0, $k1)
    addi $sp, $sp, -24
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $a0, 20($sp)
    
    # Checks if its negative
    add $t0, $a0, $zero        # $t0 = number to print
    slt $t1, $t0, $zero        # $t1 = 1 if negative
    beq $t1, $zero, Syscall1_Positive
    
    # Print minus sign '-'
    addi $t2, $zero, 45           # ASCII '-'
    # Load Terminal base address 0x03FFFF00 into $t3
    lui $t3, 0x03FF
    ori $t3, $t3, 0xFF00
    sw  $t2, 0($t3)     # Write to terminal
    
    # Make number positive
    sub  $t0, $zero, $t0        # $t0 = -$t0

Syscall1_Positive:
    # Special case: 0
    beq  $t0, $zero, Syscall1_PrintZero

    # Convert to ASCII string (store digits on stack below saved regs)
    addi $t1, $zero, 10     # Divisor = 10
    add  $t2, $sp, $zero        # $t2 = starting pointer for digits (we will store words)
    
Syscall1_ConvertLoop:
    # Divides by 10 to get last digit
    div  $t0, $t1       # $t0 / 10 (signed, but t0 >= 0 here)
    mflo $t0        # $t0 = quotient
    mfhi $t3        # $t3 = remainder (digit)
    
    # Converts the digit to ASCII
    addi $t3, $t3, 48       # add '0'
    
    # Pushes digit onto stack as a 32-bit word (growing downward by 4 bytes)
    addi $t2, $t2, -4
    sw $t3, 0($t2)
    
    # Continue if quotient > 0
    bne $t0, $zero, Syscall1_ConvertLoop
    
    # Print digits from stack back up to $sp
    # Load TERMINAL base address into $t3
    lui $t3, 0x03FF
    ori $t3, $t3, 0xFF00
    
Syscall1_PrintLoop:
    lw $t4, 0($t2)      # Load digit word
    andi $t4, $t4, 255      # Extract low byte (ASCII digit)
    sw $t4, 0($t3)      # Write to terminal
    addi $t2, $t2, 4        # Move to next digit (word-sized)
    bne $t2, $sp, Syscall1_PrintLoop
    j Syscall1_Restore

Syscall1_PrintZero:
    addi $t4, $zero, 48           # '0'
    # Write '0' to TERMINAL
    lui $t5, 0x03FF
    ori $t5, $t5, 0xFF00
    sw $t4, 0($t5)

Syscall1_Restore:
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


# SYSCALL 16: Hex set
# Input: $a0 = value (only low 4 bits used)
Syscall16:
    andi $a0, $a0, 0x000F
    sw $a0, -208($zero)
    jr $k0


# SYSCALL 17: Hex get
# Output: $v0 = hex value (0..15)
Syscall17:
    lw $v0, -208($zero)
    andi $v0, $v0, 0x000F
    jr $k0


# SYSCALL 18: Joystick read x
# Output: $v0 = X (0..15)
Syscall18:
    lw $v0, -176($zero)
    andi $v0, $v0, 0x000F
    jr $k0


# SYSCALL 19: Joystick read y
# Output: $v0 = Y (0..15)
Syscall19:
    lw   $v0, -172($zero)
    andi $v0, $v0, 0x000F
    jr   $k0


# SYSCALL 20: JOYSTICK READ BOTH
# Output: $v0 = X, $v1 = Y

Syscall20:
    lw   $v0, -176($zero)
    lw   $v1, -172($zero)
    andi $v0, $v0, 0x000F
    andi $v1, $v1, 0x000F
    jr   $k0

# SYSCALL 21: LED set
# Input: $a0 = 0 (off) or nonzero (on)
Syscall21:
    andi $a0, $a0, 0x0001
    sw   $a0, -240($zero)
    jr   $k0

# SYSCALL 22: LED get
# Output: $v0 = 0 or 1
Syscall22:
    lw   $v0, -240($zero)
    andi $v0, $v0, 0x0001
    jr   $k0

# SYSCALL 4: Prints string
# Input:  $a0 = pointer to .asciiz string in static/heap memory
# Output: prints until 0-word terminator
#   Each character word: low 8 bits = ASCII
#   Terminator: full 32-bit 0
Syscall4:
    # save caller-saved regs we use
    addi $sp, $sp, -12
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    sw   $a0, 8($sp)

    add  $t0, $a0, $zero        # t0 = current address

Syscall4_Loop:
    lw $t1, 0($t0)      # load next word
    beq $t1, $zero, Syscall4_Done   # 0-word terminator

    # send low byte to TERMINAL at -256($zero) = 0x3FFFF00
    sw $t1, -256($zero)

    addi $t0, $t0, 4        # move to next word
    j Syscall4_Loop

Syscall4_Done:
    # restore and return
    lw $a0, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 12
    jr $k0


# SYSCALL 5: Read integer
# Input:  Reads from keyboard until newline
# Output: $v0 = integer read (signed)
# Keyboard STATUS: -240($zero) = 0x3FFFF10
# Keyboard DATA:   -236($zero) = 0x3FFFF14
Syscall5:
    # Save regs...
    addi $sp, $sp, -28
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    sw   $t2, 8($sp)
    sw   $t3, 12($sp)
    sw   $t4, 16($sp)
    sw   $t5, 20($sp)
    sw   $t6, 24($sp)

    add  $t0, $zero, $zero      # result
    add  $t1, $zero, $zero      # is_negative
    addi $t2, $zero, 10         # base 10

Sys5_ReadLoop:
Sys5_WaitChar:
    lw  $t3, -240($zero)       # Status
    beq $t3, $zero, Sys5_WaitChar

    lw $t5, -236($zero)       # Data
    sw $zero, -240($zero)     # pop

    # Check for newline (10 or 13)
    addi $t6, $zero, 10
    beq  $t5, $t6, Sys5_Done
    addi $t6, $zero, 13
    beq  $t5, $t6, Sys5_Done

    # Check minus sign
    addi $t6, $zero, 45         # '-'
    bne $t5, $t6, Sys5_NotMinus
    addi $t1, $zero, 1          # is_negative = 1
    j Sys5_ReadLoop

Sys5_NotMinus:
    # Check digit '0'..'9'
    addi $t6, $zero, 48         # '0'
    slt $t6, $t5, $t6
    bne $t6, $zero, Sys5_ReadLoop

    addi $t6, $zero, 58         # '9'+1
    slt $t6, $t5, $t6
    beq $t6, $zero, Sys5_ReadLoop

    # Convert ASCII → digit
    addi $t5, $t5, -48

    # result = result * 10 + digit
    mult $t0, $t2
    mflo $t0
    add $t0, $t0, $t5
    j Sys5_ReadLoop

Sys5_Done:
    beq $t1, $zero, Sys5_Pos
    sub $t0, $zero, $t0

Sys5_Pos:
    add  $v0, $t0, $zero

    # restores the registers
    lw $t6, 24($sp)
    lw $t5, 20($sp)
    lw $t4, 16($sp)
    lw $t3, 12($sp)
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 28
    jr $k0
    
# SYSCALL 8: Read string
# Behavior:
#   - Waits for characters from keyboard
#   - Stops on newline (LF=10 or CR=13)
#   - Stores each char as a 4-byte word in heap
#   - Writes 4-byte 0 terminator
#   - Updates __HEAP_POINTER__
#   - Returns v0 = pointer to first char of the new string
# Keyboard:
#   STATUS at -240($zero)
#   DATA   at -236($zero)
#   POP    by sw anything to -240($zero)
Syscall8:
    # save regs
    addi $sp, $sp, -28
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $t5, 20($sp)
    sw $a0, 24($sp)

    # t3 = &__HEAP_POINTER__
    la $t3, __HEAP_POINTER__

    # t4 = current heap pointer (where we will store first char)
    lw $t4, 0($t3)

    # v0 = start of this string
    add  $v0, $t4, $zero

Sys8_ReadLoop:
Sys8_WaitChar:
    lw $t1, -240($zero)        # status
    beq $t1, $zero, Sys8_WaitChar

    lw $t2, -236($zero)        # Data (character)
    sw $zero, -240($zero)      # pop / acknowledge

    # End on LF (10) or CR (13)
    addi $t0, $zero, 10
    beq $t2, $t0, Sys8_Done
    addi $t0, $zero, 13
    beq $t2, $t0, Sys8_Done

    # Store character as a 4-byte word at [t4]
    sw $t2, 0($t4)
    addi $t4, $t4, 4        # advance heap pointer by 4 bytes
    j Sys8_ReadLoop

Sys8_Done:
    # Null terminator word
    sw $zero, 0($t4)
    addi $t4, $t4, 4

    # Save updated heap pointer
    sw $t4, 0($t3)

    # restore regs
    lw $a0, 24($sp)
    lw $t5, 20($sp)
    lw $t4, 16($sp)
    lw $t3, 12($sp)
    lw $t2, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 28
    jr   $k0


# SYSCALL 9: Heap Allocation
# Input:  $a0 = number of bytes to allocate (multiple of 4)
# Output: $v0 = pointer to allocated memory
Syscall9:
    # Save registers
    addi $sp, $sp, -12
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $a0, 8($sp)
    
    # Load current heap pointer
    la $t0, __HEAP_POINTER__
    lw $t1, 0($t0)               # $t1 = current heap pointer
    
    # Return current heap pointer
    add $v0, $t1, $zero
    
    # Increment heap pointer by requested bytes
    add $t1, $t1, $a0
    sw $t1, 0($t0)      # Store new heap pointer
    
    # Restore registers
    lw $a0, 8($sp)
    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 12
    
    jr $k0

# SYSCALL 10: Exits the program
Syscall10:
Syscall10_Loop:
    j  Syscall10_Loop   # infinite loop

# SYSCALL 11: Print character
# Input:  $a0 = character to print (ASCII)
# Output: Prints character to terminal at -256($zero)
Syscall11:
    # Save registers
    addi $sp, $sp, -8
    sw $t0, 0($sp)
    sw $a0, 4($sp)

    # Write to terminal (build TERMINAL address in $t0)
    lui $t0, 0x03FF
    ori $t0, $t0, 0xFF00
    sw $a0, 0($t0)      # TERMINAL (0x03FFFF00)

    # Restore registers
    lw $a0, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 8

    jr $k0

# SYSCALL 12: Read character
# Output: v0 = character (ASCII)
# Protocol: 
#   - poll STATUS at -240($zero) until nonzero
#   - read DATA from -236($zero)
#   - write anything to -240($zero) to pop
Syscall12:
    addi $sp, $sp, -8
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)

Syscall12_Wait:
    lw $t0, -240($zero)      # Status
    beq $t0, $zero, Syscall12_Wait

    lw $v0, -236($zero)      # Data → v0
    sw $zero, -240($zero)    # pop

    lw $t1, 4($sp)
    lw $t0, 0($sp)
    addi $sp, $sp, 8
    jr $k0


# OS DATA SECTION
# This section stores kernel data in OS memory space (0x3FFF000 - 0x3FFFFEFC)

    .data 
__HEAP_POINTER__:
    .word 0     # Heap pointer storage

# END OF KERNEL - User program starts here

    .text
__SYSCALL_EndOfFile__:

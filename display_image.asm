# ==============================================================================
# MIPS Draw Image Program (draw_mango.asm)
# FIX: Image Data is NO LONGER ASSEMBLED. It must be manually loaded into RAM.
# The program will look for the image data starting at address 0x00010000.
# ==============================================================================

# Register Usage:
# $s0: Base address of the image data (fixed to 0x00010000).
# $s1: Current Y coordinate (Outer Loop Counter, 0-255).
# $s2: Current X coordinate (Inner Loop Counter, 0-255).
# $s3: Image dimension (256) - Loop boundary.
# $s4: Total pixel index (0 to 65535) used for memory offset.

.text
.globl main

main:
    # 1. Initialization
    
    # Set the hardcoded base address where the image data will be loaded (0x00010000)
    # lui $s0, 0x0001 is sufficient as the lower half is zero
    lui $s0, 0x0001             # $s0 = 0x00010000 (Start address for manual RAM load)
    
    # Load the image dimension (256) and initialize counters
    li $s3, 256                 # $s3 = 256 (Max dimension/Loop boundary)
    li $s1, 0                   # $s1 = 0 (Start Y coordinate)
    li $s4, 0                   # $s4 = 0 (Start linear pixel index)

    # 2. Outer Loop (Y coordinate, 0 to 255)
OuterLoop_Y:
    bge $s1, $s3, EndProgram
    li $s2, 0                   # $s2 = 0 (Start X coordinate)

    # 3. Inner Loop (X coordinate, 0 to 255)
InnerLoop_X:
    bge $s2, $s3, EndRow
    
    # --- Pixel Address Calculation ---
    # Address = Base ($s0) + (Index ($s4) * 4 bytes/word)
    sll $t1, $s4, 2             # $t1 = $s4 * 4 (byte offset)
    add $t2, $s0, $t1           # $t2 = Address of current pixel in memory
    
    # --- Load Pixel Color ---
    lw $t0, 0($t2)              # $t0 = Pixel Color (0x00RRGGBB)

    # --- Call Syscall 11 (Draw Pixel) ---
    # $a0=X, $a1=Y, $a2=Color
    add $a0, $s2, $zero         # $a0 = X coordinate
    add $a1, $s1, $zero         # $a1 = Y coordinate
    add $a2, $t0, $zero         # $a2 = Color (0x00RRGGBB)
    
    li $v0, 11                  # Set syscall code $v0 = 11
    syscall                     # Execute Syscall (Draws the pixel)

    # --- Increment Counters ---
    addi $s2, $s2, 1            # $s2 = X + 1
    addi $s4, $s4, 1            # $s4 = Linear Index + 1
    
    j InnerLoop_X

EndRow:
    addi $s1, $s1, 1            # $s1 = Y + 1 (Next Row)
    j OuterLoop_Y

EndProgram:
    li $v0, 10                  # Set syscall code $v0 = 10 (Exit Program)
    syscall                     # Execute Syscall (loops forever in kernel)
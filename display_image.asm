# ==============================================================================
# MIPS Draw Image Program (Final Safety Fix)
# FIX: Uses clearer register management and explicit calculation for X and Y.
# ==============================================================================

# Register Usage:
# $s0: Base address of image data (0x00010000).
# $s3: Total Pixels (65536) - Loop limit.
# $s5: Image Dimension (256) - Used for X/Y calculation.
# $s4: Current Pixel Index (0 to 65535) - Primary loop counter.

.text
.globl main

main:
    # 1. Initialization
    
    # Set the hardcoded base address (0x00010000)
    lui $s0, 0x0001             # $s0 = 0x00010000 
    
    # Set loop parameters (Fixes the 32-bit constant load)
    li $s5, 256                 # $s5 = 256 (Image dimension, R-Type ops use $s5)
    
    # Load 65536 (0x00010000) explicitly
    lui $s3, 0x0001             # $s3 = Upper 16 bits (0x0001)
    ori $s3, $s3, 0x0000        # $s3 = 65536 (Loop limit)

    li $s4, 0                   # $s4 = 0 (Start Pixel Index)

    # 2. Main Drawing Loop (Iterates 65,536 times)
DrawLoop:
    # Check if Index ($s4) >= 65536 (Stop condition)
    bge $s4, $s3, EndProgram
    
    # --- 2A. Pixel Address and Color Loading ---
    # Address = Base ($s0) + (Index ($s4) * 4)
    sll $t1, $s4, 2             # $t1 = $s4 * 4 (byte offset)
    add $t2, $s0, $t1           # $t2 = Address of current pixel
    lw $t0, 0($t2)              # $t0 = Pixel Color (0x00RRGGBB)

    # --- 2B. Calculate X and Y Coordinates (using $t registers) ---
    
    # Calculate Y ($t3) = Index / 256
    div $s4, $s5                # $s4 / 256 
    mflo $t3                    # $t3 = Y coordinate (quotient)

    # Calculate X ($t4) = Index MOD 256
    mfhi $t4                    # $t4 = X coordinate (remainder)
    
    # --- 2C. Call Syscall 11 (Draw Pixel) ---
    # Syscall 11 expects: $a0=X, $a1=Y, $a2=Color
    add $a0, $t4, $zero         # $a0 = X coordinate
    add $a1, $t3, $zero         # $a1 = Y coordinate
    add $a2, $t0, $zero         # $a2 = Color (from loaded $t0)
    
    li $v0, 11                  # Set syscall code $v0 = 11
    syscall                     # Execute Syscall (Draws the pixel)

    # --- 2D. Increment and Loop ---
    addi $s4, $s4, 1            # $s4 = Index + 1
    j DrawLoop

EndProgram:
    # 3. End the program
    li $v0, 10
    syscall
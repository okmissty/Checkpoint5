# ==============================================================================
# MIPS Draw Image Program (draw_mango.asm)
# FIX: Switched to a single, linear loop based on total pixels (0-65535).
# This is more robust as it eliminates nested loop branching complexities.
# ==============================================================================

# Register Usage:
# $s0: Base address of image data (0x00010000).
# $s3: Total Pixels (65536) - Loop limit.
# $s4: Current Pixel Index (0 to 65535) - Primary loop counter.
# $s5: Image Dimension (256) - Used for X/Y calculation.

.text
.globl main

main:
    # 1. Initialization
    
    # Set the hardcoded base address where the image data will be loaded (0x00010000)
    lui $s0, 0x0001             # $s0 = 0x00010000 
    
    # Set loop parameters
    li $s5, 256                 # $s5 = 256 (Image dimension)
    lui $s3, 1                  # $s3 = 0x00010000 (Set to 65536 in lower 16 bits if assembler supports it)
    # The MIPS assembler only loads 16 bits. We need 65536.
    li $s3, 65536               # $s3 = 65536 (Total Pixels: 256*256)
    li $s4, 0                   # $s4 = 0 (Start Pixel Index)

    # 2. Main Drawing Loop (Iterates 65,536 times)
DrawLoop:
    # Check if Index ($s4) >= 65536 (Stop condition)
    bge $s4, $s3, EndProgram
    
    # --- 2A. Pixel Address Calculation ---
    # Address = Base ($s0) + (Index ($s4) * 4 bytes/word)
    sll $t1, $s4, 2             # $t1 = $s4 * 4 (byte offset)
    add $t2, $s0, $t1           # $t2 = Address of current pixel in memory
    
    # --- 2B. Load Pixel Color ---
    lw $t0, 0($t2)              # $t0 = Pixel Color (0x00RRGGBB)

    # --- 2C. Calculate X and Y Coordinates ---
    # X = Index MOD 256
    # Y = Index / 256
    
    # Calculate Y ($a1)
    div $s4, $s5                # $s4 / 256
    mflo $a1                    # $a1 = Y coordinate (quotient)

    # Calculate X ($a0) (Remainder from the division)
    mfhi $a0                    # $a0 = X coordinate (remainder)

    # --- 2D. Call Syscall 11 (Draw Pixel) ---
    # Syscall 11 expects: $a0=X, $a1=Y, $a2=Color
    add $a2, $t0, $zero         # $a2 = Color (using the loaded $t0)
    
    li $v0, 11                  # Set syscall code $v0 = 11
    syscall                     # Execute Syscall (Draws the pixel)

    # --- 2E. Increment and Loop ---
    addi $s4, $s4, 1            # $s4 = Index + 1
    j DrawLoop

EndProgram:
    # 3. End the program
    li $v0, 10                  # Set syscall code $v0 = 10 (Exit Program)
    syscall                     # Execute Syscall (loops forever in kernel)
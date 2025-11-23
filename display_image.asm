# ==============================================================================
# MIPS Draw Image Program (Final Simple Arithmetic)
# Purpose: Draws a 256x256 image loaded at 0x00010000.
# Fixes: Uses safe arithmetic (AND/SRL) for X/Y calculation to avoid DIV hazards.
# ==============================================================================

# Register Usage:
# $s0: Base address of image data (0x00010000).
# $s3: Total Pixels (65536) - Loop limit.
# $s4: Current Pixel Index (0 to 65535) - Primary loop counter.
# $t0: Pixel Color (loaded from memory).
# $t1: Byte Offset for memory loading.
# $t2: Calculated memory address.

.text
.globl main

main:
    # 1. Initialization
    
    # Set the hardcoded base address where the image data is loaded (0x00010000)
    # The image_data.hex file MUST be loaded at this address.
    lui $s0, 0x0001             # $s0 = 0x0001xxxx
    ori $s0, $s0, 0x0000        # $s0 = 0x00010000 (Image Data Start)
    
    # Load 65536 (0x00010000) explicitly - Loop limit
    lui $s3, 0x0001             
    ori $s3, $s3, 0x0000        # $s3 = 65536 (Loop limit)

    li $s4, 0                   # $s4 = 0 (Start Pixel Index)

    # 2. Main Drawing Loop (Iterates 65,536 times)
DrawLoop:
    # Check if Index ($s4) >= 65536 (Stop condition)
    bge $s4, $s3, EndProgram
    
    # --- 2A. Pixel Address and Color Loading ---
    # Address = Base ($s0) + (Index ($s4) * 4)
    sll $t1, $s4, 2             # $t1 = Index * 4 (byte offset)
    add $t2, $s0, $t1           # $t2 = Address of current pixel
    lw $t0, 0($t2)              # $t0 = Pixel Color (0x00RRGGBB)

    # --- 2B. Calculate X and Y Coordinates (Safe Arithmetic) ---
    # The image is 256x256. 256 = 2^8.
    
    # X Coordinate (Modulo 256): Index AND 0xFF
    li $t1, 0x00FF              # $t1 = Mask for lowest 8 bits (255)
    and $a0, $s4, $t1           # $a0 = X coordinate (Index % 256)

    # Y Coordinate (Division by 256): Index >> 8
    srl $a1, $s4, 8             # $a1 = Y coordinate (Index / 256)
    
    # --- 2C. Call Syscall 11 (Draw Pixel) ---
    # Syscall 11 expects: $a0=X, $a1=Y, $a2=Color
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
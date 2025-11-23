# ==============================================================================
# MIPS Draw Image Program (draw_mango.asm)
# Draws a 256x256 image by iterating through coordinates and calling Syscall 11.
# FIX: Replaced 'move' with 'add' due to assembler limitation.
# ==============================================================================

# Register Usage:
# $s0: Base address of the image data (start of IMAGE_DATA).
# $s1: Current Y coordinate (Outer Loop Counter, 0-255).
# $s2: Current X coordinate (Inner Loop Counter, 0-255).
# $s3: Image dimension (256) - Loop boundary.
# $s4: Total pixel index (0 to 65535) used for memory offset.

.text
.globl main

main:
    # 1. Initialization
    
    # Load the base address of the image data into $s0
    la $s0, IMAGE_DATA      
    
    # Load the image dimension (256) and initialize counters
    li $s3, 256             # $s3 = 256 (Max dimension/Loop boundary)
    li $s1, 0               # $s1 = 0 (Start Y coordinate)
    li $s4, 0               # $s4 = 0 (Start linear pixel index)

    # 2. Outer Loop (Y coordinate, 0 to 255)
OuterLoop_Y:
    # Check if Y >= 256 (Stop condition for Y)
    bge $s1, $s3, EndProgram
    
    # Initialize X coordinate for the inner loop
    li $s2, 0               # $s2 = 0 (Start X coordinate)

    # 3. Inner Loop (X coordinate, 0 to 255)
InnerLoop_X:
    # Check if X >= 256 (Stop condition for X)
    bge $s2, $s3, EndRow
    
    # --- Pixel Address Calculation ---
    # The image data is stored linearly (Row 0, then Row 1, etc.)
    # Address = Base ($s0) + (Index ($s4) * 4 bytes/word)
    sll $t1, $s4, 2         # $t1 = $s4 * 4 (byte offset)
    add $t2, $s0, $t1       # $t2 = Address of current pixel in memory
    
    # --- Load Pixel Color ---
    lw $t0, 0($t2)          # $t0 = Pixel Color (0x00RRGGBB)

    # --- Call Syscall 11 (Draw Pixel) ---
    # Syscall 11 now expects: $a0=X, $a1=Y, $a2=Color
    
    # Replace 'move $a0, $s2' with 'add $a0, $s2, $zero'
    add $a0, $s2, $zero     # $a0 = X coordinate
    
    # Replace 'move $a1, $s1' with 'add $a1, $s1, $zero'
    add $a1, $s1, $zero     # $a1 = Y coordinate
    
    # Replace 'move $a2, $t0' with 'add $a2, $t0, $zero'
    add $a2, $t0, $zero     # $a2 = Color (0x00RRGGBB)
    
    li $v0, 11              # Set syscall code $v0 = 11
    syscall                 # Execute Syscall (Draws the pixel)

    # --- Increment Counters ---
    addi $s2, $s2, 1        # $s2 = X + 1
    addi $s4, $s4, 1        # $s4 = Linear Index + 1
    
    # Repeat X Loop
    j InnerLoop_X

EndRow:
    # 4. End of Row
    addi $s1, $s1, 1        # $s1 = Y + 1 (Next Row)
    
    # Repeat Y Loop
    j OuterLoop_Y

EndProgram:
    # 5. End the program
    li $v0, 10              # Set syscall code $v0 = 10 (Exit Program)
    syscall                 # Execute Syscall (loops forever in kernel)

# ==============================================================================
# Static Memory Data
# This block reserves space for the image data.
# ==============================================================================
.data
IMAGE_DATA: 
    # Your assembler must read the 65536 lines of 'image_data.txt' 
    # and place those 32-bit words starting at this address.
    .space 262144 # 65536 words * 4 bytes/word = 262,144 bytes
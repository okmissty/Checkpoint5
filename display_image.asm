# Register Usage:
# $s0: Base address of the image data (0x00010000).
# $s1: Current Y coordinate (Outer Loop Counter, 0-255).
# $s2: Current X coordinate (Inner Loop Counter, 0-255).
# $s3: Image dimension (256) - Loop boundary.
# $s4: Total pixel index (0 to 65535) used for memory offset.

.text
.globl main

main:
    # Initialization
    
    # Loads the base address of the image data (0x00010000) into $s0
    lui $s0, 0x0001     # $s0 = 0x00010000 
    
    # Load the image dimension (256) and initialize counters
    li $s3, 256     # $s3 = 256 (Max dimension/Loop boundary)
    li $s1, 0       # $s1 = 0 (Start Y coordinate)
    li $s4, 0       # $s4 = 0 (Start linear pixel index)

OuterLoop_Y:
    # Outer Loop (Y coordinate, 0 to 255)
    # Checks if Y >= 256 (Stop condition for Y)
    bge $s1, $s3, EndProgram
    
    # Initializes X coordinate for the inner loop
    li $s2, 0       # $s2 = 0 (Start X coordinate)

    
InnerLoop_X:
    # Inner Loop (X coordinate, 0 to 255)
    # Check if X >= 256 (Stop condition for X)
    bge $s2, $s3, EndRow
    
    # Calculating the pixel address
    # Address = Base ($s0) + (Index ($s4) * 4 bytes/word)
    sll $t1, $s4, 2             # $t1 = $s4 * 4 (byte offset)
    add $t2, $s0, $t1           # $t2 = Address of current pixel in memory
    
    # Loads the pixel color
    lw $t0, 0($t2)              # $t0 = Pixel Color (0x00RRGGBB)

    # Draws the pixel directly to the I/O device
    # Write X Coordinate (0xFFFFFF20)
    sw $s2, -224($zero)         # $s2 (X) -> 0xFFFFFF20
    
    # Write Y Coordinate (0xFFFFFF24)
    sw $s1, -220($zero)         # $s1 (Y) -> 0xFFFFFF24
    
    # Write Color (0xFFFFFF28)
    sw $t0, -216($zero)     # $t0 (Color) -> 0xFFFFFF28
    
    # Write Enable (WE) Pulse (0xFFFFFF2C)
    li $t9, 1       # Load 1 into a temporary register
    sw $t9, -212($zero)     # Pulse HIGH to 0xFFFFFF2C (Draws the pixel)
    sw $zero, -212($zero)       # Pulse LOW immediately

    # Increments the counters
    addi $s2, $s2, 1        # $s2 = X + 1
    addi $s4, $s4, 1        # $s4 = Linear Index + 1
    
    # Repeat X Loop
    j InnerLoop_X

EndRow:
    # end of Row
    addi $s1, $s1, 1        # $s1 = Y + 1 (Next Row)
    
    # Repeat Y Loop
    j OuterLoop_Y

EndProgram:
    li $v0, 10 # Set syscall code $v0 = 10 (Exits the Program)
    syscall  # Execute Syscall (loops forever in kernel)
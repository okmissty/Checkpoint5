# display_image.asm - Simple image display (5 stars for picture challenge)
# Tyeon Ford - CMSC 301 Final Project

.data 0x00001000
title: .asciiz "Loading image...\n"
done_msg: .asciiz "Display complete!\n"

.text
.globl main

# ============================================================================
# MAIN PROGRAM
# ============================================================================
main:
    # Print title using syscall 4
    addi $a0, $zero, 0x1000
    addi $v0, $zero, 4
    syscall
    
    # Draw the image from static memory
    jal  draw_stored_image
    
    # Print done message
    addi $a0, $zero, 0x1012    # Address after "Loading image...\n"
    addi $v0, $zero, 4
    syscall
    
    # Exit
    addi $v0, $zero, 10
    syscall

# ============================================================================
# DRAW_STORED_IMAGE - Load image from static memory and display on RGB
# ============================================================================
draw_stored_image:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    
    # Image data starts at 0x2000 (from image_data.asm)
    lui  $s3, 0x0000
    ori  $s3, $s3, 0x2000
    
    add  $s0, $zero, $zero     # y counter
    
draw_img_y:
    addi $t0, $zero, 256
    beq  $s0, $t0, draw_img_done
    
    add  $s1, $zero, $zero     # x counter
    
draw_img_x:
    addi $t0, $zero, 256
    beq  $s1, $t0, draw_img_y_next
    
    # Load color from static memory
    lw   $s2, 0($s3)           # Load 24-bit color
    addi $s3, $s3, 4           # Move to next pixel
    
    # Draw pixel at (x, y) directly to RGB display
    # RGB X register at 0x3FFFF20
    lui  $t0, 0x03FF
    ori  $t0, $t0, 0xFF20
    sw   $s1, 0($t0)           # Set X
    
    # RGB Y register at 0x3FFFF24
    addi $t0, $t0, 4
    sw   $s0, 0($t0)           # Set Y
    
    # RGB Color register at 0x3FFFF28
    addi $t0, $t0, 4
    sw   $s2, 0($t0)           # Set Color
    
    # RGB Write register at 0x3FFFF2C
    addi $t0, $t0, 4
    addi $t1, $zero, 1
    sw   $t1, 0($t0)           # Write pixel
    
    addi $s1, $s1, 1           # Next x
    j    draw_img_x

draw_img_y_next:
    addi $s0, $s0, 1           # Next y
    j    draw_img_y

draw_img_done:
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra
# display_image.asm - Display real image from static memory
# Tyeon Ford - CMSC 301 Final Project

.data 0x00001000
title: .asciiz "Loading image...\n"
done_msg: .asciiz "Display complete!\n"

.text
.globl main

main:
    # Print title
    lui  $a0, 0x0000
    ori  $a0, $a0, 0x1000
    addi $v0, $zero, 4
    syscall
    
    # Draw the image
    jal  draw_stored_image
    
    # Print done message  
    lui  $a0, 0x0000
    ori  $a0, $a0, 0x1012
    addi $v0, $zero, 4
    syscall
    
    # Exit
    addi $v0, $zero, 10
    syscall

draw_stored_image:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    
    # Image data at 0x2000
    lui  $s3, 0x0000
    ori  $s3, $s3, 0x2000
    
    add  $s0, $zero, $zero     # y = 0
    
draw_y_loop:
    addi $t0, $zero, 256
    beq  $s0, $t0, draw_done   # if y == 256, done
    
    add  $s1, $zero, $zero     # x = 0
    
draw_x_loop:
    addi $t0, $zero, 256
    beq  $s1, $t0, draw_y_next # if x == 256, next row
    
    # Load color from memory
    lw   $s2, 0($s3)
    addi $s3, $s3, 4
    
    # Set X coordinate (0x3FFFF20)
    lui  $t0, 0x03FF
    ori  $t0, $t0, 0xFF20
    sw   $s1, 0($t0)
    
    # Set Y coordinate (0x3FFFF24)
    lui  $t0, 0x03FF
    ori  $t0, $t0, 0xFF24
    sw   $s0, 0($t0)
    
    # Set Color (0x3FFFF28)
    lui  $t0, 0x03FF
    ori  $t0, $t0, 0xFF28
    sw   $s2, 0($t0)
    
    # Write pixel (0x3FFFF2C)
    lui  $t0, 0x03FF
    ori  $t0, $t0, 0xFF2C
    addi $t1, $zero, 1
    sw   $t1, 0($t0)
    
    addi $s1, $s1, 1
    j    draw_x_loop

draw_y_next:
    addi $s0, $s0, 1
    j    draw_y_loop

draw_done:
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    j
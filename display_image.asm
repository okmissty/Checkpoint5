# display_image.asm - Display 64x64 or 256x256 image
# Tyeon Ford - CMSC 301 Final Project

.data 0x00001000
title: .asciiz "Loading image...\n"
done_msg: .asciiz "Display complete!\n"

.text
.globl main

main:
    # Initialize stack pointer
    addi $sp, $zero, -4096
    
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
    addi $sp, $sp, -28
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    sw   $s5, 24($sp)
    
    # Load image width from 0x2000
    lui  $t0, 0x0000
    ori  $t0, $t0, 0x2000
    lw   $s4, 0($t0)           # width
    
    # Load image height from 0x2004
    lw   $s5, 4($t0)           # height
    
    # Image data starts at 0x2008 (after width and height)
    lui  $s3, 0x0000
    ori  $s3, $s3, 0x2008
    
    # y = 0
    add  $s0, $zero, $zero
    
draw_y_loop:
    # if y >= height, done
    slt  $t0, $s0, $s5
    beq  $t0, $zero, draw_done
    
    # x = 0
    add  $s1, $zero, $zero
    
draw_x_loop:
    # if x >= width, next row
    slt  $t0, $s1, $s4
    beq  $t0, $zero, draw_y_next
    
    # Load color from image data
    lw   $s2, 0($s3)
    addi $s3, $s3, 4
    
    # Write to RGB controller using negative offsets from $zero
    # -224 = 0xFFFFFF20 -> 26-bit = 0x3FFFF20 (X)
    # -220 = 0xFFFFFF24 -> 26-bit = 0x3FFFF24 (Y)
    # -216 = 0xFFFFFF28 -> 26-bit = 0x3FFFF28 (Color)
    # -212 = 0xFFFFFF2C -> 26-bit = 0x3FFFF2C (Write)
    sw   $s1, -224($zero)      # X coordinate
    sw   $s0, -220($zero)      # Y coordinate
    sw   $s2, -216($zero)      # Color
    sw   $zero, -212($zero)    # Write pixel (write 0 to trigger)
    
    # x++
    addi $s1, $s1, 1
    j    draw_x_loop

draw_y_next:
    # y++
    addi $s0, $s0, 1
    j    draw_y_loop

draw_done:
    lw   $s5, 24($sp)
    lw   $s4, 20($sp)
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 28
    jr   $ra
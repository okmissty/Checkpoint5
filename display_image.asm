# display_image.asm - Display image (using negative offsets)
# Tyeon Ford - CMSC 301 Final Project

.data 0x00001000
title: .asciiz "Loading image...\n"
done_msg: .asciiz "Display complete!\n"

.text
.globl main

main:
    lui  $a0, 0x0000
    ori  $a0, $a0, 0x1000
    addi $v0, $zero, 4
    syscall
    
    jal  draw_stored_image
    
    lui  $a0, 0x0000
    ori  $a0, $a0, 0x1012
    addi $v0, $zero, 4
    syscall
    
    addi $v0, $zero, 10
    syscall

draw_stored_image:
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    
    # Load image width and height from 0x2000
    lui  $t0, 0x0000
    ori  $t0, $t0, 0x2000
    lw   $s4, 0($t0)           # width
    lw   $s5, 4($t0)           # height
    
    # Image data starts at 0x2008
    lui  $s3, 0x0000
    ori  $s3, $s3, 0x2008
    
    add  $s0, $zero, $zero     # y = 0
    
draw_y_loop:
    beq  $s0, $s5, draw_done
    
    add  $s1, $zero, $zero     # x = 0
    
draw_x_loop:
    beq  $s1, $s4, draw_y_next
    
    # Load color from image data
    lw   $s2, 0($s3)
    addi $s3, $s3, 4
    
    # Write to RGB controller using negative offsets from $zero
    sw   $s1, -224($zero)      # X coordinate (0xFFFFFF20 -> 0x3FFFF20)
    sw   $s0, -220($zero)      # Y coordinate (0xFFFFFF24 -> 0x3FFFF24)
    sw   $s2, -216($zero)      # Color        (0xFFFFFF28 -> 0x3FFFF28)
    sw   $zero, -212($zero)    # Write pixel  (0xFFFFFF2C -> 0x3FFFF2C)
    
    addi $s1, $s1, 1
    j    draw_x_loop

draw_y_next:
    addi $s0, $s0, 1
    j    draw_y_loop

draw_done:
    lw   $s4, 20($sp)
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 24
    jr   $ra
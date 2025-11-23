# image_display.asm - Display real image from static memory

.data 0x00001000
title: .asciiz "Loading image...\n"
done_msg: .asciiz "Display complete!\n"

.text
.globl main

main:
    # Print title
    addi $a0, $zero, 0x1000
    addi $v0, $zero, 4
    syscall
    
    # LED on
    addi $a0, $zero, 1
    jal  led_set
    
    # Draw from static memory
    jal  draw_stored_image
    
    # Print done
    addi $a0, $zero, 0x1012    # After title
    addi $v0, $zero, 4
    syscall
    
    # LED off
    add  $a0, $zero, $zero
    jal  led_set
    
    # Hex display 'F'
    addi $a0, $zero, 15
    jal  hex_display
    
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
    
    # Image data starts at 0x2000 (from image_to_asm.py)
    addi $s3, $zero, 0x2000
    
    add  $s0, $zero, $zero     # y
    
draw_img_y:
    addi $t0, $zero, 256
    beq  $s0, $t0, draw_img_done
    
    add  $s1, $zero, $zero     # x
    
draw_img_x:
    addi $t0, $zero, 256
    beq  $s1, $t0, draw_img_y_next
    
    # Load color from static memory
    lw   $s2, 0($s3)           # Load 24-bit color
    addi $s3, $s3, 4           # Next pixel
    
    # Draw pixel
    add  $a0, $s1, $zero       # x
    add  $a1, $s0, $zero       # y
    add  $a2, $s2, $zero       # color
    jal  rgb_draw_pixel
    
    addi $s1, $s1, 1
    j    draw_img_x

draw_img_y_next:
    addi $s0, $s0, 1
    
    # Progress on hex (y / 16)
    srl  $a0, $s0, 4
    jal  hex_display
    
    j    draw_img_y

draw_img_done:
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra
# display_image.asm - Display image (26-bit addresses)
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
    
    # Load image width and height
    lui  $t0, 0x0000
    ori  $t0, $t0, 0x2000
    lw   $s4, 0($t0)           # width
    lw   $s5, 4($t0)           # height
    
    # Image data starts at 0x2008
    lui  $s3, 0x0000
    ori  $s3, $s3, 0x2008
    
    # Build RGB base address 0x3FFFF20 for 26-bit system
    # 0x3FFFF20 = 0011 1111 1111 1111 1111 0010 0000
    # Upper 10 bits: 0011 1111 11 = 0x0FF (shifted left 16) = 0x0FF0000
    # But lui shifts by 16, so: lui 0x03FF gives 0x03FF0000 (32-bit)
    # For 26-bit, we need: 0x3FFFF20
    # Let's build it: 0x3FFF = upper, 0xF20 = lower... no wait
    # 0x3FFFF20 in hex = 67108640 decimal
    # Split: 0x3FF = 1023, 0xFF20 = 65312
    # lui 0x03FF = 0x03FF0000, then ori 0xFF20 = 0x03FFFF20
    # The CPU will use lower 26 bits: 0x3FFFF20 ✓
    
    lui  $s6, 0x03FF
    ori  $s6, $s6, 0xFF20      # $s6 = RGB base (X register)
    
    add  $s0, $zero, $zero     # y = 0
    
draw_y_loop:
    beq  $s0, $s5, draw_done
    
    add  $s1, $zero, $zero     # x = 0
    
draw_x_loop:
    beq  $s1, $s4, draw_y_next
    
    # Load color
    lw   $s2, 0($s3)
    addi $s3, $s3, 4
    
    # Write X (base + 0)
    sw   $s1, 0($s6)
    
    # Write Y (base + 4)
    sw   $s0, 4($s6)
    
    # Write Color (base + 8)
    sw   $s2, 8($s6)
    
    # Write Enable (base + 12)
    addi $t1, $zero, 1
    sw   $t1, 12($s6)
    
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
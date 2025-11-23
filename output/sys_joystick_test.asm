##############################################
# sys_joystick_test.asm
##############################################

.text

###################################################
# === JOYSTICK DRIVER ROUTINES ===
###################################################

# Return X (0..15) in $v0
Joystick_ReadX:
    lw   $v0, -176($zero)        # 0x3FFFF50
    andi $v0, $v0, 0x000F
    jr   $ra

# Return Y (0..15) in $v0
Joystick_ReadY:
    lw   $v0, -172($zero)        # 0x3FFFF54
    andi $v0, $v0, 0x000F
    jr   $ra

# Return X and Y
#   $v0 = X
#   $v1 = Y
Joystick_ReadXY:
    lw   $v0, -176($zero)        # X
    lw   $v1, -172($zero)        # Y
    andi $v0, $v0, 0x000F
    andi $v1, $v1, 0x000F
    jr   $ra

###################################################
# === MAIN ===
###################################################
main:
Loop:
    # Read joystick
    jal  Joystick_ReadXY         # X→v0, Y→v1

    # Print "X="
    li   $v0, 11
    li   $a0, 88                 # 'X'
    syscall
    li   $v0, 11
    li   $a0, 61                 # '='
    syscall

    # Print X (integer)
    li   $v0, 1
    add  $a0, $v0, $zero         # move $a0, $v0
    syscall

    # Print " Y="
    li   $v0, 11
    li   $a0, 32                 # ' '
    syscall
    li   $v0, 11
    li   $a0, 89                 # 'Y'
    syscall
    li   $a0, 61                 # '='
    syscall

    # Print Y (integer)
    li   $v0, 1
    add  $a0, $v1, $zero         # move $a0, $v1
    syscall

    # Newline
    li   $v0, 11
    li   $a0, 10
    syscall

    j Loop

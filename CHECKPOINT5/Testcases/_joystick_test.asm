.text

###################################################
# === MAIN PROGRAM ===
###################################################
main:
Loop:
    # Read joystick
    jal  Joystick_ReadXY         # X -> v0, Y -> v1

    # Save X,Y before we overwrite v0 with syscall codes
    add  $t0, $v0, $zero         # t0 = X
    add  $t1, $v1, $zero         # t1 = Y

    # Print "X="
    li   $v0, 11                 # print char
    li   $a0, 88                 # 'X'
    syscall
    li   $v0, 11
    li   $a0, 61                 # '='
    syscall

    # Print X as integer (from t0, not v0)
    li   $v0, 1                  # print int
    add  $a0, $t0, $zero         # a0 = X
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

    # Print Y as integer (from t1)
    li   $v0, 1
    add  $a0, $t1, $zero         # a0 = Y
    syscall

    # Newline
    li   $v0, 11
    li   $a0, 10
    syscall

    j Loop

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

# Return X and Y: v0 = X, v1 = Y
Joystick_ReadXY:
    lw   $v0, -176($zero)        # X
    lw   $v1, -172($zero)        # Y
    andi $v0, $v0, 0x000F
    andi $v1, $v1, 0x000F
    jr   $ra

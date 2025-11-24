.text

###################################################
# === MAIN PROGRAM ===
###################################################
main:
    # Loop: exercise joystick syscalls individually and combined
Loop:
    # Read X via Syscall18
    addi $v0, $zero, 18
    syscall                     # v0 = X
    add  $t0, $v0, $zero        # save X

    # Print "X=" and value
    addi $v0, $zero, 11
    addi $a0, $zero, 88         # 'X'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 61         # '='
    syscall
    add  $a0, $t0, $zero
    addi $v0, $zero, 1
    syscall

    # Read Y via Syscall19
    addi $v0, $zero, 19
    syscall                     # v0 = Y
    add  $t1, $v0, $zero        # save Y

    # Print " Y=" and value
    addi $v0, $zero, 11
    addi $a0, $zero, 32         # ' '
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 89         # 'Y'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 61         # '='
    syscall
    add  $a0, $t1, $zero
    addi $v0, $zero, 1
    syscall

    # Now call combined Syscall20 (X->v0, Y->v1) and print both to verify
    addi $v0, $zero, 20
    syscall
    # print "Both: " then X and Y
    addi $v0, $zero, 11
    addi $a0, $zero, 66         # 'B'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 111        # 'o'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 116        # 't'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 104        # 'h'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 58         # ':'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 32         # ' '
    syscall
    # v0 already has X, v1 has Y — print both
    add  $a0, $v0, $zero
    addi $v0, $zero, 1
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 32
    syscall
    add  $a0, $v1, $zero
    addi $v0, $zero, 1
    syscall

    # Newline
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall

    j Loop

###################################################
# === JOYSTICK DRIVER ROUTINES ===
###################################################

    # Joystick access is performed via kernel syscalls (18/19/20)

.text

###################################################
# === MAIN PROGRAM ===
###################################################
main:
Loop:
    # Read joystick via syscall (Syscall20): returns X in $v0, Y in $v1
    addi $v0, $zero, 20
    syscall

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

    # Joystick access is performed via kernel syscalls (18/19/20)

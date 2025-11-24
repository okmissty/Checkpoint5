.text

###################################################
# === MAIN PROGRAM: count 0..15 on hex display ===
###################################################
main:
    addi $s0, $zero, 0           # s0 = current value (0..15)
    addi $t0, $zero, 16          # loop counter = 16 values

Hex_Loop:
    # Call Hex_Set(s0) via syscall (Syscall16)
    add  $a0, $s0, $zero
    addi $v0, $zero, 16
    syscall

    # Read back via Syscall17 and print as integer
    addi $v0, $zero, 17
    syscall                     # returns value in $v0
    add  $a0, $v0, $zero        # move to a0 for print-int
    addi $v0, $zero, 1          # syscall 1 = print integer
    syscall

    # Newline
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall

    # advance
    addi $s0, $s0, 1
    andi $s0, $s0, 0x000F
    addi $t0, $t0, -1
    bne  $t0, $zero, Hex_Loop

    # Exit (syscall 10)
    addi $v0, $zero, 10
    syscall

    # Device access is performed via kernel syscalls (16/17)

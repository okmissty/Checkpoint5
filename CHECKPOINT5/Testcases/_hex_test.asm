.text

###################################################
# === MAIN PROGRAM: count 0..15 on hex display ===
###################################################
main:
    addi $s0, $zero, 0           # s0 = current value (0..15)

Hex_Loop:
    # Call Hex_Set(s0) via syscall (Syscall16)
    add  $a0, $s0, $zero
    addi $v0, $zero, 16
    syscall

    # Delay so you can see each value
    addi $t0, $zero, 15       # tweak if too fast/slow
Hex_Delay:
    addi $t0, $t0, -1
    bne  $t0, $zero, Hex_Delay

    # s0 = (s0 + 1) mod 16
    addi $s0, $s0, 1
    andi $s0, $s0, 0x000F        # wrap back to 0 after 15

    j    Hex_Loop

    # Device access is performed via kernel syscalls (16/17)

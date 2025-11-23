.text

###################################################
# === MAIN PROGRAM: count 0..15 on hex display ===
###################################################
main:
    addi $s0, $zero, 0           # s0 = current value (0..15)

Hex_Loop:
    # Call Hex_Set(s0)
    add  $a0, $s0, $zero
    jal  Hex_Set

    # Delay so you can see each value
    addi $t0, $zero, 15       # tweak if too fast/slow
Hex_Delay:
    addi $t0, $t0, -1
    bne  $t0, $zero, Hex_Delay

    # s0 = (s0 + 1) mod 16
    addi $s0, $s0, 1
    andi $s0, $s0, 0x000F        # wrap back to 0 after 15

    j    Hex_Loop

###################################################
# === HEX DRIVER ROUTINES ===
###################################################
Hex_Set:
    andi $a0, $a0, 0x000F
    sw   $a0, -208($zero)        # 0x3FFFF30
    jr   $ra

Hex_Get:
    lw   $v0, -208($zero)
    andi $v0, $v0, 0x000F
    jr   $ra

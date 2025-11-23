.text
main:
    addi $s0, $zero, 0           # start off

LED_Loop:
    add  $a0, $s0, $zero
    jal  LED_Set

    addi $t0, $zero, 50
Delay:
    addi $t0, $t0, -1
    bne  $t0, $zero, Delay

    addi $s0, $s0, 1
    andi $s0, $s0, 0x0001
    j    LED_Loop

# driver after main:
LED_Set:
    andi $a0, $a0, 0x0001
    sw   $a0, -240($zero)
    jr   $ra

LED_Get:
    lw   $v0, -240($zero)
    andi $v0, $v0, 0x0001
    jr   $ra

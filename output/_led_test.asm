##############################################
# led_test.asm
# Assemble with:
#   ./assemble kernel.asm CHECKPOINT5/led_test.asm led_static.bin led_inst.bin
##############################################

.text

###################################################
# === MAIN PROGRAM: blink the LED ===
###################################################
main:
    # s0 will hold the LED state (0 or 1)
    addi $s0, $zero, 0           # start with LED off

LED_Loop:
    # Call LED_Set(s0)
    add  $a0, $s0, $zero         # a0 = current LED state
    jal  LED_Set

    # Simple delay loop so blinking is visible
    addi $t0, $zero, 50       # adjust this for your clock speed
LED_Delay:
    addi $t0, $t0, -1
    bne  $t0, $zero, LED_Delay

    # Toggle s0: s0 = (s0 + 1) & 1
    addi $s0, $s0, 1
    andi $s0, $s0, 0x0001

    j    LED_Loop

###################################################
# === LED DRIVER ROUTINES (as above) ===
###################################################
LED_Set:
    andi $a0, $a0, 0x0001
    sw   $a0, -192($zero)       # 0x3FFFF40
    jr   $ra

LED_Get:
    lw   $v0, -192($zero)
    andi $v0, $v0, 0x0001
    jr   $ra

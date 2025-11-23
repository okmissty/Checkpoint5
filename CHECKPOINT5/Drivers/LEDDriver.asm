# LED Controller Driver
# Address: 0x3FFFF10 → offset -240($zero)

# Set LED on/off based on $a0 (0 = off, nonzero = on)
LED_Set:
    andi $a0, $a0, 0x0001
    sw   $a0, -240($zero)        # write to LED_CTRL at 0x3FFFF10
    jr   $ra

# Read current LED state into $v0 (0 or 1)
LED_Get:
    lw   $v0, -240($zero)        # read LED_CTRL
    andi $v0, $v0, 0x0001
    jr   $ra

########################################
# LED Controller Driver
# Address: 0x3FFFF40 → offset -192($zero)
#
# Write:
#   sw value, -192($zero)   ; value's bit 0 drives the LED
#
# Read:
#   lw v0, -192($zero)      ; v0 = 0 or 1 (we'll mask to be safe)
########################################

# Set LED on/off based on $a0 (0 = off, nonzero = on)
LED_Set:
    # Only bit 0 matters; mask to be explicit
    andi $a0, $a0, 0x0001
    sw   $a0, -192($zero)       # write to LED_CTRL
    jr   $ra

# Read current LED state into $v0 (0 or 1)
LED_Get:
    lw   $v0, -192($zero)       # read LED_CTRL
    andi $v0, $v0, 0x0001       # keep only bit 0
    jr   $ra

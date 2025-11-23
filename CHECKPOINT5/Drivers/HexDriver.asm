# Hex Display Driver
# Address: 0x3FFFF30 → offset -208($zero)
#
# Write:
#   sw value, -208($zero)   ; lower 4 bits drive the hex digit
# Read:
#   lw v0, -208($zero)      ; v0 has previous hex_reg value

# Set hex display to $a0 & 0xF (0..15)
Hex_Set:
    andi $a0, $a0, 0x000F       # keep only low 4 bits
    sw   $a0, -208($zero)       # write to HEX_DISPLAY_CTRL
    jr   $ra

# Read hex_reg value into $v0 (0..15)
Hex_Get:
    lw   $v0, -208($zero)
    andi $v0, $v0, 0x000F
    jr   $ra

########################################
# Joystick Driver
# Hardware:
#   0x3FFFF50 → X address (read X input)
#   0x3FFFF54 → Y address (read Y input)
#
# On read:
#   DataToBus = zero_extend(X[3:0]) or Y[3:0]
#   So the low 4 bits are the joystick position, 0..15.
#
# Our CPU reaches these with:
#   X: lw ..., -176($zero)   # 0xFFFFFF50 → 0x3FFFF50 on bus
#   Y: lw ..., -172($zero)   # 0xFFFFFF54 → 0x3FFFF54 on bus
########################################

# Return X (0..15) in $v0
Joystick_ReadX:
    lw   $v0, -176($zero)        # read zero-extended X
    andi $v0, $v0, 0x000F        # (optional) keep only low 4 bits
    jr   $ra

# Return Y (0..15) in $v0
Joystick_ReadY:
    lw   $v0, -172($zero)        # read zero-extended Y
    andi $v0, $v0, 0x000F        # (optional) keep only low 4 bits
    jr   $ra

# Convenience: read BOTH X and Y
#   $v0 = X (0..15)
#   $v1 = Y (0..15)
Joystick_ReadXY:
    lw   $v0, -176($zero)        # X
    lw   $v1, -172($zero)        # Y
    andi $v0, $v0, 0x000F
    andi $v1, $v1, 0x000F
    jr   $ra

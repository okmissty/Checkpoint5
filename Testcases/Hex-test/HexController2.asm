.text
.globl main

main:
    # Initializes stack pointer
    addi $sp,$0,-4096

    # $t0 will hold the current digit (0..15)
    addi $t0,$0,0         # digit = 0

loop_digits:
    # Put current digit into $t1 (low 4 bits)
    add  $t1,$t0,$0       # t1 = t0

    # Write to hex display: address 0x3FFFF30 == 0xFFFFFF30 == -208
    sw   $t1,-208($0)     # HexController should show hex digit t0

    # Simple delay so we can see the digit change
    addi $t2,$0,15     # adjust this bigger/smaller as needed
delay:
    addi $t2,$t2,-1
    bne  $t2,$0,delay

    # Next digit: 0,1,2,...,15 then wrap back to 0
    addi $t0,$t0,1        # digit++

    addi $t3,$0,16        # limit = 16
    bne  $t0,$t3,loop_digits

    # If we reached 16, reset to 0 and repeat
    addi $t0,$0,0
    j    loop_digits

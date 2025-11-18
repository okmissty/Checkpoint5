.text
.globl main

main:
    # Initialize stack pointer
    addi $sp,$0,-4096

    # $t0 will hold the current digit (0..15)
    addi $t0,$0,0         # digit = 0

loop_digits:
    # Write current digit directly to hex display
    # 0x3FFFF30 == 0xFFFFFF30 == -208
    sw   $t0,-208($0)     # HexController should show hex digit t0 (low 4 bits)

    # Simple delay so you can see the digit change

    addi $t2,$0,15     # adjust as needed
delay:
    addi $t2,$t2,-1
    bne  $t2,$0,delay


    # Next digit: (t0 + 1) & 0xF  -> cycles 0..15

    addi $t0,$t0,1        # t0++
    andi $t0,$t0,0xF      # keep only low 4 bits

    j    loop_digits

.text
.globl main
main:
    addi $sp,$0,-4096

    # value to show
    lui  $t1, 4660 #0x1234 -> $t1 = 0x12340000
    ori  $t1,$t1, 22136 #0x5678 -> $t1 = 0x12345678

    # 0x3FFFF30 == 0xFFFFFF30 == -208
    sw   $t1,-208($0)     # <- correct byte address to the device
end: j end

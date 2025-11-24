.text
main:
    addi $sp,$0,-4096
    addi $s0,$0,0           # start off

LED_Loop:
    add $a0,$s0,$0
    addi $v0,$zero,21    # Syscall21 = LED_Set
    syscall

    addi $t0,$0,50
Delay:
    addi $t0,$t0,-1
    bne $t0,$0,Delay

    addi $s0,$s0,1
    andi $s0,$s0,0x0001
    j LED_Loop

# Device access is performed via kernel syscalls (21/22)

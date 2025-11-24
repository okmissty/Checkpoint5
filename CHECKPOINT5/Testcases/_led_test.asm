.text
main:
    addi $sp,$0,-4096
    addi $s0,$0,0           # start off
    # Loop: toggle LED and verify with get syscall
LED_Loop:
    # Set LED according to s0 (0 or 1)
    add  $a0, $s0, $zero
    addi $v0, $zero, 21    # Syscall21 = LED_Set
    syscall

    # Read back via Syscall22
    addi $v0, $zero, 22
    syscall                 # v0 = LED state

    # Print returned LED state as integer
    add  $a0, $v0, $zero
    addi $v0, $zero, 1      # print int
    syscall

    # Newline
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall

    # Delay
    addi $t0,$0,50
Delay:
    addi $t0,$t0,-1
    bne $t0,$0,Delay

    # Toggle and repeat
    addi $s0,$s0,1
    andi $s0,$s0,0x0001
    j LED_Loop

# Device access is performed via kernel syscalls (21/22)

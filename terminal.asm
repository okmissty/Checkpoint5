# Run this test once you have hooked up your terminal and memory
.data
    functions: .word end f
    info: .word 72 101 108 108 111 44 32 119 111 114 108 100 33 10 0
.text
.globl main
main:
    addi $sp, $sp, -4096
    la $s0, functions
begin:
    lw $t0, 4($s0)              # load f
    la $a0, info                # argument = &info
    jalr $t0                    # call f(info)
    lw $t0, 0($s0)              # load end
    jalr $t0                    # call end()
f:
    lw $t0, 0($a0)              # load *a0 (current character)
    beq $t0, $0, endf           # if char == 0 → end
    addi $sp, $sp, -4   
    sw $ra, 0($sp)              # save return address
    sw $t0, -256($0)            # write char to TERMINAL (0x3FFFF00)
    addi $a0, $a0, 4            # advance to next char
    jal f                       # recursive call f(a0)
    lw $ra, 0($sp)              # restore $ra
    addi $sp, $sp, 4
endf:
    jr $ra

end:
    j end
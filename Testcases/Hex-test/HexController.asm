.text
.globl main

main:
    # Test basic R-type instruction
    add $t0, $zero, $zero
    
    # Test I-type instruction - put value 0x1234 in register
    addi $t1, $zero, 0x1234
    
    # Test store instruction - store to address 5 (so hex display shows it)
    sw $t1, 5($zero)
    
    # Test load instruction - load back from address 5
    lw $t2, 5($zero)
    
    # Test branch instruction
    beq $t1, $t2, end
    
end:
    # Halt (infinite loop)
    j end
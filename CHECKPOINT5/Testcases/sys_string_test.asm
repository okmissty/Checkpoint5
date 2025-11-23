##############################################
# sys_string_test.asm
# Test syscall 4 (print string) and 8 (read string)
##############################################

.text
.globl main

main:
    # Print prompt: "Enter a line:"
    la   $a0, msg_prompt
    addi $v0, $zero, 4      # syscall 4: print string
    syscall

    # Print newline after the prompt
    addi $a0, $zero, 10     # '\n'
    addi $v0, $zero, 11     # syscall 11: print char
    syscall

    # Read a line into heap, v0 = pointer to heap string
    addi $v0, $zero, 8      # syscall 8: read string
    syscall                 # v0 = pointer

    # Save returned pointer in s0
    add  $s0, $v0, $zero

    # Print "You typed: "
    la   $a0, msg_prefix
    addi $v0, $zero, 4
    syscall

    # Print the string we just read
    add  $a0, $s0, $zero    # a0 = pointer from syscall 8
    addi $v0, $zero, 4
    syscall

    # Print newline at the end
    addi $a0, $zero, 10
    addi $v0, $zero, 11
    syscall

    # Exit program
    addi $v0, $zero, 10
    syscall

##############################################
.data

msg_prompt: .asciiz "Enter a line:"      # no '\n' or extra .word

msg_prefix: .asciiz "You typed: "
.text
.globl main

main:
    la  $a0, msg
    li  $v0, 4      # print string
    syscall

    # Print newline at the end
    addi $a0, $zero, 10
    addi $v0, $zero, 11
    syscall

    li  $v0, 10     # exit
    syscall

.data
msg:
    .asciiz "Hello from static .asciiz!"
.text
.globl main

main:
    la  $a0, msg
    li  $v0, 4      # print string
    syscall

    li  $v0, 10     # exit
    syscall

.data
msg:
    .asciiz "Hello from static .asciiz!\n"
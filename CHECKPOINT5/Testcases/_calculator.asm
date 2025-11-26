.text

# Simple calculator using kernel syscalls
# - Reads a line (syscall 8)
# - Parses: <int_or_\_> <op> <int_or_\_>
# - Supported ops: + - * /
# - '_' uses previous result (starts as 0)
# - Type 'q' as first non-space char to quit

main:
    addi $sp, $zero, -4096
    addi $s3, $zero, 0      # s3 = previous result
    addi $s4, $zero, 0      # s4 = has_prev (0 = no)

Calc_Loop:
    # Print prompt: "calc> " using syscall11 per char
    addi $v0, $zero, 11
    addi $a0, $zero, 99      # 'c'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 97      # 'a'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 108     # 'l'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 99      # 'c'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 62      # '>'
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 32      # ' '
    syscall

    # Read a line (syscall 8) -> v0 = pointer to heap string (words)
    addi $v0, $zero, 8
    syscall
    add  $t0, $v0, $zero     # t0 = ptr to current char (word-addressed)

    # Skip leading whitespace
SkipLeading:
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    beq  $t1, $zero, Calc_Loop   # empty line -> prompt again
    addi $t2, $zero, 32
    beq  $t1, $t2, SkipInc
    addi $t2, $zero, 9          # tab
    beq  $t1, $t2, SkipInc
    # if 'q' or 'Q' then quit
    addi $t2, $zero, 113        # 'q'
    beq  $t1, $t2, Calc_Quit
    addi $t2, $zero, 81         # 'Q'
    beq  $t1, $t2, Calc_Quit
    j ParseFirst
SkipInc:
    addi $t0, $t0, 4
    j SkipLeading

# Parse first operand (could be '_' or integer)
ParseFirst:
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    addi $t2, $zero, 95        # '_'
    beq  $t1, $t2, FirstUnderscore
    # parse optional sign
    addi $t2, $zero, 45        # '-'
    beq  $t1, $t2, FirstSignNeg
    addi $t2, $zero, 43        # '+'
    beq  $t1, $t2, FirstSignPos
    # otherwise expect digit
    addi $t2, $zero, 48
    slt  $t3, $t1, $t2
    bne  $t3, $zero, ParseError
    addi $t2, $zero, 58
    slt  $t3, $t1, $t2
    beq  $t3, $zero, ParseError

    # parse digits
    addi $t5, $zero, 0      # acc
    addi $t6, $zero, 1      # sign = 1
FirstDigitLoop:
    addi $t4, $t1, -48      # digit value
    addi $t7, $zero, 10
    mult $t5, $t7
    mflo $t5
    add  $t5, $t5, $t4
    addi $t0, $t0, 4
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    addi $t2, $zero, 48
    slt  $t3, $t1, $t2
    bne  $t3, $zero, FirstDigitsDone
    addi $t2, $zero, 58
    slt  $t3, $t1, $t2
    beq  $t3, $zero, FirstDigitsDone
    j FirstDigitLoop
FirstDigitsDone:
    mult $t5, $t6
    mflo $s0                # s0 = operand1
    j AfterFirst

FirstSignNeg:
    addi $t6, $zero, -1
    addi $t0, $t0, 4
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    j FirstDigitLoop

FirstSignPos:
    addi $t6, $zero, 1
    addi $t0, $t0, 4
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    j FirstDigitLoop

FirstUnderscore:
    # use previous result if available, else 0
    beq  $s4, $zero, UseZero1
    add  $s0, $s3, $zero
    addi $t0, $t0, 4
    j AfterFirst
UseZero1:
    addi $s0, $zero, 0
    addi $t0, $t0, 4
    j AfterFirst

AfterFirst:
    # skip spaces
Skip1:
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    beq  $t1, $zero, Calc_Loop
    addi $t2, $zero, 32
    beq  $t1, $t2, Skip1Inc
    addi $t2, $zero, 9
    beq  $t1, $t2, Skip1Inc
    j ReadOp
Skip1Inc:
    addi $t0, $t0, 4
    j Skip1

ReadOp:
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    add  $s1, $t1, $zero     # operator ASCII
    addi $t0, $t0, 4

    # skip spaces before second operand
Skip2:
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    beq  $t1, $zero, Calc_Loop
    addi $t2, $zero, 32
    beq  $t1, $t2, Skip2Inc
    addi $t2, $zero, 9
    beq  $t1, $t2, Skip2Inc
    j ParseSecond
Skip2Inc:
    addi $t0, $t0, 4
    j Skip2

ParseSecond:
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    addi $t2, $zero, 95
    beq  $t1, $t2, SecondUnderscore
    # optional sign
    addi $t2, $zero, 45
    beq  $t1, $t2, SecondSignNeg
    addi $t2, $zero, 43
    beq  $t1, $t2, SecondSignPos
    # digit?
    addi $t2, $zero, 48
    slt  $t3, $t1, $t2
    bne  $t3, $zero, ParseError
    addi $t2, $zero, 58
    slt  $t3, $t1, $t2
    beq  $t3, $zero, ParseError

    addi $t5, $zero, 0
    addi $t6, $zero, 1
SecondDigitLoop:
    addi $t4, $t1, -48
    addi $t7, $zero, 10
    mult $t5, $t7
    mflo $t5
    add  $t5, $t5, $t4
    addi $t0, $t0, 4
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    addi $t2, $zero, 48
    slt  $t3, $t1, $t2
    bne  $t3, $zero, SecondDigitsDone
    addi $t2, $zero, 58
    slt  $t3, $t1, $t2
    beq  $t3, $zero, SecondDigitsDone
    j SecondDigitLoop
SecondDigitsDone:
    mult $t5, $t6
    mflo $s2
    j AfterSecond

SecondSignNeg:
    addi $t6, $zero, -1
    addi $t0, $t0, 4
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    j SecondDigitLoop

SecondSignPos:
    addi $t6, $zero, 1
    addi $t0, $t0, 4
    lw   $t1, 0($t0)
    andi $t1, $t1, 0xFF
    j SecondDigitLoop

SecondUnderscore:
    beq  $s4, $zero, UseZero2
    add  $s2, $s3, $zero
    addi $t0, $t0, 4
    j AfterSecond
UseZero2:
    addi $s2, $zero, 0
    addi $t0, $t0, 4
    j AfterSecond

AfterSecond:
    # compute based on operator
    # '+'
    addi $t2, $zero, 43
    beq  $s1, $t2, DoAdd
    # '-'
    addi $t2, $zero, 45
    beq  $s1, $t2, DoSub
    # '*'
    addi $t2, $zero, 42
    beq  $s1, $t2, DoMul
    # '/'
    addi $t2, $zero, 47
    beq  $s1, $t2, DoDiv
    j ParseError

DoAdd:
    add  $t0, $s0, $s2
    add  $s3, $s0, $s2
    addi $s4, $zero, 1
    j PrintResult

DoSub:
    sub  $t0, $s0, $s2
    add  $s3, $s0, $zero
    sub  $s3, $s3, $s2
    addi $s4, $zero, 1
    j PrintResult

DoMul:
    mult $s0, $s2
    mflo $t0
    mfhi $t1
    add  $s3, $t0, $zero
    addi $s4, $zero, 1
    j PrintResult

DoDiv:
    # check divide by zero
    beq  $s2, $zero, DivByZero
    div  $s0, $s2
    mflo $t0
    add  $s3, $t0, $zero
    addi $s4, $zero, 1
    j PrintResult

DivByZero:
    # print error message "ERR: div0\n"
    # E, R, R, :, ' ', d,i,v,0, newline
    addi $v0, $zero, 11
    addi $a0, $zero, 69
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 82
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 82
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 58
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 32
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 100
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 105
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 118
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 48
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall
    j Calc_Loop

PrintResult:
    # print integer in $t0 via syscall1
    add  $a0, $t0, $zero
    addi $v0, $zero, 1
    syscall
    # newline
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall
    j Calc_Loop

ParseError:
    # print "Parse error\n" and reprompt
    addi $v0, $zero, 11
    addi $a0, $zero, 80
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 97
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 114
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 115
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 101
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 32
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall
    j Calc_Loop

Calc_Quit:
    # print goodbye and exit
    addi $v0, $zero, 11
    addi $a0, $zero, 71
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 111
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 111
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 100
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 98
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 121
    syscall
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall
    # exit loop via syscall10
    addi $v0, $zero, 10
    syscall

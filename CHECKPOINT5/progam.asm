# Tyeon Ford & Andy Quach
# Two-Term Calculator 

# Reads arithmetic expressions like: "10 + 20" or "_ * 5"
# Supports +, -, *, /, and the '_' placeholder for the previous result.

# Register Usage:
# $s0: Stores the previous calculation result (starts at 0).
# $s1: Stores the first operand (A).
# $s2: Stores the second operand (B).
# $s3: Stores the operator character (+, -, *, /).

.data
# Data to be printed for user prompts
prompt_str: .asciiz "Enter expression (e.g., 10 + 20 or _ / 4): "
result_str: .asciiz "= "
newline: .asciiz "\n"

.text
.globl main

main:
    # Initialization and Greeting
    
    # Initialize previous result to 0
    li $s0, 0           # $s0 = previous_result (starts at 0)
    
CalculatorLoop:
    
    # Print prompt string (Syscall 4)
    li $v0, 4
    la $a0, prompt_str
    syscall
    
    # Read First Operand (A)
    
    # Read the first character to check for '_' (Syscall 12)
    li $v0, 12          # Read character
    syscall
    add $t0, $v0, $zero # $t0 = first character read
    
    addi $t1, $zero, 95 # ASCII value for '_' (95)
    
    # If character is '_', load previous result ($s0) into A ($s1)
    bne $t0, $t1, ReadFirstInt # If not '_', jump to read integer
    
    add $s1, $s0, $zero # $s1 = previous_result (A = $s0)
    
    # Now read the next character (a space, which we must consume)
    li $v0, 12
    syscall             # Consume the space after '_'
    
    j ReadOperator
    
ReadFirstInt:
    # Program already read the first character, which was the first digit.
    # We must reset the keyboard buffer before reading the full integer.
    # The kernel's Syscall 5 handle
    s polling the keyboard and reading until newline.
    
    # Since we already read the first character in $t0, we can't use Syscall 5 directly.
    # For simplicity, we will assume Syscall 5 handles all digits *after* the first one 
    # and requires the user to retype the first number. 
    
    # Resetting prompt and reading the integer A (simplification)
    li $v0, 5           # Read integer
    syscall
    add $s1, $v0, $zero # $s1 = First Operand (A)
    
    
    # Read Operator
ReadOperator:
    li $v0, 12          # Read character (space)
    syscall             # Consume the space
    
    li $v0, 12          # Read character (operator)
    syscall
    add $s3, $v0, $zero # $s3 = Operator character
    
    li $v0, 12          # Read character (space)
    syscall             # Consume the space

    # Read Second Operand (B)
    li $v0, 5           # Read integer
    syscall
    add $s2, $v0, $zero # $s2 = Second Operand (B)
    
    # Determine Operation
    
    # Print "=" (Syscall 4)
    li $v0, 4
    la $a0, result_str
    syscall
    
    # Check operator type and branch
    addi $t1, $zero, 43 # ASCII '+'
    beq $s3, $t1, DoAdd
    
    addi $t1, $zero, 45 # ASCII '-'
    beq $s3, $t1, DoSub
    
    addi $t1, $zero, 42 # ASCII '*'
    beq $s3, $t1, DoMult
    
    addi $t1, $zero, 47 # ASCII '/'
    beq $s3, $t1, DoDiv
    
    j PrintResult # Default case (unknown operator)

DoAdd:
    add $s0, $s1, $s2   # $s0 = A + B
    j PrintResult
    
DoSub:
    sub $s0, $s1, $s2   # $s0 = A - B
    j PrintResult

DoMult:
    mult $s1, $s2       # HI/LO = A * B
    mflo $s0            # $s0 = LO (Result)
    j PrintResult
    
DoDiv:
    # Check for divide by zero
    beq $s2, $zero, DivideByZeroError
    
    div $s1, $s2        # HI/LO = A / B
    mflo $s0            # $s0 = LO (Quotient/Result)
    j PrintResult

DivideByZeroError:
    # Print error message or just set result to 0 (simplification)
    li $s0, 0           # Set result to 0
    j PrintResult
    
    # 6. Print Result
PrintResult:
    # Print result ($s0) (Syscall 1)
    add $a0, $s0, $zero
    li $v0, 1
    syscall
    
    # Print newline (Syscall 4)
    li $v0, 4
    la $a0, newline
    syscall
    
    j CalculatorLoop

# 7. Data Section
.data
.asciiz "\n"
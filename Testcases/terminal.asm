.text
main:
    addi $t0, $zero, 65      # 'A'
    sw   $t0, -256($zero)    # 0x3FFFF00 == -256 after truncation
    j    main
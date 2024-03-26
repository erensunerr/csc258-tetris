.data
    displayAddress: .word 0x10008000
    rect_x: .word 3
    rect_y: .word 5
    displayWidth: .word 8 # 2^n = 256, n = 8


.macro getDisplayWidth()
    8
.end_macro

.text
    lw $t0, displayAddress
    li $t1, 0xff0000
    
    lw $t2, rect_x
    lw $t3, rect_y
    
    sll $t2, getDisplayWidth()
    
    
    
    # $a0: first pixel location
    # $a1, length of the line
    # $a2, colour
    # $t0, index of current pixel
    draw_line_function:
    
    
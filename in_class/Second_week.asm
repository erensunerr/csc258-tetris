.data
    displayAddress: .word 0x10008000
    rect_x: .word 3
    rect_y: .word 5
    
.text
    lw $t0, displayAddress
    li $t1, 0xff0000
    
    # $a0: first pixel location
    # $a1, length of the line
    # $a2, colour
    # $t0, index of current pixel
    draw_line_function:
    
    
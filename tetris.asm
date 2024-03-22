# MACROS


.macro push(%from)
    subi $sp, $sp, 4
    sw %from, 0($sp)
.end_macro

.macro pop(%to)
    lw %to, 0($sp)
    addi $sp, $sp, 4
.end_macro

.macro __caller_prep()
    push($ra)
    push($t0)
    push($t1)
    push($t2)
    push($t3)
    push($t4)
    push($t5)
    push($t6)
    push($t7)
    push($t8)
    push($t9)
.end_macro

.macro __caller_restore()
    pop($t9)
    pop($t8)
    pop($t7)
    pop($t6)
    pop($t5)
    pop($t4)
    pop($t3)
    pop($t2)
    pop($t1)
    pop($t0)
    pop($ra)
.end_macro

.macro __callee_prep()
    push($s0)
    push($s1)
    push($s2)
    push($s3)
    push($s4)
    push($s5)
    push($s6)
    push($s7)
.end_macro

.macro __callee_restore()
    pop($s7)
    pop($s6)
    pop($s5)
    pop($s4)
    pop($s3)
    pop($s2)
    pop($s1)
    pop($s0)
.end_macro

# DATA


.data
    DISPLAY_ADDR:
        .word 0x10008000
    # These are in pixels
    DISPLAY_H:
        .byte 128
    DISPLAY_W:
        .byte 64
    UNIT: # sidelength of one block
        .byte 4
    .align 1
    # data + 8
    
    # x and y values are in unit_size dimensions, not pixels
    GAME_AREA_TOP_LEFT:
    GAME_AREA_TOP_LEFT_x:
        .byte 2
    GAME_AREA_TOP_LEFT_y:
        .byte 0
    GAME_AREA_HEIGHT:
        .byte 22
    GAME_AREA_WIDTH:
        .byte 12
    # data + 12
    
    GRID_COLOR:
        .word 0x333230
    CHECKERBOARD_COLOR:
        .word 0x242323
    
    # data + 20
    TET_SIZE: .byte 8 # size for each individual tetramino
    .align 3
    
    # data + 24
    TET:
        # for each tetramino, the least significant 16 bits (= 2 bytes) of the *first word*
        # is the draw zones in a 4x4 grid from top left to bottom right
        # the last 4 bytes is the color
        # so each tetramino is 4 + 4 = 8 bytes
        TET_0:
            .word 0b0000011001100000 # least significant 16 bits
            .word 0x0000ff
        TET_1:
            .word 0b100010001000
                1000
    # GRID:
        # # size: GAME_AREA_W * GAME_AREA_H
        
    # TET_LOOKUP:
        
# CODE


.text
# 0: w x, 1: w y, 2: w color
# values in unit
draw_box:
    lb $t2, UNIT
    
    pop($t0)
    multu $t0, $t0, $t2 # $t0: x in pixels
    
    pop($t1)
    multu $t1, $t1, $t2 # $t1: y in pixels
    
    pop($t7) # $t7 is color
    
    lb $t3, DISPLAY_W
    multu $t1, $t1, $t3 # $t1: change in position due to y coord
    
    add $t0, $t0, $t1 # t0 is the correct pixel location
    # $t0 = UNIT*x + DISPLAY_W*UNIT*y
    
    lb $t8, UNIT
        draw_box_loop_0:
            lb $t9, UNIT
            draw_box_loop_1:
                # draw the pixel at $t0
                lw $t4, DISPLAY_ADDR
                move $t5, $t0
                # This is 4 because the color is 4 bytes, not unit!
                mult $t5, $t5, 4
                add $t4, $t4, $t5
                # Write address is $t4 = DISPLAY_ADDR + 4*$t0
                sw $t7, 0($t4)
                
                addi $t0, $t0, 1
                subi $t9, $t9, 1
                bne $t9, 0, draw_box_loop_1
            subi $t8, $t8, 1
            
            # $t0 = DISPLAY_W - UNIT, so it's the correct value
            add $t0, $t0, $t3
            sub $t0, $t0, $t2
            
            bne $t8, 0, draw_box_loop_0
            
    jr $ra


# 0: w start.x, 1: w start.y, 2: w end.x, 3: w end.y, 4: w color
# dimensions in unit, not pixels!
draw_line:
    pop($t0)
    pop($t1)
    pop($t2)
    pop($t3)
    pop($t4)
    
    # calculate slope
    sub $t5, $t3, $t1
    sub $t6, $t2, $t0
    beq $t6, 0, draw_line_loop_1
    
    div $t5, $t6
    mflo $t5 # $t5 = slope
    
    # $t7 = b = start.y - slope*start.x
    mult $t7, $t5, $t0
    sub $t7, $t1, $t7
    nop
    # draw line
    draw_line_loop_0:
        # y = slope * x + b
        mult $t6, $t5, $t0
        add $t6, $t6, $t7
        
        #draw box
        __caller_prep()
        push($t4)
        push($t6)
        push($t0)
        jal draw_box
        __caller_restore()
        
        addi $t0, $t0, 1
        bne $t0, $t2, draw_line_loop_0
    jr $ra
    
    # if slope is a division by 0, only deal with y
    draw_line_loop_1:
    
        #draw box
        __caller_prep()
        push($t4)
        push($t1)
        push($t0)
        jal draw_box
        __caller_restore()
        
        addi $t1, $t1, 1
        bne $t1, $t3, draw_line_loop_1
    jr $ra

# no arguments
draw_grid:
    # $t1 is start x - units
    # $t2 is start y - units
    # $t3 is end x - units
    # $t4 is end y - units
    li $t1, 0
    lb $t2, GAME_AREA_TOP_LEFT_y
    lb $t4, GAME_AREA_HEIGHT
    add $t4, $t4, $t2
    add $t4, $t4, $t2
    
    lw $t5, GRID_COLOR
    lb $t6, GAME_AREA_TOP_LEFT_x
    
    li $t7, 0
    
    # for each vertical line before the game area, draw a gridline
    draw_grid_loop_0:
        __caller_prep()
        push($t5)
        push($t4)
        push($t1)
        push($t2)
        push($t1)
        jal draw_line
        __caller_restore()
        
        addi $t1, $t1, 1
        bne $t1, $t6, draw_grid_loop_0
        
    # use draw_grid_loop_0 to draw a gridline for each vertical line after
    # the game area
    bne $t7, 0, draw_grid_branch_0
    
    # divide display width by unit to get it in units
    # and not pixels
    lb $t6, DISPLAY_W
    lb $t8, UNIT
    divu $t6, $t8
    mflo $t6
    
    lb $t9, GAME_AREA_WIDTH
    add $t1, $t1, $t9
    
    li $t7, 1
    j draw_grid_loop_0
    
    # if the end gridlines are made jump here
    draw_grid_branch_0:
    
    # draw the bottom line
    li $t0, 0
    lb $t1, GAME_AREA_HEIGHT
    lb $t6, GAME_AREA_TOP_LEFT_y
    add $t1, $t1, $t6
    
    lb $t4, GAME_AREA_TOP_LEFT_x
    add $t4, $t4, $t1
    
    lb $t2, DISPLAY_W
    lb $t3, UNIT
    divu $t2, $t3
    mflo $t2
    
    draw_grid_loop_2:
        __caller_prep()
        push($t5)
        push($t1)
        push($t2)
        push($t1)
        push($t0)
        jal draw_line
        __caller_restore()
        addi $t1, $t1, 1
        blt $t1, $t4, draw_grid_loop_2
    
    # draw the checkerboard inside the game area
    lw $t9, CHECKERBOARD_COLOR
    lb $t0, GAME_AREA_TOP_LEFT_x
    lb $t1, GAME_AREA_TOP_LEFT_y
    lb $t4, GAME_AREA_WIDTH
    lb $t5, GAME_AREA_HEIGHT
    
    add $t2, $t0, $t4 # t2 is the x boundary = game_area_top_left_x + game_area_width
    add $t3, $t1, $t5 # t3 is the y boundary = game_area_top_left_y + game_area_height
    
    draw_grid_loop_1:
        # go through y
        lb $t0, GAME_AREA_TOP_LEFT_x
        
        # add 1 if y index is odd
        andi $t4, $t1, 1
        add $t0, $t0, $t4
        
        draw_grid_loop_1_0:
            # go through x
            __caller_prep()
            push($t9) # color
            push($t1) # y
            push($t0) # x
            jal draw_box
            __caller_restore()
            
            # add 2 to x each round
            addi $t0, $t0, 2
            blt $t0, $t2, draw_grid_loop_1_0
        addi $t1, $t1, 1
        blt $t1, $t3, draw_grid_loop_1
    jr $ra

# 0: w x - from game area top left in units
# 1: w y - "
# 2: w tetramino code, from left to right, top to bottom
# on this image: https://www.researchgate.net/publication/276133486/figure/fig1/AS:1086774763888648@1636118703157/The-standard-naming-convention-for-the-seven-Tetrominoes.jpg
# starting from 0 top left
draw_tet:
    pop($t0)
    pop($t1)
    pop($t2)
    
    lb $t3, TET_SIZE
    mult $t2, $t2, $t3
    la $t3, TET
    add $t2, $t2, $t3
    
    lw $t3, 0($t2) # load the tetramino draw zone from definition
    lw $t4, 4($t2) # load tetramino color
    
    add $t5, $t0, 4 # x boundary
    add $t6, $t1, 4 # y boundary
    
    move $t8, $t0 # x saved
    
    # draw while right shifting
    # from the draw zone
    draw_tet_loop_0:
        move $t0, $t8
        draw_tet_loop_0_0:
            li $t7, 1 # mask for getting which box to draw from drawzone
            and $t7, $t3, $t7 # 1 if drawing 0 otw
            beq $t7, 0, draw_tet_loop_0_0_nodraw
            
            __caller_prep()
            push($t4) # color
            push($t1) # y
            push($t0) # x
            jal draw_box
            __caller_restore()
            
            draw_tet_loop_0_0_nodraw:
            addi $t0, $t0, 1
            srl $t3, $t3, 1
            bne $t0, $t5, draw_tet_loop_0_0
        addi $t1, $t1, 1
        bne $t1, $t6, draw_tet_loop_0
    jr $ra


# 0: x, 1: y, 2: color
# x, y in units, from top left of the
# game area being 0, 0
draw_box_inside_grid:
    jr $ra


.entry main
main:
    __caller_prep()
    jal draw_grid
    __caller_restore()
    
    
    li $t0, 3
    li $t1, 3
    li $t2, 0
    
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal draw_tet
    __caller_restore()
    
exit:
    li $v0, 10
    syscall
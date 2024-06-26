.include "font.asm"

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


.macro get_IPA(%det, %load)
    # %det: 0 -> IPA, 1 -> NEXT_IPA, 2 -> STATIC_IPA, otw unchanged
    beq %det, 0, get_IPA_current
    beq %det, 1, get_IPA_next
    beq %det, 2, get_IPA_static
    j get_IPA_end
    
    get_IPA_current:
        la %load, INTERMEDIATE_PLAYING_AREA
        j get_IPA_end
    get_IPA_next:
        la %load, NEXT_INTERMEDIATE_PLAYING_AREA
        j get_IPA_end
    get_IPA_static:
        la %load, STATIC_INTERMEDIATE_PLAYING_AREA
        j get_IPA_end
    
    get_IPA_end:
.end_macro


# DATA


.data
    
    KEYBOARD_ADDR:
        .word 0xffff0000
    DISPLAY_ADDR:
        .word 0x10015000
    # These are in pixels
    DISPLAY_H:
        .word 512
    DISPLAY_W:
        .word 256
    UNIT: # sidelength of one block - not the unit in bitmap display
        .word 16
    # data + 8
    
    # x and y values are in unit dimensions, not pixels
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
    
    # data + 24
    TET:
        # for each tetramino, the least significant 16 bits (= 2 bytes) of the *first word*
        # is the draw zones in a 4x4 grid from top left (most significant) to bottom right (least significant)
        # the last 4 bytes is the color
        # so each tetramino is 4 + 4 = 8 bytes
        TET_0:
            .word 0b0000011001100000 # least significant 16 bits
            .word 2
        TET_1:
            .word 0b0100010001000100
            .word 3
        # TODO: center align the rest
        TET_2:
            .word 0b0110110000000000
            .word 4
        TET_3:
            .word 0b1100011000000000
            .word 5
        TET_4:
            .word 0b1000100011000000
            .word 6
        TET_5:
            .word 0b0100010011000000
            .word 7
        TET_6:
            .word 0b1110010000000000
            .word 8
    
    INTERMEDIATE_PLAYING_AREA: # (22 + 4) * 12 = 312
        # # size: GAME_AREA_W * GAME_AREA_H
        # address: 1 byte color lookup code
        .space 312
    
    NEXT_INTERMEDIATE_PLAYING_AREA: # will be the intermediate playing area
        # for the next turn, if it satisfies the representation invariants
        .space 312
    
    STATIC_INTERMEDIATE_PLAYING_AREA:
        # this includes the landed tetraminoes
        .space 312
    
    COLOR_LOOKUP:
        .word 0x000000 # checkerboard - 0
        .word 0x242323 # checkerboard - 1
        .word 0x0000ff # tet - 0
        .word 0x00ff00
        .word 0xff0000
        .word 0x00ffff
        .word 0xff00ff
        .word 0xffff00
        .word 0xffffff # tet - 6
    
    STRINGS: # only uppercase and digits are allowed
        SCORE:
            .asciiz "SCORE"
        TETRIS:
            .asciiz "TETRIS"
        PRESS_TO_START_0:
            .asciiz "PRESS S"
        PRESS_TO_START_1:
            .asciiz "TO START"
        GAME_OVER:
            .asciiz "GAME OVER"
        PRESS_TO_RESTART_0:
            .asciiz "PRESS S"
        PRESS_TO_RESTART_1:
            .asciiz "TO PLAY AGAIN"
        TOP_SCORES:
            .asciiz "TOP SCORES"
    .align 2
    HIGH_SCORES:
        .word 0
        .word 0
        .word 0
        .word 0
        .word 0
.text
# 0: w x, 1: w y, 2: w color
# values in unit
draw_box:
    lw $t2, UNIT
    
    pop($t0)
    multu $t0, $t0, $t2 # $t0: x in pixels
    
    pop($t1)
    multu $t1, $t1, $t2 # $t1: y in pixels
    
    pop($t7) # $t7 is color
    lw $t3, DISPLAY_W
    multu $t1, $t1, $t3 # $t1: change in position due to y coord
    
    add $t0, $t0, $t1 # t0 is the correct pixel location
    # $t0 = UNIT*x + DISPLAY_W*UNIT*y
    
    lw $t8, UNIT
    draw_box_loop_0:
        lw $t9, UNIT
        draw_box_loop_1:
            # draw the pixel at $t0
            lw $t4, DISPLAY_ADDR
            move $t5, $t0
            # This is 4 because the color is 4 bytes, not unit!
            multu $t5, $t5, 4
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
    lw $t6, DISPLAY_W
    lw $t8, UNIT
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
    
    lw $t2, DISPLAY_W
    lw $t3, UNIT
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
    jr $ra
    

# $a0: which playing area to initialize
# no returns
initialize_intermediate_playing_area:
    li $t1, 0 # y counter
    lb $t2, GAME_AREA_WIDTH # x limit
    lb $t3, GAME_AREA_HEIGHT # y limit
    
    addi $t3, $t3, 4
    
    li $t9, 0 # color code should alternate between 1 and 0
    li $t8, 1 # used as flag for alternating colors
    
    la $t5, INTERMEDIATE_PLAYING_AREA
    
    initialize_intermediate_playing_area_0:
        li $t0, 0 # x counter
        move $t7, $t9
        initialize_intermediate_playing_area_1:
            __caller_prep()
            push($t7)
            push($t1)
            push($t0) # a0 is passed directly to WIPAB
            jal write_intermediate_playing_area_box
            __caller_restore()
            
            addi $t7, $t7, 1
            and $t7, $t7, $t8
            
            addi $t0, $t0, 1
            blt $t0, $t2, initialize_intermediate_playing_area_1
    
        addi $t9, $t9, 1
        and $t9, $t9, $t8
    
        addi $t1, $t1, 1
        blt $t1, $t3, initialize_intermediate_playing_area_0
    jr $ra
    
# 0: x
# 1: y
# a0: which IPA to read from
# returns: color lookup code in $v0
read_intermediate_playing_area_box:
    pop($t0) # x
    pop($t1) # y
    lb $t2, GAME_AREA_WIDTH
    
    multu $t1, $t1, $t2
    add $t0, $t0, $t1
    
    get_IPA($a0, $t2)
    
    add $t0, $t0, $t2
    
    lb $t2, 0($t0) # t2 is the color lookup code
    
    move $v0, $t2
    jr $ra
     
     
# 0: color lookup code
# returns: 0: color, in $v0
lookup_color:
    pop($t2)
    la $t0, COLOR_LOOKUP
    li $t1, 4
    mult $t2, $t2, $t1
    add $t0, $t0, $t2 # t0 is the color address
    
    lw $v0, 0($t0)
    jr $ra
 
 # 0: x
 # 1: y
 # 2: color lookup code
 # a0: which intermediate playing area to write on
 # returns nothing
 write_intermediate_playing_area_box:
    pop($t0) # x
    pop($t1) # y
    pop($t3) # color lookup code
    
    lb $t2, GAME_AREA_WIDTH
    
    multu $t1, $t1, $t2
    add $t0, $t0, $t1
    
    get_IPA($a0, $t2)
    
    add $t0, $t0, $t2   # $t0 is the write address
    
    sb $t3, 0($t0) # t3 is the color lookup code
    jr $ra


# x : 0
# y : 1
# returns nothing
write_intermediate_playing_area_box_to_display:
    pop($t0) # x
    pop($t1) # y
    
    __caller_prep()
    li $a0, 0 # when writing to display, always read from the current IPA
    push($t1)
    push($t0)
    jal read_intermediate_playing_area_box
    __caller_restore()
   
   move $t3, $v0 # $t3 is the color lookup code
   
   __caller_prep()
   push($t3)
   jal lookup_color
   __caller_restore()
   move $t3, $v0 # $t3 is the color to write
   
   blt $t1, 4, return_write_intermediate_playing_area_box_to_display
   
   subi $t1, $t1, 4
   # calculate the address, in display, to write
   
   lb $t2, GAME_AREA_TOP_LEFT_x
   add $t0, $t0, $t2
   
   lb $t2, GAME_AREA_TOP_LEFT_y
   add $t1, $t1, $t2
   
   __caller_prep()
   push($t3)
   push($t1)
   push($t0)
   jal draw_box
   __caller_restore()
   
   return_write_intermediate_playing_area_box_to_display:
   jr $ra
   
# no arguments
draw_intermediate_playing_area:
    li $t0, 0 # x address of the intermediate playing area
    li $t1, 4 # y address of the intermediate playing area
    
    lb $t5, GAME_AREA_WIDTH # x - limit
    lb $t6, GAME_AREA_HEIGHT # y - limit
    addi $t6, $t6, 4
    
    draw_intermediate_playing_area_loop_0:
        # go through each row
        li $t0, 0
        draw_intermediate_playing_area_loop_1:
            # go through each box
            __caller_prep()
            push($t1)
            push($t0)
            jal write_intermediate_playing_area_box_to_display
            __caller_restore()
            
            addi $t0, $t0, 1
            blt $t0, $t5, draw_intermediate_playing_area_loop_1 
            
        addi $t1, $t1, 1
        blt $t1, $t6, draw_intermediate_playing_area_loop_0
    jr $ra


# 0: tet_code
# returns
# 0: tet draw zone in $v0
# 1: tet color code in $v1
get_tet:
    pop($t0)
    li $t3, 8 # memory size of a tetramino object = 2 words
    
    mult $t0, $t0, $t3
    la $t3, TET
    add $t0, $t0, $t3 # t2 is the tetramino address
    
    lw $v0, 0($t0) # load the tetramino draw zone from definition
    lw $v1, 4($t0) # load tetramino color code
    jr $ra
    
# 0: x
# 1: y
# 2: tet code
# 3: rotation -> 0 for up, then +1 for each left rotation
# returns: $v0: 0 if written, -1 if it went out of bounds, -2 if overwriting an existing cell
draw_tet:
    pop($t0)
    pop($t1)
    pop($t2) # t2 has the tet code
    
    __caller_prep()
    push($t2)
    jal get_tet
    __caller_restore()
    
    pop($t2) # t2 has the rotation
    
    __callee_prep()
    
    move $t3, $v0 # load the tetramino draw zone from definition
    move $t4, $v1 # load tetramino color code
    
    
    # perform rotations
    beq $t2, 0, draw_tet_no_rotation
    draw_tet_rotate_left:
        __caller_prep()
        push($t3)
        jal rotate_left
        __caller_restore()
        move $t3, $v0
        subi $t2, $t2, 1
        bne $t2, 0, draw_tet_rotate_left
        
    draw_tet_no_rotation:
    
    add $t5, $t0, 3 # x boundary
    add $t6, $t1, 3 # y boundary
    
    move $t8, $t5 # x saved
    
    lb $s0, GAME_AREA_WIDTH # checkers
    lb $s1, GAME_AREA_HEIGHT
    addi $s1, $s1, 4
    
    # draw while right shifting
    # from the draw zone
    draw_tet_loop_0:
        move $t5, $t8
        draw_tet_loop_0_0:
            li $t7, 1 # mask for getting which box to draw from drawzone
            and $t7, $t3, $t7 # 1 if drawing 0 otw
            beq $t7, 0, draw_tet_loop_0_0_nodraw
            
            blt $t5, 0, draw_tet_failure
            blt $t6, 0, draw_tet_failure
            bge $t5, $s0, draw_tet_failure
            bge $t6, $s1, draw_tet_failure
            
            __caller_prep()
            push($t6)
            push($t5)
            li $a0, 1 # read from next IPA
            jal read_intermediate_playing_area_box
            __caller_restore()
            
            # 0 or 1 is okay to overwrite, but nothing else!
            andi $t9, $v0, -2
            bne $t9, 0, draw_tet_failure_overwrite
            
            __caller_prep()
            push($t4) # color
            push($t6) # y
            push($t5) # x
            li $a0, 1 # write to next intermediate playing area
            jal write_intermediate_playing_area_box
            __caller_restore()
            
            draw_tet_loop_0_0_nodraw:
            subi $t5, $t5, 1
            srl $t3, $t3, 1
            bge $t5, $t0, draw_tet_loop_0_0
        subi $t6, $t6, 1
        bge $t6, $t1, draw_tet_loop_0
        
    draw_tet_success:
        __callee_restore()
        li $v0, 0
        jr $ra
    
    draw_tet_failure:
        __callee_restore()
        li $v0, -1
        jr $ra
    
    draw_tet_failure_overwrite:
        __callee_restore()
        li $v0, -2
        jr $ra
    
    
# 0: area address 0 (values taken from) -> 0 if current, otw next
# 1: area address 1 (values written to) -> 0 if current otw, next
copy_intermediate_game_area:
    li $t0, 0
    pop($t1)
    pop($t2)
    
    get_IPA($t1, $t1)
    get_IPA($t2, $t2)
    
    beq $t1, $t2, copy_intermediate_game_area_exit
    
    copy_intermediate_game_area_0:
        lb $t3, 0($t1)
        sb $t3, 0($t2)
        
        addi $t1, $t1, 1
        addi $t2, $t2, 1
        addi $t0, $t0, 1
        
        blt $t0, 312, copy_intermediate_game_area_0
        
    copy_intermediate_game_area_exit:
        jr $ra

# 0: draw zone
# 1: bit number
# 0 or 1 in $v0
get_bit:
    pop($t0)
    pop($t1)
    beq $t1, 0, get_bit_noloop
    get_bit_loop:
        srl $t0, $t0, 1
        subi $t1, $t1, 1
        bgt $t1, 0, get_bit_loop
        
    get_bit_noloop:
        andi $v0, $t0, 1 # get the last bit
    jr $ra
    
    
# 0: draw zone
# v0 contains the counterclockwise rotated draw zone
rotate_left:
    pop($t0)
    li $t1, 12
    li $t2, 0
    li $v0, 0
    rotate_left_0:
        rotate_left_0_0:
            nop
            __caller_prep()
            push($t1)
            push($t0)
            jal get_bit
            __caller_restore()
            sll $t2, $t2, 1
            or $t2, $t2, $v0 # or the result
            subi $t1, $t1, 4
            nop
            bgt $t1, -1, rotate_left_0_0
        addi $t1, $t1, 17
        nop
        bne $t1, 16, rotate_left_0
    move $v0, $t2
    jr $ra


# $a0: which IPA to do this on
# returns a bitmap (1 for full, 0 for not) from bottom to 4th row (first displayed) in $v0
# $v1: number of rows removed
detect_full_rows:
  lb $t1, GAME_AREA_HEIGHT # start from the bottom row
  addi $t1, $t1, 3
  li $t2, 0
  lb $v1, GAME_AREA_HEIGHT
  detect_full_rows_loop_y:
    lb $t0, GAME_AREA_WIDTH
    subi $t0, $t0, 1
    li $t3, 1
    detect_full_rows_loop_x:
        __caller_prep()
        push($t1)
        push($t0)
        jal read_intermediate_playing_area_box
        __caller_restore()
        and $t4, $v0, -2 # remove the last bit (0 or 1)
        # if $t4 is 0 this box is empty
        beq $t4, 0, detect_full_rows_empty # this row is empty
        subi $t0, $t0, 1
        bne $t0, 0, detect_full_rows_loop_x
        j detect_full_rows_y_end
    detect_full_rows_empty:
    li $t3, 0
    subi $v1, $v1, 1
    detect_full_rows_y_end:
    or $t2, $t2, $t3
    sll $t2, $t2, 1
    subi $t1, $t1, 1
    bge $t1, 4, detect_full_rows_loop_y
    
    # when the last one is hit, the rows will be shifted anyway
    # so right shift
    srl $t2, $t2, 1
    move $v0, $t2
    jr $ra


# $a0: IPA code
#0: row number
remove_single_row:
    pop($t1)
    lb $t0, GAME_AREA_WIDTH
    subi $t0, $t0, 1 
    
    andi $t3, $t1, 1 # last bit is color code
    
    # Replace the row with checkerboard pattern
    remove_single_row_loop_0:
        # invert $t3
        addi $t3, $t3, 1
        andi $t3, $t3, 1
        
        __caller_prep()
        push($t3)
        push($t1)
        push($t0)
        jal write_intermediate_playing_area_box
        __caller_restore()
        
        subi $t0, $t0, 1
        bgez $t0, remove_single_row_loop_0
        
    # Move the rows above down   
    remove_single_row_move_0:
        # Go current row to 4
        subi $t2, $t1, 1
        lb $t0, GAME_AREA_WIDTH
        subi $t0, $t0, 1 # subtract for 0 based indexing
        andi $t3, $t1, 1 # last bit is color code for checkerboard replacing
        remove_single_row_move_1:
            # read from row $t2, write to row $t1
            __caller_prep()
            push($t2)
            push($t0)
            jal read_intermediate_playing_area_box
            __caller_restore()
            
            # if not a tetramino, don't move it
            andi $t5, $v0, -2
            beq $t5, 0, remove_single_row_nomove
            
            __caller_prep()
            push($v0)
            push($t1)
            push($t0)
            jal write_intermediate_playing_area_box
            __caller_restore()
            
            # replace the moved square
            add $t3, $t2, $t0
            andi $t3, $t3, 1
            
            __caller_prep()
            push($t3)
            push($t2)
            push($t0)
            jal write_intermediate_playing_area_box
            __caller_restore()
            
            remove_single_row_nomove:
            
            subi $t0, $t0, 1
            bgez $t0, remove_single_row_move_1
        subi $t1, $t1, 1
        bge $t1, 3, remove_single_row_move_0
    jr $ra
        
        
# 0: number produced by detect full rows
remove_rows:
    pop($t0)
    lb $t1, GAME_AREA_HEIGHT
    addi $t1, $t1, 4
    li $t2, 4 # height counter
    
    remove_rows_loop_0:
        andi $t4, $t0, 1
        beq $t4, 0, remove_rows_noremove
        remove_rows_remove:
        
        __caller_prep()
        push($t2) 
        jal remove_single_row
        __caller_restore()
        
        remove_rows_noremove:
        srl $t0, $t0, 1
        addi $t2, $t2, 1
        blt $t2, $t1, remove_rows_loop_0
    jr $ra

# 0: w x, 1: w y, 2: ascii code
# x and y in unit length
draw_letter:
    pop($t0)
    pop($t1)
    pop($t2)
    
    # check if $t2 is a letter, digit or unknown
    bgt $t2, 90, draw_letter_unknown
    blt $t2, 48, draw_letter_unknown
    subi $t4, $t2, 65
    bgez $t4, draw_letter_letter
    blt $t4, -6, draw_letter_digit
    j draw_letter_unknown
    
    # Select the correct type of letter / digit
    # $t2 has the address of the 16*16 glyph
    draw_letter_letter:
        subi $t2, $t2, 65
        multu $t2, $t2, 64
        la $t4, CHARACTERS
        add $t2, $t2, $t4
        j draw_letter_end_switch
    draw_letter_digit:
        subi $t2, $t2, 48
        multu $t2, $t2, 64
        la $t4, DIGITS
        add $t2, $t2, $t4
        j draw_letter_end_switch
    draw_letter_unknown:
        la $t2, UNKNOWN
        
    draw_letter_end_switch:
    lw $t4, DISPLAY_ADDR
    lw $t5, DISPLAY_W
    multu $t5, $t5, $t1
    add $t5, $t5, $t0
    
    lw $t8, UNIT
    multu $t5, $t5, $t8 # unit sized boxes
    multu $t5, $t5, 4 # 4 byte colors
    add $t4, $t4, $t5
    # t4 has the address we should start writing from
    
    lw $t5, DISPLAY_W # delta to add for each row
    sub $t5, $t5, $t8
    multu $t5, $t5, 4
    
    li $t9, 0xffffff # white
    li $t8, 0 # black
    
    li $t1, 0
    draw_letter_row:
        li $t0, 0
        lw $t3, 0($t2)
        draw_letter_pixel:
            andi $t6, $t3, 65536 # only keep the 16th bit
            beq $t6, 0, draw_letter_pixel_passive
            
            draw_letter_pixel_active:
                sw $t9, 0($t4)
                j draw_letter_pixel_end
                
            draw_letter_pixel_passive:
                sw $t8, 0($t4)
                
            draw_letter_pixel_end:
            sll $t3, $t3, 1
            addi $t0, $t0, 1
            addi $t4, $t4, 4
            blt $t0, 16, draw_letter_pixel
            
        add $t4, $t4, $t5
        add $t2, $t2, 4
        addi $t1, $t1, 1
        blt $t1, 16, draw_letter_row
    jr $ra

# 0: x
# 1: y
# 2: zero terminated ascii string address
# you are responsible for choosing a good location
# it will wrap around and cause trouble !!
write_word:
    pop($t0)
    pop($t1)
    pop($t2)
    nop
    write_word_loop:
        lb $t3, 0($t2)
        beq $t3, 0, write_word_done
        __caller_prep()
        push($t3)
        push($t1)
        push($t0)
        jal draw_letter
        __caller_restore()
        addi $t2, $t2, 1
        addi $t0, $t0, 1
        j write_word_loop
        
    write_word_done:
        jr $ra

# 0: x
# 1: y
# 2: number
write_number:
    pop($t0)
    pop($t1)
    pop($t2)
    li $t3, 1000
    li $t9, 10
    write_number_loop:
        divu $t2, $t3
        # t2 gets the remainder
        # t4 gets the other one
        # print t4
        mfhi $t2
        mflo $t4
        addi $t4, $t4, 48
        
        __caller_prep()
        push($t4)
        push($t1)
        push($t0)
        jal draw_letter
        __caller_restore()
        
        divu $t3, $t9
        # t3 gets the other one
        mflo $t3
        addi $t0, $t0, 1
        bne $t3, 0, write_number_loop
    jr $ra


# 0: animate if zero
make_modal_bg:
    pop($t4)
    lw $t0, UNIT
    lw $t8, DISPLAY_H
    div $t8, $t0
    mflo $t8
    lw $t9, DISPLAY_W
    div $t9, $t0
    mflo $t9
    
    lw $t7, GRID_COLOR
    li $t6, 0
    li $t5, 0
    
    make_modal_background_loop:
        __caller_prep()
        push($t7)
        push($t6)
        push($t9)
        push($t6)
        push($t5)
        jal draw_line
        __caller_restore()
        
        # TODO: uncomment this line
        # wait - animation
        bne $t4, 0, make_modal_background_skip_animation
        li $v0, 32
        li $a0, 180
        syscall
        
        make_modal_background_skip_animation:
        addi $t6, $t6, 1
        bne $t6, $t8, make_modal_background_loop
    jr $ra
    
    
# 0: new score to insert
insert_high_score:
    pop($t0)
    la $t1, HIGH_SCORES
    move $t3, $t1
    addi $t3, $t3, 20 # limit
    
    # go through each one, insert $t0 if its higher than the one, swap the rest
    insert_high_score_loop_0:
        lw $t2, 0($t1)
        add $t1, $t1, 4
        bgt $t1, $t3, insert_high_score_exit
        blt $t0, $t2, insert_high_score_loop_0
        sw $t0, -4($t1)
    
    insert_high_score_loop_1:
        lw $t4, 0($t1)
        sw $t2, 0($t1)
        add $t1, $t1, 4
        move $t2, $t4
        ble $t1, $t3, insert_high_score_loop_1
                
    insert_high_score_exit:
    jr $ra

# runs the game loop
game_loop:
    # game_loop_setup:
    __caller_prep()
    jal draw_grid
    __caller_restore()
    
    li $t0, 1
    li $t1, 25
    la $t2, SCORE
    
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    
    li $a0, 0
    __caller_prep() # initialize current IPA
    jal initialize_intermediate_playing_area
    __caller_restore()
    
    li $a0, 2
    __caller_prep() # initialize static
    jal initialize_intermediate_playing_area
    __caller_restore()
    
    # score starts from 0
    li $s0, 0
    
    game_loop_tetramino_landed:
        # check if game is over
        blt $t1, 4, game_loop_exit
    
        # # copy current to static
        li $t3, 0
        li $t4, 2
        
        __caller_prep()
        push($t4)
        push($t3)
        jal copy_intermediate_game_area
        __caller_restore()
        
        # detect full rows in static and remove them
        li $a0, 2
        __caller_prep()
        jal detect_full_rows
        __caller_restore()
        
        multu $v1, $v1, 16
        add $s0, $s0, $v1
        
        
        li $t0, 1
        li $t1, 26
        move $t2, $s0
        
        __caller_prep()
        push($t2)
        push($t1)
        push($t0)
        jal write_number
        __caller_restore()
        
        __caller_prep()
        push($v0)
        jal remove_rows
        __caller_restore()
        
        
        # change tet number and reset the x and y
        li $t0, 4 # x
        li $t1, 0 # y
        li $t5, 0 # rotation
        li $t9, 0 # loop counter
        
        # Generate random tet code
        li $v0, 41
        li $a0, 0
        syscall   
        divu $a0, $a0, 7 # modulo by 7
        mfhi $t2
        
        # For debugging, set tetramino to 1
        # TODO: comment this line for random tetraminos
        # li $t2, 1
        
    game_loop_loop:
        __caller_prep()
        jal draw_intermediate_playing_area
        __caller_restore()
        
        # copy static to next
        li $t3, 2
        li $t4, 1
        
        __caller_prep()
        push($t4)
        push($t3)
        jal copy_intermediate_game_area
        __caller_restore()
        
        # Save the values before trying the change
        push($t0)
        push($t1)
        push($t5)
        
        # apply gravity
        addi $t9, $t9, 1
        blt $t9, 31, skip_gravity
        li $t9, 0
        addi $t1, $t1, 1
        
        # skip keyboard events if gravity is applied
        j game_loop_loop_no_events
        
        skip_gravity:
        
        # Check keyboard for actions!
        lw $t3, KEYBOARD_ADDR
        lw $t4, 0($t3)
        bne $t4, 1, game_loop_loop_no_events
        lw $t4, 4($t3)
        
        beq $t4, 0x61, pressed_key_is_a
        beq $t4, 0x73, pressed_key_is_s
        beq $t4, 0x64, pressed_key_is_d
        beq $t4, 0x71, pressed_key_is_q
        beq $t4, 0x77, pressed_key_is_w
        
        b game_loop_loop_no_events
        
        pressed_key_is_a:
            subi $t0, $t0, 1 # x - 1
            b game_loop_loop_no_events
        pressed_key_is_s:
            addi $t1, $t1, 1 # y - 1
            b game_loop_loop_no_events
        pressed_key_is_d:
            addi $t0, $t0, 1 # x + 1
            b game_loop_loop_no_events
        pressed_key_is_q:
            j exit # exit
        pressed_key_is_w:
            addi $t5, $t5, 1 # rotate + 1
            div $t5, $t5, 4
            mfhi $t5
            b game_loop_loop_no_events
        
        game_loop_loop_no_events:
        
        __caller_prep() # draws to next
        push($t5) # rotation
        push($t2) # tet code
        push($t1) # y
        push($t0) # x
        jal draw_tet
        __caller_restore()
        
        beq $v0, 0, game_loop_loop_valid_next
        
        # game_loop_loop_invalid_next:
        
        # check if the tetramino is landed by checking if the cause of the
        # invalidation is a change in y.
        lw $t3, 4($sp) # last valid y value
        bne $t1, $t3, game_loop_tetramino_landed
        
        # restore the values
        pop($t5)
        pop($t1)
        pop($t0)
        j game_loop_loop_after
        
        game_loop_loop_valid_next:
        # if it's valid, copy next to current
        li $t3, 1
        li $t4, 0
        
        __caller_prep()
        push($t4)
        push($t3)
        jal copy_intermediate_game_area
        __caller_restore()
        
        # trash the saved t0 and t1 values
        addi $sp, $sp, 12
        
        game_loop_loop_after:
        # sleep for $a0 milliseconds
        li $a0, 8
        li $v0, 32
        syscall
        
        b game_loop_loop
        
    game_loop_exit:
        __caller_prep()
        push($s0)
        jal insert_high_score
        __caller_restore()
        
        __callee_restore()
        jr $ra

start_game_modal:
    li $t0, 0
    __caller_prep()
    push($t0)
    jal make_modal_bg
    __caller_restore()

    li $t0, 5
    li $t1, 8
    la $t2, TETRIS
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    li $t0, 5
    li $t1, 20
    la $t2, PRESS_TO_START_0
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    li $t0, 4
    li $t1, 21
    la $t2, PRESS_TO_START_1
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    no_s:
        lw $t3, KEYBOARD_ADDR
        lw $t4, 0($t3)
        bne $t4, 1, no_s
        lw $t4, 4($t3)
        beq $t4, 0x71, exit
        bne $t4, 0x73, no_s # s
    
    jr $ra

restart_game_modal:
    li $t0, 0
    __caller_prep()
    push($t0)
    jal make_modal_bg
    __caller_restore()
    
    li $t0, 4
    li $t1, 6
    la $t2, GAME_OVER
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    li $t0, 5
    li $t1, 24
    la $t2, PRESS_TO_RESTART_0
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    li $t0, 2
    li $t1, 25
    la $t2, PRESS_TO_RESTART_1
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    li $t0, 4
    li $t1, 9
    la $t2, TOP_SCORES
    __caller_prep()
    push($t2)
    push($t1)
    push($t0)
    jal write_word
    __caller_restore()
    
    li $t3, 0
    la $t5, HIGH_SCORES
    restart_game_modal_high_scores:
        li $t0, 5
        multu $t1, $t3, 2
        addi $t1, $t1, 12
        
        # write score label 1, 2, 3...
        addi $t2, $t3, 49
        __caller_prep()
        push($t2)
        push($t1)
        push($t0)
        jal draw_letter
        __caller_restore()
        
        
        # write score next to it
        addi $t0, $t0, 2
        lw $t2, 0($t5)
        __caller_prep()
        push($t2)
        push($t1)
        push($t0)
        jal write_number
        __caller_restore()
    
        addi $t3, $t3, 1
        addi $t5, $t5, 4
        bne $t3, 5, restart_game_modal_high_scores
        
    no_s:
        lw $t3, KEYBOARD_ADDR
        lw $t4, 0($t3)
        bne $t4, 1, no_s
        lw $t4, 4($t3)
        beq $t4, 0x71, exit
        bne $t4, 0x73, no_s # s
    
    jr $ra
    

.entry main
# TODO: 1. high scores
# TODO: 2. put a random tetramino on the welcome screen and animate

main:
    __caller_prep()
    jal start_game_modal
    __caller_restore()
restart:
    __caller_prep()
    jal game_loop
    __caller_restore()
    
    
    __caller_prep()
    jal restart_game_modal
    __caller_restore()
    
    li $t0, 1
    __caller_prep()
    push($t0)
    jal make_modal_bg
    __caller_restore()
    
    b restart
    
exit:
    li $v0, 10
    syscall
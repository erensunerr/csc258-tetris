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
    # if %det == 0, return the address of the normal IPA, next IPA otw
    beq %det, 0, get_IPA_next
    
    la %load, INTERMEDIATE_PLAYING_AREA
    j get_IPA_end
    get_IPA_next:
        la %load, NEXT_INTERMEDIATE_PLAYING_AREA
    get_IPA_end:
.end_macro

# DATA

.data
    KEYBOARD_ADDR:
        .word 0xffff0000
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
    
    # data + 24
    TET:
        # for each tetramino, the least significant 16 bits (= 2 bytes) of the *first word*
        # is the draw zones in a 4x4 grid from top left to bottom right
        # the last 4 bytes is the color
        # so each tetramino is 4 + 4 = 8 bytes
        TET_0:
            .word 0b1100110000000000 # least significant 16 bits
            .word 2
        TET_1:
            .word 0b1000100010001000
            .word 3
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
        
    CURR_TET:
        .word 0 # tet code
        .word 0 # x
        .word 0 # y
        .word 0 # rotation 0
        
    NEXT_TET:
        .word 0 # tet code
 
; Build instructions: please se README_BUILD.md

INCLUDE "pre.asm"

INCLUDE "defs.asm"

; addresses


; ------------------------------------------------------------------------------
BANK 0
BASE $8000

FROM $8BE5
; calculates screen y position of object X.
calc_screen_y:

FROM $8D70
; input:
; X is the y-position of the reference player on screen.
; $00D0 is the current camera speed
adjust_camera_speed:

FROM $95B5
read_joysticks:

ifdef NO_AUTO_SCROLL
    FROM $8D81
        LDA camera_speed
        DEY
        BEQ skip_camcheck
        CMP $8D15,Y
        BCC inc_auto_scroll
    skip_camcheck:
        CPX #$0F
        BCC rts_auto_scroll
        LDA camera_speed
        BEQ rts_auto_scroll
        DEC camera_speed
        BEQ rts_auto_scroll
        DEC camera_speed
        RTS
    inc_auto_scroll:
        INC camera_speed
    rts_auto_scroll:
        RTS
    if $ > $8d9D
        error "no-autoscroll hack space exceeded"
    endif
endif

ifdef UNITILE

    FROM $db36:
    next0:
        LDY #$0
        LDA ($00),Y
        TAY
        INC $0
        BNE next0rts
        INC $1
    next0rts:
        TYA
        RTS
    
    unitile_calc_prologue:
        ; store registers
        TXA
        PHA
        TYA
        PHA
        LDA $0
        PHA
        LDA $1
        PHA
        LDA $2
        PHA
        LDA $3
        PHA
        LDA $4
        PHA
        LDA $5
        PHA
        
        LDA current_level
        ASL
        TAY
        LDA level_table,Y
        STA $0
        ;LDA level_table+1,Y
        ;STA $1

        SEC
        LDA level_data
        SBC $0
        LSR
        LSR
        ASL
        STA $0
        DEC $0
        DEC $0 ; now contains the current macro row idx * 0x2
        
        ; determine med row idx
        LDA $5C9
        LSR
        LSR
        LSR
        LSR
        AND #$1
        ORA $0
        STA $2 ; now contains med row idx
        
    unitile_calc:
        ; read data up to the current point
        LDA #$0
        STA $3
        STA $4
    
        LDA current_level
        ifndef SINGLE_UNITILE_CHUNK_PER_LEVEL
            ; Y <- ((current_level * 4) | (med_row_idx / 16)) << 1
            ; $3:4 = 16 * (med_row_idx / 16) * 16
            ; if the size of a level is ever extended, this logic must be adjusted or disabled.
            ASL
            ASL
            STA $0
            LDA $2
            LSR
            LSR
            LSR
            LSR
            AND #$3 ; paranoia
            STA $4
            ORA $0
        endif
        ASL
        TAY
        
        ; get the pointer to the start of the med-tile data chunk for Y.
        LDA unitile_level_table,Y
        STA $0
        LDA unitile_level_table+1,Y
        STA $1
        
        ; if pointer is 0000, early-out.
        ORA $0
        BEQ jmp_to_unitile_calc_epilogue
    
    read_bytecode:
        JSR next0
        CMP #$0 ; 0 -> we're done.
        BEQ unitile_calc_epilogue
        CMP #$1 ; -> skip the next byte in tiles
        BEQ bytecode_skip
        CMP #$3
        BEQ bytecode_skip_1
        
        AND #$E0
        TAX
        
        ; calculate if the current patch row matches the placement row
        LDA $3
        LSR
        LSR
        LSR
        LSR
        STA $5
        LDA $4
        ASL
        ASL
        ASL
        ASL
        ORA $5
        
        CMP $2
        BCC skip_one_tile
        BEQ apply_if_matches
    jmp_to_unitile_calc_epilogue:
        JMP unitile_calc_epilogue ; already past us.. no need to bother continuing
    
    apply_if_matches:
        ; check if normal/hardmode/hellmode flag matches.
        TXA ; retrieves header byte
        BEQ apply ; 0 means all modes are okay
        BIT game_state_b
        
        BVC +
        AND #$20
        BNE skip_one_tile ; skip
        BEQ apply         ; matches
        ; -----
        
      + BPL +
        AND #$40
        BNE skip_one_tile ; skip
        BEQ apply         ; matches
        ; -----
    
      + AND #$80
        BNE skip_one_tile ; skip
    
    apply:
        ; stash $2
        LDA $2
        PHA
        
        ; $2 <- #$f0 - ($2 << 4)
        ASL
        ASL
        ASL
        ASL
        STA $2
        
        SEC
        LDA #$F0
        SBC $2
        STA $2
        
        ; get x offset, add to $2
        LDA $3
        AND #$f
        CLC
        ADC $2
        TAX
        
        ; restore $2
        PLA
        STA $2
        
        JSR next0
        STA $600,X
        JMP read_bytecode
        
        skip_one_tile:
        ; ignore this one
        JSR next0
        
        finish_read_one_tile:
        JMP read_bytecode
    
    bytecode_skip_1:
        LDA #$0
        BEQ bytecode_skip_add; guaranteed
    
    bytecode_skip:
        JSR next0
    bytecode_skip_add:
        SEC
        ADC $3
        STA $3
        BCC read_bytecode
        INC $4
        JMP read_bytecode
        
    unitile_calc_epilogue:
        ; restore registers
        PLA
        STA $5
        PLA
        STA $4
        PLA
        STA $3
        PLA
        STA $2
        PLA
        STA $1
        PLA
        STA $0
        PLA
        TAY
        PLA
        TAX
        ; unhacked did this.
        LDA $D2
        AND #$03
        
        ; return from unitile calculation
        RTS
        
    if $ > $DC48
        error "unitile patch space exceeded"
    endif
    
    FROM $DC48
        unitile_level_table:
endif

; executes the next commands for track X.
FROM $9762
mus_advance_track:

; executes the opcode at nibble $a6:a7
FROM $931F
mus_execute_opcode:

; jumps to the music opcode Y.
FROM $93AE
mus_exec_opY:

; the code for the "subroutine" opcode
FROM $944C
mus_op_sub:

; the code for the "repeat" opcode.
FROM $947F
mus_op_repeat:

; sets the current song to A
FROM $97AA
set_music:

; resets all music variables to their default values.
FROM $9713
reset_music_vars:

; ------------------------------------------------------------------------------
BANK 1
BASE $C000

ifdef NO_BOUNCY_LANDINGS
    FROM $D5D7
        db 0
endif

; this subroutine mirrors a med-tile (16x16).
; most med-tiles mirror by flipping the least bit.
; med-tiles below $1E flip specially (mirror_tile_special)
FROM $F63F
mirror_tile:

FROM $F654
mirror_tile_special:

; this possibly checks for contact with the 4 players for the current object.
FROM $A28A
contact_players:

; this possibly checks for terrain collision?
FROM $A0BA
terrain_collision:

FROM $CAAD
read_4_bits:

FROM $CAB1
read_1_bit:

FROM $CAB5
read_5_bits:

FROM $CAB7
read_y_bits:

FROM $DAD0:
level_table:

; multiplies A and Y, stores the result in $a6:a7.
FROM $EA97
multiply:

; loads (into A) the nth nibble (half-byte) starting from $8000, and then increments n,
; where n is $a6:$a7.
FROM $EAA3:
load_nibble:

; as above, but loads two nibbles (into one byte)
FROM $EAC5:
load_nibble_byte:

; as above, but loads 3 consecutive nibbles
; A <- byte, Y <- nibble
FROM $EAD6:
read_byte_and_nibble:

; adds A to the nibble index $A6:A7
FROM $EA7C:
nibble_advance:

; subtracts A from the nibble index $A6:A7
FROM $EA89:
load_deadvance:

;sets the medtile data pointers EF, etc. to values from F883 onwards.
FROM $F6DE
set_medtile_data_pointers:

FROM $F30D
start_stage:

ifdef UNITILE
    FROM $F620
        JSR unitile_calc_prologue
        NOP
endif
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

FROM $95B5
read_joysticks:

ifdef NO_AUTO_SCROLL
    FROM $8D15
        db $00
        db $44
        
    FROM $8D91
        db $F0
        db $09
        db $E0
        db $0F
        db $90
        db $05
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
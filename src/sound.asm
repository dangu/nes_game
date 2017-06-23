	.rsset $0300 ;sound engine variables will be on the $0300 page of RAM

sound_disable_flag  .rs 1   ;a flag variable that keeps track of whether the sound engine is disabled or not.
                            ;if set, sound_play_frame will return without doing anything.
	.bank 0
	.org $8000
	
sound_data:
    .byte C3, E3, G3, B3, C4, E4, G4, B4, C5 ; Cmaj7 (CEGB)

sound_init:
	lda	#$0F
	sta $4015 ; Enable Square 1&2, Triangle and Noise

	lda #$30
	sta $4000	; Set Square 1 volume to 0
	sta $4004	; Set Square 2 volume to 0
	sta $400C	; Set Noise volume to 0
	lda #$80
	sta $4008	; Silence Triangle

	lda #$00
	sta sound_disable_flag	; Clear disable flag

	rts
	
	
	sound_disable:
    lda #$00
    sta $4015   ;disable all channels
    lda #$01
    sta sound_disable_flag  ;set disable flag
    rts

sound_load:
    ;nothing here yet
    rts
 
sound_play_frame:
    lda sound_disable_flag
    bne .done       ;if disable flag is set, don't advance a frame
    ;nothing here yet
.done:
    rts

test_sound:
	lda	#%00000111
	sta	$4015	; Enable square wave channel 1 and 2
	lda #%10111111
	sta $4000	;
	lda #36		; C4
	asl a
	tay
	lda note_table, y
	sta $4002	; Period $C000
	lda note_table+1, y
	sta $4003
	
	; Square 2
	lda #%10111111
	sta $4004	;
	lda #40		; E4
	asl a
	tay
	lda note_table, y
	sta $4006
	lda note_table+1, y
	sta $4007
	
	; Triangle
	lda #%10000001
	sta $4008
	lda #55		; G4 (actually G5 but triangle is one octave lower)
	asl a
	tay
	lda note_table, y
	sta $400A
	lda note_table+1, y
	sta $400B	
	
	
	rts
	
note_table: .include "test.notes"  ;period values for notes

; Sound
;
; Most of this was inspired by the mighty Nerdy Nights
; (http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=7155)

	.rsset $0300 ;sound engine variables will be on the $0300 page of RAM

; Constants
MUSIC_SQ1 = $00 ;these are stream number constants
MUSIC_SQ2 = $01 ;stream number is used to index into stream variables (see below)
MUSIC_TRI = $02
MUSIC_NOI = $03
SFX_1     = $04
SFX_2     = $05

SQUARE_1  = $00 ;these are channel constants
SQUARE_2  = $01
TRIANGLE  = $02
NOISE     = $03

sound_disable_flag  .rs 1   ;a flag variable that keeps track of whether the sound engine is disabled or not.
                            ;if set, sound_play_frame will return without doing anything.
sound_temp1         .rs 1   ; Used for saving a temporary byte
sound_temp2         .rs 1   ; Used for saving a temporary byte

;reserve 6 bytes each, one for each stream
stream_curr_sound   .rs 6   ;what song/sfx # is this stream currently playing?  
stream_status       .rs 6   ; Status  
stream_channel      .rs 6   ;what channel is it playing on?
stream_vol_duty     .rs 6   ;volume/duty settings for this stream
stream_ptr_LO       .rs 6   ;low 8 bits of period for the current note playing on the stream
stream_ptr_HI       .rs 6   ;high 3 bits of the note period
stream_note_LO      .rs 6   ;low 8 bits of period
stream_note_HI      .rs 6   ;high 3 bits of period
	.bank 1
	.org $8000
	
song_headers:
    .word song0_header
;	.word song1_header
	
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
    sta sound_temp1         ; Save the song number
    asl a                   ; Multiply the index with 2, as the table 
                            ; uses pointers with word length
    tay
    lda song_headers, y     ; Read lo byte of pointer
    sta sound_ptr
    lda song_headers+1, y   ; Read hi byte
    sta sound_ptr+1
    
    lda #$00
    lda [sound_ptr], y      ; Indirect addressing
                            ; Read the first byte: # of streams
    sta sound_temp2         ; Store in temporary byte
    iny
.loop
    lda [sound_ptr], y      ; Stream number    
    tax                     ; This is used as variable index
    iny
    
    lda [sound_ptr], y      ; Status byte (1=enable, 0=disable)
    sta stream_status, x    ; Here the variable index is used
    beq .next_stream        ; If stream disabled, jump to next stream
    iny
    
    lda [sound_ptr], y      ; Channel number
    sta stream_channel, x
    iny
    
    lda [sound_ptr], y      ; Initial duty and volume settings
    sta stream_vol_duty, x
    iny
    
    lda [sound_ptr], y      ; Pointer to stream data
    sta stream_ptr_LO, x    ; Little endian, low byte first
                            ; (AAARGH! This always confuses
                            ; me: LITTLE ENDian = the smallest
                            ; byte last? But no, of course it's
                            ; the other way around...)
    iny
    
    lda [sound_ptr], y
    sta stream_ptr_HI, x    ; Now high byte of stream data pointer
.next_stream:
    iny
    
    lda sound_temp1         ; Song number
    sta stream_curr_sound, x
    
    dec sound_temp2         ; The loop is counting # of streams
    bne .loop
    rts
 
sound_play_frame:
    lda sound_disable_flag
    bne .done       ;if disable flag is set, don't advance a frame
    
    ldx #$00    ; Start at stream 0 (MUSIC_SQ1)
.loop
    lda stream_vol_duty, x  ; X is an offset to the current stream

    inx             ; Next stream
    cpx #$06        ; Loop through all streams
                    ; Todo: Use a constant for this?
    bne .loop
.done:
    rts

; Fetch a byte from the data stream
;
;     
; Input:
;   X: Stream number
se_fetch_byte:
    lda stream_ptr_LO, x    ; Copy stream pointer into a zero page
                            ; pointer variable
    sta sound_ptr
    lda stream_ptr_HI, x
    sta sound_ptr+1
    
    ldy #$00
    lda [sound_ptr], y      ; Read a byte using indirect mode
    bpl .note               ; If <#$80, a note
    cmp #$A0                ; If <#$A0, a note length
    bcc .note_length
.opcode:                    ; Else, an opcode
    jmp .update_pointer
.note_length:
    jmp .update_pointer
.note:
    asl a                   ; Word indexing
    sty sound_temp1         ; Save Y
    tay
    lda note_table, y       ; Low 8 bits of period
    sta stream_note_LO, x
    lda note_table+1, y
    sta stream_note_HI, x
    lda sound_temp1         ; Restore Y

; Update stream pointer to point to the next byte
; in the data stream
.update_pointer:
    iny
    tya
    clc
    adc stream_ptr_LO, x    ; Add Y to the LO pointer
    sta stream_ptr_LO, x
    bcc .end
    inc stream_ptr_HI, x    ; 16 bit add
.end:
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
song0: .include "song0.asm"

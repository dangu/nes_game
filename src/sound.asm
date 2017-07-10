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
stream_tempo        .rs 6   ; The tempo which is added to the ticker below
                            ; The ticker will wrap around at 0xFF and there
                            ; is the next tick
stream_ticker_total .rs 6   ; This is the ticker that wraps around at 0xFF
stream_note_length_counter .rs 6 ; When this counts to zero, the note ends
stream_note_length  .rs 6   ; Saves the currently set note length for all notes in stream
stream_vol_duty     .rs 6   ;volume/duty settings for this stream
stream_ptr_LO       .rs 6   ;low 8 bits of period for the current note playing on the stream
stream_ptr_HI       .rs 6   ;high 3 bits of the note period
stream_note_LO      .rs 6   ;low 8 bits of period
stream_note_HI      .rs 6   ;high 3 bits of period
	.bank 1
	.org $A000
	
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
    iny
    
    lda [sound_ptr], y
    sta stream_tempo, x     ; Set inital tempo of the stream

    lda #$01
    sta stream_note_length_counter, x ; This is to start playing the 
                                      ; very first note immediately

.next_stream:
    iny
    
    lda sound_temp1         ; Song number
    sta stream_curr_sound, x
    
    dec sound_temp2         ; The loop is counting # of streams
    bne .loop
    rts
 
; Play sound frame
;
; This subroutine is called every NMI and uses separate
; tickers for the streams
sound_play_frame:
    lda sound_disable_flag
    bne .done       ;if disable flag is set, don't advance a frame
    
    ldx #$00    ; Start at stream 0 (MUSIC_SQ1)
.loop
    lda stream_status, x    ; Is stream enabled?
    and #$01
    beq .next_stream        ; If not enabled, skip to next stream

    lda stream_ticker_total, x  ; Get the old ticker value
    clc
    adc stream_tempo, x
    sta stream_ticker_total, x  ; Increase ticker with tempo value
    bcc .next_stream
    
    dec stream_note_length_counter, x ; Decrement note length counter
    bne .next_stream    ; If counter is zero, the next note should start
                    ; If not, this note is not finished
    lda stream_note_length, x   ; Reload the note length counter
    sta stream_note_length_counter, x
    
    jsr se_fetch_byte       ; Read next byte from stream
    jsr se_set_apu          ; Write the data to the APU

.next_stream:
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
.fetch
    lda [sound_ptr], y      ; Read a byte using indirect mode
    bpl .note               ; If <#$80, a note
    cmp #$A0                ; If <#$A0, a note length
    bcc .note_length
.opcode:                    ; Else, an opcode
    jmp .update_pointer
.note_length:
    and #%01111111          ; Note length are defined as
                            ; #$80, 81, ... 
                            ; Use only the 7 msb to get a zero
                            ; based index
    sty sound_temp1         ; Save Y as it will be overwritten
    tay
    lda note_length_table, y
    sta stream_note_length, x   ; Now using this note length
                            ; for all future notes in this stream
    sta stream_note_length_counter, x
                            ; Now the stream_note_length_counter
                            ; is reset with the new value
    ldy sound_temp1         ; Restore Y
    iny                     ; Get the next byte from the stream
    jmp .fetch
.note:
    asl a                   ; Word indexing
    sty sound_temp1         ; Save Y
    tay
    lda note_table, y       ; Low 8 bits of period
    sta stream_note_LO, x
    lda note_table+1, y
    sta stream_note_HI, x
    ldy sound_temp1         ; Restore Y

; Update stream pointer to point to the next byte
; in the data stream
; This needs some extra explanation:
; - stream_ptr_LO/HI points to the current byte in the stream
; - stream_ptr_LO/HI is an array of as many bytes as there are streams
; - X indexes the actual stream
; - At this point in the code, Y holds the value #$00
;   used for indirect addressing above
.update_pointer:
    iny  ; Now Y=#$01
    tya
    clc
    adc stream_ptr_LO, x    ; Add Y to the LO pointer
    sta stream_ptr_LO, x    ; This increases the stream pointer by 1
    bcc .end
    inc stream_ptr_HI, x    ; 16 bit add
.end:
    rts

; Write the stream data to the APU ports
;
se_set_apu:
    lda stream_channel, x  ; Get the channel of this stream
    asl a
    asl a           ; Multiply by four as the channels are as follows:
                    ; $4000: Pulse 1
                    ; $4004: Pulse 2
                    ;   ...
                    ; (https://wiki.nesdev.com/w/index.php/APU_registers)
                    
    tay
    lda stream_vol_duty, x
    sta $4000, y            ; Write to the correct register
                            ; (with an offset of Y)
    lda stream_note_LO, x
    sta $4002, y
    lda stream_note_HI, x
    sta $4003, y
    
    lda stream_channel, x
    cmp #TRIANGLE
    bcs .end        ; The triangle and noise channels do not have the
                    ; sweep register 
    lda #$08        ; Set the negate flag. Not sure why, but it is
                    ; mentioned here:
                    ; http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452
    sta $4001, y

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
	
note_table: .include "sound_data.asm"  ;period values for notes
song0: .include "song0.asm"

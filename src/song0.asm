; This is the song0
; Inspired by http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452

song0_header:
    .byte $04           ;4 streams
 
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $BC           ;initial volume (C) and duty (10 => B0)
    .byte $00           ; The first volume envelope
    .word song0_square1 ;pointer to stream
    .byte $53            ;initial tempo
 
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $38           ;initial volume (8) and duty (00 => 30)
    .byte $00           ; The first volume envelope
    .word song0_square2 ;pointer to stream
    .byte $53            ;initial tempo
 
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .byte $00           ; The first volume envelope
    .word song0_tri     ;pointer to stream
    .byte $53            ;initial tempo
 
    .byte MUSIC_NOI     ;which stream
    .byte $01           ; Enabled
    .byte NOISE         ; Which channel
    .byte $30           ; Initial volume_duty
    .byte $02           ; Drum volume envelope
    .word song0_noise   ; Pointer to the sound data stream
    .byte $53           ; Tempo

;these are the actual data streams that are pointed to in our stream headers.   
song0_square1:
    .byte set_note_offset, 0
    .byte sixteenth, A3, rest, C4, E4, A4
    .byte volume_envelope, 1
    .byte C5
    .byte volume_envelope, 0, E5
    .byte quarter
    .byte A5
    .byte duty, $30
    .byte A5
    .byte duty, $B0
    .byte A5
    .byte duty, $F0
    .byte A5
    .byte duty, $B0
    .byte set_loop1_counter, 2
.intro_loop:
    .byte sixteenth
    .byte set_loop2_counter, 4
.inner_loop:
    .byte E4, G4
    .byte adjust_note_offset, 1
    .byte loop2
    .word .inner_loop
    .byte A3, C4, E4, A4
    .byte loop1
    .word .intro_loop
    .byte A3, E4, E3, E2
;    .byte loop
;    .word song0_square1
    .byte endsound
song0_square2:
    .byte quarter, A3, A3, A3, E4, A3, A3, E4 ;some notes to play on square 2
    .byte endsound
song0_tri:
    .byte whole, A3, B3, C3, D3, E3, F3, G3 ;triangle data
    .byte endsound
    
song0_noise:
    .byte eighth, $04                   ;this song only uses drum 04 (Mode-0, Sound Type 4) for a snare
    .byte sixteenth, $04, $04, $04
    .byte d_eighth, $04
    .byte sixteenth, $04, $04, $04, $04
    .byte eighth, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09
    .byte eighth, $0A, $0B, $0C, $0D, $0E, $0F
    .byte eighth, $00, $11, $12, $13, $14, $15, $16, $17, $18, $19
    .byte eighth, $1A, $1B, $1C, $1D, $1E, $1F
    .byte loop
    .word song0_noise
; This is the song0
; Inspired by http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452

song0_header:
    .byte $04           ;4 streams
 
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $BC           ;initial volume (C) and duty (10)
    .byte $00           ; The first volume envelope
    .word song0_square1 ;pointer to stream
    .byte 06            ;initial tempo
 
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $38           ;initial volume (8) and duty (00)
    .byte $00           ; The first volume envelope
    .word song0_square2 ;pointer to stream
    .byte 06            ;initial tempo
 
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $81           ;initial volume (on)
    .byte $00           ; The first volume envelope
    .word song0_tri     ;pointer to stream
    .byte 06            ;initial tempo
 
    .byte MUSIC_NOI     ;which stream
    .byte $00           ;disabled.  We will have our load routine skip the
                        ;   rest of the reads if the status byte disables the stream.
                        ;   We are disabling Noise because we haven't covered it yet.

;these are the actual data streams that are pointed to in our stream headers.   
song0_square1:
    .byte eighth, A3, rest, C4, E4, A4, C5, E5, A5 ;some notes.  A minor
 
song0_square2:
    .byte quarter, A3, A3, A3, E4, A3, A3, E4 ;some notes to play on square 2
 
song0_tri:
    .byte whole, A3, B3, C3, D3, E3, F3, G3 ;triangle data

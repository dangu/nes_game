; Opcode launcher
;
; A: The opcode
se_opcode_launcher:
    sty sound_temp1     ; Save Y
    sec                 ; Set carry before subtracting
    sbc #$A0            ; Subtract $A0 from A
                        ; $A0 => $00, $A1 => $01, ...
    asl a               ; The table is using words
    tay
    lda sound_opcodes, y    ; Get low byte of address
    sta jmp_ptr
    lda sound_opcodes+1, y  ; Get high byte of address
    sta jmp_ptr+1
    ldy sound_temp1     ; Restore Y
    iny                 ; Increment Y to point to the next
                        ; position in the data stream (assume
                        ; an argument)
    jmp [jmp_ptr]       ; Indirect jump into the table
                        ; Note: No rts here! The jsr was in
                        ; the caller of se_opcode_launcher.
                        ; When the next rts occurs, the return
                        ; address is inside that caller.

; Sound opcodes
;
; X: Stream number
; Y: The next index in data stream (assume an argument)

; Sound opcode: End sound
;
se_op_endsound:
    lda stream_status, x
    and #%11111110
    sta stream_status, x    ; Clear enable flag

    lda stream_channel, x
    cmp #TRIANGLE
    beq .silence_tri        ; Silence triangle in a special way
    lda #$30                ; Sqares and noise silenced with #$30
    bne .silence
.silence_tri:
    lda #$80                ; Triangle silenced with #$80
.silence:
    sta stream_vol_duty, x  ; Store silence value
    rts
    
; Sound opcode: Infinite loop
;
; Uses a 2 byte argument
; sound_ptr: A pointer to the current position in the
; data stream
; Y: 1 for the first call (pointing to the first argument)
se_op_infinite_loop:
    lda [sound_ptr], y      ; Read LO byte of the
                            ; address argument
    sta stream_ptr_LO, x    ; Save as the new stream position
    iny
    lda [sound_ptr], y      ; The same for the HI byte
    sta stream_ptr_HI, x
    
    sta sound_ptr+1         ; Update the stream data pointer. Now
    lda stream_ptr_LO, x
    sta sound_ptr           ; Now it points to the second argument of this
                            ; opcode
    ldy #$FF                ; After opcodes return, Y is incremented.
                            ; This results in Y=0
    rts    
    
; Sound opcode: Change volume envelope
;
; Y: Desired volume envelope
se_op_change_ve:
    lda [sound_ptr], y      ; Read the argument
    sta stream_ve, x        ; Store the desired volume envelope
    lda #$00
    sta stream_ve_index, x  ; Start from the beginning of the envelope
    rts
    
; Sound opcode: Change duty cycle
;
; Y: Desired duty
se_op_duty:
    lda [sound_ptr], y      ; Read the argument
    sta stream_vol_duty, x  ; Store the desired duty
    rts

; Jump table for sound opcodes
;
; The table is put here to not disturb the mednafen debugger.
; When it was put above within the actual code, the debugger
; was translating A0, A1, ... into instructions which garbled
; the rest of the disassembly.
sound_opcodes:
    .word se_op_endsound        ; $A0
    .word se_op_infinite_loop   ; $A1
    .word se_op_change_ve       ; $A2
    .word se_op_duty            ; $A3

endsound        = $A0
loop            = $A1
volume_envelope = $A2
duty            = $A3
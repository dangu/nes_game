		;!The Header!

        .inesprg    1
        .ineschr    1 ;1 bank of chr ROM
        .inesmir    1
        .inesmap    0

	.org $8000
	.bank 0

Start:
	;this setups the PPU
	lda #%00001000     
	sta $2000          
	lda #%00011110 
	sta $2001
;set to start of palette
        lda #$3F
        sta $2006
        lda #$00
        sta $2006

	;these are the writes that setup the palette
        lda #$01
        sta $2007
        lda #$02 
        sta $2007
        lda #$03
        sta $2007
        lda #$04
        sta $2007
        lda #$05
        sta $2007
        lda #$06
        sta $2007
        lda #$07
        sta $2007
        lda #$08
        sta $2007
        lda #$01     ;stop here
        sta $2007
        lda #$08
        sta $2007
        lda #$09
        sta $2007
        lda #$0A
        sta $2007
        lda #$01
        sta $2007
        lda #$0B
        sta $2007
        lda #$0C
        sta $2007
        lda #$0D
        sta $2007
        lda #$01    ;Start sprite colors
        sta $2007
        lda #$0D
        sta $2007
        lda #$08
        sta $2007
        lda #$2B
        sta $2007
        lda #$01
        sta $2007
        lda #$05
        sta $2007
        lda #$06
        sta $2007
        lda #$07
        sta $2007
        lda #$01
        sta $2007
        lda #$08
        sta $2007
        lda #$09
        sta $2007
        lda #$0A
        sta $2007
        lda #$01
        sta $2007
        lda #$0B
        sta $2007
        lda #$0C
        sta $2007
        lda #$0D
        sta $2007

	
Loop:
	jmp Loop

    	.bank 1
	.org	$FFFA
	.dw		0 ;(NMI_Routine)
	.dw		Start ;(Reset_Routine)
	.dw		0 ;(IRQ_Routine)

    .bank 2
    .org    $0000
     .incbin "test.chr"		gotta be 8192 bytes long

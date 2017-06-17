		;!The Header!

        .inesprg    1
        .ineschr    1 ;1 bank of chr ROM
        .inesmir    1
        .inesmap    0

	.org $8000
	.bank 0

Start:
	;this sets up the PPU
	lda #%00001000     
	sta $2000          
	lda #%00011110 
	sta $2001

    lda #$3F	;set to start of palette
    sta $2006
    lda #$00
    sta $2006
    
    ldx	#$00
loadpal:
	lda titlepal, x		;loads a 32 byte pa
	sta	$2007
	inx
	cpx	#$20
	bne loadpal


titlepal: .incbin "test.pal"	;palette data

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

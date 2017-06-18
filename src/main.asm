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
	lda #%00010110 
	sta $2001

    lda #$3F	;set to start of palette
    sta $2006
    lda #$00
    sta $2006
    
    

    ldx	#$00
loadpal:
	lda titlepal, x		;loads a 32 byte palette
	sta	$2007
	inx
	cpx	#$20
	bne loadpal

    Loop:
	jmp Loop
	
titlepal: .incbin "test.pal"	;palette data

	lda #$00
	sta $10		;Store local variable


;vwait:	
;	lda $2002    ;wait
;	bpl vwait

    lda #$20        ;set ppu to start of VRAM
    sta $2006       
    lda #$20     
    sta $2006 

	lda #$48	;write pattern table tile numbers to the name table
	sta $2007
	lda #$65
	sta $2007
	lda #$6C
	sta $2007
	lda #$6C
	sta $2007
	lda #$6F
	sta $2007


	ldx #$00	;set $2004 to the start of SPR-RAM
	stx $2003
	stx $2003

    lda #$0D	;y-1
    sta $2004
    ldx $10		; Local variable
    sta $2004	;write sprite pattern number
    lda #%00000001       ;color bit
    sta $2004
    stx $2004
	inx
	stx $10    
    

	
halt:
	jmp halt

    	.bank 1
	.org	$FFFA
	.dw		0 ;(NMI_Routine)
	.dw		Start ;(Reset_Routine)
	.dw		0 ;(IRQ_Routine)

    .bank 2
    .org    $0000
     .incbin "test.chr"		gotta be 8192 bytes long

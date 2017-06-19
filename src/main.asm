		;!The Header!

        .inesprg    1
        .ineschr    1 ;1 bank of chr ROM
        .inesmir    1
        .inesmap    0

	.org $8000
	.bank 0

Start:
	jsr vwait
	;this sets up the PPU
	lda #%00001000     
	sta $2000          
	lda #%00011110 
	sta $2001
	
main_loop:
	jsr vwait
	jsr load_palette
	jsr vwait
	jsr load_palette2
	jmp main_loop
halt:
	jmp halt

	
load_palette2:
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
	rts


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

    lda #$00	;Sprite memory location 0
    sta $2004
    
    lda #128	;y-1
    sta $2004
    lda #$01	; SPrite number
    sta $2004	;write sprite pattern number
;    lda #%00000001       ;color bit
    lda #0       ;Attribute
    sta $2004
    lda #120	; x
    sta $2004
	  

    

load_palette:
	lda #$3F
	sta	$2006
	lda	#$00
	sta	$2006
	lda	#$0E	; Base color black
	sta	$2007
	lda #$3F
	sta	$2006
	lda #$11
	sta	$2006
	lda #$30
	sta	$2007
	
	
	rts	
	
vwait:
	lda $2002
	bpl vwait ;//wait for start of retrace
vwait_1:
	lda $2002
	bmi vwait_1 ;//wait for end of retrace
	lda #0
	sta $2005
	sta $2005
	sta $2006
	sta $2006	
	rts


titlepal: .incbin "test.pal"	;palette data

    	.bank 1
	.org	$FFFA
	.dw		0 ;(NMI_Routine)
	.dw		Start ;(Reset_Routine)
	.dw		0 ;(IRQ_Routine)

    .bank 2
    .org    $0000
     .incbin "test.chr"		;gotta be 8192 bytes long

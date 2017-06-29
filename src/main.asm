	.list
; Some explanation of the nesasm bank and org:
; When using 1 bank of ROM (16 kB) and 1 bank of CHR (8 kB),
; the nesasm bank 0 and 1 will be the ROM. Bank 2 is CHR.
;
; Within each bank, it is possible to set the .org. If it is
; set to a multiple of 8 kB (0x2000) it will be the start of
; the given bank [1].
; 
; References
; [1]: https://forums.nesdev.com/viewtopic.php?f=10&t=10606

        .inesprg    1
        .ineschr    1 ;1 bank of chr ROM
        .inesmir    1
        .inesmap    0
        
	.bank 0        
	.org $0000
; Some variables
joy1a:	.ds 1
joy1b:	.ds 1
xpos:	.ds 1
ypos:	.ds 1
	.bank 0
	.org $8000


	
Start:
	; Init stack
	sei			; Disable interrupts
	cld			; Deactivate decimal mode (is there even one 
				; in the NES processor? No, but this helps with 
				; compatibility with generic 6502 emulators
				; (https://wiki.nesdev.com/w/index.php/Init_code))
	ldx #$40
	stx $4017	; Disable APU frame IRQ (https://wiki.nesdev.com/w/index.php/APU_Frame_Counter)
	ldx	#$FF	; Set up stack 
	txs			; Set stack pointer to $FF
	inx			; X=0
	stx $2000	; Disable NMI (https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL)
	stx $2001	; Disable rendering (https://wiki.nesdev.com/w/index.php/PPU_registers#PPUMASK)
	stx $4010	; Disable DMC interrupts (https://wiki.nesdev.com/w/index.php/APU_DMC)


	jsr init
	cli			; Enable interrupts
	jsr vwait
	;this sets up the PPU
	lda #%00000000     
	sta $2000          
	lda #%00011110 
	sta $2001
	
	jsr load_palette2
;	jsr test_sound

main_loop:
	jmp main_loop
	jsr joystick1
	jsr calc_pos
	jsr vwait
	jsr drawstuff

halt:
	jmp halt

init:

;	jsr sound_init
	
	lda #120
	sta xpos		; Start with some default x y values
	lda #127
	sta ypos
	rts
	
	
NMI:
	pha			; push A to stack
	txa
	pha			; push X to stack
	tya
	pha			; push Y to stack

;	jsr sound_play_frame
	
	lda #$00
;	sta sleeping	; clear sleeping flag

	pla
	tay			; pop Y from stack
	pla
	tax			; pop X from stack
	pla			; pop A from stack
	rti
	
; Just to see if the irq interrupt jumps here at all
IRQ:
	pha
	lda $4015	; It seems we are stuck in this interrupt from the APU
				; According to https://wiki.nesdev.com/w/index.php/APU_Frame_Counter
				; reading $4015 will clear the interrupt
	pla
	rti
	
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

; Calculate positions
calc_pos:
	lda joy1a
	and #$01
	beq not_a
	ldx xpos
	inx
	stx xpos
not_a:
	lda joy1b
	and #$01
	beq not_b
	ldx ypos
	inx
	stx ypos
not_b:
	rts

drawstuff:
    lda #$00	;Sprite memory location 0
    sta $2003
    
    lda ypos	;y-1
    sta $2004
    lda #$01	; Sprite number
    sta $2004	;write sprite pattern number
;    lda #%00000001       ;color bit
    lda #0       ;Attribute
    sta $2004
    lda xpos	; x
    sta $2004
    rts
	  

    

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
	sta $2005	; Set scroll and PPU base address
	sta $2005
	sta $2006
	sta $2006	
	rts
	
joystick1:
	lda #$01
	sta	$4016	;first strobe byte
	lda #$00
	sta	$4016	;second strobe byte

	lda	$4016	; Read joy1a
	sta joy1a
	lda	$4016	; Read joy1b
	sta joy1b
	rts
	
;	set joy1a		& [$4016] 1
;	set joy1b		& [$4016] 1
;	set joy1select	& [$4016] 1
;	set joy1start	& [$4016] 1
;	set joy1up		& [$4016] 1
;	set joy1down	& [$4016] 1
;	set joy1left	& [$4016] 1
;	set joy1right	& [$4016] 1
;	return


titlepal: .incbin "test.pal"	;palette data
	.include "sound.asm"

    	.bank 1
	.org	$FFFA
	.dw		NMI ;(NMI_Routine)
	.dw		Start ;(Reset_Routine)
	.dw		IRQ ;(IRQ_Routine)

    .bank 2
    .org    $0000
     .incbin "test.chr"		;gotta be 8192 bytes long

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

				; Fill stack area with a specific pattern for debugging
	lda #$CD	; The pattern to use
	ldx #$00
.fill_stack:
	sta $0100,x	; The stack is located at $0100-$01FF
	inx
	bne .fill_stack
	
	ldx	#$FF	; Set up stack 
	txs			; Set stack pointer to $FF
	inx			; X=0
	stx $2000	; Disable NMI (https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL)
	stx $2001	; Disable rendering (https://wiki.nesdev.com/w/index.php/PPU_registers#PPUMASK)
	stx $4010	; Disable DMC interrupts (https://wiki.nesdev.com/w/index.php/APU_DMC)

	; Code from https://wiki.nesdev.com/w/index.php/Init_code:
    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the @vblankwait1 loop sees an actual vblank.
	; Something about the BIT instruction (http://users.telenet.be/kim1-6502/6502/proman.html#4221):
	; BIT: Test bits in memory with accumulator
	; The instruction affects the N flag (the 7th bit) but doesn't store
	; the result in the accumulator
    bit $2002

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
.vblankwait1:  
    bit $2002
    bpl .vblankwait1
    
    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    txa
.clrmem:
    sta $000,x
;    sta $100,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).
	; We also skipped $100, as the stack is already filled with a pattern

    inx
    bne .clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
   
.vblankwait2:
    bit $2002
    bpl .vblankwait2
    

	jsr init

	;this sets up the PPU
	lda #%10000000     ; Generate NMI
	sta $2000          
	lda #%00011110 
	sta $2001
	
	cli				; Start interrupts
	
	
	jsr load_palette2
;	jsr test_sound

main_loop:

	jsr joystick1
	jsr calc_pos
	jsr vwait
	jmp main_loop
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

	jsr drawstuff	; Do the drawing
	
;	jsr sound_play_frame ; Play sounds after the time critical drawing
	
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

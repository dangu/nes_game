
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
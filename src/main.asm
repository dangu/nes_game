		;!The Header!

        .inesprg    1
        .ineschr    0 ;this is 0 b/c we have no chr data...yet
        .inesmir    1
        .inesmap    0

	.org $8000
	.bank 0

		
Start:
		;!Code Goes Here!

	jmp Start


		;!The Vector Table!
    	.bank 1
	.org	$FFFA
	.dw		0 ;(NMI_Routine)
	.dw		Start ;(Reset_Routine)
	.dw		0 ;(IRQ_Routine)

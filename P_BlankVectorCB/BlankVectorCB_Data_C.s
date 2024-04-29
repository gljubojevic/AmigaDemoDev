;**************************************************************************
; Declare here all data used in demo part that should be in chip mem
	INCDIR	"../Include/"
	INCLUDE	"hardware/custom.i"	
	INCDIR	""

	CNOP	0,8
BV_Copper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81			;DIWSTRT
	dc.w	$0090,$2cc1			;DIWSTOP
	dc.w	$0092,$0038			;DDFSTRT
	dc.w	$0094,$00d0			;DDFSTOP
BV_CSpr:	
	dc.w	$0120,$0000,$0122,$0000		;SPR0PTH,SPR0PTL
	dc.w	$0124,$0000,$0126,$0000		;SPR1PTH,SPR1PTL
	dc.w	$0128,$0000,$012A,$0000		;SPR2PTH,SPR2PTL
	dc.w	$012C,$0000,$012E,$0000		;SPR3PTH,SPR3PTL
	dc.w	$0130,$0000,$0132,$0000		;SPR4PTH,SPR4PTL
	dc.w	$0134,$0000,$0136,$0000		;SPR5PTH,SPR5PTL
	dc.w	$0138,$0000,$013A,$0000		;SPR6PTH,SPR6PTL
	dc.w	$013C,$0000,$013E,$0000		;SPR7PTH,SPR7PTL
BV_CMod:	
	dc.w	$0108,$0000			;BPL1MOD
	dc.w	$010a,$0000			;BPL2MOD
BV_CCon:	
	dc.w	$0100,$0000			;BPLCON0
	dc.w	$0102,$0000			;BPLCON1
	dc.w	$0104,$0000			;BPLCON2
BV_CBitplanes:	
	dc.w	$00e0,$0000,$00e2,$0000		;BPL0PTH,BPL0PTL
	dc.w	$00e4,$0000,$00e6,$0000		;BPL1PTH,BPL1PTL
BV_CColors:	
	dc.w	$0180,$0000			;COLOR00
	dc.w	$0182,$0000			;COLOR01
	dc.w	$0184,$0000			;COLOR02
	dc.w	$0186,$0000			;COLOR03
	IF	COPPERINT=1
	;dc.w	$2c01,$ff00
	dc.w	$009c,$8010			;INTREQ
	ENDIF
	dc.w	$ffff,$fffe			;End of Copper List
	dc.w	$ffff,$fffe			;End of Copper List

; Trigger blitter clear using copper
;	CNOP	0,8
;BV_CopperClearBlitter:
;	dc.w	$0180,$0f00
;	dc.w	$0001,$0000	;Wait Blitter
;	;dc.w	$0001,$fffe	;Wait Blitter
;	dc.w	bltcon0,$0100
;	dc.w	bltcon1,$0000
;	dc.w	bltdmod,$0000
;BV_CCB_Destination:
;	dc.w	bltdpt+0,$0000,bltdpt+2,$0000
;	dc.w	bltsize,$0000
;	dc.w	$0001,$0000	;Wait Blitter
;	;dc.w	$0001,$fffe	;Wait Blitter
;	dc.w	$0180,$0000
;	dc.w	$ffff,$fffe	;End of Copper List
;	dc.w	$ffff,$fffe	;End of Copper List

	CNOP	0,8
BV_CopperDrawBlitter:
	blk.b	32,0		;Line prepare
	blk.b	52,0		;Fill
	blk.b	48*2*24,0	;Line*Bitmaps*MaxLines
	blk.b	8,0		;End of Copper List
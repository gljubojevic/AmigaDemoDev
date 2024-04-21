;**************************************************************************
; Declare here all data used in demo part that should be in chip mem

	CNOP	0,8
EP_Copper:
	dc.w	$01fc,$0000
	dc.w	$0100,$0000			;BPLCON0
	dc.w	$0102,$0000			;BPLCON1
	dc.w	$0104,$0000			;BPLCON2
	dc.w	$0106,$0000			;BPLCON3
	dc.w	$010c,$0000			;BPLCON4
EP_CWait:
	dc.w	$2f01,$fffe,$2fe1,$fffe
	dc.w	$3001,$fffe,$0180,$0000,$30e1,$fffe
	dc.w	$3101,$fffe,$0180,$0111,$31e1,$fffe
	dc.w	$3201,$fffe,$0180,$0222,$32e1,$fffe
	dc.w	$3301,$fffe,$0180,$0333,$33e1,$fffe
	dc.w	$3401,$fffe,$0180,$0444,$34e1,$fffe
	dc.w	$3501,$fffe,$0180,$0555,$35e1,$fffe
	dc.w	$3601,$fffe,$0180,$0666,$36e1,$fffe
	dc.w	$3701,$fffe,$0180,$0777,$37e1,$fffe
	dc.w	$3801,$fffe,$0180,$0888,$38e1,$fffe
	dc.w	$3901,$fffe,$0180,$0999,$39e1,$fffe
	dc.w	$3a01,$fffe,$0180,$0aaa,$3ae1,$fffe
	dc.w	$3b01,$fffe,$0180,$0bbb,$3be1,$fffe
	dc.w	$3c01,$fffe,$0180,$0ccc,$3ce1,$fffe
	dc.w	$3d01,$fffe,$0180,$0ddd,$3de1,$fffe
	dc.w	$3e01,$fffe,$0180,$0eee,$3ee1,$fffe
	dc.w	$3f01,$fffe,$0180,$0fff,$3fe1,$fffe

	dc.w	$4001,$fffe,$0180,$0fff,$40e1,$fffe
	dc.w	$4101,$fffe,$0180,$0eee,$41e1,$fffe
	dc.w	$4201,$fffe,$0180,$0ddd,$42e1,$fffe
	dc.w	$4301,$fffe,$0180,$0ccc,$43e1,$fffe
	dc.w	$4401,$fffe,$0180,$0bbb,$44e1,$fffe
	dc.w	$4501,$fffe,$0180,$0aaa,$45e1,$fffe
	dc.w	$4601,$fffe,$0180,$0999,$46e1,$fffe
	dc.w	$4701,$fffe,$0180,$0888,$47e1,$fffe
	dc.w	$4801,$fffe,$0180,$0777,$48e1,$fffe
	dc.w	$4901,$fffe,$0180,$0666,$49e1,$fffe
	dc.w	$4a01,$fffe,$0180,$0555,$4ae1,$fffe
	dc.w	$4b01,$fffe,$0180,$0444,$4be1,$fffe
	dc.w	$4c01,$fffe,$0180,$0333,$4ce1,$fffe
	dc.w	$4d01,$fffe,$0180,$0222,$4de1,$fffe
	dc.w	$4e01,$fffe,$0180,$0111,$4ee1,$fffe
	dc.w	$4f01,$fffe,$0180,$0000,$4fe1,$fffe

	IF	COPPERINT=1
	dc.w	$009c,$8010			;INTREQ
	ENDIF
	dc.w	$ffff,$fffe			;End of Copper List
	dc.w	$ffff,$fffe			;End of Copper List

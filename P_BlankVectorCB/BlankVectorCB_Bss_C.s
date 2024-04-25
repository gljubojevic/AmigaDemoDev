;**************************************************************************
; Declare here free mem used in demo part that should be in chip mem

	CNOP	0,8
BV_Copper_BlitterDraw:
	ds.l	2,0		;2x Wait blitter finish
	ds.l	2,0		;2x Copper END

	CNOP	0,8
BV_Video00:
	ds.b	20480,0		;320*256*2 size picture

	CNOP	0,8
BV_Video01:
	ds.b	20480,0		;320*256*2 size picture

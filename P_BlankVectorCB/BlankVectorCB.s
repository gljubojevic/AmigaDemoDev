; Use prefix for all lables e.g "BV_" for Blank Vector part

	INCDIR	"../Include/"
	INCLUDE	"hardware/custom.i"	
	INCDIR	""

;*****************************************************************
;Init for demo part, Do all init for part here e.g. create tables
;prepare copper list etc...
;Input:
;	a6 - Custom Chip Address $dff000 
;Output:
;	a0 - CopperList to set initially
;	a1 - VBlank routine
;	a2 - Main routine
BV_Init:
	movem.l d0-d7/a3-a6,-(sp)

	bsr	Line_TablesCreate
	bsr	VideoBuffersSet
	bsr	Write_Copper

	lea	Cube(pc),a0
	move.l	a0,Curent_Object
	bsr	RotateXYZ
	bsr	Draw_Object_Test

	;Enable copper to use blitter
	move.w	#$0002,copcon(a6)

	;return values for part
	lea	BV_Copper,a0
	lea	BV_VBlank(pc),a1
	lea	BV_Main(pc),a2
	movem.l (sp)+,d0-d7/a3-a6
	rts

;*****************************************************************
;Demo part, main routine usually for part timing
;Input:
;	a0 - frame counter pointer
;	a6 - Custom Chip Address $dff000
BV_Main:
	movem.l d0-d7/a1-a6,-(sp)

	move.l	(a0),d0
	add.l	#20*50,d0	; wait 20 sec

BV_Wait:
	btst	#$6,$bfe001	; exit part on mouse
	beq.s	BV_Exit
	cmp.l	(a0),d0		; or wait until finished
	bge.s	BV_Wait

BV_Exit:
	;Disable copper to use blitter
	move.w	#$0000,copcon(a6)

	movem.l (sp)+,d0-d7/a1-a6
	rts

;*****************************************************************
;Demo part, Vertical blank routine, either copper or vblank
;Input:
;	a0 - frame counter pointer
;	a6 - Custom Chip Address $dff000 
BV_VBlank:
	movem.l d0-a6,-(sp)

	bsr	Clear_Screen
	bsr	Draw_And_Fill

	bsr	Write_Copper
	bsr	VideoBuffersSwap

	;move.w	#$00f0,$180(a6)
	bsr	Move_Object
	bsr	RotateXYZ
	bsr	Draw_Object_Test
	;move.w	#$0000,$180(a6)

	movem.l (sp)+,d0-a6
	rts

;*****************************************************************
;Demo part routines

VideoBuffers:
	dc.l	0	;Draw video buffer
	dc.l	0	;Show video buffer

VideoBuffersSet:
	movem.l	a0-a1,-(sp)
	lea	VideoBuffers(pc),a0
	lea	BV_Video00,a1
	move.l	a1,(a0)+
	lea	BV_Video01,a1
	move.l	a1,(a0)+
	movem.l	(sp)+,a0-a1
	rts

VideoBuffersSwap:
	movem.l	a0-a1/d0,-(sp)
	lea VideoBuffers(pc),a0
	lea $4(a0),a1
	move.l	(a0),d0
	move.l	(a1),(a0)
	move.l	d0,(a1)
	movem.l	(sp)+,a0-a1/d0
	rts

Write_Copper:
	movem.l	d0-d1/a0-a1,-(sp)
	move.l	VideoBuffers(pc),d0		;Address of Video Memory in d0
	lea	BV_CBitplanes,a1		;Address in Copper List
	moveq	#$01,d1
WC_NextBitMap:
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	swap	d0
	add.l	#$00000028,d0
	lea	$0008(a1),a1
	dbf	d1,WC_NextBitMap

	lea	Colors(pc),a0
	lea	BV_CColors,a1
	moveq	#$03,d1
WC_NextColor:
	move.w	(a0)+,$0002(a1)
	lea	$0004(a1),a1
	dbf	d1,WC_NextColor

	lea	BV_CMod,a1
	move.w	#$0028,$0002(a1)
	move.w	#$0028,$0006(a1)

	lea	BV_CCon,a1
	move.w	#$2200,$0002(a1)
	move.w	#$0000,$0006(a1)
	move.w	#$0000,$000a(a1)

	movem.l	(sp)+,d0-d1/a0-a1
	rts


L_BMaps=2			;Mumber of bitmaps
L_BMapWid=40			;Width of one bitmap
L_Width=L_BMaps*L_BMapWid	;Width for line routine
L_YTableHeight=256		;Max Y cordinate

Line_TablesCreate:
	movem.l	d0-d1/a0,-(sp)
	lea	L_YTable,a0
	move.l	#L_YTableHeight,d0
	moveq	#0,d1
L_YTableLoop:	
	move.w	d1,(a0)+
	addi.w	#L_Width,d1
	dbra	d0,L_YTableLoop

	lea	L_SizeTable,a0
	move.l	#320,d0
	moveq	#0,d1
L_STableLoop:
	move.l	d1,d2
	lsl.w	#$0006,d2	
	add.w	#$0042,d2
	move.w	d2,(a0)+
	addq.l	#1,d1
	dbra	d0,L_STableLoop
	movem.l	(sp)+,d0-d1/a0
	rts


Clear_Screen:
	movem.l	d0-a6,-(sp)

	move.l	VideoBuffers(pc),d0
	lea	BV_CCB_Destination,a0
	move.w	d0,$6(a0)
	swap	d0
	move.w	d0,$2(a0)
	move.w	#256*64+320/16,$a(a0)
	lea	BV_CopperClearBlitter,a0
	move.l	a0,cop2lc(a6)
	move.w	#0,copjmp2(a6)

	moveq	#$00,d0
	moveq	#$00,d1
	moveq	#$00,d2
	moveq	#$00,d3
	moveq	#$00,d4
	moveq	#$00,d5
	moveq	#$00,d6
	moveq	#$00,d7
	move.l	d0,a0
	move.l	d0,a1
	move.l	d0,a2
	move.l	d0,a3
	move.l	d0,a4
	move.l	d0,a5
	move.l	VideoBuffers(pc),a6
	lea	$5000(a6),a6
	REPT	182
	movem.l	d0-a5,-(a6)
	ENDR
	movem.l	d0-a3,-(a6)
	movem.l	(sp)+,d0-a6
	rts


Up	=	0
Left	=	0
Down	=	255
Right	=	319

Draw_Object_Test:
	movem.l	d0-a6,-(sp)
	move.l	Curent_Object(pc),a0		;Object Data in a0
	move.l	$14(a0),a1			;Object Rotated Dots in a1
	move.l	$18(a0),a4			;Object Normals in a4
	move.l	(a0),a0				;Object Poligon Data in a0
	lea	DOT_Line_Area(pc),a2		;Line Area in a2
	lea	DOT_Clipped(pc),a3		;Clipped Line Area in a3
	lea	ColorsTable(pc),a5			;ColorTable in a5
	lea	Colors(pc),a6			;Colors in a6
	bra.s	DOT_Next_Poligon		;Jump to first Poligon Test
DOT_Poligon_Start:
	addq.l	#$04,a0
DOT_Next_Poligon:
	move.l	(a0)+,d4			;Color,Flag in d4
	move.l	(a0)+,d5			;0Dot,1Dot in d5
	move.l	(a1,d5.w),d1			;X1,Y1 in d1
	swap	d5				;Get 0Dot Offset
	move.l	(a1,d5.w),d0			;X0,Y1 in d0
	move.w	(a0)+,d5			;Get 2Dot Offset
	move.l	(a1,d5.w),d2			;X2,Y2 in d2
	sub.w	d0,d1				;(X1-X0) in d1.w
	sub.w	d0,d2				;(X2-X0) in d2.w
	move.w	d1,d3				;(X1-X0) in d3.w
	move.w	d2,d5				;(X2-X0) in d5.w
	swap	d0				;Get X0
	swap	d1				;Get X1
	swap	d2				;Get X2
	sub.w	d0,d1				;(Y1-Y0) in d1
	sub.w	d0,d2				;(Y2-Y0) in d2
	muls	d2,d3				;(Y2-Y0)*(X1-X0) in d3
	muls	d1,d5				;(X2-X0)*(Y1-Y0) in d5
	sub.l	d5,d3				;(Y2-Y0)*(X1-X0)+(X2-X0)*(Y1-Y0) in d4
	blt.s	DOT_Poligon_Visible
DOT_Poligon_Invisible:
	cmp.w	#$ffff,(a0)			;Test if Object End
	beq.w	DOT_End				;It is Object End
	cmp.w	#$aaaa,(a0)+			;Test if Poligon End
	bne.s	DOT_Poligon_Invisible		;Not End Search Poligon End
	addq.l	#$06,a4				;Next Poligon Normal
	bra.s	DOT_Next_Poligon		;Do Next Poligon
DOT_Poligon_Visible:
	swap	d4				;Color in d4.w
	movem.w	R_CalculationsBefore+12(pc),d0-d2	;X,Y,Z of Normal d0-d2
	muls	(a4)+,d0
	muls	(a4)+,d1
	muls	(a4)+,d2
	add.l	d1,d0
	add.l	d2,d0
	bmi.s	DOT_NO_Color
	swap	d0
	move.w	d4,d1
	add.w	d1,d1				;Color Number * 2
	add.w	d0,d0				;Color Ofset * 2
	move.w	(a5,d0.w),(a6,d1.w)		;Color Transfer
DOT_NO_Color:
	subq.l	#$06,a0				;Address of first Offset
DOT_Next_Line:
	move.w	(a0)+,d5			;Offset in d5
	movem.w	$00(a1,d5.w),d0/d1		;X0,Y0 in d0,d1
	move.w	(a0),d5				;Next Offset in d5
	movem.w	$00(a1,d5.w),d2/d3		;X1,Y1 in d2,d3

Clipping:
	move.w	#Up,d5			;Up in d5
	cmp.w	d5,d1			;Test Y0 on Up
	bge.s	Cl_X0_Test_Left		;Y0 is Ok on Up Edge
	cmp.w	d5,d3			;Test Y1 on Up
	blt.w	Cl_Line_Out		;Line is out of Screen
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	sub.w	d1,d5			;(Up-Y0) in d5
	muls	d6,d5			;(X1-X0)*(Up-Y0) in d5
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	divs	d6,d5			;(X1-X0)*(Up-Y0)/(Y1-Y0) in d5
	add.w	d5,d0			;X0New=(X1-X0)*(Up-Y0)/(Y1-Y0)+X0 in d0
	move.w	#Up,d1			;Y0=Up
Cl_X0_Test_Left:
	move.w	#Left,d5		;Left in d5
	cmp.w	d5,d0			;Test X0 on Left
	bge.s	Cl_Y0_Test_Down		;X0 is Ok on Left Edge
	cmp.w	d5,d2			;Test X1 on Left
	blt.w	Cl_Line_Out		;Line is out of Screen
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	sub.w	d0,d5			;(Left-X0) in d5
	muls	d6,d5			;(Y1-Y0)*(Left-X0) in d5
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	divs	d6,d5			;(Y1-Y0)*(Left-X0)/(X1-X0) in d5
	add.w	d5,d1			;Y0New=(Y1-Y0)*(Left-X0)/(X1-X0)+Y0 in d1
	move.w	#Left,d0		;X0=Left
Cl_Y0_Test_Down:
	move.w	#Down,d5		;Down in d5
	cmp.w	d5,d1			;Test Y0 on Down
	ble.s	Cl_X0_Test_Right	;Y0 is Ok on Down Edge
	cmp.w	d5,d3			;Test Y1 on Down
	bgt.w	Cl_Line_Out		;Line is out of Screen
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	sub.w	d1,d5			;(Down-Y0) in d5
	muls	d6,d5			;(X1-X0)*(Down-Y0) in d5
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	divs	d6,d5			;(X1-X0)*(Down-Y0)/(Y1-Y0) in d5
	add.w	d5,d0			;X0New=(X1-X0)*(Down-Y0)/(Y1-Y0)+X0 in d0
	move.w	#Down,d1		;Y0=Down
Cl_X0_Test_Right:
	move.w	#Right,d5		;Right in d5
	cmp.w	d5,d0			;Test X0 on Right
	ble.s	Cl_Y1_Test_Up		;X0 is Ok on Right
	cmp.w	d5,d2			;Test X1 on Right
	bgt.s	Cl_Line_Out_Right	;Line is out of Screen on Right
	move.w	d4,(a3)+		;Color of Clipped line in Area
	move.w	d1,(a3)+		;Y0 of Clipped Line in Area 
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	sub.w	d0,d5			;(Right-X0) in d5
	muls	d6,d5			;(Y1-Y0)*(Right-X0) in d5
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	divs	d6,d5			;(Y1-Y0)*(Right-X0)/(X1-X0) in d5
	add.w	d5,d1			;Y0New=(Y1-Y0)*(Right-X0)/(X1-X0)+Y0 in d1
	move.w	#Right,d0		;X0=Right
	cmp.w	#Down,d1		;Test Clipped Y0 on Down
	ble.s	Cl_X0_Y0Down_Ok
	move.w	#Down,(a3)+
	bra.s	Cl_Y1_Test_Up		;Skip Line Out Right
Cl_X0_Y0Down_Ok:
	cmp.w	#Up,d1			;Test Clipped Y0 on Up
	bge.s	Cl_X0_Y0Up_Ok
	move.w	#Up,(a3)+
	bra.s	Cl_Y1_Test_Up		;Skip Line Out Right
Cl_X0_Y0Up_Ok:
	move.w	d1,(a3)+		;Y1 of Clipped Line in Area
	bra.s	Cl_Y1_Test_Up		;Skip Line Out Right

Cl_Line_Out_Right:
	move.w	d4,(a3)+		;Color of Line out in Clipped Area
	move.w	d1,(a3)+		;Y0 of Line out in Clipped Area
	cmp.w	#Up,d3			;Test Y1 on Up
	bge.s	ClLOR_Test_Y1_Down	;Y1 is Ok on Up Edge
	move.w	#Up,(a3)+		;Up in Clipped Area
	bra.w	Cl_Line_Out		;Line is out
ClLOR_Test_Y1_Down:
	cmp.w	#Down,d3		;Test Y1 on Down
	ble.s	ClLOR_Test_End		;Y1 is Ok on Down Edge
	move.w	#Down,(a3)+		;Down in Clipped Area
	bra.w	Cl_Line_Out		;Line is out
ClLOR_Test_End:
	move.w	d3,(a3)+		;Y1 in Line Clipped Area
	bra.w	Cl_Line_Out		;Line in out

Cl_Y1_Test_Up:
	move.w	#Up,d5			;Up in d5
	cmp.w	d5,d3			;Test Y1 on Up
	bge.s	Cl_X1_Test_Left		;Y1 is Ok on Up
	cmp.w	d5,d1
	blt.w	Cl_Line_Out
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	sub.w	d3,d5			;(Up-Y1) in d5
	muls	d6,d5			;(X1-X0)*(Up-Y1) in d5
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	divs	d6,d5			;(X1-X0)*(Up-Y1)/(Y1-Y0) in d5
	add.w	d5,d2			;X1New=(X1-X0)*(Up-Y1)/(Y1-Y0)+X1 in d2
	move.w	#Up,d3			;Y1=Up
Cl_X1_Test_Left:
	move.w	#Left,d5		;Left in d5
	cmp.w	d5,d2			;Test X1 on Left
	bge.s	Cl_Y1_Test_Down		;X1 is Ok on Left
	cmp.w	d5,d0
	blt.s	Cl_Line_Out
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	sub.w	d2,d5			;(Left-X1) in d5
	muls	d6,d5			;(Y1-Y0)*(Left-X1) in d5
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	divs	d6,d5			;(Y1-Y0)*(Left-X1)/(X1-X0) in d5
	add.w	d5,d3			;Y1New=(Y1-Y0)*(Left-X1)/(X1-X0)+Y1 in d3
	move.w	#Left,d2		;X1=Left
Cl_Y1_Test_Down:
	move.w	#Down,d5		;Down in d5
	cmp.w	d5,d3			;Test Y1 on Down
	ble.s	Cl_X1_Test_Right	;Y1 is Ok on Down
	cmp.w	d5,d1
	bgt.s	Cl_Line_Out
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	sub.w	d3,d5			;(Down-Y1) in d5
	muls	d6,d5			;(X1-X0)*(Down-Y1) in d5
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	divs	d6,d5			;(X1-X0)*(Down-Y1)/(Y1-Y0) in d5
	add.w	d5,d2			;X1New=(X1-X0)*(Down-Y1)/(Y1-Y0)+X1 in d2
	move.w	#Down,d3		;Y1=Down
Cl_X1_Test_Right:
	move.w	#Right,d5		;Right in d5
	cmp.w	d5,d2			;Test X1 on Right
	ble.s	Clipping_End		;X1 is Ok on Right
	cmp.w	d5,d0
	bgt.s	Cl_Line_Out
	move.w	d4,(a3)+		;Color of Clipped Line in Area
	move.w	d3,(a3)+		;Y0 of Clipped Line in Area
	move.w	d3,d6			;Y1 in d6
	sub.w	d1,d6			;(Y1-Y0) in d6
	sub.w	d2,d5			;(Right-X1) in d5
	muls	d6,d5			;(Y1-Y0)*(Right-X1) in d5
	move.w	d2,d6			;X1 in d6
	sub.w	d0,d6			;(X1-X0) in d6
	divs	d6,d5			;(Y1-Y0)*(Right-X1)/(X1-X0) in d5
	add.w	d5,d3			;Y1New=(Y1-Y0)*(Right-X1)/(X1-X0)+Y1 in d3
	move.w	#Right,d2		;X1=Right
	cmp.w	#Down,d3		;Test Clipped Y1 on Down
	ble.s	Cl_X1_Y1Down_Ok
	move.w	#Down,(a3)+
	bra.s	Clipping_End
Cl_X1_Y1Down_Ok:
	cmp.w	#Up,d3			;Test Clipped Y1 on Up
	bge.s	Cl_X1_Y1Up_Ok
	move.w	#Up,(a3)+
	bra.s	Clipping_End
Cl_X1_Y1Up_Ok:
	move.w	d3,(a3)+		;Y1 of Clipped Line in Area
Clipping_End:
	move.w	d4,(a2)+			;Color in Line Area
	move.w	d0,(a2)+			;X0 in Line Area
	move.w	d1,(a2)+			;Y0 in Line Area
	move.w	d2,(a2)+			;X1 in Line Area
	move.w	d3,(a2)+			;Y1 in Line Area
Cl_Line_Out:
	cmp.w	#$aaaa,$0002(a0)		;Test if Poligon End
	beq.w	DOT_Poligon_Start		;It is Poligon End	
	cmp.w	#$ffff,$0002(a0)		;Test if Object End
	bne.w	DOT_Next_Line			;It is Not Poligon End
DOT_End:
	move.w	#$ffff,(a2)			;Mark End of Line Area
	move.w	#$ffff,(a3)			;Mark End of Clipped Area
	movem.l	(sp)+,d0-a6
	rts


Draw_And_Fill:
	movem.l	d0-a5,-(sp)
	move.l	VideoBuffers(pc),a0	;VideoBuffers in a0
	lea	L_YTable(pc),a1		;L_YTable in a1
	lea	L_SizeTable(pc),a2	;L_SizeTable in a2

	lea	BV_CopperDrawBlitter,a5
	; line drawing common
	move.l	#$00010000,(a5)+	;Wait blitter
	move.l	#$0001fffe,(a5)+
	move.w	#bltbdat,(a5)+
	move.w	#$ffff,(a5)+
	move.w	#bltadat,(a5)+
	move.w	#$8000,(a5)+
	move.w	#bltafwm,(a5)+
	move.w	#$ffff,(a5)+
	move.w	#bltalwm,(a5)+
	move.w	#$ffff,(a5)+
	move.w	#bltcmod,(a5)+
	move.w	#L_Width,(a5)+
	move.w	#bltdmod,(a5)+
	move.w	#L_Width,(a5)+

	lea	DOT_Line_Area(pc),a3	;Line Area in a3
DO_Next_Line:
	move.w	(a3)+,d4		;Get Color in d4
	bmi.s	DO_Draw_Clipped
	movem.w	(a3)+,d0-d3
	bsr.w	Line
	bra.s	DO_Next_Line

DO_Draw_Clipped:
	lea	DOT_Clipped(pc),a3
DO_Next_Clipped_Line:
	move.w	(a3)+,d4
	bmi.s	DO_Fill
	move.w	(a3)+,d1
	move.w	(a3)+,d3
	bsr.w	Line_Vertical
	bra.s	DO_Next_Clipped_Line

DO_Fill:
	lea	$4ffe(a0),a0
	move.l	#$00010000,(a5)+
	move.l	#$0001fffe,(a5)+
	move.w	#bltcon0,(a5)+
	move.w	#$09f0,(a5)+
	move.w	#bltcon1,(a5)+
	move.w	#$001a,(a5)+
	move.w	#bltafwm,(a5)+
	move.w	#$ffff,(a5)+
	move.w	#bltalwm,(a5)+
	move.w	#$ffff,(a5)+
	move.l	a0,d0
	move.w	#bltapt+2,(a5)+
	move.w	d0,(a5)+
	swap	d0
	move.w	#bltapt,(a5)+
	move.w	d0,(a5)+
	move.l	a0,d0
	move.w	#bltdpt+2,(a5)+
	move.w	d0,(a5)+
	swap	d0
	move.w	#bltdpt,(a5)+
	move.w	d0,(a5)+
	move.w	#bltamod,(a5)+
	move.w	#$0000,(a5)+
	move.w	#bltdmod,(a5)+
	move.w	#$0000,(a5)+
	move.w	#bltsize,(a5)+
	move.w	#$8014,(a5)+

	move.l	#$00010000,(a5)+	;Wait blitter finish
	move.l	#$0001fffe,(a5)+
	move.l	#$fffffffe,(a5)+	;End of Copper list
	move.l	#$fffffffe,(a5)+	;End of Copper list

	lea	BV_CopperDrawBlitter,a0
	move.l	a0,cop2lc(a6)
	move.w	#0,copjmp2(a6)

	movem.l	(sp)+,d0-a5
	rts

Line:	movem.l	d2-d7/a3,-(sp)
	cmp.w	d1,d3			;Compare y0 and y1
	beq	L_End			;if y0=y1 then no line
	bgt.s	L_NoChange		;if y1>y0 then Cords ok !!
	exg	d2,d0			;Exchange x0 with x1
	exg	d3,d1			;Exchange y0 with y1
L_NoChange:
	subq	#1,d3			;y1=y1-1
	sub.w	d1,d3			;Calculate dy=y1-y0
	sub.w	d0,d2			;Calculate dx=x1-x0
	bmi.s	L_dxNeg			
	move.l	#$0b4a0013,d5			
	cmp.w	d2,d3			
	blt.s	L_Finish		
	exg	d2,d3			
	move.l	#$0b4a0003,d5
	bra.s	L_Finish
L_dxNeg:
	neg	d2
	move.l	#$0b4a0017,d5
	cmp.w	d2,d3
	blt.s	L_Finish
	exg	d2,d3
	move.l	#$0b4a000b,d5
L_Finish:
	swap	d5
	add.w	d1,d1		;y1 * 4 calc offset
	move.w	0(a1,d1.w),d1	;Get y offset from table
	lea	0(a0,d1.w),a3	;Calc Address of pixel row
	move.w	d0,d1		;x0 in d1
	lsr.w	#4,d1		;x0 / 16
	add.w	d1,d1		;x0 * 2 For Address of First Pixel
	lea	0(a3,d1.w),a3	;Adress of First Pixel in a2
	andi.w	#$000f,d0	;Get Shift in d0
	ror.w	#$0004,d0	;place Shift value
	or.w	d0,d5		;b4a-or mode and bca-normal mode
	swap	d5
	add.w	d3,d3		;dy*2 This is for BLTBMOD
	move.w	d3,d1		;2dy in d1
	swap	d3
	sub.w	d2,d1		;d1=2dy-dx This is for BLTAPTL
	bpl.s	L_NoSignFlag	;test for sign flag
	ori.w	#$0040,d5
L_NoSignFlag:
	move.w	d1,d3		;2dy-dx in d1
	sub.w	d2,d3		;d1=2dy-2dx This is for BLTAMOD
	add.w	d2,d2		;Add 1 to Height and 1 to width
	move.w	(a2,d2.w),d2	;Set BLTSIZE in d2

	moveq	#L_BMaps-1,d7
L_NextBitmap:
	lsr.w	#1,d4
	bcc.s	L_NothingOnBM
	move.l	#$00010000,(a5)+
	move.l	#$0001fffe,(a5)+
	move.w	#bltamod,(a5)+	;BLTAMOD
	move.w	d3,(a5)+	;2dy-2dx
	swap	d3
	move.w	#bltbmod,(a5)+	;BLTBMOD
	move.w	d3,(a5)+	;2dy
	swap	d3
	move.w	#bltapt+2,(a5)+	;BLTAPTL
	move.w	d1,(a5)+	;2dy-dx
	move.w	#bltcon1,(a5)+	;BLTCON1
	move.w	d5,(a5)+
	swap	d5
	move.w	#bltcon0,(a5)+	;BLTCON0
	move.w	d5,(a5)+
	swap	d5
	move.l	a3,d6
	move.w	#bltcpt+2,(a5)+	;BLTCPTL
	move.w	d6,(a5)+
	swap	d6
	move.w	#bltcpt,(a5)+	;BLTCPTH
	move.w	d6,(a5)+
	swap	d6
	move.w	#bltdpt+2,(a5)+	;BLTDPTL
	move.w	d6,(a5)+
	swap	d6
	move.w	#bltdpt,(a5)+	;BLTDPTH
	move.w	d6,(a5)+
	move.w	#bltsize,(a5)+	;BLTSIZE
	move.w	d2,(a5)+
L_NothingOnBM:
	lea	L_BMapWid(a3),a3	;Adress of next Bit Map in a3
	dbf	d7,L_NextBitmap
L_End:	movem.l	(sp)+,d2-d7/a3
	rts

Line_Vertical:
	movem.l	d2-d7/a3,-(sp)
	cmp.w	d1,d3
	beq	LV_End
	bgt.s	LV_NoChange
	exg	d1,d3
LV_NoChange:
	subq.w	#$01,d3
	sub.w	d1,d3
	move.l	#$fb4a0043,d5
	add.w	d1,d1
	move.w	$00(a1,d1.w),d1
	lea	$26(a0,d1.w),a3
	move.w	d3,d1		;dx in d1
	neg.w	d1
	add.w	d3,d3
	move.w	$00(a2,d3.w),d2	;BLTSIZE in d2
	neg.w	d3
	ext.l	d3

	moveq	#L_BMaps-1,d7
LV_NextBitmap:
	lsr.w	#1,d4
	bcc.s	LV_NothingOnBM
	move.l	#$00010000,(a5)+
	move.l	#$0001fffe,(a5)+
	move.w	#bltamod,(a5)+	;BLTAMOD
	move.w	d3,(a5)+	;2dy-2dx
	swap	d3
	move.w	#bltbmod,(a5)+	;BLTBMOD
	move.w	d3,(a5)+	;2dy
	swap	d3
	move.w	#bltapt+2,(a5)+	;BLTAPTL
	move.w	d1,(a5)+	;2dy-dx
	move.w	#bltcon1,(a5)+	;BLTCON1
	move.w	d5,(a5)+
	swap	d5
	move.w	#bltcon0,(a5)+	;BLTCON0
	move.w	d5,(a5)+
	swap	d5
	move.l	a3,d6
	move.w	#bltcpt+2,(a5)+	;BLTCPTL
	move.w	d6,(a5)+
	swap	d6
	move.w	#bltcpt,(a5)+	;BLTCPTH
	move.w	d6,(a5)+
	swap	d6
	move.w	#bltdpt+2,(a5)+	;BLTDPTL
	move.w	d6,(a5)+
	swap	d6
	move.w	#bltdpt,(a5)+	;BLTDPTH
	move.w	d6,(a5)+
	move.w	#bltsize,(a5)+	;BLTSIZE
	move.w	d2,(a5)+
LV_NothingOnBM:
	lea	L_BMapWid(a3),a3	;Adress of next Bit Map in a2
	dbf	d7,LV_NextBitmap
LV_End:	movem.l	(sp)+,d2-d7/a3
	rts

Move_Object:
	movem.l	d0-d1/a0,-(sp)
	; rotate object
	move.l	Curent_Object(pc),a0
	add.w	#$0010,$04(a0)
	add.w	#$0008,$06(a0)
	add.w	#$0020,$08(a0)

	; move object
	jsr	Mouse
	add.w	d0,$0a(a0)
	btst	#$0a,$16(a6)
	bne.s	CI_RMB_NP
	sub.w	d1,$0e(a0)
	bra.s	CI_RMB_YP
CI_RMB_NP:
	add.w	d1,$0c(a0)
CI_RMB_YP:
	movem.l	(sp)+,d0-d1/a0
	rts

RotateXYZ:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	Curent_Object(pc),a0		;Adr. of Obj. data in a0
	addq.l	#$04,a0				;Get Address of Angles in a0
	lea	R_CalculationsBefore(pc),a1	;Adr. of Calc. Field in a1
	lea	R_SinCosTable(pc),a2		;Adr. of Sin & Cos Table in a2
	movem.w	(a0),d0-d2	;Put Curent Alpha,Beta & Gama in d0-d2
	move.w	#$1ffe,d3	;Get mask in d3
	and.w	d3,d0		;Alpha Ok!
	and.w	d3,d1		;Beta Ok!
	and.w	d3,d2		;Gama Ok!
	movem.w	d0-d2,(a0)	;Put Curent Alpha,Beta & Gama in table.
	addq.l	#$06,a0		;This part of table is finished
	move.w	(a2,d0.w),d3	;Sin(Alpha) in d3
	move.w	(a2,d1.w),d4	;Sin(Beta) in d4
	move.w	(a2,d2.w),d5	;Sin(Gama) in d5
	lea	$800(a2),a2	;Address of Cos table in a3
	move.w	(a2,d0.w),d0	;Cos(Alpha) in d0
	move.w	(a2,d1.w),d1	;Cos(Beta) in d1
	move.w	(a2,d2.w),d2	;Cos(Gama) in d2
	move.w	d1,d6		;Cos(Beta) in d6
	muls	d2,d6		;Cos(Beta) * Cos(Gama) in d6
	add.l	d6,d6
	swap	d6
	move.w	d6,$00(a1)	;A Part Finished
	move.w	d1,d6		;Cos(Beta) in d6
	muls	d5,d6		;Cos(Beta) * Sin(Gama) in d6
	add.l	d6,d6
	swap	d6
	neg.w	d6		;-(Cos(Beta) * Sin(Gama)) in d6
	move.w	d6,$02(a1)	;B Part Finished
	move.w	d4,$04(a1)	;C Part Finished
	move.w	d1,d6		;Cos(Beta) in d6
	muls	d3,d6		;Sin(Alpha) * Cos(Beta) in d6
	add.l	d6,d6
	swap	d6
	neg.w	d6		;-(Sin(Alpha) * Cos(Beta)) in d6
	move.w	d6,$0a(a1)	;F Part Finished
	muls	d0,d1		;Cos(Alpha) * Cos(Beta) in d1
	add.l	d1,d1
	swap	d1
	move.w	d1,$10(a1)	;I Part Finished
	move.w	d0,d6		;Cos(Alpha) in d6
	move.w	d3,d7		;Sin(Alpha) in d7
	muls	d5,d0		;Cos(Alpha) * Sin(Gama) in d0
	add.l	d0,d0
	swap	d0
	muls	d2,d6		;Cos(Alpha) * Cos(Gama) in d6
	add.l	d6,d6
	swap	d6
	muls	d5,d3		;Sin(Alpha) * Sin(Gama) in d3
	add.l	d3,d3
	swap	d3
	muls	d2,d7		;Sin(Alpha) * Cos(Gama) in d7
	add.l	d7,d7
	swap	d7
	move.w	d7,d1		;Sin(Alpha) * Cos(Gama) in d1
	muls	d4,d1		;Sin(Alpha) * Sin(Beta) * Cos(Gama) in d1
	add.l	d1,d1
	swap	d1
	add.w	d0,d1		;Cos(Alpha) * Sin(Gama) + Sin(Alpha) * Sin(Beta) * Cos(Gama) in d1
	move.w	d1,$06(a1)	;D Part Finished
	move.w	d3,d1		;Sin(Alpha) * Sin(Gama) in d1
	muls	d4,d1		;Sin(Alpha) * Sin(Beta) * Sin(Gama) in d1
	add.l	d1,d1
	swap	d1
	neg.w	d1		;-(Sin(Alpha) * Sin(Beta) * Sin(Gama)) in d1
	add.w	d6,d1		;Cos(Alpha) * Cos(Gama) - Sin(Alpha) * Sin(Beta) * Sin(Gama) in d1
	move.w	d1,$08(a1)	;E Part Finished
	muls	d4,d6		;Cos(Alpha) * Sin(Beta) * Cos(Gama) in d6
	add.l	d6,d6
	swap	d6
	neg.w	d6		;-(Cos(Alpha) * Sin(Beta) * Cos(Gama)) in d6
	add.w	d3,d6		;Sin(Alpha) * Sin(Gama) - Cos(Alpha) * Sin(Beta) * Cos(Gama) in d6
	move.w	d6,$0c(a1)	;G Part Finished
	muls	d4,d0		;Cos(Alpha) * Sin(Beta) * Sin(Gama) in d0
	add.l	d0,d0
	swap	d0
	add.w	d7,d0		;Sin(Alpha) * Cos(Gama) + Cos(Alpha) * Sin(Beta) * Sin(Gama) in d0
	move.w	d0,$0e(a1)	;H Part Finished
	movem.w	(a0)+,a3/a4/a5	;TX in a3  TY in a4  TZ in a5
	move.l	$0004(a0),a2	;Rotated Dots Area in a2
	move.l	(a0),a0		;Dots Area in a0
R_RotateNextDot:
	movem.w	(a0)+,d3-d5	;X0-->d3.w  Y0-->d4.w  Z0-->d5.w
	movem.w	(a1)+,d0-d2	;A -->d0.w  B -->d1.w  C -->d2.w
	muls	d3,d0		;d0=A*X0
	muls	d4,d1		;d1=B*Y0
	muls	d5,d2		;d2=C*Z0
	add.l	d1,d0		;d0=A*X0+B*Y0
	add.l	d2,d0		;d0=A*X0+B*Y0+C*Z0
	swap	d0		;X/32768
	add.w	a3,d0		;X+TX
	move.w	d0,d6		;X in d6 ****
	movem.w	(a1)+,d0-d2	;D -->d0.w  E -->d1.w  F -->d2.w
	muls	d3,d0		;D0=D*X0
	muls	d4,d1		;D1=E*Y0
	muls	d5,d2		;d2=F*Z0
	add.l	d0,d1		;D0=D*X0+E*Y0
	add.l	d2,d1		;D0=D*X0+E*Y0+F*Z0
	swap	d1		;Y/32768
	add.w	a4,d1		;Y+TY
	move.w	d1,d7		;Y in d7 ****
	movem.w	(a1)+,d0-d2	;G -->d0.w  H -->d1.w  I -->d2.w
	muls	d3,d0		;G*X0
	muls	d4,d1		;H*Y0
	muls	d5,d2		;I*Z0
	add.l	d1,d2		;d2=H*Y0+I*Z0
	add.l	d0,d2		;d2=G*X0+H*Y0+I*Z0
	swap	d2		;Z/32768
	add.w	a5,d2		;Z+TZ
	move.w	#512,d3		;Zaslon in d3
	add.w	d3,d2		;Z+Zaslon in d2
	muls	d3,d6		;Zaslon*X
	muls	d3,d7		;Zaslon*Y
	divs	d2,d6		;(Zaslon*X)/(Z+Zaslon)
	divs	d2,d7		;(Zaslon*Y)/(Z+Zaslon)

	add.w	#160,d6
	add.w	#128,d7

	move.w	d6,(a2)+	;X Rotated in Memory
	move.w	d7,(a2)+	;Y Rotared in Memory
;	move.w	d2,(a2)+	;Z Rotated in Memory  !!!!!!
	lea	-$12(a1),a1
	cmp.w	#$ffff,(a0)
	bne.s	R_RotateNextDot

	movem.l	(sp)+,d0-d7/a0-a6
	rts

R_CalculationsBefore:
	dc.w	0	;A  $00(An) Cos(Beta) * Cos(Gama)
	dc.w	0	;B  $02(An) -(Cos(Beta) * Sin(Gama))
	dc.w	0	;C  $04(An) Sin(Beta)
	dc.w	0	;D  $06(An) Cos(Alpha) * Sin(Gama) + Sin(Alpha) * Sin(Beta) * Cos(Gama)
	dc.w	0	;E  $08(An) Cos(Alpha) * Cos(Gama) - Sin(Alpha) * Sin(Beta) * Sin(Gama) 
	dc.w	0	;F  $0a(An) -(Sin(Alpha) * Cos(Beta))
	dc.w	0	;G  $0c(An) Sin(Alpha) * Sin(Gama) - Cos(Alpha) * Sin(Beta) * Cos(Gama)
	dc.w	0	;H  $0e(An) Sin(Alpha) * Cos(Gama) + Cos(Alpha) * Sin(Beta) * Sin(Gama)
	dc.w	0	;I  $10(An) Cos(Alpha) * Cos(Beta)

R_SinCosTable:
;	blk.w	5120,0
;	AUTO	CS\R_SinCosTable\0\450\5120\32767\0\W1\yy
;@generated-datagen-start----------------
; This code was generated by Amiga Assembly extension
;
;----- parameters : modify ------
;expression(x as variable): round(sin(x*(pi/2*5/5120))*32767)
;variable:
;   name:x
;   startValue:0
;   endValue:5119
;   step:1
;outputType(B,W,L): W
;outputInHex: true
;valuesPerLine: 16
;--------------------------------
;- DO NOT MODIFY following lines -
 ; -> SIGNED values <-
 dc.w $0000, $0032, $0065, $0097, $00c9, $00fb, $012e, $0160, $0192, $01c4, $01f7, $0229, $025b, $028d, $02c0, $02f2
 dc.w $0324, $0356, $0389, $03bb, $03ed, $041f, $0452, $0484, $04b6, $04e8, $051b, $054d, $057f, $05b1, $05e3, $0616
 dc.w $0648, $067a, $06ac, $06de, $0711, $0743, $0775, $07a7, $07d9, $080b, $083e, $0870, $08a2, $08d4, $0906, $0938
 dc.w $096a, $099d, $09cf, $0a01, $0a33, $0a65, $0a97, $0ac9, $0afb, $0b2d, $0b5f, $0b92, $0bc4, $0bf6, $0c28, $0c5a
 dc.w $0c8c, $0cbe, $0cf0, $0d22, $0d54, $0d86, $0db8, $0dea, $0e1c, $0e4e, $0e80, $0eb1, $0ee3, $0f15, $0f47, $0f79
 dc.w $0fab, $0fdd, $100f, $1041, $1072, $10a4, $10d6, $1108, $113a, $116c, $119d, $11cf, $1201, $1233, $1264, $1296
 dc.w $12c8, $12fa, $132b, $135d, $138f, $13c0, $13f2, $1424, $1455, $1487, $14b9, $14ea, $151c, $154d, $157f, $15b0
 dc.w $15e2, $1613, $1645, $1676, $16a8, $16d9, $170b, $173c, $176e, $179f, $17d0, $1802, $1833, $1865, $1896, $18c7
 dc.w $18f9, $192a, $195b, $198c, $19be, $19ef, $1a20, $1a51, $1a82, $1ab4, $1ae5, $1b16, $1b47, $1b78, $1ba9, $1bda
 dc.w $1c0b, $1c3c, $1c6d, $1c9e, $1ccf, $1d00, $1d31, $1d62, $1d93, $1dc4, $1df5, $1e26, $1e57, $1e87, $1eb8, $1ee9
 dc.w $1f1a, $1f4a, $1f7b, $1fac, $1fdd, $200d, $203e, $206f, $209f, $20d0, $2100, $2131, $2161, $2192, $21c2, $21f3
 dc.w $2223, $2254, $2284, $22b5, $22e5, $2315, $2346, $2376, $23a6, $23d7, $2407, $2437, $2467, $2497, $24c8, $24f8
 dc.w $2528, $2558, $2588, $25b8, $25e8, $2618, $2648, $2678, $26a8, $26d8, $2708, $2737, $2767, $2797, $27c7, $27f7
 dc.w $2826, $2856, $2886, $28b5, $28e5, $2915, $2944, $2974, $29a3, $29d3, $2a02, $2a32, $2a61, $2a91, $2ac0, $2af0
 dc.w $2b1f, $2b4e, $2b7d, $2bad, $2bdc, $2c0b, $2c3a, $2c6a, $2c99, $2cc8, $2cf7, $2d26, $2d55, $2d84, $2db3, $2de2
 dc.w $2e11, $2e40, $2e6e, $2e9d, $2ecc, $2efb, $2f2a, $2f58, $2f87, $2fb6, $2fe4, $3013, $3041, $3070, $309e, $30cd
 dc.w $30fb, $312a, $3158, $3187, $31b5, $31e3, $3211, $3240, $326e, $329c, $32ca, $32f8, $3326, $3355, $3383, $33b1
 dc.w $33df, $340c, $343a, $3468, $3496, $34c4, $34f2, $351f, $354d, $357b, $35a8, $35d6, $3604, $3631, $365f, $368c
 dc.w $36ba, $36e7, $3715, $3742, $376f, $379c, $37ca, $37f7, $3824, $3851, $387e, $38ab, $38d9, $3906, $3933, $3960
 dc.w $398c, $39b9, $39e6, $3a13, $3a40, $3a6c, $3a99, $3ac6, $3af2, $3b1f, $3b4c, $3b78, $3ba5, $3bd1, $3bfe, $3c2a
 dc.w $3c56, $3c83, $3caf, $3cdb, $3d07, $3d33, $3d60, $3d8c, $3db8, $3de4, $3e10, $3e3c, $3e68, $3e93, $3ebf, $3eeb
 dc.w $3f17, $3f43, $3f6e, $3f9a, $3fc5, $3ff1, $401d, $4048, $4073, $409f, $40ca, $40f6, $4121, $414c, $4177, $41a2
 dc.w $41ce, $41f9, $4224, $424f, $427a, $42a5, $42d0, $42fa, $4325, $4350, $437b, $43a5, $43d0, $43fb, $4425, $4450
 dc.w $447a, $44a5, $44cf, $44f9, $4524, $454e, $4578, $45a3, $45cd, $45f7, $4621, $464b, $4675, $469f, $46c9, $46f3
 dc.w $471c, $4746, $4770, $479a, $47c3, $47ed, $4816, $4840, $4869, $4893, $48bc, $48e5, $490f, $4938, $4961, $498a
 dc.w $49b4, $49dd, $4a06, $4a2f, $4a58, $4a80, $4aa9, $4ad2, $4afb, $4b24, $4b4c, $4b75, $4b9d, $4bc6, $4bee, $4c17
 dc.w $4c3f, $4c68, $4c90, $4cb8, $4ce0, $4d09, $4d31, $4d59, $4d81, $4da9, $4dd1, $4df9, $4e20, $4e48, $4e70, $4e98
 dc.w $4ebf, $4ee7, $4f0e, $4f36, $4f5d, $4f85, $4fac, $4fd4, $4ffb, $5022, $5049, $5070, $5097, $50be, $50e5, $510c
 dc.w $5133, $515a, $5181, $51a8, $51ce, $51f5, $521b, $5242, $5268, $528f, $52b5, $52dc, $5302, $5328, $534e, $5374
 dc.w $539b, $53c1, $53e7, $540c, $5432, $5458, $547e, $54a4, $54c9, $54ef, $5515, $553a, $5560, $5585, $55aa, $55d0
 dc.w $55f5, $561a, $563f, $5664, $568a, $56af, $56d3, $56f8, $571d, $5742, $5767, $578b, $57b0, $57d5, $57f9, $581e
 dc.w $5842, $5867, $588b, $58af, $58d3, $58f8, $591c, $5940, $5964, $5988, $59ac, $59cf, $59f3, $5a17, $5a3b, $5a5e
 dc.w $5a82, $5aa5, $5ac9, $5aec, $5b0f, $5b33, $5b56, $5b79, $5b9c, $5bbf, $5be2, $5c05, $5c28, $5c4b, $5c6e, $5c91
 dc.w $5cb3, $5cd6, $5cf9, $5d1b, $5d3e, $5d60, $5d82, $5da5, $5dc7, $5de9, $5e0b, $5e2d, $5e4f, $5e71, $5e93, $5eb5
 dc.w $5ed7, $5ef8, $5f1a, $5f3c, $5f5d, $5f7f, $5fa0, $5fc2, $5fe3, $6004, $6025, $6047, $6068, $6089, $60aa, $60cb
 dc.w $60eb, $610c, $612d, $614e, $616e, $618f, $61af, $61d0, $61f0, $6211, $6231, $6251, $6271, $6291, $62b1, $62d1
 dc.w $62f1, $6311, $6331, $6351, $6370, $6390, $63af, $63cf, $63ee, $640e, $642d, $644c, $646c, $648b, $64aa, $64c9
 dc.w $64e8, $6507, $6525, $6544, $6563, $6582, $65a0, $65bf, $65dd, $65fc, $661a, $6638, $6656, $6675, $6693, $66b1
 dc.w $66cf, $66ed, $670a, $6728, $6746, $6764, $6781, $679f, $67bc, $67da, $67f7, $6814, $6832, $684f, $686c, $6889
 dc.w $68a6, $68c3, $68e0, $68fc, $6919, $6936, $6952, $696f, $698b, $69a8, $69c4, $69e0, $69fd, $6a19, $6a35, $6a51
 dc.w $6a6d, $6a89, $6aa4, $6ac0, $6adc, $6af8, $6b13, $6b2f, $6b4a, $6b65, $6b81, $6b9c, $6bb7, $6bd2, $6bed, $6c08
 dc.w $6c23, $6c3e, $6c59, $6c74, $6c8e, $6ca9, $6cc3, $6cde, $6cf8, $6d13, $6d2d, $6d47, $6d61, $6d7b, $6d95, $6daf
 dc.w $6dc9, $6de3, $6dfd, $6e16, $6e30, $6e4a, $6e63, $6e7c, $6e96, $6eaf, $6ec8, $6ee1, $6efb, $6f14, $6f2c, $6f45
 dc.w $6f5e, $6f77, $6f90, $6fa8, $6fc1, $6fd9, $6ff2, $700a, $7022, $703a, $7053, $706b, $7083, $709b, $70b2, $70ca
 dc.w $70e2, $70fa, $7111, $7129, $7140, $7158, $716f, $7186, $719d, $71b4, $71cb, $71e2, $71f9, $7210, $7227, $723e
 dc.w $7254, $726b, $7281, $7298, $72ae, $72c4, $72db, $72f1, $7307, $731d, $7333, $7349, $735e, $7374, $738a, $739f
 dc.w $73b5, $73ca, $73e0, $73f5, $740a, $7420, $7435, $744a, $745f, $7474, $7488, $749d, $74b2, $74c6, $74db, $74f0
 dc.w $7504, $7518, $752d, $7541, $7555, $7569, $757d, $7591, $75a5, $75b8, $75cc, $75e0, $75f3, $7607, $761a, $762d
 dc.w $7641, $7654, $7667, $767a, $768d, $76a0, $76b3, $76c6, $76d8, $76eb, $76fe, $7710, $7722, $7735, $7747, $7759
 dc.w $776b, $777d, $778f, $77a1, $77b3, $77c5, $77d7, $77e8, $77fa, $780b, $781d, $782e, $783f, $7850, $7862, $7873
 dc.w $7884, $7894, $78a5, $78b6, $78c7, $78d7, $78e8, $78f8, $7909, $7919, $7929, $7939, $794a, $795a, $796a, $7979
 dc.w $7989, $7999, $79a9, $79b8, $79c8, $79d7, $79e6, $79f6, $7a05, $7a14, $7a23, $7a32, $7a41, $7a50, $7a5f, $7a6d
 dc.w $7a7c, $7a8b, $7a99, $7aa8, $7ab6, $7ac4, $7ad2, $7ae0, $7aee, $7afc, $7b0a, $7b18, $7b26, $7b33, $7b41, $7b4f
 dc.w $7b5c, $7b69, $7b77, $7b84, $7b91, $7b9e, $7bab, $7bb8, $7bc5, $7bd2, $7bde, $7beb, $7bf8, $7c04, $7c10, $7c1d
 dc.w $7c29, $7c35, $7c41, $7c4d, $7c59, $7c65, $7c71, $7c7d, $7c88, $7c94, $7c9f, $7cab, $7cb6, $7cc1, $7ccd, $7cd8
 dc.w $7ce3, $7cee, $7cf9, $7d04, $7d0e, $7d19, $7d24, $7d2e, $7d39, $7d43, $7d4d, $7d57, $7d62, $7d6c, $7d76, $7d80
 dc.w $7d89, $7d93, $7d9d, $7da6, $7db0, $7db9, $7dc3, $7dcc, $7dd5, $7ddf, $7de8, $7df1, $7dfa, $7e02, $7e0b, $7e14
 dc.w $7e1d, $7e25, $7e2e, $7e36, $7e3e, $7e47, $7e4f, $7e57, $7e5f, $7e67, $7e6f, $7e77, $7e7e, $7e86, $7e8d, $7e95
 dc.w $7e9c, $7ea4, $7eab, $7eb2, $7eb9, $7ec0, $7ec7, $7ece, $7ed5, $7edc, $7ee2, $7ee9, $7eef, $7ef6, $7efc, $7f02
 dc.w $7f09, $7f0f, $7f15, $7f1b, $7f21, $7f26, $7f2c, $7f32, $7f37, $7f3d, $7f42, $7f48, $7f4d, $7f52, $7f57, $7f5c
 dc.w $7f61, $7f66, $7f6b, $7f70, $7f74, $7f79, $7f7d, $7f82, $7f86, $7f8a, $7f8f, $7f93, $7f97, $7f9b, $7f9f, $7fa2
 dc.w $7fa6, $7faa, $7fad, $7fb1, $7fb4, $7fb8, $7fbb, $7fbe, $7fc1, $7fc4, $7fc7, $7fca, $7fcd, $7fd0, $7fd2, $7fd5
 dc.w $7fd8, $7fda, $7fdc, $7fdf, $7fe1, $7fe3, $7fe5, $7fe7, $7fe9, $7feb, $7fec, $7fee, $7ff0, $7ff1, $7ff3, $7ff4
 dc.w $7ff5, $7ff6, $7ff7, $7ff8, $7ff9, $7ffa, $7ffb, $7ffc, $7ffd, $7ffd, $7ffe, $7ffe, $7ffe, $7fff, $7fff, $7fff
 dc.w $7fff, $7fff, $7fff, $7fff, $7ffe, $7ffe, $7ffe, $7ffd, $7ffd, $7ffc, $7ffb, $7ffa, $7ff9, $7ff8, $7ff7, $7ff6
 dc.w $7ff5, $7ff4, $7ff3, $7ff1, $7ff0, $7fee, $7fec, $7feb, $7fe9, $7fe7, $7fe5, $7fe3, $7fe1, $7fdf, $7fdc, $7fda
 dc.w $7fd8, $7fd5, $7fd2, $7fd0, $7fcd, $7fca, $7fc7, $7fc4, $7fc1, $7fbe, $7fbb, $7fb8, $7fb4, $7fb1, $7fad, $7faa
 dc.w $7fa6, $7fa2, $7f9f, $7f9b, $7f97, $7f93, $7f8f, $7f8a, $7f86, $7f82, $7f7d, $7f79, $7f74, $7f70, $7f6b, $7f66
 dc.w $7f61, $7f5c, $7f57, $7f52, $7f4d, $7f48, $7f42, $7f3d, $7f37, $7f32, $7f2c, $7f26, $7f21, $7f1b, $7f15, $7f0f
 dc.w $7f09, $7f02, $7efc, $7ef6, $7eef, $7ee9, $7ee2, $7edc, $7ed5, $7ece, $7ec7, $7ec0, $7eb9, $7eb2, $7eab, $7ea4
 dc.w $7e9c, $7e95, $7e8d, $7e86, $7e7e, $7e77, $7e6f, $7e67, $7e5f, $7e57, $7e4f, $7e47, $7e3e, $7e36, $7e2e, $7e25
 dc.w $7e1d, $7e14, $7e0b, $7e02, $7dfa, $7df1, $7de8, $7ddf, $7dd5, $7dcc, $7dc3, $7db9, $7db0, $7da6, $7d9d, $7d93
 dc.w $7d89, $7d80, $7d76, $7d6c, $7d62, $7d57, $7d4d, $7d43, $7d39, $7d2e, $7d24, $7d19, $7d0e, $7d04, $7cf9, $7cee
 dc.w $7ce3, $7cd8, $7ccd, $7cc1, $7cb6, $7cab, $7c9f, $7c94, $7c88, $7c7d, $7c71, $7c65, $7c59, $7c4d, $7c41, $7c35
 dc.w $7c29, $7c1d, $7c10, $7c04, $7bf8, $7beb, $7bde, $7bd2, $7bc5, $7bb8, $7bab, $7b9e, $7b91, $7b84, $7b77, $7b69
 dc.w $7b5c, $7b4f, $7b41, $7b33, $7b26, $7b18, $7b0a, $7afc, $7aee, $7ae0, $7ad2, $7ac4, $7ab6, $7aa8, $7a99, $7a8b
 dc.w $7a7c, $7a6d, $7a5f, $7a50, $7a41, $7a32, $7a23, $7a14, $7a05, $79f6, $79e6, $79d7, $79c8, $79b8, $79a9, $7999
 dc.w $7989, $7979, $796a, $795a, $794a, $7939, $7929, $7919, $7909, $78f8, $78e8, $78d7, $78c7, $78b6, $78a5, $7894
 dc.w $7884, $7873, $7862, $7850, $783f, $782e, $781d, $780b, $77fa, $77e8, $77d7, $77c5, $77b3, $77a1, $778f, $777d
 dc.w $776b, $7759, $7747, $7735, $7722, $7710, $76fe, $76eb, $76d8, $76c6, $76b3, $76a0, $768d, $767a, $7667, $7654
 dc.w $7641, $762d, $761a, $7607, $75f3, $75e0, $75cc, $75b8, $75a5, $7591, $757d, $7569, $7555, $7541, $752d, $7518
 dc.w $7504, $74f0, $74db, $74c6, $74b2, $749d, $7488, $7474, $745f, $744a, $7435, $7420, $740a, $73f5, $73e0, $73ca
 dc.w $73b5, $739f, $738a, $7374, $735e, $7349, $7333, $731d, $7307, $72f1, $72db, $72c4, $72ae, $7298, $7281, $726b
 dc.w $7254, $723e, $7227, $7210, $71f9, $71e2, $71cb, $71b4, $719d, $7186, $716f, $7158, $7140, $7129, $7111, $70fa
 dc.w $70e2, $70ca, $70b2, $709b, $7083, $706b, $7053, $703a, $7022, $700a, $6ff2, $6fd9, $6fc1, $6fa8, $6f90, $6f77
 dc.w $6f5e, $6f45, $6f2c, $6f14, $6efb, $6ee1, $6ec8, $6eaf, $6e96, $6e7c, $6e63, $6e4a, $6e30, $6e16, $6dfd, $6de3
 dc.w $6dc9, $6daf, $6d95, $6d7b, $6d61, $6d47, $6d2d, $6d13, $6cf8, $6cde, $6cc3, $6ca9, $6c8e, $6c74, $6c59, $6c3e
 dc.w $6c23, $6c08, $6bed, $6bd2, $6bb7, $6b9c, $6b81, $6b65, $6b4a, $6b2f, $6b13, $6af8, $6adc, $6ac0, $6aa4, $6a89
 dc.w $6a6d, $6a51, $6a35, $6a19, $69fd, $69e0, $69c4, $69a8, $698b, $696f, $6952, $6936, $6919, $68fc, $68e0, $68c3
 dc.w $68a6, $6889, $686c, $684f, $6832, $6814, $67f7, $67da, $67bc, $679f, $6781, $6764, $6746, $6728, $670a, $66ed
 dc.w $66cf, $66b1, $6693, $6675, $6656, $6638, $661a, $65fc, $65dd, $65bf, $65a0, $6582, $6563, $6544, $6525, $6507
 dc.w $64e8, $64c9, $64aa, $648b, $646c, $644c, $642d, $640e, $63ee, $63cf, $63af, $6390, $6370, $6351, $6331, $6311
 dc.w $62f1, $62d1, $62b1, $6291, $6271, $6251, $6231, $6211, $61f0, $61d0, $61af, $618f, $616e, $614e, $612d, $610c
 dc.w $60eb, $60cb, $60aa, $6089, $6068, $6047, $6025, $6004, $5fe3, $5fc2, $5fa0, $5f7f, $5f5d, $5f3c, $5f1a, $5ef8
 dc.w $5ed7, $5eb5, $5e93, $5e71, $5e4f, $5e2d, $5e0b, $5de9, $5dc7, $5da5, $5d82, $5d60, $5d3e, $5d1b, $5cf9, $5cd6
 dc.w $5cb3, $5c91, $5c6e, $5c4b, $5c28, $5c05, $5be2, $5bbf, $5b9c, $5b79, $5b56, $5b33, $5b0f, $5aec, $5ac9, $5aa5
 dc.w $5a82, $5a5e, $5a3b, $5a17, $59f3, $59cf, $59ac, $5988, $5964, $5940, $591c, $58f8, $58d3, $58af, $588b, $5867
 dc.w $5842, $581e, $57f9, $57d5, $57b0, $578b, $5767, $5742, $571d, $56f8, $56d3, $56af, $568a, $5664, $563f, $561a
 dc.w $55f5, $55d0, $55aa, $5585, $5560, $553a, $5515, $54ef, $54c9, $54a4, $547e, $5458, $5432, $540c, $53e7, $53c1
 dc.w $539b, $5374, $534e, $5328, $5302, $52dc, $52b5, $528f, $5268, $5242, $521b, $51f5, $51ce, $51a8, $5181, $515a
 dc.w $5133, $510c, $50e5, $50be, $5097, $5070, $5049, $5022, $4ffb, $4fd4, $4fac, $4f85, $4f5d, $4f36, $4f0e, $4ee7
 dc.w $4ebf, $4e98, $4e70, $4e48, $4e20, $4df9, $4dd1, $4da9, $4d81, $4d59, $4d31, $4d09, $4ce0, $4cb8, $4c90, $4c68
 dc.w $4c3f, $4c17, $4bee, $4bc6, $4b9d, $4b75, $4b4c, $4b24, $4afb, $4ad2, $4aa9, $4a80, $4a58, $4a2f, $4a06, $49dd
 dc.w $49b4, $498a, $4961, $4938, $490f, $48e5, $48bc, $4893, $4869, $4840, $4816, $47ed, $47c3, $479a, $4770, $4746
 dc.w $471c, $46f3, $46c9, $469f, $4675, $464b, $4621, $45f7, $45cd, $45a3, $4578, $454e, $4524, $44f9, $44cf, $44a5
 dc.w $447a, $4450, $4425, $43fb, $43d0, $43a5, $437b, $4350, $4325, $42fa, $42d0, $42a5, $427a, $424f, $4224, $41f9
 dc.w $41ce, $41a2, $4177, $414c, $4121, $40f6, $40ca, $409f, $4073, $4048, $401d, $3ff1, $3fc5, $3f9a, $3f6e, $3f43
 dc.w $3f17, $3eeb, $3ebf, $3e93, $3e68, $3e3c, $3e10, $3de4, $3db8, $3d8c, $3d60, $3d33, $3d07, $3cdb, $3caf, $3c83
 dc.w $3c56, $3c2a, $3bfe, $3bd1, $3ba5, $3b78, $3b4c, $3b1f, $3af2, $3ac6, $3a99, $3a6c, $3a40, $3a13, $39e6, $39b9
 dc.w $398c, $3960, $3933, $3906, $38d9, $38ab, $387e, $3851, $3824, $37f7, $37ca, $379c, $376f, $3742, $3715, $36e7
 dc.w $36ba, $368c, $365f, $3631, $3604, $35d6, $35a8, $357b, $354d, $351f, $34f2, $34c4, $3496, $3468, $343a, $340c
 dc.w $33df, $33b1, $3383, $3355, $3326, $32f8, $32ca, $329c, $326e, $3240, $3211, $31e3, $31b5, $3187, $3158, $312a
 dc.w $30fb, $30cd, $309e, $3070, $3041, $3013, $2fe4, $2fb6, $2f87, $2f58, $2f2a, $2efb, $2ecc, $2e9d, $2e6e, $2e40
 dc.w $2e11, $2de2, $2db3, $2d84, $2d55, $2d26, $2cf7, $2cc8, $2c99, $2c6a, $2c3a, $2c0b, $2bdc, $2bad, $2b7d, $2b4e
 dc.w $2b1f, $2af0, $2ac0, $2a91, $2a61, $2a32, $2a02, $29d3, $29a3, $2974, $2944, $2915, $28e5, $28b5, $2886, $2856
 dc.w $2826, $27f7, $27c7, $2797, $2767, $2737, $2708, $26d8, $26a8, $2678, $2648, $2618, $25e8, $25b8, $2588, $2558
 dc.w $2528, $24f8, $24c8, $2497, $2467, $2437, $2407, $23d7, $23a6, $2376, $2346, $2315, $22e5, $22b5, $2284, $2254
 dc.w $2223, $21f3, $21c2, $2192, $2161, $2131, $2100, $20d0, $209f, $206f, $203e, $200d, $1fdd, $1fac, $1f7b, $1f4a
 dc.w $1f1a, $1ee9, $1eb8, $1e87, $1e57, $1e26, $1df5, $1dc4, $1d93, $1d62, $1d31, $1d00, $1ccf, $1c9e, $1c6d, $1c3c
 dc.w $1c0b, $1bda, $1ba9, $1b78, $1b47, $1b16, $1ae5, $1ab4, $1a82, $1a51, $1a20, $19ef, $19be, $198c, $195b, $192a
 dc.w $18f9, $18c7, $1896, $1865, $1833, $1802, $17d0, $179f, $176e, $173c, $170b, $16d9, $16a8, $1676, $1645, $1613
 dc.w $15e2, $15b0, $157f, $154d, $151c, $14ea, $14b9, $1487, $1455, $1424, $13f2, $13c0, $138f, $135d, $132b, $12fa
 dc.w $12c8, $1296, $1264, $1233, $1201, $11cf, $119d, $116c, $113a, $1108, $10d6, $10a4, $1072, $1041, $100f, $0fdd
 dc.w $0fab, $0f79, $0f47, $0f15, $0ee3, $0eb1, $0e80, $0e4e, $0e1c, $0dea, $0db8, $0d86, $0d54, $0d22, $0cf0, $0cbe
 dc.w $0c8c, $0c5a, $0c28, $0bf6, $0bc4, $0b92, $0b5f, $0b2d, $0afb, $0ac9, $0a97, $0a65, $0a33, $0a01, $09cf, $099d
 dc.w $096a, $0938, $0906, $08d4, $08a2, $0870, $083e, $080b, $07d9, $07a7, $0775, $0743, $0711, $06de, $06ac, $067a
 dc.w $0648, $0616, $05e3, $05b1, $057f, $054d, $051b, $04e8, $04b6, $0484, $0452, $041f, $03ed, $03bb, $0389, $0356
 dc.w $0324, $02f2, $02c0, $028d, $025b, $0229, $01f7, $01c4, $0192, $0160, $012e, $00fb, $00c9, $0097, $0065, $0032
 dc.w $0000, $ffce, $ff9b, $ff69, $ff37, $ff05, $fed2, $fea0, $fe6e, $fe3c, $fe09, $fdd7, $fda5, $fd73, $fd40, $fd0e
 dc.w $fcdc, $fcaa, $fc77, $fc45, $fc13, $fbe1, $fbae, $fb7c, $fb4a, $fb18, $fae5, $fab3, $fa81, $fa4f, $fa1d, $f9ea
 dc.w $f9b8, $f986, $f954, $f922, $f8ef, $f8bd, $f88b, $f859, $f827, $f7f5, $f7c2, $f790, $f75e, $f72c, $f6fa, $f6c8
 dc.w $f696, $f663, $f631, $f5ff, $f5cd, $f59b, $f569, $f537, $f505, $f4d3, $f4a1, $f46e, $f43c, $f40a, $f3d8, $f3a6
 dc.w $f374, $f342, $f310, $f2de, $f2ac, $f27a, $f248, $f216, $f1e4, $f1b2, $f180, $f14f, $f11d, $f0eb, $f0b9, $f087
 dc.w $f055, $f023, $eff1, $efbf, $ef8e, $ef5c, $ef2a, $eef8, $eec6, $ee94, $ee63, $ee31, $edff, $edcd, $ed9c, $ed6a
 dc.w $ed38, $ed06, $ecd5, $eca3, $ec71, $ec40, $ec0e, $ebdc, $ebab, $eb79, $eb47, $eb16, $eae4, $eab3, $ea81, $ea50
 dc.w $ea1e, $e9ed, $e9bb, $e98a, $e958, $e927, $e8f5, $e8c4, $e892, $e861, $e830, $e7fe, $e7cd, $e79b, $e76a, $e739
 dc.w $e707, $e6d6, $e6a5, $e674, $e642, $e611, $e5e0, $e5af, $e57e, $e54c, $e51b, $e4ea, $e4b9, $e488, $e457, $e426
 dc.w $e3f5, $e3c4, $e393, $e362, $e331, $e300, $e2cf, $e29e, $e26d, $e23c, $e20b, $e1da, $e1a9, $e179, $e148, $e117
 dc.w $e0e6, $e0b6, $e085, $e054, $e023, $dff3, $dfc2, $df91, $df61, $df30, $df00, $decf, $de9f, $de6e, $de3e, $de0d
 dc.w $dddd, $ddac, $dd7c, $dd4b, $dd1b, $dceb, $dcba, $dc8a, $dc5a, $dc29, $dbf9, $dbc9, $db99, $db69, $db38, $db08
 dc.w $dad8, $daa8, $da78, $da48, $da18, $d9e8, $d9b8, $d988, $d958, $d928, $d8f8, $d8c9, $d899, $d869, $d839, $d809
 dc.w $d7da, $d7aa, $d77a, $d74b, $d71b, $d6eb, $d6bc, $d68c, $d65d, $d62d, $d5fe, $d5ce, $d59f, $d56f, $d540, $d510
 dc.w $d4e1, $d4b2, $d483, $d453, $d424, $d3f5, $d3c6, $d396, $d367, $d338, $d309, $d2da, $d2ab, $d27c, $d24d, $d21e
 dc.w $d1ef, $d1c0, $d192, $d163, $d134, $d105, $d0d6, $d0a8, $d079, $d04a, $d01c, $cfed, $cfbf, $cf90, $cf62, $cf33
 dc.w $cf05, $ced6, $cea8, $ce79, $ce4b, $ce1d, $cdef, $cdc0, $cd92, $cd64, $cd36, $cd08, $ccda, $ccab, $cc7d, $cc4f
 dc.w $cc21, $cbf4, $cbc6, $cb98, $cb6a, $cb3c, $cb0e, $cae1, $cab3, $ca85, $ca58, $ca2a, $c9fc, $c9cf, $c9a1, $c974
 dc.w $c946, $c919, $c8eb, $c8be, $c891, $c864, $c836, $c809, $c7dc, $c7af, $c782, $c755, $c727, $c6fa, $c6cd, $c6a0
 dc.w $c674, $c647, $c61a, $c5ed, $c5c0, $c594, $c567, $c53a, $c50e, $c4e1, $c4b4, $c488, $c45b, $c42f, $c402, $c3d6
 dc.w $c3aa, $c37d, $c351, $c325, $c2f9, $c2cd, $c2a0, $c274, $c248, $c21c, $c1f0, $c1c4, $c198, $c16d, $c141, $c115
 dc.w $c0e9, $c0bd, $c092, $c066, $c03b, $c00f, $bfe3, $bfb8, $bf8d, $bf61, $bf36, $bf0a, $bedf, $beb4, $be89, $be5e
 dc.w $be32, $be07, $bddc, $bdb1, $bd86, $bd5b, $bd30, $bd06, $bcdb, $bcb0, $bc85, $bc5b, $bc30, $bc05, $bbdb, $bbb0
 dc.w $bb86, $bb5b, $bb31, $bb07, $badc, $bab2, $ba88, $ba5d, $ba33, $ba09, $b9df, $b9b5, $b98b, $b961, $b937, $b90d
 dc.w $b8e4, $b8ba, $b890, $b866, $b83d, $b813, $b7ea, $b7c0, $b797, $b76d, $b744, $b71b, $b6f1, $b6c8, $b69f, $b676
 dc.w $b64c, $b623, $b5fa, $b5d1, $b5a8, $b580, $b557, $b52e, $b505, $b4dc, $b4b4, $b48b, $b463, $b43a, $b412, $b3e9
 dc.w $b3c1, $b398, $b370, $b348, $b320, $b2f7, $b2cf, $b2a7, $b27f, $b257, $b22f, $b207, $b1e0, $b1b8, $b190, $b168
 dc.w $b141, $b119, $b0f2, $b0ca, $b0a3, $b07b, $b054, $b02c, $b005, $afde, $afb7, $af90, $af69, $af42, $af1b, $aef4
 dc.w $aecd, $aea6, $ae7f, $ae58, $ae32, $ae0b, $ade5, $adbe, $ad98, $ad71, $ad4b, $ad24, $acfe, $acd8, $acb2, $ac8c
 dc.w $ac65, $ac3f, $ac19, $abf4, $abce, $aba8, $ab82, $ab5c, $ab37, $ab11, $aaeb, $aac6, $aaa0, $aa7b, $aa56, $aa30
 dc.w $aa0b, $a9e6, $a9c1, $a99c, $a976, $a951, $a92d, $a908, $a8e3, $a8be, $a899, $a875, $a850, $a82b, $a807, $a7e2
 dc.w $a7be, $a799, $a775, $a751, $a72d, $a708, $a6e4, $a6c0, $a69c, $a678, $a654, $a631, $a60d, $a5e9, $a5c5, $a5a2
 dc.w $a57e, $a55b, $a537, $a514, $a4f1, $a4cd, $a4aa, $a487, $a464, $a441, $a41e, $a3fb, $a3d8, $a3b5, $a392, $a36f
 dc.w $a34d, $a32a, $a307, $a2e5, $a2c2, $a2a0, $a27e, $a25b, $a239, $a217, $a1f5, $a1d3, $a1b1, $a18f, $a16d, $a14b
 dc.w $a129, $a108, $a0e6, $a0c4, $a0a3, $a081, $a060, $a03e, $a01d, $9ffc, $9fdb, $9fb9, $9f98, $9f77, $9f56, $9f35
 dc.w $9f15, $9ef4, $9ed3, $9eb2, $9e92, $9e71, $9e51, $9e30, $9e10, $9def, $9dcf, $9daf, $9d8f, $9d6f, $9d4f, $9d2f
 dc.w $9d0f, $9cef, $9ccf, $9caf, $9c90, $9c70, $9c51, $9c31, $9c12, $9bf2, $9bd3, $9bb4, $9b94, $9b75, $9b56, $9b37
 dc.w $9b18, $9af9, $9adb, $9abc, $9a9d, $9a7e, $9a60, $9a41, $9a23, $9a04, $99e6, $99c8, $99aa, $998b, $996d, $994f
 dc.w $9931, $9913, $98f6, $98d8, $98ba, $989c, $987f, $9861, $9844, $9826, $9809, $97ec, $97ce, $97b1, $9794, $9777
 dc.w $975a, $973d, $9720, $9704, $96e7, $96ca, $96ae, $9691, $9675, $9658, $963c, $9620, $9603, $95e7, $95cb, $95af
 dc.w $9593, $9577, $955c, $9540, $9524, $9508, $94ed, $94d1, $94b6, $949b, $947f, $9464, $9449, $942e, $9413, $93f8
 dc.w $93dd, $93c2, $93a7, $938c, $9372, $9357, $933d, $9322, $9308, $92ed, $92d3, $92b9, $929f, $9285, $926b, $9251
 dc.w $9237, $921d, $9203, $91ea, $91d0, $91b6, $919d, $9184, $916a, $9151, $9138, $911f, $9105, $90ec, $90d4, $90bb
 dc.w $90a2, $9089, $9070, $9058, $903f, $9027, $900e, $8ff6, $8fde, $8fc6, $8fad, $8f95, $8f7d, $8f65, $8f4e, $8f36
 dc.w $8f1e, $8f06, $8eef, $8ed7, $8ec0, $8ea8, $8e91, $8e7a, $8e63, $8e4c, $8e35, $8e1e, $8e07, $8df0, $8dd9, $8dc2
 dc.w $8dac, $8d95, $8d7f, $8d68, $8d52, $8d3c, $8d25, $8d0f, $8cf9, $8ce3, $8ccd, $8cb7, $8ca2, $8c8c, $8c76, $8c61
 dc.w $8c4b, $8c36, $8c20, $8c0b, $8bf6, $8be0, $8bcb, $8bb6, $8ba1, $8b8c, $8b78, $8b63, $8b4e, $8b3a, $8b25, $8b10
 dc.w $8afc, $8ae8, $8ad3, $8abf, $8aab, $8a97, $8a83, $8a6f, $8a5b, $8a48, $8a34, $8a20, $8a0d, $89f9, $89e6, $89d3
 dc.w $89bf, $89ac, $8999, $8986, $8973, $8960, $894d, $893a, $8928, $8915, $8902, $88f0, $88de, $88cb, $88b9, $88a7
 dc.w $8895, $8883, $8871, $885f, $884d, $883b, $8829, $8818, $8806, $87f5, $87e3, $87d2, $87c1, $87b0, $879e, $878d
 dc.w $877c, $876c, $875b, $874a, $8739, $8729, $8718, $8708, $86f7, $86e7, $86d7, $86c7, $86b6, $86a6, $8696, $8687
 dc.w $8677, $8667, $8657, $8648, $8638, $8629, $861a, $860a, $85fb, $85ec, $85dd, $85ce, $85bf, $85b0, $85a1, $8593
 dc.w $8584, $8575, $8567, $8558, $854a, $853c, $852e, $8520, $8512, $8504, $84f6, $84e8, $84da, $84cd, $84bf, $84b1
 dc.w $84a4, $8497, $8489, $847c, $846f, $8462, $8455, $8448, $843b, $842e, $8422, $8415, $8408, $83fc, $83f0, $83e3
 dc.w $83d7, $83cb, $83bf, $83b3, $83a7, $839b, $838f, $8383, $8378, $836c, $8361, $8355, $834a, $833f, $8333, $8328
 dc.w $831d, $8312, $8307, $82fc, $82f2, $82e7, $82dc, $82d2, $82c7, $82bd, $82b3, $82a9, $829e, $8294, $828a, $8280
 dc.w $8277, $826d, $8263, $825a, $8250, $8247, $823d, $8234, $822b, $8221, $8218, $820f, $8206, $81fe, $81f5, $81ec
 dc.w $81e3, $81db, $81d2, $81ca, $81c2, $81b9, $81b1, $81a9, $81a1, $8199, $8191, $8189, $8182, $817a, $8173, $816b
 dc.w $8164, $815c, $8155, $814e, $8147, $8140, $8139, $8132, $812b, $8124, $811e, $8117, $8111, $810a, $8104, $80fe
 dc.w $80f7, $80f1, $80eb, $80e5, $80df, $80da, $80d4, $80ce, $80c9, $80c3, $80be, $80b8, $80b3, $80ae, $80a9, $80a4
 dc.w $809f, $809a, $8095, $8090, $808c, $8087, $8083, $807e, $807a, $8076, $8071, $806d, $8069, $8065, $8061, $805e
 dc.w $805a, $8056, $8053, $804f, $804c, $8048, $8045, $8042, $803f, $803c, $8039, $8036, $8033, $8030, $802e, $802b
 dc.w $8028, $8026, $8024, $8021, $801f, $801d, $801b, $8019, $8017, $8015, $8014, $8012, $8010, $800f, $800d, $800c
 dc.w $800b, $800a, $8009, $8008, $8007, $8006, $8005, $8004, $8003, $8003, $8002, $8002, $8002, $8001, $8001, $8001
 dc.w $8001, $8001, $8001, $8001, $8002, $8002, $8002, $8003, $8003, $8004, $8005, $8006, $8007, $8008, $8009, $800a
 dc.w $800b, $800c, $800d, $800f, $8010, $8012, $8014, $8015, $8017, $8019, $801b, $801d, $801f, $8021, $8024, $8026
 dc.w $8028, $802b, $802e, $8030, $8033, $8036, $8039, $803c, $803f, $8042, $8045, $8048, $804c, $804f, $8053, $8056
 dc.w $805a, $805e, $8061, $8065, $8069, $806d, $8071, $8076, $807a, $807e, $8083, $8087, $808c, $8090, $8095, $809a
 dc.w $809f, $80a4, $80a9, $80ae, $80b3, $80b8, $80be, $80c3, $80c9, $80ce, $80d4, $80da, $80df, $80e5, $80eb, $80f1
 dc.w $80f7, $80fe, $8104, $810a, $8111, $8117, $811e, $8124, $812b, $8132, $8139, $8140, $8147, $814e, $8155, $815c
 dc.w $8164, $816b, $8173, $817a, $8182, $8189, $8191, $8199, $81a1, $81a9, $81b1, $81b9, $81c2, $81ca, $81d2, $81db
 dc.w $81e3, $81ec, $81f5, $81fe, $8206, $820f, $8218, $8221, $822b, $8234, $823d, $8247, $8250, $825a, $8263, $826d
 dc.w $8277, $8280, $828a, $8294, $829e, $82a9, $82b3, $82bd, $82c7, $82d2, $82dc, $82e7, $82f2, $82fc, $8307, $8312
 dc.w $831d, $8328, $8333, $833f, $834a, $8355, $8361, $836c, $8378, $8383, $838f, $839b, $83a7, $83b3, $83bf, $83cb
 dc.w $83d7, $83e3, $83f0, $83fc, $8408, $8415, $8422, $842e, $843b, $8448, $8455, $8462, $846f, $847c, $8489, $8497
 dc.w $84a4, $84b1, $84bf, $84cd, $84da, $84e8, $84f6, $8504, $8512, $8520, $852e, $853c, $854a, $8558, $8567, $8575
 dc.w $8584, $8593, $85a1, $85b0, $85bf, $85ce, $85dd, $85ec, $85fb, $860a, $861a, $8629, $8638, $8648, $8657, $8667
 dc.w $8677, $8687, $8696, $86a6, $86b6, $86c7, $86d7, $86e7, $86f7, $8708, $8718, $8729, $8739, $874a, $875b, $876c
 dc.w $877c, $878d, $879e, $87b0, $87c1, $87d2, $87e3, $87f5, $8806, $8818, $8829, $883b, $884d, $885f, $8871, $8883
 dc.w $8895, $88a7, $88b9, $88cb, $88de, $88f0, $8902, $8915, $8928, $893a, $894d, $8960, $8973, $8986, $8999, $89ac
 dc.w $89bf, $89d3, $89e6, $89f9, $8a0d, $8a20, $8a34, $8a48, $8a5b, $8a6f, $8a83, $8a97, $8aab, $8abf, $8ad3, $8ae8
 dc.w $8afc, $8b10, $8b25, $8b3a, $8b4e, $8b63, $8b78, $8b8c, $8ba1, $8bb6, $8bcb, $8be0, $8bf6, $8c0b, $8c20, $8c36
 dc.w $8c4b, $8c61, $8c76, $8c8c, $8ca2, $8cb7, $8ccd, $8ce3, $8cf9, $8d0f, $8d25, $8d3c, $8d52, $8d68, $8d7f, $8d95
 dc.w $8dac, $8dc2, $8dd9, $8df0, $8e07, $8e1e, $8e35, $8e4c, $8e63, $8e7a, $8e91, $8ea8, $8ec0, $8ed7, $8eef, $8f06
 dc.w $8f1e, $8f36, $8f4e, $8f65, $8f7d, $8f95, $8fad, $8fc6, $8fde, $8ff6, $900e, $9027, $903f, $9058, $9070, $9089
 dc.w $90a2, $90bb, $90d4, $90ec, $9105, $911f, $9138, $9151, $916a, $9184, $919d, $91b6, $91d0, $91ea, $9203, $921d
 dc.w $9237, $9251, $926b, $9285, $929f, $92b9, $92d3, $92ed, $9308, $9322, $933d, $9357, $9372, $938c, $93a7, $93c2
 dc.w $93dd, $93f8, $9413, $942e, $9449, $9464, $947f, $949b, $94b6, $94d1, $94ed, $9508, $9524, $9540, $955c, $9577
 dc.w $9593, $95af, $95cb, $95e7, $9603, $9620, $963c, $9658, $9675, $9691, $96ae, $96ca, $96e7, $9704, $9720, $973d
 dc.w $975a, $9777, $9794, $97b1, $97ce, $97ec, $9809, $9826, $9844, $9861, $987f, $989c, $98ba, $98d8, $98f6, $9913
 dc.w $9931, $994f, $996d, $998b, $99aa, $99c8, $99e6, $9a04, $9a23, $9a41, $9a60, $9a7e, $9a9d, $9abc, $9adb, $9af9
 dc.w $9b18, $9b37, $9b56, $9b75, $9b94, $9bb4, $9bd3, $9bf2, $9c12, $9c31, $9c51, $9c70, $9c90, $9caf, $9ccf, $9cef
 dc.w $9d0f, $9d2f, $9d4f, $9d6f, $9d8f, $9daf, $9dcf, $9def, $9e10, $9e30, $9e51, $9e71, $9e92, $9eb2, $9ed3, $9ef4
 dc.w $9f15, $9f35, $9f56, $9f77, $9f98, $9fb9, $9fdb, $9ffc, $a01d, $a03e, $a060, $a081, $a0a3, $a0c4, $a0e6, $a108
 dc.w $a129, $a14b, $a16d, $a18f, $a1b1, $a1d3, $a1f5, $a217, $a239, $a25b, $a27e, $a2a0, $a2c2, $a2e5, $a307, $a32a
 dc.w $a34d, $a36f, $a392, $a3b5, $a3d8, $a3fb, $a41e, $a441, $a464, $a487, $a4aa, $a4cd, $a4f1, $a514, $a537, $a55b
 dc.w $a57e, $a5a2, $a5c5, $a5e9, $a60d, $a631, $a654, $a678, $a69c, $a6c0, $a6e4, $a708, $a72d, $a751, $a775, $a799
 dc.w $a7be, $a7e2, $a807, $a82b, $a850, $a875, $a899, $a8be, $a8e3, $a908, $a92d, $a951, $a976, $a99c, $a9c1, $a9e6
 dc.w $aa0b, $aa30, $aa56, $aa7b, $aaa0, $aac6, $aaeb, $ab11, $ab37, $ab5c, $ab82, $aba8, $abce, $abf4, $ac19, $ac3f
 dc.w $ac65, $ac8c, $acb2, $acd8, $acfe, $ad24, $ad4b, $ad71, $ad98, $adbe, $ade5, $ae0b, $ae32, $ae58, $ae7f, $aea6
 dc.w $aecd, $aef4, $af1b, $af42, $af69, $af90, $afb7, $afde, $b005, $b02c, $b054, $b07b, $b0a3, $b0ca, $b0f2, $b119
 dc.w $b141, $b168, $b190, $b1b8, $b1e0, $b207, $b22f, $b257, $b27f, $b2a7, $b2cf, $b2f7, $b320, $b348, $b370, $b398
 dc.w $b3c1, $b3e9, $b412, $b43a, $b463, $b48b, $b4b4, $b4dc, $b505, $b52e, $b557, $b580, $b5a8, $b5d1, $b5fa, $b623
 dc.w $b64c, $b676, $b69f, $b6c8, $b6f1, $b71b, $b744, $b76d, $b797, $b7c0, $b7ea, $b813, $b83d, $b866, $b890, $b8ba
 dc.w $b8e4, $b90d, $b937, $b961, $b98b, $b9b5, $b9df, $ba09, $ba33, $ba5d, $ba88, $bab2, $badc, $bb07, $bb31, $bb5b
 dc.w $bb86, $bbb0, $bbdb, $bc05, $bc30, $bc5b, $bc85, $bcb0, $bcdb, $bd06, $bd30, $bd5b, $bd86, $bdb1, $bddc, $be07
 dc.w $be32, $be5e, $be89, $beb4, $bedf, $bf0a, $bf36, $bf61, $bf8d, $bfb8, $bfe3, $c00f, $c03b, $c066, $c092, $c0bd
 dc.w $c0e9, $c115, $c141, $c16d, $c198, $c1c4, $c1f0, $c21c, $c248, $c274, $c2a0, $c2cd, $c2f9, $c325, $c351, $c37d
 dc.w $c3aa, $c3d6, $c402, $c42f, $c45b, $c488, $c4b4, $c4e1, $c50e, $c53a, $c567, $c594, $c5c0, $c5ed, $c61a, $c647
 dc.w $c674, $c6a0, $c6cd, $c6fa, $c727, $c755, $c782, $c7af, $c7dc, $c809, $c836, $c864, $c891, $c8be, $c8eb, $c919
 dc.w $c946, $c974, $c9a1, $c9cf, $c9fc, $ca2a, $ca58, $ca85, $cab3, $cae1, $cb0e, $cb3c, $cb6a, $cb98, $cbc6, $cbf4
 dc.w $cc21, $cc4f, $cc7d, $ccab, $ccda, $cd08, $cd36, $cd64, $cd92, $cdc0, $cdef, $ce1d, $ce4b, $ce79, $cea8, $ced6
 dc.w $cf05, $cf33, $cf62, $cf90, $cfbf, $cfed, $d01c, $d04a, $d079, $d0a8, $d0d6, $d105, $d134, $d163, $d192, $d1c0
 dc.w $d1ef, $d21e, $d24d, $d27c, $d2ab, $d2da, $d309, $d338, $d367, $d396, $d3c6, $d3f5, $d424, $d453, $d483, $d4b2
 dc.w $d4e1, $d510, $d540, $d56f, $d59f, $d5ce, $d5fe, $d62d, $d65d, $d68c, $d6bc, $d6eb, $d71b, $d74b, $d77a, $d7aa
 dc.w $d7da, $d809, $d839, $d869, $d899, $d8c9, $d8f8, $d928, $d958, $d988, $d9b8, $d9e8, $da18, $da48, $da78, $daa8
 dc.w $dad8, $db08, $db38, $db69, $db99, $dbc9, $dbf9, $dc29, $dc5a, $dc8a, $dcba, $dceb, $dd1b, $dd4b, $dd7c, $ddac
 dc.w $dddd, $de0d, $de3e, $de6e, $de9f, $decf, $df00, $df30, $df61, $df91, $dfc2, $dff3, $e023, $e054, $e085, $e0b6
 dc.w $e0e6, $e117, $e148, $e179, $e1a9, $e1da, $e20b, $e23c, $e26d, $e29e, $e2cf, $e300, $e331, $e362, $e393, $e3c4
 dc.w $e3f5, $e426, $e457, $e488, $e4b9, $e4ea, $e51b, $e54c, $e57e, $e5af, $e5e0, $e611, $e642, $e674, $e6a5, $e6d6
 dc.w $e707, $e739, $e76a, $e79b, $e7cd, $e7fe, $e830, $e861, $e892, $e8c4, $e8f5, $e927, $e958, $e98a, $e9bb, $e9ed
 dc.w $ea1e, $ea50, $ea81, $eab3, $eae4, $eb16, $eb47, $eb79, $ebab, $ebdc, $ec0e, $ec40, $ec71, $eca3, $ecd5, $ed06
 dc.w $ed38, $ed6a, $ed9c, $edcd, $edff, $ee31, $ee63, $ee94, $eec6, $eef8, $ef2a, $ef5c, $ef8e, $efbf, $eff1, $f023
 dc.w $f055, $f087, $f0b9, $f0eb, $f11d, $f14f, $f180, $f1b2, $f1e4, $f216, $f248, $f27a, $f2ac, $f2de, $f310, $f342
 dc.w $f374, $f3a6, $f3d8, $f40a, $f43c, $f46e, $f4a1, $f4d3, $f505, $f537, $f569, $f59b, $f5cd, $f5ff, $f631, $f663
 dc.w $f696, $f6c8, $f6fa, $f72c, $f75e, $f790, $f7c2, $f7f5, $f827, $f859, $f88b, $f8bd, $f8ef, $f922, $f954, $f986
 dc.w $f9b8, $f9ea, $fa1d, $fa4f, $fa81, $fab3, $fae5, $fb18, $fb4a, $fb7c, $fbae, $fbe1, $fc13, $fc45, $fc77, $fcaa
 dc.w $fcdc, $fd0e, $fd40, $fd73, $fda5, $fdd7, $fe09, $fe3c, $fe6e, $fea0, $fed2, $ff05, $ff37, $ff69, $ff9b, $ffce
 dc.w $0000, $0032, $0065, $0097, $00c9, $00fb, $012e, $0160, $0192, $01c4, $01f7, $0229, $025b, $028d, $02c0, $02f2
 dc.w $0324, $0356, $0389, $03bb, $03ed, $041f, $0452, $0484, $04b6, $04e8, $051b, $054d, $057f, $05b1, $05e3, $0616
 dc.w $0648, $067a, $06ac, $06de, $0711, $0743, $0775, $07a7, $07d9, $080b, $083e, $0870, $08a2, $08d4, $0906, $0938
 dc.w $096a, $099d, $09cf, $0a01, $0a33, $0a65, $0a97, $0ac9, $0afb, $0b2d, $0b5f, $0b92, $0bc4, $0bf6, $0c28, $0c5a
 dc.w $0c8c, $0cbe, $0cf0, $0d22, $0d54, $0d86, $0db8, $0dea, $0e1c, $0e4e, $0e80, $0eb1, $0ee3, $0f15, $0f47, $0f79
 dc.w $0fab, $0fdd, $100f, $1041, $1072, $10a4, $10d6, $1108, $113a, $116c, $119d, $11cf, $1201, $1233, $1264, $1296
 dc.w $12c8, $12fa, $132b, $135d, $138f, $13c0, $13f2, $1424, $1455, $1487, $14b9, $14ea, $151c, $154d, $157f, $15b0
 dc.w $15e2, $1613, $1645, $1676, $16a8, $16d9, $170b, $173c, $176e, $179f, $17d0, $1802, $1833, $1865, $1896, $18c7
 dc.w $18f9, $192a, $195b, $198c, $19be, $19ef, $1a20, $1a51, $1a82, $1ab4, $1ae5, $1b16, $1b47, $1b78, $1ba9, $1bda
 dc.w $1c0b, $1c3c, $1c6d, $1c9e, $1ccf, $1d00, $1d31, $1d62, $1d93, $1dc4, $1df5, $1e26, $1e57, $1e87, $1eb8, $1ee9
 dc.w $1f1a, $1f4a, $1f7b, $1fac, $1fdd, $200d, $203e, $206f, $209f, $20d0, $2100, $2131, $2161, $2192, $21c2, $21f3
 dc.w $2223, $2254, $2284, $22b5, $22e5, $2315, $2346, $2376, $23a6, $23d7, $2407, $2437, $2467, $2497, $24c8, $24f8
 dc.w $2528, $2558, $2588, $25b8, $25e8, $2618, $2648, $2678, $26a8, $26d8, $2708, $2737, $2767, $2797, $27c7, $27f7
 dc.w $2826, $2856, $2886, $28b5, $28e5, $2915, $2944, $2974, $29a3, $29d3, $2a02, $2a32, $2a61, $2a91, $2ac0, $2af0
 dc.w $2b1f, $2b4e, $2b7d, $2bad, $2bdc, $2c0b, $2c3a, $2c6a, $2c99, $2cc8, $2cf7, $2d26, $2d55, $2d84, $2db3, $2de2
 dc.w $2e11, $2e40, $2e6e, $2e9d, $2ecc, $2efb, $2f2a, $2f58, $2f87, $2fb6, $2fe4, $3013, $3041, $3070, $309e, $30cd
 dc.w $30fb, $312a, $3158, $3187, $31b5, $31e3, $3211, $3240, $326e, $329c, $32ca, $32f8, $3326, $3355, $3383, $33b1
 dc.w $33df, $340c, $343a, $3468, $3496, $34c4, $34f2, $351f, $354d, $357b, $35a8, $35d6, $3604, $3631, $365f, $368c
 dc.w $36ba, $36e7, $3715, $3742, $376f, $379c, $37ca, $37f7, $3824, $3851, $387e, $38ab, $38d9, $3906, $3933, $3960
 dc.w $398c, $39b9, $39e6, $3a13, $3a40, $3a6c, $3a99, $3ac6, $3af2, $3b1f, $3b4c, $3b78, $3ba5, $3bd1, $3bfe, $3c2a
 dc.w $3c56, $3c83, $3caf, $3cdb, $3d07, $3d33, $3d60, $3d8c, $3db8, $3de4, $3e10, $3e3c, $3e68, $3e93, $3ebf, $3eeb
 dc.w $3f17, $3f43, $3f6e, $3f9a, $3fc5, $3ff1, $401d, $4048, $4073, $409f, $40ca, $40f6, $4121, $414c, $4177, $41a2
 dc.w $41ce, $41f9, $4224, $424f, $427a, $42a5, $42d0, $42fa, $4325, $4350, $437b, $43a5, $43d0, $43fb, $4425, $4450
 dc.w $447a, $44a5, $44cf, $44f9, $4524, $454e, $4578, $45a3, $45cd, $45f7, $4621, $464b, $4675, $469f, $46c9, $46f3
 dc.w $471c, $4746, $4770, $479a, $47c3, $47ed, $4816, $4840, $4869, $4893, $48bc, $48e5, $490f, $4938, $4961, $498a
 dc.w $49b4, $49dd, $4a06, $4a2f, $4a58, $4a80, $4aa9, $4ad2, $4afb, $4b24, $4b4c, $4b75, $4b9d, $4bc6, $4bee, $4c17
 dc.w $4c3f, $4c68, $4c90, $4cb8, $4ce0, $4d09, $4d31, $4d59, $4d81, $4da9, $4dd1, $4df9, $4e20, $4e48, $4e70, $4e98
 dc.w $4ebf, $4ee7, $4f0e, $4f36, $4f5d, $4f85, $4fac, $4fd4, $4ffb, $5022, $5049, $5070, $5097, $50be, $50e5, $510c
 dc.w $5133, $515a, $5181, $51a8, $51ce, $51f5, $521b, $5242, $5268, $528f, $52b5, $52dc, $5302, $5328, $534e, $5374
 dc.w $539b, $53c1, $53e7, $540c, $5432, $5458, $547e, $54a4, $54c9, $54ef, $5515, $553a, $5560, $5585, $55aa, $55d0
 dc.w $55f5, $561a, $563f, $5664, $568a, $56af, $56d3, $56f8, $571d, $5742, $5767, $578b, $57b0, $57d5, $57f9, $581e
 dc.w $5842, $5867, $588b, $58af, $58d3, $58f8, $591c, $5940, $5964, $5988, $59ac, $59cf, $59f3, $5a17, $5a3b, $5a5e
 dc.w $5a82, $5aa5, $5ac9, $5aec, $5b0f, $5b33, $5b56, $5b79, $5b9c, $5bbf, $5be2, $5c05, $5c28, $5c4b, $5c6e, $5c91
 dc.w $5cb3, $5cd6, $5cf9, $5d1b, $5d3e, $5d60, $5d82, $5da5, $5dc7, $5de9, $5e0b, $5e2d, $5e4f, $5e71, $5e93, $5eb5
 dc.w $5ed7, $5ef8, $5f1a, $5f3c, $5f5d, $5f7f, $5fa0, $5fc2, $5fe3, $6004, $6025, $6047, $6068, $6089, $60aa, $60cb
 dc.w $60eb, $610c, $612d, $614e, $616e, $618f, $61af, $61d0, $61f0, $6211, $6231, $6251, $6271, $6291, $62b1, $62d1
 dc.w $62f1, $6311, $6331, $6351, $6370, $6390, $63af, $63cf, $63ee, $640e, $642d, $644c, $646c, $648b, $64aa, $64c9
 dc.w $64e8, $6507, $6525, $6544, $6563, $6582, $65a0, $65bf, $65dd, $65fc, $661a, $6638, $6656, $6675, $6693, $66b1
 dc.w $66cf, $66ed, $670a, $6728, $6746, $6764, $6781, $679f, $67bc, $67da, $67f7, $6814, $6832, $684f, $686c, $6889
 dc.w $68a6, $68c3, $68e0, $68fc, $6919, $6936, $6952, $696f, $698b, $69a8, $69c4, $69e0, $69fd, $6a19, $6a35, $6a51
 dc.w $6a6d, $6a89, $6aa4, $6ac0, $6adc, $6af8, $6b13, $6b2f, $6b4a, $6b65, $6b81, $6b9c, $6bb7, $6bd2, $6bed, $6c08
 dc.w $6c23, $6c3e, $6c59, $6c74, $6c8e, $6ca9, $6cc3, $6cde, $6cf8, $6d13, $6d2d, $6d47, $6d61, $6d7b, $6d95, $6daf
 dc.w $6dc9, $6de3, $6dfd, $6e16, $6e30, $6e4a, $6e63, $6e7c, $6e96, $6eaf, $6ec8, $6ee1, $6efb, $6f14, $6f2c, $6f45
 dc.w $6f5e, $6f77, $6f90, $6fa8, $6fc1, $6fd9, $6ff2, $700a, $7022, $703a, $7053, $706b, $7083, $709b, $70b2, $70ca
 dc.w $70e2, $70fa, $7111, $7129, $7140, $7158, $716f, $7186, $719d, $71b4, $71cb, $71e2, $71f9, $7210, $7227, $723e
 dc.w $7254, $726b, $7281, $7298, $72ae, $72c4, $72db, $72f1, $7307, $731d, $7333, $7349, $735e, $7374, $738a, $739f
 dc.w $73b5, $73ca, $73e0, $73f5, $740a, $7420, $7435, $744a, $745f, $7474, $7488, $749d, $74b2, $74c6, $74db, $74f0
 dc.w $7504, $7518, $752d, $7541, $7555, $7569, $757d, $7591, $75a5, $75b8, $75cc, $75e0, $75f3, $7607, $761a, $762d
 dc.w $7641, $7654, $7667, $767a, $768d, $76a0, $76b3, $76c6, $76d8, $76eb, $76fe, $7710, $7722, $7735, $7747, $7759
 dc.w $776b, $777d, $778f, $77a1, $77b3, $77c5, $77d7, $77e8, $77fa, $780b, $781d, $782e, $783f, $7850, $7862, $7873
 dc.w $7884, $7894, $78a5, $78b6, $78c7, $78d7, $78e8, $78f8, $7909, $7919, $7929, $7939, $794a, $795a, $796a, $7979
 dc.w $7989, $7999, $79a9, $79b8, $79c8, $79d7, $79e6, $79f6, $7a05, $7a14, $7a23, $7a32, $7a41, $7a50, $7a5f, $7a6d
 dc.w $7a7c, $7a8b, $7a99, $7aa8, $7ab6, $7ac4, $7ad2, $7ae0, $7aee, $7afc, $7b0a, $7b18, $7b26, $7b33, $7b41, $7b4f
 dc.w $7b5c, $7b69, $7b77, $7b84, $7b91, $7b9e, $7bab, $7bb8, $7bc5, $7bd2, $7bde, $7beb, $7bf8, $7c04, $7c10, $7c1d
 dc.w $7c29, $7c35, $7c41, $7c4d, $7c59, $7c65, $7c71, $7c7d, $7c88, $7c94, $7c9f, $7cab, $7cb6, $7cc1, $7ccd, $7cd8
 dc.w $7ce3, $7cee, $7cf9, $7d04, $7d0e, $7d19, $7d24, $7d2e, $7d39, $7d43, $7d4d, $7d57, $7d62, $7d6c, $7d76, $7d80
 dc.w $7d89, $7d93, $7d9d, $7da6, $7db0, $7db9, $7dc3, $7dcc, $7dd5, $7ddf, $7de8, $7df1, $7dfa, $7e02, $7e0b, $7e14
 dc.w $7e1d, $7e25, $7e2e, $7e36, $7e3e, $7e47, $7e4f, $7e57, $7e5f, $7e67, $7e6f, $7e77, $7e7e, $7e86, $7e8d, $7e95
 dc.w $7e9c, $7ea4, $7eab, $7eb2, $7eb9, $7ec0, $7ec7, $7ece, $7ed5, $7edc, $7ee2, $7ee9, $7eef, $7ef6, $7efc, $7f02
 dc.w $7f09, $7f0f, $7f15, $7f1b, $7f21, $7f26, $7f2c, $7f32, $7f37, $7f3d, $7f42, $7f48, $7f4d, $7f52, $7f57, $7f5c
 dc.w $7f61, $7f66, $7f6b, $7f70, $7f74, $7f79, $7f7d, $7f82, $7f86, $7f8a, $7f8f, $7f93, $7f97, $7f9b, $7f9f, $7fa2
 dc.w $7fa6, $7faa, $7fad, $7fb1, $7fb4, $7fb8, $7fbb, $7fbe, $7fc1, $7fc4, $7fc7, $7fca, $7fcd, $7fd0, $7fd2, $7fd5
 dc.w $7fd8, $7fda, $7fdc, $7fdf, $7fe1, $7fe3, $7fe5, $7fe7, $7fe9, $7feb, $7fec, $7fee, $7ff0, $7ff1, $7ff3, $7ff4
 dc.w $7ff5, $7ff6, $7ff7, $7ff8, $7ff9, $7ffa, $7ffb, $7ffc, $7ffd, $7ffd, $7ffe, $7ffe, $7ffe, $7fff, $7fff, $7fff
;@generated-datagen-end----------------

Cube:
	dc.l	Cube_Poligons			;$00
	dc.w	0,0,0				;$04 Alfa,Beta,Gama
	dc.w	0,0,$400			;$0a TX,TY,TZ
	dc.l	Cube_Dots			;$10
	dc.l	Cube_Rotated_Dots		;$14
	dc.l	Cube_Normal_Vektors		;$18
Cube_Poligons:
	dc.w	1,0,0*4,1*4,2*4,3*4,0*4,$aaaa
	dc.w	2,0,0*4,4*4,5*4,1*4,0*4,$aaaa
	dc.w	3,0,1*4,5*4,6*4,2*4,1*4,$aaaa
	dc.w	1,0,5*4,4*4,7*4,6*4,5*4,$aaaa
	dc.w	2,0,3*4,2*4,6*4,7*4,3*4,$aaaa
	dc.w	3,0,7*4,4*4,0*4,3*4,7*4,$ffff
Cube_Normal_Vektors:
	dc.w	0,0,16*2
	dc.w	0,16*2,0
	dc.w	-16*2,0,0
	dc.w	0,0,-16*2
	dc.w	0,-16*2,0
	dc.w	16*2,0,0
	dc.w	$ffff
Cube_Dots:
	dc.w	-200*2,-200*2,-200*2		;00
	dc.w	200*2,-200*2,-200*2		;01
	dc.w	200*2,200*2,-200*2		;02
	dc.w	-200*2,200*2,-200*2		;03
	dc.w	-200*2,-200*2,200*2		;04
	dc.w	200*2,-200*2,200*2		;05
	dc.w	200*2,200*2,200*2		;06
	dc.w	-200*2,200*2,200*2		;07
	dc.w	$ffff
Cube_Rotated_Dots:
	dc.w	0,0,0				;00
	dc.w	0,0,0				;01
	dc.w	0,0,0				;02
	dc.w	0,0,0				;03
	dc.w	0,0,0				;04
	dc.w	0,0,0				;05
	dc.w	0,0,0				;06
	dc.w	0,0,0				;07
	dc.w	$ffff


Curent_Object:
	dc.l	0

ColorsTable:
	dc.w	$0000,$0001,$0002,$0003,$0004,$0005,$0006,$0007
	dc.w	$0008,$0009,$000a,$000b,$000c,$000d,$000e,$000f
		
Colors:	dc.w	$0000,$0000,$0000,$0000


L_YTable:	blk.w	257,0
L_SizeTable:	blk.w	321,0

DOT_Line_Area:	blk.b	2048,0
DOT_Clipped:	blk.b	1024,0

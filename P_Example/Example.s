; Use prefix for all lables e.g "EP_" for Example part

;*****************************************************************
;Init for demo part, Do all init for part here e.g. create tables
;prepare copper list etc...
;Input:
;	a6 - Custom Chip Address $dff000 
;Output:
;	a0 - CopperList to set initially
;	a1 - VBlank routine
;	a2 - Main routine
EP_Init:
	movem.l d0-d7/a3-a6,-(sp)
	lea EP_Move(pc),a0
	move.w	#$0,(a0)+	;position
	move.w	#$1,(a0)+	;direction

	bsr	EP_VBlank	;wite copper once

	;return values for part
	lea	EP_Copper,a0
	lea	EP_VBlank(pc),a1
	lea	EP_Main(pc),a2
	movem.l (sp)+,d0-d7/a3-a6
	rts

;*****************************************************************
;Demo part, main routine usually for part timing
;Input:
;	a0 - frame counter pointer
;	a6 - Custom Chip Address $dff000
EP_Main:
	movem.l d0-d7/a1-a6,-(sp)

	move.l	(a0),d0
	add.l	#10*50,d0	; wait 10 sec

EP_Wait:
	btst	#$6,$bfe001	; exit part on mouse
	beq.s	EP_Exit
	cmp.l	(a0),d0		; or wait until finished
	bge.s	EP_Wait

EP_Exit:
	movem.l (sp)+,d0-d7/a1-a6
	rts

EP_Move:
	dc.w	0	;position
	dc.w	0	;direction

;*****************************************************************
;Demo part, Vertical blank routine, either copper or vblank
;Input:
;	a0 - frame counter pointer
;	a6 - Custom Chip Address $dff000 
EP_VBlank:
	movem.l d0-a6,-(sp)

	lea	EP_Move(pc),a0
	movem.w	(a0)+,d0-d1
	add.w	d1,d0
	bgt.s	EP_VB_NotStart
	moveq	#1,d1
	bra.s	EP_VB_WriteCopper
EP_VB_NotStart:
	cmp.w	#$116,d0
	ble.s	EP_VB_WriteCopper
	moveq	#-1,d1
EP_VB_WriteCopper:
	movem.w	d0-d1,-(a0)


	lea	EP_CWait,a1
	move.w	d0,d1
	;first wait 
	btst	#8,d1
	beq.s	EP_VB_NotOver255
	moveq	#-1,d1
EP_VB_NotOver255:
	move.b	d1,(a1)
	addq	#4,a1
	move.b	d1,(a1)
	addq	#4,a1
	addq	#1,d0

	;other lines
	moveq	#31,d1
EP_VB_NextLine:
	move.b	d0,(a1)
	addq	#8,a1
	move.b	d0,(a1)
	addq	#4,a1
	addq	#1,d0
	dbf	d1,EP_VB_NextLine

	movem.l (sp)+,d0-a6
	rts

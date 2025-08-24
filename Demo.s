	Section	"Demo Main code",CODE_P

	INCDIR	"Include/"
	INCLUDE	"LVO3.1/exec_lib.i"
	INCLUDE	"LVO3.1/dos_lib.i"
	INCLUDE	"LVO3.1/graphics_lib.i"
	INCLUDE	"graphics/gfxbase.i"
	INCLUDE	"exec/interrupts.i"
	INCLUDE	"exec/Memory.i"
	INCLUDE	"exec/exec.i"
	INCLUDE	"exec/execbase.i"
	INCLUDE	"dos/dos.i"
	INCLUDE	"hardware/intbits.i"	
	INCLUDE	"hardware/dmabits.i"
	INCLUDE	"hardware/cia.i"
	INCLUDE	"hardware/custom.i"
	INCLUDE	"libraries/dosextens.i"
	INCLUDE	"devices/input.i"
	INCLUDE	"devices/inputevent.i"
	INCLUDE	"resources/misc.i"

	INCDIR	""	;return include folder to root

DEBUGGING	= 1	;use 1 if debugging
COPPERINT	= 1	;use 1 if Copper int otherwise is vertb int
INPUTHANDLER	= 0	;use 1 if using input handler
DOSLIB		= 0	;use 1 if dos library is needed
DMA_ACTIVATE	= (DMAF_SETCLR|DMAF_SPRITE|DMAF_BLITTER|DMAF_COPPER|DMAF_RASTER)
PART_TIMING	= 0	;use 1 for time measure in VBlank

;***********************************
;Macro for running parts
;	\1 - Part definition
;	\2 - Part prefix
PART_RUN:	MACRO
	IF	\1=1
	jsr	\2_Init			;part init
	bsr	Wait_VerticalBlank	;wait end of frame
	move.l	a0,cop1lc(a6)		;set part copper
	move.l	a1,Part_VTBInt		;set part vblank
	lea	VTBInt_Counter(pc),a0	;get frame counter
	jsr	(a2)			;run part main
	ENDIF
	ENDM

;***********************************
; Demo parts for on/off
PART_EXAMPLE		= 0	; include Example demo part
PART_BLANK_VECTOR	= 1	; include Blank Vector demo part
PART_BLANK_VECTOR_CB	= 0	; include Blank Vector copper blitter demo part

Demo:	
	movem.l	d0-a6,-(sp)
	bsr	Startup_Init	;Init Routine
	tst.l	d0		;Check Ok?
	bne.w	Demo_Exit

Demo_Init:
	lea	$dff000,a6	;Custom Chip Address in a6
;***********************************
;TODO: init
;***********************************
	move.w	#DMA_ACTIVATE,dmacon(a6)	;enable DMA
	move.w	#0,VTBInt_Stop			;Start Interrupt
Demo_MainLoop:
;***********************************
;Main demo code
;***********************************

	PART_RUN PART_EXAMPLE, EP
	PART_RUN PART_BLANK_VECTOR, BV
	PART_RUN PART_BLANK_VECTOR_CB, BV

	;IF	INPUTHANDLER=1
	;tst.b	ESCKey
	;beq.s	Demo_MainLoop
	;ELSE
	;btst	#$6,$bfe001
	;bne.s	Demo_MainLoop
	;ENDIF

Demo_Exit:
	bsr	Startup_Restore
	movem.l	(sp)+,d0-a6
	rts

;active part vertical blank interrupt handler
Part_VTBInt: dc.l 	0	

VTBInt_Handler:
	movem.l	d0-a6,-(sp)
	tst.w	VTBInt_Stop
	bne.s	VTBInt_End

	lea	$dff000,a6
	lea	VTBInt_Counter(pc),a0
	add.l	#$01,(a0)

;***********************************
;TODO: interrupt code here
;***********************************

	;run part interrupt handler
	move.l	Part_VTBInt(pc),d0
	beq.s	VTBInt_End
	move.l	d0,a1
	IF PART_TIMING=1
	move.w	#$0f00,$180(a6)
	ENDIF
	jsr	(a1)
	IF PART_TIMING=1
	move.w	#$0000,$180(a6)
	ENDIF

VTBInt_End:
	movem.l	(sp)+,d0-a6
	moveq	#$00,d0
	rts

	INCLUDE	"Startup/CyberlabsStartup.s"

;***************************************************
;Public/Fast code
;***************************************************
	Section	"Demo Parts Code",CODE_P

	IF	PART_EXAMPLE=1
	INCLUDE	"P_Example/Example.s"
	ENDIF

	IF	PART_BLANK_VECTOR=1
	INCLUDE	"P_BlankVector/BlankVector.s"
	;AUTO	CS\R_SinCosTable\0\450\5120\32767\0\W1\yy
	ENDIF

	IF	PART_BLANK_VECTOR_CB=1
	INCLUDE	"P_BlankVectorCB/BlankVectorCB.s"
	;AUTO	CS\R_SinCosTable\0\450\5120\32767\0\W1\yy
	ENDIF
;***************************************************
;Public/Fast data
;***************************************************
	Section	"Demo Public data",DATA_P

	IF	PART_EXAMPLE=1
	INCLUDE	"P_Example/Example_Data_P.s"
	ENDIF

;***************************************************
;Public/Fast bss
;***************************************************
	Section	"Demo Public bss",BSS_P

	IF	PART_EXAMPLE=1
	INCLUDE	"P_Example/Example_Bss_P.s"
	ENDIF

;***************************************************
;Chip data
;***************************************************
	SECTION	"Demo Chip Data",DATA_C

	INCLUDE "Startup/CyberlabsStartupCopper.s"

	IF	PART_EXAMPLE=1
	INCLUDE	"P_Example/Example_Data_C.s"
	ENDIF

	IF	PART_BLANK_VECTOR=1
	INCLUDE	"P_BlankVector/BlankVector_Data_C.s"
	ENDIF

	IF	PART_BLANK_VECTOR_CB=1
	INCLUDE	"P_BlankVectorCB/BlankVectorCB_Data_C.s"
	ENDIF

;***************************************************
;Chip BSS
;***************************************************
	SECTION	"Demo Chip BSS",BSS_C

	IF	PART_EXAMPLE=1
	INCLUDE	"P_Example/Example_Bss_C.s"
	ENDIF

	IF	PART_BLANK_VECTOR=1
	INCLUDE	"P_BlankVector/BlankVector_Bss_C.s"
	ENDIF

	IF	PART_BLANK_VECTOR_CB=1
	INCLUDE	"P_BlankVectorCB/BlankVectorCB_Bss_C.s"
	ENDIF

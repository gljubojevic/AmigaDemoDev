;**************************************************
; Macro set for NO CPU recoding copper fragments
;	INCDIR	"../Include"
;	INCLUDE "dos/dos.i"
;	INCLUDE	"LVO3.1/dos_lib.i"
;	INCDIR	""

	IFND	NO_CPU_RECORDER_S
NO_CPU_RECORDER_S	SET	1

; Default NO CPU Copper recording disabled
	IFND	NO_CPU_RECORDER_ENABLE
NO_CPU_RECORDER_ENABLE	SET	0
	ENDIF

; Default number of symbols in symbol table
	IFND	REC_MAX_SYMBOLS
REC_MAX_SYMBOLS	SET	10
	ENDIF

; Default mem space for recording references
	IFND	REC_REFERENCES_SPACE
REC_REFERENCES_SPACE	SET	1024*16
	ENDIF

	IFND	REC_FRAMES_SPACE
REC_FRAMES_SPACE	SET	1024*128
	ENDIF

; Macro for generating init code
REC_INIT:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	jsr	REC_InitAll
	ENDIF
	ENDM

; Macro for generating finish code
REC_FINISHED:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	jsr	REC_Finish
	ENDIF
	ENDM

; Macro for saving recoding file
; Requires _DOSBase and requires DOS Lib open
REC_SAVE_RECORDING: MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d0-a6,-(sp)
	; Open file for Writing
	move.l	#REC_FileName,d1
	move.l	#MODE_NEWFILE,d2
	CALLDOS	Open
	tst.l	d0	; check for error
	beq.s	RES_SaveDone
	; Write Frame references
	move.l	d0,-(sp)
	move.l	d0,d1
	move.l	#REC_References,d2
	move.l	REC_ReferencesPtr,d3
	sub.l	d2,d3
	CALLDOS	Write
	; Write Frames
	move.l	(sp),d1
	move.l	#REC_Frames,d2
	move.l	REC_FramesPtr,d3
	sub.l	d2,d3
	CALLDOS	Write
	; Close file
	move.l	(sp)+,d1
	CALLDOS	Close
RES_SaveDone:
	movem.l	(sp)+,d0-a6
	ENDIF
	ENDM

; Macro for generating frame start code
REC_FRAME_START:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	jsr	REC_FrameStart
	ENDIF
	ENDM

; Macro for generating frame end
REC_FRAME_END:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	jsr	REC_FrameEnd
	ENDIF
	ENDM

; Record value word to HW register
;	\1 - value.w
;	\2 - HW register offset from $dff000
REC_WORD: MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d1-d2,-(sp)
	move.w	\1,d1	;d1 for value
	move.w	\2,d2	;d2 for HW register
	jsr	REC_CopperWord
	movem.l	(sp)+,d1-d2
	ENDIF
	ENDM

; Record long to HW register
;	\1 - value.l
;	\2 - HW register offset from $dff000
REC_LONG: MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d1-d2,-(sp)
	move.l	\1,d1	;d1 for value
	move.w	\2,d2	;d2 for HW register
	jsr	REC_CopperLong
	movem.l	(sp)+,d1-d2
	ENDIF
	ENDM

; Record Symbol with offset long to HW register
;	\1 - Symbol address
;	\2 - Offset address
;	\3 - HW register offset from $dff000
REC_SYMBOL: MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d1-d3,-(sp)
	move.l	\1,d1	;d1 for Symbol address
	move.w	\2,d2	;d2 offset address
	move.w	\3,d3	;d3 for HW register
	jsr	REC_CopperSymbol
	movem.l	(sp)+,d1-d3
	ENDIF
	ENDM

; Add Symbol to symbol table
;	\1 - Symbol address
;	\2 - Symbol name address
REC_SYMBOL_ADD:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d0-d1,-(sp)
	move.l	\1,d0
	move.l	\2,d1
	jsr	REC_SymbolAdd
	movem.l	(sp)+,d0-d1
	ENDIF
	ENDM

	IF	NO_CPU_RECORDER_ENABLE=1

REC_InitAll:
	movem.l	d0/a0-a1,-(sp)
	; references
	move.l	REC_ReferencesPtr(pc),a0
	lea	REC_Name(pc),a1
	bsr	REC_StrCopy
	lea	REC_NameFrames(pc),a1
	bsr	REC_StrCopy
	move.l	a0,REC_ReferencesPtr

	; frames
	move.l	REC_FramesPtr(pc),a0
	lea	REC_Name(pc),a1
	bsr	REC_StrCopy
	lea	REC_NameFramesPrefix(pc),a1
	bsr	REC_StrCopy

	move.l	a0,REC_FramesPtr
	movem.l	(sp)+,d0/a0-a1
	rts

REC_Finish:
	movem.l	d0/a0-a1,-(sp)
	move.l	REC_ReferencesPtr(pc),a0
	lea	REC_DCL(pc),a1
	bsr	REC_StrCopy
	moveq	#0,d0
	bsr	REC_WToHex
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+
	move.l	a0,REC_ReferencesPtr
	movem.l	(sp)+,d0/a0-a1
	rts


REC_FrameStart:
	movem.l	d0/a0-a1,-(sp)
	;frame reference
	move.l	REC_ReferencesPtr(pc),a0
	lea	REC_DCL(pc),a1
	bsr	REC_StrCopy
	lea	REC_Name(pc),a1
	bsr	REC_StrCopy
	move.b	#'F',(a0)+
	move.l	REC_Frame(pc),d0
	bsr	REC_WToHexNoPrefix
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+
	move.l	a0,REC_ReferencesPtr

	; frame label
	move.l	REC_FramesPtr(pc),a0
	lea	REC_Name(pc),a1
	bsr	REC_StrCopy
	move.b	#'F',(a0)+
	move.l	REC_Frame(pc),d0
	bsr	REC_WToHexNoPrefix
	move.b	#':',(a0)+
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+
	move.l	a0,REC_FramesPtr

	; next frame
	addq	#1,d0
	move.l	d0,REC_Frame
	movem.l	(sp)+,d0/a0-a1
	rts

; Record Copper Word value to HW register
; d1.w - Word value
; d2.w - HW register offset from $dff000
REC_CopperWord:
	movem.l	d0/a0-a1,-(sp)
	move.l	REC_FramesPtr(pc),a0
	lea	REC_DCW(pc),a1
	bsr.s	REC_StrCopy
	; HW Reg
	move.w	d2,d0
	bsr.s	REC_WToHex
	move.b	#',',(a0)+
	; Value
	move.w	d1,d0
	bsr.s	REC_WToHex
	; line end
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+

	move.l	a0,REC_FramesPtr
	movem.l	(sp)+,d0/a0-a1
	rts

; String copy
; a0 - destination, increased
; a1 - source string, increased
REC_StrCopy:
	tst.b	(a1)
	beq.s	REC_StrCopyDone
	move.b	(a1)+,(a0)+
	bra.s	REC_StrCopy
REC_StrCopyDone:
	rts

; Word to HEX string
; d0 - value
; a0 - destination, increased
REC_WToHex:
	move.b	#'$',(a0)+
REC_WToHexNoPrefix:
	movem.l d1-d2/a1,-(sp)
	lea	REC_Hex(pc),a1
	moveq	#3,d2
REC_WToHex_Digit:
	rol.w	#4,d0
	move.w	d0,d1
	and.w	#$f,d1
	move.b	(a1,d1.w),(a0)+
	dbf	d2,REC_WToHex_Digit
	movem.l (sp)+,d1-d2/a1
	rts

; Record Copper Long value to HW register
; d1.l - Long value
; d2.w - HW register offset from $dff000
REC_CopperLong:
	movem.l	d0/a0-a1,-(sp)
	move.l	REC_FramesPtr(pc),a0
	lea	REC_DCW(pc),a1
	bsr.s	REC_StrCopy
	;HW reg HI
	move.w	d2,d0
	bsr.s	REC_WToHex
	move.b	#',',(a0)+
	;Value HI
	swap	d1
	move.w	d1,d0
	bsr.s	REC_WToHex
	move.b	#',',(a0)+
	;HW reg LO
	add.w	#2,d2
	move.w	d2,d0
	bsr.s	REC_WToHex
	move.b	#',',(a0)+
	;Value LO
	swap	d1
	move.w	d1,d0
	bsr.s	REC_WToHex

	; line end
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+

	move.l	a0,REC_FramesPtr
	movem.l	(sp)+,d0/a0-a1
	rts

; Record frame end, trigger COP1JMP
REC_FrameEnd:
	movem.l	a0-a1,-(sp)
	move.l	REC_FramesPtr(pc),a0
	lea	REC_COPJMP1(pc),a1
	bsr.s	REC_StrCopy
	move.l	a0,REC_FramesPtr
	movem.l	(sp)+,a0-a1
	rts

; Record Copper Symbol with offset into HW register
; d1.l - Symbol address
; d2.l - Value address for offset calc
; d3.w - HW register offset from $dff000
REC_CopperSymbol:
	movem.l	d0/a0-a2,-(sp)
	; Find symbol name
	bsr	REC_SymbolFind
	move.l	a1,d0	; Check found
	bne.s	REC_CopperSymbolNameFound
	; Symbol name not found, add comment 
	move.l	REC_FramesPtr(pc),a0
	lea	REC_MissingSymbol(pc),a1
	bsr	REC_StrCopy
	move.l	a0,REC_FramesPtr
	; and use regular copper long
	move.l	d2,d1
	move.w	d3,d2
	bsr	REC_CopperLong
	bra	REC_CopperSymbolEnd
REC_CopperSymbolNameFound:
	move.l	REC_FramesPtr(pc),a0
	move.l	a1,a2	; keep symbol name
	sub.l	d1,d2	; calc offset
	lea	REC_DCW(pc),a1
	bsr	REC_StrCopy
	;HW reg HI
	move.w	d3,d0
	bsr	REC_WToHex
	move.b	#',',(a0)+
	; Symbol and offset HI Word
	tst.l	d2	; check for zero offset
	bne.s	REC_CopperSymbolHIWithOffset
	move.l	a2,a1	; just symbol
	bsr	REC_StrCopy
	bra.s	REC_CopperSymbolHIShift
REC_CopperSymbolHIWithOffset:
	bsr.s	REC_CopperSymbolWithOffset

REC_CopperSymbolHIShift:
	move.b	#'>',(a0)+
	move.b	#'>',(a0)+
	move.b	#'1',(a0)+
	move.b	#'6',(a0)+
	move.b	#',',(a0)+
	;HW reg LO
	add.w	#2,d3
	move.w	d3,d0
	bsr	REC_WToHex
	move.b	#',',(a0)+

	; Symbol and offset LO Word
	tst.l	d2	; check for zero offset
	bne.s	REC_CopperSymbolLOWithOffset
	move.l	a2,a1	; just symbol
	bsr	REC_StrCopy
	bra.s	REC_CopperSymbolLineEnd
REC_CopperSymbolLOWithOffset:
	bsr.s	REC_CopperSymbolWithOffset

REC_CopperSymbolLineEnd:
	move.b	#$d,(a0)+	; line end
	move.b	#$a,(a0)+

	move.l	a0,REC_FramesPtr
REC_CopperSymbolEnd:
	movem.l	(sp)+,d0/a0-a2
	rts

REC_CopperSymbolWithOffset:
	move.b	#'(',(a0)+
	move.l	a2,a1
	bsr	REC_StrCopy
	move.b	#'+',(a0)+
	move.l	d2,d0
	bsr	REC_WToHex
	move.b	#')',(a0)+
	rts

; Find Symbol name in table
; d1.l	symbol address
; Returns:
; a1.l	symbol name address
REC_SymbolFind:
	move.l	a0,-(sp)
	sub.l	a1,a1	;clear a1
	lea	REC_SymbolTable(pc),a0
REC_SymbolFindNext:
	cmp.l	REC_SymbolEnd(pc),a0
	beq.s	REC_SymbolFindEnd
	cmp.l	(a0),d1
	beq.s	REC_SymbolFindFound
	lea	$8(a0),a0
	bra.s	REC_SymbolFindNext
REC_SymbolFindFound:
	move.l	$4(a0),a1
REC_SymbolFindEnd:
	move.l	(sp)+,a0
	rts

;Add new symbol to table
; d0.l	Symbol address
; d1.l	Symbol name address
REC_SymbolAdd:
	move.l	a0,-(sp)
	move.l	REC_SymbolEnd(pc),a0
	move.l	d0,(a0)+
	move.l	d1,(a0)+
	move.l	a0,REC_SymbolEnd
	move.l	(sp)+,a0
	rts

	CNOP	0,2
; Table for converting to HEX number
REC_Hex:
	dc.b	"0123456789ABCDEF"

; source fragments
	CNOP	0,2
REC_DCW:
	dc.b	"	dc.w	",0

	CNOP	0,2
REC_DCL:
	dc.b	"	dc.l	",0

	CNOP	0,2
REC_COPJMP1:
	dc.b	"	dc.w	$0088,$0000",$d,$a,$d,$a,0

; Prefix for generated code
	CNOP	0,2
REC_Name:
	dc.b	"RECPart_",0

; Part of frames label
	CNOP	0,2
REC_NameFrames:
	dc.b	"Frames:",$d,$a,0

; Part of frames prefix label
	CNOP	0,2
REC_NameFramesPrefix:
	dc.b	"FramesPrefix:",$d,$a,0

; Filename to save recording
	CNOP	0,2
REC_FileName:
	dc.b	"NoCPURecording.s",0

; Missing symbol error
	CNOP	0,2
REC_MissingSymbol:
	dc.b	"; -- Missing Symbol --",$d,$a,0

; Address after last symbol in table
	CNOP	0,4
REC_SymbolEnd:
	dc.l	REC_SymbolTable

; Symbol table is list of pair addresses
; dc.l Pointer to Symbol memory
; dc.l Pointer to Symbol name, zero terminated string
	CNOP	0,4
REC_SymbolTable:
	blk.l	REC_MAX_SYMBOLS*2,0
	dc.l	0,0	; END With zeros just in case

	CNOP	0,4
; Current frame recording
REC_Frame:
	dc.l	0
REC_ReferencesPtr:
	dc.l	REC_References
REC_FramesPtr:
	dc.l	REC_Frames

	ENDIF

	ENDC  !NO_CPU_RECORDER_S

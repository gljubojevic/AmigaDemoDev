;**************************************************
; Macro set for NO CPU recoding copper fragments

; Default NO CPU Copper recording disabled
	IFND	NO_CPU_RECORDER_ENABLE
NO_CPU_RECORDER_ENABLE	SET	0
	ENDIF

	IFND	NO_CPU_RECORDER_S
NO_CPU_RECORDER_S	SET	1

; Macro for generating frame start code
REC_FRAME_START:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d0-d2/a0-a2,-(sp)
	move.l	REC_ReferencesPtr,a0
	moveq	#$9,d0
	move.b	d0,(a0)+
	move.b	#'d',(a0)+
	move.b	#'c',(a0)+
	move.b	#'.',(a0)+
	move.b	#'l',(a0)+
	move.b	d0,(a0)+
	move.l	REC_FramesPtr,a1
	lea	REC_Name,a2
REC_NameCopy\@:
	move.b	(a2)+,d0
	beq.s	REC_NameCopyDone\@
	move.b	d0,(a0)+
	move.b	d0,(a1)+
	bra.s	REC_NameCopy\@
REC_NameCopyDone\@:
	; frame prefix
	moveq	#'F',d0
	move.b	d0,(a0)+
	move.b	d0,(a1)+
	; frame number
	lea	REC_Hex,a2
	move.l	REC_Frame,d0
	move.l	d0,d1
	; next frame
	addq.l	#1,d1
	move.l	d1,REC_Frame

	moveq	#3,d2
REC_FrameDigit\@:
	rol.w	#4,d0
	move.l	d0,d1
	and.w	#$f,d1
	move.b	(a2,d1.w),d1
	move.b	d1,(a0)+
	move.b	d1,(a1)+
	dbf	d2,REC_FrameDigit\@

	move.b	#':',(a1)+
	moveq	#$d,d0
	move.b	d0,(a0)+
	move.b	d0,(a1)+
	moveq	#$a,d0
	move.b	d0,(a0)+
	move.b	d0,(a1)+

	move.l	a0,REC_ReferencesPtr
	move.l	a1,REC_FramesPtr
	movem.l	(sp)+,d0-d2/a0-a2
	ENDIF
	ENDM

; Macro for generating frame end
; trigger COP1JMP
REC_FRAME_END:	MACRO
	IF	NO_CPU_RECORDER_ENABLE=1
	movem.l	d0/a0,-(sp)
	move.l	REC_FramesPtr,a0

	moveq	#$9,d0
	move.b	d0,(a0)+
	move.b	#'d',(a0)+
	move.b	#'c',(a0)+
	move.b	#'.',(a0)+
	move.b	#'w',(a0)+
	move.b	d0,(a0)+

	move.b	#'$',d0
	move.b	d0,(a0)+
	move.b	#'0',(a0)+
	move.b	#'0',(a0)+
	move.b	#'8',(a0)+
	move.b	#'8',(a0)+
	move.b	#',',(a0)+
	move.b	d0,(a0)+
	move.b	#'0',(a0)+
	move.b	#'0',(a0)+
	move.b	#'0',(a0)+
	move.b	#'0',(a0)+

	move.b	#$d,(a0)+
	move.b	#$a,(a0)+
	move.b	#$d,(a0)+
	move.b	#$a,(a0)+

	move.l	a0,REC_FramesPtr
	movem.l	(sp)+,d0/a0
	ENDIF
	ENDM

; Prefix for generated code
	CNOP	0,2
REC_Name:
	dc.b	"RECPart_",0

; Table for converting to HEX number
	CNOP	0,2
REC_Hex:
	dc.b	"0123456789ABCDEF"

	CNOP	0,2
; Current frame recording
REC_Frame:
	dc.l	0
REC_ReferencesPtr:
	dc.l	REC_References
REC_FramesPtr:
	dc.l	REC_Frames

; Generated references to frames
REC_References:
	ds.b	65536,0
; Generated frames
REC_Frames:
	ds.b	65536,0

	ENDC  !NO_CPU_RECORDER_S

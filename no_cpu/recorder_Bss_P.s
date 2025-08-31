;**************************************************************************
; Declare here all data used by recorder that should be in public/fast mem
	IFND	NO_CPU_RECORDER_BSS_P_S
NO_CPU_RECORDER_BSS_P_S	SET	1

; Default NO CPU Copper recording disabled
	IFND	NO_CPU_RECORDER_ENABLE
NO_CPU_RECORDER_ENABLE	SET	0
	ENDIF

; Default mem space for recording references
	IFND	REC_REFERENCES_SPACE
REC_REFERENCES_SPACE	SET	1024*16
	ENDIF

	IFND	REC_FRAMES_SPACE
REC_FRAMES_SPACE	SET	1024*128
	ENDIF


	IF	NO_CPU_RECORDER_ENABLE=1

	CNOP	0,4
; Generated references to frames
REC_References:
	ds.b	REC_REFERENCES_SPACE,0

	CNOP	0,4
; Generated frames
REC_Frames:
	ds.b	REC_FRAMES_SPACE,0

	ENDIF

	ENDC  !NO_CPU_RECORDER_BSS_P_S

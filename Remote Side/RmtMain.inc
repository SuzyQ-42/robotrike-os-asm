;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																	 					 ;
;									RMTMAIN.INC											 ;
;					Constants for running the remote-side main loop						 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State and token type definitions for remote-side main loop
;
; Revision History:
;		12/07/2014		Suzannah Osekowsky	initial revision

;constants for use initializing the event queue on the remote side
	RMT_QUEUE_LENGTH	EQU		127		;maximum queue length
	WORD_QUEUE			EQU		0FFH	;word queue
    
;constants for use with display table
    ON_INDEX            EQU     0       ;display string "LASER ON"
    OFF_INDEX           EQU     1       ;display string "LASEROFF"
    SRL_ERR_INDEX       EQU     2       ;display string "SRLERROR"
    ILL_KEY_INDEX       EQU     3       ;display string "STOP IT"
    
    DISPLAY_ENTRY_SIZE  EQU     9       ;number of characters in display strings
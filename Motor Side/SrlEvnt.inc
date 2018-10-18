;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									SRLEVNT.INC											 ;
;			Constants for Installing and Setting the INT2 Event Handler					 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains constants for installing and setting up the INT2 event handler
;interrupt constants
	Int2Vec		EQU		14		;interrupt vector for serial value
	Int2EOI		EQU		14		;EOI identifier to send to end of interrupt controller
	Int2Priority    EQU  0      ;slightly less high-priority than timer interrupts
    
    UNMASK_INT2 	EQU 1111111110111111B   	;use to enable INT2
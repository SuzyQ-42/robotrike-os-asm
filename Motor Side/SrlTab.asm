	NAME	SERIALTAB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									SRLTAB.ASM											 ;
;					Tables of constants for writing serial values						 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Contains tables for use setting serial control registers. The tables included are
;	ParityTable		-		contains values used to set parity for each parity option
;	BaudTable		-		baud divisors for each of 8 reasonable baud rates

CGROUP	GROUP	CODE

CODE	SEGMENT	PUBLIC	'CODE'

; ParityTable
;
; Description:		Register values to use in each of 5 possible parity options
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 25, 2014
ParityTable		LABEL	BYTE
				PUBLIC	ParityTable
;	DB	parity register value 
	DB	00000000B	;no parity
	DB	00001000B	;odd parity
	DB	00011000B	;even parity
	DB	00101000B	;parity transmitted, always 1
	DB	00111000B	;parity bit transmitted, always 0

; BaudTable
;
; Description:		Divisors for 8 reasonable baud rates
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 25, 2014
BaudTable		LABEL	WORD
				PUBLIC	BaudTable
;	DW	baud divisor
	DW	    10		;56,000 baud
	DW		30		;19,200 baud
	DW	    60		;9,600 baud
	DW	    80		;7,200 baud
	DW	   120		;4,800 baud
	DW	   160		;3,600 baud
	DW	   240		;2,400 baud
	DW	   480		;1,200 baud
CODE	ENDS
END
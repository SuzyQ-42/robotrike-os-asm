;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            			 ;
;                                  DISPLAY.INC                                			 ;
;                              Display Procedures                            			 ;
;                                 Include File                               			 ;
;                                                                           			 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timer event handler.
;
; Revision History:
;		11/12/2014		Suzannah Osekowsky	initial revision

WORDLENGTH	EQU	02H						;allows us to turn a byte address into a word 
										;	address
BYTELENGTH	EQU	01H						;allows user to offset an address by 1 byte
WORDFACTOR		EQU	01H					;used to shift left/right by 1 value 
										;	(multiply/divide by 2)

MAX_STRING_SIZE	EQU	08H		;defines maximum string length to be num. of digits 
							;	available on LED readout 
MAX_NUM_BYTES	EQU	10H		;defines maximum number of bytes available to write 
							;	(maxStringSize* 2bytes/word)


LEDDisplay      EQU     0000H           ;display address
HIGHBITADDR		EQU		0008H			;address to which we write the high bit of each
										;	segment pattern

NUM_DIGITS      EQU     08H             ;number of digits in the display

SEG_BLANK		EQU		0000H			;blank segment pattern (display nothing)

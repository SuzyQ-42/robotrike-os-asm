;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									RMTPARS.INC											 ;
;					Constants for remote-side serial parsing							 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State and token type definitions for serial string parsing
;
; Revision History:	
;		12/07/2014	Suzannah Osekowsky	initial revision

; State definitions
	ST_INITIAL		EQU		0 		;initial state
	ST_GETNUMDIG	EQU		1		;have digits associated with value
	
	NUM_STATES		EQU		2		;number of states

; Token definitions
	TOKEN_DIGIT			EQU		0		;have an alphanumeric character (0-9, A-Z, a-z)
	TOKEN_OTHER			EQU		1		;have an illegal token
	TOKEN_EOS			EQU		2		;end transmission (carriage return)
    TOKEN_NOACTION      EQU     3      	;characters that don't affect the output
	
	NUM_TOKEN_TYPES		EQU		4		;number of token types
 
;constants for finding tokens
    TOKEN_MASK	        EQU	01111111B	;mask high bit of token
    
    DISPLAY_SIZE        EQU     9       ;8 available display digits + null character
    
    PARSING_ERROR       EQU     0100H   ;indicates a parsing error
    NO_ERROR            EQU     0000H   ;indicates no parsing error
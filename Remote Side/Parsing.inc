;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									PARSING.INC											 ;
;					Include file for parsing serial character strings					 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State and token type definitions for serial string parsing
;
; Revision History:	
;		12/01/2014	Suzannah Osekowsky	initial revision

; State definitions
	ST_INITIAL		EQU		0 		;initial state
	ST_SPEED		EQU		1		;have a letter "S," indicating set absolute speed
	ST_SPEEDSIGN	EQU		2		;have a sign (+/-) indicating sign of value to output
	ST_SPEEDDIGIT	EQU		3		;have a digit indicating current value to output
	ST_RELSPEED		EQU		4		;enter a relative speed
	ST_RELSPEEDSIGN	EQU		5		;enter a sign for relative speed
	ST_RELSPEEDDIG	EQU		6		;enter a value for relative speed
	ST_SETANGLE		EQU		7		;have a letter "D," indicating set direction
	ST_SETANGLESIGN	EQU		8		;set sign for direction
	ST_SETANGLEDIG	EQU		9		;set value for angle
	ST_TURRETANG	EQU		10		;have "T," indicating set turret rotation
	ST_TURRETANGSIG	EQU		11		;have sign, indicating set relative turret rotation
	ST_TURRETANGDIG	EQU		12		;digit of value corresponding to turret rotation
	ST_TURRETELEV	EQU		13		;have "E," indicating set turret angle of elevation
	ST_TURRETELSIGN	EQU		14		;have a sign for turret angle of elevation
	ST_TURRETELDIG	EQU		15		;have digits indicating value of turret angle of elev.
	ST_LASERON		EQU		16		;have "F," indicating fire laser
	ST_LASEROFF		EQU		17		;have "O," indicating laser off
	
	NUM_STATES		EQU		18		;number of states

; Token definitions
	TOKEN_SPEED			EQU		0		;set speed (S,s)
	TOKEN_RELSPEED		EQU		1		;set relative speed (V,v)
	TOKEN_SETANGLE		EQU		2		;set direction of movement (D,d)
	TOKEN_TURRETANG		EQU		3		;set turret rotation (T,t)
	TOKEN_TURRETELEV	EQU		4		;set turret angle of elevation (E,e)
	TOKEN_LASERON		EQU		5		;fire laser (F,f)
	TOKEN_LASEROFF		EQU		6		;laser off (O,o)
	TOKEN_SIGN			EQU		7		;have a sign (+,-)
	TOKEN_DIGIT			EQU		8		;have a digit (0-9)
	TOKEN_OTHER			EQU		9		;have an illegal token
	TOKEN_EOS			EQU		10		;end transmission (carriage return)
    TOKEN_NOACTION      EQU     11      ;characters that don't affect the output
	
	NUM_TOKEN_TYPES		EQU		12		;number of token types
	
;constants for setting shared variables
	NO_SIGN				EQU		  0		;indicates that no sign has yet been transmitted
	NEG_SIG 			EQU	   0FFH		;indicates a negative sign
	POS_SIG			    EQU		01H		;indicates that value will be positive
	
	MAX_TURRET_ANG		EQU		60		;max output angle of elevation
	MIN_TURRET_ANG		EQU	   -60		;min output turret angle of elevation
	
	NO_ERROR			EQU		0		;no error status
	PARSING_ERROR		EQU		0100H	;indicates a parsing error
    
    FULL_ROTATION       EQU     360     ;number of degrees in a full rotation
    
    MAX_ARG             EQU     8000H   ;largest value that the argument value can have
    MAX_SPEED           EQU    0FFFEH   ;largest value for speed
 
;constants for finding tokens
    TOKEN_MASK	        EQU	01111111B	;mask high bit of token
	
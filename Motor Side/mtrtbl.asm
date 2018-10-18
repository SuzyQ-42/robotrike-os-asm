NAME	MTR_TABLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;										MTR_TABLE										 ;
;					Tables of values relevant to motor speed calculation				 ;
;									Suzannah Osekowsky									 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains the tables of factors and constants necessary to find and output the 
; correct speed to each motor in order to maintain a given a given speed and angle of 
; motion. Values are normalized to 32767.
; The tables included are:
;	MtrXFactorTable	-	values to multiply by X-component of speed in motors
;	MtrYFactorTable	-	values to multiply by Y-component of speed in motors
;	MtrFwdTable		-	values for moving each motor forward
;	MtrReverseTable	-	values for moving each motor backward
;
; Revision History
;	11/21/2014	Suzannah Osekowsky	initial revision
;	12/14/2014	Suzannah Osekowsky	updated headers

CGROUP	GROUP	CODE

CODE	SEGMENT	PUBLIC	'CODE'

; MtrXFactorTable
;
; Description:		This is the factor by which to multiply each of the motors' 
;					x-component of speed. Normal rounding is used to generate values; 
;					values are normalized to 32767 = 1 (Q0.15)
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 18, 2014

MtrXFactorTable		LABEL	WORD
					PUBLIC	MtrXFactorTable
;	DW	normalized value (hexadecimal)
	DW	07FFFH		;motor 1
	DW	0C001H		;motor 2
	DW  0C001H		;motor 3

; MtrYFactorTable
;
; Description:		This is the factor by which to multiply each of the motors' 
;					y-component of speed. Normal rounding is used to generate values; 
;					values are normalized to 32767 = 1 (Q0.15)
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 18, 2014

MtrYFactorTable		LABEL	WORD
					PUBLIC	MtrYFactorTable
;	DW	normalized value (hexadecimal)
	DW		 0000		;motor 1
	DW		 9127H		;motor 2
	DW		 6ED9H		;motor 3 
	
; MtrFwdTable
;
; Description:		Values to "OR" into the output value to move each motor forward,
;					respectively. Values are given in binary.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 18, 2014

MtrFwdTable			LABEL	BYTE
					PUBLIC	MtrFwdTable
;	DB	value (binary)
	DB	00000010B	;motor 1
	DB	00001000B	;motor 2 
	DB	00100000B	;motor 3 
	
; MtrReverseTable
;
; Description:		Values to "OR" into the output value to move each motor backward,
;					respectively. Values are given in binary and offset is equal to motor
;					index pertaining to each value.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 18, 2014

MtrReverseTable		LABEL	BYTE
					PUBLIC	MtrReverseTable
;	DB	value (binary)
	DB	00000011B	;motor 1
	DB	00001100B	;motor 2 
	DB	00110000B	;motor 3

CODE	ENDS
END	
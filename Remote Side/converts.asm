        NAME    CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;							  Suzannah Osekowsky			    			 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Contains functions to convert a 16-bit value to either a signed decimal ASCII
; string or an unsigned hexadecimal ASCII string. The included public functions 
; are:
;		Dec2String: converts a 16-bit value to a signed ASCII decimal string
;		Hex2String: converts a 16-bit value to an unsigned ASCII hexadecimal string
;
; 
;
;	
;
; Revision History:
;	10/22/2014 Suzannah Osekowsky	remove null preceding entry
;	10/23/2014 Suzannah Osekowsky	write assembly
;	10/24/2014 Suzannah Osekowsky	debugged, updated comments
;	11/02/2014 Suzannah Osekowsky	saved address in SI



CGROUP  GROUP   CODE
$INCLUDE(ASCII.inc)

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP




; Dec2String
;
;Description:	The function is passed a 16-bit signed value and a memory 	
;				location a. It converts the signed value to a signed ASCII 
;				decimal string (5 digits + sign) and stores that result
;				in memory location a (in SI). 
;
;Operation:		The function first checks if the argument is negative 
;				and sets the sign bit. If negative, it negates the 
;				argument. It then proceeds to divide by the largest possible 
;				power of 10, returning the resulting value as the first  
;				digit and storing it in a memory location given to the  
;				function. The remainder is stored back in the argument
;				and power of 10 is divided by 10. This process is repeated
;				until the power of 10 is zero, at which point the full 
;				number has been stored in memory location a.
;
;Arguments:			AX - 16-bit signed binary value to convert to ASCII string
;					SI - location at which to write ASCII string
;
;Return Values:		none
;
;Local Variables:	arg (BX) - copy of passed binary value to convert
;					digit (AX) - computed digit
;					pwr10 (CX) - current power of 10 being computed
;
;Shared Variables:	None
;Global Variables:	None
;Input:				None
;Output:			None
;Error Handling:	None
;
;Registers Used:	flags, AX, BX, CX, DX
;Stack Depth:		3 words
;
;Algorithms:		OR argument with itself to set sign flag; negate if negative
;					Repeatedly divide by powers of 10 to get ASCII digits
;
;Data Structures: 	None
;			
;Known Bugs:		None
;Limitations:		None within argument set of 16-bit signed values
;
;Revision History:	10/19/2014 Suzannah Osekowsky	initial revision
;					10/22/2014 Suzannah Osekowsky	remove null preceding entry
;					10/23/2014 Suzannah Osekowsky	write assembly
;					11/02/2014 Suzannah Osekowsky 	use stack to avoid changing SI
;													
; Author: Suzannah Osekowsky
; Last Modified: 11/2/2014

Dec2String      PROC        NEAR
                PUBLIC      Dec2String

Dec2StringInit:					;initialization
	PUSH SI						;save SI to keep it the same in other functions
	MOV	BX,AX					;BX = arg
	MOV	CX, 10000				;start with 10^4 as power 10
	;JMP	Dec2StringLoop		;otherwise start dividing by pwr10

Dec2StringLoop:
	CMP	CX,0					;check if pwr10>0
	JLE	EndDec2StringLoop		;If not, done, end function
	CMP	BX,0					;check if arg>0
	JGE	Dec2StringLoopBody		;If so, get next digit
	;JMP	NegativeSign		;else, process negative
	
NegativeSign:
	MOV BYTE PTR [SI],ASCIIminus		;Store ASCII minus sign in SI
	INC	SI								;Increment storage location
	NEG	BX								;arg = -arg
	;JMP	Dec2StringLoopBody			;Start dividing positive arg by pwr10

Dec2StringLoopBody:					;function to get a digit
	MOV	DX,0						;get ready to divide
	MOV	AX, BX						;load argument
	DIV	CX							;digit(AX) = arg/pwr10
	;JMP	HaveDigit				;process the digit

HaveDigit:							;store digit in memory
	MOV	BYTE PTR [SI],ASCIIzero	;put ASCII zero in SI
	ADD ES:[SI],AX					;adds digit to stored zero
	INC	SI							;increment storage location
	MOV	BX,DX						;Work with remainder
	MOV	AX,CX						;setup to update pwr10
	MOV	CX,0AH						; sets CX to 10, clears error
	MOV 	DX,0					;Clear DX to prepare for div
	DIV	CX							;updates power of 10
	MOV	CX,AX						; pwr10=pwr10/10
	;JMP	EndDec2StringLoopBody	;Done with this digit

EndDec2StringLoopBody:				
	JMP	Dec2StringLoop				;keep looping (end check is at top)

EndDec2StringLoop:					;Done converting
	MOV	BYTE PTR [SI],00H		;add null termination
	POP SI							;restore pointer value to SI
	RET								;and return

Dec2String	ENDP


; Hex2String
;
;Description:		The function is passed a 16-bit unsigned value to 
;					convert to a hexadecimal string (4 digits) 
;					and stores that result in memory location a (in SI). 
;
;Operation:			The function divides by the largest possible 
;					power of 16, returning the resulting value as the first hex digit 
;					and storing it.The remainder is stored back in the argument
;					and power of 16 is divided by 16. This process is repeated
;					until the power of 10 is zero, at which point the full number
;					has been stored in memory location a.
;
;Arguments:			AX - 16-bit unsigned binary value to convert to ASCII string
;					SI - location at which to write ASCII string
;
;Return Values:		none
;
;Local Variables:	arg (SI) - copy of passed binary value to convert
;					digit (AX) - computed digit
;					pwr16 (CX) - current power of 16 being computed
;
;Shared Variables:	None
;Global Variables:	None
;Input:				None
;Output:			None
;Error Handling:	None
;
;Registers Used:	AX, CX, DX, SI
;Stack Depth:		3 words
;
;Algorithms:		Repeatedly divide by powers of 16 to get ASCII digits
;
;Data Structures: 	None
;
; Author: Suzannah Osekowsky
; Last Modified:11/2/2014

Hex2String      PROC        NEAR
                PUBLIC      Hex2String

Hex2StringInit:						;initialization
	PUSH SI							;save SI to restore at the end of function
	MOV	BX,AX						;BX = arg
	MOV	CX, 1000H					;start with 16^3 as pwr16
	JMP	Hex2StringLoop				;start dividing by pwr16

Hex2StringLoop:
	CMP	CX, 0						;check if pwr16>0
	JLE	EndHex2StringLoop			;If not, done, end function
	;JMP	Hex2StringLoopBody		;else, get the next digit

Hex2StringLoopBody:					;function to get a digit
	MOV	DX,0						;get ready to divide
	MOV	AX, BX						;load argument
	DIV	CX							;digit(AX) = arg/pwr16
	;JMP	HaveDigit				;process the digit

CheckVal:
	CMP	AX,9						;check if digit(AX)>9
	JG	HaveDigitTenPlus			;otherwise, process digit for digit>9
	;JLE	HaveDigitSubTen			;if not, process digit

HaveDigitSubTen:					;store digit from 0-9 in memory
	MOV	BYTE PTR [SI],ASCIIzero	;put ASCII zero(initial digit) in storage location
	ADD [SI],AX					;add digit to stored zero
	INC	SI							;increment storage location
	MOV	BX,DX						;Work with remainder
	MOV	AX,CX						;setup to update pwr16
	MOV	CX,10H						; sets CX to 16, clears error
	MOV DX,0						;Clear DX to prepare for div
	DIV	CX							;updates power of 16
	MOV	CX,AX						; pwr16=pwr16/16
	JMP	EndHex2StringLoopBody		;Done with this digit

HaveDigitTenPlus:
	SUB	AX, 10
	MOV	BYTE PTR [SI],ASCIIhexTen		;put ASCII "A" in memory location
	ADD	[SI],AX							;add digit to stored ASCII A
	INC	SI								;increment storage locations
	MOV	BX,DX							;Work with remainder
	MOV	AX,CX							;setup to update pwr16
	MOV	CX,10H							; sets CX to 16, clears error
	MOV DX,0							;Clear DX to prepare for div
	DIV	CX								;updates power of 16
	MOV	CX,AX							; pwr16=pwr16/16
	;JMP	EndHex2StringLoopBody		;Done with this digit

EndHex2StringLoopBody:				
	JMP	Hex2StringLoop				;keep looping (end check is at top)

EndHex2StringLoop:					;Done converting
	MOV	BYTE PTR [SI],00H			;add null termination
	POP	SI							;return SI to original value
	RET								;returns nothing

Hex2String	ENDP


CODE    ENDS



        END

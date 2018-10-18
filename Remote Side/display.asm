NAME    DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Display                                  ;
;                      Outputting Strings to Display                         ;
;                              Suzannah Osekowsky                            ;
;																			 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains a set of functions for displaying values 
;		InitializeDisplay	clears display variables
;		MUXDisplay		writes a specific digit to a spot on the display
;		Display			outputs a given string to the display buffer
;		DisplayNum		outputs a number to the display in signed decimal
;		DisplayHex		outputs a number to the display in hexadecimal
;
;Revision History:	11/02/2014	Suzannah Osekowsky initial revision

CGROUP	GROUP	CODE

CODE    SEGMENT PUBLIC  'CODE'
    ASSUME  CS:CGROUP, DS:DATA
;external function declarations
	EXTRN	Dec2String:NEAR		;converts a binary value to an ASCII signed decimal string
	EXTRN	Hex2String:NEAR		;converts a binary value to an ASCII hexadecimal string
	EXTRN	ASCIISegTable:BYTE	;contains a table for converting ASCII characters to 
								;	segment patterns
	
;include files
$INCLUDE(ASCII.inc)				;contains definitions of a few key ASCII values
$INCLUDE(Display.inc)			;defines max string size, some key addresses and segment 
								;	patterns

;InitializeDisplay
; Description: 		Initializes buffer and digit index to zero.
;
;Operation:			Clears "Digit," clears each entry in the display buffer.
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	BX - buffer offset
;					
; Shared Variables:	Digit - index of digit to which we begin writing values
; Global Variables:	None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	Array for output buffer
;
; Registers Used:	flags, AX, BX
; Stack Depth:		0 words
;
; Limitations:		None
;
; Author:           Suzannah Osekowsky
InitializeDisplay	PROC	NEAR
					PUBLIC	InitializeDisplay
BeginDispInit:
	MOV	Digit,0					;clear digit; start writing at digit 0
	XOR	BX,BX					;start clearing buffer at 0th place
ClearBuffer:
	XOR	AX,AX					;clear AX
	CMP	BX,MAX_NUM_BYTES			;checks if index is at maximum write location
	JE	EndInitialize			;if so, stop writing values
	MOV	WORD PTR stringBuffer[BX], SEG_BLANK	;else, turns this digit off
	INC	BX						;increment digit index
	JMP	ClearBuffer				;repeat
EndInitialize:
	RET							;returns nothing in particular
InitializeDisplay	ENDP

	

;MUXDisplay
; Description: 		Gets a segment pattern value from the display buffer and writes it to 
;					the display. The output is a left-justified, 14-segment display 
;					limited to 8 characters. If the pattern is more than 8 digits long, 
;					the remaining digits are not displayed.
;
;Operation:			Gets a segment pattern value from the display buffer and writes it to 
;					the corresponding display digit. Once it displays the last digit, it 
;					loops the digit counter back to zero and begins displaying again at 
;					the first digit.
;
; Arguments:		None
; Return Value:		None
;
; Local Variables:	CX - buffer offset
;					AX - current ASCII offset pre/post conversion
; Shared Variables:	Digit - index for display digits
; Global Variables:	None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	Arrays for conversion and output buffers
;
; Registers Used:	flags, AX, BX, CX, DX
; Stack Depth:		0 words
;
; Limitations:		Cannot display a value using more than 8 characters
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/02/2014
MUXDisplay		PROC	NEAR
				PUBLIC	MUXDisplay
CheckTermination:
	MOV		BX,Digit					;can use BX as index, but not a variable
	CMP		BX,NUM_DIGITS				;check if we're at the end of the display
	JE		LoopChar					;if so, go back to beginning of string
	;JNE	DisplayDigit				;if not, continue to display digit

DisplayDigit:							;update the display
	SHL	BX,WORDFACTOR					;multiply index by length of entries
	MOV	BX,stringbuffer[BX]				;get word value to be displayed
	MOV	DX,LEDDisplay + HIGHBITADDR		;accesses upper bits that allow 14-segment 
										;	characters
	MOV	AL,BH							;shifts for output
	OUT	DX,AL							;outputs high bit to the other 7 segments
	MOV	DX,LEDDisplay					;get display address
	ADD DX,Digit						;set DX to address of current digit output
	MOV	AL,BL
	OUT	DX,AL							;outputs the segment pattern to its corresponding
										;	LED display digit
	INC	Digit							;increments the digit to which we're displaying
	JMP	EndMUXDisplay					;Holds this digit until called again

LoopChar:
	MOV	Digit,00H						;sets offset to zero
	;JMP EndMuxDisplay					;finish, don't display anything
EndMUXDisplay:
	RET									;returns nothing in particular
MUXDisplay	ENDP

;Display
; Description: 		Takes an ASCII string passed in ES:SI and loads the corresponding 
;					segment pattern into the string buffer for display. The timer event 
;					handler accesses this buffer to multiplex the 14-segment LED display. 
;					If the string is less than 8 digits, it is left-justified and the 
;					remainder of 8 addresses in the buffer are filled with blank segment 
;					patterns. If the string is greater than 8 characters, the remaining 
;					characters are cut off and not displayed.
;
;Operation:			Gets a sequence of ASCII character values from the location at ES:SI. 
;					For each value, uses a lookup table to find the correct segment 
;					pattern; then loads that pattern into a buffer for use by the display 
;					functionality in the timer event handler.
;
; Arguments:		SI - location of string to be stored
; Return Value:		None
;
; Local Variables:	CX - buffer offset
;					AX - current ASCII offset pre/post conversion
; Shared Variables:	None
; Global Variables:	None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	Arrays for conversion and output buffers
;
; Registers Used:	flags, AX, BX, CX, SI
; Stack Depth:		0 words
;
; Limitations:		Cannot display a value using more than 8 characters
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/02/2014
Display		PROC	NEAR
			PUBLIC	Display
DisplayInit:
	MOV		CX,00H				;sets initial buffer offset to zero
	;JMP	DisplayLoop			;go to get values from buffer
DisplayLoop:
	XOR	AX,AX					;clear AX to avoid remaining values in upper bits
	MOV AL,BYTE PTR ES:[SI]		;get the value on the read buffer (ASCII display values)
	SHL	AX,WORDFACTOR           ;multiples the display value by 2 to get its location in 
								;	the table
	MOV	BX,OFFSET(ASCIISegTable);set BX to the base + offset = address of segment pattern
	ADD	BX,AX					;adds offset to BX
	MOV	AX,CS:[BX]				;gets value from segment pattern table
    MOV BX,CX                   ;copy buffer offset to BX so it can be an index
	MOV	WORD PTR stringBuffer[BX], AX	;puts segment pattern in buffer
	;JMP CheckNull				;check if the next digit is a <null> termination
CheckNull:						;checks for <null> termination
	MOV AL,ES:[SI]				;puts the current ASCII character in output location
	CMP	AL,ASCIInull			;checks if the currents value is a <null> termination
	JE	EndDisplayLoop			;if equal, null all remaining characters
	MOV	BX,CX					;moves a copy of the write index for operations
	CMP	CX,MAX_NUM_BYTES		;checks if index has reached the maximum write location
	JE	EndDisplay				;if equal, stop storing characters
	INC SI						;else, increment read location
	ADD CX,WORDLENGTH			;	and increment write location
	JMP DisplayLoop				;if not null and not at max address, add another value to 
								;	buffer
EndDisplayLoop:
	MOV	BX,CX					;goes to digit we want to null
	CMP	CX,MAX_NUM_BYTES		;checks if index is at maximum write location
	JE	EndDisplay				;if so, stop writing values
	MOV	WORD PTR stringBuffer[BX], SEG_BLANK	;else, turns this digit off
	INC	CX						;increment digit index
	JMP	EndDisplayLoop			;repeat

EndDisplay:
	RET							;returns 
Display ENDP


;DisplayNum
; Description:		Takes a 16-bit number and converts it to a string of ASCII signed 
;					decimal digits, then loads it into the string buffer for display. The 
;					buffer is then read by the display MUXing function.
;
;Operation:			Moves argument to appropriate register, loads previously defined 
;					functions Dec2String and Display.
;
; Arguments:		AX - value to be converted/displayed
; Return Value:		None
;
; Local Variables:	BX - copy of value to be converted
; Shared Variables:	None
; Global Variables:	None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		Repeatedly dividing by powers of 10 to find decimal representation
; Data Structures:	Array for string buffer
;
; Registers Used:	AX, BX, SI, ES, flags
; Stack Depth:		2 words
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/02/2014

DisplayNum	PROC	NEAR
			PUBLIC	DisplayNum
	MOV		BX,AX				;moves value to be converted into the correct register
								;	it doesn't make any sense that I need this, but my 
								;	code breaks without it.
	LEA 	SI,ASCIIbuffer		;put converted values into ASCIIbuffer
	CALL	Dec2String			;converts binary number into signed ASCII decimal at SI
	MOV 	AX,DS				;copies string into location from which Display will read
	MOV		ES,AX
	CALL	Display				;move string to buffer for display
	RET							;Returns nothing in particular
DisplayNum ENDP

;DisplayHex
; Description:		Takes a 16-bit number and converts it to a string of ASCII hexadecimal
;					digits, then loads it into the string buffer for display. The 
;					buffer is then read by the display MUXing function.
;
;Operation:			Moves argument to appropriate register, loads previously defined 
;					functions Hex2String and Display.
;
; Arguments:		AX - value to be converted/displayed
; Return Value:		None
;
; Local Variables:	BX - copy of value to be converted
; Shared Variables:	None
; Global Variables:	None
;
; Input:			None
; Output:			Hexadecimal characters to 14-seg LED display
;
; Error Handling:	None
;
; Algorithms:		Repeatedly dividing by powers of 16 to find hexadecimal representation
; Data Structures:	Array for string buffer
;
; Registers Used:	AX, BX, SI, ES, flags
; Stack Depth:		2 words
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/02/2014

DisplayHex	PROC	NEAR
			PUBLIC	DisplayHex
	MOV		BX,AX				;moves value to be converted into the correct register
	LEA		SI,ASCIIbuffer		;write Hex2String result to ASCII buffer
	CALL	Hex2String      	;converts binary number into ASCII hexadecimal at SI
	MOV 	AX,DS				;copies DS to the address from which Display will read
	MOV		ES,AX
	CALL	Display				;move string to buffer for display
	RET							;Returns nothing in particular
DisplayHex ENDP

CODE ENDS

;the data segment

DATA    SEGMENT PUBLIC  'DATA'

ASCIIbuffer 	DB	MAX_STRING_SIZE	DUP(?);creates a buffer to hold ASCII values in order
Digit           DW      ?               	;the current digit number
SegPat          DW      ?               	;the current segment pattern number
stringbuffer 	DW	MAX_STRING_SIZE	DUP(?);creates a buffer to hold segment patterns

DATA    ENDS

END
	NAME	KEYPAD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									KEYPAD.ASM											 ;
;			Scanning and debouncing functions for the target board keypad				 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains a set of functions for displaying values 
;		KeypadInit		initializes keypad variables
;		KeyScan			scans for button presses and debounces
;
;Revision History:	11/09/2014	Suzannah Osekowsky	initial revision

CGROUP	GROUP	CODE

CODE    SEGMENT PUBLIC  'CODE'
    ASSUME  CS:CGROUP, DS:DATA

;include files
$INCLUDE(KEYPAD.INC)

;external function declarations
EXTRN	EnqueueEvent:NEAR		;creates a buffer of event identifiers

;KeypadInit
;
;Description:	Initializes variables for the keypad by clearing them.
;Operation:		Sets all keypad variables to zero
;
; Arguments:		None
; Return Value:		None
;
; Local Variables:	None
; Shared Variables:	None
; Global Variables:	None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	None
;
; Registers Used:	AX
; Stack Depth:		0 words
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/09/2014

KeypadInit	PROC	NEAR
			PUBLIC	KeypadInit
	MOV	Line,0				;clear line counter index
	MOV	LastVal,0			;and history monitor
	MOV	CurrentVal,0		;and currently read value
	MOV	CurrentKey,0	;and key identifier
	MOV	DebounceCnt,MAX_DEBOUNCE	;max out debouncing counter
	RET						;done, return
KeypadInit	ENDP

;KeyScan
;
;Description:		Scans one row of keys each time it's called to see if any buttons are 
;					being pressed. If so, it re-scans that row until the button is 
;					released or until it's been held for MAX_DEBOUNCE ms. When a key has 
;					been held for long enough, it calls the external function EnqueueEvent
;					to put an event identifier for the specific key in the event buffer 
;					(called EventBuf). Has auto-repeat every AUTO_RPT_TIME ms for already 
;					debounced keys.
;
;Operation:			Compares the current value of the keypad with the keypad output with 
;					no keys pressed, then checks if that value was the same as the value 
;					in the previous scan. If so, decrements debounce counter; if not, 
;					updates line number and continues scanning. Once a keey has been 
;					pressed for long enough, the key identifier is passed to an event 
;					buffer and the debounce counter goes up to AUTO_RPT_TIME ms until the 
;					button is released or another button is pressed.
;
; Arguments:		None
; Return Value:		None
;
; Local Variables:	AX - currently pressed keys
; Shared Variables:	None
; Global Variables:	None
;
; Input:			Key presses
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	Buffer of event identifiers
;
; Registers Used:	AX, DX, flags
; Stack Depth:		1 word
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/09/2014
KeyScan		PROC	NEAR
			PUBLIC	KeyScan
ScanInit:
    XOR     DX,DX                   ;clear upper byte so address is correct
    MOV     DL,Keypad               ;gets the output value of the current line
    ADD     DL,Line
	IN		AL, DX
    AND     AX,CLEAR_EXTRA_BIT      ;clears the (nonsensical) imported top bit
	XOR		AL,NO_KEYS_PRESSED		;gets the bits at which the keypad is deviating from 
									;	its empty (no presses) state
	MOV		CurrentVal,AL			;loads the current set of pressed keys into AX
	CMP		AL,0					;check if the current line is outputting all zeroes
	JE		NextLine				;done with this line, update to read the next one
	;JNE	Debounce				;if not NoKeys, go to debounce currently pressed keys
Debounce:
	XOR		AL,LastVal				;check if the currently pressed keys are the same as 
									;	the last ones
	CMP		AL,0					;if so, add a value to the debounce counter
	JE		DebounceStep			
	;JNE	NewDebounce	
NewDebounce:
	MOV		DebounceCnt,MAX_DEBOUNCE;clears debounce counter
    MOV     DL,Line                 ;get current line identifier
    SHL     DL,BITSHIFT             ;move to second display digit
    ADD     DL,CurrentVal           ;Get current key identifier      
	MOV		CurrentKey,DL           ;store
DebounceStep:
	DEC		DebounceCnt				;decrements debounce counter
    MOV     DL,Line                 ;get current line identifier
    SHL     DL,BITSHIFT             ;move to second display digit
    ADD     DL,CurrentVal           ;Get current key identifier
	AND		CurrentKey, DL      	;if more than one key in this line was 
									;	pressed, ensures that only the relevant (held) 
									;	ones are being counted
	CMP		DebounceCnt,0			;checks if the key has been pressed long enough
	JNE		ScanDone				;if not, done; return.
	;JE		KeyPress				;if so, generate key press event
KeyPress:
	MOV		AL,CurrentKey			;output the key identifier in the lower bits of AX
    MOV		AH,KeyEvent				;   and the key event code in the upper bits 
	MOV		DebounceCnt,AUTO_RPT_TIME	;start auto-repeating
	CALL	EnqueueEvent			;add key press to event buffer
	JMP	    ScanDone				;finished; wait until next interrupt
NextLine:
	INC		Line					;scan next line
	CMP		Line,MAX_LINE			;check if at maximum num. of lines
	JNE 	ScanDone				;if not, done; return.				
	MOV		Line,0	                ;else, clear Line and start back at zero.				
	;JMP	ScanDone
ScanDone:
    MOV     AL,CurrentVal
    MOV     LastVal,AL               ;update value history
	RET		;done so return
KeyScan	ENDP
CODE	ENDS

DATA SEGMENT	PUBLIC	'DATA'
	Line		DB		?			;current keyboard line from which we're reading
	LastVal		DB		?			;the last value the debouncer read
	DebounceCnt	DW		?			;number of times the current value has been output
	CurrentVal	DB		?			;the current value output by the keypad
	CurrentKey	DB		?			;current key being debounced
DATA	ENDS

END
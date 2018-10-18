;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									KEYPAD.INC											 ;
;					Constants and Relevant Values for Keypad							 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CLEAR_EXTRA_BIT EQU     000FH       ;AND with a value to get only the last bit of that val
NO_KEYS_PRESSED	EQU		0fH		    ;the value output by a keypad line read if no keys are
									;	pressed	
MAX_LINE		EQU		04H			;the maximum number of lines
MAX_DEBOUNCE	EQU		50  		;maximum number of cycles before concluding an 
									;	intentional press (currently set to 16ms)
AUTO_RPT_TIME	EQU		0200H		;maximum number of ms before the key considers 
									;	itself pressed again; currently set to about half 
									;	a second
BITSHIFT        EQU     04H     	;moves a value 1 hex digit to the left	
							
Keypad			EQU		80H		;starting address for reading from keypad
KeyEvent		EQU		00H			;gives a nice event identifier for key presses
	NAME	KEYPADEVENTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									KEYFUNC.ASM											 ;
;						Functions associated with key presses							 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains functions handling key presses for the remote-side main loop. The 
;	functions included are:
;		KeyPressEvent:		Performs actions based on key press
;		KeypadTable:		Call table of functions for various key presses
;		IllegalKey:			Generates error message for illegal key press
;		AngleDecrease:		Rotates the robotrike's direction vector by 1 degree CCW
;		AngleIncrease:		Rotates the robotrike's direction vector by 1 degree clockwise
;		OutputSerialString:	Helper function that outputs a given string to serial
;		Stop:				Stops the robotrike (sets speed to zero)
;		TurnLaserOn:		Fires the laser
;		TurnLaserOff:		Turns off the laser
;		DecreaseSpeed:		Increment robotrike speed by 1
;		DecreaseSpeed:		Decrement robotrike speed by 1
;		SerialStringTable:	Table of strings to be output to serial port based on presses
;
;	Revision History:	
;		12/07/2014	Suzannah Osekowsky	initial revision

CGROUP	GROUP	CODE

CODE    SEGMENT PUBLIC  'CODE'
    ASSUME  CS:CGROUP
    
;local include files
$INCLUDE(KEYFUNC.INC)           ;constants for key press functions
$INCLUDE(RMTMAIN.INC)           ;constants for displaying strings
$INCLUDE(MOTOR.INC)             ;again, only defines constant for reading from word queues

; external function declarations
	EXTRN	SerialPutChar:NEAR	    ;puts characters into the serial output queue
    EXTRN   Display:NEAR            ;displays a string at passed address
    EXTRN   DisplayIllegalKey:NEAR  ;outputs an illegal key string to display
    EXTRN   DisplayStringTable:BYTE ;table of strings to be output to display

	
; KeyPressEvent
;
; Description:		Handles a pressed key on the remote keypad. 
;
; Operation:		Uses a table lookup to find the correct function associated with the 
;					pressed key. Combinations of keys are ignored (considered illegal) and
;					not all keys have associated actions.
;
; Arguments:		AL - key identifier value
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	Displays error message if an illegal key is pressed.
;
; Registers Used:   
; Stack Depth:      2 words
;
; Algorithms:		
; Data Structures:	
;
; Known Bugs:		
; Limitations:		
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
KeyPressEvent		PROC	NEAR
					PUBLIC	KeyPressEvent
	MOV		BX,OFFSET(KeypadTable)	;look up key associated function in table
    MOV     AH,00                   ;clear upper bits so I can add registers
    MOV     CX,WORDLENGTH           ;read from word table
    MUL     CX              
	ADD		BX,AX
    MOV     SI,CS:[BX]              ;move data into addressable register
	CALL 	SI  					;call function pertaining to key press
	RET
KeyPressEvent		ENDP
	
; KeypadTable
;
; Description:		Call table for functions responding to key presses
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 07, 2014
KeypadTable		LABEL	WORD
				PUBLIC	KeypadTable
;	DW		OFFSET(function)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 00)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 01)
	DW		OFFSET(AngleIncrease)	;Decrease set angle  (key code 02)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 03)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 04)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 05)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 06)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 07)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 08)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 09)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 0A)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 0B)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 0C)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 0D)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 0E)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 0F)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 10)
	DW		OFFSET(Stop)			;stop (set speed 0)  (key code 11)
	DW		OFFSET(AngleDecrease)	;decrease set angle  (key code 12)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 13)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 14)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 15)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 16)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 17)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 18)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 19)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 1A)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 1B)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 1C)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 1D)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 1E)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 1F)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 20)
	DW		OFFSET(TurnLaserOn)		;Laser fire key pressed (key code 21)
	DW		OFFSET(IncreaseSpeed)	;Decrease set speed (key code 22)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 23)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 24)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 25)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 26)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 27)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 28)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 29)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 2A)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 2B)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 2C)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 2D)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 2E)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 2F)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 30)
	DW		OFFSET(TurnLaserOff)	;Turn off laser (key code 31)
	DW		OFFSET(DecreaseSpeed)	;decrease set speed (key code 32)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 33)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 34)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 35)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 36)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 37)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 38)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 39)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 3A)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 3B)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 3C)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 3D)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 3E)
	DW		OFFSET(IllegalKey)		;illegal key pressed (key code 3F)

; IllegalKey
;
; Description:		Outputs 'STOP IT' to display. Expects to be called when an unallowed 
;					key is pressed.
;
; Operation:		Sets the string to be displayed to 'STOP IT' and calls Display
;					function.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: DisplayString - stores string to be output to display
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	Tells you to stop pressing keys that don't do anything.
;
; Registers Used:   AX, SI
; Stack Depth:      1 word
;
; Algorithms:		
; Data Structures:	
;
; Known Bugs:		
; Limitations:		
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
IllegalKey		PROC	NEAR
				PUBLIC	IllegalKey
	MOV		SI,ILL_KEY_INDEX		    ;set ASCII string to be displayed to "STOP IT"
	IMUL    SI,DISPLAY_ENTRY_SIZE   
    ADD     SI,OFFSET(DisplayStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL    Display					    ;and call Display function
    RET
IllegalKey	ENDP

; AngleDecrease
;
; Description:		Decreases angle of motion (rotate direction vector by 1 degree 
;					clockwise)
;
; Operation:		Uses serial output functions to enqueue characters for output to the 
;					serial port. Outputs characters indicating that the angle value
;					should be increased (rotated counterclockwise) by 1 degree
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
AngleDecrease	PROC	NEAR
				PUBLIC	AngleDecrease
	MOV		SI,ANG_DEC_INDEX		    ;output serial characters indicating angle should 
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   be decreased
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
AngleDecrease	ENDP

; AngleIncrease
;
; Description:		Increases angle of motion (rotates direction vector by 1 degree 
;					clockwise)
;
; Operation:		Uses serial output functions to enqueue characters for output to the 
;					serial port. Outputs characters indicating that the angle value
;					should be decreased (rotated clockwise) by 1 degree
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
AngleIncrease	PROC	NEAR
				PUBLIC	AngleIncrease
	MOV		SI,ANG_INC_INDEX		    ;output serial characters indicating angle should 
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   be decreased
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
AngleIncrease	ENDP

; OutputSerialString
;
; Description:		Outputs a stored ASCII string to serial port; loops ensuring that all
;					characters up to 1st carriage return in the string are output.
;
; Operation:		Loops calling serial enqueue function, looping on each character until
;					queue is not full.
;
; Arguments:		SI - offset of value to be output to serial
;                   ES - segment in which value is stored
; Return Values:	None.
;
; Local Variables:	CX - counter for serial string loop
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX,BX, flags
; Stack Depth:      19 words
;
; Algorithms:		None.
; Data Structures:	serial string buffer - array of characters to be output to serial port
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
OutputSerialString	PROC	NEAR
					PUBLIC	OutputSerialString
	OutputSrlInit:
		MOV		CX,0						;reset counter
	OutputSerialStringLoop:
        MOV     BX,SI                       ;get current address of serial character
        ADD     BX,CX                       ;up to the byte
		MOV		AL,ES:[BX]		
		CMP		AL, EOS                    	;check if at end of transmission
		JE		EndTransmission				;if not at end, continue sending
											;	characters
		CALL	SerialPutChar				;enqueue for serial output
		JC		OutputSerialStringLoop		;loop until value is enqueued
		INC		CX							;increment counter if value is enqueued
		JMP		OutputSerialStringLoop		;loop until hit end of transmission signal
		
    EndTransmission:
        MOV     AL,EOS                      ;else, output end of transmission
        CALL    SerialPutChar               ;enqueue for serial output
        JC      EndTransmission             ;loop until value is enqueued
		RET									;and return
OutputSerialString	ENDP

; Stop
;
; Description:		Stops the robotrike (sends a serial string setting speed to zero)
;
; Operation:		Sends a serial string setting the speed of the robotrike to zero
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words.
;
; Algorithms:		None.
; Data Structures:	serialString - array holding a string to be output by the 
;									OutputSerialString function
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
Stop		PROC	NEAR
			PUBLIC	Stop
    MOV		SI,STOP_INDEX		        ;output serial characters indicating robotrike  
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   should stop
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
Stop        ENDP

; TurnLaserOn
;
; Description:		Sends a serial command to fire the laser.
;
; Operation:		Writes a laser fire command to the serial buffer, then calls a
;					function to enqueue the values for serial output
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words
;
; Algorithms:		None.
; Data Structures:	serialString - array holding a string to be output by the 
;									OutputSerialString function
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
TurnLaserOn		PROC	NEAR
				PUBLIC	TurnLaserOn
	MOV		SI,LASER_ON_INDEX		    ;output serial characters indicating laser should 
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   be fired
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
TurnLaserOn		ENDP

; TurnLaserOff
;
; Description:		Sends a serial command to shut off the laser.
;
; Operation:		Writes a laser off command to the serial buffer, then calls a
;					function to enqueue the values for serial output
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words
;
; Algorithms:		None.
; Data Structures:	serialString - array holding a string to be output by the 
;									OutputSerialString function
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
TurnLaserOff	PROC	NEAR
				PUBLIC	TurnLaserOff
	MOV		SI,LASER_OFF_INDEX		    ;output serial characters indicating laser should 
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   be turned off
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
TurnLaserOff	ENDP

; DecreaseSpeed
;
; Description:		Increments current speed of robot. Expects to be called when the user 
;					wants the robot to move faster.
;
; Operation:		Sends a set relative speed command to the serial port to decrease 
;					speed by 256.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
DecreaseSpeed		PROC	NEAR
					PUBLIC	DecreaseSpeed
	MOV		SI,SPEED_DEC_INDEX		    ;output serial characters indicating speed should 
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   be decreased
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
DecreaseSpeed		ENDP	

; IncreaseSpeed
;
; Description:		Increments current speed of robot. Expects to be called when the user 
;					wants the robot to move faster.
;
; Operation:		Sends a set relative speed command to the serial port to increase 
;					speed by 256.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      20 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
IncreaseSpeed		PROC	NEAR
					PUBLIC	IncreaseSpeed
	MOV		SI,SPEED_INC_INDEX		    ;output serial characters indicating speed should 
	IMUL    SI,SERIAL_ENTRY_SIZE        ;   be increased
    ADD     SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	OutputSerialString				;output that string	
	RET
IncreaseSpeed		ENDP	

; SerialStringTable
;
; Description:      This is a table containing strings to be output to serial port 
;                   according to key presses.
;
; Author:           Suzannah Osekowsky
; Last Modified:    Dec. 10, 2014
SerialStringTable	LABEL	BYTE
    DB  'D-1    ',EOS        ;Increase angle of movement
    DB  'D+1    ',EOS        ;Decrease angle of movement
    DB  'S0     ',EOS        ;Stop
    DB  'F      ',EOS        ;Fire laser
    DB  'O      ',EOS        ;Laser off
    DB  'V-256  ',EOS        ;decrease speed
    DB  'V+256  ',EOS        ;increase speed
			
CODE	ENDS

END
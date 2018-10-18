	NAME	PARSING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									PARSING.ASM											 ;
;					Parsing state machine for robotrike serial signals					 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains the main functions for parsing serial input characters.
; The functions included are:
;	ParseInit:			initializes shared variables for use with other actions
;   ParseSerialChar:    parse a serial input character
;   GetSrlToken: 		get an input token for the parser
; 	newDigit:			handles a new digit input
;	clrVals:			prepares system to receive a new command string
;	doNOP:				idle state
;	error:				generates a parsing error
;	setSign:			sets the sign of the current value being written
;	speedOut:			outputs the newly set speed to the motors
;	relSpeedOut:		outputs newly set relative speed to the motors
;	angleOut:			outputs newly set direction to motors
;	turretAngOut:		outputs turret rotation angle to motors
;	turretElevOut:		outputs turret angle of elevation to turret motor
;	laserOn:			sets laser on
;	laserOff:			sets laser off
;	laserOut:			outputs laser value to laser
;
; The tables included are:
;	StateTable:			contains state transitions and actions associated with each 
;							state and token type
;
; Revision History:
;     2/26/03  	Glen George             initial revision
;     2/24/05  	Glen George             simplified some code in ParseSrl
;                                       updated comments
;	 12/01/14	Suzannah Osekowsky		updated for use with serial characters
;	 12/04/14	Suzannah Osekowsky		added overflow, underflow control
;	 12/05/14	Suzannah Osekowsky		updated comments
;	 12/14/14	Suzannah Osekowsky		added status transmissions to remote side

CGROUP	GROUP	CODE

CODE    SEGMENT PUBLIC  'CODE'
    ASSUME  CS:CGROUP, DS:DATA

;local include files
$INCLUDE(Parsing.INC)	;constants for token types and state order
$INCLUDE(MOTOR.INC)		;constants for use when calling motor functions
$INCLUDE(ASCII.inc)     ;constants for use with writing ASCII strings

;external function declarations
	EXTRN	SetMotorSpeed:NEAR		;takes arguments of robotrike speed and direction and 
									;	moves them to shared variables.
	EXTRN	GetMotorSpeed:NEAR		;finds current intended robotrike speed
	EXTRN	GetMotorDirection:NEAR	;finds current intended robotrike movement angle
	EXTRN	SetLaser:NEAR			;receives a signal and outputs a value (on or off) to 
									;	the laser
	EXTRN	SetTurretAngle:NEAR		;outputs absolute rotation of turret to turret motor
	EXTRN	SetRelTurretAngle:NEAR	;outputs relative rotation of turret to turret motor
	EXTRN	SetTurretElevation:NEAR	;outputs absolute angle of elevation of turret
    EXTRN   SerialPutChar:NEAR      ;puts a character in the serial transmit queue
	EXTRN	OutputSerialString:NEAR	;outputs a serial string to the serial port
    EXTRN   Dec2String:NEAR         ;converts a signed decimal value to a string
    EXTRN   Hex2String:NEAR         ;converts an unsigned hexadecimal value to a string

; ParseInit
;
; Description:		Initializes variables and states for the serial character parser state
;					machine.
;
; Operation:		Sets shared variables to their no action/initial states (e.g., laser 
;					off, current argument cleared, etc.)
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: Laser - holds current state of laser
;					CmdVal - current argument value based on characters that have so far 
;							 been passed
;					ValSign - holds sign (if present) of value currently being passed
;					ErrorStat - current error status of the system
;					CurrState - indicates which state the FSM is currently in
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	serialString - array storing values corresponding to serial states
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014	
ParseInit	PROC	NEAR
			PUBLIC	ParseInit
	MOV	Laser,LASER_OFF			;clear laser status variable
	MOV	CmdVal,0 				;clear variable indicating value associated with argument
	MOV	ValSign,NO_SIGN			;clear sign variable
	MOV	ErrorStat,NO_ERROR		;clear error variable
	MOV	CurrState,ST_INITIAL	;start at initial state
ClearStringLoop:
    MOV     serialString[BX],ASCIInull  ;clear entries
    INC     BX                          ;next entry
    CMP     BX,SERIAL_SIZE             ;unless at max value
    JNE     ClearStringLoop             ;loop until at maximum location
	RET							;done, return
ParseInit	ENDP

; ParseSerialChar
;
; Description:		Accepts a serial (ASCII) character passed in AL, and uses external 
;					table lookups to translate that character into a state change for the 
;					serial parsing state machine. Returns PARSING_ERROR if the character 
;					creates a parsing error, and returns zero otherwise.
;
; Operation:		Uses a table to get the token type and value associated with the 
;					passed character, then uses a state machine table to find the actions
;					and state transition associated with that character and the current 
;					state of the state machine. It then performs those actions (external
;					functions) and returns the error status.
;
; Arguments:		AL - serial character
; Return Values:	AX - error status
;
; Local Variables:	None.
; Shared Variables: CurrState - defines the current state of the parsing FSM
;					ErrorStat - holds the current error status of the parsing FSM
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	Returns error status in AX
;
; Registers Used:   AX, BX, CX, DX, flags
; Stack Depth:      3 words
;
; Algorithms:		None.
; Data Structures:	Code tables of FSM values (actions, state transitions)
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014

ParseSerialChar		PROC    NEAR
					PUBLIC  ParseSerialChar	
DoNextToken:				;get next input for state machine
	CALL	GetSrlToken		;and get the token type and value (character is in AL)
	MOV		DH,AH			;and save token type in DH and token value in CH
	MOV		CH,AL
	
ComputeTransition:				;figure out what transition to do
	MOV		AL,NUM_TOKEN_TYPES	;find row in table
	MOV		CL,CurrState		;AL = NUM_TOKEN_TYPES * CurrState + TOKEN_TYPE
	MUL		CL					;looks up correct table row
	ADD 	AL, DH				;get actual transition
	ADC		AH, 0				;propagate low byte carry into high byte
	MOV		BX,0				;clear unused register
	IMUL	BX,AX,SIZE TRANSITION_ENTRY   ;now convert to table offset

DoTransition:									;go to next state
	MOV	AL, CS:StateTable[BX].NEXTSTATE			;and prepare to accept another character
	MOV	CurrState,AL							;store in shared variable


DoActions:								;do the actions (don't affect regs)
	MOV		AL,CH						;get token value back for actions
	CALL	CS:StateTable[BX].ACTION1	;do the actions
	MOV		CX,ErrorStat				;load error status
	CALL	CS:StateTable[BX].ACTION2

EndParseSerial:				;done parsing serial character, return with nothing
	MOV	AX,CX				;outputs error status
	
    RET
ParseSerialChar		ENDP

; GetSrlToken
;
; Description:		Uses a passed serial character to look up the token type and value 
;					that will be used to find the actions and state transition associated
;					with the character.
;
; Operation:		Strips the high (unused) bit of the passed character and gets the 
;					token type and value from code tables. Returns with the token type and
;					value.
;
; Arguments:		AL - passed serial character
; Return Values:	AH - token type
;					AL - Token value
;
; Local Variables:	BX - table pointer, points at lookup tables.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX, BX
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
GetSrlToken	PROC    NEAR
			PUBLIC	GetSrlToken

InitGetSrlToken:				;setup for lookups
	AND		AL,TOKEN_MASK		;strip unused bits (high bit) and preserve value in AH
	MOV		AH,AL		

TokenTypeLookup:                        ;get the token type
    MOV		BX,OFFSET(TokenTypeTable)  	;BX points at table
	XLAT	CS:TokenTypeTable			;have token type in AL
	XCHG	AH, AL						;token type in AH, character in AL

TokenValueLookup:							;get the token value
    MOV		BX,OFFSET(TokenValueTable)  	;BX points at table
	XLAT	CS:TokenValueTable				;have token value in AL

EndGetSrlToken:                     	;done looking up type and value
    RET

GetSrlToken	ENDP
	
; newDigit
;
; Description:		Adds a new decimal digit to the currently stored argument value by 
;					first multiplying the current argument by 10 and then adding the new 
;					digit. Performs an overflow check (largest allowed positive value is 
;					32767, largest allowed negative value is 32768)
;
; Operation:		Multiplies the current argument by 10, generating an error if it 
;					overflows. If it does not overflow, the passed digit is added. Again, 
;					if the resulting value exceeds the maximum, then the function stops 
;					and generates an error. Otherwise, it stores the updated decimal value
;					in a shared variable.
;
; Arguments:		AL - digit to be added (0-9)
; Return Values:	None.
;
; Local Variables:	BX - current argument being updated
; Shared Variables: CmdVal - current argument to the system
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	Generates error if the value being updated exceeds it alotted space.
;
; Registers Used:   AX, BX (both restored), flags
; Stack Depth:      3 words
;
; Algorithms:		CmdVal = (10*CmdVal) + current_digit updates current value by shifting
;					it one decimal place left and adding the newest value.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
newDigit	PROC	NEAR
			PUBLIC	newDigit
	PUSH	AX								;might as well save registers
	PUSH	BX
MulTen:
	MOV		BX,CmdVal						;updates current value by shifting
	IMUL	BX,10							;it one decimal place left and adding the
											;	newest value. Also shift left by one to
											;	properly indicate overflow (will fix later)
	JO		DigitError						;if it overflows its space, give error
AddNewDigit:
	MOV		AH,0							;clear junk (upper) bits
	ADD		BX,AX							;add to current value
	JNO		StoreNewDigit					;if it overflows, check if it is the only 
	CMP		BX,MAX_ARG						; allowed value that uses the high bit (8000H)
	JNE		DigitError						; if it isn't, send error
	CMP		ValSign,NEG_SIG					; also check if value is to be subtracted
	JNE		DigitError						;and if not, this is also an error
	
StoreNewDigit:
	MOV		CmdVal,BX						;else, store back in shared variable
	JMP		newDigitDone					;and return
	
DigitError:
	CALL	error							;if there is an overflow error,
	MOV		CurrState,ST_INITIAL			; go to initial state, set error status
	
newDigitDone:
	POP		BX								;restore registers
	POP		AX								
	RET			
newDigit	ENDP

; clrVals
;
; Description:		Clears shared variables to be used in the next state. Expects to be
;					called whenever the system jumps back to the initial state.
;
; Operation:		Sets shared variables to their initial states.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: CmdVal - abs. value of current argument being handled by the system
;					ValSign - sign of current argument being handled by the system
;					ErrorStat - current error status of system
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
clrVals		PROC	NEAR
			PUBLIC	clrVals
	MOV		CmdVal,0			;clear shared variables
	MOV		ValSign,NO_SIGN
	MOV		ErrorStat,NO_ERROR	;and error status
	RET
clrVals		ENDP

; doNOP
;
; Description:		Idle state; a space-filler. Literally does nothing and returns.
;
; Operation:		Actually just returns.
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
; Stack Depth:      0 words.
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 1, 2014
doNOP	PROC	NEAR
		PUBLIC	doNOP
	NOP
	RET		;it really just returns.
doNOP	ENDP

; error
;
; Description:		Generates a parsing error
;
; Operation:		Outputs an invalid serial character, generating a parsing error on the
;                   remote end, which displays a serial error message.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: ErrorStat - current error status
; Global Variables: None.
;
; Input:            None.
; Output:			None yet.
;
; Error Handling:	Generates error state
;
; Registers Used:   None.
; Stack Depth:      None.
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 1, 2014
error	PROC	NEAR
		PUBLIC	error
	MOV	    AL,'G'		    ;transmit a character indicating a parsing error (will 
    CALL    SerialPutChar   ;   generate a parsing error on remote side)
	RET
error	ENDP

; setSign
;
; Description:		Uses the passed token value to set the sign of the argument currently 
;					being handled. Expects to be called when the passed serial character
;					is a valid + or - sign.
;
; Operation:		If the passed token value indicates a negative sign, sets the shared 
;					sign variable to a negative sign; else, sets a positive sign. Returns.
;
; Arguments:		AL - token value associated with the passed sign character.
; Return Values:	None
;
; Local Variables:	None.
; Shared Variables: ValSign - sign of current argument being handled by the system
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX (read only), flags
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
setSign		PROC	NEAR
			PUBLIC	setSign
	CMP	AL,-1				;check if sign argument indicates transmitted negative sign
	JNE	PositiveSign		;if not, set sign to positive
	MOV	ValSign,NEG_SIG		;if so, set sign to negative
	JMP	SetSignDone			;and return
PositiveSign:
	MOV	ValSign,POS_SIG	;set sign to positive
	;JMP	SetSignDone		;done, return
SetSignDone:
	RET 					;done, return
setSign		ENDP

; speedOut
;
; Description:		Outputs the current serial argument to the motor speed set function,
;					which turns that value into individual speeds for each motor according
;					to equations of holonomic motion. It then transmits a string to the 
;					serial port containing the speed indicator (letter "S") and the 
;					current speed in hex (0000 to FFFE).
;
; Operation:		Sets the direction argument to maintain whatever it's currently doing,
;					and updates the speed variable to match the current argument. Then 
;					calls the external function SetMotorSpeed. We don't need to do any 
;					overflow/underflow checks because the passed value can't exceed the 
;					maximum speed value. It then sets the shared serial string variable to
;					contain the ASCII character "S" followed by an ASCII string indicating
;					the speed value in hexadecimal (use an external converter function to 
;					accomplish this), and calls OutputSerialString to output that string 
;					to the serial port.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	SI - address to which to write an ASCII character
; Shared Variables: CmdVal - abs. value of current argument being handled
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	None.
;
; Registers Used:   AX, BX (changed and restored)
; Stack Depth:      12 words
;
; Algorithms:		None.
; Data Structures:	serialString - array containing values to be output to the serial
;					buffer.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 14, 2014
speedOut	PROC	NEAR
			PUBLIC	speedOut
	PUSH	AX					;save registers
	PUSH	BX		
	MOV		BX,SAME_ANGLE		;set angle to not change
	MOV		AX,CmdVal			;set speed as indicated by serial string
	CALL	SetMotorSpeed		;set individual motor speed for PWM
	CALL	GetMotorSpeed		;get the robotrike's speed in AX
	LEA		SI,serialString		;load address of temporary serial transmit buffer
	MOV		BYTE PTR [SI],'S'	;write speed-indicating serial character to serial port
	INC		SI                  ;start writing at next (blank) spot
    MOV     BX,DS               ;read from data segment
    MOV     ES,BX
	CALL	Hex2String			;convert the speed value to hexadecimal string
	LEA		SI,serialString
	CALL	OutputSerialString	;and output to serial port
	POP		BX					;restore registers
	POP		AX
	RET
speedOut	ENDP

; relSpeedOut
;
; Description:		Gets the current trike speed and adds the (positive or negative) 
;					argument to that value. Maintains current direction of movement and
;					performs underflow and overflow checks. It then transmits a string to 
;					the serial port containing the speed indicator (letter "S") and the 
;					current speed in hex (0000 to FFFE).
;
; Operation:		Gets the current motor speed by calling an external function. If the 
;					current sign is negative, the current argument is subtracted from the
;					current speed. If this goes below zero, the speed bottoms out at 
;					zero (cancels underflow). If the current sign is not negative, then 
;					the current argument is added to the current speed. If this goes above
;					the maximum speed, the speed maxes out at MAX_SPEED. Maintains the 
;					same angle of motion and calls SetMotorSpeed. It then sets the shared 
;					serial string variable to contain the ASCII character "S" followed by 
;					an ASCII string indicating the speed value in hexadecimal (use an 
;					external converter function to accomplish this), and calls 
;					OutputSerialString to output that string to the serial port.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	AX - speed being updated
; Shared Variables: CmdVal - abs. value of current argument being handled by the system
;					ValSign - sign of current argument being handled by the system
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	Speed bottoms out at zero and maxes out at MAX_SPEED
;
; Registers Used:   AX,BX (changed and restored)
; Stack Depth:      2 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
relSpeedOut		PROC	NEAR
				PUBLIC	relSpeedOut
	PUSH	AX							;save registers
	PUSH	BX
	Call 	GetMotorSpeed				;get the current motor speed in AX
	CMP		ValSign,NEG_SIG				;negate current value if negative
	JNE		AddSpeed					;else, go to add values
	SUB		AX,CmdVal					;if supposed to be negative, subtract
	JNC		OutputRelSpeed				;and output
	
SpeedUnderflow:							;or correct for underflow, if present
	CMP		AX,0						;if result is greater than zero,
	JGE		OutputRelSpeed				;go to output
	MOV		AX,0						;otherwise set to zero (no negative vals)
	JMP		OutputRelSpeed				;and output
	
AddSpeed:
	ADD		AX,CmdVal					;add to current motor speed
	JC		SpeedOverflow				;and output
	CMP     AX,SAME_SPEED               ;check if speed has exceeded max w/o carry
    JE      SpeedOverflow               ;if so, correct speed
    JMP     OutputRelSpeed              ;if has not exceeded max, proceed to output
    
SpeedOverflow:							;or correct for overflow, if present
	MOV		AX,MAX_SPEED				;else, max out speed (handle overflow)
	JMP		OutputRelSpeed				

OutputRelSpeed:
	MOV		BX,SAME_ANGLE				;maintain current angle
	Call	SetMotorSpeed				;and output to motors
	
OutputSerialInstruction:
	CALL	GetMotorSpeed		;get the robotrike's speed in AX
	LEA		SI,serialString		;load address of temporary serial transmit buffer
	MOV		BYTE PTR [SI],'S'	;write speed-indicating serial string to serial port
	INC		SI                  ;start writing at next (blank) spot
    MOV     BX,DS               ;read from data segment
    MOV     ES,BX
	CALL	Hex2String			;convert the speed value to decimal string to be displayed
	LEA		SI,serialString
	CALL	OutputSerialString

RelSpeedDone:
	POP		BX							;restore registers
	POP		AX
	RET
relSpeedOut		ENDP

; angleOut
;
; Description:		Adds the current (positive or negative) argument to the current 
;					direction of movement. Handles overflow and underflow by repeatedly
;					changing the current direction by +/- 360.  It then transmits a string
;					to the serial port containing the angle indicator (letter "D") and the 
;					current direction in decimal decrees (0 to 360).
;
; Operation:		Gets the current motor direction using an external function. If the 
;					current argument is negative, then it is subtracted from the current 
;					direction; if this exceeds available space, then the subtraction is 
;					repeated from a value that is 360 larger than the value originally
;					returned by the GetMotorDirection function. If the current argument is
;					nonnegative, then it is added to the current direction; if this 
;					exceeds available space, then the addition is repeated with a value
;					that is 360 less than the value originally returned by the 
;					GetMotorDirection function. The speed argument is set to maintain the 
;					same speed at which the robot is currently traveling and the resulting
;					direction is output to motors. It then sets the shared serial string 
;					variable to contain the ASCII character "D" followed by an ASCII 
;					string indicating the angle value in decimal (uses an external 
;					converter function to accomplish this), and calls OutputSerialString 
;					to output that string to the serial port.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: CmdVal - abs. value of current argument being handled by the system
;					ValSign - sign of current argument being handled by the system
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	Decreases argument by full rotations until it fits within allowed 
;					space.
;
; Registers Used:   AX, BX (changed and restored), flags
; Stack Depth:      3 words
;
; Algorithms:		Decreases argument by full rotations until it fits within allowed 
;					space.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
angleOut	PROC	NEAR
			PUBLIC	angleOut
	PUSH	AX							;save registers
	PUSH	BX
GetAngleVal:
	CALL	GetMotorDirection			;set new angle relative to current angle
	MOV		BX,AX						;change registers for output
	
	CMP		ValSign,NEG_SIG				;subtract and perform underflow check if 
										;	negative
	JNE		AddAngleVal					;else, go to output positive angle value

SubAngleVal:	
	SUB		BX,CmdVal					;output to motors at new angle, same speed
	JNO		MotorSpeedOut				;if no underflow, continue to output
	ADD		AX,FULL_ROTATION			;if underflow, cap by rotating by multiples
										; of a full circle
	MOV		BX,AX						;change registers for output
	JMP		SubAngleVal					;and repeat until subtraction no longer  
										; causes underflow
	
AddAngleVal:
	ADD		BX,CmdVal					;output to motors at new angle, same speed
	JNO		MotorSpeedOut				;if no overflow, continue to output
	SUB		AX,FULL_ROTATION			;if overflow, cap by rotating by multiples
										; of a full circle
	MOV		BX,AX						;change registers for output
	JMP		AddAngleVal					;and repeat until addition no longer causes 
										;overflow
	
MotorSpeedOut:
	MOV		AX,SAME_SPEED				;output to motors
	CALL	SetMotorSpeed
	
SerialAngleOut:
	CALL	GetMotorDirection	;get the robotrike's speed in AX
	LEA		SI,serialString		;load address of temporary serial transmit buffer
	MOV		BYTE PTR [SI],'D'	;write angle-indicating serial string to serial port
	INC		SI                  ;start writing at next (blank) spot
    MOV     BX,DS               ;read from data segment
    MOV     ES,BX
	CALL	Dec2String			;convert the speed value to decimal string to be output to
	LEA		SI,serialString		;serial port
	CALL	OutputSerialString
	
AngleOutDone:
	POP		BX							;restore registers
	POP		AX
	RET									;done, return
angleOut	ENDP

; turretAngOut
;
; Description:		If there is no sign attached to the argument, sets the turret rotation
;					to the current argument. If there is a sign attached to the argument,
;					sets relative turret angle to the positive or negative argument.
;
; Operation:		Checks the sign attached to the current argument; if no sign present, 
;					sets the current turret rotation to the current argument. If there is 
;					a negative sign, negates argument and sets the turret angle relative 
;					to its current angle to the negated argument. If there is a positive 
;					sign, sets the turret angle relative to its current angle to the 
;					argument.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: CmdVal - abs. value of current argument being handled by the system
;					ValSign - sign of current argument being handled by the system
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	None.
;
; Registers Used:   AX, BX (changed and restored), flags
; Stack Depth:      3 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
turretAngOut	PROC	NEAR
				PUBLIC	turretAngOut
	PUSH	AX							;save registers
	CMP		ValSign,NO_SIGN				;if have absolute angle, then prepare for output
	JNE		RelativeTurretAngle			;if have relative angle, go to relative angle
										;	calculations
	MOV		AX,CmdVal					;else, get ready for abs. angle output
	CALL	SetTurretAngle				;and call appropriate function
	JMP		TurretAngleDone				;then return
RelativeTurretAngle:					;if have relative speed, then
	CMP		ValSign,NEG_SIG				;check whether val is positive or negative	
	JNE		AddVal						;if positive, skip negation
	NEG		CmdVal						;if negative, negate
	;JMP	AddVal						;and set relative turret rotaton
AddVal:
	MOV		AX,CmdVal
	CALL	SetRelTurretAngle			;add current value to current angle and output
TurretAngleDone:
	POP		AX							;restore registers
	RET									;done, return
turretAngOut	ENDP	

; turretElevOut
;
; Description:		Sets the turret angle of elevation to the (positive or negative) 
;					serial argument. 
;
; Operation:		Negates the argument if a negative sign is stored in the sign variable
;					and checks that the resulting value is between -60 and 60 inclusively.
;					If it is, the value is set as the turret elevation. If it isn't, the
;					function returns without outputting anything to the turret
;					elevation function.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: CmdVal - abs. value of current argument being handled by the system
;					ValSign - sign of current argument being handled by the system
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	Returns without outputting to turret elevation if the argument is not
;					between -60 and 60 inclusively.
;
; Registers Used:   AX (changed and restored), flags
; Stack Depth:      2 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		Passed value CmdVal must be in the range of -60 to 60 inclusively, 
;					else function terminates without calling SetTurretElevation.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
turretElevOut	PROC	NEAR
				PUBLIC	turretElevOut
	PUSH	AX							;save registers
	CMP		ValSign,NEG_SIG				;check sign of passed value
	JNE		SetElevation				;if not negative, go set elevation
	NEG		CmdVal						;correct sign of passed value if negative
SetElevation:
	CMP		CmdVal,MAX_TURRET_ANG		;check if value is within desired range
	JG		SetElevationDone
	CMP		CmdVal,MIN_TURRET_ANG
	JL		SetElevationDone			;if so, 
	MOV		AX,CmdVal					; output it to turret elevation actuators
	CALL	SetTurretElevation
SetElevationDone:
	POP		AX							;restore registers
	RET									;done so return
turretElevOut	ENDP

; LaserOn
;
; Description:		Sets shared laser status variable to LASER_ON, returns.
;
; Operation:		Sets shared laser status variable to LASER_ON, returns.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: Laser - stores current laser status.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      0 words.
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
LaserOn	PROC	NEAR
		PUBLIC	LaserOn
	PUSHA                       ;save registers
	MOV		Laser,LASER_ON		;set shared variable to indicate that laser is off
	MOV     SI,ON_INDEX           		;load message indicating laser is on
    IMUL    SI,SERIAL_ENTRY_SIZE
	ADD		SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;display a string stored in code segment
    MOV     ES,AX
	CALL	OutputSerialString
    POPA                        ;restore registers
	RET
LaserOn	ENDP

; LaserOff
;
; Description:		Sets shared laser status variable to LASER_OFF, returns.
;
; Operation:		Sets shared laser status variable to LASER_OFF, returns.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: Laser - stores current laser status.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   None.
; Stack Depth:      0 words.
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
LaserOff	PROC	NEAR
		PUBLIC	LaserOff
    PUSHA                       ;save registers      
	MOV		Laser,LASER_OFF		;set shared variable to indicate that laser is off
	MOV     SI,OFF_INDEX           		;load message indicating laser is off
    IMUL    SI,SERIAL_ENTRY_SIZE
	ADD		SI,OFFSET(SerialStringTable)
    MOV     AX,CS                       ;display a string stored in code segment
    MOV     ES,AX
	CALL	OutputSerialString
    POPA                        ;restore registers
	RET
LaserOff	ENDP

; LaserOut
;
; Description:		Gets laser status and sets laser appropriately.
;
; Operation:		Gets laser status from shared variable and uses it as the argument to
;					external function SetLaser, which sets the actual laser.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: Laser - current laser status
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	None.
;
; Registers Used:   AX
; Stack Depth:      9 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
LaserOut	PROC	NEAR
		PUBLIC	LaserOut
	PUSHA						;save registers
	MOV		AH,0				;clear upper (junk) bits
	MOV		AL,Laser			;use shared variable to indicate current laser state
	CALL	SetLaser			;and output to laser
	POPA						;restore registers
	RET
LaserOut	ENDP

; SerialStringTable
;
; Description:      This is a table containing strings to be output to serial port 
;                   according to FSM actions
;
; Author:           Suzannah Osekowsky
; Last Modified:    Dec. 10, 2014
SerialStringTable	LABEL	BYTE
    DB  'LASER ON',ASCIInull        ;Increase angle of movement
    DB  'LASEROFF',ASCIInull        ;Decrease angle of movement
	
; StateTable
;
; Description:      This is and entry in the state transition table for the state machine.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Suzannah Osekowsky
; Last Modified:    Dec. 06, 2014

TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION1     DW      ?               ;first action for the transition
    ACTION2     DW      ?               ;second action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act1, act2))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act1), OFFSET(%act2) >
)


StateTable	LABEL	TRANSITION_ENTRY

	;Current State = ST_INITIAL                 Input Token Type
	%TRANSITION(ST_SPEED, doNOP, doNOP)			;TOKEN_SPEED
	%TRANSITION(ST_RELSPEED, doNOP, doNOP)		;TOKEN_RELSPEED
	%TRANSITION(ST_SETANGLE, doNOP, doNOP)		;TOKEN_SETANGLE
	%TRANSITION(ST_TURRETANG, doNOP, doNOP)		;TOKEN_TURRETANG
	%TRANSITION(ST_TURRETELEV, doNOP, doNOP)	;TOKEN_TURRETELEV
	%TRANSITION(ST_LASERON, laserOn, doNOP)		;TOKEN_LASERON
	%TRANSITION(ST_LASEROFF, laserOff, doNOP)	;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, clrVals, doNOP)		;TOKEN_EOS
	%TRANSITION(ST_INITIAL,doNOP,doNOP)			;TOKEN_NOACTION

	;Current State = ST_SPEED                   Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_SPEEDSIGN, setSign, doNOP)	;TOKEN_SIGN
	%TRANSITION(ST_SPEEDDIGIT, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_SPEED,doNOP,doNOP)			;TOKEN_NOACTION

	;Current State = ST_SPEEDSIGN               Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_SPEEDDIGIT, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_SPEEDSIGN,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_SPEEDDIGIT              Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_SPEEDDIGIT, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,speedOut,clrVals)	;TOKEN_EOS
	%TRANSITION(ST_SPEEDDIGIT,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_RELSPEED                Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_RELSPEEDSIGN, setSign, doNOP);TOKEN_SIGN
	%TRANSITION(ST_RELSPEEDDIG, newDigit, doNOP);TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_RELSPEED, doNOP, doNOP)		;TOKEN_NOACTION

	;Current State = ST_RELSPEEDSIGN            Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_RELSPEEDDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_RELSPEEDSIGN,doNOP,doNOP)	;TOKEN_NOACTION

	;Current State = ST_RELSPEEDDIG             Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_RELSPEEDDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,relSpeedOut,clrVals)	;TOKEN_EOS
	%TRANSITION(ST_RELSPEEDDIG,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_SETANGLE                Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_SETANGLESIGN, setSign, doNOP);TOKEN_SIGN
	%TRANSITION(ST_SETANGLEDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_SETANGLE,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_SETANGLESIGN            Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_SETANGLEDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_SETANGLESIGN,doNOP,doNOP)	;TOKEN_NOACTION

	;Current State = ST_SETANGLEDIG             Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_SETANGLEDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,angleOut,clrVals)	;TOKEN_EOS
	%TRANSITION(ST_SETANGLEDIG,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_TURRETANG               Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_TURRETANGSIG, setSign, doNOP);TOKEN_SIGN
	%TRANSITION(ST_TURRETANGDIG, newDigit,doNOP);TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_TURRETANG,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_TURRETANGSIG            Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_TURRETANGDIG, newDigit,doNOP);TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_TURRETANGSIG,doNOP,doNOP)	;TOKEN_NOACTION

	;Current State = ST_TURRETANGDIG            Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_TURRETANGDIG, newDigit,doNOP);TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,turretAngOut,clrVals);TOKEN_EOS
	%TRANSITION(ST_TURRETANGDIG,doNOP,doNOP)	;TOKEN_NOACTION

	;Current State = ST_TURRETELEV              Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_TURRETELSIGN, setSign, doNOP);TOKEN_SIGN
	%TRANSITION(ST_TURRETELDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_TURRETELEV,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_TURRETELSIGN            Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_TURRETELDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_EOS
	%TRANSITION(ST_TURRETELSIGN,doNOP,doNOP)	;TOKEN_NOACTION

	;Current State = ST_TURRETELDIG             Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_TURRETELDIG, newDigit,doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,turretElevOut,clrVals);TOKEN_EOS
	%TRANSITION(ST_TURRETELDIG,doNOP,doNOP)		;TOKEN_NOACTION

	;Current State = ST_LASERON		            Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,laserOut,clrVals)	;TOKEN_EOS
	%TRANSITION(ST_LASERON,doNOP,doNOP)			;TOKEN_NOACTION
	
	;Current State = ST_LASEROFF		        Input Token Type
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_RELSPEED
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SETANGLE
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETANG
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_TURRETELEV
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASERON
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_LASEROFF
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_SIGN
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL,laserOut,clrVals)	;TOKEN_EOS
	%TRANSITION(ST_LASEROFF,doNOP,doNOP)		;TOKEN_NOACTION

	

; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Author:           Suzannah Osekowsky
; Last Modified:    Nov. 30, 2014

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_OTHER, 0)		;<null> 
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_NOACTION, 0)	;TAB (no action)
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_EOS, 0)		;carriage return (end of signal)
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_NOACTION, 1)	;space (take no action)
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_SIGN, +1)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_SIGN, -1)		;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, 0)		;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)		;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)		;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)		;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)		;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)		;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)		;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)		;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)		;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_SETANGLE, 0)	;D	(set direction)
        %TABENT(TOKEN_TURRETELEV,0)	;E  (elevation angle)
        %TABENT(TOKEN_LASERON, 0)	;F	(fire laser)
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_LASEROFF, 0)	;O	(laser off)
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_SPEED, 0)		;S	(set speed)
        %TABENT(TOKEN_TURRETANG, 0)	;T	(set turret rotation)
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_RELSPEED, 0)	;V	(set relative speed)
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_SETANGLE, 0)	;d 	(set direction)
        %TABENT(TOKEN_TURRETELEV,0)	;e 	(elevation angle)
        %TABENT(TOKEN_LASERON, 0)	;f	(fire laser)
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_LASEROFF, 0)	;o	(laser off)
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_SPEED, 0)		;s 	(set speed)
        %TABENT(TOKEN_TURRETANG, 0)	;t	(set turret rotation)
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_RELSPEED, 0)	;v
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE


; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE
CODE	ENDS

DATA    SEGMENT PUBLIC  'DATA'	;shared variables for serial parsing functions
	CurrState	DB	?	;current state of FSM
	Laser		DB		?				;current intended laser status
	CmdVal		DW		?				;stores value transmitted
	ValSign		DB		?				;stores sign (if given) of transmission value
	ErrorStat	DW		?				;error state
	serialString	DB	SERIAL_SIZE	DUP(?)	;string to be output to serial port
DATA    ENDS

END
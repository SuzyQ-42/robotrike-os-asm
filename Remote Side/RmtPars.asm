	NAME	REMOTEPARSE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									RMTPARS.ASM											 ;
;					Serial parsing functions for the remote side						 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Functions for parsing serial characters passed to the remote side of the system. The 
;	functions included are:
;   RemoteInit: 		Initializes queue for remote-side main loop
;   EnqueueEvent:       Enqueues an event in the remote event queue
;	CheckForEvents:		blocking function that loops until queue is not empty
;   EventTypeTable:		Table of function calls for various event types
;   SerialError:     	Displays the string "SRLERROR" in response to an invalid character
;	DisplayStringTable:	Table of strings to be displayed by different functions
;	ParseInit:			initializes shared variables for use with other actions
;   ParseRemoteChar:    parse a serial input character
;   GetRmtToken: 		get an input token for the parser
; 	newDigit:			handles a new alphanumeric character input
;	clrVals:			prepares system to receive a new display string
;	doNOP:				idle state
;	error:				generates a parsing error
;	numOut:				outputs number-associated message to screen
;	laserOn:			sets laser on
;	laserOff:			sets laser off
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

CGROUP	GROUP	CODE

CODE    SEGMENT PUBLIC  'CODE'
    ASSUME  CS:CGROUP, DS:DATA

;local include files
$INCLUDE(RMTPARS.INC)	;constants for token types and state order
$INCLUDE(RMTMAIN.INC)   ;constants for display table
$INCLUDE(MOTOR.INC)		;constants for use when calling motor functions
$INCLUDE(QUEUE.INC)     ;important stuff for defining queues
$INCLUDE(ASCII.INC)     ;stuff for writing ASCII characters

;external function declarations
    EXTRN   Display:NEAR            ;displays a string of ASCII characters
	EXTRN	SetMotorSpeed:NEAR		;takes arguments of robotrike speed and direction and 
									;	moves them to shared variables.
	EXTRN	GetMotorSpeed:NEAR		;finds current intended robotrike speed
	EXTRN	GetMotorDirection:NEAR	;finds current intended robotrike movement angle
	EXTRN	SetLaser:NEAR			;receives a signal and outputs a value (on or off) to 
									;	the laser
	EXTRN	SetTurretAngle:NEAR		;outputs absolute rotation of turret to turret motor
	EXTRN	SetRelTurretAngle:NEAR	;outputs relative rotation of turret to turret motor
	EXTRN	SetTurretElevation:NEAR	;outputs absolute angle of elevation of turret
    EXTRN   QueueInit:NEAR          ;initializes a queue
    EXTRN   Enqueue:NEAR            ;enqueues a value in a queue
    EXTRN   Dequeue:NEAR            ;removes a value from a queue
    EXTRN   KeyPressEvent:NEAR      ;what to run if a key is pressed
    EXTRN   QueueEmpty:NEAR         ;checks if queue at passed address is empty
    
; RemoteInit
;
; Description:		Initializes the event queue by setting up relevant variables and 
;					calling an external function.
;
; Operation:		Calls the external function QueueInit with the address of the queue,
;					the desired number of entries in the queue, and the size of each entry
;					(byte or word). QueueInit then initializes shared variables for use 
;					with other generalized queue-related functions.
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
; Stack Depth:      1 word.
;
; Algorithms:		None
; Data Structures:	EventQueue - holds events to be dequeued by remote-side main loop
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 14, 2014
RemoteInit		PROC	NEAR
				PUBLIC	RemoteInit
	MOV		AX,RMT_QUEUE_LENGTH		;RMT_QUEUE_LENGTH elements in the queue
	MOV		BL,WORD_QUEUE			;word-size elements
	LEA		SI,EventQueue			;load address before calling QueueInit
	
	CALL 	QueueInit 				;initialize a word queue at address RMTQUEUE_ADDRESS 
									;	with RMTQUEUE_LENGTH entries
	RET
RemoteInit		ENDP


; EnqueueEvent
;
; Description:		Enqueues a value into the event buffer, which handles remote-side 
;					events.
;
; Operation:		Gets the address of the event buffer and calls an external (queue)
;					function to enqueue a passed value.
;
; Arguments:		AX - value to be enqueued (high bits indicate event type, low indicate
;						 an associated value)
; Return Values:	None.
;
; Local Variables:	SI - address of event queue
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	Enqueues error events.
;
; Registers Used:   AX (read), SI(changed)
; Stack Depth:      10 words
;
; Algorithms:		None.
; Data Structures:	Queue structure
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
EnqueueEvent	PROC	NEAR
				PUBLIC	EnqueueEvent
	LEA		SI,EventQueue       			;get address of event queue
	CALL 	Enqueue							;enqueue the value passed in the event queue
	RET
EnqueueEvent	ENDP

; CheckForEvents
;
; Description:		Blocking function that returns when event queue is no longer empty
;
; Operation:		Gets the address of the event queue and checks if it's empty; if so,
;                   loops until is isn't; if not, returns.
;
; Arguments:		None.
; Return Values:	SI - address fo event queue
;
; Local Variables:	SI - address of event queue
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	Enqueues error events.
;
; Registers Used:   AX (read), SI(changed)
; Stack Depth:      10 words
;
; Algorithms:		None.
; Data Structures:	Queue structure
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
CheckForEvents  PROC    NEAR
                PUBLIC  CheckForEvents
 LoopUntilNotEmpty:
    LEA		SI,EventQueue						;load address of event queue into register
	CALL	QueueEmpty							;check if queue is empty
	JZ		LoopUntilNotEmpty       			;keep looping if queue is empty
    RET
CheckForEvents  ENDP

; EventTypeTable
;
; Description:      This is a call table for use with event queue. Each event type gets
;					a row and a function call.
;
; Author:           Suzannah Osekowsky
; Last Modified:    Dec. 06, 2014
EventTypeTable	LABEL	WORD
				PUBLIC	EventTypeTable
;	DW		OFFSET(function)
	DW		OFFSET(KeyPressEvent)	;a key has been pressed
	DW		OFFSET(SerialError)		;a serial parser error has been generated
	DW		OFFSET(ParseRemoteChar)	;received data from the serial port
	
	
; SerialError
;
; Description:		Expects to be called in case of a serial parsing error; outputs string
;					"SRLERROR" to the display.
;
; Operation:		Sets ES:SI to the address of the string "SRLERROR<null>" and calls the 
;					display function.
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
; Error Handling:	Displays "SRLERROR" in response to a serial error
;
; Registers Used:   AX,SI (both changed)
; Stack Depth:      1 word
;
; Algorithms:		None.
; Data Structures:	Display queue
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 14, 2014
SerialError		PROC	NEAR
				PUBLIC	SerialError
	MOV		SI,SRL_ERR_INDEX		    ;set ASCII string to be displayed to SRLERROR
	IMUL    SI,DISPLAY_ENTRY_SIZE   
    ADD     SI,OFFSET(DisplayStringTable)
    MOV     AX,CS                       ;read from code segment
    MOV     ES,AX
	CALL	Display						;and display the string
	RET
SerialError		ENDP

; DisplayStringTable
;
; Description:      This is a table containing strings to be displayed according to key
;                   presses. I know it's really small but it's still easier than 
;                   hard-coding the strings.
;
; Author:           Suzannah Osekowsky
; Last Modified:    Dec. 10, 2014

DisplayStringTable	LABEL	BYTE
                    PUBLIC  DisplayStringTable
    DB  'LASER ON',ASCIInull    ;"LASER ON"
    DB  'LASEROFF',ASCIInull    ;"LASEROFF"
    DB  'SRLERROR',ASCIInull    ;"SRLERROR"
    DB  'STOP IT ',ASCIInull    ;"STOP IT"


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
; Shared Variables: displayIndex - holds current index to which display is writing
;					ErrorStat - current error status of the system
;					CurrState - indicates which state the FSM is currently in
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   BX (changed)
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
ParseInit	PROC	NEAR
			PUBLIC	ParseInit
	MOV     displayIndex,0		        ;clear index
    MOV     CurrState,ST_INITIAL        ;start parsing FSM at initial state
    MOV     ErrorStat,NO_ERROR          ;no parsing errors yet
    MOV     BX,0                        ;clear temporary index
ClearStringLoop:
    MOV     displayString[BX],ASCIInull ;clear entries
    INC     BX                          ;next entry
    CMP     BX,DISPLAY_SIZE             ;unless at max value
    JNE     ClearStringLoop             ;loop until at maximum location
	RET							        ;done when at maximum location
ParseInit	ENDP

; ParseRemoteChar
;
; Description:		Accepts a serial (ASCII) character passed in AL, and uses external 
;					table lookups to translate that character into a state change for the 
;					serial parsing state machine. Returns PARSING_ERROR if the character 
;					creates a parsing error, and returns zero otherwise. Really all the
;					functions do is display any alphanumeric characters passed.
;
; Operation:		Uses a table to get the token type and value associated with the 
;					passed character, then uses a state machine table to find the actions
;					and state transition associated with that character and the current 
;					state of the state machine. It then performs those actions (external
;					functions) and returns the error status. Really all the
;					functions do is display any alphanumeric characters passed.
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

ParseRemoteChar		PROC    NEAR
					PUBLIC  ParseRemoteChar	
DoNextToken:				;get next input for state machine
	CALL	GetRmtToken		;and get the token type and value (character is in AL)
	MOV		DH,AH			;and save token type in DH and token value in CH
	MOV		CH,AL
	
ComputeTransition:				;figure out what transition to do
	MOV		AL,NUM_TOKEN_TYPES	;find row in table
	MOV		CL,CurrState		;AL = NUM_TOKEN_TYPES * CurrState + TOKEN_TYPE
	MUL		CL					;looks up correct table row
	ADD 	AL, DH				;get actual transition
	MOV		AH, 0				;propagate low byte carry into high byte
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

EndParseRemote:				;done parsing serial character, return with nothing
	MOV	AX,CX				;outputs error status
	
    RET
ParseRemoteChar		ENDP

; GetRmtToken
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
GetRmtToken	PROC    NEAR
			PUBLIC	GetRmtToken

InitGetRmtToken:				;setup for lookups
	AND		AL,TOKEN_MASK		;strip unused bits (high bit) and preserve value in AH
	MOV		AH,AL		

TokenTypeLookup:                        ;get the token type
    MOV		BX,OFFSET(TokenTypeTable)  	;BX points at table
	XLAT	CS:TokenTypeTable			;have token type in AL
	XCHG	AH, AL						;token type in AH, character in AL

TokenValueLookup:							;get the token value
    MOV		BX,OFFSET(TokenValueTable)  	;BX points at table
    XLAT	CS:TokenValueTable				;have token value in AL

EndGetRmtToken:                     	;done looking up type and value
    RET

GetRmtToken	ENDP
	
; newDigit
;
; Description:		Stores a new character in the display string buffer.
;
; Operation:		Stores a new character in the indexed loccation in the display string 
;					buffer.
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
; Stack Depth:      2 words
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
	PUSHA       						;might as well save registers
AddNewDigit:
    XOR     BX,BX                       ;clear BX so it's all nice and empty
    MOV     BL,displayIndex             ;use as index
	MOV		displayString[BX],AL	    ;store passed character in indexed buffer 
										;	location
    INC     BX
    MOV     displayIndex,BL             ;update string pointer
newDigitDone:
	POPA            					;restore registers							
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
; Shared Variables: displayIndex - used to index entries into the display buffer
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
	MOV		displayIndex,0	;clear digit index (start writing at first digit)
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
; Operation:		Enqueues a parsing error in the main event queue.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None yet.
;
; Error Handling:	Generates error state
;
; Registers Used:   None.
; Stack Depth:      9 words
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
    PUSHA                           ;save registers
	MOV		AX,PARSING_ERROR		;enqueues a parsing error
	CALL	EnqueueEvent
    POPA                            ;restore registers
	RET
error	ENDP


; numOut
;
; Description:		Outputs the current serial argument to the motor speed set function,
;					which turns that value into individual speeds for each motor according
;					to equations of holonomic motion. 
;
; Operation:		Sets the direction argument to maintain whatever it's currently doing,
;					and updates the speed variable to match the current argument. Then 
;					calls the external function SetMotorSpeed. We don't need to do any 
;					overflow/underflow checks because the passed value can't exceed the 
;					maximum speed value.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: CmdVal - abs. value of current argument being handled
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	None.
;
; Registers Used:   AX, BX (changed and restored)
; Stack Depth:      11 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
numOut		PROC	NEAR
			PUBLIC	numOut
    PUSHA                       ;save registers
    XOR BX,BX                   ;clear upper bits
    MOV BL,displayIndex         ;add null termination
    MOV displayString[BX],ASCIInull
    MOV AX,DS                   ;read from data segment
    MOV ES,AX
	LEA	SI,displayString		;value is already in display variable, just call function
	CALL Display				;	to display it
    POPA                        ;restore registers
	RET
numOut		ENDP



; LaserOn
;
; Description:		Loads message indicating laser is on, calls display buffer, returns.
;
; Operation:		Loads message indicating laser is on, calls display buffer, returns.
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
; Data Structures:	displayString - buffer holding string to be displayed
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
LaserOn	PROC	NEAR
		PUBLIC	LaserOn
    PUSHA                               ;save registers
    MOV     SI,ON_INDEX           		;load message indicating laser is on
    IMUL    SI,DISPLAY_ENTRY_SIZE
	ADD		SI,OFFSET(DisplayStringTable)
    MOV     AX,CS                       ;display a string stored in code segment
    MOV     ES,AX
	CALL	Display						;display message
    POPA                                ;restore registers
	RET
LaserOn	ENDP

; LaserOff
;
; Description:		Loads message indicating laser is off, calls display buffer, returns.
;
; Operation:		Loads message indicating laser is off, calls display buffer, returns.
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
; Data Structures:	displayString - buffer holding string to be displayed
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 6, 2014
LaserOff	PROC	NEAR
		PUBLIC	LaserOff
    PUSHA                               ;save registers
	MOV     SI,OFF_INDEX                ;load message indicating laser is off
    IMUL    SI,DISPLAY_ENTRY_SIZE
	ADD		SI,OFFSET(DisplayStringTable)
    MOV     AX,CS                       ;display a string stored in code segment
    MOV     ES,AX
	CALL	Display						;display message
    POPA                                ;restore registers
	RET
LaserOff	ENDP

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
	%TRANSITION(ST_GETNUMDIG, newDigit, doNOP)	;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, clrVals, doNOP)		;TOKEN_EOS
	%TRANSITION(ST_INITIAL,doNOP,doNOP)			;TOKEN_NOACTION

	;Current State = ST_GETNUMDIG              	Input Token Type
	%TRANSITION(ST_GETNUMDIG, newDigit, doNOP)  ;TOKEN_DIGIT
	%TRANSITION(ST_INITIAL, error, clrVals)		;TOKEN_OTHER
	%TRANSITION(ST_INITIAL, numOut, clrVals)	;TOKEN_EOS
	%TRANSITION(ST_GETNUMDIG, doNOP, doNOP)		;TOKEN_NOACTION

	

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
        %TABENT(TOKEN_OTHER, '+')	;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_OTHER, '-')	;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, '0')	;0  (digit)
        %TABENT(TOKEN_DIGIT, '1')	;1  (digit)
        %TABENT(TOKEN_DIGIT, '2')	;2  (digit)
        %TABENT(TOKEN_DIGIT, '3')	;3  (digit)
        %TABENT(TOKEN_DIGIT, '4')	;4  (digit)
        %TABENT(TOKEN_DIGIT, '5')	;5  (digit)
        %TABENT(TOKEN_DIGIT, '6')	;6  (digit)
        %TABENT(TOKEN_DIGIT, '7')	;7  (digit)
        %TABENT(TOKEN_DIGIT, '8')	;8  (digit)
        %TABENT(TOKEN_DIGIT, '9')	;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_DIGIT, 'A')	;A
        %TABENT(TOKEN_DIGIT, 'B')	;B
        %TABENT(TOKEN_DIGIT, 'C')	;C
        %TABENT(TOKEN_DIGIT, 'D')	;D	(set direction)
        %TABENT(TOKEN_DIGIT, 'E')	;E  (elevation angle)
        %TABENT(TOKEN_DIGIT, 'F')	;F	(fire laser)
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_DIGIT, 'H')	;H
        %TABENT(TOKEN_DIGIT, 'I')	;I
        %TABENT(TOKEN_DIGIT, 'J')	;J
        %TABENT(TOKEN_DIGIT, 'K')	;K
        %TABENT(TOKEN_DIGIT, 'L')	;L
        %TABENT(TOKEN_DIGIT, 'M')	;M
        %TABENT(TOKEN_DIGIT, 'N')	;N
        %TABENT(TOKEN_DIGIT, 'O')	;O	(laser off)
        %TABENT(TOKEN_DIGIT, 'P')	;P
        %TABENT(TOKEN_DIGIT, 'Q')	;Q
        %TABENT(TOKEN_DIGIT, 'R')	;R
        %TABENT(TOKEN_DIGIT, 'S')	;S	(set speed)
        %TABENT(TOKEN_DIGIT, 'T')	;T	(set turret rotation)
        %TABENT(TOKEN_DIGIT, 'U')	;U
        %TABENT(TOKEN_DIGIT, 'V')	;V	(set relative speed)
        %TABENT(TOKEN_DIGIT, 'W')	;W
        %TABENT(TOKEN_DIGIT, 'X')	;X
        %TABENT(TOKEN_DIGIT, 'Y')	;Y
        %TABENT(TOKEN_DIGIT, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_DIGIT, 'a')	;a
        %TABENT(TOKEN_DIGIT, 'b')	;b
        %TABENT(TOKEN_DIGIT, 'c')	;c
        %TABENT(TOKEN_DIGIT, 'D')	;d 	(set direction)
        %TABENT(TOKEN_DIGIT,0)		;e 	(elevation angle)
        %TABENT(TOKEN_DIGIT, 'F')	;f	(fire laser)
        %TABENT(TOKEN_DIGIT, 'g')	;g
        %TABENT(TOKEN_DIGIT, 'h')	;h
        %TABENT(TOKEN_DIGIT, 'i')	;i
        %TABENT(TOKEN_DIGIT, 'j')	;j
        %TABENT(TOKEN_DIGIT, 'k')	;k
        %TABENT(TOKEN_DIGIT, 'l')	;l
        %TABENT(TOKEN_DIGIT, 'm')	;m
        %TABENT(TOKEN_DIGIT, 'n')	;n
        %TABENT(TOKEN_DIGIT, 'O')	;o	(laser off)
        %TABENT(TOKEN_DIGIT, 'p')	;p
        %TABENT(TOKEN_DIGIT, 'q')	;q
        %TABENT(TOKEN_DIGIT, 'r')	;r
        %TABENT(TOKEN_DIGIT, 'S')	;s 	(set speed)
        %TABENT(TOKEN_DIGIT, 't')	;t	(set turret rotation)
        %TABENT(TOKEN_DIGIT, 'u')	;u
        %TABENT(TOKEN_DIGIT, 'v')	;v (set relative speed)
        %TABENT(TOKEN_DIGIT, 'w')	;w
        %TABENT(TOKEN_DIGIT, 'x')	;x
        %TABENT(TOKEN_DIGIT, 'y')	;y
        %TABENT(TOKEN_DIGIT, 'z')	;z
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
    EventQueue	    QUEUE<>						;creates a queue for storing actions
	CurrState		DB		?					;current state of FSM
    ErrorStat       DW      ?                   ;current error status of FSM
	displayString	DB	DISPLAY_SIZE	DUP(?)	;string to be output to display
	displayIndex	DB		?					;index to display string buffer
DATA    ENDS

END
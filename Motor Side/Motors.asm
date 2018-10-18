NAME	MOTORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;						 			MOTORS.ASM											 ;
;				Functions for assigning and determining motor state						 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Contains functions that assign and determine motor state for the robotrike
;	MotorInit				initializes motor variables
;	PWMFunc					outputs intended speed of each individual motor, laser status
;	SetMotorSpeed			takes arguments of robotrike speed and direction and moves 
;								them to shared variables.
;	GetMotorSpeed			finds current intended robotrike speed
;	GetMotorDirection		finds current intended robotrike movement angle
;	SetLaser				receives a signal and outputs a value (on or off) to the laser
;	GetLaser				returns current intended state of laser
;
; Revision History:	11/14/2014	Suzannah Osekowsky	initial revision
;					11/18/2014	Suzannah Osekowsky	modified constants, created arrays
;					11/20/2014	Suzannah Osekowsky	debugged
;					11/21/2014	Suzannah Osekowsky	updated comments
;					12/14/2014	Suzannah Osekowsky	updated comments

CGROUP	GROUP	CODE

CODE    SEGMENT PUBLIC  'CODE'
    ASSUME  CS:CGROUP, DS:DATA
    
;local include files
$INCLUDE(Motor.inc)	    			;constants for running motor code
    
;external function, table declarations
	EXTRN	MtrXFactorTable:WORD	;values to multiply by X-component of speed in motors
	EXTRN	MtrYFactorTable:WORD	;values to multiply by Y-component of speed in motors
	EXTRN	MtrFwdTable:BYTE		;values for moving each motor forward
	EXTRN	MtrReverseTable:BYTE	;values for moving each motor backward
	EXTRN	Sin_Table:WORD			;table of sine values for 0-360 degrees
	EXTRN	Cos_Table:WORD 			;table of cosine values for 0-360 degrees

; MotorInit
;
; Description:		Clears shared variables and arrays for use with functions pertaining 
;					to motor mutators and accessors. Writes a control word to the parallel
;					output control chip that initialized the parallel output.		
;
; Operation:		sets all variables to zero, sets parallel control register to mode
;					zero, fills motor value and PWM count arrays with zeroes.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	BX - index used to clear motors individually (goes from 0-MOTOR_NUM)
; Shared Variables: FullSpeed - user input speed (cleared)
;					Speed - current fractional robotrike speed (cleared)
;					Angle - current intended robotrike direction (cleared)
;					Laser - current intended laser status (cleared)
;					PWMCnt - PWM counter index (cleared)
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX,BX,DX, flags
; Stack Depth:      0 words
;
; Algorithms:		Clearing an array element, incrementing index, clearing next element 
;					until on last element.
; Data Structures:	MtrDirArray - array containing +/- directions for motors
;					PWMCntArray - array containing PWM values for each motor
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 21, 2014
MotorInit	PROC		NEAR
			PUBLIC      MotorInit
ClearVariables:
	MOV		FullSpeed,0			;clear user-input robotrike speed
	MOV		Speed,0				;clear current intended robotrike speed
	MOV		Angle,0				;clear current intended robotrike direction
	MOV		Laser,0				;clear current intended laser status
	MOV		PWMCnt,0			;clear PWM counter index
	;JMP	WriteParallelCtrl
WriteParallelCtrl:
	MOV		DX,ParallelCtrl 	;set output control register value to 12 bits input, 8 
	MOV		AL,PARALLEL_CTRL_VAL; bits output, with no handshaking
	OUT		DX,AL
	MOV		BX,0				;prepare to clear arrays
	;JMP	ClearCounts	
ClearCounts:
	MOV		PWMCntArray[BX],0 	;clears this entry 
	INC		BX					;increment digit index
	CMP		BX,MOTOR_NUM		;checks if index is at maximum value
	JNE		ClearCounts			;if not, repeat until buffer is clear
	MOV		BX,0				;if so, clear index 
;	JMP		ClearMtrVals		;	and move on to clear motor value array
ClearMtrVals:
	MOV		MtrDirArray[BX],0 	;clears this entry in motor value array
	INC		BX					;increment digit index
	CMP		BX,MOTOR_NUM		;checks if index is at maximum value
	JNE		ClearMtrVals		;if not, repeat until buffer is clear
;	JMP		MtrInitDone			;if so, stop writing values
MtrInitDone:
	RET
MotorInit	ENDP	

; PWMFunc
;
; Description:		Turns motors on and off (and forward/backward) according to PWM 
;					values, turns laser on and off according to user-set value. This 
;					function expects to be called by a timer event handler a few hundred 
;					times per second.
;
; Operation:		Clears a register, then proceeds to check whether, according to the 
;					the current PWM count and the PWM value for each motor, that motor 
;					should be on. If so, it checks whether (according to the direction 
;					stored in the motor direction array)it should be going forward or 
;					backward, then adds the corresponding bit(s) into the previously 
;					cleared register. Once it's finished updating the motors, it checks 
;					whether the laser should be on or off and updates output to include 
;					that value. The function then outputs output register to the motor 
;					controller chip. It increments the PWM count and waits to be called 
;					again.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	BX - used as motor index until have updated all motor values
; Shared Variables: PWMCnt - 7-bit counter that tracks how many times this function has
;							 been called (changed)
;					Laser - current status of laser (read)
; Global Variables: None.
;
; Input:            None.
; Output:			On/off pulse width modulated signals to motors, on/off signal to laser
;
; Error Handling:	None.
;
; Registers Used:   AX,BX,CX,DX,SI,flags
; Stack Depth:      0 words
;
; Algorithms:		For each motor, loads current PWM value, checks if the current count 
;					is greater than that value, and if not, moves the motor, then updates
;					index and does the next motor.
; Data Structures:	MtrDirArray - array containing +/- directions for motors
;					PWMCntArray - array containing PWM values for each motor
;
; Known Bugs:		None.
; Limitations:		Speeds that necessitate a duty cycle output of less than 1 percent 
;					will be represented with a zero duty cycle.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 21, 2014
PWMFunc		PROC	NEAR
			PUBLIC  PWMFunc
PWMInit:
	XOR		AX,AX	;clear AX for output to motor port
	MOV		BX,0	;start writing values at port A
	;JMP	MotorUpdate
MotorUpdate:
    MOV CL,PWMCntArray[BX]          ;load current speed magnitude
    MOV DL,PWMCnt                   ;and current PWM count
	CMP	DL,CL                  	 	;if still within the correct speed magnitude,
	JGE	NextMotor					; (else this motor stays at zero, update next motor)
	CMP	MtrDirArray[BX],POS_SIGN    ;and if motor is supposed to be moving backward,
	JE	MotorFwd
	MOV	SI,OFFSET(MtrReverseTable)	;get value for backward movement
	ADD	SI,BX						; for this particular motor
	MOV	CL,CS:[SI]					; from the table in a separate table file
	OR	AL,CL						;set value so motor is moving in reverse
	JMP	NextMotor					;and go to update next motor
MotorFwd:							;else if motor is supposed to be moving forward
	MOV	SI,OFFSET(MtrFwdTable)		;get value for forward movement
	ADD	SI,BX						; for this particular motor
	MOV	CL,CS:[SI]					; from the table in a separate table file
	OR	AL,CL						;set value so motor is moving forward
	;JMP	Motor2Update			;and go to update next motor
NextMotor:
	INC	BX							;increment motor index (update next motor)
	CMP	BX,MOTOR_NUM				;check if writing to last motor
	JNE	MotorUpdate					; if not, go update the next motor
	;JMP	LaserUpdate				;else, update laser
LaserUpdate:
	CMP	Laser, LASER_OFF			;if laser is off
	JE	ParallelOutput				;output without changing laser bit
	OR	AL,LASER_ON					;else, set value so laser is on
	;JMP	ParallelOutput			;	and output all values
ParallelOutput:	
	MOV		DX,ParallelPortB		;output motor values to motor port
	OUT 	DX,AL					
	MOV		AL,PWMCnt				;increment counter (can't do this in memory because 
    ADD     AL,1					;	PWMCnt is a byte value)
    MOV     PWMCnt,AL
	CMP		PWMCnt,MAX_PWM_CNT		;and check if it's reached its maximum
	JNE		PWMDone					;if not, done so return
	MOV		PWMCnt,0				;else, loop PWM counter (start from 0)
PWMDone:
	RET								;done, return
PWMFunc		ENDP 

; SetMotorSpeed
;
; Description:		Gets a speed and direction input by the user, and outputs values  
;					indicative of holonomic motion to PWM value and direction arrays. 
;					These arrays expect to be accessed by a timer event handler to output 
;					speed/direction to motors. 
;
; Operation:		Updates shared variables to indicate correct speed and direction, then
;					uses equations of holonomic motion and fixed-point arithmetic to 
;					generate a PWM value and direction for each motor, then stores those 
;					values in their respective arrays. The PWM values are generated 
;					according to the equation V_i = (x-factor)_i * cos(angle) * speed
;					+ (y-factor)_i * cos(angle) * speed. The arrays are then used as 
;					counters for the timer-based PWM output.
;
; Arguments:		AX - speed at which user wished robotrike to move (0-65534)
;					BX - direction in degrees at which user wished robotrike to move 
;						 (-32767 - 32767)
; Return Values:	None.
;
; Local Variables:	CX - motor index for motor update loop
; Shared Variables: FullSpeed - user input speed
;					Speed - current fractional robotrike speed
;					Angle - current intended robotrike direction
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX, BX, CD, DX, SI, flags (all saved and restored when function done)
; Stack Depth:      9 words
;
; Algorithms:		Equations of holonomic motion: V_i = (x-factor)_i * cos(angle) * speed
;					+ (y-factor)_i * cos(angle) * speed
;					These equations are applied to each motor in sequence and the sign and
;					absolute value of each result is stored in the appropriate array.
; Data Structures:	MtrDirArray - array containing +/- directions for motors
;					PWMCntArray - array containing PWM values for each motor
;
; Known Bugs:		None.
; Limitations:		Speeds that necessitate a duty cycle output of less than 1 percent 
;					will be represented with a zero duty cycle.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 21, 2014
SetMotorSpeed	PROC	NEAR
				PUBLIC	SetMotorSpeed
BeginSetSpeed:
    PUSHA                   ;save registers
CheckSpeed:
	CMP		AX,SAME_SPEED	;checks if instruction is to stay the same speed
	JE		CheckAngle		;if it is, do not change speed; check if you should change the
							;	angle
    MOV     FullSpeed,AX    ;store user-set speed value
    SHR     AX,NORM_SPEED   ;normalize speed variable to 0-1
	MOV		Speed,AX		;else, update speed variable
	;JMP	CheckAngle		;if so, do not change speed signal; check angle
CheckAngle:
	CMP		BX,SAME_ANGLE			;checks if instruction is to maintain the same angle
    JE      InitMotorLoop           ; if so, don't update angle variable, go update motors
	;JMP	UpdateAngle				;else, change angle variable
UpdateAngle:
	MOV		AX,BX					;put angle value into working register
    CWD                             ;modulo by FULL_ANGLE_FACTOR in order to get the
    MOV     BX,FULL_ANGLE_FACTOR    ;    effective desired angle
    IDIV    BX                		;reduce angle to an angle in +/- 180 degrees
	CMP		DX,0 					;check if the angle is negative
	JL		AngleNeg				;if so, go subtract angle from FULL_ANGLE_OFFSET
	MOV		Angle,DX				;and updates angle variable
	JMP		InitMotorLoop			;done, go to get values for each motor
AngleNeg:
	ADD		DX,FULL_ANGLE_OFFSET	;convert values -180 to 180 to 0-360
	MOV		Angle,DX				;store in shared variable
	;JMP	InitMotorLoop			;done; continue to find motor speeds
InitMotorLoop:
    MOV		CX,0				    	;clear to use as an index for motor speed loop    
GetMotorXVal:
	MOV 	AX,CX                       ;multiply motor index by word length factor to get 
    MOV     BX,WORDLENGTH               ;   the correct (word) offset in the x factors
    MUL     BX                          ;   table
    MOV		SI,OFFSET(MtrXFactorTable)	;get x factor for motion
    ADD     SI,AX                       ;by using the word offset to look up the value
	MOV		AX,CS:[SI]					;and put it in our working register
	MOV		BX,Speed					;get current speed value
	IMUL	BX							;and multiply it by the (fractional) x factor
	MOV		AX,DX						;work only with DX amount
	MOV		SI,OFFSET(Cos_Table)		;get cosine value for current angle
    MOV     BX,Angle                    ; (angle given between 0 and 360)
    IMUL    BX,WORDLENGTH               ; multiply by word length to get correct word 
	ADD		SI,BX   					;	offset from table of cosine values
	MOV		BX,CS:[SI]					
	IMUL	BX							;and multiply working value by that value
	SHL		DX,EXTRA_SIGN_BITS			;get rid of extra sign bits by shifting them out
	SAR		DX,PWMCNT_OFFSET			;use only 15-PWMCNT_OFFSET bits for PWM counter
	PUSH    DX				        	;store the current result so it can be added to 
										; the y-component shortly
	;JMP	GetMotorYVal				;get the y-component of motion
GetMotorYVal:
	MOV 	AX,CX                       ;multiply motor index by word length factor to get 
    MOV     BX,WORDLENGTH               ;   the correct (word) offset in the y factors
    MUL     BX                          ;   table
    MOV		SI,OFFSET(MtrYFactorTable)	;get y factor for motion
    ADD     SI,AX                       ;by using the word offset to look up the value
	MOV		AX,CS:[SI]					;and put it in our working register
	MOV		BX,Speed					;get current speed value
	IMUL	BX							;and multiply it by the (fractional) y factor
	MOV		AX,DX						;work only with DX amount
	MOV		SI,OFFSET(Sin_Table)		;get sine value for current angle
    MOV     BX,Angle                    ; (angle given between 0 and 360)
    IMUL    BX,WORDLENGTH               ; multiply by word length to get correct word
    ADD     SI,BX                       ; offset from table of sine values
	MOV		BX,CS:[SI]					
	IMUL	BX							;and multiply working value by that value
	SHL		DX,EXTRA_SIGN_BITS			;get rid of extra sign bits by shifting them out
	SAR		DX,PWMCNT_OFFSET			;use only 15-PWMCNT_OFFSET bits for PWM counter
    MOV     AX,DX                       ;prepare to POP x-component and add
	;JMP	AddComponents				;finish calculating value
AddComponents:
	POP		DX      					;get the x-component of the motor's movement
	ADD		AX,DX						;add x- and y-components
    MOV     SI,CX                       ;(use a register that can be used as an address)
	CMP		AX,0						;check if negative
	JL		StoreNeg					;if so, store negative sign
	MOV		MtrDirArray[SI],POS_SIGN	;else, store positive indicator
	JMP		StorePWMVal					;go to shift result and store
StoreNeg:
	MOV		MtrDirArray[SI],NEG_SIGN	;add NEG_SIGN to direction array.
	NEG		AX							;get abs.value of AX to store in PWM Count array
	;JMP	StorePWMVal
StorePWMVal:
	MOV		PWMCntArray[SI],AL			;add abs. value of motor speed to PWM counter 
										;	array (use lower bits b/c using 8-bit counter)
GoToNextMotor:
	INC		CX							;increment motor index
	CMP		CX,MOTOR_NUM				;check if at last value
    JGE 	MotorSpeedDone				;if at last motor, done and return
	JMP		GetMotorXVal				;if not yet at last motor, loop and get next motor
MotorSpeedDone:
    POPA                                ;restore registers
	RET 								;done so return			
SetMotorSpeed	ENDP


;GetMotorSpeed
;
;Description:		Gets motor speed, returns it
;Operation:			Checks shared variable and returns its value
;
; Arguments:		None
; Return Value:		AX - Current speed setting for RoboTrike
;
; Local Variables:	None
; Shared Variables:	FullSpeed - user-input intended speed
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
; Last Modified:    11/14/2014
GetMotorSpeed	PROC	NEAR
				PUBLIC  GetMotorSpeed
MOV	AX,FullSpeed	;return user-input speed of motors
RET
GetMotorSpeed	ENDP

;GetMotorDirection
;
;Description:		Gets robotrike angle, returns it
;Operation:			Checks shared variable and returns its value	
;
; Arguments:		None
; Return Value:		AX - intended direction of robotrike motion (0-359 degrees)
;
; Local Variables:	None
; Shared Variables:	Angle - user-input intended angle normalized to 0-359 degrees
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
; Last Modified:    11/14/2014
GetMotorDirection	PROC	NEAR
					PUBLIC  GetMotorDirection
MOV	AX,Angle		;return intended direction of robotrike motion
RET				
GetMotorDirection	ENDP

;SetLaser
;
;Description:		Sets laser to fire or not fire, depending on how the user sets it.
;					A nonzero value indicates the laser should be on, and a zero value 
;					indicates the laser should be off.
;Operation:			Updates shared variable to zero/nonzero value depending on whether the
;					argument is zero or nonzero
;
; Arguments:		AX - current status of laser. A nonzero value indicates laser is 
;						 turned on and a nonzero value indicates laser is turned off.
; Return Value:		None
;
; Local Variables:	None
; Shared Variables:	Laser - current intended laser status
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
; Registers Used:	AX,flags
; Stack Depth:		0 words
;
; Author:           Suzannah Osekowsky
; Last Modified:    11/14/2014
SetLaser	PROC	NEAR
			PUBLIC  SetLaser
    CMP     AX,LASER_OFF ;check if laser is off
    JE      LaserSet    ;if so, val is already zero; go ahead and store
    ;JMP    LaserOn     ;else, set laser on
LaserOn:
    MOV AL,LASER_ON     ;sets laser on (in case register is nonzero only in upper bits)
    ;JMP    LaserSet    ;go to change shared variable
LaserSet:
    MOV	Laser,AL    	;sets laser variable to current status
    RET				    ;done, return
SetLaser	ENDP

;GetLaser
;
;Description:		Gets laser value, returns it
;Operation:			Checks shared variable and returns its value	
;
; Arguments:		None
; Return Value:		AL - Laser on/off value
;
; Local Variables:	None
; Shared Variables:	Laser - intended value of laser (0 indicates off, else indicates on)
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
; Last Modified:    11/14/2014
GetLaser	PROC	NEAR
			PUBLIC  GetLaser
	MOV AH,0            ;clears upper junk bits of unintended stuff
	MOV	AL,Laser		;returns laser value
	RET
GetLaser	ENDP
	
CODE	ENDS

DATA    SEGMENT PUBLIC  'DATA'	;shared variables for motor control functions
    FullSpeed   DW      ?               ;user input speed
	Speed		DW		?				;current fractional robotrike speed
	Angle		DW		?				;current intended robotrike direction
	Laser		DB		?				;current intended laser status
	PWMCnt		DB	    ?				;PWM counter index
	PWMCntArray	DB	MOTOR_NUM	DUP(?)	;PWM counter index array (amount of time each 
										;	motor is on)
	MtrDirArray	DB	MOTOR_NUM	DUP(?)	;motor speed array, stores motor speed values
DATA    ENDS

END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									MOTORS.INC											 ;
;						Constants for setting motor speed								 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains constants for setting status of each individual motor based on a 
;	user-given speed and direction
;
;	Revision History:
;		

	SAME_SPEED	EQU	0FFFFH		;used to maintain the same motor speed
	SAME_ANGLE	EQU	08000H		;used to maintain the same angle
	
;parallel port base address
	ParallelPort	EQU		180H				;base address for parallel port
 ;offsets from parallel port begin
	ParallelPortA	EQU		ParallelPort + 00H	;not used so far
	ParallelPortB	EQU		ParallelPort + 01H	;address for motors, laser
	ParallelPortC	EQU		ParallelPort + 02H	;address for turret stepper motor
	ParallelCtrl	EQU		ParallelPort + 03H	;control register for parallel port

;index maxima
	MAX_PWM_CNT		EQU		07FH 		;max count before PWM loops
	MOTOR_NUM		EQU		3		    ;number of motors to drive
	
;constants for fixed-point arithmetic
	EXTRA_SIGN_BITS	EQU		02H		;number of extra sign bits to get rid of
	NEG_SIGN		EQU		80H		;represents stored negative sign
    POS_SIGN        EQU     00H     ;represents stored positive sign
	NORM_SPEED      EQU     01H     ;shift speed by this to normalize between 0 and 1
    
	PWMCNT_OFFSET	EQU		08H		;values to ignore (shift out) in fixed-point result

    
	PARALLEL_CTRL_VAL	EQU		090H		;1------- 	activates parallel I/O
											;-00--0--	simple I/O (no handshake)
											;---1----	port A is input
											;------0-	port B is output
											;----0--0	port C is output										
	
;general constants
	FULL_ANGLE_FACTOR	EQU	360	 	;factor by which to multiply given angle to get 
										;	an angle between -180 and 180
	FULL_ANGLE_OFFSET	EQU	360			;offset between angles in [-180,180] and angles in
										;	[0,360] 
	ANGLE_DIGITS		EQU	3			;number of digits to use for angle measurement
		
	LASER_ON	EQU		10000000B		;sets laser on
    LASER_OFF   EQU             0       ;sets laser off
    
    WORDLENGTH	EQU	0002H				;allows us to turn a byte address into a word 
										;	address
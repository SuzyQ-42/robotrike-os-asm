	NAME		MTREVNT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									MTREVNT.ASM											 ;
;			Initialization Procedures and Instructions for Timer 1 Event Handler		 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains a set of functions called when initializing timer event
;		Timer1EventHandler:	controls motors via PWM
;		InitTimer1:			writes control/count values to timer registers	
;		InstallTmr1Handler:	puts the pointer to the timer 1 event handler in the interrupt 
;								vector table
;Revision History:		11/12/2014	Suzannah Osekowsky	separated from timer main loop
;						11/14/2014	Suzannah Osekowsky	modified for homework 6
;						11/21/2014	Suzannah Osekowsky	updated comments
;
CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
		
; local include files
$INCLUDE(TMRINT.INC)	;contains useful constants specific to the timer event handler
$INCLUDE(TIMER.INC)		;contains addresses and constants for use with timer registers
$INCLUDE(INTCON.INC)	;contains addresses and constants for interrupt controller

;external functions
	EXTRN	PWMFunc:NEAR	;outputs intended speed of each individual motor, laser status
								
; Timer1EventHandler
;
; Description:		Manages pulse width modulation output to motors by calling an external
;					PWM function.
;
; Operation:		Calls PWM function (which checks whether motors are 
;					running/not running according to a pulse width modulation count, 
;					outputs signals to motors, and checks/outputs user-input laser value),
;					then sends a Timer EOI and restores registers.
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
; Registers Used:   AX,DX (all restored)
; Stack Depth:      9 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		Speeds that necessitate a duty cycle output of less than 1 percent 
;					will be represented with a zero duty cycle.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 21, 2014
Timer1EventHandler		PROC	NEAR
						PUBLIC	Timer1EventHandler
	PUSHA						;save registers so the event handler doesn't change them
	CALL	PWMFunc				;output on/off signals to each motor using PWM

    MOV	DX,IntCtrlrEOI	        ;sends EOI to interrupt controller
	MOV	AL,TimerEOI		
	OUT	DX,AL
    
	POPA						;restore registers
	IRET						;done so return
Timer1EventHandler      ENDP

; InitTimer1
;
; Description:       Initialize the 80188 Timer 1. Timer 1 generates an interrupt every 
;					 MOTOR_COUNT ms. The interrupt controller is also initialized to allow 
;					 timer interrupts.  
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count register
;                    is reset to zero.  Finally, the interrupt controller is
;                    setup to accept timer interrupts and any pending
;                    interrupts are cleared by sending a TimerEOI to the
;                    interrupt controller.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Author:            Suzannah Osekowsky
; Last Modified:     Nov. 21, 2014

InitTimer1       PROC    NEAR
                 PUBLIC  InitTimer1
		MOV		DX,Timer1Count	;set up Timer #1 for MOTOR_COUNT interrupts
		XOR		AX,AX			;clear count register
		OUT 	DX,AL			
		
		MOV		DX,Timer1CMPA	;set up max count for timer count per motor signal output
		MOV		AX,MOTOR_COUNT	;	to MOTOR_COUNT interrupts
		OUT		DX,AL			
		
		MOV		DX,Timer1Ctrl	;set up control register, interrupts on
		MOV		AX,Tmr1CtrlVal	
		OUT		DX,AL			
                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer1       ENDP

; InstallTmr1Handler
;
; Description:       Install the event handler for the timer 1 interrupt.
;
; Operation:         Writes the address of the timer 1 event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, ES
; Stack Depth:       0 words
;
; Author:            Suzannah Osekowsky
; Last Modified:     Nov. 21, 2014

InstallTmr1Handler  PROC    NEAR
                    PUBLIC  InstallTmr1Handler


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr1Vec), OFFSET(Timer1EventHandler)
        MOV     ES: WORD PTR (4 * Tmr1Vec + 2), SEG(Timer1EventHandler)


        RET                     ;all done, return


InstallTmr1Handler  ENDP

CODE	ENDS

END
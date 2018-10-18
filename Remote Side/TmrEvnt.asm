	NAME		TMREVNT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									TMREVNT.ASM											 ;
;			Initialization Procedures and Instructions for Timer 0 Event Handler		 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains a set of functions called when initializing timer event
;		Timer0EventHandler:	contains instructions to run each time the timer is called
;		InitTimer0:			writes control/count values to timer registers	
;		InstallTmr0Handler:	puts the pointer to the timer event handler in the interrupt 
;								vector table
;Revision History:		11/12/2014	Suzannah Osekowsky	separated from timer main loop
;
CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
		
; local include files
$INCLUDE(TMRINT.INC)	;contains useful constants specific to the timer event handler
$INCLUDE(TIMER.INC)		;contains addresses and constants for use with timer registers
$INCLUDE(INTCON.INC)	;contains addresses and constants for interrupt controller

;external functions
EXTRN	MUXDisplay:NEAR		;Outputs a single digit to the display with every interrupt
EXTRN	KeyScan:NEAR		;Scans the keyboard for button presses with each timer 0 int

; Timer0EventHandler
;
; Description:       This procedure is the event handler for the timer
;                    interrupt. It accesses each digit and finds the user-input value,
;					 then displays that value and holds it until the timer event is 
;					 incurred again. Patterns longer than 8 digits will be cut off.
;
; Operation:         Calls external function to access and display each digit value 
;					(previously stored in a buffer by a separate, user-accessed function). 
;					 Clears timer interrupt and returns.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            14-segment digits to the display
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
; Stack Depth:       4 words
;
; Author:            Suzannah Osekowsky
; Last Modified:     Nov 7, 2014
;
Timer0EventHandler	PROC	NEAR
					PUBLIC	Timer0EventHandler
					
Timer0EventHandlerInit:
	PUSH 	AX			;save registers
	PUSH	BX
	PUSH	DX
	CALL	MUXDisplay	;display the relevant digit
    CALL    KeyScan     ;check if any buttons have been pressed

EndTimer0EventHandler:
	MOV	DX,IntCtrlrEOI	;sends EOI to interrupt controller
	MOV	AL,TimerEOI		
	OUT	DX,AL
	
	POP DX				;restores registers
	POP	BX
	POP	AX								
	IRET									
Timer0EventHandler	ENDP	

; InitTimer0
;
; Description:       Initialize the 80188 Timers.  The timers are initialized
;                    to generate interrupts every MS_PER_SEG milliseconds.
;                    The interrupt controller is also initialized to allow the
;                    timer interrupts.  Timer #2 is used to prescale the
;                    internal clock from 2.304 MHz to 1 KHz.  Timer #0 then
;                    counts MS_PER_DIG timer #2 intervals to generate the
;                    interrupts.
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count registers
;                    are reset to zero.  Finally, the interrupt controller is
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
; Last Modified:     Nov. 7, 2014

InitTimer0       PROC    NEAR
                 PUBLIC  InitTimer0

                                ;initialize Timer #0 for COUNTS_PER_MS count interrupts
        MOV     DX, Timer0Count ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Timer0CMPA 		;setup max count for timer count per digit output
        MOV     AX, COUNTS_PER_MS  	;   count so can time the segments
        OUT     DX, AL

        MOV     DX, Timer0Ctrl    ;setup the control register, interrupts on
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer0       ENDP




; InstallTmr0Handler
;
; Description:       Install the event handler for the timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
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
; Last Modified:     Nov. 7, 2014

InstallTmr0Handler  PROC    NEAR
                    PUBLIC  InstallTmr0Handler


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(Timer0EventHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(Timer0EventHandler)


        RET                     ;all done, return


InstallTmr0Handler  ENDP

CODE	ENDS

END
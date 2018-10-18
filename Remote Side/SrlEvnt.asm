	NAME		SERIALEVNT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									SRLEVNT.ASM											 ;
;			Initialization Procedures and Instructions for INT2 Event Handler			 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains a set of functions called when initializing timer event
;		INT2EventHandler:	Outputs values from target board to motors/laser
;		InstallINT2Handler:	puts the pointer to the INT2 event handler in the interrupt 
;								vector table
;		InitINT2:			Initializes INT2 interrupt
;Revision History:		11/23/2014	Suzannah Osekowsky	initial revision
;
CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
		
; local include files
$INCLUDE(TIMER.INC)		;contains addresses referenced in following include file
$INCLUDE(INTCON.INC)	;contains addresses and constants for interrupt controller
$INCLUDE(TMRINT.INC)	;some useful interrupt-related constants
$INCLUDE(SERIAL.INC)	;contains constants for use with serial output
$INCLUDE(SRLEVNT.INC)   ;addresses, constants for installing INT2 event handler

;external functions
	EXTRN	SerialEventHandler:NEAR	;outputs values from target board to motors/laser
								
; INT2EventHandler
;
; Description:		Calls the serial event handler, which checks the interrupt ID and 
;					executes appropriate instructions to clear and handle the event. Loops
;					if more interrupts remain (interrupt ID register is not clear). Sends
;					an EOI when no more interrupts remain.
;
; Operation:		Calls the serial event handler, which checks the interrupt ID and 
;					executes appropriate instructions to clear and handle the event. Reads
;					the interrupt ID register, and calls the serial event handler again if
;					the IIR is not empty. When done, sends an INT2 end of interrupt and 
;					returns.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			Values to transmitter holding register.
;
; Error Handling:	Clears modem status, line status errors.
;
; Registers Used:   AX,BX,DX
; Stack Depth:      18 words
;
; Algorithms:		None.
; Data Structures:	Queues (for some events)
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
INT2EventHandler		PROC	NEAR
						PUBLIC	INT2EventHandler
	PUSHA						;save registers so the event handler doesn't change them
HandlerLoop:
    CALL	SerialEventHandler	;output signals to robotrike
    
    MOV     DX,EOIReg           ;else, clear interrupt by sending INT2EOI
    MOV     AL,INT2EOI
    OUT		DX,AL	
    
	POPA						;restore registers
	IRET						;done so return
INT2EventHandler      ENDP

; InstallINT2Handler
;
; Description:       Install the event handler for the INT2 interrupt.
;
; Operation:         Writes the address of the INT2 event handler to the
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

InstallINT2Handler  PROC    NEAR
                    PUBLIC  InstallINT2Handler

        MOV     AX,0
        MOV		ES,AX         			;clear ES (interrupt vectors are in segment 0)
										;store the vector
        MOV		ES:WORD PTR(4 * INT2Vec),OFFSET(INT2EventHandler)
        MOV		ES:WORD PTR(4 * INT2Vec + 2),SEG(INT2EventHandler)

        RET                     ;all done, return


InstallINT2Handler  ENDP

; InitINT2
;
; Description:       Initialize INT2 as a level-triggering,unmasked interrupt
;
; Operation:         Writes the INT2 control register with values indicating it is a 
;					 level-triggering, unmasked interrupt. Sends an INT2 EOI to clear 
;					 interrupt.
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
; Registers Changed: flags, AX, BX, ES
; Stack Depth:       0 words
;
; Author:            Suzannah Osekowsky
; Last Modified:     Nov. 25, 2014
InitINT2    PROC    NEAR
            PUBLIC  InitINT2
    MOV DX,INT2Ctrl     ;get current control register value
    IN  AX,DX
    AND AX,Priority     ;Clear priority bits
    OR  AX,INT2Priority ;set desired priority bits
    OR  AX,LvlTrig      ;set as level-triggering
    MOV BX,IntMask      ;unmask interrupt
    NOT BX
    AND AX,BX
    OUT DX,AX           ;and return value to control register
    
    MOV BX,UNMASK_INT2  ;unmask interrupt 2
    MOV DX,IntMaskReg   ;by getting value currently in register
    IN  AX,DX
    AND AX,BX           ;ANDing with cleared value
    MOV DX,AX           ;and returning it to the appropriate register
    
    MOV     DX,EOIReg   ;clear interrupt by sending INT2EOI
    MOV     AL,INT2EOI
    OUT		DX,AL
    
    RET
InitINT2   ENDP

CODE	ENDS

END
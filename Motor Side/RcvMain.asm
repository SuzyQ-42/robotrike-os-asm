	NAME		RECEIVERMAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									RCVMAIN.ASM											 ;
;				Main loop for the receiver (motor) side of the system					 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ReceiverMain
;
; Description:		Main loop for receiver (motor) side of the robotrike system
;
; Operation:		Calls functions to initialize chip selects, interrupt vector table, 
;					serial event handler, motor timers, serial parser, and serial transmit
;					functions. It then loops emptying the main event queue.
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
; Error Handling:	Enqueues and transmits errors.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Revision History:
;	12/07/2014	Suzannah Osekowsky	initial revision

CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DATA, SS:STACK
;local include files
$INCLUDE(QUEUE.INC)     ;defines queue structure
$INCLUDE(SERIAL.INC)    ;important constants for queue creation	
$INCLUDE(RCVMAIN.INC)   ;constants specific to the receiver-side main loop
	
;external function declarations
	EXTRN	InitCS:NEAR		;writes initial control values to chip selects
	EXTRN	ClrIRQVectors:NEAR		;replaces the data in the non-reserved parts of the 
									; table with a pointer to the illegal event handler
	EXTRN	InstallTmr0Handler:NEAR	;puts pointer to timer event handler in table
    EXTRN   InstallInt2Handler:NEAR ;install interrupt 2 event handler
    EXTRN   InitINT2:NEAR           ;initialize the interrupt
    EXTRN   SerialInit:NEAR         ;initialize serial queues
	EXTRN	ParseInit:NEAR			;initializes variables for parsing state machine
	EXTRN	InitTimer1:NEAR			;writes control/count values to timers
	EXTRN	InstallTmr1Handler:NEAR	;creates pointer to timer 1 event handler
    EXTRN   MotorInit:NEAR          ;initializes motor variables and arrays
    EXTRN   Dequeue:NEAR            ;removes a value from a queue
    EXTRN   ParseSerialChar:NEAR    ;parses passed serial characters
    EXTRN   ReceiverInit:NEAR       ;initializes receiver variables
    EXTRN   CheckForEvents:NEAR     ;blocking function that loops until queue is not empty

START:

MAIN:

	MOV     AX, STACK               ;initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(TopOfStack)

    MOV     AX, DATA                ;initialize the data segment
    MOV     DS, AX

    CALL    InitCS                  ;initialize the 80188 chip selects
                                        ;   assumes LCS and UCS already setup

    CALL    ClrIRQVectors           ;clear (initialize) interrupt vector table

	CALL	InstallINT2Handler		; install Int2 event handler								

    CALL    InitINT2	            ;initialize the INT2 interrupt
    
	CALL	InstallTmr1Handler		; install Timer 1 event handler								

    CALL    InitTimer1              ;initialize the internal timer
		
	CALL	MotorInit				;initialize motor variables
    
    CALL    ReceiverInit            ;initialize receiver main loop queue
    
    CALL    ParseInit               ;initialize parser state machine
		
	MOV		AX,PARITY_INDEX			;default parity
	MOV		BX,BAUD_INDEX			;default baud
		
SetThingsIfYouWant:				    ;can set a breakpoint to set the parity and baud

	CALL	SerialInit				;initialize serial queues
		
	STI                             ;and finally allow interrupts.
	
MainLoop:
    CALL    CheckForEvents          ;blocking function that loops until queue
                                    ;   is not empty
    
	CALL	Dequeue					;call function to get head of queue in AL
    
	CALL	ParseSerialChar 		;perform appropriate function
    
	JMP	MainLoop				    ;when done, loop forever


CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'		;empty data segment so it can be initialized in this
									;	file
DATA    ENDS

STACK           SEGMENT STACK  'STACK'	;initialize the stack

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK           ENDS

    END     START
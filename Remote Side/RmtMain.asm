	NAME	REMOTEMAIN																		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									RMTMAIN.ASM											 ;
;						Remote-side main loop for robotrike								 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:		Initializes and runs functions for remote side of robotrike system
;
; Operation:		Calls initialization functions, then enables interrupts and starts 
;					dequeueing any queued events.
;
; Input:            None.
; Output:           Characters to serial port, lights to display.
;
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  Queues for input/output
;
; Revision History:
;   12/03/2014		Suzannah Osekowsky	initial revision

CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DATA, SS:STACK
        
; local include files
$INCLUDE(serial.inc)    ;constants for initializing serial
$INCLUDE(RmtPars.inc)   ;constants for parsing serial characters on remote side
$INCLUDE(RmtMain.Inc)   ;constants specifically for the remote-side main loop
$INCLUDE(Queue.inc)     ;important stuff for defining queues
$INCLUDE(Motor.inc)     ;again, I'm really only using this to define word queues

; external function declarations
	EXTRN	InitCS:NEAR				;writes initial control values to chip selects
	EXTRN	ClrIRQVectors:NEAR		;replaces the data in the non-reserved parts of the 
									; table with a pointer to the illegal event handler
	EXTRN	ParseInit:NEAR			;initializes variables for parsing state machine
	EXTRN	InitTimer0:NEAR			;writes control/count values to timers
	EXTRN	InstallTmr0Handler:NEAR	;puts pointer to timer event handler in table
    EXTRN   InstallInt2Handler:NEAR ;install interrupt 2 event handler
    EXTRN   InitINT2:NEAR           ;initialize the interrupt
    EXTRN   SerialInit:NEAR         ;initialize serial queues
    EXTRN   InitializeDisplay:NEAR  ;initializes display variables
	EXTRN	KeypadInit:NEAR			;initializes keypad variables
    EXTRN   Dequeue:NEAR            ;removes a value from a queue
    EXTRN   Display:NEAR            ;displays a string at a passed address
    EXTRN	RemoteInit:NEAR			;Initializes queue for remote-side main loop
    EXTRN   EventTypeTable:WORD		;Table of function calls for various event types
    EXTRN   CheckForEvents:NEAR     ;blocking function that loops until queue is not empty
	

START:  

MAIN:
    MOV     AX, STACK               ;initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(TopOfStack)

    MOV     AX, DATA                ;initialize the data segment
    MOV     DS, AX
    
	CALL	InitCS					;initialize chip selects
    
	CALL	ClrIRQVectors
    
	CALL	RemoteInit				;initialize remote variables
    
	CALL    InstallTmr0Handler      ;install the keypad/display event handler

    CALL    InitTimer0               ;initialize the internal timer
		
	CALL	InitializeDisplay		;initialize display variables
		
	CALL	KeypadInit				;initialize keypad variables
	
    CALL    ParseInit               ;initialize remote-side serial parser

	CALL	InstallINT2Handler		; install serial event handler								

    CALL    InitINT2	            ;initialize the INT2 interrupt
		
	MOV		AX,PARITY_INDEX			;default parity
	MOV		BX,BAUD_INDEX			;default baud
		
	SetThingsIfYouWant:				;can set a breakpoint to set the parity and baud
	
	CALL	SerialInit				;initialize serial queues
	
	STI								;allow interrupts
	
MainLoop:
	CALL    CheckForEvents                      ;blocking function that loops until queue
                                                ;   is not empty
	CALL	Dequeue								;call function to get head of queue in AX
    MOV     BX,AX                               ;copy event value into indexable variable
    XCHG    BH,BL                               ;use upper bits as index
    MOV     BH,00                               ;clear new upper bits. Don't need those.
    IMUL    BX,WORDLENGTH                       ;multiply by size of table entry
WhatTheFuck:
    ADD     BX,OFFSET(EventTypeTable)           ;and look up function in call table
    MOV     SI,CS:[BX]
HelpfulBreakpointSpot:
	CALL	SI                                  ;get function to be performed from
												; lookup table
	JMP	MainLoop								;when done, loop forever

CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'					;queues for use in called functions


DATA    ENDS

STACK           SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK           ENDS

    END     START
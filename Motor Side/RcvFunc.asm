    NAME    RCVFUNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                                        ;
;                                   RCVFUNC.ASM                                          ;
;                   Functions for use with receiver main loop                            ;
;                               Suzannah Osekowsky                                       ;
;                                                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains functions for use with the receiver main loop. The functions included
; are:
;   ReceiverInit:       Initializes receiver variables
;	EnqueueEvent:		Enqueues an event into the main event queue
;	CheckForEvents:		Checks if the event queue is empty
;	OutputSerialString:	Outputs a string at ES:SI to serial port

CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DATA
        
;local include files
$INCLUDE(QUEUE.INC)     ;defines queue structure
$INCLUDE(SERIAL.INC)    ;important constants for queue creation	
$INCLUDE(RCVMAIN.INC)   ;constants specific to the receiver-side main loop
$INCLUDE(ASCII.INC)     ;Defines important ASCII characters

;external function declarations
    EXTRN   QueueInit:NEAR          ;initializes a queue
    EXTRN   Enqueue:NEAR            ;enqueues a value in a queue
    EXTRN   QueueEmpty:NEAR         ;checks if queue at passed address is empty
	EXTRN	SerialPutChar:NEAR		;enqueues a character to be output to the serial port
        
; ReceiverInit
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
; Local Variables:	AX - number of entries in desired queue
;					BL - indicator as to desired size of each queue element (byte or word)
;					SI - address of queue
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX, BX, SI
; Stack Depth:      1 word
;
; Algorithms:		None.
; Data Structures:	Queue structure
;
; Known Bugs:		None.
; Limitations:		Can't initialize a queue of over 511 bytes' length.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 14, 2014
ReceiverInit		PROC	NEAR
				PUBLIC	ReceiverInit
	MOV		AX,EVENT_QUEUE_LENGTH	;initialize a word queue at address EventQueue
	MOV		BL,BYTE_QUEUE			; with EVENT_QUEUE_LENGTH entries
	LEA		SI,EventQueue
	CALL	QueueInit	
	RET                             ;done, return				
ReceiverInit		ENDP

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
; Return Values:	SI - address of event queue
;
; Local Variables:	SI - address of event queue
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			None.
;
; Error Handling:	Enqueues receiver-side error events.
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
; Last Modified:	Dec. 12, 2014
CheckForEvents  PROC    NEAR
                PUBLIC  CheckForEvents
 LoopUntilNotEmpty:
    LEA		SI,EventQueue						;load address of event queue into register
	CALL	QueueEmpty							;check if queue is empty
	JZ		LoopUntilNotEmpty       			;keep looping if queue is empty
    RET
CheckForEvents  ENDP

; OutputSerialString
;
; Description:		Outputs a stored ASCII string to serial port; loops ensuring that all
;					characters up to 1st null character in the string are output.
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
        CMP		AL, ASCIInull              	;check if at end of transmission
		JE		EndTransmission     		;if not at end, continue sending
											;	character; terminate if at null	
		CALL	SerialPutChar				;enqueue for serial output
		JC		OutputSerialStringLoop		;loop until value is enqueued
		INC		CX							;increment counter if value is enqueued
        JMP     OutputSerialStringLoop      ;continue until dequeued char is ASCII null
		
    EndTransmission:
        MOV     AL,EOS                      ;else, output end of transmission
        CALL    SerialPutChar               ;enqueue for serial output
        JC      EndTransmission             ;loop until value is enqueued
		RET									;and return
OutputSerialString	ENDP

CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'					;queues for use in called functions

EventQueue	QUEUE<>					;creates a queue for storing actions

DATA    ENDS
END
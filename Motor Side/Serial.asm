	NAME	SERIAL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									SERIAL.ASM											 ;
;			Functions for Generating and Monitoring Serial Output Status				 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This document contains functions for generating and monitoring serial I/O.
;	SerialInit:			Initializes shared variables and structures for the serial channel
;	SetParity:			Sets the parity of the serial channel
;	SetData:			Does stop/data bit settings for serial channel
;	SetBaud:			Sets baud rate for serial channel
;	EnableSerialInt:	Sets interrupt enable register to enable serial interrupts
;	SerialPutChar:		Outputs a user-generated character to the serial channel
;	SerialEventHandler:	Enqueues input data, dequeues output data, monitors error status
;	ModemStatus:		Handles a modem interrupt (clears interrupt, returns)
;	NoError:			Handles no error (returns without doing anything)
;	DataReady:			Handles a data ready event (puts data in a holding queue)
;	SendData:			Handles a THRE (transmit holding reg. empty) event
;	LineStatErr:		Handles a line status error by clearing error and returning
;	ErrFuncTable:		Holds addresses for functions to be called by serial event handler
CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP,DS:DATA
;local include files
$INCLUDE(Serial.inc)	;constants specifically for serial connection
$INCLUDE(Motor.inc)		;Has only one constant I need (WORDLENGTH) but I don't want to 
						;	redefine it
$INCLUDE(Queue.inc)

; external function declarations
	EXTRN	QueueInit:NEAR		;initializes a queue defined by the user
	EXTRN	QueueEmpty:NEAR		;returns whether or not a queue is empty
	EXTRN	QueueFull:NEAR		;returns whether or not a queue is full
	EXTRN	Dequeue:NEAR		;remove and return a value at the head of the queue
	EXTRN	Enqueue:NEAR 		;add a value to the queue
    EXTRN   EnqueueEvent:NEAR   ;test code, enqueues transmitted serial character
	EXTRN	ParityTable:BYTE	;register values for each of 5 parity options
	EXTRN	BaudTable:WORD 		;register values for each of 10 baud rates

; SerialInit
;
; Description:		Initializes registers controlling data bits, stop bits, parity, baud
;					rate, and interrupts of serial connection. Initializes a queue of 
;					values to be output and returns.
;
; Operation:		Outputs appropriate values to line control register, baud divisor 
;					registers, and interrupt enable register on serial chip. Uses an 
;					external struc and the function QueueInit to initialize TxQueue at 
;					length TX_LENGTH with element size BYTE_QUEUE.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			Values to serial registers
;
; Error Handling:	None.
;
; Registers Used:   SI,AX,BX
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	TxQueue - queue holding elements to be output via serial connection
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SerialInit		PROC	NEAR
				PUBLIC	SerialInit
SetSerialChip:
	CALL 	SetParity		;set parity, data/stop bits, and baud rate as defined by 
	CALL	SetData			;	constants; enable serial interrupts
	CALL	SetBaud
    CALL    EnableSerialInt
InitQueues:
	LEA	SI,TxQueue		    ;initialize the otuput queue 
	MOV	AX,TX_LENGTH
	MOV	BX,BYTE_QUEUE
	CALL QueueInit	
SerialInitDone:
    RET                     ;done, so return
SerialInit	ENDP

; SetParity
;
; Description:		Sets parity according to a value passed in BX as an index to the 
;					parity table.
;
; Operation:		Gets the address of the line control register, and ORs in the value 
;					indexed by BX in the parity table. Restores registers and returns.
;
; Arguments:		BX - index to parity table. Default is no parity unless user chooses 
;					otherwise.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			Parity bits to LCR
;
; Error Handling:	None.
;
; Registers Used:   AX,BX,DX,SI
; Stack Depth:      1 word
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SetParity	PROC	NEAR
			PUBLIC	SetParity
	PUSH BX						;save baud value
	MOV	BX,AX					;preserve intended baud rate
	MOV	DX,LineCtrlReg			;get address for LCR
	IN	AX,DX					;get value from LCR
	AND AX,CLEAR_PARITY			;clears parity bits so we can set them correctly
	MOV	SI,OFFSET(ParityTable)	;get parity value from table
	ADD	SI,BX					; choose correct (byte) value
	MOV	BX,CS:[SI]				;get the value from the table
	OR	AX,BX					;and OR it with AX to get 
	OUT	DX,AX					;return changed value to LCR
	POP BX						;restore baud value
    RET
SetParity	ENDP

; SetData
;
; Description:		sets LCR to transmit 8 bits of data (1 character) per transmission, 
;					and to transmit 2 stop bits per transmission.
;
; Operation:		Reads in line control register value, ORs in values indicating 8 bits
;					per transmission and 2 stop bits per transmission. Outputs new value 
;					back to LCR.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			Updated value to LCR.
;
; Error Handling:	None.
;
; Registers Used:   AX,DX
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SetData		PROC	NEAR
			PUBLIC	SetData
	MOV	DX,LineCtrlReg			;sets LCR to transmit 8 bits of data (1 character)
	IN	AX,DX
	OR	AX,SERIAL_8_BIT
	OR	AX,STOP_BITS_2			;sets 2 stop bits
	OUT	DX,AX
	RET
SetData		ENDP

; SetBaud
;
; Description:		Sets baud rate divisor for passed baud index (0-7), which corresponds
;					to an entry in the baud divisor table. 
;
; Operation:		Sets DLAB so baud divisors can be written; gets value from baud 
;					divisor table and writes it to baud divisor registers. Resets DLAB and
;					returns.
;
; Arguments:		BX - baud index (refers to baud divisor table in document SrlTab.asm)
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			Baud rate divisors to divisor registers.
;
; Error Handling:	None.
;
; Registers Used:   AX,CX,DX,SI,flags
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SetBaud		PROC	NEAR
			PUBLIC	SetBaud
SetDLAB:
	MOV	DX,LineCtrlReg			;get address for LCR
	IN	AX,DX					;get value from LCR
	OR 	AX,WRITE_DIVISOR		;turn on DLAB so we can write to the divisor register
	OUT	DX,AX
WriteBaudLower:
	MOV	SI,OFFSET(BaudTable)	;get address of desired value
    MOV AX,BX                   ;get word address of desired baud rate (see table for 
	MOV CX,WORDLENGTH			;   allowed baud rates and respective offsets)		
    MUL	CX
	ADD	SI,AX		
	MOV	AX,CS:[SI]				;get desired baud divisor from table
	MOV	DX,DivLatchLB			; (high bits to upper bits register, low bits to lower)
	OUT	DX,AL
WriteBaudUpper:
    MOV AL,AH                   ;shift for output
	MOV	DX,DivLatchHB
	OUT	DX,AL
ResetDLAB:
	MOV	DX,LineCtrlReg			;get address for LCR
	IN	AX,DX					;get value from LCR
	AND	AX,DIVISOR_DONE			;turn off DLAB so we can access other registers later
	OUT	DX,AX	
SetBaudDone:
	RET
SetBaud		ENDP

; EnableSerialInt
;
; Description:		Enables interrupts from the serial chip.
;
; Operation:		Sets bits to enable interrupts for line status, transmitter holding
;					register empty, modem status, and receiver register have data. Outputs
;					a value that indicates these interrupts enabled to the interrupt 
;					enable register on the serial chip.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:			Value to interrupt enable register.
;
; Error Handling:	None.
;
; Registers Used:   AX,DX
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014	
EnableSerialInt     PROC    NEAR
                    PUBLIC  EnableSerialInt
    MOV DX,IntEnableReg     ;write interrupt-enabling value to the interrupt enable reg.
    MOV AL,INTERRUPTS_ON    
    OUT DX,AL
    RET
EnableSerialInt     ENDP

; SerialPutChar
;
; Description:		Enqueues a value for transmission if the queue is not full. If the 
;					queue was empty last time the transmission holding register empty 
;					(THRE) interrupt was generated, it kickstarts interrupts to generate 
;					another interrupt so the system send the newly enqueued character.
;
; Operation:		Checks if queue is full using QueueFull function. If so, sets a carry 
;					flag to indicate that event has not been enqueued, and returns. If not
;					it checks if the kickstart flag is set (set by the THRE event handler)
;					and if that is set, it enqueues the value and kickstarts interrupts by
;					clearing the serial interrupt enable register and rewriting it after 
;					enqueueing the value. If the kickstart flag is not set, it enqueues 
;					the value without kickstarting interrupts.
;
; Arguments:		AL - character to be enqueued
; Return Values:	Carry flag - set if character not enqueued, else cleared
;
; Local Variables:	None.
; Shared Variables: KickStartFlag - flag indicating whether kickstarting is enabled or 
;									disabled.
; Global Variables: None.
;
; Input:            None.
; Output:			None directly.
;
; Error Handling:	Returns a carry flag if the transmission queue is full.
;
; Registers Used:   AX,BX,CX,DX,SI,(all restored), flags
; Stack Depth:      18 words
;
; Algorithms:		None.
; Data Structures:	TxQueue - queue of values to be transmitted
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SerialPutChar	PROC	NEAR
				PUBLIC	SerialPutChar
CheckQueueFull:	
	PUSHA					;save registers because why not
	LEA	    SI,TxQueue  	;access output queue
	CALL	QueueFull		;check if we can output a character (queue is not full)
							;	returns when queue is not full
	JNZ		CheckKS			;if not, go enqueue a value
	STC						;else, set carry flag
	JMP		PutCharDone		;and return
CheckKS:
    MOV     CL,KickStartFlag    ;check if should kickstart
    CMP     CL,KS_ON        ;if so, go kickstart the thing
    JE      KickstartEnqueue
    ;JMP     EnqueueNoKS     ;else, enqueue without kickstarting
EnqueueNoKS:
    CALL    Enqueue          ;enqueue the character (no kickstart) and clear carry flag
    JMP     ClearCarry
KickstartEnqueue:
    MOV BX,AX               ;save value in AX
    MOV DX,IntEnableReg     ;temporarily stop interrupts for transmitter register empty
    MOV AL,CLR_INTERRUPTS    
    OUT DX,AL               
    MOV AX,BX               ;get value to enqueue
	CALL    Enqueue		    ;adds the value to the end of the output queue
    MOV DX,IntEnableReg     ;kickstart interrupts
    MOV AL,INTERRUPTS_ON    
    OUT DX,AL
    ;JMP    ClearCarry     ;clear carry flag and return
ClearCarry:
	CLC						;clear carry flag
	;JMP	PutCharDone		;and return
PutCharDone:
	POPA					;restore registers
	RET
SerialPutChar	ENDP

; SerialEventHandler
;
; Description:		Uses the value in the interrupt identification register to find the 
;					appropriate event handler, then executes that event handler.
;
; Operation:		Reads the interrupt identification register (IIR) on the serial chip 
;					and uses it to look up an address in an function handling table. If 
;                   the IIR indicates that there are no interrupts pending, it returns to
;                   the INT2 event handler.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Value from interrupt ID register.
; Output:			None.
;
; Error Handling:	Handles modem status, line status errors by clearing the interrupt.
;
; Registers Used:   AX,BX,DX,SI
; Stack Depth:      1 word
;
; Algorithms:		None.
; Data Structures:	None here (some event handlers call queues)
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SerialEventHandler	PROC	NEAR
					PUBLIC	SerialEventHandler
HandleStatus:
	MOV	DX,IntIDReg				;get value from interrupt ID register
	IN	AL,DX
    MOV	AH,0					;clear junk (unused) data from upper bits
    CMP     AL,NO_INTERRUPT     ;check if there is still an interrupt pending
    JE     EventHandlerDone     ;and if not, return
    
HandlerLoop:
    MOV BX,WORDLENGTH           ;use word table
    MUL BX
	MOV SI,OFFSET(ErrFuncTable)	;use that value to get the correct function from the 
	ADD	SI,AX					;	status handling function table
	MOV	BX,CS:[SI]				;get the address of the desired function
    CALL BX   		            ;call the function at that address (handle appropriate 
								;	status)	
    
EventHandlerDone:
	RET					;done so return
SerialEventHandler	ENDP

; ModemStatus
;
; Description:		Read modem status register to clear modem interrupt.
;
; Operation:		Read modem status register to clear modem interrupt.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Value from modem status register
; Output:			None.
;
; Error Handling:	Clears modem status error.
;
; Registers Used:   AX,DX
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
ModemStatus		PROC	NEAR
				PUBLIC	ModemStatus
	MOV	DX,ModemStatReg		;read modem status register to clear interrupt
	IN	AX,DX				
	RET						;done, return
ModemStatus		ENDP

; NoError
;
; Description:		Does nothing, returns.
;
; Operation:		Does nothing. Really it doesn't do anything, I just need it so the 
;					code has something to call if the IIR is empty.
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
; Last Modified:	Nov. 23, 2014
NoError		PROC	NEAR
			PUBLIC	NoError
    NOP			;I really meant it does nothing
    RET 		;look at that, it didn't do anything.
NoError		ENDP

; DataReady
;
; Description:		This expects to be run when there's a value in the received data 
;					register. It calls an external function to enqueue the data in a
;					received data queue.
;
; Operation:		Reads value from receiver buffer register, calls an external function 
;					that enqueues the data for use by the system.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Value from receiver buffer register.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX,DX
; Stack Depth:      1 word
;
; Algorithms:		None.
; Data Structures:	Queue
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
DataReady	PROC	NEAR
			PUBLIC	DataReady
	MOV		DX,ReceiverBufReg	;get value in receiver buffer register
	IN		AL,DX				; so we can enqueue it (clears interrupt)
	MOV		AH,SRL_RECEIVE		;put serial receive identifier into upper bits
	CALL	EnqueueEvent	    ;put data in received data queue						
	RET							;done, return
DataReady	ENDP


; SendData
;
; Description:		This expects to be called when the transmitter holding register is 
;					empty. It gets a value from the transmission queue and puts it in the 
;					transmitter holding register to be sent by the serial chip.
;
; Operation:		Checks if the transmission queue is empty; if so, sets the kickstart 
;					flag and returns. If not, it gets a value from the head of the 
;					transmission queue and puts that value in the transmitter holding 
;					register to be sent by the serial chip.
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: KickStartFlag - indicates whether interrupts must be kickstarted in 
;									SerialPutChar
; Global Variables: None.
;
; Input:            None.
; Output:			Value to transmitter holding register.
;
; Error Handling:	None.
;
; Registers Used:   AX,DX,SI
; Stack Depth:      5 words
;
; Algorithms:		None.
; Data Structures:	TxQueue - queue holding values to be transmitted by serial chip
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
SendData	PROC	NEAR
			PUBLIC	SendData
	LEA     SI,TxQueue     		;check if output queue is empty
	CALL 	QueueEmpty			
	JNZ		QueueOutVal			; if not, dequeue value and put it in output
	MOV     KickStartFlag,KS_ON ;if so, set kickstarter flag
    JMP		SetDataDone         ;and return
QueueOutVal:
	CALL	Dequeue				;get a value from output queue, return in AL
	MOV		DX,TransmitterReg	;output that value to Transmitter Holding Register (THR)
	OUT		DX,AL				;this clears the error
    MOV     KickStartFlag,KS_OFF    ;make sure kickstart flag is cleared
SetDataDone:
	RET
SendData	ENDP

; LineStatErr
;
; Description:      Reads LSR to clear error, goes back
;
; Operation:        Reads LSR,returns
;
; Arguments:		None.
; Return Values:	None.
;
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Value from line status register.
; Output:			None.
;
; Error Handling:	None.
;
; Registers Used:   AX,DX,flags
; Stack Depth:      0 words
;
; Algorithms:		None.
; Data Structures:	None.
;
; Known Bugs:		None.
; Limitations:		None.
;
; Author:			Suzannah Osekowsky
; Last Modified:	Dec. 01, 2014
LineStatErr     PROC    NEAR
                PUBLIC  LineStatErr
    MOV DX,LineStatReg  ;read line status register to clear error
    IN  AL,DX
    RET                 ;done, return
LineStatErr     ENDP
    
; ErrFuncTable
;
; Description:		Code segment offsets of error handlers for errors corresponding to 
;					values 
;
; Author:			Suzannah Osekowsky
; Last Modified:	Nov. 18, 2014
ErrFuncTable	LABEL	BYTE
				PUBLIC	ErrFuncTable
;	DW		Offset	
	DW		OFFSET(ModemStatus)	;reads modem status to clear error
	DW		OFFSET(NoError)		;handles no error
	DW		OFFSET(SendData)	;deals with empty THR
	DW		OFFSET(NoError)		;handles no error
	DW		OFFSET(DataReady)	;handes ready data
	DW		OFFSET(NoError)		;handles no error
	DW		OFFSET(LineStatErr)	;reads LSR to clear error
CODE	ENDS

DATA    SEGMENT PUBLIC  'DATA'			;queues for use in called functions

TxQueue	QUEUE<>			;creates an output queue
KickStartFlag   DB  ?   ;used to tell whether or not I need to kickstart interrupts

DATA    ENDS

END
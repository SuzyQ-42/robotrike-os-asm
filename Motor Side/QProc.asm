NAME	QPROC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    QProc                                   ;
;                      Initializing and Using Queues                         ;
;                              Suzannah Osekowsky                            ;
;																			 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This file contains a set of functions for use with queues. 
;		QueueInit:	initializes a queue defined by the user
;		QueueEmpty:	returns whether or not a queue is empty
;		QueueFull:	returns whether or not a queue is full
;		Dequeue:	remove and return a value at the head of the queue
;		Enqueue: 	add a value to the queue
;
;Revision History:	10/26/2014	Suzannah Osekowsky	wrote pseudo-code
;					10/31/2014	Suzannah Osekowsky	wrote assembly
;                   11/25/2014  Suzannah Osekowsky  made functions non-blocking
;                   11/26/2014  Suzannah Osekowsky  used the stack to save registers

CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP
; local include files	
$INCLUDE(QUEUE.INC)		;constants for writing queues


;QueueInit		
; Description:		Initializes a queue at passed address [SI] with passed length
;					AX and element size BL; defines variables for use in other functions. 
;					Allows user to define a queue of up to 512 bytes with elements of 
;					either bytes or words
;
; Operation:		Defines shared variables (head pointer, tail pointer, size, 
;					length, address) related to the queue. These shared variables are 
;					created by the queue structure and defined at set values. The user 
;					cannot initialize a queue of greater than 512 bytes.
;
; Arguments:        SI - address a at which queue begins
;					AX - length l of queue
;					BL - size s of individual elements
; Return Value:     None
;
; Local Variables:  None
; Shared Variables: [SI].head - stores head pointer value
;					[SI].tail - stores tail pointer value
;					[SI].valsize - size of elements in queue stored at memory address SI
;					[SI].lngth - length of queue (number of elements)
; Global Variables: None
;
; Input:            None
; Output:           None
;
; Error Handling:   None
;
; Registers Changed:AX - length passed to function (incremented to leave a blank space)
; Stack Depth:      0
;
; Algorithms:       None
; Data Structures:  Queue structure
;
; Known Bugs:       None
; Limitations:      Cannot initialize queue of more than 512 bytes
;
; Author:           Suzannah Osekowsky
; Last Modified:    10/26/2014


QueueInit	PROC	NEAR
			PUBLIC	QueueInit
			
Initialize:						;gives value to some shared variables related to the queue
	MOV 	[SI].head,0			;initializes head pointer to zero offset (starts at top of 
								;	allocated memory)
	MOV 	[SI].tail,0			;initializes tail pointer to zero offset
	ADD		AX,byte1			;accounts for the tail pointer address always being blank,
								;	  creating the intended number of addresses
	MOV		[SI].lngth,AX		;initializes length to the passed length + 1 byte
	CMP		BL,00				;Check if size is bytes (if BL=FALSE=00, then size = byte)
	JNE		WordQueue			;If not bytes, create word queue
	;JMP	ByteQueue			;else, create byte queue
	
ByteQueue:						;initializes a queue of byte-size elements
	MOV		[SI].valsize,byte1	;initializes size to 1 byte per element
	JMP		EndQueue			;goes to function termination
	
WordQueue:
	MOV		[SI].valsize,word1	;sets queue elements to be words
	;JMP	EndQueue			;goes to function termination
	
EndQueue:
	RET 	
	
QueueInit ENDP
	
	

;QueueEmpty
;
; Description:		Checks whether the queue at location [SI] is empty or not.
;					Returns a zero flag if the queue is empty and no zero flag 
;					otherwise. Because the tail pointer is always at the first blank value
;					in the queue, the queue is empty if the head and tail pointer are at 
;					the same place (the first value in the queue is empty).
;
; Operation:		Compares head and tail pointers, sets zero flag if equal, no
;					flag otherwise. Because the tail pointer is always at the first blank 
;					value in the queue, the queue is empty if the head and tail pointer 
;					are at the same place (the first value in the queue is empty).
;
; Arguments:        SI - address a at which queue begins
; Return Value:     None
;
; Local Variables:  CX - copy of head pointer for operations
; Shared Variables: [SI].head - stores head pointer value
;					[SI].tail - stores tail pointer value
; Global Variables: None
;
; Input:            None
; Output:           None
;
; Error Handling:   None
;
; Registers Changed:flags, CX
; Stack Depth:      1 word
;
; Algorithms:       None
; Data Structures:  Queue structure
;
; Known Bugs:       None
; Limitations:      None
; Author:           Suzannah Osekowsky
; Last Modified:    10/31/2014

QueueEmpty		PROC	NEAR
				PUBLIC	QueueEmpty

CheckQueueEmpty:
    PUSH    CX                  ;save register
	MOV		CX,[SI].head		;moves head pointer into a register for operations
	CMP		CX,[SI].tail		;checks whether head and tail pointers hold the same value
    POP     CX                  ;restore register
	RET							;if so, returns a set zero flag; no flag otherwise
QueueEmpty ENDP

; QueueFull
;
; Description:		Checks whether the queue at location [SI] is full or not.
;					Returns a zero flag if the queue is full and no zero flag 
;					otherwise. 
;
; Operation:		Checks whether myQueue.head = myQueue.tail + 1. If so, 
;					returns zero flag (queue is full). If not, returns no flag.
;
; Arguments:        SI - address a at which queue begins
; Return Value:     None
;
; Local Variables:  BX - total length of queue
; Shared Variables: [SI].head - stores head pointer value
;					[SI].tail - stores tail pointer value
;					[SI].lngth - stores number of elements in queue at [SI]
;					[SI].valsize - stores size of elements in queue at [SI]
; Global Variables: None
;
; Input:            None
; Output:           None
;
; Error Handling:   None
;
; Registers Changed:flags,AX,BX,DX
; Stack Depth:      0
;
; Algorithms:       None
; Data Structures:  Queue structure
;
; Known Bugs:       None
; Limitations:      None
; Author:           Suzannah Osekowsky
; Last Modified:    10/26/2014

QueueFull		PROC	NEAR
				PUBLIC	QueueFull
    PUSH    AX                  ;save the registers
    PUSH    BX
    PUSH    DX
CheckQueueFull:
	MOV		AX,[SI].lngth		;move a copy of the length of the queue into AX
	MUL		[SI].valsize		;multiplies length by size of elements to find total bytes
	MOV		BX,AX				;moves total length into BX so AX is available
	MOV		AX,[SI].tail		;loads tail pointer value into AX
	ADD		AX,[SI].valsize		;adds 1 position (either 1 word or 1 byte) into AX
	MOV		DX,0				;prepare DX for division
	DIV		BX					;DX = (tail + 1 position) MODUL0 (total bytes in queue)
	MOV		AX,DX				;tail position corrected for looping
	CMP		AX,[SI].head		;checks whether head is 1 higher than tail
    POP     DX                  ;restore registers
    POP     BX
    POP     AX
	RET							;if so, returns a set zero flag; no flag otherwise
QueueFull ENDP

;Dequeue
;
; Description:		Gets a value from the head of the queue at the address passed in SI, 
;					removes it from the head of the queue, increments/loops head pointer, 
;					and returns the value in register AX. Expects to be called when queue
;					is not empty.
;
; Operation:		stores head value, increments/loops head pointer, returns head value.
;
; Arguments:        SI - address a at which queue begins
; Return Value:     AX - value dequeued from queue at [SI]
;
; Local Variables:  BX - copy of head pointer value
;					CX - copy of element size value
; Shared Variables: myQueue.head - stores head pointer value
;					myQueue.tail - stores tail pointer value
;					myQueue.lngth - stores number of entries in queue
;					myQueue.valsize - stores size of entries
; Global Variables: None
;
; Input:            None
; Output:           None
;
; Error Handling:   None
;
; Registers Changed:flags, AX, BX, CX, DX (BX, CX, DX restored)
; Stack Depth:      0
;
; Algorithms:       None
; Data Structures:  Queue structure
;
; Known Bugs:       None
; Limitations:      None
; Author:           Suzannah Osekowsky
; Last Modified:    12/01/2014

DeQueue		PROC	NEAR
			PUBLIC	DeQueue
SaveVals:
	PUSH	BX			;save values from registers, flags
	PUSH	CX
	PUSH	DX
	PUSHF
GetSize:
	MOV		CX,[SI].valsize			;puts the element size in a register for operations
	CMP		CX,byte1				;compares element size with a byte
	JNE		WordDequeue				;if not a byte, go to word element code
	;JMP	ByteDequeue				;else, go to byte element code
	
ByteDequeue:						;dequeues a byte value
	MOV		BX,[SI].head			;moves the head pointer address into a register
	MOV		CL,[SI].array[BX]		;moves the value from the head of the queue into BL
	MOV		BL,CL					;moves value into BL for storage
	JMP		UpdateHeadPtr			;Go update head pointer
	
WordDequeue:						;dequeues a word value
	MOV		BX,[SI].head			;moves the head pointer address into a register
	MOV		CH,[SI].array[BX]		;moves the high bits of the value from the head of the
									;	 queue into CH
	ADD		BX,byte1				;adds 1 position to BX
	MOV		CL,[SI].array[BX]		;moves the low bits of the value from the head of the 
									;	queue into CL
	MOV		BX,CX					;moves value into BX for storage
	;JMP		UpdateHeadPtr		;Go update head pointer
	
UpdateHeadPtr:
	MOV	AX,[SI].lngth				;puts a copy of the length value into AX
	MUL	[SI].valsize				;multiplies length with value size to find total bytes
	MOV	CX,AX						;moves the total length into CX
	MOV	AX,[SI].head				;moves a copy of the head pointer into AX
	ADD	AX,[SI].valsize				;adds a byte or a word (depending on the element size)
									;	 to the head pointer copy in AX
	MOV	DX,0						;prepare for division
	DIV	CX							;divide the head pointer value by total bytes in queue
	MOV	[SI].head,DX				;loads the remainder. This loops the pointer.
	MOV	AX,BX						;loads the value stored in BX into AX to return
DeQueueDone:
	POPF							;restore flags
	POP	DX							;restore registers
	POP	CX
	POP	BX
	RET 							;returns with the value at the head of the queue in AX
									; or with the zero flag set (if queue was empty)
DeQueue ENDP



;Enqueue
;
; Description:		Adds a value AX to a queue. Assumes that it is called when the queue 
;					is not full. Note that the queue is considered full if the tail 
;					address is the only empty value; i.e., the first empty value is
;					the value immediately preceding the head pointer.
;
; Operation:		Blocking function - loops to check if the queue is full, and when it 
;					finds that the queue is not full, it adds a value AX to the queue and 
;					updates the tail pointer by incrementing it by 1 position and then 
;					taking the modulo of the incremented value and the length.
;
; Arguments:        SI - address a at which queue begins
;					AL/AX - value to add to the queue
; Return Value:     None
;
; Local Variables:  BX - copy of tail pointer value
;					CX - copy of the value to be enqueued
;					DX - copy of element size
; Shared Variables: myQueue.head - stores head pointer value
;					myQueue.tail - stores tail pointer value
; Global Variables: None
;
; Input:            None
; Output:           None
;
; Error Handling:   None
;
; Registers Changed:flags,AX,BX, CX, DX
; Stack Depth:      0
;
; Algorithms:       Increments tail pointer, modulo by length to keep it in the loop
; Data Structures:  Queue structure
;
; Known Bugs:       None
; Limitations:      None
; Author:           Suzannah Osekowsky
; Last Modified:    12/01/2014
	

EnQueue		PROC	NEAR
			PUBLIC	EnQueue
	PUSHA				;save registers,flags because I can
	PUSHF
CheckFull:
	MOV		CX,AX		;saves a copy of the value to be enqueued
	;JMP	GetValSize
GetValSize:
	MOV		DX, [SI].valsize		;moves the size variable into a register for use
	CMP		DX,byte1				;check if the size is a byte
	JNE		WordEnqueue				;if not a byte, go to word element code
	;JMP	ByteEnqueue				;else, go to byte element code
	
ByteEnqueue:
	MOV		BX,[SI].tail			;moves the tail pointer value into a register for use
	MOV		[SI].array[BX],CL		;moves the value from CL into the tail of the queue
	JMP		UpdateTail				;Go update tail pointer
	
WordEnqueue:
	MOV		BX,[SI].tail			;moves tail pointer address into a register for use
	MOV		[SI].array[BX],CH		;moves high bits of the value from CX into the tail
	ADD		BX,byte1				;adds 1 byte to address pointed by BX
	MOV		[SI].array[BX],CL		;moves low bits of the value from CX into the tail
	;JMP	UpdateTail				;Go update tail pointer
	
UpdateTail:
	MOV	AX,[SI].lngth				;puts a copy of the length value into AX
	MUL	[SI].valsize				;multiplies length with value size to find total bytes
	MOV	CX,AX						;moves the total length into CX
	MOV	AX,[SI].tail				;moves a copy of the tail pointer into AX
	ADD	AX,[SI].valsize				;adds a byte or a word (depending on the element size)
									;	 to the tail pointer copy in AX
	MOV	DX,0						;prepare for division
	DIV	CX							;divide the tail pointer value by total bytes in queue
	MOV	[SI].tail,DX				;loads the remainder. This loops the pointer.
	;JMP EndEnqueue

EndEnqueue:
	POPF							;restore flags
	POPA							;restore registers
	RET 							;returns nothing

Enqueue ENDP

CODE	ENDS
END
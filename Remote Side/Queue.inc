;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;										QUEUE.INC										 ;
;									  Include File							   			 ;
;									For making queues								     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;Description: creates useful constants for defining queues, creates a queue template
;
;Revision History:	10/31/2014	Suzannah Osekowsky	initial revision

byte1 			EQU		0001H		;sets "byte" to mean 1 byte
word1 			EQU		0002H		;sets "word" to mean 2 bytes
maxQueueSize	EQU		0200H		;sets the maximum queue length to 512 bytes

;Queue structure
	QUEUE	STRUC							;creates a queue structure with byte elements
		head	DW	?						;creates a shared head pointer variable
		tail	DW	?						;creates a shared tail pointer variable
		valsize	DW	?						;creates a shared variable <QueueName>.size
		lngth	DW	?						;creates a shared variable <QueueName>.length
		array	DB	maxQueueSize	DUP(?)	;allocates (maxQueueSize) bytes of memory 
	QUEUE   ENDS
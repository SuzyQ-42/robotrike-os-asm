;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;								SERIAL.INC												 ;
;					Constants for serial I/O connection									 ;
;							Suzannah Osekowsky											 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains constants for writing to and reading from the serial chip.

;addresses for relevant registers
	SerialBase		EQU		100H			;base address for serial registers
;offsets from serial base
	ReceiverBufReg	EQU	SerialBase + 00H	;contains values to be read by this board
	TransmitterReg	EQU	SerialBase + 00H	;contains values to be transmitted 
											;	(accessible when DLAB low)
	DivLatchLB		EQU	SerialBase + 00H	;contains baud divisor (accessible 
											;	when DLAB high)
    DivLatchHB      EQU SerialBase + 01H    ;contains upper bits of baud divisor 
                                            ;   (accessible when DLAB high)
	IntEnableReg	EQU	SerialBase + 01H	;enables/disables interrupts (accessible when
											;	DLAB low)
	IntIDReg		EQU SerialBase + 02H	;read to determine interrupt status
	LineCtrlReg		EQU	SerialBase + 03H	;write to determine data bits, stop bits, 
											;	and parity
	ModemCtrlReg	EQU	SerialBase + 04H	;contains transmission-related values
	LineStatReg		EQU	SerialBase + 05H	;contains error status of serial connection
	ModemStatReg	EQU	SerialBase + 06H	;status of transmission modem
	ScratchReg		EQU	SerialBase + 07H	;basically a temp variable register
	
;constant indices for setting baud, parity, and other important factors
	PARITY_INDEX    EQU            0    ;default no parity
    BAUD_INDEX      EQU            2    ;default 9600 baud
	CLEAR_PARITY	EQU		11000111B	;AND with LCR value to set no parity
	
	WRITE_DIVISOR	EQU		10000000B	;OR with LCR to enable divisor writing (set DLAB)
	DIVISOR_DONE	EQU		01111111B	;AND with LCR value to clear DLAB (enable register
										;	reading)
										
	SERIAL_8_BIT	EQU		00000011B	;OR with LCR value to set data transmissions to 
										; 8 data bits
	STOP_BITS_2		EQU		00000100B	;OR with LCR value to set 2 stop bits per cycle
	
	INTERRUPTS_ON	EQU		00001111B	;set as IER value to enable interrupts 
    
    CLR_INTERRUPTS  EQU     0B      ;set as IER value to disable interrupts
    
    NO_INTERRUPT    EQU     	01		;use to check if an interrupt is pending
    
;queue constants
    BYTE_QUEUE      EQU     0           ;use to indicate we want a byte queue
    TX_LENGTH       EQU     127         ;make a queue of the maximum length
	
 ;kickstart flag constants
    KS_ON           EQU     0FFH        ;turns kickstarting on
    KS_OFF          EQU     00H         ;turns kickstarting off
	
;event queue constant
	SRL_RECEIVE		EQU		02H			;serial receive token identifier
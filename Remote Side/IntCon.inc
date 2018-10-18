;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;										IntCon.INC										 ;
;						Values of Interrupt Controller Locations						 ;
; 									Suzannah Osekowsky									 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;This file contains definitions for the 80188 interrupt controller.
;
;Revision history:	10/29/2014	Suzannah Osekowsky	initial revision

;Addresses of registers

INT3Ctrl 	EQU PeriphBase + 03EH	;INT3 control register (I3CON)
INT2Ctrl	EQU	PeriphBase + 03CH	;INT2 control register (I2CON)
INT1Ctrl	EQU PeriphBase + 03AH	;INT1 control register (I1CON)
INT0Ctrl	EQU	PeriphBase + 038H	;INT0 control register (I0CON)
DMA1Ctrl	EQU	PeriphBase + 036H	;DMA1 control register (DMA1CON)
DMA0Ctrl	EQU	PeriphBase + 034H	;DMA0 control register (DMA0CON)
TimerCtrl	EQU	PeriphBase + 032H	;Timer control register (TCUCON)
IntStatus	EQU	PeriphBase + 030H	;interrupt status register (INSTS)
IntRequest	EQU	PeriphBase + 02EH	;interrupt request register (REQST)
InService	EQU	PeriphBase + 02CH	;in-service register(INSERV)
PriorityMsk	EQU	PeriphBase + 02AH	;priority mask register (PRIMSK)
IntMaskReg	EQU	PeriphBase + 028H	;interrupt mask register (IMASK)
PollStatus	EQU	PeriphBase + 026H	;poll status register (POLLSTS)
PollReg		EQU	PeriphBase + 024H	;poll register (POLL)
EOIReg		EQU	PeriphBase + 022H	;end-of-interrupt register (EOI)

;Control register definitions
;	Each set of control register definitions includes a mask for masking the high 16 bits  
;	of the interrupts from that source and a mask for setting the priority of that 
;	source's interrupts

;INT0,1 Control Registers (INT0Ctrl,INT1Ctrl)
NestMode	EQU	0000000001000000B	;mask to enable special fully nested mode
CascMode	EQU	0000000000100000B	;mask to enable cascade mode
LevelTrig	EQU	0000000000010000B	;mask to switch between level and edge triggering (if
									;	set,interrupt is level-triggered) (must be set
									;	when cascading inputs)
										
;INT0:3; DMA0:1; Timer Control Registers (INT0Ctrl,INT1Ctrl,INT2Ctrl,INT3Ctrl,DMA0Ctrl,
;DMA1Ctrl,TimerCtrl)
LvlTrig     EQU 0000000000010000B   ;use to set the interrupt as a level interrupt
IntMask		EQU	0000000000001000B	;disables interrupts
Priority	EQU	1111111111111000B	;mask for setting interrupt priority

;Interrupt Request Register
TimerIntRequest	EQU	0000000000000001B	;mask for setting the timer interrupt request bit
DMA0Request		EQU	0000000000000100B	;mask for setting the DMA0 interrupt request bit
DMA1Request		EQU	0000000000001000B	;mask for setting the DMA1 interrupt request bit
INT0Request		EQU	0000000000010000B	;mask for setting the INT0 interrupt request bit
INT1Request		EQU	0000000000100000B	;mask for setting the INT1 interrupt request bit
INT2Request		EQU	0000000001000000B	;mask for setting the INT2 interrupt request bit
INT3Request		EQU	0000000010000000B	;mask for setting the INT3 interrupt request bit

;Interrupt Mask Register (IntMask)
DisableTimerInt	EQU	0000000000000001B	;mask to disable interrupt requests from timer
DisableDMA0Int	EQU	0000000000000100B	;mask to disable interrupt requests from DMA0
DisableDMA1Int	EQU	0000000000001000B	;mask to disable interrupt requests from DMA1
DisableINT0Int	EQU	0000000000010000B	;mask to disable interrupt requests from INT0
DisableINT1Int	EQU	0000000000100000B	;mask to disable interrupt requests from INT1
DisableINT2Int	EQU	0000000001000000B	;mask to disable interrupt requests from INT2
DisableINT3Int	EQU	0000000010000000B	;mask to disable interrupt requests from INT3

;Priority Mask Register (PriorityMsk)
SetPriorityMask	EQU	0000000000000111B	;mask to set priority under which interrupts are 
										;	disabled

;In-Service Register (InService)
ServicingTimer	EQU	0000000000000001B	;mask to indicate a timer int. is being serviced
ServicingDMA0	EQU	0000000000000100B	;mask to indicate a DMA0 int. is being serviced
ServicingDMA1	EQU	0000000000001000B	;mask to indicate a DMA1 int. is being serviced
ServicingINT0	EQU	0000000000010000B	;mask to indicate an INT0 int. is being serviced
ServicingINT1	EQU	0000000000100000B	;mask to indicate an INT1 int. is being serviced
ServicingINT2	EQU	0000000001000000B	;mask to indicate an INT2 int. is being serviced
ServicingINT3	EQU	0000000010000000B	;mask to indicate an INT3 int. is being serviced

;Poll (Status) Register (PollStatus,PollReg)
IntPendingStat		EQU	1000000000000000B	;mask to indicate a pending interrupt
InterruptTypeStat	EQU	0000000000011111B	;mask by which to set the type of the highest 
											;	priority pending interrupt

;End-of-Interrupt Register (EOIReg)
NonSpecificEOI	EQU	100000000000000B	;mask by which to issue a nonspecific EOI command
EOIType			EQU	000000000011111B	;mask by which to issue a specific EOI command

;Interrupt Status Register (IntStatus)
HaltDMA			EQU	1000000000000000B	;suspends DMA activity
Timer0Pending	EQU	0000000000000001B	;indicates pending interrupt from timer 0
Timer1Pending	EQU	0000000000000010B	;indicates pending interrupt from timer 1
Timer2Pending	EQU	0000000000000100B	;indicates pending interrupt from timer 2
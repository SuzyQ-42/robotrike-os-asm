;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;										Timer.INC										 ;
;							 Timer Constants and Addresses								 ;
; 									Suzannah Osekowsky									 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;This file contains definitions for the 80188 interrupt controller.
;
;Revision history:	10/29/2014	Suzannah Osekowsky	initial revision

;Addresses
PeriphBase	EQU	0FF00H				;Peripheral control block starts at default (top 
										;	of I/O space)
										
Timer0Count	EQU	PeriphBase + 050H	;timer 0 count register
Timer0CMPA	EQU	PeriphBase + 052H	;timer 0 compare A register
Timer0CMPB	EQU	PeriphBase + 054H	;timer 0 compare B register
Timer0Ctrl	EQU	PeriphBase + 056H	;timer 0 control register
Timer1Count	EQU	PeriphBase + 058H	;timer 1 count register
Timer1CMPA	EQU	PeriphBase + 05AH	;timer 1 compare A register
Timer1CMPB	EQU	PeriphBase + 05CH	;timer 1 compare B register
Timer1Ctrl	EQU	PeriphBase + 05EH	;timer 1 control register
Timer2Count	EQU	PeriphBase + 060H	;timer 2 count register
Timer2CMPA	EQU	PeriphBase + 062H	;timer 2 compare A register
Timer2Ctrl	EQU	PeriphBase + 066H	;timer 2 control register

;Control Registers: contain instructions and limits for timers. The user can enable/
;					disable timers, read when the timer has reached its maximum count, 
;					choose which register to use for comparing 

;Bits for all control registers (Timer0Ctrl,Timer1Ctrl,Timer2Ctrl)
TimerEnable		EQU	1000000000000000B	;setting this bit enables the timer
TimerInhibit	EQU	0100000000000000B	;cannot enable timer unless this bit is set
TimerInterrupt	EQU	0010000000000000B	;set to enable an interrupt request
TimerMaxCount	EQU	0000000000100000B	;use mask to set when timer has reached its max 
										;count, clear manually
TimerContinuous	EQU	0000000000000001B	;sets timer to run continuously

;Bits only for Timer 0 and Timer 1 control registers (Timer0Ctrl,Timer1Ctrl)
T01CMPRegInUse	EQU	0001000000000000B	;set if CMPB stores high count, clear if CMPA
T01Retrig		EQU	0000000000010000B	;sets what timer does when TMR INx goes from low 
										;	to high - resets count when set, enables 
										;	counting when cleared
T01Prescale		EQU	0000000000001000B	;set to prescale by Timer 2; if cleared, 
										;	increments timer at 1/4 CLKOUT
T01ExtClock		EQU	0000000000000100B	;set to use external clock, clear to use internal
T01AltCMP		EQU	0000000000000010B	;set to specify dual maximum count mode, clear to 
										;	use a single maximum count

;Compare Registers: contain timer maximum counts
;Compare Registers (Timer0CMPA,Timer0CMPB,Timer1CMPA,Timer1CMPB,Timer2CMPA)
TimerMaximum	EQU	1111111111111111B	;OR this with a value to set the timer maximum								
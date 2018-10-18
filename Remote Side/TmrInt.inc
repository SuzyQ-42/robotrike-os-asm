;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            			 ;
;                                  TIMERINT.INC                                			 ;
;                              Timer Event Handler                            			 ;
;                                 Include File                               			 ;
;                                                                           			 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timer event handler.
;
; Revision History:
;		11/05/2014		Suzannah Osekowsky	initial revision
; Timer Definitions

; Control Register Values
Tmr0CtrlVal     EQU     0E001H          ;value to write to Timer 0 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  TMRIN0 is an enable
                                        ;------------00--  don't prescale by timer 2
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode
Tmr1CtrlVal		EQU		0E001H			;value to write to Timer 1 control register
										;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  Enable counting
                                        ;------------00--  don't prescale by timer 2
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode

; Interrupt Vectors
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0
Tmr1Vec         EQU     18              ;interrupt vector for Timer 1

; Interrupt Controller Definitions

; Addresses
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)


; Timing Definitions
COUNTS_PER_MS   EQU     2304            ;number of timer counts per 1 ms (assumes 18.432 
										;	MHz clock)
MOTOR_COUNT		EQU		0240H			;refresh rate of motor speed - set to about 0.25ms
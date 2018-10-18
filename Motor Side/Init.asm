NAME	INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;										INIT.ASM										 ;
;			Procedures for initialization of event handlers and chip selects			 ;
;								  Suzannah Osekowsky									 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Contains general functions to initialize the processor and get it ready for 
; 		InitCS:					writes initial control values to chip selects
;		ClrIRQVectors:			replaces the data in the non-reserved parts of the vector 
;								table with a pointer to the illegal event handler
;		IllegalEventHandler:	clears out the illegal event, returns to code
;
;	Revision History:	11/14/2014	Suzannah Osekowsky	separated from timer initializer

CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
;local include files
$INCLUDE(INIT.INC)		;general initialization constants
$INCLUDE(TMRINT.INC)    ;interrupt controller constants
$INCLUDE(TIMER.INC)     ;processor constants
$INCLUDE(INTCON.INC)    ;constants based on processor interrupt controller

; InitCS
;
; Description:       Initialize the Chip Selects on the 80188.
;
; Operation:         Write the initial values to the PACS and MPCS registers. (LCS, UCS 
;					 assumed initialized)
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Values to chip select registers.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Author:            Suzannah Osekowsky
; Last Modified:     Nov. 7, 2014

InitCS  PROC    NEAR
        PUBLIC  InitCS


        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                     ;done so return


InitCS  ENDP
; ClrIRQVectors
;
; Description:      This functions installs the IllegalEventHandler for all
;                   interrupt vectors in the interrupt vector table.  Note
;                   that all 256 vectors are initialized so the code must be
;                   located above 400H.  The initialization skips  (does not
;                   initialize vectors) from vectors FIRST_RESERVED_VEC to
;                   LAST_RESERVED_VEC.
;
; Operation:		Checks if the current vector is reserved; if not, it replaces whatever
;					data is currently at that place in the vector table with a pointer to 
;					the illegal event handler. Repeats for all 256 vector spots.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX    - vector counter.
;                   ES:SI - pointer to vector table.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, CX, SI, ES
; Stack Depth:      1 word
;
; Author:           Suzannah Osekowsky
; Last Modified:    Nov. 6, 2014

ClrIRQVectors   PROC    NEAR
                PUBLIC  ClrIRQVectors


InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to skip RESERVED_VECS (4 bytes each)

        MOV     CX, 256         ;up to 256 vectors to initialize


ClrVectorLoop:                  ;loop clearing each vector
				;check if should store the vector
	CMP SI, 4 * FIRST_RESERVED_VEC
	JB	DoStore		;if before start of reserved field - store it
	CMP	SI, 4 * LAST_RESERVED_VEC
	JBE	DoneStore	;if in the reserved vectors - don't store it
	;JA	DoStore		;otherwise past them - so do the store

DoStore:                        ;store the vector
    MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
    MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

DoneStore:			;done storing the vector
    ADD     SI, 4   		;update pointer to next vector (each vector is 4 bytes: 2 
							;	bytes indicating the code segment + 2 indicating the 
							;	offset of the handler)
    LOOP    ClrVectorLoop   ;loop until have cleared all vectors
    ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
    RET


ClrIRQVectors   ENDP




; IllegalEventHandler
;
; Description:       This procedure is the event handler for illegal
;                    (uninitialized) interrupts.  It does nothing - it just
;                    returns after sending a non-specific EOI.
;
; Operation:         Send a non-specific EOI and return.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
; Stack Depth:       2 words
;
; Author:            Suzannah Osekowsky
; Last Modified:     11/05/2014

IllegalEventHandler     PROC    NEAR
                        PUBLIC  IllegalEventHandler

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-specific EOI to the
        MOV     AX, NonSpecificEOI      ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the gibberish interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP

CODE	ENDS
END
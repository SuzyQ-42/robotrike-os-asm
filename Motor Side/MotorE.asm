    NAME    EXTRAMTR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                                        ;
;                                      MOTORE.ASM                                        ;
;                   Extra (unused) motor functions for serial parsing                    ;
;                                  Suzannah Osekowsky                                    ;
;                                                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file includes a bunch of functions that do nothing but could do something if I 
; wanted to bother writing them. The functions included are:
;   SetTurretAngle:         Does nothing, returns. Placeholder for turret angle set func
;   SetRelTurretAngle:      Does nothing. Placeholder for turret angle relative set func.
;   SetTurretElevation:     Does nothing. Placeholder for turret elevation set function.
;
;   Revision History:
;       12/12/2014  Suzannah Osekowsky  initial revision

CGROUP	GROUP	CODE
CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

; SetTurretAngle 
;
; Description:		This is a placeholder function in case I ever decide to write a 
;                   function that rotates the turret. In its current state, it does 
;                   nothing and returns.
;
; Operation:		Actually does nothing and returns.
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
; Last Modified:	Dec. 12, 2014     
SetTurretAngle      PROC    NEAR
                    PUBLIC  SetTurretAngle
     NOP    ;actually for real does nothing and returns.
     RET
SetTurretAngle      ENDP

; SetRelTurretAngle 
;
; Description:		This is a placeholder function in case I ever decide to write a 
;                   function that rotates the turret. In its current state, it does 
;                   nothing and returns.
;
; Operation:		Actually does nothing and returns.
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
; Last Modified:	Dec. 12, 2014     
SetRelTurretAngle      PROC    NEAR
                    PUBLIC  SetRelTurretAngle
     NOP    ;actually for real does nothing and returns.
     RET
SetRelTurretAngle      ENDP

; SetTurretElevation 
;
; Description:		This is a placeholder function in case I ever decide to write a 
;                   function that elevates the turret. In its current state, it does 
;                   nothing and returns.
;
; Operation:		Actually does nothing and returns.
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
; Last Modified:	Dec. 12, 2014     
SetTurretElevation      PROC    NEAR
                    PUBLIC  SetTurretElevation
     NOP    ;actually for real does nothing and returns.
     RET
SetTurretElevation      ENDP
       
CODE    ENDS
END
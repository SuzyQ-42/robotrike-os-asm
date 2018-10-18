;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																						 ;
;									KEYFUNC.INC											 ;
;						Constants for the keypad actions								 ;
;								Suzannah Osekowsky										 ;
;																						 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	EOS		EQU		0DH		;carriage returns signal end of transmission
    
 ;indices to serial output string table
    ANG_DEC_INDEX   EQU     0   ;decrement angle in which robot is driving by 1 degree
    ANG_INC_INDEX   EQU     1   ;increment angle in which robot is driving by 1 degree
    STOP_INDEX      EQU     2   ;stop moving
    LASER_ON_INDEX  EQU     3   ;fire laser
    LASER_OFF_INDEX EQU     4   ;turn laser off
    SPEED_DEC_INDEX EQU     5   ;decrement speed by 1
    SPEED_INC_INDEX EQU     6   ;increment speed by 1
    
    
    SERIAL_ENTRY_SIZE   EQU     8   ;I want to be able to output 8 characters at once
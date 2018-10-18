;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                                        ;
;                                 RCVMAIN.INC                                            ;
;               Constants for running receiver-side main loop                            ;
;                            Suzannah Osekowsky                                          ;
;                                                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This file contains constants for running the receiver-side main loop

    EVENT_QUEUE_LENGTH      EQU     255     ;maximum length for event queue
	EOS						EQU		0DH		;carriage return = end of transmission char
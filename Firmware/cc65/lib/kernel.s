; Kernel Functions for S65xx Computer System
; Author: Synthron
; 
; Ringbuffer Input Code by Ben Eater
;
;

READ_PTR = $EC
WRITE_PTR = $ED

.segment "BSS"

INPUT_BUFFER:   .res $100


.segment "KERNEL_ROM"

; ------------------------------------------------------------------------
; Input Buffer Code
; ------------------------------------------------------------------------

; Initialize the circular input buffer
; Modifies: flags, A
INIT_BUFFER:
    lda READ_PTR
    sta WRITE_PTR
    rts

; Write a character (from the A register) to the circular input buffer
; Modifies: flags, X
WRITE_BUFFER:
    ldx WRITE_PTR
    sta INPUT_BUFFER,x
    inc WRITE_PTR
    rts

; Read a character from the circular input buffer and put it in the A register
; Modifies: flags, A, X
READ_BUFFER:
    ldx READ_PTR
    lda INPUT_BUFFER,x
    inc READ_PTR
    rts

; Return (in A) the number of unread bytes in the circular input buffer
; Modifies: flags, A
BUFFER_SIZE:
    lda WRITE_PTR
    sec
    sbc READ_PTR
    RTS
    
; ------------------------------------------------------------------------
; Data Storage Code
; ------------------------------------------------------------------------

LOAD:
    rts
    
SAVE:
    rts
    
; ------------------------------------------------------------------------
; COM1 Default Char In Out Code
; ------------------------------------------------------------------------

; Input a character from the serial interface.
; On return, carry flag indicates whether a key was pressed
; If a key was pressed, the key value will be in the A register
;
; Modifies: flags, A
CHRIN:
    phx
    jsr     BUFFER_SIZE
    beq     @no_keypressed
    jsr     READ_BUFFER
    jsr     CHROUT                  ; echo
    plx
    sec
    rts
@no_keypressed:
    plx
    clc
    rts


; Output a character (from the A register) to the serial interface.
;
; Modifies: flags
CHROUT:
    jsr COM1_TRANSMIT
    rts
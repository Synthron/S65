.setcpu "65c02"

.include "pia.s"
.include "via.s"
.include "tpi.s"
.include "acia.s"
.include "sid.s"

.include "kernel.s"

.segment "CODE"
RESET:
    ldx #$FF            ; Reset Stack Pointer
    txs

BOOT:
    jsr COM1_INIT       ; initialize COM1 Serial
    jsr PIA_INIT
    CLI
    
PRINT_MOT:
    ldx #0              ; prepare X register
@print_mot:
    lda BOOT_MSG,X      ; get boot message character
    beq PREPRAM
    jsr COM1_TRANSMIT
    inx
    jmp @print_mot
    
PREPRAM:
    lda #<COM1_TRANSMIT ; jump address for transmit in RAM
    sta $300
    lda #>COM1_TRANSMIT
    sta $301


MAIN_LOOP:
    jmp RESET_MONITOR
    jmp MAIN_LOOP

.segment "ISRS"

ISR:
    ; for now just assume COM1 is the only Interrupt Source
    ; Other sources will be added later and checked during ISR runtime
    pha
    phx
    lda COM1_STAT
    lda COM1_DATA
    jsr WRITE_BUFFER
    plx
    pla
    rti
NMI:
    rti

    
.include "wozmon.s"

.segment "RODATA"

HELLO_WORLD: .asciiz "Hello World\n"
BOOT_MSG:    .asciiz "Welcome to the S65xx Computer System!\n"

.segment "VECTORS"
.word NMI
.word RESET
.word ISR

.segment "EHBASIC"
; input vector          $0805 $0806
; output vector         $0807 $0808
; load vector           $0809 $080A
; save vector           $080B $080C
.include "ehbasic.s"
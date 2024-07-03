.setcpu "65c02"
.debuginfo

.include "macros.s"
.include "io.s"
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
    jsr TPI_INIT        ; initialize banks and interrupt
    jsr COM1_INIT       ; initialize COM1 Serial
    jsr PIA_INIT        ; initialize LED port
    cli                 ; clear interrupt disable flag
    
; print Boot Messagr
    cpt BOOT_MSG
    jsr PRINT_MSG

; print Kernel Transfer Messagr
    cpt BOOT_TKERN
    jsr PRINT_MSG


    ldx #<EHBASIC_TABLE_END
PREPRAM:
    lda EHBASIC_TABLE_START,x
    sta ccflag,x
    dex
    beq PREPRAM

; 
; Transfer Kernel Code from ROM to RAM
; Kernel in ROM is Page Aligned, so whole pages will be copied,
; regardless whether useful or not
;
CPY_KERNEL:
    lda #$00            ; Kernel sits at C000 in ROM, get start address
    sta $00
    lda #$C0
    sta $01
    lda #0              ; Copy Kernel code to RAM starting at 0300
    sta $02
    lda #3
    sta $03
    ldx #3              ; load last kernel page into X, current assumption is only one page
    ldy #0              ; reset Y
CPY_KERNEL_LOOP:
    lda ($00),y         ; iterate through KERNEL page and copy into RAM
    sta ($02),y
    iny
    bne CPY_KERNEL_LOOP ; check if Y had rollover (256 bytes copied, Y back to 0)
    cpx $03             ; check if last page reached
    beq @end            ; done when Zero Flag Set (X = value)
    inc $03             ; else increment destination page pointer
    inc $01             ; as well as source page pointer
    jmp CPY_KERNEL_LOOP ; start copying next page
@end:

; print Kernel Transfer done
    cpt MSG_DONE
    jsr PRINT_MSG

; print WozMon Start Message
    cpt MSG_MONITOR
    jsr PRINT_MSG

MAIN_LOOP:
    jmp RESET_MONITOR
    jmp MAIN_LOOP

.segment "KERNEL_RAM"

ISR:
    ; for now just assume COM1 is the only Interrupt Source
    ; Other sources will be added later and checked during ISR runtime
    pha
    phx
    lda COM1_STAT       ; clear IRQ from ACIA
    lda TPI1_AIR        ; clear IRQ from TPI
    lda COM1_DATA       ; get received character
    jsr WRITE_BUFFER    ; write character into Input buffer
    plx
    pla
    rti
NMI:
    rti

.segment "JP_TBLE"

LBL_XX00:               ; start EhBASIC
    lda #1
    jmp SW_ROMBANK
LBL_XX05:               ; start MS BASIC CDM2
    lda #2
    jmp SW_ROMBANK
    
.include "wozmon.s"

.segment "RODATA"

HELLO_WORLD: .asciiz "Hello World\n"
BOOT_MSG:    .asciiz "Welcome to the S65xx Computer System!\n\n"
BOOT_TKERN:  .asciiz "Transfer KERNEL to RAM... "
MSG_MONITOR: .asciiz "Starting up WozMon:\n"
MSG_DONE:    .asciiz "done!\n"

EHBASIC_TABLE_START:
    .byte 0             ; dummy bytes for padding
    .byte 0
    .byte 0
    .word $C000         ; Control-C function vector, currently restart BASIC
    .word CHRIN         ; Character In function pointer
    .word CHROUT        ; Character Out function pointer
    .word $C000         ; LOAD function pointer, currently restart BASIC
    .word $C000         ; SAVE function pointer, currently restart BASIC
EHBASIC_TABLE_END:

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
TPI1_PRA   = TPI1 + 0
TPI1_PRB   = TPI1 + 1
TPI1_PRC   = TPI1 + 2
TPI1_DDRA  = TPI1 + 3
TPI1_DDRB  = TPI1 + 4
TPI1_DDRC  = TPI1 + 5
TPI1_CR    = TPI1 + 6
TPI1_AIR   = TPI1 + 7

IDE1_PRA   = IDE1 + 0
IDE1_PRB   = IDE1 + 1
IDE1_PRC   = IDE1 + 2
IDE1_DDRA  = IDE1 + 3
IDE1_DDRB  = IDE1 + 4
IDE1_DDRC  = IDE1 + 5
IDE1_CR    = IDE1 + 6
IDE1_AIR   = IDE1 + 7

TPI_INIT:
    lda #0          ; reset Bank Registers
    sta TPI1_DDRA
    sta TPI1_DDRB
    lda #$FF        ; set Bank Register Ports to output
    sta TPI1_PRA
    sta TPI1_PRB
    lda #$A1     ; CB and CA low, no priority, Port C Interrupt Mode
    sta TPI1_CR
    lda #$1F        ; enable all interrupts
    sta TPI1_DDRC
    rts

IDE_INIT:
    lda #0          ; reset all pins
    sta IDE1_DDRA
    sta IDE1_DDRB
    sta IDE1_DDRC
    lda #$FF        ; set Register Ports to output
    sta IDE1_PRA
    sta IDE1_PRB
    sta IDE1_PRC
    rts
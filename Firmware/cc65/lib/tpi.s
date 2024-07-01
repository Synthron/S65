.import __TPI1_START__
.import __IDE1_START__

TPI1_PRA   = __TPI1_START__ + 0
TPI1_PRB   = __TPI1_START__ + 0
TPI1_PRC   = __TPI1_START__ + 0
TPI1_DDRA  = __TPI1_START__ + 0
TPI1_DDRB  = __TPI1_START__ + 0
TPI1_DDRC  = __TPI1_START__ + 0
TPI1_CR    = __TPI1_START__ + 0
TPI1_AIR   = __TPI1_START__ + 0

IDE1_PRA   = __IDE1_START__ + 0
IDE1_PRB   = __IDE1_START__ + 0
IDE1_PRC   = __IDE1_START__ + 0
IDE1_DDRA  = __IDE1_START__ + 0
IDE1_DDRB  = __IDE1_START__ + 0
IDE1_DDRC  = __IDE1_START__ + 0
IDE1_CR    = __IDE1_START__ + 0
IDE1_AIR   = __IDE1_START__ + 0

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
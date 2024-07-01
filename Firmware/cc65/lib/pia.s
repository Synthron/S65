.import __PIA_START__

; PIA = LEDs

PORTA_PIA = __PIA_START__ + 0
CRA_PIA   = __PIA_START__ + 1
PORTB_PIA = __PIA_START__ + 2
CRB_PIA   = __PIA_START__ + 3

PIA_DDR   = $00 ; config value for DDR Register
PIA_PORT  = $04 ; config value for PORT Register

    .segment "CODE"

PIA_INIT: 
    lda #PIA_DDR
    sta CRA_PIA
    sta CRB_PIA

    lda #$ff
    sta PORTA_PIA
    sta PORTB_PIA

    lda #PIA_PORT
    sta CRA_PIA
    sta CRB_PIA
    rts
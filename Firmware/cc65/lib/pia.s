; PIA = LEDs

PORTA_PIA = PIA + 0
CRA_PIA   = PIA + 1
PORTB_PIA = PIA + 2
CRB_PIA   = PIA + 3

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
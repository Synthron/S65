.import __VIA1_START__
.import __VIA2_START__
.import __VIA3_START__

;initialize VIA1 with IRQ and LCD
PORTB1   = __VIA1_START__ + 0
PORTA1   = __VIA1_START__ + 1
DDRB1    = __VIA1_START__ + 2
DDRA1    = __VIA1_START__ + 3
VIA1_PCR = __VIA1_START__ + 12
VIA1_IFR = __VIA1_START__ + 13
VIA1_IER = __VIA1_START__ + 14
;initialize VIA2 
PORTB2   = __VIA2_START__ + 0
PORTA2   = __VIA2_START__ + 1
DDRB2    = __VIA2_START__ + 2
DDRA2    = __VIA2_START__ + 3
VIA2_PCR = __VIA2_START__ + 12
VIA2_IFR = __VIA2_START__ + 13
VIA2_IER = __VIA2_START__ + 14
;initialize VIA3 
PORTB3   = __VIA3_START__ + 0
PORTA3   = __VIA3_START__ + 1
DDRB3    = __VIA3_START__ + 2
DDRA3    = __VIA3_START__ + 3
VIA3_PCR = __VIA3_START__ + 12
VIA3_IFR = __VIA3_START__ + 13
VIA3_IER = __VIA3_START__ + 14
; PCR
; bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0
; |    CB2     | CB1  |    CA2     | CA1
;  1    1    0    0    1    1    0    0     
; set CB2 out low, CB1 negative edge, CA2 out low, CA1 negative edge
; IER
; bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0
; S/C   T1   T2  CB1  CB2  SHR  CA1  CA2
; 1     0    0    1    0    0    0    0
; IFR
; bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0
; IRQ  TIM1 TIM2 CB1  CB2  SR   CA1  CA2

.rodata


VIA1_Init:
    lda #0          ; Reset Port A
    sta PORTA1
    lda #$FF        ; Port A to output for LCD
    sta DDRA1       
    lda #$7F         ; disable all interrupts
    sta VIA1_IER
    lda #$CC        ; Cx2 Out Low, Cx1 Interrupt falling edge
    sta VIA1_PCR
    lda #$90        ; Enable Interrupt on CB1 active edge
    sta VIA1_IER
    rts

VIA2_Init:
    lda #0          ; set all pins Input
    sta DDRA2
    sta DDRB2
    lda #$7F        ; disable all interrupts
    sta VIA2_IER
    rts

VIA3_Init:
    lda #0          ; set all pins Input
    sta DDRA3
    sta DDRB3
    lda #$7F        ; disable all interrupts
    sta VIA3_IER
    rts


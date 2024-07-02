; Registers ACIA1
COM1_DATA  = ACIA1 + 0
COM1_STAT  = ACIA1 + 1
COM1_CMD   = ACIA1 + 2
COM1_CTRL  = ACIA1 + 3
; Registers ACIA2
COM2_DATA  = ACIA2 + 0
COM2_STAT  = ACIA2 + 1
COM2_CMD   = ACIA2 + 2
COM2_CTRL  = ACIA2 + 3
; Registers ACIA3
COM3_DATA  = ACIA3 + 0
COM3_STAT  = ACIA3 + 1
COM3_CMD   = ACIA3 + 2
COM3_CTRL  = ACIA3 + 3
; Registers ACIA4
COM4_DATA  = ACIA4 + 0
COM4_STAT  = ACIA4 + 1
COM4_CMD   = ACIA4 + 2
COM4_CTRL  = ACIA4 + 3

; ZeroPage Variable for TxReady-Check
ZP_WAIT = $E2

; STAT-REG bits (MSB left): IRQ | /DSR | /DCD | TDRE | RDRF | OVRN | FE | PE
; IRQ: goes High on Interrupt
; DSR = Data Set Ready (Low = Ready)
; DCD = Data Carrier Detect (Low = detected)
; TDRE = Transmitter Data Register Empty (1 = Empty)
; RDRF = Receiver Data Register Full (1 = Full)
; OVRN = Overrun (1 = Overrun occurred)
; FE = Framing Error (1 = Framing Error detected)
; PE = Parity Error (1 = Parity Error detected)
; OVRN, FE, PE do not trigger interrupts
; RESET-Value 0b0--10000

; CTL-REG bits (MSB left): SBN | WL1-WL0 | RCS | SBR3-SBR0
; SBN = Stop Bit Number (0 = 1bit, 1 = 2bit, 0 = 1.5bit for WL 5 no parity, 1 = 1bit for WL 8 + parity)
; WL = Word Length (00 = 8, 01 = 7, 10 = 6, 11 = 5)
; RCS = Receiver Clock Source (0 = External Receiver Clock, 1 = Baud Rate Generator)
; SBR = Sleceted Baud Rate
; common SBR values: 1000 = 1200, 1110 = 9600, 1111 = 19.200
; RESET-Value 0b00000000

; CMD-REG bits (MSB left): PMC1-PMC0 | PME | REM | TIC1-TIC0 | IRD | DTR
; PMC = Parity Mode Control (00=odd, 01=even, 10=mark transmitted- check disabled, 11=space transmitted- check disabled)
; PME = Parity Mode Enabled (0 = no parity generated - check disabled, 1 = parity enabled)
; REM = Receiver Echo Mode (0=normal, 1=echo bits 2 and 3)
; TIC = Transmitter Interrupt Control (00 = RTS high-transmitter disabled, 01 = RTS low-transmit interrupt enabled, 10 = RTS low- transmit interrupt disabled, 11 = RTS low, transmit interrupt desabled - transmit break on TxD)
; IRD = Receiver Interrupt Request Disabled (0 = IRQ enabled (receiver), 1 = IRQ disabled (receiver))
; DTR = Data Terminal Ready (0 = not ready, 1 = ready) (Enables Transmitter + Receiver)
; RESET-Value 0b00000000

; Initializations
COM1_INIT:         
    lda #$0         ; soft reset
    sta COM1_STAT
    lda #%10001001  ; Enable Receive Interrupt, diable parity, enable Tx and Rx
    sta COM1_CMD
;   lda #%00011111  ; setup 8N1 communication at 19200 Baud
    lda #%00011110  ; setup 8N1 communication at 9600 Baud
    sta COM1_CTRL
    rts

COM2_INIT:
    lda #$0         ; soft reset
    sta COM2_STAT
    lda #%10001001  ; Enable Receive Interrupt, diable parity, enable Tx and Rx
    sta COM2_CMD
;   lda #%00011111  ; setup 8N1 communication at 19200 Baud
    lda #%00011110  ; setup 8N1 communication at 9600 Baud
    sta COM2_CTRL    
    rts

COM3_INIT:         
    lda #$0         ; soft reset
    sta COM3_STAT
    lda #%10001001  ; Enable Receive Interrupt, diable parity, enable Tx and Rx
    sta COM3_CMD
;   lda #%00011111  ; setup 8N1 communication at 19200 Baud
    lda #%00011110  ; setup 8N1 communication at 9600 Baud
    sta COM3_CTRL
    rts

COM4_INIT:
    lda #$0         ; soft reset
    sta COM4_STAT
    lda #%10001001  ; Enable Receive Interrupt, diable parity, enable Tx and Rx
    sta COM4_CMD
;   lda #%00011111  ; setup 8N1 communication at 19200 Baud
    lda #%00011110  ; setup 8N1 communication at 9600 Baud
    sta COM4_CTRL    
    rts

.segment "KERNEL_RAM"

COM1_TRANSMIT:
    pha
TX1READY:           ; check if ready to send next byte
    lda COM1_STAT   
    sta ZP_WAIT
    BBR4 ZP_WAIT,TX1READY
    pla
    sta COM1_DATA
    rts

COM2_TRANSMIT:
    pha
TX2READY:           ; check if ready to send next byte
    lda COM2_STAT
    sta ZP_WAIT
    BBR4 ZP_WAIT,TX2READY
    pla
    sta COM2_DATA
    rts

COM3_TRANSMIT:
    pha
TX3READY:           ; check if ready to send next byte
    lda COM3_STAT   
    sta ZP_WAIT
    BBR4 ZP_WAIT,TX3READY
    pla
    sta COM3_DATA
    rts

COM4_TRANSMIT:
    pha
TX4READY:           ; check if ready to send next byte
    lda COM4_STAT
    sta ZP_WAIT
    BBR4 ZP_WAIT,TX4READY
    pla
    sta COM4_DATA
    rts

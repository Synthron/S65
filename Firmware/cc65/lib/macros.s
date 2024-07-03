; ---------------------------------------------
; Macro to write the String Pointer for the 
; PRINT_MSG function to Zero Page
; ---------------------------------------------
.macro cpt addr
    lda #<addr   ; low byte
    sta $EC
    lda #>addr   ; high byte
    sta $ED
.endmacro
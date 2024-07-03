; Single-File Port from https://github.com/mist64/msbasic
; with some small influence by Ben Eaters fork
;
; ToDo:
;   - remove system-specific code, that doesn't match S65
;     - Investigate CBM1
;     - Investigate CBM2
;     - Investigate CONFIG_CBM_ALL
; Done:
;   - remove CONFIG_SMALL code reductions
;   - applied all CONFIG_2C and lower (most recent MS BASIC version)
;
; Goal:
; have MS Basic on a working stand as a single file to include. 
; I don't care about "byte-identical" compilation

.feature force_range
;.debuginfo +

;.setcpu "6502"
.macpack longbranch

; MS BASIC Defines (copied from CBM2-Defines)

;CONFIG_DATAFLG := 1
CONFIG_EASTER_EGG := 1
;CONFIG_FILE := 1; support PRINT#, INPUT#, GET#, CMD
CONFIG_NO_CR := 1; terminal doesn't need explicit CRs on line ends
;CONFIG_NO_LINE_EDITING := 1; support for "@", "_", BEL etc.
;CONFIG_NO_READ_Y_IS_ZERO_HACK := 1
;CONFIG_PEEK_SAVE_LINNUM := 1
CONFIG_SCRTCH_ORDER := 2


ZP_START0 = $00
ZP_START1 = $02
ZP_START2 = $0C
ZP_START3 = $62
ZP_START4 = $6D

; extra/override ZP variables
;CURDVC			:= $000E
;TISTR			:= $008D
;Z96				:= $0096
;POSX			:= $00C6
;TXPSV			:= LASTOP
USR				:= GORESTART ; XXX

;CBM2 := 1
;CONFIG_CBM_ALL := 1

; inputbuffer
;INPUTBUFFER     := $0200

; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP		:= $FA
WIDTH			:= 40
WIDTH2			:= 30

RAMSTART2		:= $0900

; magic memory locations
;ENTROPY = $E844

; monitor functions
;OPEN	:= $FFC0
;CLOSE	:= $FFC3
;CHKIN	:= $FFC6
;CHKOUT	:= $FFC9
;CLRCH	:= $FFCC
;LOAD	:= $FFD5
;SAVE	:= $FFD8
;VERIFY	:= $FFDB
;SYS	:= $FFDE
;ISCNTC	:= $FFE1
;GETIN	:= $FFE4
;CLALL	:= $FFE7
;LE7F3	:= $E7F3; for CBM1
MONCOUT	:= CHROUT
MONRDKEY := CHRIN

BYTES_FP		:= 5

.ifndef BYTES_PER_ELEMENT
BYTES_PER_ELEMENT := BYTES_FP
.endif
BYTES_PER_VARIABLE := BYTES_FP+2
MANTISSA_BYTES	:= BYTES_FP-1
BYTES_PER_FRAME := 2*BYTES_FP+8
FOR_STACK1		:= 2*BYTES_FP+5
FOR_STACK2		:= BYTES_FP+4

.ifndef MAX_EXPON
MAX_EXPON = 10
.endif

STACK           := $0100
.ifndef STACK2
STACK2          := STACK
.endif

.ifdef INPUTBUFFER
  .if INPUTBUFFER >= $0100
CONFIG_NO_INPUTBUFFER_ZP := 1
  .endif
  .if INPUTBUFFER = $0200
CONFIG_INPUTBUFFER_0200 := 1
  .endif
.endif
INPUTBUFFERX = INPUTBUFFER & $FF00

CR=13
LF=10

.ifndef CRLF_1
CRLF_1 := CR
CRLF_2 := LF
.endif

; Macros included for MS BASIC

; htasc - set the hi bit on the last byte of a string for termination
; (by Tom Greene)
.macro htasc str
	.repeat	.strlen(str)-1,I
		.byte	.strat(str,I)
	.endrep
	.byte	.strat(str,.strlen(str)-1) | $80
.endmacro

; For every token, a byte gets put into segment "DUMMY".
; This way, we count up with every token. The DUMMY segment
; doesn't get linked into the binary.
.macro init_token_tables
        .segment "MSBVECTORS"
TOKEN_ADDRESS_TABLE:
        .segment "MSBKEYWORDS"
TOKEN_NAME_TABLE:
		.segment "MSBDUMMY"
DUMMY_START:
.endmacro

; optionally define token symbol
; count up token number
.macro define_token token
        .segment "MSBDUMMY"
		.ifnblank token
			token := <(*-DUMMY_START)+$80
		.endif
		.res 1; count up in any case
.endmacro

; lay down a keyword, optionally define a token symbol
.macro keyword key, token
		.segment "MSBKEYWORDS"
		htasc	key
		define_token token
.endmacro

; lay down a keyword and an address (RTS style),
; optionally define a token symbol
.macro keyword_rts key, vec, token
        .segment "MSBVECTORS"
		.word	vec-1
		keyword key, token
.endmacro

; lay down a keyword and an address,
; optionally define a token symbol
.macro keyword_addr key, vec, token
        .segment "MSBVECTORS"
		.addr	vec
		keyword key, token
.endmacro

.macro count_tokens
        .segment "MSBDUMMY"
		NUM_TOKENS := <(*-DUMMY_START)
.endmacro

.macro init_error_table
        .segment "MSBERROR"
ERROR_MESSAGES:
.endmacro

.macro define_error error, msg
        .segment "MSBERROR"
		error := <(*-ERROR_MESSAGES)
		htasc msg
.endmacro

;---------------------------------------------
; set the MSB of every byte of a string
.macro asc80 str
	.repeat	.strlen(str),I
		.byte	.strat(str,I)+$80
	.endrep
.endmacro

; MS BASIC ZP definitions

.feature org_per_seg
.zeropage

.org ZP_START1

GORESTART:
	.res 3      ; 0
GOSTROUT:
	.res 3      ; 3
GOAYINT:
	.res 2      ; 6
GOGIVEAYF:
	.res 2      ; 8

.org ZP_START2
Z15:
	.res 1      ; 10
.ifndef POSX; allow override
POSX:
.endif
	.res 1      ; 11
.ifndef Z17; allow override
Z17:
.endif
	.res 1      ; 12
.ifndef Z18; allow override
Z18:
.endif
	.res 1      ; 13
LINNUM:
.ifndef TXPSV; allow override
TXPSV:
.endif
	.res 2      ; 14
.ifndef INPUTBUFFER; allow override
INPUTBUFFER:
.endif

.org ZP_START3

CHARAC:
	.res 1      ; 16
ENDCHR:
	.res 1      ; 17
EOLPNTR:
	.res 1      ; 18
DIMFLG:
	.res 1      ; 19
VALTYP:
	.res 2      ; 20
DATAFLG:
	.res 1      ; 22
SUBFLG:
	.res 1      ; 23
INPUTFLG:
	.res 1      ; 24
CPRMASK:
	.res 1      ; 25
Z14:
	.res 1      ; 26

.org ZP_START4

TEMPPT:
	.res 1      ; 27
LASTPT:
	.res 2      ; 28
TEMPST:
	.res 9      ; 30
INDEX:
	.res 2      ; 39
DEST:
	.res 2      ; 41
RESULT:
	.res BYTES_FP
RESULT_LAST = RESULT + BYTES_FP-1
TXTTAB:
	.res 2
VARTAB:
	.res 2
ARYTAB:
	.res 2
STREND:
	.res 2
FRETOP:
	.res 2
FRESPC:
	.res 2
MEMSIZ:
	.res 2
CURLIN:
	.res 2
OLDLIN:
	.res 2
OLDTEXT:
	.res 2
Z8C:
	.res 2
DATPTR:
	.res 2
INPTR:
	.res 2
VARNAM:
	.res 2
VARPNT:
	.res 2
FORPNT:
	.res 2
LASTOP:
	.res 2
CPRTYP:
	.res 1
FNCNAM:
TEMP3:
	.res 2
DSCPTR:
		.res 3
DSCLEN:
	.res 2
.ifndef JMPADRS ; allow override
JMPADRS			:= DSCLEN + 1
.endif
Z52:
	.res 1
ARGEXTENSION:
	.res 1
TEMP1:
	.res 1
HIGHDS:
	.res 2
HIGHTR:
	.res 2
TEMP2:
	.res 1
INDX:
TMPEXP:
	.res 1
EXPON:
	.res 1
LOWTR:
.ifndef LOWTRX ; allow override
LOWTRX:
.endif
	.res 1
EXPSGN:
	.res 1
FAC:
	.res BYTES_FP
FAC_LAST = FAC + BYTES_FP-1
FACSIGN:
	.res 1
SERLEN:
	.res 1
SHIFTSIGNEXT:
	.res 1
ARG:
	.res BYTES_FP
ARG_LAST = ARG + BYTES_FP-1
ARGSIGN:
	.res 1
STRNG1:
	.res 2
SGNCPR = STRNG1
FACEXTENSION = STRNG1+1
STRNG2:
	.res 2


CHRGET:
TXTPTR = <(GENERIC_TXTPTR-GENERIC_CHRGET + CHRGET)
CHRGOT = <(GENERIC_CHRGOT-GENERIC_CHRGET + CHRGET)
CHRGOT2 = <(GENERIC_CHRGOT2-GENERIC_CHRGET + CHRGET)
RNDSEED = <(GENERIC_RNDSEED-GENERIC_CHRGET + CHRGET)

;.include "S65x_conf.s"

.segment "MSBHEADER"
    jmp COLD_START

;.include "token.s"

		init_token_tables

		keyword_rts "END", END
		keyword_rts "FOR", FOR
		keyword_rts "NEXT", NEXT
		keyword_rts "DATA", DATA
.ifdef CONFIG_FILE
		keyword_rts "INPUT#", INPUTH
.endif
		keyword_rts "INPUT", INPUT
		keyword_rts "DIM", DIM
		keyword_rts "READ", READ
		keyword_rts "LET", LET
		keyword_rts "GOTO", GOTO, TOKEN_GOTO
		keyword_rts "RUN", RUN
		keyword_rts "IF", IF
		keyword_rts "RESTORE", RESTORE
		keyword_rts "GOSUB", GOSUB, TOKEN_GOSUB
		keyword_rts "RETURN", POP
		keyword_rts "REM", REM, TOKEN_REM
		keyword_rts "STOP", STOP
		keyword_rts "ON", ON
;.ifdef CONFIG_NULL
;		keyword_rts "NULL", NULL
;.endif
.ifndef CONFIG_NO_POKE
		keyword_rts "WAIT", WAIT
.endif
		keyword_rts "LOAD", LOAD
		keyword_rts "SAVE", SAVE
;.ifdef CONFIG_CBM_ALL
;		keyword_rts "VERIFY", VERIFY
;.endif
		keyword_rts "DEF", DEF
.ifndef CONFIG_NO_POKE
		keyword_rts "POKE", POKE
.endif
.ifdef CONFIG_FILE
		keyword_rts "PRINT#", PRINTH
.endif
		keyword_rts "PRINT", PRINT, TOKEN_PRINT
		keyword_rts "CONT", CONT
		keyword_rts "LIST", LIST
;.ifdef CONFIG_CBM_ALL
;		keyword_rts "CLR", CLEAR
;.else
		keyword_rts "CLEAR", CLEAR
;.endif
.ifdef CONFIG_FILE
		keyword_rts "CMD", CMD
		keyword_rts "SYS", SYS
		keyword_rts "OPEN", OPEN
		keyword_rts "CLOSE", CLOSE
.endif
		keyword_rts "GET", GET
		keyword_rts "NEW", NEW

		count_tokens

		keyword	"TAB(", TOKEN_TAB
		keyword	"TO", TOKEN_TO
		keyword	"FN", TOKEN_FN
		keyword	"SPC(", TOKEN_SPC
		keyword	"THEN", TOKEN_THEN
		keyword	"NOT", TOKEN_NOT
		keyword	"STEP", TOKEN_STEP
		keyword	"+", TOKEN_PLUS
		keyword	"-", TOKEN_MINUS
		keyword	"*"
		keyword	"/"
		keyword	"^"
		keyword	"AND"
		keyword	"OR"
		keyword	">", TOKEN_GREATER
		keyword	"=", TOKEN_EQUAL
		keyword	"<"

        .segment "MSBVECTORS"
UNFNC:

		keyword_addr "SGN", SGN, TOKEN_SGN
		keyword_addr "INT", INT
		keyword_addr "ABS", ABS
.ifndef CONFIG_NO_POKE
  .ifdef CONFIG_RAM
		keyword_addr "USR", IQERR
  .else
		keyword_addr "USR", USR, TOKEN_USR
  .endif
.endif
		keyword_addr "FRE", FRE
		keyword_addr "POS", POS
		keyword_addr "SQR", SQR
		keyword_addr "RND", RND
		keyword_addr "LOG", LOG
		keyword_addr "EXP", EXP
.segment "MSBVECTORS"
UNFNC_COS:
		keyword_addr "COS", COS
.segment "MSBVECTORS"
UNFNC_SIN:
		keyword_addr "SIN", SIN
.segment "MSBVECTORS"
UNFNC_TAN:
		keyword_addr "TAN", TAN
.segment "MSBVECTORS"
UNFNC_ATN:
		keyword_addr "ATN", ATN
.ifndef CONFIG_NO_POKE
		keyword_addr "PEEK", PEEK
.endif
		keyword_addr "LEN", LEN
		keyword_addr "STR$", STR
		keyword_addr "VAL", VAL
		keyword_addr "ASC", ASC
		keyword_addr "CHR$", CHRSTR
		keyword_addr "LEFT$", LEFTSTR, TOKEN_LEFTSTR
		keyword_addr "RIGHT$", RIGHTSTR
		keyword_addr "MID$", MIDSTR
		keyword	"GO", TOKEN_GO
        .segment "MSBKEYWORDS"
		.byte   0

        .segment "MSBVECTORS"
MATHTBL:
        .byte   $79
        .word   FADDT-1
        .byte   $79
        .word   FSUBT-1
        .byte   $7B
        .word   FMULTT-1
        .byte   $7B
        .word   FDIVT-1
        .byte   $7F
        .word   FPWRT-1
        .byte   $50
        .word   TAND-1
        .byte   $46
        .word   OR-1
        .byte   $7D
        .word   NEGOP-1
        .byte   $5A
        .word   EQUOP-1
        .byte   $64
        .word   RELOPS-1

; .include "error.s"

init_error_table

define_error ERR_NOFOR, "NEXT WITHOUT FOR"
define_error ERR_SYNTAX, "SYNTAX"
define_error ERR_NOGOSUB, "RETURN WITHOUT GOSUB"
define_error ERR_NODATA, "OUT OF DATA"
define_error ERR_ILLQTY, "ILLEGAL QUANTITY"
.ifdef CBM1
	.byte 0,0,0,0,0
.endif
define_error ERR_OVERFLOW, "OVERFLOW"
define_error ERR_MEMFULL, "OUT OF MEMORY"
define_error ERR_UNDEFSTAT, "UNDEF'D STATEMENT"
define_error ERR_BADSUBS, "BAD SUBSCRIPT"
define_error ERR_REDIMD, "REDIM'D ARRAY"
define_error ERR_ZERODIV, "DIVISION BY ZERO"
define_error ERR_ILLDIR, "ILLEGAL DIRECT"
define_error ERR_BADTYPE, "TYPE MISMATCH"
define_error ERR_STRLONG, "STRING TOO LONG"
.ifdef CONFIG_FILE
  .ifdef CBM1
define_error ERR_BADDATA, "BAD DATA"
  .else
define_error ERR_BADDATA, "FILE DATA"
  .endif
.endif
define_error ERR_FRMCPX, "FORMULA TOO COMPLEX"
define_error ERR_CANTCONT, "CAN'T CONTINUE"
define_error ERR_UNDEFFN, "UNDEF'D FUNCTION"

; .include "message.s"

; global messages: "error", "in", "ready", "break"

.segment "MSBCODE"

QT_ERROR:
    .byte   " ERROR"
    .byte   0

QT_IN:
    .byte   " IN "
    .byte   $00


QT_OK:
.ifdef CONFIG_CBM_ALL
    .byte   CR,LF,"READY.",CR,LF
.else
    .byte   CR,LF,"OK",CR,LF
.endif
    .byte	0

QT_BREAK:
    .byte CR,LF,"BREAK"
    .byte   0


; .include "memory.s"

; generic stack and memory management code
; this code is identical across all versions of
; BASIC

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; CALLED BY "NEXT" AND "FOR" TO SCAN THROUGH
; THE STACK FOR A FRAME WITH THE SAME VARIABLE.
;
; (FORPNT) = ADDRESS OF VARIABLE IF "FOR" OR "NEXT"
; 	= $XXFF IF CALLED FROM "RETURN"
; 	<<< BUG: SHOULD BE $FFXX >>>
;
;	RETURNS .NE. IF VARIABLE NOT FOUND,
;	(X) = STACK PNTR AFTER SKIPPING ALL FRAMES
;
;	.EQ. IF FOUND
;	(X) = STACK PNTR OF FRAME FOUND
; ----------------------------------------------------------------------------
GTFORPNT:
        tsx
        inx
        inx
        inx
        inx
L2279:
        lda     STACK+1,x
        cmp     #$81
        bne     L22A1
        lda     FORPNT+1
        bne     L228E
        lda     STACK+2,x
        sta     FORPNT
        lda     STACK+3,x
        sta     FORPNT+1
L228E:
        cmp     STACK+3,x
        bne     L229A
        lda     FORPNT
        cmp     STACK+2,x
        beq     L22A1
L229A:
        txa
        clc
        adc     #BYTES_PER_FRAME
        tax
        bne     L2279
L22A1:
        rts

; ----------------------------------------------------------------------------
; MOVE BLOCK OF MEMORY UP
;
; ON ENTRY:
;	(Y,A) = (HIGHDS) = DESTINATION END+1
;	(LOWTR) = LOWEST ADDRESS OF SOURCE
;	(HIGHTR) = HIGHEST SOURCE ADDRESS+1
; ----------------------------------------------------------------------------
BLTU:
        jsr     REASON
        sta     STREND
        sty     STREND+1
BLTU2:
        sec
        lda     HIGHTR
        sbc     LOWTR
        sta     INDEX
        tay
        lda     HIGHTR+1
        sbc     LOWTR+1
        tax
        inx
        tya
        beq     L22DD
        lda     HIGHTR
        sec
        sbc     INDEX
        sta     HIGHTR
        bcs     L22C6
        dec     HIGHTR+1
        sec
L22C6:
        lda     HIGHDS
        sbc     INDEX
        sta     HIGHDS
        bcs     L22D6
        dec     HIGHDS+1
        bcc     L22D6
L22D2:
        lda     (HIGHTR),y
        sta     (HIGHDS),y
L22D6:
        dey
        bne     L22D2
        lda     (HIGHTR),y
        sta     (HIGHDS),y
L22DD:
        dec     HIGHTR+1
        dec     HIGHDS+1
        dex
        bne     L22D6
        rts

; ----------------------------------------------------------------------------
; CHECK IF ENOUGH ROOM LEFT ON STACK
; FOR "FOR", "GOSUB", OR EXPRESSION EVALUATION
; ----------------------------------------------------------------------------
CHKMEM:
        asl     a
        adc     #SPACE_FOR_GOSUB
        bcs     MEMERR
        sta     INDEX
        tsx
        cpx     INDEX
        bcc     MEMERR
        rts

; ----------------------------------------------------------------------------
; CHECK IF ENOUGH ROOM BETWEEN ARRAYS AND STRINGS
; (Y,A) = ADDR ARRAYS NEED TO GROW TO
; ----------------------------------------------------------------------------
REASON:
        cpy     FRETOP+1
        bcc     L231E
        bne     L22FC
        cmp     FRETOP
        bcc     L231E
L22FC:
        pha
        ldx     #FAC-TEMP1-1
        tya
L2300:
        pha
        lda     TEMP1,x
        dex
        bpl     L2300
        jsr     GARBAG
        ldx     #TEMP1-FAC+1
L230B:
        pla
        sta     FAC,x
        inx
        bmi     L230B
        pla
        tay
        pla
        cpy     FRETOP+1
        bcc     L231E
        bne     MEMERR
        cmp     FRETOP
        bcs     MEMERR
L231E:
        rts

;.include "program.s"

; error
; line input, line editing
; tokenize
; detokenize
; BASIC program memory management

; MICROTAN has some nonstandard extension to LIST here

.segment "MSBCODE"

MEMERR:
        ldx     #ERR_MEMFULL

; ----------------------------------------------------------------------------
; HANDLE AN ERROR
;
; (X)=OFFSET IN ERROR MESSAGE TABLE
; (ERRFLG) > 128 IF "ON ERR" TURNED ON
; (CURLIN+1) = $FF IF IN DIRECT MODE
; ----------------------------------------------------------------------------
ERROR:
        lsr     Z14
.ifdef CONFIG_FILE
        lda     CURDVC    ; output
        beq     LC366     ; is screen
        jsr     CLRCH     ; otherwise redirect output back to screen
        lda     #$00
        sta     CURDVC
LC366:
.endif
        jsr     CRDO
        jsr     OUTQUES
L2329:
        lda     ERROR_MESSAGES,x
        pha
        and     #$7F
        jsr     OUTDO
        inx
        pla
        bpl     L2329
        jsr     STKINI
        lda     #<QT_ERROR
        ldy     #>QT_ERROR

; ----------------------------------------------------------------------------
; PRINT STRING AT (Y,A)
; PRINT CURRENT LINE # UNLESS IN DIRECT MODE
; FALL INTO WARM RESTART
; ----------------------------------------------------------------------------
PRINT_ERROR_LINNUM:
        jsr     STROUT
        ldy     CURLIN+1
        iny
        beq     RESTART
        jsr     INPRT

; ----------------------------------------------------------------------------
; WARM RESTART ENTRY
; ----------------------------------------------------------------------------
RESTART:

        lsr     Z14
        lda     #<QT_OK
        ldy     #>QT_OK
  .ifdef CONFIG_CBM_ALL
        jsr     STROUT
  .else
        jsr     GOSTROUT
  .endif
L2351:
        jsr     INLIN
        stx     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGET
; bug in pre-1.1: CHRGET sets Z on '\0'
; and ':' - a line starting with ':' in
; direct mode gets ignored
        tax
        beq     L2351
        ldx     #$FF
        stx     CURLIN+1
        bcc     NUMBERED_LINE
        jsr     PARSE_INPUT_LINE
        jmp     NEWSTT2

; ----------------------------------------------------------------------------
; HANDLE NUMBERED LINE
; ----------------------------------------------------------------------------
NUMBERED_LINE:
        jsr     LINGET
        jsr     PARSE_INPUT_LINE
        sty     EOLPNTR
        jsr     FNDLIN
        bcc     PUT_NEW_LINE
        ldy     #$01
        lda     (LOWTR),y
        sta     INDEX+1
        lda     VARTAB
        sta     INDEX
        lda     LOWTR+1
        sta     DEST+1
        lda     LOWTR
        dey
        sbc     (LOWTR),y
        clc
        adc     VARTAB
        sta     VARTAB
        sta     DEST
        lda     VARTAB+1
        adc     #$FF
        sta     VARTAB+1
        sbc     LOWTR+1
        tax
        sec
        lda     LOWTR
        sbc     VARTAB
        tay
        bcs     L23A5
        inx
        dec     DEST+1
L23A5:
        clc
        adc     INDEX
        bcc     L23AD
        dec     INDEX+1
        clc
L23AD:
        lda     (INDEX),y
        sta     (DEST),y
        iny
        bne     L23AD
        inc     INDEX+1
        inc     DEST+1
        dex
        bne     L23AD
; ----------------------------------------------------------------------------
PUT_NEW_LINE:
        jsr     SETPTRS
        jsr     LE33D
        lda     INPUTBUFFER
        beq     L2351
        clc
        lda     VARTAB
        sta     HIGHTR
        adc     EOLPNTR
        sta     HIGHDS
        ldy     VARTAB+1
        sty     HIGHTR+1
        bcc     L23D6
        iny
L23D6:
        sty     HIGHDS+1
        jsr     BLTU
.ifdef CONFIG_INPUTBUFFER_0200
        lda     LINNUM
        ldy     LINNUM+1
        sta     INPUTBUFFER-2
        sty     INPUTBUFFER-1
.endif
        lda     STREND
        ldy     STREND+1
        sta     VARTAB
        sty     VARTAB+1
        ldy     EOLPNTR
        dey
; ---COPY LINE INTO PROGRAM-------
L23E6:
        lda     INPUTBUFFER-4,y
        sta     (LOWTR),y
        dey
        bpl     L23E6

; ----------------------------------------------------------------------------
; CLEAR ALL VARIABLES
; RE-ESTABLISH ALL FORWARD LINKS
; ----------------------------------------------------------------------------
FIX_LINKS:
        jsr     SETPTRS
        jsr     LE33D
        jmp     L2351
LE33D:
        lda     TXTTAB
        ldy     TXTTAB+1
        sta     INDEX
        sty     INDEX+1
        clc
L23FA:
        ldy     #$01
        lda     (INDEX),y
        beq     RET3
        jeq     L2351
        ldy     #$04
L2405:
        iny
        lda     (INDEX),y
        bne     L2405
        iny
        tya
        adc     INDEX
        tax
        ldy     #$00
        sta     (INDEX),y
        lda     INDEX+1
        adc     #$00
        iny
        sta     (INDEX),y
        stx     INDEX
        sta     INDEX+1
        bcc     L23FA	; always

; ----------------------------------------------------------------------------

RET3:
		rts

;.include "inline.s"

.segment "MSBCODE"

.ifndef CONFIG_NO_INPUTBUFFER_ZP
L2420:
        dex
        bpl     INLIN2
L2423:
        jsr     CRDO
.endif

; ----------------------------------------------------------------------------
; READ A LINE, AND STRIP OFF SIGN BITS
; ----------------------------------------------------------------------------

INLIN:

        ldx     #$00
INLIN2:
        jsr     GETLN
    .ifndef CONFIG_NO_LINE_EDITING
        cmp     #$07
        beq     L2443
    .endif
        cmp     #$0D
        beq     L2453
    .ifndef CONFIG_NO_LINE_EDITING
        cmp     #$20
        bcc     INLIN2
        cmp     #$7D
        bcs     INLIN2
        cmp     #$40 ; @
        beq     L2423
        cmp     #$5F ; _
        beq     L2420
L2443:
        cpx     #$47
        bcs     L244C
    .endif
        sta     INPUTBUFFER,x
        inx
        bne     INLIN2
L244C:
    .ifndef CONFIG_NO_LINE_EDITING
        lda     #$07 ; BEL
L244E:
        jsr     OUTDO
        bne     INLIN2
    .endif
L2453:
        jmp     L29B9


GETLN:
    .ifdef CONFIG_FILE
        jsr     CHRIN
        ldy     CURDVC
        bne     L2465
    .else
        jsr     MONRDKEY
    .endif
        cmp     #$0F
        bne     L2465
        pha
        lda     Z14
        eor     #$FF
        sta     Z14
        pla
L2465:
        rts


; ----------------------------------------------------------------------------
; TOKENIZE THE INPUT LINE
; ----------------------------------------------------------------------------
PARSE_INPUT_LINE:
        ldx     TXTPTR
        ldy     #$04
        sty     DATAFLG
L246C:
        lda     INPUTBUFFERX,x
.ifdef CONFIG_CBM_ALL
        bpl     LC49E
        cmp     #$FF
        beq     L24AC
        inx
        bne     L246C
LC49E:
.endif
        cmp     #$20
        beq     L24AC
        sta     ENDCHR
        cmp     #$22
        beq     L24D0
        bit     DATAFLG
        bvs     L24AC
        cmp     #$3F
        bne     L2484
        lda     #TOKEN_PRINT
        bne     L24AC
L2484:
        cmp     #$30
        bcc     L248C
        cmp     #$3C
        bcc     L24AC
; ----------------------------------------------------------------------------
; SEARCH TOKEN NAME TABLE FOR MATCH STARTING
; WITH CURRENT CHAR FROM INPUT LINE
; ----------------------------------------------------------------------------
L248C:
        sty     STRNG2
        ldy     #$00
        sty     EOLPNTR
        dey
        stx     TXTPTR
        dex
L2496:
        iny
L2497:
        inx
L2498:
        lda     INPUTBUFFERX,x
        sec
        sbc     TOKEN_NAME_TABLE,y
        beq     L2496
        cmp     #$80
        bne     L24D7
        ora     EOLPNTR
; ----------------------------------------------------------------------------
; STORE CHARACTER OR TOKEN IN OUTPUT LINE
; ----------------------------------------------------------------------------
L24AA:
        ldy     STRNG2
L24AC:
        inx
        iny
        sta     INPUTBUFFER-5,y
        lda     INPUTBUFFER-5,y
        beq     L24EA
        sec
        sbc     #$3A
        beq     L24BF
        cmp     #$49
        bne     L24C1
L24BF:
        sta     DATAFLG
L24C1:
        sec
        sbc     #TOKEN_REM-':'
        bne     L246C
        sta     ENDCHR
; ----------------------------------------------------------------------------
; HANDLE LITERAL (BETWEEN QUOTES) OR REMARK,
; BY COPYING CHARS UP TO ENDCHR.
; ----------------------------------------------------------------------------
L24C8:
        lda     INPUTBUFFERX,x
        beq     L24AC
        cmp     ENDCHR
        beq     L24AC
L24D0:
        iny
        sta     INPUTBUFFER-5,y
        inx
        bne     L24C8
; ----------------------------------------------------------------------------
; ADVANCE POINTER TO NEXT TOKEN NAME
; ----------------------------------------------------------------------------
L24D7:
        ldx     TXTPTR
        inc     EOLPNTR
L24DB:
        iny
        lda     MATHTBL+28+1,y
        bpl     L24DB
        lda     TOKEN_NAME_TABLE,y
        bne     L2498
        lda     INPUTBUFFERX,x
        bpl     L24AA
; ---END OF LINE------------------
L24EA:
        sta     INPUTBUFFER-3,y
.ifdef CONFIG_NO_INPUTBUFFER_ZP
        dec     TXTPTR+1
.endif
        lda     #<INPUTBUFFER-1
        sta     TXTPTR
        rts

; ----------------------------------------------------------------------------
; SEARCH FOR LINE
;
; (LINNUM) = LINE # TO FIND
; IF NOT FOUND:  CARRY = 0
;	LOWTR POINTS AT NEXT LINE
; IF FOUND:      CARRY = 1
;	LOWTR POINTS AT LINE
; ----------------------------------------------------------------------------
FNDLIN:
        lda     TXTTAB
        ldx     TXTTAB+1
FL1:
        ldy     #$01
        sta     LOWTR
        stx     LOWTR+1
        lda     (LOWTR),y
        beq     L251F
        iny
        iny
        lda     LINNUM+1
        cmp     (LOWTR),y
        bcc     L2520
        beq     L250D
        dey
        bne     L2516
L250D:
        lda     LINNUM
        dey
        cmp     (LOWTR),y
        bcc     L2520
        beq     L2520
L2516:
        dey
        lda     (LOWTR),y
        tax
        dey
        lda     (LOWTR),y
        bcs     FL1
L251F:
        clc
L2520:
        rts

; ----------------------------------------------------------------------------
; "NEW" STATEMENT
; ----------------------------------------------------------------------------
NEW:
        bne     L2520
SCRTCH:
        lda     #$00
        tay
        sta     (TXTTAB),y
        iny
        sta     (TXTTAB),y
        lda     TXTTAB
		clc
        adc     #$02
        sta     VARTAB
        lda     TXTTAB+1
        adc     #$00
        sta     VARTAB+1
; ----------------------------------------------------------------------------
SETPTRS:
        jsr     STXTPT
        lda     #$00

; ----------------------------------------------------------------------------
; "CLEAR" STATEMENT
; ----------------------------------------------------------------------------
CLEAR:
        bne     L256A
CLEARC:

        lda     MEMSIZ
        ldy     MEMSIZ+1
        sta     FRETOP
        sty     FRETOP+1
.ifdef CONFIG_CBM_ALL
        jsr     CLALL
.endif
        lda     VARTAB
        ldy     VARTAB+1
        sta     ARYTAB
        sty     ARYTAB+1
        sta     STREND
        sty     STREND+1
        jsr     RESTORE
; ----------------------------------------------------------------------------
STKINI:
        ldx     #TEMPST
        stx     TEMPPT
        pla
		tay
        pla
        ldx     #STACK_TOP
        txs
        pha
        tya
        pha
        lda     #$00
        sta     OLDTEXT+1
        sta     SUBFLG
L256A:
        rts

; ----------------------------------------------------------------------------
; SET TXTPTR TO BEGINNING OF PROGRAM
; ----------------------------------------------------------------------------
STXTPT:
        clc
        lda     TXTTAB
        adc     #$FF
        sta     TXTPTR
        lda     TXTTAB+1
        adc     #$FF
        sta     TXTPTR+1
        rts

; ----------------------------------------------------------------------------
; "LIST" STATEMENT
; ----------------------------------------------------------------------------
LIST:
        bcc     L2581
        beq     L2581
        cmp     #TOKEN_MINUS
        bne     L256A
L2581:
        jsr     LINGET
        jsr     FNDLIN
        jsr     CHRGOT
        beq     L2598
        cmp     #TOKEN_MINUS
        bne     L2520
        jsr     CHRGET
        jsr     LINGET
        bne     L2520
L2598:
        lda     #$FF
        sta     LINNUM
        sta     LINNUM+1
L25A6:
L25A6X:
        ldy     #$01
.ifdef CONFIG_DATAFLG
        sty     DATAFLG
.endif
        lda     (LOWTRX),y
        beq     L25E5
        jsr     ISCNTC
        jsr     CRDO
        iny
        lda     (LOWTRX),y
        tax
        iny
        lda     (LOWTRX),y
        cmp     LINNUM+1
        bne     L25C1
        cpx     LINNUM
        beq     L25C3
L25C1:
        bcs     L25E5
; ---LIST ONE LINE----------------
L25C3:
        sty     FORPNT
        jsr     LINPRT
        lda     #$20
L25CA:
        ldy     FORPNT
        and     #$7F
L25CE:
        jsr     OUTDO
.ifdef CONFIG_DATAFLG
        cmp     #$22
        bne     LA519
        lda     DATAFLG
        eor     #$FF
        sta     DATAFLG
LA519:
.endif
        iny
        beq     L25E5
        lda     (LOWTRX),y
        bne     L25E8
        tay
        lda     (LOWTRX),y
        tax
        iny
        lda     (LOWTRX),y
        stx     LOWTRX
        sta     LOWTRX+1
        bne     L25A6
L25E5:
        jmp     RESTART
L25E8:
        bpl     L25CE
.ifdef CONFIG_DATAFLG
        cmp     #$FF
        beq     L25CE
        bit     DATAFLG
        bmi     L25CE
.endif
        sec
        sbc     #$7F
        tax
        sty     FORPNT
        ldy     #$FF
L25F2:
        dex
        beq     L25FD
L25F5:
        iny
        lda     TOKEN_NAME_TABLE,y
        bpl     L25F5
        bmi     L25F2
L25FD:
        iny
        lda     TOKEN_NAME_TABLE,y
        bmi     L25CA
        jsr     OUTDO
        bne     L25FD	; always


;.include "flow1.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; "FOR" STATEMENT
;
; FOR PUSHES 18 BYTES ON THE STACK:
; 2 -- TXTPTR
; 2 -- LINE NUMBER
; 5 -- INITIAL (CURRENT)  FOR VARIABLE VALUE
; 1 -- STEP SIGN
; 5 -- STEP VALUE
; 2 -- ADDRESS OF FOR VARIABLE IN VARTAB
; 1 -- FOR TOKEN ($81)
; ----------------------------------------------------------------------------
FOR:
        lda     #$80
        sta     SUBFLG
        jsr     LET
        jsr     GTFORPNT
        bne     L2619
        txa
        adc     #FOR_STACK1
        tax
        txs
L2619:
        pla
        pla
        lda     #FOR_STACK2
        jsr     CHKMEM
        jsr     DATAN
        clc
        tya
        adc     TXTPTR
        pha
        lda     TXTPTR+1
        adc     #$00
        pha
        lda     CURLIN+1
        pha
        lda     CURLIN
        pha
        lda     #TOKEN_TO
        jsr     SYNCHR
        jsr     CHKNUM
        jsr     FRMNUM
        lda     FACSIGN
        ora     #$7F
        and     FAC+1
        sta     FAC+1
        lda     #<STEP
        ldy     #>STEP
        sta     INDEX
        sty     INDEX+1
        jmp     FRM_STACK3

; ----------------------------------------------------------------------------
; "STEP" PHRASE OF "FOR" STATEMENT
; ----------------------------------------------------------------------------
STEP:
        lda     #<CON_ONE
        ldy     #>CON_ONE
        jsr     LOAD_FAC_FROM_YA
        jsr     CHRGOT
        cmp     #TOKEN_STEP
        bne     L2665
        jsr     CHRGET
        jsr     FRMNUM
L2665:
        jsr     SIGN
        jsr     FRM_STACK2
        lda     FORPNT+1
        pha
        lda     FORPNT
        pha
        lda     #$81
        pha

; ----------------------------------------------------------------------------
; PERFORM NEXT STATEMENT
; ----------------------------------------------------------------------------
NEWSTT:
        jsr     ISCNTC
        lda     TXTPTR
        ldy     TXTPTR+1
;.if .def(CONFIG_NO_INPUTBUFFER_ZP) && .def(CONFIG_2)
        cpy     #>INPUTBUFFER
  .ifdef CBM2
        nop
  .endif
        beq     LC6D4
;.else
; BUG on AppleSoft I,
; fixed differently on AppleSoft II (ldx/inx)
;        beq     L2683
;.endif
        sta     OLDTEXT
        sty     OLDTEXT+1
LC6D4:
        ldy     #$00
L2683:
        lda     (TXTPTR),y
        bne     COLON; new: 1 cycle more on ":" case
        ldy     #$02
        lda     (TXTPTR),y
        clc
        jeq     L2701
        iny
        lda     (TXTPTR),y
        sta     CURLIN
        iny
        lda     (TXTPTR),y
        sta     CURLIN+1
        tya
        adc     TXTPTR
        sta     TXTPTR
        bcc     NEWSTT2
        inc     TXTPTR+1
NEWSTT2:
        jsr     CHRGET
        jsr     EXECUTE_STATEMENT
        jmp     NEWSTT

; ----------------------------------------------------------------------------
; EXECUTE A STATEMENT
;
; (A) IS FIRST CHAR OF STATEMENT
; CARRY IS SET
; ----------------------------------------------------------------------------
EXECUTE_STATEMENT:
        beq     RET2
EXECUTE_STATEMENT1:
        sbc     #$80
        bcc     LET1; new: 1 cycle more on assignment
        cmp     #NUM_TOKENS
        bcs     LC721
        asl     a
        tay
        lda     TOKEN_ADDRESS_TABLE+1,y
        pha
        lda     TOKEN_ADDRESS_TABLE,y
        pha
        jmp     CHRGET

LET1:
        jmp     LET

COLON:
        cmp     #$3A
        beq     NEWSTT2
SYNERR1:
        jmp     SYNERR

LC721:
        cmp     #TOKEN_GO-$80
        bne     SYNERR1
        jsr     CHRGET
        lda     #TOKEN_TO
        jsr     SYNCHR
        jmp     GOTO

; ----------------------------------------------------------------------------
; "RESTORE" STATEMENT
; ----------------------------------------------------------------------------
RESTORE:
        sec
        lda     TXTTAB
        sbc     #$01
        ldy     TXTTAB+1
        bcs     SETDA
        dey
SETDA:
        sta     DATPTR
        sty     DATPTR+1
RET2:
        rts

; .include "iscntc.s"

ISCNTC:
        jsr CHRIN
        bcc not_cntc
        cmp #3
        bne not_cntc
        jmp is_cntc

not_cntc:
        rts

is_cntc:
        ; Fall through

;!!! runs into "STOP"
; ----------------------------------------------------------------------------
; "STOP" STATEMENT
; ----------------------------------------------------------------------------
STOP:
        bcs     END2

; ----------------------------------------------------------------------------
; "END" STATEMENT
; ----------------------------------------------------------------------------
END:
        clc
END2:
        bne     RET1
        lda     TXTPTR
        ldy     TXTPTR+1
;.if .def(CONFIG_NO_INPUTBUFFER_ZP) && .def(CONFIG_2)
; BUG on AppleSoft I
; fix exists on AppleSoft II
; TXTPTR+1 will always be > 0
        ldx     CURLIN+1
        inx
;.endif
        beq     END4
        sta     OLDTEXT
        sty     OLDTEXT+1
CONTROL_C_TYPED:
        lda     CURLIN
        ldy     CURLIN+1
        sta     OLDLIN
        sty     OLDLIN+1
END4:
        pla
        pla
L2701:
        lda     #<QT_BREAK
        ldy     #>QT_BREAK
        bcc     L270E
        jmp     PRINT_ERROR_LINNUM
L270E:
        jmp     RESTART


; ----------------------------------------------------------------------------
; "CONT" COMMAND
; ----------------------------------------------------------------------------
CONT:
        bne     RET1
        ldx     #ERR_CANTCONT
        ldy     OLDTEXT+1
        bne     L271C
        jmp     ERROR
L271C:
        lda     OLDTEXT
        sta     TXTPTR
        sty     TXTPTR+1
        lda     OLDLIN
        ldy     OLDLIN+1
        sta     CURLIN
        sty     CURLIN+1
RET1:
        rts

.if .def(CONFIG_NULL) || .def(CONFIG_PRINTNULLS)
; CBM1 has the keyword removed,
; but the code is still here
NULL:
        jsr     GETBYT
        bne     RET1
        inx
        cpx     #NULL_MAX
        bcs     L2739
        dex
        stx     Z15
L2738:
        rts
L2739:
        jmp     IQERR

.endif

;.include "loadsave.s"

;.include "flow2.s"

.segment "MSBCODE"
; ----------------------------------------------------------------------------
; "RUN" COMMAND
; ----------------------------------------------------------------------------
RUN:
        bne     L27CF
        jmp     SETPTRS
L27CF:
        jsr     CLEARC
        jmp     L27E9

; ----------------------------------------------------------------------------
; "GOSUB" STATEMENT
;
; LEAVES 7 BYTES ON STACK:
; 2 -- RETURN ADDRESS (NEWSTT)
; 2 -- TXTPTR
; 2 -- LINE #
; 1 -- GOSUB TOKEN
; ----------------------------------------------------------------------------
GOSUB:
        lda     #$03
        jsr     CHKMEM
        lda     TXTPTR+1
        pha
        lda     TXTPTR
        pha
        lda     CURLIN+1
        pha
        lda     CURLIN
        pha
        lda     #TOKEN_GOSUB
        pha
L27E9:
        jsr     CHRGOT
        jsr     GOTO
        jmp     NEWSTT

; ----------------------------------------------------------------------------
; "GOTO" STATEMENT
; ALSO USED BY "RUN" AND "GOSUB"
; ----------------------------------------------------------------------------
GOTO:
        jsr     LINGET
        jsr     REMN
        lda     CURLIN+1
        cmp     LINNUM+1
        bcs     L2809
        tya
        sec
        adc     TXTPTR
        ldx     TXTPTR+1
        bcc     L280D
        inx
        bcs     L280D
L2809:
        lda     TXTTAB
        ldx     TXTTAB+1
L280D:
        jsr     FL1
        bcc     UNDERR
        lda     LOWTRX
        sbc     #$01
        sta     TXTPTR
        lda     LOWTRX+1
        sbc     #$00
        sta     TXTPTR+1
L281E:
        rts

; ----------------------------------------------------------------------------
; "POP" AND "RETURN" STATEMENTS
; ----------------------------------------------------------------------------
POP:
        bne     L281E
        lda     #$FF
        sta     FORPNT+1 ; bugfix, wrong in AppleSoft II
        jsr     GTFORPNT
        txs
        cmp     #TOKEN_GOSUB
        beq     RETURN
        ldx     #ERR_NOGOSUB
        .byte   $2C
UNDERR:
        ldx     #ERR_UNDEFSTAT
        jmp     ERROR
; ----------------------------------------------------------------------------
SYNERR2:
        jmp     SYNERR
; ----------------------------------------------------------------------------
RETURN:
        pla
        pla
        sta     CURLIN
        pla
        sta     CURLIN+1
        pla
        sta     TXTPTR
        pla
        sta     TXTPTR+1

; ----------------------------------------------------------------------------
; "DATA" STATEMENT
; EXECUTED BY SKIPPING TO NEXT COLON OR EOL
; ----------------------------------------------------------------------------
DATA:
        jsr     DATAN

; ----------------------------------------------------------------------------
; ADD (Y) TO TXTPTR
; ----------------------------------------------------------------------------
ADDON:
        tya
        clc
        adc     TXTPTR
        sta     TXTPTR
        bcc     L2852
        inc     TXTPTR+1
L2852:
        rts

; ----------------------------------------------------------------------------
; SCAN AHEAD TO NEXT ":" OR EOL
; ----------------------------------------------------------------------------
DATAN:
        ldx     #$3A
        .byte   $2C
REMN:
        ldx     #$00
        stx     CHARAC
        ldy     #$00
        sty     ENDCHR
L285E:
        lda     ENDCHR
        ldx     CHARAC
        sta     CHARAC
        stx     ENDCHR
L2866:
        lda     (TXTPTR),y
        beq     L2852
        cmp     ENDCHR
        beq     L2852
        iny
        cmp     #$22
        bne     L2866; new: cont is faster
        beq     L285E

; ----------------------------------------------------------------------------
; "IF" STATEMENT
; ----------------------------------------------------------------------------
IF:
        jsr     FRMEVL
        jsr     CHRGOT
        cmp     #TOKEN_GOTO
        beq     L2884
        lda     #TOKEN_THEN
        jsr     SYNCHR
L2884:
        lda     FAC
        bne     L288D

; ----------------------------------------------------------------------------
; "REM" STATEMENT, OR FALSE "IF" STATEMENT
; ----------------------------------------------------------------------------
REM:
        jsr     REMN
        beq     ADDON
L288D:
        jsr     CHRGOT
        bcs     L2895
        jmp     GOTO
L2895:
        jmp     EXECUTE_STATEMENT

; ----------------------------------------------------------------------------
; "ON" STATEMENT
;
; ON <EXP> GOTO <LIST>
; ON <EXP> GOSUB <LIST>
; ----------------------------------------------------------------------------
ON:
        jsr     GETBYT
        pha
        cmp     #TOKEN_GOSUB
        beq     L28A4
L28A0:
        cmp     #TOKEN_GOTO
        bne     SYNERR2
L28A4:
        dec     FAC_LAST
        bne     L28AC
        pla
        jmp     EXECUTE_STATEMENT1
L28AC:
        jsr     CHRGET
        jsr     LINGET
        cmp     #$2C
        beq     L28A4
        pla
L28B7:
        rts

;.include "misc1.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; CONVERT LINE NUMBER
; ----------------------------------------------------------------------------
LINGET:
        ldx     #$00
        stx     LINNUM
        stx     LINNUM+1
L28BE:
        bcs     L28B7
        sbc     #$2F
        sta     CHARAC
        lda     LINNUM+1
        sta     INDEX
        cmp     #$19
        bcs     L28A0
; <<<<<DANGEROUS CODE>>>>>
; NOTE THAT IF (A) = $AB ON THE LINE ABOVE,
; ON.1 WILL COMPARE = AND CAUSE A CATASTROPHIC
; JUMP TO $22D9 (FOR GOTO), OR OTHER LOCATIONS
; FOR OTHER CALLS TO LINGET.
;
; YOU CAN SEE THIS IS YOU FIRST PUT "BRK" IN $22D9,
; THEN TYPE "GO TO 437761".
;
; ANY VALUE FROM 437760 THROUGH 440319 WILL CAUSE
; THE PROBLEM.  ($AB00 - $ABFF)
; <<<<<DANGEROUS CODE>>>>>
        lda     LINNUM
        asl     a
        rol     INDEX
        asl     a
        rol     INDEX
        adc     LINNUM
        sta     LINNUM
        lda     INDEX
        adc     LINNUM+1
        sta     LINNUM+1
        asl     LINNUM
        rol     LINNUM+1
        lda     LINNUM
        adc     CHARAC
        sta     LINNUM
        bcc     L28EC
        inc     LINNUM+1
L28EC:
        jsr     CHRGET
        jmp     L28BE

; ----------------------------------------------------------------------------
; "LET" STATEMENT
;
; LET <VAR> = <EXP>
; <VAR> = <EXP>
; ----------------------------------------------------------------------------
LET:
        jsr     PTRGET
        sta     FORPNT
        sty     FORPNT+1
        lda     #TOKEN_EQUAL
        jsr     SYNCHR
        lda     VALTYP+1
        pha
        lda     VALTYP
        pha
        jsr     FRMEVL
        pla
        rol     a
        jsr     CHKVAL
        bne     LETSTRING
        pla
LET2:
        bpl     L2923
        jsr     ROUND_FAC
        jsr     AYINT
        ldy     #$00
        lda     FAC+3
        sta     (FORPNT),y
        iny
        lda     FAC+4
        sta     (FORPNT),y
        rts
L2923:

; ----------------------------------------------------------------------------
; REAL VARIABLE = EXPRESSION
; ----------------------------------------------------------------------------
        jmp     SETFOR
LETSTRING:
        pla

; ----------------------------------------------------------------------------
; INSTALL STRING, DESCRIPTOR ADDRESS IS AT FAC+3,4
; ----------------------------------------------------------------------------
PUTSTR:
.ifdef CONFIG_CBM_ALL
        ldy     FORPNT+1
  .ifdef CBM1
        cpy     #$D0	; TI$
  .else
        cpy     #$DE
  .endif
        bne     LC92B
        jsr     FREFAC
        cmp     #$06
  .ifdef CBM2
        bne     IQERR1
  .else
        jne     IQERR
  .endif
        ldy     #$00
        sty     FAC
        sty     FACSIGN
LC8E8:
        sty     STRNG2
        jsr     LC91C
        jsr     MUL10
        inc     STRNG2
        ldy     STRNG2
        jsr     LC91C
        jsr     COPY_FAC_TO_ARG_ROUNDED
        tax
        beq     LC902
        inx
        txa
        jsr     LD9BF
LC902:
        ldy     STRNG2
        iny
        cpy     #$06
        bne     LC8E8
        jsr     MUL10
        jsr     QINT
        ldx     #$02
        sei
LC912:
        lda     FAC+2,x
        sta     TISTR,x
        dex
        bpl     LC912
        cli
        rts
LC91C:
        lda     (INDEX),y
        jsr     CHRGOT2
        bcc     LC926
IQERR1:
        jmp     IQERR
LC926:
        sbc     #$2F
        jmp     ADDACC
LC92B:
.endif
        ldy     #$02
        lda     (FAC_LAST-1),y
        cmp     FRETOP+1
        bcc     L2946
        bne     L2938
        dey
        lda     (FAC_LAST-1),y
        cmp     FRETOP
        bcc     L2946
L2938:
        ldy     FAC_LAST
        cpy     VARTAB+1
        bcc     L2946
        bne     L294D
        lda     FAC_LAST-1
        cmp     VARTAB
        bcs     L294D
L2946:
        lda     FAC_LAST-1
        ldy     FAC_LAST
        jmp     L2963
L294D:
        ldy     #$00
        lda     (FAC_LAST-1),y
        jsr     STRINI
        lda     DSCPTR
        ldy     DSCPTR+1
        sta     STRNG1
        sty     STRNG1+1
        jsr     MOVINS
        lda     #FAC
        ldy     #$00
L2963:
        sta     DSCPTR
        sty     DSCPTR+1
        jsr     FRETMS
        ldy     #$00
        lda     (DSCPTR),y
        sta     (FORPNT),y
        iny
        lda     (DSCPTR),y
        sta     (FORPNT),y
        iny
        lda     (DSCPTR),y
        sta     (FORPNT),y
RET5:
        rts

.ifdef CONFIG_FILE
PRINTH:
        jsr     CMD
        jmp     LCAD6
CMD:
        jsr     GETBYT
        beq     LC98F
        lda     #$2C
        jsr     SYNCHR
LC98F:
        php
        jsr     CHKOUT
        stx     CURDVC
        plp
        jmp     PRINT
.endif

;.include "print.s"

.segment "MSBCODE"

PRSTRING:
        jsr     STRPRT
L297E:
        jsr     CHRGOT

; ----------------------------------------------------------------------------
; "PRINT" STATEMENT
; ----------------------------------------------------------------------------

PRINT:
        beq     CRDO
PRINT2:
        beq     L29DD
        cmp     #TOKEN_TAB
        beq     L29F5
        cmp     #TOKEN_SPC
        clc	; also AppleSoft II
        beq     L29F5
        cmp     #','
; Pre-KIM had no CLC. KIM added the CLC
; here. Post-KIM moved the CLC up...
; (makes no sense on KIM, liveness = 0)
        beq     L29DE
        cmp     #$3B
        beq     L2A0D
        jsr     FRMEVL
        bit     VALTYP
        bmi     PRSTRING
        jsr     FOUT
        jsr     STRLIT
.ifndef CONFIG_NO_CR
        ldy     #$00
        lda     (FAC_LAST-1),y
        clc
        adc     POSX
        cmp     Z17
        bcc     L29B1
        jsr     CRDO
L29B1:
.endif
        jsr     STRPRT
        jsr     OUTSP
        bne     L297E ; branch always


L29B9:
.ifdef CBM2
        lda     #$00
        sta     INPUTBUFFER,x
        ldx     #<(INPUTBUFFER-1)
        ldy     #>(INPUTBUFFER-1)
.else
        ldy     #$00
        sty     INPUTBUFFER,x
        ldx     #LINNUM+1
.endif
.ifdef CONFIG_FILE
        lda     CURDVC
        bne     L29DD
.endif


CRDO:
.if .def(CONFIG_PRINTNULLS) && .def(CONFIG_FILE)
        lda     CURDVC
        bne     LC9D8
        sta     POSX
LC9D8:
.endif
        lda     #CRLF_1
.ifndef CONFIG_CBM_ALL
        sta     POSX
.endif
        jsr     OUTDO
CRDO2:
        lda     #CRLF_2
        jsr     OUTDO

PRINTNULLS:
  .if .def(CONFIG_NULL) || .def(CONFIG_PRINTNULLS)
    .ifdef CONFIG_FILE
    ; Although there is no statement for it,
    ; CBM1 had NULL support and ignores
    ; it when not targeting the screen,
    ; CBM2 dropped it completely.
        lda     CURDVC
        bne     L29DD
    .endif
        txa
        pha
        ldx     Z15
        beq     L29D9
        lda     #$00
L29D3:
        jsr     OUTDO
        dex
        bne     L29D3
L29D9:
        stx     POSX
        pla
        tax
  .else
        eor     #$FF
  .endif
  
L29DD:
        rts
L29DE:
        lda     POSX
.ifndef CONFIG_NO_CR
        cmp     Z18
        bcc     L29EA
        jsr     CRDO
        jmp     L2A0D
L29EA:
.endif
        sec
L29EB:
.if .def(CONFIG_CBM_ALL) || .def(AIM65)
        sbc     #$0A
.else
        sbc     #$0E
.endif
        bcs     L29EB
        eor     #$FF
        adc     #$01
        bne     L2A08
L29F5:
        php
        jsr     GTBYTC
        cmp     #')'
        bne     SYNERR4
        plp
        bcc     L2A09
        txa
        sbc     POSX
        bcc     L2A0D
L2A08:
        tax
L2A09:
        inx
L2A0A:
        dex
        bne     L2A13
L2A0D:
        jsr     CHRGET
        jmp     PRINT2
L2A13:
        jsr     OUTSP
        bne     L2A0A

; ----------------------------------------------------------------------------
; PRINT STRING AT (Y,A)
; ----------------------------------------------------------------------------
STROUT:
        jsr     STRLIT

; ----------------------------------------------------------------------------
; PRINT STRING AT (FACMO,FACLO)
; ----------------------------------------------------------------------------
STRPRT:
        jsr     FREFAC
        tax
        ldy     #$00
        inx
L2A22:
        dex
        beq     L29DD
        lda     (INDEX),y
        jsr     OUTDO
        iny
        cmp     #$0D
        bne     L2A22
        jsr     PRINTNULLS
        jmp     L2A22
; ----------------------------------------------------------------------------
OUTSP:
.ifdef CONFIG_FILE
  .ifndef CBM1
; on non-screen devices, print SPACE
; instead of CRSR RIGHT
        lda     CURDVC
        beq     LCA40
        lda     #$20
        .byte   $2C
LCA40:
  .endif
        lda     #$1D ; CRSR RIGHT
.else
        lda     #$20
.endif
        .byte   $2C
OUTQUES:
        lda     #$3F

; ----------------------------------------------------------------------------
; PRINT CHAR FROM (A)
; ----------------------------------------------------------------------------
OUTDO:
        bit     Z14
        bmi     L2A56
.if .def(CONFIG_PRINT_CR) || .def(CBM1)
; Commodore forgot to remove this in CBM1
        pha
.endif
.ifdef CBM1
        cmp     #$1D ; CRSR RIGHT
        beq     LCA6A
        cmp     #$9D ; CRSR LEFT
        beq     LCA5A
        cmp     #$14 ; DEL
        bne     LCA64
LCA5A:
        lda     POSX
        beq     L2A4E
        lda     CURDVC
        bne     L2A4E
        dec     POSX
LCA64:
        and     #$7F
.endif
.ifndef CBM2
        cmp     #$20
        bcc     L2A4E
.endif
LCA6A:
.ifdef CONFIG_CBM1_PATCHES
        lda     CURDVC
        jsr     PATCH6
        nop
.endif
.ifdef CONFIG_PRINT_CR
        lda     POSX
        cmp     Z17
        bne     L2A4C
        jsr     CRDO
L2A4C:
.endif
.ifndef CONFIG_CBM_ALL
        inc     POSX
.endif
L2A4E:
.if .def(CONFIG_PRINT_CR) || .def(CBM1)
; Commodore forgot to remove this in CBM1
        pla
.endif
.ifdef CONFIG_MONCOUT_DESTROYS_Y
        sty     DIMFLG
.endif
.ifdef CONFIG_IO_MSB
        ora     #$80
.endif
        jsr     MONCOUT
.ifdef CONFIG_IO_MSB
        and     #$7F
.endif
.ifdef CONFIG_MONCOUT_DESTROYS_Y
        ldy     DIMFLG
.endif
.ifdef OSI
        nop
        nop
        nop
        nop
.endif
L2A56:
        and     #$FF
LE8F2:
        rts

;.include "input.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; INPUT CONVERSION ERROR:  ILLEGAL CHARACTER
; IN NUMERIC FIELD.  MUST DISTINGUISH
; BETWEEN INPUT, READ, AND GET
; ----------------------------------------------------------------------------
INPUTERR:
        lda     INPUTFLG
        beq     RESPERR	; INPUT
; without this, it treats GET errors
; like READ errors
        bmi     L2A63	; READ
        ldy     #$FF	; GET
        bne     L2A67
L2A63:
.ifdef CONFIG_CBM1_PATCHES
        jsr     PATCH5
		nop
.else
        lda     Z8C
        ldy     Z8C+1
.endif
L2A67:
        sta     CURLIN
        sty     CURLIN+1
SYNERR4:
        jmp     SYNERR
RESPERR:
.ifdef CONFIG_FILE
        lda     CURDVC
        beq     LCA8F
        ldx     #ERR_BADDATA
        jmp     ERROR
LCA8F:
.endif
        lda     #<ERRREENTRY
        ldy     #>ERRREENTRY
        jsr     STROUT
        lda     OLDTEXT
        ldy     OLDTEXT+1
        sta     TXTPTR
        sty     TXTPTR+1
RTS20:
        rts

; ----------------------------------------------------------------------------
; "GET" STATEMENT
; ----------------------------------------------------------------------------
GET:
        jsr     ERRDIR
; CBM: if GET#, then switch input
.ifdef CONFIG_FILE
        cmp     #'#'
        bne     LCAB6
        jsr     CHRGET
        jsr     GETBYT
        lda     #','
        jsr     SYNCHR
        jsr     CHKIN
        stx     CURDVC
LCAB6:
        ldx     #<(INPUTBUFFER+1)
        ldy     #>(INPUTBUFFER+1)
.ifdef CONFIG_NO_INPUTBUFFER_ZP
        lda     #$00
        sta     INPUTBUFFER+1
.else
        sty     INPUTBUFFER+1
.endif
        lda     #$40
        jsr     PROCESS_INPUT_LIST
; CBM: if GET#, then switch input back
.ifdef CONFIG_FILE
        ldx     CURDVC
        bne     LCAD8
.endif
        rts
.endif

; ----------------------------------------------------------------------------
; "INPUT#" STATEMENT
; ----------------------------------------------------------------------------
.ifdef CONFIG_FILE
INPUTH:
        jsr     GETBYT
        lda     #$2C
        jsr     SYNCHR
        jsr     CHKIN
        stx     CURDVC
        jsr     L2A9E
LCAD6:
        lda     CURDVC
LCAD8:
        jsr     CLRCH
        ldx     #$00
        stx     CURDVC
        rts
LCAE0:
.endif


; ----------------------------------------------------------------------------
; "INPUT" STATEMENT
; ----------------------------------------------------------------------------
INPUT:
        lsr     Z14
        cmp     #$22
        bne     L2A9E
        jsr     STRTXT
        lda     #$3B
        jsr     SYNCHR
        jsr     STRPRT
L2A9E:
        jsr     ERRDIR
        lda     #$2C
        sta     INPUTBUFFER-1
LCAF8:
        jsr     NXIN
  .ifdef CONFIG_FILE
        lda     CURDVC
        beq     LCB0C
        lda     Z96
        and     #$02
        beq     LCB0C
        jsr     LCAD6
        jmp     DATA
LCB0C:
  .endif
        lda     INPUTBUFFER
        bne     L2ABE
  .ifdef CONFIG_FILE
        lda     CURDVC
        bne     LCAF8
  .endif
  .ifdef CONFIG_CBM1_PATCHES
        jmp     PATCH1
  .else
        clc
        jmp     CONTROL_C_TYPED
  .endif

NXIN:
  .ifdef CONFIG_FILE
        lda     CURDVC
        bne     LCB21
  .endif
        jsr     OUTQUES	; '?'
        jsr     OUTSP
LCB21:
        jmp     INLIN


; ----------------------------------------------------------------------------
; "READ" STATEMENT
; ----------------------------------------------------------------------------
READ:
        ldx     DATPTR
        ldy     DATPTR+1
.ifdef CONFIG_NO_READ_Y_IS_ZERO_HACK
; AppleSoft II, too
        lda     #$98	; READ
        .byte   $2C
L2ABE:
        lda     #$00	; INPUT
.else
        .byte   $A9	; LDA #$98
L2ABE:
        tya
.endif

; ----------------------------------------------------------------------------
; PROCESS INPUT LIST
;
; (Y,X) IS ADDRESS OF INPUT DATA STRING
; (A) = VALUE FOR INPUTFLG:  $00 FOR INPUT
; 				$40 FOR GET
;				$98 FOR READ
; ----------------------------------------------------------------------------
PROCESS_INPUT_LIST:
        sta     INPUTFLG
        stx     INPTR
        sty     INPTR+1
PROCESS_INPUT_ITEM:
        jsr     PTRGET
        sta     FORPNT
        sty     FORPNT+1
        lda     TXTPTR
        ldy     TXTPTR+1
        sta     TXPSV
        sty     TXPSV+1
        ldx     INPTR
        ldy     INPTR+1
        stx     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGOT
        bne     INSTART
        bit     INPUTFLG
        bvc     L2AF0
        jsr     MONRDKEY
  .ifdef CONFIG_IO_MSB
        and     #$7F
  .endif
        sta     INPUTBUFFER
; BUG: The beq/bne L2AF8 below is supposed
; to be always taken. For this to happen,
; the last load must be a 0 for beq
; and != 0 for bne. The original Microsoft
; code had ldx/ldy/bne here, which was only
; correct for a non-ZP INPUTBUFFER. Commodore
; fixed it in CBMBASIC V1 by swapping the
; ldx and the ldy. It was broken on KIM,
; but okay on APPLE and CBM2, because
; these used a non-ZP INPUTBUFFER.
; Microsoft fixed this somewhere after KIM
; and before MICROTAN, by using beq instead
; of bne in the ZP case.
  .ifdef CBM1
        ldy     #>(INPUTBUFFER-1)
        ldx     #<(INPUTBUFFER-1)
  .else
        ldx     #<(INPUTBUFFER-1)
        ldy     #>(INPUTBUFFER-1)
  .endif
;  .if .def(CONFIG_2) && (!.def(CONFIG_NO_INPUTBUFFER_ZP))
        beq     L2AF8	; always
;  .else
;        bne     L2AF8	; always
;  .endif
L2AF0:
        bmi     FINDATA
.ifdef CONFIG_FILE
        lda     CURDVC
        bne     LCB64
.endif
        jsr     OUTQUES
LCB64:
        jsr     NXIN
L2AF8:
        stx     TXTPTR
        sty     TXTPTR+1

; ----------------------------------------------------------------------------
INSTART:
        jsr     CHRGET
        bit     VALTYP
        bpl     L2B34
        bit     INPUTFLG
        bvc     L2B10
  .ifdef CONFIG_CBM1_PATCHES
        lda     #$00
        jsr     PATCH4
        nop
  .else
        inx
        stx     TXTPTR
        lda     #$00
        sta     CHARAC
        beq     L2B1C
  .endif
L2B10:
        sta     CHARAC
        cmp     #$22
        beq     L2B1D
        lda     #$3A
        sta     CHARAC
        lda     #$2C
L2B1C:
        clc
L2B1D:
        sta     ENDCHR
        lda     TXTPTR
        ldy     TXTPTR+1
        adc     #$00
        bcc     L2B28
        iny
L2B28:
        jsr     STRLT2
        jsr     POINT
        jsr     PUTSTR
        jmp     INPUT_MORE
; ----------------------------------------------------------------------------
L2B34:
        jsr     FIN
        lda     VALTYP+1
        jsr     LET2
; ----------------------------------------------------------------------------
INPUT_MORE:
        jsr     CHRGOT
        beq     L2B48
        cmp     #$2C
        beq     L2B48
        jmp     INPUTERR
L2B48:
        lda     TXTPTR
        ldy     TXTPTR+1
        sta     INPTR
        sty     INPTR+1
        lda     TXPSV
        ldy     TXPSV+1
        sta     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGOT
        beq     INPDONE
        jsr     CHKCOM
        jmp     PROCESS_INPUT_ITEM
; ----------------------------------------------------------------------------
FINDATA:
        jsr     DATAN
        iny
        tax
        bne     L2B7C
        ldx     #ERR_NODATA
        iny
        lda     (TXTPTR),y
        beq     GERR
        iny
        lda     (TXTPTR),y
        sta     Z8C
        iny
        lda     (TXTPTR),y
        iny
        sta     Z8C+1
L2B7C:
        lda     (TXTPTR),y
        tax
        jsr     ADDON
        cpx     #$83
        bne     FINDATA
        jmp     INSTART
; ---NO MORE INPUT REQUESTED------
INPDONE:
        lda     INPTR
        ldy     INPTR+1
        ldx     INPUTFLG
        bpl     L2B94; INPUT or GET
        jmp     SETDA
L2B94:
        ldy     #$00
        lda     (INPTR),y
        beq     L2BA1
.ifdef CONFIG_FILE
        lda     CURDVC
        bne     L2BA1
.endif
        lda     #<ERREXTRA
        ldy     #>ERREXTRA
        jmp     STROUT
L2BA1:
        rts

; ----------------------------------------------------------------------------
ERREXTRA:
        .byte   "?EXTRA IGNORED"
        .byte   $0D,$0A,$00
ERRREENTRY:
        .byte   "?REDO FROM START"
        .byte   $0D,$0A,$00

;.include "eval.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; "NEXT" STATEMENT
; ----------------------------------------------------------------------------
NEXT:
        bne     NEXT1
        ldy     #$00
        beq     NEXT2
NEXT1:
        jsr     PTRGET
NEXT2:
        sta     FORPNT
        sty     FORPNT+1
        jsr     GTFORPNT
        beq     NEXT3
        ldx     #$00
GERR:
        beq     JERROR
NEXT3:
        txs
        txa
        clc
        adc     #$04
        pha
        adc     #BYTES_FP+1
        sta     DEST
        pla
        ldy     #>STACK
        jsr     LOAD_FAC_FROM_YA
        tsx
        lda     STACK+BYTES_FP+4,x
        sta     FACSIGN
        lda     FORPNT
        ldy     FORPNT+1
        jsr     FADD
        jsr     SETFOR
        ldy     #>STACK
        jsr     FCOMP2
        tsx
        sec
        sbc     STACK+BYTES_FP+4,x
        beq     L2C22
        lda     STACK+2*BYTES_FP+5,x
        sta     CURLIN
        lda     STACK+2*BYTES_FP+6,x
        sta     CURLIN+1
        lda     STACK+2*BYTES_FP+8,x
        sta     TXTPTR
        lda     STACK+2*BYTES_FP+7,x
        sta     TXTPTR+1
L2C1F:
        jmp     NEWSTT
L2C22:
        txa
        adc     #2*BYTES_FP+7
        tax
        txs
        jsr     CHRGOT
        cmp     #$2C
        bne     L2C1F
        jsr     CHRGET
        jsr     NEXT1

; ----------------------------------------------------------------------------
; EVALUATE EXPRESSION, MAKE SURE IT IS NUMERIC
; ----------------------------------------------------------------------------
FRMNUM:
        jsr     FRMEVL

; ----------------------------------------------------------------------------
; MAKE SURE (FAC) IS NUMERIC
; ----------------------------------------------------------------------------
CHKNUM:
        clc
        .byte   $24

; ----------------------------------------------------------------------------
; MAKE SURE (FAC) IS STRING
; ----------------------------------------------------------------------------
CHKSTR:
        sec

; ----------------------------------------------------------------------------
; MAKE SURE (FAC) IS CORRECT TYPE
; IF C=0, TYPE MUST BE NUMERIC
; IF C=1, TYPE MUST BE STRING
; ----------------------------------------------------------------------------
CHKVAL:
        bit     VALTYP
        bmi     L2C41
        bcs     L2C43
L2C40:
        rts
L2C41:
        bcs     L2C40
L2C43:
        ldx     #ERR_BADTYPE
JERROR:
        jmp     ERROR

; ----------------------------------------------------------------------------
; EVALUATE THE EXPRESSION AT TXTPTR, LEAVING THE
; RESULT IN FAC.  WORKS FOR BOTH STRING AND NUMERIC
; EXPRESSIONS.
; ----------------------------------------------------------------------------
FRMEVL:
        ldx     TXTPTR
        bne     L2C4E
        dec     TXTPTR+1
L2C4E:
        dec     TXTPTR
        ldx     #$00
        .byte   $24
FRMEVL1:
        pha
        txa
        pha
        lda     #$01
        jsr     CHKMEM
        jsr     FRM_ELEMENT
        lda     #$00
        sta     CPRTYP
FRMEVL2:
        jsr     CHRGOT
L2C65:
        sec
        sbc     #TOKEN_GREATER
        bcc     L2C81
        cmp     #$03
        bcs     L2C81
        cmp     #$01
        rol     a
        eor     #$01
        eor     CPRTYP
        cmp     CPRTYP
        bcc     SNTXERR
        sta     CPRTYP
        jsr     CHRGET
        jmp     L2C65
L2C81:
        ldx     CPRTYP
        bne     FRM_RELATIONAL
        bcs     L2D02
        adc     #$07
        bcc     L2D02
        adc     VALTYP
        bne     L2C92
        jmp     CAT
L2C92:
        adc     #$FF
        sta     INDEX
        asl     a
        adc     INDEX
        tay
FRM_PRECEDENCE_TEST:
        pla
        cmp     MATHTBL,y
        bcs     FRM_PERFORM1
        jsr     CHKNUM
L2CA3:
        pha
L2CA4:
        jsr     FRM_RECURSE
        pla
        ldy     LASTOP
        bpl     PREFNC
        tax
        beq     GOEX
        bne     FRM_PERFORM2

; ----------------------------------------------------------------------------
; FOUND ONE OR MORE RELATIONAL OPERATORS <,=,>
; ----------------------------------------------------------------------------
FRM_RELATIONAL:
        lsr     VALTYP
        txa
        rol     a
        ldx     TXTPTR
        bne     L2CBB
        dec     TXTPTR+1
L2CBB:
        dec     TXTPTR
        ldy     #$1B
        sta     CPRTYP
        bne     FRM_PRECEDENCE_TEST
PREFNC:
        cmp     MATHTBL,y
        bcs     FRM_PERFORM2
        bcc     L2CA3

; ----------------------------------------------------------------------------
; STACK THIS OPERATION AND CALL FRMEVL FOR
; ANOTHER ONE
; ----------------------------------------------------------------------------
FRM_RECURSE:
        lda     MATHTBL+2,y
        pha
        lda     MATHTBL+1,y
        pha
        jsr     FRM_STACK1
        lda     CPRTYP
        jmp     FRMEVL1
SNTXERR:
        jmp     SYNERR

; ----------------------------------------------------------------------------
; STACK (FAC)
; THREE ENTRY POINTS:
; 	1, FROM FRMEVL
;	2, FROM "STEP"
;	3, FROM "FOR"
; ----------------------------------------------------------------------------
FRM_STACK1:
        lda     FACSIGN
        ldx     MATHTBL,y

; ----------------------------------------------------------------------------
; ENTER HERE FROM "STEP", TO PUSH STEP SIGN AND VALUE
; ----------------------------------------------------------------------------
FRM_STACK2:
        tay
        pla
        sta     INDEX
        pla
        sta     INDEX+1
        inc     INDEX
        bne     LEB69
        inc     INDEX+1
LEB69:
        tya
        pha

; ----------------------------------------------------------------------------
; ENTER HERE FROM "FOR", WITH (INDEX) = STEP,
; TO PUSH INITIAL VALUE OF "FOR" VARIABLE
; ----------------------------------------------------------------------------
FRM_STACK3:
        jsr     ROUND_FAC
        lda     FAC+4
        pha
        lda     FAC+3
        pha
        lda     FAC+2
        pha
        lda     FAC+1
        pha
        lda     FAC
        pha
        jmp     (INDEX)
L2D02:
        ldy     #$FF
        pla
GOEX:
        beq     EXIT

; ----------------------------------------------------------------------------
; PERFORM STACKED OPERATION
;
; (A) = PRECEDENCE BYTE
; STACK:  1 -- CPRMASK
;	5 -- (ARG)
;	2 -- ADDR OF PERFORMER
; ----------------------------------------------------------------------------
FRM_PERFORM1:
        cmp     #$64
        beq     L2D0E
        jsr     CHKNUM
L2D0E:
        sty     LASTOP
FRM_PERFORM2:
        pla
        lsr     a
        sta     CPRMASK
        pla
        sta     ARG
        pla
        sta     ARG+1
        pla
        sta     ARG+2
        pla
        sta     ARG+3
        pla
        sta     ARG+4
        pla
        sta     ARGSIGN
        eor     FACSIGN
        sta     SGNCPR
EXIT:
        lda     FAC
        rts

; ----------------------------------------------------------------------------
; GET ELEMENT IN EXPRESSION
;
; GET VALUE OF VARIABLE OR NUMBER AT TXTPNT, OR POINT
; TO STRING DESCRIPTOR IF A STRING, AND PUT IN FAC.
; ----------------------------------------------------------------------------
FRM_ELEMENT:
        lda     #$00
        sta     VALTYP
L2D31:
        jsr     CHRGET
        bcs     L2D39
L2D36:
        jmp     FIN
L2D39:
        jsr     ISLETC
        bcs     FRM_VARIABLE
.ifdef CONFIG_CBM_ALL
        cmp     #$FF
        bne     LCDC1
        lda     #<CON_PI
        ldy     #>CON_PI
        jsr     LOAD_FAC_FROM_YA
        jmp     CHRGET
CON_PI:
        .byte   $82,$49,$0f,$DA,$A1
LCDC1:
.endif
        cmp     #$2E
        beq     L2D36
        cmp     #TOKEN_MINUS
        beq     MIN
        cmp     #TOKEN_PLUS
        beq     L2D31
        cmp     #$22
        bne     NOT_

; ----------------------------------------------------------------------------
; STRING CONSTANT ELEMENT
;
; SET Y,A = (TXTPTR)+CARRY
; ----------------------------------------------------------------------------
STRTXT:
        lda     TXTPTR
        ldy     TXTPTR+1
        adc     #$00
        bcc     L2D57
        iny
L2D57:
        jsr     STRLIT
        jmp     POINT

; ----------------------------------------------------------------------------
; "NOT" FUNCTION
; IF FAC=0, RETURN FAC=1
; IF FAC<>0, RETURN FAC=0
; ----------------------------------------------------------------------------
NOT_:
        cmp     #TOKEN_NOT
        bne     L2D74
        ldy     #$18
        bne     EQUL

; ----------------------------------------------------------------------------
; COMPARISON FOR EQUALITY (= OPERATOR)
; ALSO USED TO EVALUATE "NOT" FUNCTION
; ----------------------------------------------------------------------------
EQUOP:
        jsr     AYINT
        lda     FAC_LAST
        eor     #$FF
        tay
        lda     FAC_LAST-1
        eor     #$FF
        jmp     GIVAYF
L2D74:
        cmp     #TOKEN_FN
        bne     L2D7B
        jmp     L31F3
L2D7B:
        cmp     #TOKEN_SGN
        bcc     PARCHK
        jmp     UNARY

; ----------------------------------------------------------------------------
; EVALUATE "(EXPRESSION)"
; ----------------------------------------------------------------------------
PARCHK:
        jsr     CHKOPN
        jsr     FRMEVL
CHKCLS:
        lda     #$29
        .byte   $2C
CHKOPN:
        lda     #$28
        .byte   $2C
CHKCOM:
        lda     #$2C

; ----------------------------------------------------------------------------
; UNLESS CHAR AT TXTPTR = (A), SYNTAX ERROR
; ----------------------------------------------------------------------------
SYNCHR:	; XXX all CBM code calls SYNCHR instead of CHKCOM
        ldy     #$00
        cmp     (TXTPTR),y
        bne     SYNERR
        jmp     CHRGET
; ----------------------------------------------------------------------------
SYNERR:
        ldx     #ERR_SYNTAX
        jmp     ERROR
; ----------------------------------------------------------------------------
MIN:
        ldy     #$15
EQUL:
        pla
        pla
        jmp     L2CA4
; ----------------------------------------------------------------------------
FRM_VARIABLE:
        jsr     PTRGET
FRM_VARIABLE_CALL	= *-1
        sta     FAC_LAST-1
        sty     FAC_LAST
.ifdef CONFIG_CBM_ALL
        lda     VARNAM
        ldy     VARNAM+1
.endif
        ldx     VALTYP
        beq     L2DB1
.ifdef CONFIG_CBM_ALL
  .ifdef CONFIG_CBM1_PATCHES
        jmp     PATCH2
        clc
LCE3B:
  .else
        ldx     #$00
        stx     STRNG1+1
        bit     FAC+4
        bpl     LCE53
        cmp     #$54	; T
        bne     LCE53
  .endif
        cpy     #$C9	; I$
        bne     LCE53
        jsr     LCE76
        sty     EXPON
        dey
        sty     STRNG2
        ldy     #$06
        sty     INDX
        ldy     #$24
        jsr     LDD3A
        jmp     LD353
LCE53:
.endif
  .ifndef CBM2
; bugfix?
; fixed on AppleSoft II, not on any CBM
        ldx     #$00
        stx     STRNG1+1
  .endif
        rts
L2DB1:
        ldx     VALTYP+1
        bpl     L2DC2
        ldy     #$00
        lda     (FAC+3),y
        tax
        iny
        lda     (FAC+3),y
        tay
        txa
        jmp     GIVAYF
L2DC2:
.ifdef CONFIG_CBM1_PATCHES
        jmp     PATCH3
        .byte   $19
.endif
.ifdef CBM2
        bit     FAC+4
        bpl     LCE90
        cmp     #$54
        bne     LCE82
.endif
.ifndef CONFIG_CBM_ALL
        jmp     LOAD_FAC_FROM_YA
.endif
.ifdef CONFIG_CBM_ALL
LCE69:
        cpy     #$49
.ifdef CBM1
        bne     LCE82
.else
        bne     LCE90
.endif
        jsr     LCE76
        tya
        ldx     #$A0
        jmp     LDB21
LCE76:
.ifdef CBM1
        lda     #$FE
        ldy     #$01
.else
        lda     #$8B
        ldy     #$00
.endif
        sei
        jsr     LOAD_FAC_FROM_YA
        cli
        sty     FAC+1
        rts
LCE82:
        cmp     #$53
        bne     LCE90
        cpy     #$54
        bne     LCE90
        lda     Z96
        jmp     FLOAT
LCE90:
        lda     FAC+3
        ldy     FAC+4
        jmp     LOAD_FAC_FROM_YA
.endif

; ----------------------------------------------------------------------------
UNARY:
        asl     a
        pha
        tax
        jsr     CHRGET
        cpx     #<(TOKEN_LEFTSTR*2-1)
        bcc     L2DEF
        jsr     CHKOPN
        jsr     FRMEVL
        jsr     CHKCOM
        jsr     CHKSTR
        pla
        tax
        lda     FAC_LAST
        pha
        lda     FAC_LAST-1
        pha
        txa
        pha
        jsr     GETBYT
        pla
        tay
        txa
        pha
        jmp     L2DF4
L2DEF:
        jsr     PARCHK
        pla
        tay
L2DF4:
        lda     UNFNC-TOKEN_SGN-TOKEN_SGN+$100,y
        sta     JMPADRS+1
        lda     UNFNC-TOKEN_SGN-TOKEN_SGN+$101,y
        sta     JMPADRS+2
        jsr     JMPADRS
        jmp     CHKNUM

; ----------------------------------------------------------------------------
OR:
        ldy     #$FF
        .byte   $2C
; ----------------------------------------------------------------------------
TAND:
        ldy     #$00
        sty     EOLPNTR
        jsr     AYINT
        lda     FAC_LAST-1
        eor     EOLPNTR
        sta     CHARAC
        lda     FAC_LAST
        eor     EOLPNTR
        sta     ENDCHR
        jsr     COPY_ARG_TO_FAC
        jsr     AYINT
        lda     FAC_LAST
        eor     EOLPNTR
        and     ENDCHR
        eor     EOLPNTR
        tay
        lda     FAC_LAST-1
        eor     EOLPNTR
        and     CHARAC
        eor     EOLPNTR
        jmp     GIVAYF

; ----------------------------------------------------------------------------
; PERFORM RELATIONAL OPERATIONS
; ----------------------------------------------------------------------------
RELOPS:
        jsr     CHKVAL
        bcs     STRCMP
        lda     ARGSIGN
        ora     #$7F
        and     ARG+1
        sta     ARG+1
        lda     #<ARG
        ldy     #$00
        jsr     FCOMP
        tax
        jmp     NUMCMP

; ----------------------------------------------------------------------------
; STRING COMPARISON
; ----------------------------------------------------------------------------
STRCMP:
        lda     #$00
        sta     VALTYP
        dec     CPRTYP
        jsr     FREFAC
        sta     FAC
        stx     FAC+1
        sty     FAC+2
        lda     ARG_LAST-1
        ldy     ARG_LAST
        jsr     FRETMP
        stx     ARG_LAST-1
        sty     ARG_LAST
        tax
        sec
        sbc     FAC
        beq     L2E74
        lda     #$01
        bcc     L2E74
        ldx     FAC
        lda     #$FF
L2E74:
        sta     FACSIGN
        ldy     #$FF
        inx
STRCMP1:
        iny
        dex
        bne     L2E84
        ldx     FACSIGN
NUMCMP:
        bmi     CMPDONE
        clc
        bcc     CMPDONE
L2E84:
        lda     (ARG_LAST-1),y
        cmp     (FAC+1),y
        beq     STRCMP1
        ldx     #$FF
        bcs     CMPDONE
        ldx     #$01
CMPDONE:
        inx
        txa
        rol     a
        and     CPRMASK
        beq     L2E99
        lda     #$FF
L2E99:
        jmp     FLOAT

;.include "var.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; "DIM" STATEMENT
; ----------------------------------------------------------------------------
NXDIM:
        jsr     CHKCOM
DIM:
        tax
        jsr     PTRGET2
        jsr     CHRGOT
        bne     NXDIM
        rts

; ----------------------------------------------------------------------------
; PTRGET -- GENERAL VARIABLE SCAN
;
; SCANS VARIABLE NAME AT TXTPTR, AND SEARCHES THE
; VARTAB AND ARYTAB FOR THE NAME.
; IF NOT FOUND, CREATE VARIABLE OF APPROPRIATE TYPE.
; RETURN WITH ADDRESS IN VARPNT AND Y,A
;
; ACTUAL ACTIVITY CONTROLLED SOMEWHAT BY TWO FLAGS:
;	DIMFLG -- NONZERO IF CALLED FROM "DIM"
;		ELSE = 0
;
;	SUBFLG -- = $00
;		= $40 IF CALLED FROM "GETARYPT"
; ----------------------------------------------------------------------------
PTRGET:
        ldx     #$00
        jsr     CHRGOT
PTRGET2:
        stx     DIMFLG
PTRGET3:
        sta     VARNAM
        jsr     CHRGOT
        jsr     ISLETC
        bcs     NAMOK
SYNERR3:
        jmp     SYNERR
NAMOK:
        ldx     #$00
        stx     VALTYP
        stx     VALTYP+1
        jsr     CHRGET
        bcc     L2ECD
        jsr     ISLETC
        bcc     L2ED8
L2ECD:
        tax
L2ECE:
        jsr     CHRGET
        bcc     L2ECE
        jsr     ISLETC
        bcs     L2ECE
L2ED8:
        cmp     #$24
        bne     L2EE2
        lda     #$FF
        sta     VALTYP
        bne     L2EF2
L2EE2:
        cmp     #$25
        bne     L2EF9
        lda     SUBFLG
        bne     SYNERR3
        lda     #$80
        sta     VALTYP+1
        ora     VARNAM
        sta     VARNAM
L2EF2:
        txa
        ora     #$80
        tax
        jsr     CHRGET
L2EF9:
        stx     VARNAM+1
        sec
        ora     SUBFLG
        sbc     #$28
        bne     L2F05
        jmp     ARRAY
L2F05:
        lda     #$00
        sta     SUBFLG
        lda     VARTAB
        ldx     VARTAB+1
        ldy     #$00
L2F0F:
        stx     LOWTR+1
L2F11:
        sta     LOWTR
        cpx     ARYTAB+1
        bne     L2F1B
        cmp     ARYTAB
        beq     NAMENOTFOUND
L2F1B:
        lda     VARNAM
        cmp     (LOWTR),y
        bne     L2F29
        lda     VARNAM+1
        iny
        cmp     (LOWTR),y
        beq     SET_VARPNT_AND_YA
        dey
L2F29:
        clc
        lda     LOWTR
        adc     #BYTES_PER_VARIABLE
        bcc     L2F11
        inx
        bne     L2F0F

; ----------------------------------------------------------------------------
; CHECK IF (A) IS ASCII LETTER A-Z
;
; RETURN CARRY = 1 IF A-Z
;	= 0 IF NOT
; ----------------------------------------------------------------------------
ISLETC:
        cmp     #$41
        bcc     L2F3C
        sbc     #$5B
        sec
        sbc     #$A5
L2F3C:
        rts

; ----------------------------------------------------------------------------
; VARIABLE NOT FOUND, SO MAKE ONE
; ----------------------------------------------------------------------------
NAMENOTFOUND:
        pla
        pha
        cmp     #<FRM_VARIABLE_CALL
        bne     MAKENEWVARIABLE
.ifdef CONFIG_SAFE_NAMENOTFOUND
        tsx
        lda     STACK+2,x
        cmp     #>FRM_VARIABLE_CALL
        bne     MAKENEWVARIABLE
.endif
LD015:
        lda     #<C_ZERO
        ldy     #>C_ZERO
        rts

; ----------------------------------------------------------------------------


; ----------------------------------------------------------------------------
; MAKE A NEW SIMPLE VARIABLE
;
; MOVE ARRAYS UP 7 BYTES TO MAKE ROOM FOR NEW VARIABLE
; ENTER 7-BYTE VARIABLE DATA IN THE HOLE
; ----------------------------------------------------------------------------
MAKENEWVARIABLE:
.ifdef CONFIG_CBM_ALL
        lda     VARNAM
        ldy     VARNAM+1
        cmp     #$54
        bne     LD02F
        cpy     #$C9
        beq     LD015
        cpy     #$49
        bne     LD02F
LD02C:
        jmp     SYNERR
LD02F:
        cmp     #$53
        bne     LD037
        cpy     #$54
        beq     LD02C
LD037:
.endif
        lda     ARYTAB
        ldy     ARYTAB+1
        sta     LOWTR
        sty     LOWTR+1
        lda     STREND
        ldy     STREND+1
        sta     HIGHTR
        sty     HIGHTR+1
        clc
        adc     #BYTES_PER_VARIABLE
        bcc     L2F68
        iny
L2F68:
        sta     HIGHDS
        sty     HIGHDS+1
        jsr     BLTU
        lda     HIGHDS
        ldy     HIGHDS+1
        iny
        sta     ARYTAB
        sty     ARYTAB+1
        ldy     #$00
        lda     VARNAM
        sta     (LOWTR),y
        iny
        lda     VARNAM+1
        sta     (LOWTR),y
        lda     #$00
        iny
        sta     (LOWTR),y
        iny
        sta     (LOWTR),y
        iny
        sta     (LOWTR),y
        iny
        sta     (LOWTR),y
        iny
        sta     (LOWTR),y

; ----------------------------------------------------------------------------
; PUT ADDRESS OF VALUE OF VARIABLE IN VARPNT AND Y,A
; ----------------------------------------------------------------------------
SET_VARPNT_AND_YA:
        lda     LOWTR
        clc
        adc     #$02
        ldy     LOWTR+1
        bcc     L2F9E
        iny
L2F9E:
        sta     VARPNT
        sty     VARPNT+1
        rts


;.include "array.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; COMPUTE ADDRESS OF FIRST VALUE IN ARRAY
; ARYPNT = (LOWTR) + #DIMS*2 + 5
; ----------------------------------------------------------------------------
GETARY:
        lda     EOLPNTR
        asl     a
        adc     #$05
        adc     LOWTR
        ldy     LOWTR+1
        bcc     L2FAF
        iny
L2FAF:
        sta     HIGHDS
        sty     HIGHDS+1
        rts

; ----------------------------------------------------------------------------
NEG32768:
        .byte   $90,$80,$00,$00

		.byte	$00; bugfix: short number

; ----------------------------------------------------------------------------
; EVALUATE NUMERIC FORMULA AT TXTPTR
; CONVERTING RESULT TO INTEGER 0 <= X <= 32767
; IN FAC+3,4
; ----------------------------------------------------------------------------
MAKINT:
        jsr     CHRGET
        jsr     FRMEVL

; ----------------------------------------------------------------------------
; CONVERT FAC TO INTEGER
; MUST BE POSITIVE AND LESS THAN 32768
; ----------------------------------------------------------------------------
MKINT:
        jsr     CHKNUM
        lda     FACSIGN
        bmi     MI1

; ----------------------------------------------------------------------------
; CONVERT FAC TO INTEGER
; MUST BE -32767 <= FAC <= 32767
; ----------------------------------------------------------------------------
AYINT:
        lda     FAC
        cmp     #$90
        bcc     MI2
        lda     #<NEG32768
        ldy     #>NEG32768
        jsr     FCOMP
MI1:
        bne     IQERR
MI2:
        jmp     QINT

; ----------------------------------------------------------------------------
; LOCATE ARRAY ELEMENT OR CREATE AN ARRAY
; ----------------------------------------------------------------------------
ARRAY:
        lda     DIMFLG
        ora     VALTYP+1
        pha
        lda     VALTYP
        pha
        ldy     #$00
L2FDE:
        tya
        pha
        lda     VARNAM+1
        pha
        lda     VARNAM
        pha
        jsr     MAKINT
        pla
        sta     VARNAM
        pla
        sta     VARNAM+1
        pla
        tay
        tsx
        lda     STACK+2,x
        pha
        lda     STACK+1,x
        pha
        lda     FAC_LAST-1
        sta     STACK+2,x
        lda     FAC_LAST
        sta     STACK+1,x
        iny
        jsr     CHRGOT
        cmp     #$2C
        beq     L2FDE
        sty     EOLPNTR
        jsr     CHKCLS
        pla
        sta     VALTYP
        pla
        sta     VALTYP+1
        and     #$7F
        sta     DIMFLG
; ----------------------------------------------------------------------------
; SEARCH ARRAY TABLE FOR THIS ARRAY NAME
; ----------------------------------------------------------------------------
        ldx     ARYTAB
        lda     ARYTAB+1
L301F:
        stx     LOWTR
        sta     LOWTR+1
        cmp     STREND+1
        bne     L302B
        cpx     STREND
        beq     MAKE_NEW_ARRAY
L302B:
        ldy     #$00
        lda     (LOWTR),y
        iny
        cmp     VARNAM
        bne     L303A
        lda     VARNAM+1
        cmp     (LOWTR),y
        beq     USE_OLD_ARRAY
L303A:
        iny
        lda     (LOWTR),y
        clc
        adc     LOWTR
        tax
        iny
        lda     (LOWTR),y
        adc     LOWTR+1
        bcc     L301F

; ----------------------------------------------------------------------------
; ERROR:  BAD SUBSCRIPTS
; ----------------------------------------------------------------------------
SUBERR:
        ldx     #ERR_BADSUBS
        .byte   $2C

; ----------------------------------------------------------------------------
; ERROR:  ILLEGAL QUANTITY
; ----------------------------------------------------------------------------
IQERR:
        ldx     #ERR_ILLQTY
JER:
        jmp     ERROR

; ----------------------------------------------------------------------------
; FOUND THE ARRAY
; ----------------------------------------------------------------------------
USE_OLD_ARRAY:
        ldx     #ERR_REDIMD
        lda     DIMFLG
        bne     JER
        jsr     GETARY
        lda     EOLPNTR
        ldy     #$04
        cmp     (LOWTR),y
        bne     SUBERR
        jmp     FIND_ARRAY_ELEMENT

; ----------------------------------------------------------------------------
; CREATE A NEW ARRAY, UNLESS CALLED FROM GETARYPT
; ----------------------------------------------------------------------------
MAKE_NEW_ARRAY:
        jsr     GETARY
        jsr     REASON
        lda     #$00
        tay
        sta     STRNG2+1
        ldx     #BYTES_PER_ELEMENT
        lda     VARNAM
        sta     (LOWTR),y
        bpl     L3078
        dex
L3078:
        iny
        lda     VARNAM+1
        sta     (LOWTR),y
        bpl     L3081
        dex
        dex
L3081:
        stx     STRNG2
        lda     EOLPNTR
        iny
        iny
        iny
        sta     (LOWTR),y
L308A:
        ldx     #$0B
        lda     #$00
        bit     DIMFLG
        bvc     L309A
        pla
        clc
        adc     #$01
        tax
        pla
        adc     #$00
L309A:
        iny
        sta     (LOWTR),y
        iny
        txa
        sta     (LOWTR),y
        jsr     MULTIPLY_SUBSCRIPT
        stx     STRNG2
        sta     STRNG2+1
        ldy     INDEX
        dec     EOLPNTR
        bne     L308A
        adc     HIGHDS+1
        bcs     GME
        sta     HIGHDS+1
        tay
        txa
        adc     HIGHDS
        bcc     L30BD
        iny
        beq     GME
L30BD:
        jsr     REASON
        sta     STREND
        sty     STREND+1
        lda     #$00
        inc     STRNG2+1
        ldy     STRNG2
        beq     L30D1
L30CC:
        dey
        sta     (HIGHDS),y
        bne     L30CC
L30D1:
        dec     HIGHDS+1
        dec     STRNG2+1
        bne     L30CC
        inc     HIGHDS+1
        sec
        lda     STREND
        sbc     LOWTR
        ldy     #$02
        sta     (LOWTR),y
        lda     STREND+1
        iny
        sbc     LOWTR+1
        sta     (LOWTR),y
        lda     DIMFLG
        bne     RTS9
        iny

; ----------------------------------------------------------------------------
; FIND SPECIFIED ARRAY ELEMENT
;
; (LOWTR),Y POINTS AT # OF DIMS IN ARRAY DESCRIPTOR
; THE SUBSCRIPTS ARE ALL ON THE STACK AS INTEGERS
; ----------------------------------------------------------------------------
FIND_ARRAY_ELEMENT:
        lda     (LOWTR),y
        sta     EOLPNTR
        lda     #$00
        sta     STRNG2
L30F6:
        sta     STRNG2+1
        iny
        pla
        tax
        sta     FAC_LAST-1
        pla
        sta     FAC_LAST
        cmp     (LOWTR),y
        bcc     FAE2
        bne     GSE
        iny
        txa
        cmp     (LOWTR),y
        bcc     FAE3
; ----------------------------------------------------------------------------
GSE:
        jmp     SUBERR
GME:
        jmp     MEMERR
; ----------------------------------------------------------------------------
FAE2:
        iny
FAE3:
        lda     STRNG2+1
        ora     STRNG2
        clc
        beq     L3124
        jsr     MULTIPLY_SUBSCRIPT
        txa
        adc     FAC_LAST-1
        tax
        tya
        ldy     INDEX
L3124:
        adc     FAC_LAST
        stx     STRNG2
        dec     EOLPNTR
        bne     L30F6

        sta     STRNG2+1
        ldx     #BYTES_FP
        lda     VARNAM
        bpl     L3135
        dex
L3135:
        lda     VARNAM+1
        bpl     L313B
        dex
        dex
L313B:
        stx     RESULT+2
        lda     #$00
        jsr     MULTIPLY_SUBS1
        txa
        adc     HIGHDS
        sta     VARPNT
        tya
        adc     HIGHDS+1
        sta     VARPNT+1
        tay
        lda     VARPNT
RTS9:
        rts

; ----------------------------------------------------------------------------
; MULTIPLY (STRNG2) BY ((LOWTR),Y)
; LEAVING PRODUCT IN A,X.  (HI-BYTE ALSO IN Y.)
; USED ONLY BY ARRAY SUBSCRIPT ROUTINES
; ----------------------------------------------------------------------------
MULTIPLY_SUBSCRIPT:
        sty     INDEX
        lda     (LOWTR),y
        sta     RESULT_LAST-2
        dey
        lda     (LOWTR),y
MULTIPLY_SUBS1:
        sta     RESULT_LAST-1
        lda     #$10
        sta     INDX
        ldx     #$00
        ldy     #$00
L3163:
        txa
        asl     a
        tax
        tya
        rol     a
        tay
        bcs     GME
        asl     STRNG2
        rol     STRNG2+1
        bcc     L317C
        clc
        txa
        adc     RESULT_LAST-2
        tax
        tya
        adc     RESULT_LAST-1
        tay
        bcs     GME
L317C:
        dec     INDX
        bne     L3163
        rts

;.include "misc2.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; "FRE" FUNCTION
;
; COLLECTS GARBAGE AND RETURNS # BYTES OF MEMORY LEFT
; ----------------------------------------------------------------------------
FRE:
        lda     VALTYP
        beq     L3188
        jsr     FREFAC
L3188:
        jsr     GARBAG
        sec
        lda     FRETOP
        sbc     STREND
        tay
        lda     FRETOP+1
        sbc     STREND+1
; FALL INTO GIVAYF TO FLOAT THE VALUE
; NOTE THAT VALUES OVER 32767 WILL RETURN AS NEGATIVE

; ----------------------------------------------------------------------------
; FLOAT THE SIGNED INTEGER IN A,Y
; ----------------------------------------------------------------------------
GIVAYF:
        ldx     #$00
        stx     VALTYP
        sta     FAC+1
        sty     FAC+2
        ldx     #$90
        jmp     FLOAT1
POS:
        ldy     POSX

; ----------------------------------------------------------------------------
; FLOAT (Y) INTO FAC, GIVING VALUE 0-255
; ----------------------------------------------------------------------------
SNGFLT:
        lda     #$00
        beq     GIVAYF

; ----------------------------------------------------------------------------
; CHECK FOR DIRECT OR RUNNING MODE
; GIVING ERROR IF DIRECT MODE
; ----------------------------------------------------------------------------
ERRDIR:
        ldx     CURLIN+1
        inx
        bne     RTS9
        ldx     #ERR_ILLDIR
        .byte   $2C
LD288:
        ldx     #ERR_UNDEFFN
L31AF:
        jmp     ERROR
DEF:
        jsr     FNC
        jsr     ERRDIR
        jsr     CHKOPN
        lda     #$80
        sta     SUBFLG
        jsr     PTRGET
        jsr     CHKNUM
        jsr     CHKCLS
        lda     #TOKEN_EQUAL
        jsr     SYNCHR
        pha
        lda     VARPNT+1
        pha
        lda     VARPNT
        pha
        lda     TXTPTR+1
        pha
        lda     TXTPTR
        pha
        jsr     DATA
        jmp     L3250
FNC:
        lda     #TOKEN_FN
        jsr     SYNCHR
        ora     #$80
        sta     SUBFLG
        jsr     PTRGET3
        sta     FNCNAM
        sty     FNCNAM+1
        jmp     CHKNUM
L31F3:
        jsr     FNC
        lda     FNCNAM+1
        pha
        lda     FNCNAM
        pha
        jsr     PARCHK
        jsr     CHKNUM
        pla
        sta     FNCNAM
        pla
        sta     FNCNAM+1
        ldy     #$02
        lda     (FNCNAM),y
        sta     VARPNT
        tax
        iny
        lda     (FNCNAM),y
        beq     LD288
        sta     VARPNT+1
        iny
L3219:
        lda     (VARPNT),y
        pha
        dey
        bpl     L3219
        ldy     VARPNT+1
        jsr     STORE_FAC_AT_YX_ROUNDED
        lda     TXTPTR+1
        pha
        lda     TXTPTR
        pha
        lda     (FNCNAM),y
        sta     TXTPTR
        iny
        lda     (FNCNAM),y
        sta     TXTPTR+1
        lda     VARPNT+1
        pha
        lda     VARPNT
        pha
        jsr     FRMNUM
        pla
        sta     FNCNAM
        pla
        sta     FNCNAM+1
        jsr     CHRGOT
        beq     L324A
        jmp     SYNERR
L324A:
        pla
        sta     TXTPTR
        pla
        sta     TXTPTR+1
L3250:
        ldy     #$00
        pla
        sta     (FNCNAM),y
        pla
        iny
        sta     (FNCNAM),y
        pla
        iny
        sta     (FNCNAM),y
        pla
        iny
        sta     (FNCNAM),y
        pla
        iny
        sta     (FNCNAM),y
        rts

;.include "string.s"

.segment "MSBCODE"
; ----------------------------------------------------------------------------
; "STR$" FUNCTION
; ----------------------------------------------------------------------------
STR:
        jsr     CHKNUM
        ldy     #$00
        jsr     FOUT1
        pla
        pla
LD353:
        lda     #<(STACK2-1)
        ldy     #>(STACK2-1)
        beq     STRLIT

; ----------------------------------------------------------------------------
; GET SPACE AND MAKE DESCRIPTOR FOR STRING WHOSE
; ADDRESS IS IN FAC+3,4 AND WHOSE LENGTH IS IN A-REG
; ----------------------------------------------------------------------------
STRINI:
        ldx     FAC_LAST-1
        ldy     FAC_LAST
        stx     DSCPTR
        sty     DSCPTR+1

; ----------------------------------------------------------------------------
; GET SPACE AND MAKE DESCRIPTOR FOR STRING WHOSE
; ADDRESS IS IN Y,X AND WHOSE LENGTH IS IN A-REG
; ----------------------------------------------------------------------------
STRSPA:
        jsr     GETSPA
        stx     FAC+1
        sty     FAC+2
        sta     FAC
        rts

; ----------------------------------------------------------------------------
; BUILD A DESCRIPTOR FOR STRING STARTING AT Y,A
; AND TERMINATED BY $00 OR QUOTATION MARK
; RETURN WITH DESCRIPTOR IN A TEMPORARY
; AND ADDRESS OF DESCRIPTOR IN FAC+3,4
; ----------------------------------------------------------------------------
STRLIT:
        ldx     #$22
        stx     CHARAC
        stx     ENDCHR

; ----------------------------------------------------------------------------
; BUILD A DESCRIPTOR FOR STRING STARTING AT Y,A
; AND TERMINATED BY $00, (CHARAC), OR (ENDCHR)
;
; RETURN WITH DESCRIPTOR IN A TEMPORARY
; AND ADDRESS OF DESCRIPTOR IN FAC+3,4
; ----------------------------------------------------------------------------
STRLT2:
        sta     STRNG1
        sty     STRNG1+1
        sta     FAC+1
        sty     FAC+2
        ldy     #$FF
L3298:
        iny
        lda     (STRNG1),y
        beq     L32A9
        cmp     CHARAC
        beq     L32A5
        cmp     ENDCHR
        bne     L3298
L32A5:
        cmp     #$22
        beq     L32AA
L32A9:
        clc
L32AA:
        sty     FAC
        tya
        adc     STRNG1
        sta     STRNG2
        ldx     STRNG1+1
        bcc     L32B6
        inx
L32B6:
        stx     STRNG2+1
        lda     STRNG1+1
.ifdef CONFIG_NO_INPUTBUFFER_ZP
        beq     LD399
        cmp     #>INPUTBUFFER
.endif
        bne     PUTNEW
LD399:
        tya
        jsr     STRINI
        ldx     STRNG1
        ldy     STRNG1+1
        jsr     MOVSTR

; ----------------------------------------------------------------------------
; STORE DESCRIPTOR IN TEMPORARY DESCRIPTOR STACK
;
; THE DESCRIPTOR IS NOW IN FAC, FAC+1, FAC+2
; PUT ADDRESS OF TEMP DESCRIPTOR IN FAC+3,4
; ----------------------------------------------------------------------------
PUTNEW:
        ldx     TEMPPT
        cpx     #TEMPST+9
        bne     PUTEMP
        ldx     #ERR_FRMCPX
JERR:
        jmp     ERROR
PUTEMP:
        lda     FAC
        sta     0,x
        lda     FAC+1
        sta     1,x
        lda     FAC+2
        sta     2,x
        ldy     #$00
        stx     FAC_LAST-1
        sty     FAC_LAST
        sty     FACEXTENSION
        dey
        sty     VALTYP
        stx     LASTPT
        inx
        inx
        inx
        stx     TEMPPT
        rts

; ----------------------------------------------------------------------------
; MAKE SPACE FOR STRING AT BOTTOM OF STRING SPACE
; (A)=# BYTES SPACE TO MAKE
;
; RETURN WITH (A) SAME,
;	AND Y,X = ADDRESS OF SPACE ALLOCATED
; ----------------------------------------------------------------------------
GETSPA:
        lsr     DATAFLG
L32F1:
        pha
        eor     #$FF
        sec
        adc     FRETOP
        ldy     FRETOP+1
        bcs     L32FC
        dey
L32FC:
        cpy     STREND+1
        bcc     L3311
        bne     L3306
        cmp     STREND
        bcc     L3311
L3306:
        sta     FRETOP
        sty     FRETOP+1
        sta     FRESPC
        sty     FRESPC+1
        tax
        pla
        rts
L3311:
        ldx     #ERR_MEMFULL
        lda     DATAFLG
        bmi     JERR
        jsr     GARBAG
        lda     #$80
        sta     DATAFLG
        pla
        bne     L32F1

; ----------------------------------------------------------------------------
; SHOVE ALL REFERENCED STRINGS AS HIGH AS POSSIBLE
; IN MEMORY (AGAINST HIMEM), FREEING UP SPACE
; BELOW STRING AREA DOWN TO STREND.
; ----------------------------------------------------------------------------
GARBAG:

.ifdef CONST_MEMSIZ
        ldx     #<CONST_MEMSIZ
        lda     #>CONST_MEMSIZ
.else
        ldx     MEMSIZ
        lda     MEMSIZ+1
.endif
FINDHIGHESTSTRING:
        stx     FRETOP
        sta     FRETOP+1
        ldy     #$00
        sty     FNCNAM+1
        sty     FNCNAM	; GC bugfix!
        lda     STREND
        ldx     STREND+1
        sta     LOWTR
        stx     LOWTR+1
        lda     #TEMPST
        ldx     #$00
        sta     INDEX
        stx     INDEX+1
L333D:
        cmp     TEMPPT
        beq     L3346
        jsr     CHECK_VARIABLE
        beq     L333D
L3346:
        lda     #BYTES_PER_VARIABLE
        sta     DSCLEN
        lda     VARTAB
        ldx     VARTAB+1
        sta     INDEX
        stx     INDEX+1
L3352:
        cpx     ARYTAB+1
        bne     L335A
        cmp     ARYTAB
        beq     L335F
L335A:
        jsr     CHECK_SIMPLE_VARIABLE
        beq     L3352
L335F:
        sta     HIGHDS
        stx     HIGHDS+1
        lda     #$03	; OSI GC bugfix -> $04 ???
        sta     DSCLEN
L3367:
        lda     HIGHDS
        ldx     HIGHDS+1
L336B:
        cpx     STREND+1
        bne     L3376
        cmp     STREND
        bne     L3376
        jmp     MOVE_HIGHEST_STRING_TO_TOP
L3376:
        sta     INDEX
        stx     INDEX+1
        ldy     #$00
        lda     (INDEX),y
        tax
        iny
        lda     (INDEX),y
        php
        iny
        lda     (INDEX),y
        adc     HIGHDS
        sta     HIGHDS
        iny
        lda     (INDEX),y
        adc     HIGHDS+1
        sta     HIGHDS+1
        plp
        bpl     L3367
        txa
        bmi     L3367
        iny
        lda     (INDEX),y
.ifdef CONFIG_CBM1_PATCHES
        jsr     LE7F3 ; XXX patch, call into screen editor
.else
        ldy     #$00	; GC bugfix
        asl     a
        adc     #$05
.endif
        adc     INDEX
        sta     INDEX
        bcc     L33A7
        inc     INDEX+1
L33A7:
        ldx     INDEX+1
L33A9:
        cpx     HIGHDS+1
        bne     L33B1
        cmp     HIGHDS
        beq     L336B
L33B1:
        jsr     CHECK_VARIABLE
        beq     L33A9

; ----------------------------------------------------------------------------
; PROCESS A SIMPLE VARIABLE
; ----------------------------------------------------------------------------
CHECK_SIMPLE_VARIABLE:
        lda     (INDEX),y
        bmi     CHECK_BUMP
        iny
        lda     (INDEX),y
        bpl     CHECK_BUMP
        iny

; ----------------------------------------------------------------------------
; IF STRING IS NOT EMPTY, CHECK IF IT IS HIGHEST
; ----------------------------------------------------------------------------
CHECK_VARIABLE:
        lda     (INDEX),y
        beq     CHECK_BUMP
        iny
        lda     (INDEX),y
        tax
        iny
        lda     (INDEX),y
        cmp     FRETOP+1
        bcc     L33D5
        bne     CHECK_BUMP
        cpx     FRETOP
        bcs     CHECK_BUMP
L33D5:
        cmp     LOWTR+1
        bcc     CHECK_BUMP
        bne     L33DF
        cpx     LOWTR
        bcc     CHECK_BUMP
L33DF:
        stx     LOWTR
        sta     LOWTR+1
        lda     INDEX
        ldx     INDEX+1
        sta     FNCNAM
        stx     FNCNAM+1
        lda     DSCLEN
        sta     Z52

; ----------------------------------------------------------------------------
; ADD (DSCLEN) TO PNTR IN INDEX
; RETURN WITH Y=0, PNTR ALSO IN X,A
; ----------------------------------------------------------------------------
CHECK_BUMP:
        lda     DSCLEN
        clc
        adc     INDEX
        sta     INDEX
        bcc     L33FA
        inc     INDEX+1
L33FA:
        ldx     INDEX+1
        ldy     #$00
        rts

; ----------------------------------------------------------------------------
; FOUND HIGHEST NON-EMPTY STRING, SO MOVE IT
; TO TOP AND GO BACK FOR ANOTHER
; ----------------------------------------------------------------------------
MOVE_HIGHEST_STRING_TO_TOP:
        lda     FNCNAM+1	; GC bugfix
        ora     FNCNAM
        beq     L33FA
        lda     Z52
        and     #$04
        lsr     a
        tay
        sta     Z52
        lda     (FNCNAM),y
        adc     LOWTR
        sta     HIGHTR
        lda     LOWTR+1
        adc     #$00
        sta     HIGHTR+1
        lda     FRETOP
        ldx     FRETOP+1
        sta     HIGHDS
        stx     HIGHDS+1
        jsr     BLTU2
        ldy     Z52
        iny
        lda     HIGHDS
        sta     (FNCNAM),y
        tax
        inc     HIGHDS+1
        lda     HIGHDS+1
        iny
        sta     (FNCNAM),y
        jmp     FINDHIGHESTSTRING

; ----------------------------------------------------------------------------
; CONCATENATE TWO STRINGS
; ----------------------------------------------------------------------------
CAT:
        lda     FAC_LAST
        pha
        lda     FAC_LAST-1
        pha
        jsr     FRM_ELEMENT
        jsr     CHKSTR
        pla
        sta     STRNG1
        pla
        sta     STRNG1+1
        ldy     #$00
        lda     (STRNG1),y
        clc
        adc     (FAC_LAST-1),y
        bcc     L3454
        ldx     #ERR_STRLONG
        jmp     ERROR
L3454:
        jsr     STRINI
        jsr     MOVINS
        lda     DSCPTR
        ldy     DSCPTR+1
        jsr     FRETMP
        jsr     MOVSTR1
        lda     STRNG1
        ldy     STRNG1+1
        jsr     FRETMP
        jsr     PUTNEW
        jmp     FRMEVL2

; ----------------------------------------------------------------------------
; GET STRING DESCRIPTOR POINTED AT BY (STRNG1)
; AND MOVE DESCRIBED STRING TO (FRESPC)
; ----------------------------------------------------------------------------
MOVINS:
        ldy     #$00
        lda     (STRNG1),y
        pha
        iny
        lda     (STRNG1),y
        tax
        iny
        lda     (STRNG1),y
        tay
        pla

; ----------------------------------------------------------------------------
; MOVE STRING AT (Y,X) WITH LENGTH (A)
; TO DESTINATION WHOSE ADDRESS IS IN FRESPC,FRESPC+1
; ----------------------------------------------------------------------------
MOVSTR:
        stx     INDEX
        sty     INDEX+1
MOVSTR1:
        tay
        beq     L3490
        pha
L3487:
        dey
        lda     (INDEX),y
        sta     (FRESPC),y
        tya
        bne     L3487
        pla
L3490:
        clc
        adc     FRESPC
        sta     FRESPC
        bcc     L3499
        inc     FRESPC+1
L3499:
        rts

; ----------------------------------------------------------------------------
; IF (FAC) IS A TEMPORARY STRING, RELEASE DESCRIPTOR
; ----------------------------------------------------------------------------
FRESTR:
        jsr     CHKSTR

; ----------------------------------------------------------------------------
; IF STRING DESCRIPTOR POINTED TO BY FAC+3,4 IS
; A TEMPORARY STRING, RELEASE IT.
; ----------------------------------------------------------------------------
FREFAC:
        lda     FAC_LAST-1
        ldy     FAC_LAST

; ----------------------------------------------------------------------------
; IF STRING DESCRIPTOR WHOSE ADDRESS IS IN Y,A IS
; A TEMPORARY STRING, RELEASE IT.
; ----------------------------------------------------------------------------
FRETMP:
        sta     INDEX
        sty     INDEX+1
        jsr     FRETMS
        php
        ldy     #$00
        lda     (INDEX),y
        pha
        iny
        lda     (INDEX),y
        tax
        iny
        lda     (INDEX),y
        tay
        pla
        plp
        bne     L34CD
        cpy     FRETOP+1
        bne     L34CD
        cpx     FRETOP
        bne     L34CD
        pha
        clc
        adc     FRETOP
        sta     FRETOP
        bcc     L34CC
        inc     FRETOP+1
L34CC:
        pla
L34CD:
        stx     INDEX
        sty     INDEX+1
        rts

; ----------------------------------------------------------------------------
; RELEASE TEMPORARY DESCRIPTOR IF Y,A = LASTPT
; ----------------------------------------------------------------------------
FRETMS:
        cpy     LASTPT+1
        bne     L34E2
        cmp     LASTPT
        bne     L34E2
        sta     TEMPPT
        sbc     #$03
        sta     LASTPT
        ldy     #$00
L34E2:
        rts

; ----------------------------------------------------------------------------
; "CHR$" FUNCTION
; ----------------------------------------------------------------------------
CHRSTR:
        jsr     CONINT
        txa
        pha
        lda     #$01
        jsr     STRSPA
        pla
        ldy     #$00
        sta     (FAC+1),y
        pla
        pla
        jmp     PUTNEW

; ----------------------------------------------------------------------------
; "LEFT$" FUNCTION
; ----------------------------------------------------------------------------
LEFTSTR:
        jsr     SUBSTRING_SETUP
        cmp     (DSCPTR),y
        tya
SUBSTRING1:
        bcc     L3503
        lda     (DSCPTR),y
        tax
        tya
L3503:
        pha
SUBSTRING2:
        txa
SUBSTRING3:
        pha
        jsr     STRSPA
        lda     DSCPTR
        ldy     DSCPTR+1
        jsr     FRETMP
        pla
        tay
        pla
        clc
        adc     INDEX
        sta     INDEX
        bcc     L351C
        inc     INDEX+1
L351C:
        tya
        jsr     MOVSTR1
        jmp     PUTNEW

; ----------------------------------------------------------------------------
; "RIGHT$" FUNCTION
; ----------------------------------------------------------------------------
RIGHTSTR:
        jsr     SUBSTRING_SETUP
        clc
        sbc     (DSCPTR),y
        eor     #$FF
        jmp     SUBSTRING1

; ----------------------------------------------------------------------------
; "MID$" FUNCTION
; ----------------------------------------------------------------------------
MIDSTR:
        lda     #$FF
        sta     FAC_LAST
        jsr     CHRGOT
        cmp     #$29
        beq     L353F
        jsr     CHKCOM
        jsr     GETBYT
L353F:
        jsr     SUBSTRING_SETUP
        beq     GOIQ
        dex
        txa
        pha
        clc
        ldx     #$00
        sbc     (DSCPTR),y
        bcs     SUBSTRING2
        eor     #$FF
        cmp     FAC_LAST
        bcc     SUBSTRING3
        lda     FAC_LAST
        bcs     SUBSTRING3

; ----------------------------------------------------------------------------
; COMMON SETUP ROUTINE FOR LEFT$, RIGHT$, MID$:
; REQUIRE ")"; POP RETURN ADRS, GET DESCRIPTOR
; ADDRESS, GET 1ST PARAMETER OF COMMAND
; ----------------------------------------------------------------------------
SUBSTRING_SETUP:
        jsr     CHKCLS
        pla
        tay
        pla
        sta     Z52
        pla
        pla
        pla
        tax
        pla
        sta     DSCPTR
        pla
        sta     DSCPTR+1
        lda     Z52
        pha
        tya
        pha
        ldy     #$00
        txa
        rts

; ----------------------------------------------------------------------------
; "LEN" FUNCTION
; ----------------------------------------------------------------------------
LEN:
        jsr     GETSTR
SNGFLT1:
        jmp     SNGFLT

; ----------------------------------------------------------------------------
; IF LAST RESULT IS A TEMPORARY STRING, FREE IT
; MAKE VALTYP NUMERIC, RETURN LENGTH IN Y-REG
; ----------------------------------------------------------------------------
GETSTR:
        jsr     FRESTR
        ldx     #$00
        stx     VALTYP
        tay
        rts

; ----------------------------------------------------------------------------
; "ASC" FUNCTION
; ----------------------------------------------------------------------------
ASC:
        jsr     GETSTR
        beq     GOIQ
        ldy     #$00
        lda     (INDEX),y
        tay
        jmp     SNGFLT
; ----------------------------------------------------------------------------
GOIQ:
        jmp     IQERR

; ----------------------------------------------------------------------------
; SCAN TO NEXT CHARACTER AND CONVERT EXPRESSION
; TO SINGLE BYTE IN X-REG
; ----------------------------------------------------------------------------
GTBYTC:
        jsr     CHRGET

; ----------------------------------------------------------------------------
; EVALUATE EXPRESSION AT TXTPTR, AND
; CONVERT IT TO SINGLE BYTE IN X-REG
; ----------------------------------------------------------------------------
GETBYT:
        jsr     FRMNUM

; ----------------------------------------------------------------------------
; CONVERT (FAC) TO SINGLE BYTE INTEGER IN X-REG
; ----------------------------------------------------------------------------
CONINT:
        jsr     MKINT
        ldx     FAC_LAST-1
        bne     GOIQ
        ldx     FAC_LAST
        jmp     CHRGOT

; ----------------------------------------------------------------------------
; "VAL" FUNCTION
; ----------------------------------------------------------------------------
VAL:
        jsr     GETSTR
        bne     L35AC
        jmp     ZERO_FAC
L35AC:
        ldx     TXTPTR
        ldy     TXTPTR+1
        stx     STRNG2
        sty     STRNG2+1
        ldx     INDEX
        stx     TXTPTR
        clc
        adc     INDEX
        sta     DEST
        ldx     INDEX+1
        stx     TXTPTR+1
        bcc     L35C4
        inx
L35C4:
        stx     DEST+1
        ldy     #$00
        lda     (DEST),y
        pha
        lda     #$00
        sta     (DEST),y
        jsr     CHRGOT
        jsr     FIN
        pla
        ldy     #$00
        sta     (DEST),y

; ----------------------------------------------------------------------------
; COPY STRNG2 INTO TXTPTR
; ----------------------------------------------------------------------------
POINT:
        ldx     STRNG2
        ldy     STRNG2+1
        stx     TXTPTR
        sty     TXTPTR+1
        rts

;.include "poke.s"

.segment "MSBCODE"

.ifndef CONFIG_NO_POKE
; ----------------------------------------------------------------------------
; EVALUATE "EXP1,EXP2"
;
; CONVERT EXP1 TO 16-BIT NUMBER IN LINNUM
; CONVERT EXP2 TO 8-BIT NUMBER IN X-REG
; ----------------------------------------------------------------------------
GTNUM:
        jsr     FRMNUM
        jsr     GETADR

; ----------------------------------------------------------------------------
; EVALUATE ",EXPRESSION"
; CONVERT EXPRESSION TO SINGLE BYTE IN X-REG
; ----------------------------------------------------------------------------
COMBYTE:
        jsr     CHKCOM
        jmp     GETBYT

; ----------------------------------------------------------------------------
; CONVERT (FAC) TO A 16-BIT VALUE IN LINNUM
; ----------------------------------------------------------------------------
GETADR:
        lda     FACSIGN
        bmi     GOIQ
        lda     FAC
        cmp     #$91
        bcs     GOIQ
        jsr     QINT
        lda     FAC_LAST-1
        ldy     FAC_LAST
        sty     LINNUM
        sta     LINNUM+1
        rts

; ----------------------------------------------------------------------------
; "PEEK" FUNCTION
; ----------------------------------------------------------------------------
PEEK:
.ifdef CONFIG_PEEK_SAVE_LINNUM
        lda     LINNUM+1
        pha
        lda     LINNUM
        pha
.endif
        jsr     GETADR
        ldy     #$00
.ifdef CBM1
; disallow PEEK between $C000 and $DFFF
        cmp     #$C0
        bcc     LD6F3
        cmp     #$E1
        bcc     LD6F6
LD6F3:
.endif
.ifdef CBM2
		nop ; patch that disables the compares above
		nop
		nop
		nop
		nop
		nop
		nop
		nop
.endif
        lda     (LINNUM),y
        tay
.ifdef CONFIG_PEEK_SAVE_LINNUM
        pla
        sta     LINNUM
        pla
        sta     LINNUM+1
.endif
LD6F6:
        jmp     SNGFLT

; ----------------------------------------------------------------------------
; "POKE" STATEMENT
; ----------------------------------------------------------------------------
POKE:
        jsr     GTNUM
        txa
        ldy     #$00
        sta     (LINNUM),y
        rts

; ----------------------------------------------------------------------------
; "WAIT" STATEMENT
; ----------------------------------------------------------------------------
WAIT:
        jsr     GTNUM
        stx     FORPNT
        ldx     #$00
        jsr     CHRGOT
.ifdef CONFIG_EASTER_EGG
        beq     EASTER_EGG
.else
        beq     L3628
.endif
        jsr     COMBYTE
L3628:
        stx     FORPNT+1
        ldy     #$00
L362C:
        lda     (LINNUM),y
        eor     FORPNT+1
        and     FORPNT
        beq     L362C
RTS3:
        rts
.endif

;.include "float.s"

.segment "MSBCODE"

TEMP1X = TEMP1+(5-BYTES_FP)

; ----------------------------------------------------------------------------
; ADD 0.5 TO FAC
; ----------------------------------------------------------------------------
FADDH:
        lda     #<CON_HALF
        ldy     #>CON_HALF
        jmp     FADD

; ----------------------------------------------------------------------------
; FAC = (Y,A) - FAC
; ----------------------------------------------------------------------------
FSUB:
        jsr     LOAD_ARG_FROM_YA

; ----------------------------------------------------------------------------
; FAC = ARG - FAC
; ----------------------------------------------------------------------------
FSUBT:
        lda     FACSIGN
        eor     #$FF
        sta     FACSIGN
        eor     ARGSIGN
        sta     SGNCPR
        lda     FAC
        jmp     FADDT

; ----------------------------------------------------------------------------
; Commodore BASIC V2 Easter Egg
; ----------------------------------------------------------------------------
.ifdef CONFIG_EASTER_EGG
EASTER_EGG:
        lda     LINNUM
        cmp     #<6502
        bne     L3628
        lda     LINNUM+1
        sbc     #>6502
        bne     L3628
        sta     LINNUM
        tay
        lda     #$80
        sta     LINNUM+1
LD758:
        ldx     #$0A
LD75A:
        lda     MICROSOFT-1,x
        and     #$3F
        sta     (LINNUM),y
        iny
        bne     LD766
        inc     LINNUM+1
LD766:
        dex
        bne     LD75A
        dec     FORPNT
        bne     LD758
        rts
.endif

; ----------------------------------------------------------------------------
; SHIFT SMALLER ARGUMENT MORE THAN 7 BITS
; ----------------------------------------------------------------------------
FADD1:
        jsr     SHIFT_RIGHT
        bcc     FADD3

; ----------------------------------------------------------------------------
; FAC = (Y,A) + FAC
; ----------------------------------------------------------------------------
FADD:
        jsr     LOAD_ARG_FROM_YA

; ----------------------------------------------------------------------------
; FAC = ARG + FAC
; ----------------------------------------------------------------------------
FADDT:
        bne     L365B
        jmp     COPY_ARG_TO_FAC
L365B:
        ldx     FACEXTENSION
        stx     ARGEXTENSION
        ldx     #ARG
        lda     ARG
FADD2:
        tay
        beq     RTS3
        sec
        sbc     FAC
        beq     FADD3
        bcc     L367F
        sty     FAC
        ldy     ARGSIGN
        sty     FACSIGN
        eor     #$FF
        adc     #$00
        ldy     #$00
        sty     ARGEXTENSION
        ldx     #FAC
        bne     L3683
L367F:
        ldy     #$00
        sty     FACEXTENSION
L3683:
        cmp     #$F9
        bmi     FADD1
        tay
        lda     FACEXTENSION
        lsr     1,x
        jsr     SHIFT_RIGHT4
FADD3:
        bit     SGNCPR
        bpl     FADD4
        ldy     #FAC
        cpx     #ARG
        beq     L369B
        ldy     #ARG
L369B:
        sec
        eor     #$FF
        adc     ARGEXTENSION
        sta     FACEXTENSION
        lda     4,y
        sbc     4,x
        sta     FAC+4
        lda     3,y
        sbc     3,x
        sta     FAC+3
        lda     2,y
        sbc     2,x
        sta     FAC+2
        lda     1,y
        sbc     1,x
        sta     FAC+1

; ----------------------------------------------------------------------------
; NORMALIZE VALUE IN FAC
; ----------------------------------------------------------------------------
NORMALIZE_FAC1:
        bcs     NORMALIZE_FAC2
        jsr     COMPLEMENT_FAC
NORMALIZE_FAC2:
        ldy     #$00
        tya
        clc
L36C7:
        ldx     FAC+1
        bne     NORMALIZE_FAC4
        ldx     FAC+2
        stx     FAC+1
        ldx     FAC+3
        stx     FAC+2
        ldx     FAC+4
        stx     FAC+3
        ldx     FACEXTENSION
        stx     FAC+4
        sty     FACEXTENSION
        adc     #$08
; bugfix?
; fix does not exist on AppleSoft 2
        cmp     #(MANTISSA_BYTES+1)*8
        bne     L36C7

; ----------------------------------------------------------------------------
; SET FAC = 0
; (ONLY NECESSARY TO ZERO EXPONENT AND SIGN CELLS)
; ----------------------------------------------------------------------------
ZERO_FAC:
        lda     #$00
STA_IN_FAC_SIGN_AND_EXP:
        sta     FAC
STA_IN_FAC_SIGN:
        sta     FACSIGN
        rts

; ----------------------------------------------------------------------------
; ADD MANTISSAS OF FAC AND ARG INTO FAC
; ----------------------------------------------------------------------------
FADD4:
        adc     ARGEXTENSION
        sta     FACEXTENSION
        lda     FAC+4
        adc     ARG+4
        sta     FAC+4
        lda     FAC+3
        adc     ARG+3
        sta     FAC+3
        lda     FAC+2
        adc     ARG+2
        sta     FAC+2
        lda     FAC+1
        adc     ARG+1
        sta     FAC+1
        jmp     NORMALIZE_FAC5

; ----------------------------------------------------------------------------
; FINISH NORMALIZING FAC
; ----------------------------------------------------------------------------
NORMALIZE_FAC3:
        adc     #$01
        asl     FACEXTENSION
        rol     FAC+4
        rol     FAC+3
        rol     FAC+2
        rol     FAC+1
NORMALIZE_FAC4:
        bpl     NORMALIZE_FAC3
        sec
        sbc     FAC
        bcs     ZERO_FAC
        eor     #$FF
        adc     #$01
        sta     FAC
NORMALIZE_FAC5:
        bcc     L3764
NORMALIZE_FAC6:
        inc     FAC
        beq     OVERFLOW
        ror     FAC+1
        ror     FAC+2
        ror     FAC+3
        ror     FAC+4
        ror     FACEXTENSION
L3764:
        rts

; ----------------------------------------------------------------------------
; 2'S COMPLEMENT OF FAC
; ----------------------------------------------------------------------------
COMPLEMENT_FAC:
        lda     FACSIGN
        eor     #$FF
        sta     FACSIGN

; ----------------------------------------------------------------------------
; 2'S COMPLEMENT OF FAC MANTISSA ONLY
; ----------------------------------------------------------------------------
COMPLEMENT_FAC_MANTISSA:
        lda     FAC+1
        eor     #$FF
        sta     FAC+1
        lda     FAC+2
        eor     #$FF
        sta     FAC+2
        lda     FAC+3
        eor     #$FF
        sta     FAC+3
        lda     FAC+4
        eor     #$FF
        sta     FAC+4
        lda     FACEXTENSION
        eor     #$FF
        sta     FACEXTENSION
        inc     FACEXTENSION
        bne     RTS12

; ----------------------------------------------------------------------------
; INCREMENT FAC MANTISSA
; ----------------------------------------------------------------------------
INCREMENT_FAC_MANTISSA:
        inc     FAC+4
        bne     RTS12
        inc     FAC+3
        bne     RTS12
        inc     FAC+2
        bne     RTS12
        inc     FAC+1
RTS12:
        rts
OVERFLOW:
        ldx     #ERR_OVERFLOW
        jmp     ERROR

; ----------------------------------------------------------------------------
; SHIFT 1,X THRU 5,X RIGHT
; (A) = NEGATIVE OF SHIFT COUNT
; (X) = POINTER TO BYTES TO BE SHIFTED
;
; RETURN WITH (Y)=0, CARRY=0, EXTENSION BITS IN A-REG
; ----------------------------------------------------------------------------
SHIFT_RIGHT1:
        ldx     #RESULT-1
SHIFT_RIGHT2:
        ldy     4,x
        sty     FACEXTENSION
        ldy     3,x
        sty     4,x
        ldy     2,x
        sty     3,x
        ldy     1,x
        sty     2,x
        ldy     SHIFTSIGNEXT
        sty     1,x

; ----------------------------------------------------------------------------
; MAIN ENTRY TO RIGHT SHIFT SUBROUTINE
; ----------------------------------------------------------------------------
SHIFT_RIGHT:
        adc     #$08
        bmi     SHIFT_RIGHT2
        beq     SHIFT_RIGHT2
        sbc     #$08
        tay
        lda     FACEXTENSION
        bcs     SHIFT_RIGHT5
LB588:
        asl     1,x
        bcc     LB58E
        inc     1,x
LB58E:
        ror     1,x
        ror     1,x

; ----------------------------------------------------------------------------
; ENTER HERE FOR SHORT SHIFTS WITH NO SIGN EXTENSION
; ----------------------------------------------------------------------------
SHIFT_RIGHT4:
        ror     2,x
        ror     3,x
        ror     4,x
        ror     a
        iny
        bne     LB588
SHIFT_RIGHT5:
        clc
        rts

; ----------------------------------------------------------------------------

CON_ONE:
        .byte   $81,$00,$00,$00,$00
POLY_LOG:
        .byte   $03
		.byte   $7F,$5E,$56,$CB,$79
		.byte   $80,$13,$9B,$0B,$64
		.byte   $80,$76,$38,$93,$16
        .byte   $82,$38,$AA,$3B,$20
CON_SQR_HALF:
        .byte   $80,$35,$04,$F3,$34
CON_SQR_TWO:
        .byte   $81,$35,$04,$F3,$34
CON_NEG_HALF:
        .byte   $80,$80,$00,$00,$00
CON_LOG_TWO:
        .byte   $80,$31,$72,$17,$F8

; ----------------------------------------------------------------------------
; "LOG" FUNCTION
; ----------------------------------------------------------------------------
LOG:
        jsr     SIGN
        beq     GIQ
        bpl     LOG2
GIQ:
        jmp     IQERR
LOG2:
        lda     FAC
        sbc     #$7F
        pha
        lda     #$80
        sta     FAC
        lda     #<CON_SQR_HALF
        ldy     #>CON_SQR_HALF
        jsr     FADD
        lda     #<CON_SQR_TWO
        ldy     #>CON_SQR_TWO
        jsr     FDIV
        lda     #<CON_ONE
        ldy     #>CON_ONE
        jsr     FSUB
        lda     #<POLY_LOG
        ldy     #>POLY_LOG
        jsr     POLYNOMIAL_ODD
        lda     #<CON_NEG_HALF
        ldy     #>CON_NEG_HALF
        jsr     FADD
        pla
        jsr     ADDACC
        lda     #<CON_LOG_TWO
        ldy     #>CON_LOG_TWO

; ----------------------------------------------------------------------------
; FAC = (Y,A) * FAC
; ----------------------------------------------------------------------------
FMULT:
        jsr     LOAD_ARG_FROM_YA

; ----------------------------------------------------------------------------
; FAC = ARG * FAC
; ----------------------------------------------------------------------------
FMULTT:
        jeq     L3903
        jsr     ADD_EXPONENTS
        lda     #$00
        sta     RESULT
        sta     RESULT+1
        sta     RESULT+2
        sta     RESULT+3
        lda     FACEXTENSION
        jsr     MULTIPLY1
        lda     FAC+4
        jsr     MULTIPLY1
        lda     FAC+3
        jsr     MULTIPLY1
        lda     FAC+2
        jsr     MULTIPLY1
        lda     FAC+1
        jsr     MULTIPLY2
        jmp     COPY_RESULT_INTO_FAC

; ----------------------------------------------------------------------------
; MULTIPLY ARG BY (A) INTO RESULT
; ----------------------------------------------------------------------------
MULTIPLY1:
        bne     MULTIPLY2
        jmp     SHIFT_RIGHT1
MULTIPLY2:
        lsr     a
        ora     #$80
L38A7:
        tay
        bcc     L38C3
        clc
        lda     RESULT+3
        adc     ARG+4
        sta     RESULT+3
        lda     RESULT+2
        adc     ARG+3
        sta     RESULT+2
        lda     RESULT+1
        adc     ARG+2
        sta     RESULT+1
        lda     RESULT
        adc     ARG+1
        sta     RESULT
L38C3:
        ror     RESULT
        ror     RESULT+1
        ror     RESULT+2
        ror     RESULT+3
        ror     FACEXTENSION
        tya
        lsr     a
        bne     L38A7
L3903:
        rts

; ----------------------------------------------------------------------------
; UNPACK NUMBER AT (Y,A) INTO ARG
; ----------------------------------------------------------------------------
LOAD_ARG_FROM_YA:
        sta     INDEX
        sty     INDEX+1
        ldy     #BYTES_FP-1
        lda     (INDEX),y
        sta     ARG+4
        dey
        lda     (INDEX),y
        sta     ARG+3
        dey
        lda     (INDEX),y
        sta     ARG+2
        dey
        lda     (INDEX),y
        sta     ARGSIGN
        eor     FACSIGN
        sta     SGNCPR
        lda     ARGSIGN
        ora     #$80
        sta     ARG+1
        dey
        lda     (INDEX),y
        sta     ARG
        lda     FAC
        rts

; ----------------------------------------------------------------------------
; ADD EXPONENTS OF ARG AND FAC
; (CALLED BY FMULT AND FDIV)
;
; ALSO CHECK FOR OVERFLOW, AND SET RESULT SIGN
; ----------------------------------------------------------------------------
ADD_EXPONENTS:
        lda     ARG
ADD_EXPONENTS1:
        beq     ZERO
        clc
        adc     FAC
        bcc     L393C
        bmi     JOV
        clc
        .byte   $2C
L393C:
        bpl     ZERO
        adc     #$80
        sta     FAC
        bne     L3947
        jmp     STA_IN_FAC_SIGN
L3947:
        lda     SGNCPR
        sta     FACSIGN
        rts

; ----------------------------------------------------------------------------
; IF (FAC) IS POSITIVE, GIVE "OVERFLOW" ERROR
; IF (FAC) IS NEGATIVE, SET FAC=0, POP ONE RETURN, AND RTS
; CALLED FROM "EXP" FUNCTION
; ----------------------------------------------------------------------------
OUTOFRNG:
        lda     FACSIGN
        eor     #$FF
        bmi     JOV

; ----------------------------------------------------------------------------
; POP RETURN ADDRESS AND SET FAC=0
; ----------------------------------------------------------------------------
ZERO:
        pla
        pla
        jmp     ZERO_FAC
JOV:
        jmp     OVERFLOW

; ----------------------------------------------------------------------------
; MULTIPLY FAC BY 10
; ----------------------------------------------------------------------------
MUL10:
        jsr     COPY_FAC_TO_ARG_ROUNDED
        tax
        beq     L3970
        clc
        adc     #$02
        bcs     JOV
LD9BF:
        ldx     #$00
        stx     SGNCPR
        jsr     FADD2
        inc     FAC
        beq     JOV
L3970:
        rts

; ----------------------------------------------------------------------------
CONTEN:
        .byte   $84,$20,$00,$00,$00

; ----------------------------------------------------------------------------
; DIVIDE FAC BY 10
; ----------------------------------------------------------------------------
DIV10:
        jsr     COPY_FAC_TO_ARG_ROUNDED
        lda     #<CONTEN
        ldy     #>CONTEN
        ldx     #$00

; ----------------------------------------------------------------------------
; FAC = ARG / (Y,A)
; ----------------------------------------------------------------------------
DIV:
        stx     SGNCPR
        jsr     LOAD_FAC_FROM_YA
        jmp     FDIVT

; ----------------------------------------------------------------------------
; FAC = (Y,A) / FAC
; ----------------------------------------------------------------------------
FDIV:
        jsr     LOAD_ARG_FROM_YA

; ----------------------------------------------------------------------------
; FAC = ARG / FAC
; ----------------------------------------------------------------------------
FDIVT:
        beq     L3A02
        jsr     ROUND_FAC
        lda     #$00
        sec
        sbc     FAC
        sta     FAC
        jsr     ADD_EXPONENTS
        inc     FAC
        beq     JOV
        ldx     #-MANTISSA_BYTES
        lda     #$01
L39A1:
        ldy     ARG+1
        cpy     FAC+1
        bne     L39B7
        ldy     ARG+2
        cpy     FAC+2
        bne     L39B7
        ldy     ARG+3
        cpy     FAC+3
        bne     L39B7
        ldy     ARG+4
        cpy     FAC+4
L39B7:
        php
        rol     a
        bcc     L39C4
        inx
        sta     RESULT_LAST-1,x
        beq     L39F2
        bpl     L39F6
        lda     #$01
L39C4:
        plp
        bcs     L39D5
L39C7:
        asl     ARG_LAST
        rol     ARG+3
        rol     ARG+2
        rol     ARG+1
        bcs     L39B7
        bmi     L39A1
        bpl     L39B7
L39D5:
        tay
        lda     ARG+4
        sbc     FAC+4
        sta     ARG+4
        lda     ARG+3
        sbc     FAC+3
        sta     ARG+3
        lda     ARG+2
        sbc     FAC+2
        sta     ARG+2
        lda     ARG+1
        sbc     FAC+1
        sta     ARG+1
        tya
        jmp     L39C7
L39F2:
        lda     #$40
        bne     L39C4
L39F6:
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        sta     FACEXTENSION
        plp
        jmp     COPY_RESULT_INTO_FAC
L3A02:
        ldx     #ERR_ZERODIV
        jmp     ERROR

; ----------------------------------------------------------------------------
; COPY RESULT INTO FAC MANTISSA, AND NORMALIZE
; ----------------------------------------------------------------------------
COPY_RESULT_INTO_FAC:
        lda     RESULT
        sta     FAC+1
        lda     RESULT+1
        sta     FAC+2
        lda     RESULT+2
        sta     FAC+3
        lda     RESULT+3
        sta     FAC+4
        jmp     NORMALIZE_FAC2

; ----------------------------------------------------------------------------
; UNPACK (Y,A) INTO FAC
; ----------------------------------------------------------------------------
LOAD_FAC_FROM_YA:
        sta     INDEX
        sty     INDEX+1
        ldy     #MANTISSA_BYTES
        lda     (INDEX),y
        sta     FAC+4
        dey
        lda     (INDEX),y
        sta     FAC+3
        dey
        lda     (INDEX),y
        sta     FAC+2
        dey
        lda     (INDEX),y
        sta     FACSIGN
        ora     #$80
        sta     FAC+1
        dey
        lda     (INDEX),y
        sta     FAC
        sty     FACEXTENSION
        rts

; ----------------------------------------------------------------------------
; ROUND FAC, STORE IN TEMP2
; ----------------------------------------------------------------------------
STORE_FAC_IN_TEMP2_ROUNDED:
        ldx     #TEMP2
        .byte   $2C

; ----------------------------------------------------------------------------
; ROUND FAC, STORE IN TEMP1
; ----------------------------------------------------------------------------
STORE_FAC_IN_TEMP1_ROUNDED:
        ldx     #TEMP1X
        ldy     #$00
        beq     STORE_FAC_AT_YX_ROUNDED

; ----------------------------------------------------------------------------
; ROUND FAC, AND STORE WHERE FORPNT POINTS
; ----------------------------------------------------------------------------
SETFOR:
        ldx     FORPNT
        ldy     FORPNT+1

; ----------------------------------------------------------------------------
; ROUND FAC, AND STORE AT (Y,X)
; ----------------------------------------------------------------------------
STORE_FAC_AT_YX_ROUNDED:
        jsr     ROUND_FAC
        stx     INDEX
        sty     INDEX+1
        ldy     #MANTISSA_BYTES
        lda     FAC+4
        sta     (INDEX),y
        dey
        lda     FAC+3
        sta     (INDEX),y
        dey
        lda     FAC+2
        sta     (INDEX),y
        dey
        lda     FACSIGN
        ora     #$7F
        and     FAC+1
        sta     (INDEX),y
        dey
        lda     FAC
        sta     (INDEX),y
        sty     FACEXTENSION
        rts

; ----------------------------------------------------------------------------
; COPY ARG INTO FAC
; ----------------------------------------------------------------------------
COPY_ARG_TO_FAC:
        lda     ARGSIGN
MFA:
        sta     FACSIGN
        ldx     #BYTES_FP
L3A7A:
        lda     SHIFTSIGNEXT,x
        sta     EXPSGN,x
        dex
        bne     L3A7A
        stx     FACEXTENSION
        rts

; ----------------------------------------------------------------------------
; ROUND FAC AND COPY TO ARG
; ----------------------------------------------------------------------------
COPY_FAC_TO_ARG_ROUNDED:
        jsr     ROUND_FAC
MAF:
        ldx     #BYTES_FP+1
L3A89:
        lda     EXPSGN,x
        sta     SHIFTSIGNEXT,x
        dex
        bne     L3A89
        stx     FACEXTENSION
RTS14:
        rts

; ----------------------------------------------------------------------------
; ROUND FAC USING EXTENSION BYTE
; ----------------------------------------------------------------------------
ROUND_FAC:
        lda     FAC
        beq     RTS14
        asl     FACEXTENSION
        bcc     RTS14

; ----------------------------------------------------------------------------
; INCREMENT MANTISSA AND RE-NORMALIZE IF CARRY
; ----------------------------------------------------------------------------
INCREMENT_MANTISSA:
        jsr     INCREMENT_FAC_MANTISSA
        bne     RTS14
        jmp     NORMALIZE_FAC6

; ----------------------------------------------------------------------------
; TEST FAC FOR ZERO AND SIGN
;
; FAC > 0, RETURN +1
; FAC = 0, RETURN  0
; FAC < 0, RETURN -1
; ----------------------------------------------------------------------------
SIGN:
        lda     FAC
        beq     RTS15
L3AA7:
        lda     FACSIGN
SIGN2:
        rol     a
        lda     #$FF
        bcs     RTS15
        lda     #$01
RTS15:
        rts

; ----------------------------------------------------------------------------
; "SGN" FUNCTION
; ----------------------------------------------------------------------------
SGN:
        jsr     SIGN

; ----------------------------------------------------------------------------
; CONVERT (A) INTO FAC, AS SIGNED VALUE -128 TO +127
; ----------------------------------------------------------------------------
FLOAT:
        sta     FAC+1
        lda     #$00
        sta     FAC+2
        ldx     #$88

; ----------------------------------------------------------------------------
; FLOAT UNSIGNED VALUE IN FAC+1,2
; (X) = EXPONENT
; ----------------------------------------------------------------------------
FLOAT1:
        lda     FAC+1
        eor     #$FF
        rol     a

; ----------------------------------------------------------------------------
; FLOAT UNSIGNED VALUE IN FAC+1,2
; (X) = EXPONENT
; C=0 TO MAKE VALUE NEGATIVE
; C=1 TO MAKE VALUE POSITIVE
; ----------------------------------------------------------------------------
FLOAT2:
        lda     #$00
        sta     FAC+4
        sta     FAC+3
LDB21:
        stx     FAC
        sta     FACEXTENSION
        sta     FACSIGN
        jmp     NORMALIZE_FAC1

; ----------------------------------------------------------------------------
; "ABS" FUNCTION
; ----------------------------------------------------------------------------
ABS:
        lsr     FACSIGN
        rts

; ----------------------------------------------------------------------------
; COMPARE FAC WITH PACKED # AT (Y,A)
; RETURN A=1,0,-1 AS (Y,A) IS <,=,> FAC
; ----------------------------------------------------------------------------
FCOMP:
        sta     DEST

; ----------------------------------------------------------------------------
; SPECIAL ENTRY FROM "NEXT" PROCESSOR
; "DEST" ALREADY SET UP
; ----------------------------------------------------------------------------
FCOMP2:
        sty     DEST+1
        ldy     #$00
        lda     (DEST),y
        iny
        tax
        beq     SIGN
        lda     (DEST),y
        eor     FACSIGN
        bmi     L3AA7
        cpx     FAC
        bne     L3B0A
        lda     (DEST),y
        ora     #$80
        cmp     FAC+1
        bne     L3B0A
        iny
        lda     (DEST),y
        cmp     FAC+2
        bne     L3B0A
        iny
        lda     (DEST),y
        cmp     FAC+3
        bne     L3B0A
        iny
        lda     #$7F
        cmp     FACEXTENSION
        lda     (DEST),y
        sbc     FAC_LAST
        beq     L3B32
L3B0A:
        lda     FACSIGN
        bcc     L3B10
        eor     #$FF
L3B10:
        jmp     SIGN2

; ----------------------------------------------------------------------------
; QUICK INTEGER FUNCTION
;
; CONVERTS FP VALUE IN FAC TO INTEGER VALUE
; IN FAC+1...FAC+4, BY SHIFTING RIGHT WITH SIGN
; EXTENSION UNTIL FRACTIONAL BITS ARE OUT.
;
; THIS SUBROUTINE ASSUMES THE EXPONENT < 32.
; ----------------------------------------------------------------------------
QINT:
        lda     FAC
        beq     QINT3
        sec
        sbc     #120+8*BYTES_FP
        bit     FACSIGN
        bpl     L3B27
        tax
        lda     #$FF
        sta     SHIFTSIGNEXT
        jsr     COMPLEMENT_FAC_MANTISSA
        txa
L3B27:
        ldx     #FAC
        cmp     #$F9
        bpl     QINT2
        jsr     SHIFT_RIGHT
        sty     SHIFTSIGNEXT
L3B32:
        rts
QINT2:
        tay
        lda     FACSIGN
        and     #$80
        lsr     FAC+1
        ora     FAC+1
        sta     FAC+1
        jsr     SHIFT_RIGHT4
        sty     SHIFTSIGNEXT
        rts

; ----------------------------------------------------------------------------
; "INT" FUNCTION
;
; USES QINT TO CONVERT (FAC) TO INTEGER FORM,
; AND THEN REFLOATS THE INTEGER.
; ----------------------------------------------------------------------------
INT:
        lda     FAC
        cmp     #120+8*BYTES_FP
        bcs     RTS17
        jsr     QINT
        sty     FACEXTENSION
        lda     FACSIGN
        sty     FACSIGN
        eor     #$80
        rol     a
        lda     #120+8*BYTES_FP
        sta     FAC
        lda     FAC_LAST
        sta     CHARAC
        jmp     NORMALIZE_FAC1
QINT3:
        sta     FAC+1
        sta     FAC+2
        sta     FAC+3
        sta     FAC+4
        tay
RTS17:
        rts

; ----------------------------------------------------------------------------
; CONVERT STRING TO FP VALUE IN FAC
;
; STRING POINTED TO BY TXTPTR
; FIRST CHAR ALREADY SCANNED BY CHRGET
; (A) = FIRST CHAR, C=0 IF DIGIT.
; ----------------------------------------------------------------------------
FIN:
        ldy     #$00
        ldx     #SERLEN-TMPEXP
L3B6F:
        sty     TMPEXP,x
        dex
        bpl     L3B6F
        bcc     FIN2
        cmp     #$2D
        bne     L3B7E
        stx     SERLEN
        beq     FIN1
L3B7E:
        cmp     #$2B
        bne     FIN3
FIN1:
        jsr     CHRGET
FIN2:
        bcc     FIN9
FIN3:
        cmp     #$2E
        beq     FIN10
        cmp     #$45
        bne     FIN7
        jsr     CHRGET
        bcc     FIN5
        cmp     #TOKEN_MINUS
        beq     L3BA6
        cmp     #$2D
        beq     L3BA6
        cmp     #TOKEN_PLUS
        beq     FIN4
        cmp     #$2B
        beq     FIN4
        bne     FIN6
L3BA6:
        ror     EXPSGN
FIN4:
        jsr     CHRGET
FIN5:
        bcc     GETEXP
FIN6:
        bit     EXPSGN
        bpl     FIN7
        lda     #$00
        sec
        sbc     EXPON
        jmp     FIN8

; ----------------------------------------------------------------------------
; FOUND A DECIMAL POINT
; ----------------------------------------------------------------------------
FIN10:
        ror     LOWTR
        bit     LOWTR
        bvc     FIN1

; ----------------------------------------------------------------------------
; NUMBER TERMINATED, ADJUST EXPONENT NOW
; ----------------------------------------------------------------------------
FIN7:
        lda     EXPON
FIN8:
        sec
        sbc     INDX
        sta     EXPON
        beq     L3BEE
        bpl     L3BE7
L3BDE:
        jsr     DIV10
        inc     EXPON
        bne     L3BDE
        beq     L3BEE
L3BE7:
        jsr     MUL10
        dec     EXPON
        bne     L3BE7
L3BEE:
        lda     SERLEN
        bmi     L3BF3
        rts
L3BF3:
        jmp     NEGOP

; ----------------------------------------------------------------------------
; ACCUMULATE A DIGIT INTO FAC
; ----------------------------------------------------------------------------
FIN9:
        pha
        bit     LOWTR
        bpl     L3BFD
        inc     INDX
L3BFD:
        jsr     MUL10
        pla
        sec
        sbc     #$30
        jsr     ADDACC
        jmp     FIN1

; ----------------------------------------------------------------------------
; ADD (A) TO FAC
; ----------------------------------------------------------------------------
ADDACC:
        pha
        jsr     COPY_FAC_TO_ARG_ROUNDED
        pla
        jsr     FLOAT
        lda     ARGSIGN
        eor     FACSIGN
        sta     SGNCPR
        ldx     FAC
        jmp     FADDT

; ----------------------------------------------------------------------------
; ACCUMULATE DIGIT OF EXPONENT
; ----------------------------------------------------------------------------
GETEXP:
        lda     EXPON
        cmp     #MAX_EXPON
        bcc     L3C2C
        lda     #$64
        bit     EXPSGN
        bmi     L3C3A
        jmp     OVERFLOW
LDC70:
L3C2C:
        asl     a
        asl     a
        clc
        adc     EXPON
        asl     a
        clc
        ldy     #$00
        adc     (TXTPTR),y
        sec
        sbc     #$30
L3C3A:
        sta     EXPON
        jmp     FIN4

; ----------------------------------------------------------------------------

CON_99999999_9:
        .byte   $9B,$3E,$BC,$1F,$FD
CON_999999999:
        .byte   $9E,$6E,$6B,$27,$FD
CON_BILLION:
        .byte   $9E,$6E,$6B,$28,$00

; ----------------------------------------------------------------------------
; PRINT "IN <LINE #>"
; ----------------------------------------------------------------------------
INPRT:
        lda     #<QT_IN
        ldy     #>QT_IN
        jsr     GOSTROUT2
        lda     CURLIN+1
        ldx     CURLIN

; ----------------------------------------------------------------------------
; PRINT A,X AS DECIMAL INTEGER
; ----------------------------------------------------------------------------
LINPRT:
        sta     FAC+1
        stx     FAC+2
        ldx     #$90
        sec
        jsr     FLOAT2
        jsr     FOUT
GOSTROUT2:
        jmp     STROUT

; ----------------------------------------------------------------------------
; CONVERT (FAC) TO STRING STARTING AT STACK
; RETURN WITH (Y,A) POINTING AT STRING
; ----------------------------------------------------------------------------
FOUT:
        ldy     #$01

; ----------------------------------------------------------------------------
; "STR$" FUNCTION ENTERS HERE, WITH (Y)=0
; SO THAT RESULT STRING STARTS AT STACK-1
; (THIS IS USED AS A FLAG)
; ----------------------------------------------------------------------------
FOUT1:
        lda     #$20
        bit     FACSIGN
        bpl     L3C73
        lda     #$2D
L3C73:
        sta     STACK2-1,y
        sta     FACSIGN
        sty     STRNG2
        iny
        lda     #$30
        ldx     FAC
        bne     L3C84
        jmp     FOUT4
L3C84:
        lda     #$00
        cpx     #$80
        beq     L3C8C
        bcs     L3C95
L3C8C:
        lda     #<CON_BILLION
        ldy     #>CON_BILLION
        jsr     FMULT

        lda     #-9
L3C95:
        sta     INDX
; ----------------------------------------------------------------------------
; ADJUST UNTIL 1E8 <= (FAC) <1E9
; ----------------------------------------------------------------------------
L3C97:
        lda     #<CON_999999999
        ldy     #>CON_999999999
        jsr     FCOMP
        beq     L3CBE
        bpl     L3CB4
L3CA2:
        lda     #<CON_99999999_9
        ldy     #>CON_99999999_9
        jsr     FCOMP
        beq     L3CAD
        bpl     L3CBB
L3CAD:
        jsr     MUL10
        dec     INDX
        bne     L3CA2
L3CB4:
        jsr     DIV10
        inc     INDX
        bne     L3C97
L3CBB:
        jsr     FADDH
L3CBE:
        jsr     QINT
; ----------------------------------------------------------------------------
; FAC+1...FAC+4 IS NOW IN INTEGER FORM
; WITH POWER OF TEN ADJUSTMENT IN TMPEXP
;
; IF -10 < TMPEXP > 1, PRINT IN DECIMAL FORM
; OTHERWISE, PRINT IN EXPONENTIAL FORM
; ----------------------------------------------------------------------------
        ldx     #$01
        lda     INDX
        clc
        adc     #3*BYTES_FP-5
        bmi     L3CD3
        cmp     #3*BYTES_FP-4
        bcs     L3CD4
        adc     #$FF
        tax
        lda     #$02
L3CD3:
        sec
L3CD4:
        sbc     #$02
        sta     EXPON
        stx     INDX
        txa
        beq     L3CDF
        bpl     L3CF2
L3CDF:
        ldy     STRNG2
        lda     #$2E
        iny
        sta     STACK2-1,y
        txa
        beq     L3CF0
        lda     #$30
        iny
        sta     STACK2-1,y
L3CF0:
        sty     STRNG2
; ----------------------------------------------------------------------------
; NOW DIVIDE BY POWERS OF TEN TO GET SUCCESSIVE DIGITS
; ----------------------------------------------------------------------------
L3CF2:
        ldy     #$00
LDD3A:
        ldx     #$80
L3CF6:
        lda     FAC_LAST
        clc
        adc     DECTBL+3,y
        sta     FAC+4
        lda     FAC+3
        adc     DECTBL+2,y
        sta     FAC+3
        lda     FAC+2
        adc     DECTBL+1,y
        sta     FAC+2
        lda     FAC+1
        adc     DECTBL,y
        sta     FAC+1
        inx
        bcs     L3D1A
        bpl     L3CF6
        bmi     L3D1C
L3D1A:
        bmi     L3CF6
L3D1C:
        txa
        bcc     L3D23
        eor     #$FF
        adc     #$0A
L3D23:
        adc     #$2F
        iny
        iny
        iny
        iny
        sty     VARPNT
        ldy     STRNG2
        iny
        tax
        and     #$7F
        sta     STACK2-1,y
        dec     INDX
        bne     L3D3E
        lda     #$2E
        iny
        sta     STACK2-1,y
L3D3E:
        sty     STRNG2
        ldy     VARPNT
        txa
        eor     #$FF
        and     #$80
        tax
        cpy     #DECTBL_END-DECTBL
.ifdef CONFIG_CBM_ALL
        beq     LDD96
        cpy     #$3C ; XXX
.endif
        bne     L3CF6
; ----------------------------------------------------------------------------
; NINE DIGITS HAVE BEEN STORED IN STRING.  NOW LOOK
; BACK AND LOP OFF TRAILING ZEROES AND A TRAILING
; DECIMAL POINT.
; ----------------------------------------------------------------------------
LDD96:
        ldy     STRNG2
L3D4E:
        lda     STACK2-1,y
        dey
        cmp     #$30
        beq     L3D4E
        cmp     #$2E
        beq     L3D5B
        iny
L3D5B:
        lda     #$2B
        ldx     EXPON
        beq     L3D8F
        bpl     L3D6B
        lda     #$00
        sec
        sbc     EXPON
        tax
        lda     #$2D
L3D6B:
        sta     STACK2+1,y
        lda     #$45
        sta     STACK2,y
        txa
        ldx     #$2F
        sec
L3D77:
        inx
        sbc     #$0A
        bcs     L3D77
        adc     #$3A
        sta     STACK2+3,y
        txa
        sta     STACK2+2,y
        lda     #$00
        sta     STACK2+4,y
        beq     L3D94
FOUT4:
        sta     STACK2-1,y
L3D8F:
        lda     #$00
        sta     STACK2,y
L3D94:
        lda     #<STACK2
        ldy     #>STACK2
        rts

; ----------------------------------------------------------------------------
CON_HALF:

        .byte   $80,$00,$00,$00,$00
; ----------------------------------------------------------------------------
; POWERS OF 10 FROM 1E8 DOWN TO 1,
; AS 32-BIT INTEGERS, WITH ALTERNATING SIGNS
; ----------------------------------------------------------------------------
DECTBL:
		.byte	$FA,$0A,$1F,$00	; -100000000
		.byte	$00,$98,$96,$80	; 10000000
		.byte	$FF,$F0,$BD,$C0	; -1000000
		.byte	$00,$01,$86,$A0	; 100000
		.byte	$FF,$FF,$D8,$F0	; -10000
		.byte   $00,$00,$03,$E8	; 1000
		.byte	$FF,$FF,$FF,$9C	; -100
		.byte   $00,$00,$00,$0A	; 10
		.byte	$FF,$FF,$FF,$FF	; -1

DECTBL_END:
.ifdef CONFIG_CBM_ALL
		.byte	$FF,$DF,$0A,$80 ; TI$
		.byte	$00,$03,$4B,$C0
		.byte	$FF,$FF,$73,$60
		.byte	$00,$00,$0E,$10
		.byte	$FF,$FF,$FD,$A8
		.byte	$00,$00,$00,$3C
.endif
C_ZERO = CON_HALF + 2

; ----------------------------------------------------------------------------
; "SQR" FUNCTION
; ----------------------------------------------------------------------------
SQR:
        jsr     COPY_FAC_TO_ARG_ROUNDED
        lda     #<CON_HALF
        ldy     #>CON_HALF
        jsr     LOAD_FAC_FROM_YA

; ----------------------------------------------------------------------------
; EXPONENTIATION OPERATION
;
; ARG ^ FAC  =  EXP( LOG(ARG) * FAC )
; ----------------------------------------------------------------------------
FPWRT:
        beq     EXP
        lda     ARG
        bne     L3DD5
        jmp     STA_IN_FAC_SIGN_AND_EXP
L3DD5:
        ldx     #TEMP3
        ldy     #$00
        jsr     STORE_FAC_AT_YX_ROUNDED
        lda     ARGSIGN
        bpl     L3DEF
        jsr     INT
        lda     #TEMP3
        ldy     #$00
        jsr     FCOMP
        bne     L3DEF
        tya
        ldy     CHARAC
L3DEF:
        jsr     MFA
        tya
        pha
        jsr     LOG
        lda     #TEMP3
        ldy     #$00
        jsr     FMULT
        jsr     EXP
        pla
        lsr     a
        bcc     L3E0F

; ----------------------------------------------------------------------------
; NEGATE VALUE IN FAC
; ----------------------------------------------------------------------------
NEGOP:
        lda     FAC
        beq     L3E0F
        lda     FACSIGN
        eor     #$FF
        sta     FACSIGN
L3E0F:
        rts

; ----------------------------------------------------------------------------

CON_LOG_E:
        .byte   $81,$38,$AA,$3B,$29
POLY_EXP:
        .byte   $07
		.byte	$71,$34,$58,$3E,$56
		.byte	$74,$16,$7E,$B3,$1B
		.byte	$77,$2F,$EE,$E3,$85
        .byte   $7A,$1D,$84,$1C,$2A
		.byte	$7C,$63,$59,$58,$0A
		.byte	$7E,$75,$FD,$E7,$C6
		.byte	$80,$31,$72,$18,$10
		.byte	$81,$00,$00,$00,$00

; ----------------------------------------------------------------------------
; "EXP" FUNCTION
;
; FAC = E ^ FAC
; ----------------------------------------------------------------------------
EXP:
        lda     #<CON_LOG_E
        ldy     #>CON_LOG_E
        jsr     FMULT
        lda     FACEXTENSION
        adc     #$50
        bcc     L3E4E
        jsr     INCREMENT_MANTISSA
L3E4E:
        sta     ARGEXTENSION
        jsr     MAF
        lda     FAC
        cmp     #$88
        bcc     L3E5C
L3E59:
        jsr     OUTOFRNG
L3E5C:
        jsr     INT
        lda     CHARAC
        clc
        adc     #$81
        beq     L3E59
        sec
        sbc     #$01
        pha
        ldx     #BYTES_FP
L3E6C:
        lda     ARG,x
        ldy     FAC,x
        sta     FAC,x
        sty     ARG,x
        dex
        bpl     L3E6C
        lda     ARGEXTENSION
        sta     FACEXTENSION
        jsr     FSUBT
        jsr     NEGOP
        lda     #<POLY_EXP
        ldy     #>POLY_EXP
        jsr     POLYNOMIAL
        lda     #$00
        sta     SGNCPR
        pla
        jsr     ADD_EXPONENTS1
        rts

; ----------------------------------------------------------------------------
; ODD POLYNOMIAL SUBROUTINE
;
; F(X) = X * P(X^2)
;
; WHERE:  X IS VALUE IN FAC
;	Y,A POINTS AT COEFFICIENT TABLE
;	FIRST BYTE OF COEFF. TABLE IS N
;	COEFFICIENTS FOLLOW, HIGHEST POWER FIRST
;
; P(X^2) COMPUTED USING NORMAL POLYNOMIAL SUBROUTINE
; ----------------------------------------------------------------------------
POLYNOMIAL_ODD:
        sta     STRNG2
        sty     STRNG2+1
        jsr     STORE_FAC_IN_TEMP1_ROUNDED
        lda     #TEMP1X
        jsr     FMULT
        jsr     SERMAIN
        lda     #TEMP1X
        ldy     #$00
        jmp     FMULT

; ----------------------------------------------------------------------------
; NORMAL POLYNOMIAL SUBROUTINE
;
; P(X) = C(0)*X^N + C(1)*X^(N-1) + ... + C(N)
;
; WHERE:  X IS VALUE IN FAC
;	Y,A POINTS AT COEFFICIENT TABLE
;	FIRST BYTE OF COEFF. TABLE IS N
;	COEFFICIENTS FOLLOW, HIGHEST POWER FIRST
; ----------------------------------------------------------------------------
POLYNOMIAL:
        sta     STRNG2
        sty     STRNG2+1
SERMAIN:
        jsr     STORE_FAC_IN_TEMP2_ROUNDED
        lda     (STRNG2),y
        sta     SERLEN
        ldy     STRNG2
        iny
        tya
        bne     L3EBA
        inc     STRNG2+1
L3EBA:
        sta     STRNG2
        ldy     STRNG2+1
L3EBE:
        jsr     FMULT
        lda     STRNG2
        ldy     STRNG2+1
        clc
        adc     #BYTES_FP
        bcc     L3ECB
        iny
L3ECB:
        sta     STRNG2
        sty     STRNG2+1
        jsr     FADD
        lda     #TEMP2
        ldy     #$00
        dec     SERLEN
        bne     L3EBE
RTS19:
        rts

;.include "chrget.s"

.segment "MSBCHRGET"
RAMSTART1:
GENERIC_CHRGET:
        inc     TXTPTR
        bne     GENERIC_CHRGOT
        inc     TXTPTR+1
GENERIC_CHRGOT:
GENERIC_TXTPTR = GENERIC_CHRGOT + 1
        lda     $EA60
        cmp     #$3A
        bcs     L4058
GENERIC_CHRGOT2:
        cmp     #$20
        beq     GENERIC_CHRGET
        sec
        sbc     #$30
        sec
        sbc     #$D0
L4058:
        rts

;.include "rnd.s"

.segment "MSBCODE"

; ----------------------------------------------------------------------------
; "RND" FUNCTION
; ----------------------------------------------------------------------------
; <<< THESE ARE MISSING ONE BYTE FOR FP VALUES >>>
; (non CONFIG_SMALL)
CONRND1:
        .byte   $98,$35,$44,$7A
CONRND2:
        .byte   $68,$28,$B1,$46
RND:
        jsr     SIGN
.ifdef CONFIG_CBM_ALL
        bmi     L3F01
        bne     LDF63
        lda     ENTROPY
        sta     FAC+1
        lda     ENTROPY+4
        sta     FAC+2
        lda     ENTROPY+1
        sta     FAC+3
        lda     ENTROPY+5
        sta     FAC+4
        jmp     LDF88
LDF63:
.else
        tax
        bmi     L3F01
.endif
        lda     #<RNDSEED
        ldy     #>RNDSEED
        jsr     LOAD_FAC_FROM_YA
.ifndef CONFIG_CBM_ALL
        txa
        beq     RTS19
.endif
        lda     #<CONRND1
        ldy     #>CONRND1
        jsr     FMULT
        lda     #<CONRND2
        ldy     #>CONRND2
        jsr     FADD
L3F01:
        ldx     FAC_LAST
        lda     FAC+1
        sta     FAC_LAST
        stx     FAC+1
.ifdef CONFIG_CBM_ALL
        ldx     FAC+2
        lda     FAC+3
        sta     FAC+2
        stx     FAC+3
LDF88:
.endif
        lda     #$00
        sta     FACSIGN
        lda     FAC
        sta     FACEXTENSION
        lda     #$80
        sta     FAC
        jsr     NORMALIZE_FAC2
        ldx     #<RNDSEED
        ldy     #>RNDSEED
GOMOVMF:
        jmp     STORE_FAC_AT_YX_ROUNDED

.segment "MSBCHRGET"
; ----------------------------------------------------------------------------
; INITIAL VALUE FOR RANDOM NUMBER, ALSO COPIED
; IN ALONG WITH CHRGET, BUT ERRONEOUSLY:
; <<< THE LAST BYTE IS NOT COPIED >>>
; (on all non-CONFIG_SMALL)
; ----------------------------------------------------------------------------
GENERIC_RNDSEED:
; random number seed
        .byte   $80,$4F,$C7,$52,$58
GENERIC_CHRGET_END:

;.include "trig.s"

.segment "MSBCODE"

SIN_COS_TAN_ATN:
; ----------------------------------------------------------------------------
; "COS" FUNCTION
; ----------------------------------------------------------------------------
COS:
        lda     #<CON_PI_HALF
        ldy     #>CON_PI_HALF
        jsr     FADD

; ----------------------------------------------------------------------------
; "SIN" FUNCTION
; ----------------------------------------------------------------------------
SIN:
        jsr     COPY_FAC_TO_ARG_ROUNDED
        lda     #<CON_PI_DOUB
        ldy     #>CON_PI_DOUB
        ldx     ARGSIGN
        jsr     DIV
        jsr     COPY_FAC_TO_ARG_ROUNDED
        jsr     INT
        lda     #$00
        sta     STRNG1
        jsr     FSUBT
; ----------------------------------------------------------------------------
; (FAC) = ANGLE AS A FRACTION OF A FULL CIRCLE
;
; NOW FOLD THE RANGE INTO A QUARTER CIRCLE
;
; <<< THERE ARE MUCH SIMPLER WAYS TO DO THIS >>>
; ----------------------------------------------------------------------------
        lda     #<QUARTER
        ldy     #>QUARTER
        jsr     FSUB
        lda     FACSIGN
        pha
        bpl     SIN1
        jsr     FADDH
        lda     FACSIGN
        bmi     L3F5B
        lda     CPRMASK
        eor     #$FF
        sta     CPRMASK
; ----------------------------------------------------------------------------
; IF FALL THRU, RANGE IS 0...1/2
; IF BRANCH HERE, RANGE IS 0...1/4
; ----------------------------------------------------------------------------
SIN1:
        jsr     NEGOP
; ----------------------------------------------------------------------------
; IF FALL THRU, RANGE IS -1/2...0
; IF BRANCH HERE, RANGE IS -1/4...0
; ----------------------------------------------------------------------------
L3F5B:
        lda     #<QUARTER
        ldy     #>QUARTER
        jsr     FADD
        pla
        bpl     L3F68
        jsr     NEGOP
L3F68:
        lda     #<POLY_SIN
        ldy     #>POLY_SIN
        jmp     POLYNOMIAL_ODD

; ----------------------------------------------------------------------------
; "TAN" FUNCTION
;
; COMPUTE TAN(X) = SIN(X) / COS(X)
; ----------------------------------------------------------------------------
TAN:
        jsr     STORE_FAC_IN_TEMP1_ROUNDED
        lda     #$00
        sta     CPRMASK
        jsr     SIN
        ldx     #TEMP3
        ldy     #$00
        jsr     GOMOVMF
        lda     #TEMP1+(5-BYTES_FP)
        ldy     #$00
        jsr     LOAD_FAC_FROM_YA
        lda     #$00
        sta     FACSIGN
        lda     CPRMASK
        jsr     TAN1
        lda     #TEMP3
        ldy     #$00
        jmp     FDIV
TAN1:
        pha
        jmp     SIN1

; ----------------------------------------------------------------------------

CON_PI_HALF:
        .byte   $81,$49,$0F,$DA,$A2
CON_PI_DOUB:
        .byte   $83,$49,$0F,$DA,$A2
QUARTER:
        .byte   $7F,$00,$00,$00,$00
POLY_SIN:
        .byte   $05,$84,$E6,$1A,$2D,$1B,$86,$28
        .byte   $07,$FB,$F8,$87,$99,$68,$89,$01
        .byte   $87,$23,$35,$DF,$E1,$86,$A5,$5D
        .byte   $E7,$28,$83,$49,$0F,$DA,$A2

;; ASCII encoded easter egg
MICROSOFT:
        .byte   $A6,$D3,$C1,$C8,$D4,$C8,$D5,$C4
        .byte   $CE,$CA

;; PET encoded easter egg text since CBM2
;MICROSOFT:
;        .byte   $A1,$54,$46,$8F,$13,$8F,$52,$43
;        .byte   $89,$CD

; ----------------------------------------------------------------------------
; "ATN" FUNCTION
; ----------------------------------------------------------------------------
ATN:
        lda     FACSIGN
        pha
        bpl     L3FDB
        jsr     NEGOP
L3FDB:
        lda     FAC
        pha
        cmp     #$81
        bcc     L3FE9
        lda     #<CON_ONE
        ldy     #>CON_ONE
        jsr     FDIV
; ----------------------------------------------------------------------------
; 0 <= X <= 1
; 0 <= ATN(X) <= PI/8
; ----------------------------------------------------------------------------
L3FE9:
        lda     #<POLY_ATN
        ldy     #>POLY_ATN
        jsr     POLYNOMIAL_ODD
        pla
        cmp     #$81
        bcc     L3FFC
        lda     #<CON_PI_HALF
        ldy     #>CON_PI_HALF
        jsr     FSUB
L3FFC:
        pla
        bpl     L4002
        jmp     NEGOP
L4002:
        rts

; ----------------------------------------------------------------------------
POLY_ATN:

        .byte   $0B
		.byte	$76,$B3,$83,$BD,$D3
		.byte	$79,$1E,$F4,$A6,$F5
		.byte	$7B,$83,$FC,$B0,$10
        .byte   $7C,$0C,$1F,$67,$CA
		.byte	$7C,$DE,$53,$CB,$C1
		.byte	$7D,$14,$64,$70,$4C
		.byte	$7D,$B7,$EA,$51,$7A
		.byte	$7D,$63,$30,$88,$7E
		.byte	$7E,$92,$44,$99,$3A
		.byte	$7E,$4C,$CC,$91,$C7
		.byte	$7F,$AA,$AA,$AA,$13
        .byte   $81,$00,$00,$00,$00

;.endif

;.include "init.s"

.segment "MSBINIT"

; ----------------------------------------------------------------------------
PR_WRITTEN_BY:
.ifndef CONFIG_CBM_ALL
        lda     #<QT_WRITTEN_BY
        ldy     #>QT_WRITTEN_BY
        jsr     STROUT
.endif
COLD_START:
  .ifndef CBM2
        ldx     #$FF
        stx     CURLIN+1
  .endif
  .ifdef CONFIG_NO_INPUTBUFFER_ZP
        ldx     #$FB
  .elseif .def(AIM65)
        ldx     #$FE
  .endif
        txs
  .ifndef CONFIG_CBM_ALL
        lda     #<COLD_START
        ldy     #>COLD_START
        sta     GORESTART+1
        sty     GORESTART+2
        sta     GOSTROUT+1
        sty     GOSTROUT+2
        lda     #<AYINT
        ldy     #>AYINT
        sta     GOAYINT
        sty     GOAYINT+1
        lda     #<GIVAYF
        ldy     #>GIVAYF
        sta     GOGIVEAYF
        sty     GOGIVEAYF+1
  .endif
        lda     #$4C
  .ifdef CONFIG_CBM_ALL
        sta     JMPADRS
  .endif
        sta     GORESTART
  .ifndef CONFIG_CBM_ALL
        sta     GOSTROUT
        sta     JMPADRS
  .endif
  .if (!.def(CONFIG_RAM)) && (!.def(CONFIG_CBM_ALL))
        sta     USR
  .endif

  .ifndef CONFIG_RAM
          lda     #<IQERR
          ldy     #>IQERR

          sta     USR+1
          sty     USR+2
  .endif
  .ifndef CBM1
        lda     #WIDTH
        sta     Z17
        lda     #WIDTH2
        sta     Z18
  .endif

; All non-CONFIG_SMALL versions of BASIC have
; the same bug here: While the number of bytes
; to be copied is correct for CONFIG_SMALL,
; it is one byte short on non-CONFIG_SMALL:
; It seems the "ldx" value below has been
; hardcoded. So on these configurations,
; the last byte of GENERIC_RNDSEED, which
; is 5 bytes instead of 4, does not get copied -
; which is nothing major, because it is just
; the least significant 8 bits of the mantissa
; of the random number seed.
; KBD added three bytes to CHRGET and removed
; the random number seed, but only adjusted
; the number of bytes by adding 3 - this
; copies four bytes too many, which is no
; problem.

        ldx     #GENERIC_CHRGET_END-GENERIC_CHRGET-1 ; XXX
L4098:
        lda     GENERIC_CHRGET-1,x
        sta     CHRGET-1,x
        dex
        bne     L4098
        lda     #$03
        sta     DSCLEN
        txa
        sta     SHIFTSIGNEXT
  .ifdef CONFIG_CBM_ALL
        sta     CURDVC
  .endif
        sta     LASTPT+1
  .if .defined(CONFIG_NULL) || .defined(CONFIG_PRINTNULLS)
        sta     Z15
  .endif
        pha
        sta     Z14
  .ifndef CBM2
        lda     #$03
        sta     DSCLEN
        jsr     CRDO
  .endif
  .ifdef CBM2
        inx
        stx     INPUTBUFFER-3
        stx     INPUTBUFFER-4
  .endif
        ldx     #TEMPST
        stx     TEMPPT
  .ifndef CONFIG_CBM_ALL
        lda     #<QT_MEMORY_SIZE
        ldy     #>QT_MEMORY_SIZE
        jsr     STROUT
        jsr     NXIN
        stx     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGET
        cmp     #$41
        beq     PR_WRITTEN_BY
        tay
        bne     L40EE
.ifndef CBM2
        lda     #<RAMSTART2
.endif
        ldy     #>RAMSTART2
        sta     TXTTAB
        sty     TXTTAB+1
        sta     LINNUM
        sty     LINNUM+1
.ifdef CBM2
		tay
.else
        ldy     #$00
.endif
L40D7:
        inc     LINNUM
        bne     L40DD
        inc     LINNUM+1
.ifdef CBM1
; CBM: hard RAM top limit is $8000
        lda     LINNUM+1
        cmp     #$80
        beq     L40FA
.endif
.ifdef CBM2
; optimized version of the CBM1 code
        bmi     L40FA
.endif
.if .def(AIM65)
; AIM65: hard RAM top limit is $A000
        lda     LINNUM+1
        cmp     #$A0
        beq     L40FA
.endif
L40DD:
        lda     #$55 ; 01010101 / 10101010
        sta     (LINNUM),y
        cmp     (LINNUM),y
        bne     L40FA
        asl     a
        sta     (LINNUM),y
        cmp     (LINNUM),y
.ifdef CONFIG_CBM_ALL
        beq     L40D7
.else
;  .ifndef CONFIG_11
        beq     L40D7; old: faster
        bne     L40FA
;  .else
;        bne     L40FA; new: slower
;        beq     L40D7
;  .endif
L40EE:
        jsr     CHRGOT
        jsr     LINGET
        tay
        beq     L40FA
        jmp     SYNERR
.endif
L40FA:
        lda     LINNUM
        ldy     LINNUM+1
        sta     MEMSIZ
        sty     MEMSIZ+1
L4106:
.ifndef CONFIG_CBM_ALL
        lda     #<QT_TERMINAL_WIDTH
        ldy     #>QT_TERMINAL_WIDTH
        jsr     STROUT
        jsr     NXIN
        stx     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGET
        tay
        beq     L4136
        jsr     LINGET
        lda     LINNUM+1
        bne     L4106
        lda     LINNUM
        cmp     #$10
        bcc     L4106
L2829:
        sta     Z17
L4129:
        sbc     #$0E
        bcs     L4129
        eor     #$FF
        sbc     #$0C
        clc
        adc     Z17
        sta     Z18
.endif
L4136:
.ifdef CONFIG_RAM
        lda     #<QT_WANT
        ldy     #>QT_WANT
        jsr     STROUT
        jsr     NXIN
        stx     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGET
        ldx     #<RAMSTART1
        ldy     #>RAMSTART1
        cmp     #'Y'
        beq     L4183
        cmp     #'A'
        beq     L4157
        cmp     #'N'
        bne     L4136
L4157:
        ldx     #<IQERR
        ldy     #>IQERR
        stx     UNFNC_ATN
        sty     UNFNC_ATN+1
        ldx     #<ATN	; overwrite starting
        ldy     #>ATN	; with ATN
        cmp     #'A'
        beq     L4183
        ldx     #<IQERR
        ldy     #>IQERR
        stx     UNFNC_COS
        sty     UNFNC_COS+1
        stx     UNFNC_TAN
        sty     UNFNC_TAN+1
        stx     UNFNC_SIN
        sty     UNFNC_SIN+1
        ldx     #<SIN_COS_TAN_ATN	; overwrite
        ldy     #>SIN_COS_TAN_ATN	; all of trig.s
L4183:
.else
        ldx     #<RAMSTART2
        ldy     #>RAMSTART2
.endif
        stx     TXTTAB
        sty     TXTTAB+1
        ldy     #$00
        tya
        sta     (TXTTAB),y
        inc     TXTTAB
.ifndef CBM2
        bne     L4192
        inc     TXTTAB+1
L4192:
.endif
.if CONFIG_SCRTCH_ORDER = 1
        jsr     SCRTCH
.endif
        lda     TXTTAB
        ldy     TXTTAB+1
        jsr     REASON
.ifdef CBM2
        lda     #<QT_BASIC
        ldy     #>QT_BASIC
        jsr     STROUT
.else
        jsr     CRDO
.endif
        lda     MEMSIZ
        sec
        sbc     TXTTAB
        tax
        lda     MEMSIZ+1
        sbc     TXTTAB+1
        jsr     LINPRT
        lda     #<QT_BYTES_FREE
        ldy     #>QT_BYTES_FREE
        jsr     STROUT
.if CONFIG_SCRTCH_ORDER = 2
        jsr     SCRTCH
.endif
.ifdef CONFIG_CBM_ALL
        jmp     RESTART
.else
        lda     #<STROUT
        ldy     #>STROUT
        sta     GOSTROUT+1
        sty     GOSTROUT+2
  .if CONFIG_SCRTCH_ORDER = 3
         jsr     SCRTCH
  .endif
        lda     #<RESTART
        ldy     #>RESTART
        sta     GORESTART+1
        sty     GORESTART+2
        jmp     (GORESTART+1)
.endif

  .if .def(CONFIG_RAM) || .def(OSI)
; OSI is compiled for ROM, but includes
; this unused string
QT_WANT:
        .byte   "WANT SIN-COS-TAN-ATN"
        .byte   0
  .endif
QT_WRITTEN_BY:
  .ifndef CONFIG_CBM_ALL
        .byte   CR,LF,$0C ; FORM FEED
        .byte   "WRITTEN BY WEILAND & GATES"
        .byte   CR,LF,0
   .endif
QT_MEMORY_SIZE:
        .byte   "MEMORY SIZE"
        .byte   0
QT_TERMINAL_WIDTH:
    .if !(.def(AIM65) || .def(SYM1))
        .byte   "TERMINAL "
    .endif
        .byte   "WIDTH"
        .byte   0
  .endif
QT_BYTES_FREE:
        .byte   " BYTES FREE"
  .ifdef CBM1
  .elseif .def(CBM2)
        .byte   CR,0
  .else
        .byte   CR,LF,CR,LF
  .endif
QT_BASIC:
  .ifdef CBM1
        .byte   $13 ; HOME
        .byte   "*** COMMODORE BASIC ***"
        .byte   $11,$11,$11,0 ; DOWN/DOWN/DOWN
  .endif
  .ifdef CBM2
        .byte   "### COMMODORE BASIC ###"
        .byte   CR,CR,0
  .endif
  .ifndef CONFIG_CBM_ALL
        .byte   CR,LF
        .byte   "COPYRIGHT 1977 BY MICROSOFT CO."
        .byte   CR,LF
        .byte   0
  .endif

;.include "extra.s"

.segment "VEC_MSB"
.word NMI
.word RESET
.word ISR
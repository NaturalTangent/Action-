;	  AMPL.MTH
; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; last modified September 9, 1983
;
; This file is part of Action!.
;
; Action! is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Action! is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Action!.  If not, see <http://www.gnu.org/licenses/>.
;
math	proc
..a	equ	aflast+1
..b	equ	aflast
..c	equ	afcur+1
..d	equ	afcur
..rl	equ	afsize
..rh	equ	afsize+1
..t1	equ	addr
..t2	equ	addr+1
..sign	equ	token
;
multi	;	    MultI(op1, op2)
; op2 is in c & d
;  r = ab * cd
;  r = (a*d + c*b)*2^8 + b*d
	jsr	smops
	ldx	..b
	beq	..mc5
	stx	..t1
	ldx	..d
	beq	..mc5
	dex
	stx	..t2
	ldx	#8
..mc3	asl	a		; b*d, 16 bit result
	rol	..rh
	asl	..t1
	bcc	..mc4
	adc	..t2
	bcc	..mc4
	inc	..rh
..mc4	dex
	bne	..mc3
..mc5	sta	..rl
	lda	..b
	ldx	..c
	jsr	mulb		; b*c, 8 bit result
	lda	..a
	ldx	..d
	jsr	mulb		; a*d, 8 bit result
;
..setsign	ldy	..sign
	bpl	..ss2
	$if	ramzap
	sta	mulb,x
	$else
	nop
	nop
	nop
	$endif
..ss1	sta	..rl
	stx	..rh
	sec
	lda	#0
	sbc	..rl
	tay
	lda	#0
	sbc	..rh
	tax
	tya
..ss2	rts
;
;
mulb	beq	..mb3
	dex
	stx	..t2
	tax
	beq	..mb3
	stx	..t1
	lda	#0
	ldx	#8
..mb1	asl	a
	asl	..t1
	bcc	..mb2
	adc	..t2
..mb2	dex
	bne	..mb1
	clc
	adc	..rh
	sta	..rh
..mb3	lda	..rl
	ldx	..rh
	rts
;
smops	stx	..sign
	cpx	#0		; check signs
	bpl	..smo1
	jsr	..ss1
..smo1	sta	..b
	stx	..a
	lda	..c
	bpl	..smo2
	tax
	eor	..sign
	sta	..sign
	lda	..d
	jsr	..ss1
	sta	..d
	stx	..c
..smo2	lda	#0
	sta	..rh
	rts
;
divi	jsr	smops		; DivC(op1, op2)
; see MultC above
	lda	..c
	beq	..dsmall
;
..dlarge	ldx	#8
..dl1	rol	..b
	rol	..a
	rol	..rh
	sec
	lda	..a
	sbc	..d
	tay
	lda	..rh
	sbc	..c
	bcc	..dl2		; overflow, don't subtract
	sta	..rh
	sty	..a
..dl2	dex
	bne	..dl1
	lda	..b
	rol	a
	ldx	#0
	ldy	..a
	sty	..rl		; save low byte of REM
	jmp	..setsign
;
..dsmall	ldx	#16
..ds1	rol	..b
	rol	..a
	rol	a
	bcs	..ds1a		; keep track of shift output
	cmp	..d
	bcc	..ds2		; overflow, don't subtract
..ds1a	sbc	..d
	sec			; for carry out in ROL A above
..ds2	dex
	bne	..ds1
	rol	..b
	rol	..a
	sta	..rl
	lda	..b
	ldx	..a
	jmp	..setsign
;
remi	jsr	divi
	lda	..rl
	ldx	..rh
..rem1	rts
;
rshift	ldy	..d		; RShift(val, cnt)
	beq	..rshret
	stx	..c
..rsh1	lsr	..c
	ror	a
	dey
	bne	..rsh1
	ldx	..c
..rshret	rts
;
sargs	;	    saves args for call
	sta	arg0
	stx	arg1
	sty	arg2
	clc
	pla
	sta	afcur
	adc	#3		; jump over data
	tay
	pla
	sta	afcur+1
	adc	#0
	pha
	tya
	pha
	ldy	#1
	lda	(afcur),y	; local address
	sta	aflast
	iny
	lda	(afcur),y
	sta	aflast+1
	iny
	lda	(afcur),y	; # of bytes
	tay
..sa1	lda	args,y
	sta	(aflast),y
	dey
	bpl	..sa1
; check for break key
	lda	brkkey
	bne	..sa2
	inc	brkkey
	jmp	break
..sa2	rts
;
; IToReal(int) -> FR0
;IToReal STX ..sign
; JSR ..SetSign
; STA FR0
; STX FR0+1
; JSR IFP
;:FSign LDA ..sign
; BPL ..Rem1
; JSR FMOVE
; JSR ZFR0
; JMP FSUB
; RToInt() real in FR0
;RToInt LDA FR0
; STA ..sign
; JSR ..FSign
; JSR FPI
; LDA FR0
; LDA FR0+1
; JMP ..SetSign
;
;	  AMPL.SYM
;
; Copyright 1983 by Action Computer Services
; All Rights Reserved
;
; last modified June 29, 1983
;
;
stm	proc			; STM(table)
	sta	arg2
	stx	arg3
	sta	arg4
	inx
	stx	arg5
	ldy	arg15
	sty	arg13
..stm1	lda	(arg2),y
	sta	nxtaddr+1
	beq	..stm3
	lda	(arg4),y
	sta	nxtaddr
	ldy	#0
..stm2	lda	(nxtaddr),y
	eor	(symtab),y
	and	stmask
	bne	..stm4
	cpy	arg14
	iny
	bcc	..stm2
	lda	(nxtaddr),y	; matched
..stm3	rts
..stm4	inc	arg13		; try next entry
	ldy	arg13
	cpy	arg15
	bne	..stm1
	ldy	#ster
	lda	arg3
	cmp	stglobal+1
	beq	..stm5
	iny
..stm5	jmp	splerr
stmres	jmp	(stmradr)
; this normially goes to ISTMres below
;
istmres proc
; STMres() lookup reserved names
	ldy	arg14
	cpy	#8
..stmr0 lda	#$ff		; if name too long!
	bcs	stmr3		; not reserved name
	iny
	sty	arg0
	ldx	rwstrt-2,y
..stmr1 stx	arg1
	ldy	#1
..stmr2 lda	resw1,x
	bmi	stmr3
	eor	(symtab),y
	and	stmask
	bne	..stmr4
	inx
	iny
	cpy	arg0
	bcc	..stmr2
; we have a match
	lda	resw1,x 	; get token value
stmr3	rts
;
..stmr4 clc
	lda	arg1
	adc	arg0
	tax
	bne	..stmr1 	; try next entry
;
lgetname	proc		; GetName(char)
	ldy	#0
	sta	frstchar
	tax
	ora	#$20
	sta	arg15		; initial hash
	txa
..gname1 iny
	sty	arg14
	sta	(symtab),y
	ora	#$20
	asl	arg15
	adc	arg15
	sta	arg15
	jsr	nextchar
	ldy	arg14
	cmp	#'_
	beq	..gname1
	jsr	alphanum
	bne	..gname1
	tya
	ldy	#0
	sta	(symtab),y
	dec	choff		; put character back
	jsr	stmres		; check for res. name
	bpl	stmr3		; return
	lda	qglobal
	beq	gnglobal
	lda	stlocal
	ldx	stlocal+1
	jsr	stm
	bne	stmr3		; return
;
gnglobal	lda	stglobal
	ldx	stglobal+1
	ldy	frstchar
	cpy	bigst
	bpl	..gng1
	lda	stg2
	ldx	stg2+1
..gng1	jsr	stm
	bne	stmr3		; return
	lda	qglobal
	beq	newentry
;
lgnlocal	lda	stlocal
	ldx	stlocal+1
	jsr	stm
	bne	stmr3
	$if	ramzap
	inc	stm,x
	$else
	nop
	nop
	nop
	$endif
;
newentry	proc
; Make new entry in symbol table
	lda	symtab+1
	sta	(arg2),y
	lda	symtab
	sta	(arg4),y
	lda	#low libst
	ldx	#high libst
	jsr	stm		; lookup shadow name
	lda	#undec
	ldy	arg14
	iny
	sta	(symtab),y
	lda	nxtaddr
	iny
	sta	(symtab),y	; save shadow entry
	lda	nxtaddr+1
	iny
	sta	(symtab),y
	lda	symtab
	sta	nxtaddr
	ldx	symtab+1
	stx	nxtaddr+1
	iny
	tya
	jsr	stincr
	lda	#undec
	rts
;
rwstrt	db	0
	db	resw2-resw1
	db	resw3-resw1
	db	resw4-resw1
	db	resw5-resw1
	db	resw6-resw1
	db	resw7-resw1
;
resw1	db	$ff
;
resw2	db	"DO",do
	db	"FI",fi
; .BYTE "FO",esac
	db	"IF",ifid
	db	"OD",od
; .BYTE "OF",of
	db	"OR",orid
	db	"TO",to
	db	$ff
;
resw3	db	"AND",andid
	db	"FOR",forid
; .BYTE "GET",get
	db	"INT",int
	db	"LSH",lshid
	db	"MOD",remid
; .BYTE "NOT",notId
	db	"RSH",rshid
	db	"SET",set
	db	"XOR",xorid
	db	$ff
;
resw4	db	"BYTE",byte
	db	"CARD",card
; .BYTE "CASE",caseId
	db	"CHAR",char
	db	"ELSE",else
; .BYTE "ESAC",esac
	db	"EXIT",exitid
	db	"FUNC",func
	db	"PROC",proc
; .BYTE "REAL",real
	db	"STEP",step
	db	"THEN",then
	db	"TYPE",typeid
	db	$ff
;
resw5	db	"ARRAY",array
	db	"UNTIL",untilid
	db	"WHILE",whileid
	db	$ff
;
resw6	db	"DEFINE",define
; .BYTE "DOWNTO",downto
	db	"ELSEIF",elseif
	db	"MODULE",modid
	db	"RETURN",retid
	db	$ff
;
resw7	db	"INCLUDE",get
	db	"POINTER",pointer
	db	$ff
;
;
;	  LIB.KEY
;
; Copyright 1983 by Action Computer Services
; All rights reserved
;
; last modified September 28, 1983
;
srtimr	equ	$022b
invflg	equ	$02b6
shflok	equ	$02be
;
lgetkey proc
; Get next key in buffer
	clc			; blink cursor
	lda	rtclok+2
	adc	#14
	tax
..bc1	lda	ch		; key down?
	eor	#$ff
	bne	..gk0
	cpx	rtclok+2
	bpl	..bc1
	ldy	#0
	lda	(oldadr),y
	eor	#$80
	sta	(oldadr),y
	jmp	lgetkey
;
..gk0	ldy	#0
	lda	oldchr
	eor	#$80
	sta	(oldadr),y	; restore cursor
	ldx	srtimr		; faster repeat
	cpx	#$0c
	bcs	..gk5
	cpx	#4
	bcc	..gk2
	ldx	#3
..gk1	stx	srtimr
..gk2	lda	ch
	cmp	#$c0
	bcc	..gk3		; not Ctrl-Shft
..cskey jsr	click
	bmi	..gk4		; uncond.
..gk3	and	#$3f
	cmp	#$3c		; caps key
	beq	..caps
	cmp	#$27		; Atari key
	beq	..atari
gkey	ldx	#$70
	lda	#7		; GETCHR
	sta	brkkey		; ignore BREAK key
	jsr	putch2
..gk4	ldx	srtimr
	cpx	#10
	bcs	..gkret
	ldx	#3
	stx	srtimr
..gkret sta	curch
	rts
..gk5	ldx	#20
	bne	..gk1
..caps	lda	ch
	and	#$c0
	sta	shflok
..caps1 jsr	click
	bmi	lgetkey
..atari lda	invflg
	eor	#$80
	sta	invflg
	jmp	..caps1
;
click	proc
; Click() click the keyboard
	ldx	#$7f
..click1	stx	consol
	stx	wsync
	dex
	bpl	..click1
	stx	ch
	rts
;
;	  SPL.ERR

; Copyright 1983 by Action Computer Services
; All Rights Reserved
;
; last modified July 30, 1983
;
lsplerr proc			; SPLErr(,,error)
	lda	top+1
	beq	spler1
; set pointer to error
	ldx	curwdw
	lda	spln
	sta	w1+wsp,x
	lda	curln
	sta	w1+wcur,x
	lda	curln+1
	sta	w1+wcur+1,x
spler1	jsr	syserr
	jsr	puteol
	jsr	printbuf
	lda	#0
	ldx	#low sermsg
	ldy	#high sermsg
	jsr	output
	lda	#0
	sta	$02e3
	ldx	#low numbuf
	ldy	#high numbuf
	jsr	print
	jmp	emloop
;
;	     LIB.IO
;
; Copyright 1983 by Action Computer Services
; All Rights Reserved
;
; last modified August 13, 1983
;
	proc
;
;PROC ChkErr=*(BYTE result, block, errCode)
; checks for error return from CIO
; Sets EOF(block) to true on error
; does not call Error if EOF error ($88)
; see Hardware manual for CIO details
chkerr	proc
	bpl	..ce2
	cpy	#$88		; EOF
	beq	..ce1
	tya
	cpy	#$80		; break key
	beq	break1
	jmp	error
..ce1	txa
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	tya
	sta	eof,x
..ce2
	$if	ramzap
	dec	chkerr-$10,x
	$else
	nop
	nop
	nop
	$endif
	rts
;
break1	proc			; Break1(error)
	ldx	#1
	stx	brkkey
	pha
	jsr	break
	pla
	tay
..pfe	rts
;
;PROC PrintF(STRING f, CARD a1, a2, a3, a4, a5)
; outputs a1-a5 to default device
; using format f.  Any non '%' char
; in f is output directly.  '%' char
; is interpreted as follows:
;    %S - output next arg as string
;    %I - output next arg as signed number
;    %U - output next arg as unsigned number
;    %C - output next arg as CHAR
;    %H - output next arg as HEX
;    %% - output '%' char
;    %E - output EOL
; any other char after % is treated
; the same as %U.
;
prtf	sta	addr
	stx	addr+1
	sty	temps
	ldy	#0
	lda	(addr),y
	sta	token
	inc	token
	ldx	#13
..pf1	lda	args+2,x
	sta	temps,x
	dex
	bne	..pf1
	stx	lsttoken
	stx	op
..pf2	inc	op
	ldy	op
	cpy	token
	bcs	..pfe
	lda	(addr),y
	cmp	#'%
	bne	..pf3
	inc	op
	iny
	lda	(addr),y
	cmp	#'%
	beq	..pf3
	cmp	#'E
	bne	..pf4
	lda	#eol
..pf3	jsr	put
	jmp	..pf2
;
..pf4	ldy	lsttoken
	inc	lsttoken
	inc	lsttoken
	sta	args
	lda	temps,y
	ldx	temps+1,y
	ldy	args
	cpy	#'C
	beq	..pf3
	cpy	#'S
	bne	..pf5
	jsr	prt
	jmp	..pf2
..pf5	cpy	#'I
	bne	..pf6
	jsr	prti
	jmp	..pf2
..pf6	cpy	#'H
	bne	..pf7
	jsr	prth
	jmp	..pf2
..pf7	jsr	prtc
	jmp	..pf2
;
;
;PROC Open(BYTE dev, STRING fileSpec, BYTE mode, aux2)
; opens fileSpec and assigns it to IOCB dev
opn	proc
	pha
	stx	arg1
	sty	arg2
	tay
	lda	#0
	sta	eof,y
	tay
	lda	(arg1),y
	sta	(buf),y
	tay
	iny
	lda	#eol
	bne	..op2		; uncond.
..op1	lda	(arg1),y
..op2	sta	(buf),y
	dey
	bne	..op1
	pla
	ldx	buf
	ldy	buf+1
	jsr	open
	jmp	chkerr
;
;
;PROC PrintE(STRING str)
; outputs str to default IOCB with EOL
prte	proc
	stx	arg1
	tax
	ldy	arg1
	lda	device
; falls into PrintDE
;
;PROC PrintDE(BYTE dev, STRING str)
; outputs str to IOCB dev appended with an EOL
prtde	proc
	jsr	print
	jmp	chkerr
;
;PROC Close(BYTE dev)
; closes IOCB dev
clos	proc
	jsr	close
	jmp	chkerr
;
;PROC Print(STRING str)
; outputs str to default IOCB
prt	proc
	stx	arg1
	tax
	ldy	arg1
	lda	device
; falls into PrintD
;
;PROC PrintD(BYTE dev, STRING str)
; outputs str to IOCB dev
prtd	proc
	jsr	output
	jmp	chkerr
;
;PROC InputS(STRING str)
; same as InputSD, but uses default IOCB
ins	proc
	stx	arg2
	tax
	ldy	arg2
	lda	device
; falls into InputSD
;
;PROC InputSD(BYTE dev, STRING str)
; see Input, size set to 255
insd	proc
	pha
	lda	#255
	sta	arg3
	pla
; falls into InputMD
;
;PROC InputMD(BYTE dev, STRING str, BYTE max)
; see Input, size set to max
inmd	proc
	pha
	stx	arg1
	sty	arg2
	ldy	#0
	lda	arg3
	sta	(arg1),y
	pla
	ldy	arg2
; falls into InputD
;
;PROC InputD(BYTE dev, STRING str)
; inputs str from IOCB dev
; first byte must be set to maximum size
; on return, first byte set to size of string input
ind	proc
	jsr	inputs
	jmp	chkerr
;
;BYTE FUNC GetD(BYTE dev)
; inputs character from IOCB dev
getd	proc
	ldx	#$07
ccio	stx	arg4
	asl	a
	asl	a
	asl	a
	asl	a
	tax
	lda	arg4
	sta	$0342,x
	lda	#0
	sta	$0348,x
	sta	$0349,x
	tya
	jsr	$e456
	sta	args
	jmp	chkerr
;
;PROC PutE()
; output EOL do default IOCB
pute	proc
	lda	#eol
; falls into Put
;
;PROC Put(CHAR ch)
; outputs ch to default IOCB
put	proc
	tax
	lda	device
; falls into PutD
;
;PROC PutD(BYTE dev, CHAR ch)
; outputs ch to IOCB dev
putd	proc
	stx	arg1
	ldy	arg1
putd1	ldx	#$0b
	jmp	ccio
;
;PROC PutDE(BYTE dev)
; outputs EOL to IOCD dev
putde	ldy	#eol
	bne	putd1		; uncond.
;
;PROC XIOstr(BYTE dev, fill, cmd, aux1, aux2, STRING str)
; see Hardware manual for CIO details
; performs system CIO call where:
;   ICCOM = cmd
;   ICBL = str(0)
;   ICBA = str+1
;   ICAX1 = aux1
;   ICAX2 = aux2
; CIO is not called if str(0)=0
; ICAX1 and ICAX2 are not set if aux1=0
xio	proc
	jsr	xiostr
	jmp	chkerr
;
;PROC PrintB(BYTE num)
; outputs byte num to default IOCB
prtb	proc
	ldx	#0
;PROC PrintC(CARD num)
; outputs cardinal num to default IOCB
prtc	proc
	jsr	printc
	jmp	chkerr
;
;PROC PrintBE(BYTE num)
; same as PrintB except EOL appended
prtbe	proc
	ldx	#0
;PROC PrintCE(CARD num)
; same as PrintC except EOL appended
prtce
	jsr	prtc
	jmp	pute
;
;PROC PrintBD(BYTE dev, BYTE num)
; output byte num to IOCB dev
prtbd	proc
	ldy	#0
;PROC PrintCD(BYTE dev, CARD num)
; output cardinal num to IOCB dev
prtcd	proc
	sta	arg0
	txa
	sty	arg2
	ldx	arg2
	jsr	ctostr
	lda	arg0
	jsr	pnum+2
	jmp	chkerr
;
;PROC PrintBDE(BYTE dev, BYTE num)
; output num to IOCB dev with EOL
prtbde	proc
	ldy	#0
;PROC PrintCDE(BYTE dev, CARD num)
; output num to IOCB dev with EOL
prtcde	proc
	jsr	prtcd
	lda	arg0
	jmp	putde
;
;PROC PrintI(INT num)
; outputs integer num to default IOCB
prti	proc
	stx	arg2
	tax
	ldy	arg2
	lda	device
; falls into PrintID
;
;PROC PrintID(BYTE dev, INT num)
; outputs integer num to IOCB dev
prtid	proc
	cpy	#0
	bpl	prtcd
	pha
	stx	arg1
	sty	arg2
	ldy	#'-
	jsr	putd1
	sec
	lda	#0
	sbc	arg1
	tax
	lda	#0
	sbc	arg2
	tay
	pla
	jmp	prtcd
;
;PROC PrintIE(INT num)
; same as PrintI with EOL
prtie	proc
	jsr	prti
	jmp	pute
;
;PROC PrintIDE(BYTE dev, INT num)
; same as PrintID with EOL
prtide	proc
	jsr	prtid
	lda	arg0
	jmp	putde
;
;PROC StrB(BYTE n, STRING s)
; convert number to string
strb	stx	arg2
	sty	arg3
	ldx	#0
	ldy	arg2
; falls into StrC
;
;PROC StrC(CARD n, STRING s)
; convert number to string
strc	proc
	sty	arg2
	jsr	ctostr
	iny
..strc1 lda	numbuf,y
	sta	(arg2),y
	dey
	bpl	..strc1
	rts
;
;PROC StrI(INT n, STRING s)
; convert number to string
stri	proc
	cpx	#0
	bpl	strc
	sta	arg0
	stx	arg1
	sty	arg2
	sec
	lda	#0
	sbc	arg0
	tay
	lda	#0
	sbc	arg1
	tax
	tya
	jsr	ctostr
	inx
	txa
	tay
..s1	lda	numbuf-1,y
	sta	(arg2),y
	dey
	bne	..s1
	txa
	sta	(arg2),y
	iny
	lda	#'-
	sta	(arg2),y
	rts
;
;BYTE FUNC InputB()
;CARD FUNC InputC()
;INT FUNC InputI()
; input number from default IOCB
; number must be terminated with EOL
inb	proc
inc	proc
ini	proc
	lda	device
; falls into InputND
;
;BYTE FUNC InputBD()
;CARD FUNC InputCD()
;INT FUNC InputID(BYTE dev)
; same as InputI, but from IOCB dev
inbd	proc
incd	proc
inid	proc
	ldx	#19
	stx	numbuf
	ldx	#low numbuf
	ldy	#high numbuf
	jsr	ind
	lda	#low numbuf
	ldx	#high numbuf
; falls into ValI
;
; BYTE FUNC ValB(STRING s)
; INT FUNC ValI(STRING s)
; CARD FUNC ValC(STRING s)
; returns numeric value of s
valb	proc
vali	proc
valc	proc
	sta	arg4
	stx	arg5
	ldy	#0
	sty	arg0
	sty	arg1
	sty	arg2
	lda	(arg4),y
	sta	arg3
	inc	arg3
	lda	#32
	iny
..i1	cmp	(arg4),y
	bne	..i2
	iny
	cpy	arg3
	bmi	..i1
..i2	lda	(arg4),y
	cmp	#'-
	bne	..i3
	sta	arg2
	iny
..i3	cpy	arg3
	bpl	..i6
..i4	lda	(arg4),y
	cmp	#'0
	bmi	..i6
	cmp	#':             ; '9'+1
	bpl	..i6
	sec
	sbc	#'0
	tax
; arg01*10
	lda	arg1
	pha
	lda	arg0
	asl	a
	rol	arg1
	asl	a
	rol	arg1
	clc
	adc	arg0
	sta	arg0
	pla
	adc	arg1
	sta	arg1
	asl	arg0
	rol	arg1
	clc
	txa
	adc	arg0		; add in digit
	sta	arg0
	bcc	..i5
	inc	arg1
..i5	iny
	cpy	arg3
	bmi	..i4
..i6	lda	arg2
	beq	..i7
	sec
	lda	#0
	sbc	arg0
	sta	arg0
	lda	#0
	sbc	arg1
	sta	arg1
..i7	rts
;
;PROC Note(BYTE dev, CARD POINTER sector, BYTE POINTER offset)
; returns disk sector and offset in that
; sector of next byte to be read or
; written to IOCB dev
; example:  Note(1, @sect, @pos)
; see Hardware manual
note	proc
	stx	arg1
	sty	arg2
	asl	a
	asl	a
	asl	a
	asl	a
	tax
	lda	#$26		; NOTE
	sta	$0342,x 	; ICCOM
	jsr	$e456		; CIOV
	jsr	chkerr
	ldy	#0
	lda	$034e,x 	; offset
	sta	(arg3),y
	lda	$034c,x 	; low byte of sector
	sta	(arg1),y
	lda	$034d,x 	; high byte of sector
	iny
	sta	(arg1),y
	rts
;
;PROC Point(BYTE dev, CARD sector, BYTE offset)
; Sets next byte to be read or written
; to be byte offset of sector.	File
; must be open for update (mode=12)
; see Hardware manual
point	proc
	stx	arg1
	asl	a
	asl	a
	asl	a
	asl	a
	tax
	tya			; sector+1
	sta	$034d,x
	lda	arg1		; sector
	sta	$034c,x
	lda	arg3		; offset
	sta	$034e,x
	lda	#$25		; POINT
	sta	$0342,x 	; ICCOM
	jsr	$e456		; CIOV
	jmp	chkerr
;
;	     LIB.GR
;
; Copyright 1983 by Action Computer Services
; All Rights Reserved
;
; last modified June 21, 1983
;
; PROC Graphics(BYTE mode)
; same as BASIC
graphics	proc		; Graphics(mode)
	pha
	lda	#0
	jsr	clos
	lda	#$0c
	sta	arg3
	lda	#0
	ldx	#low ..e
	ldy	#high ..e
	jsr	open
	jsr	chkerr
	lda	#6
	jsr	clos
	pla
	sta	arg4
	and	#$30
	eor	#$1c
	sta	arg3
	lda	#6
	ldx	#low ..devs
	ldy	#high ..devs
	jsr	open
	jmp	chkerr
;
..e	db	2,"E:",eol
..devs	db	2,"S:",eol
..color equ	$02fd
..atachr	equ	$02fb
;
; PROC DrawTo(CARD col, BYTE row)
; same as BASIC
drawto	jsr	..grio		; DrawTo(col, row)
	ldy	#$11
	jmp	xio
;
..grio	jsr	pos1
	lda	..color
	sta	..atachr
	lda	#low ..devs
	sta	arg5
	lda	#high ..devs
	sta	arg6
	lda	#0
	sta	arg3
	sta	arg4
	lda	#6
	rts
;
; PROC Position(CARD col, BYTE row)
; same as BASIC
position	sta	oldcol	; Position(col, row)
	stx	oldcol+1
	sty	oldrow
pos1	sta	colcrs
	stx	colcrs+1
	sty	rowcrs
	rts
;
; BYTE FUNC Locate(CARD col, BYTE row)
; same as BASIC
locate	jsr	position	; Locate(col, row)
	lda	#6
	jmp	getd
;
; PROC Plot(CARD col, BYTE row)
; same as BASIC
plot	jsr	pos1		; Plot(col, row)
	lda	#6
	ldx	..color
	jmp	putd
;
; PROC SetColor(BYTE reg, hue, lum)
; same as BASIC
setcolor	cmp	#5	; SetColor(reg, hue, lum)
	bpl	..sc1
	sta	arg0
	tya
	and	#$0f
	sta	arg2
	txa
	asl	a
	asl	a
	asl	a
	asl	a
	ora	arg2
	ldx	arg0
	sta	$02c4,x
	sta	$d016,x
..sc1	rts
;
; PROC Fill(CARD col, BYTE row)
; same as:
;   POSITION col, row
;   POKE 765, color
;   XIO 18,#6,0,0,"S:"
; in BASIC
fill	jsr	..grio
	ldy	#$12
	jmp	xio
;
;	     LIB.MSC
;
; Copyright 1983 by Action Computer Services
; All Rights Reserved
;
; last modified November 3, 1983
;
	proc
misc	proc
;
;BYTE FUNC Rand(BYTE range)
; returns random number between 0 and
; range-1.  If range=0, then a random
; number between 0 and 255 is returned
rand	ldx	$d20a		; RANDOM
	cmp	#0
	beq	..rand1
	stx	afcur
	ldx	#0
	stx	afcur+1
	jsr	multi
..rand1 stx	args
	rts
;
;PROC Sound(BYTE v, p, d, vol)
; set voice to specified pitch, distortion,
; and volume.  Assumes volume low  16.
sound	asl	a
	sty	arg2
	tay
	cmp	#7
	bmi	..snd1
	ldy	#100
	jsr	error
..snd1	txa
	sta	$d200,y
	lda	arg2
	asl	a
	asl	a
	asl	a
	asl	a
	ora	arg3
	sta	$d201,y
	rts
;
;PROC SndRst()
; reset sound channels
sndrst	lda	$0232
	and	#$ef		; turn off two tone bit
	sta	$0232
	sta	$d20f
	lda	#0
	ldx	#8
..sr1	sta	$d200,x 	; zero sound regs
	dex
	bpl	..sr1
	rts
;
;BYTE FUNC Paddle(BYTE port)
; returns paddle value of port
; Assumes port low  8.
; see LIB.ST
;Paddle TAX
; LDA $D200,X
; STA args
; RTS
;
;BYTE FUNC PTrig(BYTE port)
; returns zero if trigger of paddle
; port is depressed.  Assumes port<8
ptrig	ldx	#0
	cmp	#4
	bmi	..pt1
	inx
	and	#3
..pt1	tay
	lda	$d300,x
	and	..pt2,y
	sta	args
	rts
;
..pt2	db	$04,$08,$40,$80
;
;BYTE FUNC Stick(BYTE port)
; returns current value of joystick
; controller port.  Assumes port<4
stick	ldx	#0
	cmp	#2
	bmi	..stk1
	inx
	and	#1
..stk1	tay
	lda	$d300,x
	dey
	bne	..stk2
	lsr	a
	lsr	a
	lsr	a
	lsr	a
..stk2	and	#$0f
	sta	args
	rts
;
;BYTE FUNC STrig(BYTE port)
; returns zero if trigger of joystick
; port is depressed.  Assumes port<4
;
; see LIB.ST
;STrig TAX
; LDA $D010,X
; STA args
; RTS
;
;BYTE FUNC Peek(CARD address)
; returns value stored at address
peek	proc
; falls into PeekC
;
;CARD FUNC PeekC(CARD address)
; returns value stored at address
peekc	sta	arg2
	stx	arg3
	ldy	#0
	lda	(arg2),y
	sta	args
	iny
	lda	(arg2),y
	sta	args+1
	rts
;
;PROC Poke(CARD address, BYTE value)
; store byte or char value at address
; (single byte store)
poke	sta	arg0
	stx	arg1
	tya
	ldy	#0
	sta	(arg0),y
	rts
;
;PROC PokeC(CARD address, value)
; store cardinal or integer value at
; address (2 byte store)
pokec	jsr	poke
	iny
	lda	arg3
	sta	(arg0),y
	rts
;
;PROC Zero(BYTE POINTER address, CARD size)
; set memory bytes starting at address
; up to (but not including) address+size
; to zero.  Note this modifies size
; bytes of memory.
mzero	pha
	lda	#0
	sta	arg4
	pla
; falls into SetBlock
;
;PROC SetBlock(BYTE POINTER address, CARD size, BYTE value)
; set memory bytes starting at address
; up to (but not including) address+size
; to value.  Note this modifies size
; bytes of memory.
setblock	sta	arg0
	stx	arg1
	sty	arg2
	ldy	#0
	lda	arg4
	ldx	arg3
	beq	..sb3
..sb1	sta	(arg0),y
	iny
	bne	..sb1
	inc	arg1
	dec	arg3
	bne	..sb1
	beq	..sb3
..sb2	sta	(arg0),y
	iny
..sb3	cpy	arg2
	bne	..sb2
	rts
;
;PROC MoveBlock(BYTE POINTER dest, src, CARD size)
; moves size bytes from src through
; src+size-1 to dest through dest+size-1.
; If dest>src and dest<=src+size-1 then
; transfer will not work properly!
moveblock	sta	arg0
	stx	arg1
	sty	arg2
	ldy	#0
	lda	arg5
	beq	..mb4
..mb2	lda	(arg2),y
	sta	(arg0),y
	iny
	bne	..mb2
	inc	arg1
	inc	arg3
	dec	arg5
	bne	..mb2
	beq	..mb4
..mb3	lda	(arg2),y
	sta	(arg0),y
	iny
..mb4	cpy	arg4
	bne	..mb3
	rts
;
;PROC Break()
; returns to monitor after saving
; stack pointer in procSP
break	tsx
	stx	procsp
	ldy	#brker
	tya
	jmp	error
;
ctrace	proc			; Call Trace handler
; name passed following JSR
	clc
	pla
	adc	#1
	sta	arg10
	pla
	adc	#0
	sta	arg11
; address of name now in arg10-11
; ok, let's print the name
	lda	arg10
	ldx	arg11
	jsr	prt
	lda	#'(
	jsr	put
; now get addr of args
	sec
	lda	arg10
	ldy	#0
	sty	arg15
	adc	(arg10),y
	sta	arg10
	bcc	..ct1
	inc	arg11
..ct1	lda	(arg10),y
	sta	arg12
	iny
	lda	(arg10),y
	sta	arg13
; get number of args
	iny
	lda	(arg10),y
	sta	arg9
	sty	arg14
	beq	..ct7		; no args
..ct2	inc	arg14
	ldy	arg14
	lda	(arg10),y
	bmi	..ct4		; byte
	cmp	#cardt
	inc	arg15
	ldy	arg15
	lda	(arg12),y
	tax
	dey
	bcs	..ct5		; cardinal
; integer
	lda	(arg12),y
	jsr	prti
	jmp	..ct6
..ct4	ldx	#0
	ldy	arg15
..ct5	lda	(arg12),y
	jsr	prtc
..ct6	inc	arg15
	dec	arg9
	beq	..ct7		; all done
	lda	#',
	jsr	put
	jmp	..ct2
; setup return
..ct7	clc
	lda	arg10
	adc	arg14
	tax
	lda	arg11
	adc	#0
	pha
	txa
	pha
	lda	#')
	jsr	put
	jmp	pute
;
;	     LIB.STR
;
; Copyright 1983 by Action Computer Services
; All Rights Reserved
;
; last modified November 3, 1983
;
	proc
lstr	proc
;
;INT FUNC SCompare(STRING a,b)
; result returned is:
;   =0 if a=b
;   low 0 if a<b
;   high 0 if a>b
scompare	sta	arg4
	stx	arg5
	sty	arg2
	ldy	#0
	sty	args
	sty	args+1
	lda	(arg4),y
	cmp	(arg2),y
	beq	..sc1
	jsr	..sc4
..sc1	cmp	#0
	bne	..sc2
	rts
;
..sc2	sta	arg6
..sc3	iny
	lda	(arg4),y
	cmp	(arg2),y
	bne	..sc4
	cpy	arg6
	bcc	..sc3
	rts
;
..sc4	ldx	#$ff
	stx	args
	bcc	..sc5
	lda	(arg2),y
	inx
..sc5	stx	args+1
	rts
;
;PROC SCopy(STRING dest, src)
; dest = src
scopy	sta	arg0
	stx	arg1
	sty	arg2
	ldy	#0
	lda	(arg2),y
scopy1	sta	(arg0),y
	beq	..scp2
scopy2	tay
..scp1	lda	(arg2),y
	sta	(arg0),y
	dey
	bne	..scp1
..scp2	rts
;
;PROC SCopyS(STRING dest, src, BYTE start, stop)
; if LEN(src)<stop then stop=LEN(src)
; dest = src(start, stop)
scopys	sta	arg0
	stx	arg1
	sty	arg2
	ldy	#0
	lda	(arg2),y
	cmp	arg5
	bcs	..scs1
	sta	arg5
..scs1	dec	arg4
	clc
	lda	arg2
	adc	arg4
	sta	arg2
	bcc	..scs2
	inc	arg3
..scs2	sec
	lda	arg5
	sbc	arg4
	bcs	..scs3
	lda	#0
..scs3	jmp	scopy1
;
;PROC SAssign(STRING dest, src, BYTE start, stop)
; IF stop-start+1>LEN(src) THEN
;   stop = LEN(src)+start-1
; IF LEN(dest)<stop THEN
;   LEN(dest) = stop
; dest(start, stop) = src
sassign sta	arg0
	stx	arg1
	sty	arg2
	ldy	#0
	lda	(arg2),y
	beq	..sa1
	sta	arg6
	dec	arg4
	sec
	lda	arg5
	sbc	arg4
	beq	..sa1
	bcs	..sa2
..sa1	rts
..sa2	tax
	cmp	arg6
	bcc	..sa3
	clc
	lda	arg6
	tax
	adc	arg4
	sta	arg5
..sa3	lda	arg5
	cmp	(arg0),y
	bcc	..sa4
	sta	(arg0),y
	clc
..sa4	lda	arg0
	adc	arg4
	sta	arg0
	bcc	..sa5
	inc	arg1
..sa5	txa
	jmp	scopy2
;
	proc			; symbol table
;
;:EN6 .BYTE 6,"PrintF",200
; .WORD PrtF ; #117
; .BYTE 6,17,12,12,12,12,12
..en7	db	4,"Open",200
	dw	opn		; #96
	db	4,138,17,138,138
..en8	db	6,"PrintE",200
	dw	prte		; #116
	db	1,17
..en9	db	7,"PrintDE",200
	dw	prtde		; #75
	db	2,138,17
..en10	db	5,"Close",200
	dw	clos		; #253
	db	1,138
..en11	db	5,"Print",200
	dw	prt		; #135
	db	1,17
..en12	db	6,"PrintD",200
	dw	prtd		; #115
	db	2,138,17
..en13	db	6,"InputS",200
	dw	ins		; #249
	db	1,17
..en14	db	7,"InputSD",200
	dw	insd		; #87
	db	2,138,17
..en15	db	7,"InputMD",200
	dw	inmd		; #75
	db	3,138,17,138
..en16	db	4,"GetD",202
	dw	getd		; #138
	db	1,138
..en17	db	4,"PutE",200
	dw	pute		; #162
	db	0
..en18	db	3,"Put",200
	dw	put		; #158
	db	1,137
..en19	db	4,"PutD",200
	dw	putd		; #161
	db	2,138,137
..en20	db	5,"PutDE",200
	dw	putde		; #168
	db	1,138
..en21	db	3,"XIO",200
	dw	xio		; #225
	db	6,138,138,138,138,138,17
..en22	db	6,"PrintB",200
	dw	prtb		; #113
	db	1,138
..en23	db	7,"PrintBE",200
	dw	prtbe		; #71
	db	1,138
;:EN24 .BYTE 7,"PrintBD",200
; .WORD PrtBD ; #70
; .BYTE 2,138,138
..en25	db	8,"PrintBDE",200
	dw	prtbde		; #241
	db	2,138,138
..en26	db	6,"PrintC",200
	dw	prtc		; #114
	db	1,12
..en27	db	7,"PrintCE",200
	dw	prtce		; #73
	db	1,12
..en28	db	7,"PrintCD",200
	dw	prtcd		; #72
	db	2,138,12
..en29	db	8,"PrintCDE",200
	dw	prtcde		; #245
	db	2,138,12
..en30	db	6,"PrintI",200
	dw	prti		; #120
	db	1,11
..en31	db	7,"PrintID",200
	dw	prtid		; #84
	db	2,138,11
..en32	db	7,"PrintIE",200
	dw	prtie		; #85
	db	1,11
..en33	db	8,"PrintIDE",200
	dw	prtide		; #13
	db	2,138,11
..en34	db	6,"InputB",202
	dw	inb		; #232
	db	0
..en35	db	7,"InputBD",202
	dw	inbd		; #53
	db	1,138
..en36	db	6,"InputI",203
	dw	ini		; #239
	db	0
..en37	db	7,"InputID",203
	dw	inid		; #67
	db	1,138
..en38	db	6,"InputC",204
	dw	inc		; #233
	db	0
..en39	db	7,"InputCD",204
	dw	incd		; #55
	db	1,138
..en40	db	4,"ValB",202
	dw	valb		; #207
	db	1,17
..en41	db	4,"ValI",203
	dw	vali		; #214
	db	1,17
..en42	db	4,"ValC",204
	dw	valc		; #208
	db	1,17
..en43	db	4,"StrB",200
	dw	strb		; #223
	db	2,138,17
..en44	db	4,"StrI",200
	dw	stri		; #230
	db	2,11,17
..en45	db	4,"StrC",200
	dw	strc		; #224
	db	2,12,17
..en46	db	4,"Note",200
	dw	note		; #89
	db	3,138,20,18
..en47	db	5,"Point",200
	dw	point		; #110
	db	3,138,12,138
..en48	db	8,"Graphics",200
	dw	graphics	; #108
	db	1,138
..en49	db	6,"DrawTo",200
	dw	drawto		; #231
	db	2,12,138
..en50	db	8,"Position",200
	dw	position	; #94
	db	2,12,138
..en51	db	6,"Locate",202
	dw	locate		; #97
	db	2,12,138
..en52	db	4,"Plot",200
	dw	plot		; #131
	db	2,12,138
..en53	db	8,"SetColor",200
	dw	setcolor	; #6
	db	3,138,138,138
..en54	db	4,"Fill",200
	dw	fill		; #122
	db	2,12,138
..en55	db	4,"Rand",202
	dw	rand		; #117
	db	1,138
..en56	db	5,"Sound",200
	dw	sound		; #31
	db	4,138,138,138,138
..en57	db	6,"SndRst",200
	dw	sndrst		; #73
	db	0
..en58	db	6,"Paddle",202
	dw	paddle		; #254
	db	1,138
..en59	db	5,"PTrig",202
	dw	ptrig		; #164
	db	1,138
..en60	db	5,"Stick",202
	dw	stick		; #8
	db	1,138
..en61	db	5,"STrig",202
	dw	strig		; #52
	db	1,138
;:EN62 .BYTE 4,"Peek",202
; .WORD Peek ; #73
; .BYTE 1,12
;:EN63 .BYTE 5,"PeekC",204
; .WORD PeekC ; #245
; .BYTE 1,12
..en64	db	4,"Poke",200
	dw	poke		; #120
	db	2,12,138
..en65	db	5,"PokeC",200
	dw	pokec		; #83
	db	2,12,12
..en66	db	4,"Zero",200
	dw	mzero		; #88
	db	2,18,12
..en67	db	8,"SetBlock",200
	dw	setblock	; #203
	db	3,18,12,138
;:EN68 .BYTE 9,"MoveBlock",200
; .WORD MoveBlock ; #85
; .BYTE 3,18,18,12
..en69	db	5,"Break",200
	dw	break		; #183
..en70	db	8,"SCompare",203
	dw	scompare	; #92
	db	2,17,17
..en71	db	5,"SCopy",200
	dw	scopy		; #192
	db	2,17,17
..en72	db	6,"SCopyS",200
	dw	scopys		; #244
	db	4,17,17,138,138
..en73	db	7,"SAssign",200
	dw	sassign 	; #23
	db	4,17,17,138,138
;
; hash table
;
libst	db	0		; 1
	db	high en1		; EOF #1
	db	high en5		; TRACE #2
	db	0,0,0		; 3
	db	high ..en53		; SetColor #6
	db	0		; 1
	db	high ..en60		; Stick #8
	db	0,0,0,0 	; 4
	db	high ..en33		; PrintIDE #13
	db	high en2		; color #14
	db	0,0,0,0,0,0,0,0 ; 8
	db	high ..en73		; SAssign #23
	db	0,0,0,0,0,0,0	; 7
	db	high ..en56		; Sound #31
	db	high en3		; LIST #32
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0 ; 19
	db	high ..en61		; STrig #52
	db	high ..en35		; InputBD #53
	db	0		; 1
	db	high ..en39		; InputCD #55
	db	0,0,0,0,0,0,0,0,0,0
	db	0		; 11
	db	high ..en37		; InputID #67
	db	0,0		; 2
	db	high ..en24		; PrintBD #70
	db	high ..en23		; PrintBE #71
	db	high ..en28		; PrintCD #72
	db	high ..en27		; PrintCE #73
	db	high ..en57		; SndRst #74
	db	high ..en9		; PrintDE #75
	db	high ..en15		; InputMD #76
	db	high ..en62		; Peek #77
	db	0,0,0,0,0	; 5
	db	high ..en65		; PokeC #83
	db	high ..en31		; PrintID #84
	db	high ..en32		; PrintIE #85
	db	high ..en68		; MoveBlock #86
	db	high ..en14		; InputSD #87
	db	high ..en66		; Zero #88
	db	high ..en46		; Note #89
	db	0,0		; 2
	db	high en4		; device #92
	db	high ..en70		; SCompare #93
	db	high ..en50		; Position #94
	db	0		; 1
	db	high ..en7		; Open #96
	db	high ..en51		; Locate #97
	db	0,0,0,0,0,0,0,0,0,0 ; 10
	db	high ..en48		; Graphics #108
	db	0		; 1
	db	high ..en47		; Point #110
	db	0,0		; 2
	db	high ..en22		; PrintB #113
	db	high ..en26		; PrintC #114
	db	high ..en12		; PrintD #115
	db	high ..en8		; PrintE #116
	db	high ..en6		; PrintF #117
	db	high ..en55		; Rand #118
	db	0		; 1
	db	high ..en30		; PrintI #120
	db	high ..en64		; Poke #121
	db	high ..en54		; Fill #122
	db	0,0,0,0,0,0,0,0 ; 8
	db	high ..en52		; Plot #131
	db	0,0,0		; 3
	db	high ..en11		; Print #135
	db	0,0		; 2
	db	high ..en16		; GetD #138
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0 ; 18
	db	high en0		; Error #157
	db	high ..en18		; Put #158
	db	0,0		; 2
	db	high ..en19		; PutD #161
	db	high ..en17		; PutE #162
	db	0		; 1
	db	high ..en59		; PTrig #164
	db	0,0,0		; 3
	db	high ..en20		; PutDE #168
	db	0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0 	; 14
	db	high ..en69		; Break #183
	db	0,0,0,0,0,0,0,0 ; 8
	db	high ..en71		; SCopy #192
	db	0,0,0,0,0,0,0,0,0,0 ; 10
	db	high ..en67		; SetBlock #203
	db	0,0,0		; 3
	db	high ..en40		; ValB #207
	db	high ..en42		; ValC #208
	db	0,0,0,0,0	; 5
	db	high ..en41		; ValI #214
	db	0,0,0,0,0,0,0,0 ; 8
	db	high ..en43		; StrB #223
	db	high ..en45		; StrC #224
	db	high ..en21		; XIO #225
	db	0,0,0,0 	; 4
	db	high ..en44		; StrI #230
	db	high ..en49		; DrawTo #231
	db	high ..en34		; InputB #232
	db	high ..en38		; InputC #233
	db	0,0,0,0,0	; 5
	db	high ..en36		; InputI #239
	db	0		; 1
	db	high ..en25		; PrintBDE #241
	db	0,0		; 2
	db	high ..en72		; SCopyS #244
	db	high ..en29		; PrintCDE #245
	db	high ..en63		; PeekC #246
	db	0,0		; 2
	db	high ..en13		; InputS #249
	db	0,0,0		; 3
	db	high ..en10		; Close #253
	db	high ..en58		; Paddle #254
	db	0		; 1
;
	db	0		; 1
	db	low en1
	db	low en5
	db	0,0,0		; 3
	db	low ..en53
	db	0		; 1
	db	low ..en60
	db	0,0,0,0 	; 4
	db	low ..en33
	db	low en2
	db	0		; 1
;
; .BYTE 0,0,0,0,0,0,0,0 ; 7
strig	tax
	lda	$d010,x
	sta	args
	rts
;
	db	low ..en73
;
; .BYTE 0,0,0,0,0,0,0 ; 7
paddle	tax
	lda	$0270,x
	sta	args
	rts
;
	db	low ..en56
	db	low en3
	db	0,0		; 2
;
; .BYTE 0,0,0,0,0,0,0,0,0,0
; .BYTE 0,0,0,0,0,0,0,0,0 ; 17
..en6	db	6,"PrintF",200
	dw	prtf		; #117
	db	6,17,12,12,12,12,12
;
	db	low ..en61
	db	low ..en35
	db	0		; 1
	db	low ..en39
;
; .BYTE 0,0,0,0,0,0,0,0,0,0
; .BYTE 0 ; 11
..en63	db	5,"PeekC",204
	dw	peekc		; #245
	db	1,12
;
	db	low ..en37
	db	0,0		; 2
	db	low ..en24
	db	low ..en23
	db	low ..en28
	db	low ..en27
	db	low ..en57
	db	low ..en9
	db	low ..en15
	db	low ..en62
	db	0,0,0,0,0	; 5
	db	low ..en65
	db	low ..en31
	db	low ..en32
	db	low ..en68
	db	low ..en14
	db	low ..en66
	db	low ..en46
	db	0,0		; 2
	db	low en4
	db	low ..en70
	db	low ..en50
	db	0		; 1
	db	low ..en7
	db	low ..en51
;
; .BYTE 0,0,0,0,0,0,0,0,0,0 ; 10
; (c)1983ACS in internal char. qcode
copyright	db	8,99,9,17,25,24,19,33,35,51
;
	db	low ..en48
	db	0		; 1
	db	low ..en47
	db	0,0		; 2
	db	low ..en22
	db	low ..en26
	db	low ..en12
	db	low ..en8
	db	low ..en6
	db	low ..en55
	db	0		; 1
	db	low ..en30
	db	low ..en64
	db	low ..en54
	db	0,0,0,0,0,0,0,0 ; 8
	db	low ..en52
	db	0,0,0		; 3
	db	low ..en11
	db	0,0		; 2
	db	low ..en16
	db	0		; 1
;
; .BYTE 0,0,0,0,0,0,0,0,0,0
; .BYTE 0,0,0,0,0,0,0,0 ; 17
..en68	db	9,"MoveBlock",200
	dw	moveblock	; #85
	db	3,18,18,12
;
	db	low en0
	db	low ..en18
	db	0,0		; 2
	db	low ..en19
	db	low ..en17
	db	0		; 1
	db	low ..en59
	db	0,0,0		; 3
	db	low ..en20
;
; .BYTE 0,0,0,0,0,0,0,0,0,0
; .BYTE 0,0,0,0 ; 14
..en24	db	7,"PrintBD",200
	dw	prtbd		; #70
	db	2,138,138
;
	db	low ..en69
	db	0,0,0,0,0,0,0,0 ; 8
	db	low ..en71
;
; .BYTE 0,0,0,0,0,0,0,0,0,0 ; 10
..en62	db	4,"Peek",202
	dw	peek		; #73
	db	1,12
;
	db	low ..en67
	db	0,0,0		; 3
	db	low ..en40
	db	low ..en42
	db	0,0,0,0,0	; 5
	db	low ..en41
	db	0,0,0,0,0,0,0,0 ; 8
	db	low ..en43
	db	low ..en45
	db	low ..en21
	db	0,0,0,0 	; 4
	db	low ..en44
	db	low ..en49
	db	low ..en34
	db	low ..en38
	db	0,0,0,0,0	; 5
	db	low ..en36
	db	0		; 1
	db	low ..en25
	db	0,0		; 2
	db	low ..en72
	db	low ..en29
	db	low ..en63
	db	0,0		; 2
	db	low ..en13
	db	0,0,0		; 3
	db	low ..en10
	db	low ..en58
; .BYTE 0 ; 1

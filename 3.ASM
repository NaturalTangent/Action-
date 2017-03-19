$eject
;===========================
;         SCREEN.MAC
;===========================
; Copyright 1982 by Clinton W Parker
; All Rights Reserved
; last modified October 18, 1982
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

scrinit	proc	
	lda	#0
	jsr	close		; close #0, sets X to 0
	lda	#$0c
	sta	arg3
	lda	#0
	ldx	#low scred
	ldy	#high scred
	jmp	open
	endproc

scred	db	2,"E:",$9b


;	 ScrCh(char)
;	------------
; outputs char to screen.  Char passed in A reg.
; Control characters are ignored.

scrch	proc	
	tay	
	lda	#0
scrchar	ldx	#1
	bne	putch1
	endproc


;	PutCh(char)
;	-----------
; outputs char to screen.  Char passed in A reg.
; Processes control characters.

putch	proc	
	tay	
	lda	#0
	tax	
putch1	stx	$02fe		; DSPFLG
	asl	a
	asl	a
	asl	a
	asl	a
	tax	
	lda	#$0b		; PUTCHR
putch2	sta	$0342,x		; ICCOM
	lda	#0
	sta	$0348,x		; ICBLL
	sta	$0349,x		; ICBLH
	tya	
	jmp	$e456		; CIOV


;	ScrUp() - Move cursor up one
;	----------------------------
scrup	proc
	lda	#$1c
	bne	putch
	endproc


;	ScrDwn() - Move cursor down one
;	-------------------------------
scrdwn	proc
	lda	#$1d
	bne	putch
	endproc


;	ScrBell() - Bell Char
;	---------------------
scrbell	proc
	lda	#$fd
	bne	putch
	endproc


;	ScrLft() - Move cursor left one
;	-------------------------------
scrlft	proc
	lda	#$1e
	bne	putch
	endproc


;	ScrRt() - Move cursor right one
;	-------------------------------
scrrt	proc
	lda	#$1f
	bne	putch
	endproc


$eject
;=============================
;	Compiler tokens
;=============================

plusid	equ	1
minusid	equ	2
timesid	equ	3
divideid equ	4
orid	equ	5
andid	equ	6
equalid	equ	7
neid	equ	8
grid	equ	9
geid	equ	10
lsid	equ	11
leid	equ	12
remid	equ	13
xorid	equ	14
lshid	equ	15
rshid	equ	16
uminusid equ	17
atid	equ	18

scolon	equ	21
squote	equ	22
period	equ	23
rparen	equ	24
lparen	equ	25
comma	equ	26
defid	equ	27
digit	equ	28+$80
hex	equ	29
quote	equ	30

char	equ	32
byte	equ	33
int	equ	34
card	equ	35
string	equ	36
real	equ	37
define	equ	38
record	equ	39

array	equ	64
func	equ	65
proc	equ	66
get	equ	67
set	equ	68
pointer	equ	69
typeid	equ	70

ifid	equ	80
whileid	equ	81
retid	equ	82
exitid	equ	83
forid	equ	84
caseid	equ	85
codeid	equ	86
modid	equ	87
untilid	equ	88

lbrack	equ	91
rbrack	equ	93
uparrow	equ	94

then	equ	96
else	equ	97
do	equ	98
fi	equ	99
od	equ	100
to	equ	101
step	equ	102
of	equ	103
esac	equ	104
edoc	equ	105
elseif	equ	106
downto	equ	107

typet	equ	$70		; 112

eofid	equ	127

constt	equ	$80
vart	equ	$88
arrayt	equ	$90
tempt	equ	$a8
funct	equ	$c0
condt	equ	$48

;	types
;	-----
chart	equ	1
bytet	equ	2
intt	equ	3
cardt	equ	4
strt	equ	5
realt	equ	6

undec	equ	$88


$eject
;========================
;	Error codes
;========================

; 0 - out of system memory
strer	equ	1		; missing " at end
dfner	equ	2		; nested defines
ster	equ	3		; too many qglobal st
; 4 - too many local st entries
seter	equ	5		; SET syntax error
dcler	equ	6		; declaration error
arger	equ	7		; bad argument list
varer	equ	8		; var not declared
conster	equ	9		; not int const
asser	equ	10		; bad assignment
ender	equ	11		; unknown error
thener	equ	12		; missing THEN
fier	equ	13		; missing FI
cder	equ	14		; out of qcode space
doer	equ	15		; missing DO
toer	equ	16		; missing TO
exper	equ	17		; bad expression
parer	equ	18		; unmatched ()s
oder	equ	19		; missing OD
alcer	equ	20		; can't alloc mem.
arrer	equ	21		; bad array ref.
; 22 - file too large on input
cnder	equ	23		; illegal cond. exp.
forer	equ	24		; illegal FOR stmt
exiter	equ	25		; no loop for EXIT
nster	equ	26		; nesting level too deep
typer	equ	27		; illegal type ref.
reter	equ	28		; illegal RETURN stmt.
;61 - out of st space
brker	equ	$80		; Break key depressed


$eject
;============================================
;	Compiler lexicon - get tokens
;============================================

;	GetNext()
;	---------
getnext	proc
	lda	spnxt
	ldx	curnxt
	ldy	curnxt+1
	stx	curln
	sty	curln+1
	sta	spln

	lda	token
	sta	lsttoken
	ldx	nxtaddr
	ldy	nxtaddr+1
	lda	nxttoken
	stx	addr
	sty	addr+1
	sta	token
getnloop
	jsr	nextchar
getnl0	cmp	#eofid
	beq	getnr1

	cmp	#'!
	bcc	getnloop
			; save line index for debugging
	ldx	choff
	stx	spnxt

	cmp	#'A
	bcs	getnl1
	tay	
	lda	lexchars-33,y
	beq	getnloop
	bpl	getnr1
	and	#$7f
	bne	getnr0		; uncond.

getnl1	jsr	alpha
	bne	getnid

	cmp	#'[
	beq	getnr1
	cmp	#'^
	beq	getnr1
	cmp	#']
	beq	getnr1
	bne	getnloop	; uncond.

getnid	jsr	getname
	bmi	getnr1

getnr0	sta	nxttoken
	ldx	#low lexcmd
	ldy	#high lexcmd
	jmp	lookup

getnr1	sta	nxttoken

;GetNr2 LDA $D0
; BEQ GetNr3
; JSR PrintTok

getnr2	ldx	addr
	ldy	addr+1
ismt	lda	token
	rts	
	endproc


;	LexCom()
;	--------
lexcom	proc
	jsr	nextline
	bne	getnl0		; uncond.
	endproc


;	LexDig()
;	--------
lexdig	proc
	lda	#constt+intt
	sta	nxttoken
	jsr	lexbuf		; get buf ptr
	jsr	storeal
ldig1	jsr	nextchar	; cardinal?
	jsr	num
	bne	ldig1
	cmp	#'.
	beq	ldig4
	cmp	#'E
	beq	ldig4
	dec	choff
	jsr	rtocar
	bcc	ldig3

cnsterr	ldy	#conster
	jmp	splerr

ldig2	dey	
	sty	choff
ldig3	sta	nxtaddr
	stx	nxtaddr+1
	cpx	#0
	bne	getnr2
	lda	#constt+bytet
	bne	getnr1

ldig4	lda	#constt+realt
	sta	nxttoken
	ldy	cix
	ldx	#$ff		; for SET cmd
	bne	ldig2
	endproc


;	LexChr()
;	--------
lexchr	proc
	jsr	nextchar
	sta	nxtaddr
	lda	#constt+chart
	bne	getnr1
	endproc


;	LexNE()
;	-------
lexne	proc
	jsr	nextchar
	cmp	#'>
	bne	leq1
	lda	#neid
	bne	getnr1		; uncond.
	endproc


;	LexEq()
;	-------
lexeq	proc
	jsr	nextchar
leq1	cmp	#'=
	bne	putback
	inc	nxttoken
	bne	getnr2		; uncond.
	endproc


;	LexHex()
;	--------
lexhex	proc
	lda	#constt+cardt
	sta	nxttoken
	inc	choff
	jsr	lexbuf
	jsr	htocar
	bne	ldig2		; uncond.
	endproc


;	PutBack returns character to buf
;	--------------------------------
putback	proc	
	dec	choff
pback	jmp	getnr2
	endproc


;	LexPF()
;	-------
lexpf	proc
	lda	qglobal
	beq	pback
	lda	#0
	sta	qglobal

	lda	gbase		; restore qglobal base
	sta	symtab
	lda	gbase+1
	sta	symtab+1
	bne	pback		; uncond.
	endproc


;	LexStr()
;	--------
lexstr	proc
	lda	token
	cmp	#quote
	beq	pback		; zap local st
	lda	#0
	sta	arg9
..lstr1	jsr	nextchar
	inc	arg9
	beq	..lstr3		; string too long
	cmp	#'"'
	beq	..lstr4
..lstr2	ldy	arg9
	sta	(symtab),y
	lda	chan
	bpl	..lstr1		; if not EOF
..lstr3	ldy	#strer
	jmp	splerr

..lstr4	jsr	nextchar
	cmp	#'"
	beq	..lstr2		; " in string
				; end of string
	ldy	arg9
	lda	#eol
	sta	(symtab),y
	dey	
	tya	
	ldy	#0
	sta	(symtab),y	; save size
	lda	symtab
	ldx	symtab+1
	ldy	choff
	dey	
	jmp	ldig2
	endproc


;	NextChar()
;	----------
nextchar proc
	ldy	defflg
	bne	lexdef

nxtch0	ldy	choff
	cpy	sp
	bcc	nxtch1
	endproc


;	NextLine()
;	----------
nextline proc
	lda	chan
	beq	..nln1
	bmi	..nln4		; eof

	jsr	rdbuf
	bpl	..nln2

	cpy	#$88		; EOF
	beq	..nln0
	jmp	splerr

..nln0	dec	chan
	bne	nextline

..nln1	ldy	top+1
	beq	..nln0		; set eof, tricky qcode
	jsr	ldbuf
	lda	cur
	sta	curnxt
	ldx	cur+1
	stx	curnxt+1
	jsr	nextdwn
	bne	..nln2
;	LDA #0
	sta	top+1

..nln2	lda	list
	beq	..nln3		; don't list
	lda	device
	jsr	wrtbuf
..nln3	ldy	#0
	sty	choff
	lda	(buf),y
	tay	
	iny	
	sty	sp
	lda	#eol
	sta	(buf),y
	ldy	#0

nxtch1	iny	
	lda	(buf),y
	sty	choff
	rts	

..nln4	lda	#eofid
	rts	
	endproc


lexdef	proc	
	ldy	#0
	lda	(delnxt),y
	inc	choff
	cmp	choff
	bcs	ldef1
	lda	defflg
	sta	choff
	sty	defflg
	bcc	nxtch0		; uncond.

ldef1	ldy	choff
	lda	(delnxt),y
	rts	
	endproc


;	LexGet()
;	--------
lexget	proc
	jsr	getnloop
lget	lda	#0
	sta	defflg
	inc	chan
	lda	#4
	jsr	openchan
	jsr	nextline
	jmp	getnl0
	endproc


;	LexSet()
;	--------
lexset	proc
	jsr	getadr
	sta	arg11
	stx	arg12

	jsr	getnloop
	lda	nxttoken
	cmp	#equalid
	bne	lseterr

	jsr	getadr
	ldy	#0
	sta	(arg11),y
	txa	
	beq	lset1
	iny	
	sta	(arg11),y
lset1	jmp	getnloop

lseterr	ldy	#seter
	jmp	splerr

getadr	jsr	getnloop
	jmp	mnum
	endproc


;	LexExpand()
;	-----------
lexexpand proc
	lda	defflg
	beq	lexp
	ldy	#dfner
	jmp	splerr

lexp	lda	#3
	jsr	nxtprop
	lda	props
	ldx	props+1
	jsr	rstp
	ldy	choff
lexp1	sta	delnxt
	stx	delnxt+1
	sty	defflg
	lda	#0
	sta	choff
	jmp	getnloop
	endproc


;	LexBuf()
;	--------
lexbuf	proc
	ldy	choff
	lda	defflg
	beq	..lbuf
	lda	delnxt
	ldx	delnxt+1
	rts	
..lbuf	lda	buf
	ldx	buf+1
	rts	


lexcmd	dw	getnr2
	 db	41
	dw	lexdig
	 db	digit-$80
	dw	lexhex
	 db	hex
	dw	lexeq
	 db	grid
	dw	lexne
	 db	lsid
	dw	lexexpand
	 db	defid
	dw	lexcom
	 db	scolon
	dw	lexchr
	 db	squote
	dw	lexpf
	 db	proc
	dw	lexpf
	 db	func
	dw	lexpf
	 db	modid
	dw	lexstr
	 db	quote
	dw	lexget
	 db	get
	dw	lexset
	 db	set

lexchars
	db	xorid		; !
	db	quote+$80	; "
	db	neid		; #
	db	hex+$80		; $
	db	orid		; %
	db	andid		; &
	db	squote+$80	; '
	db	lparen
	db	rparen
	db	timesid
	db	plusid
	db	comma
	db	minusid
	db	period		; .
	db	divideid+$80	; /
	db	digit,digit,digit,digit
	db	digit,digit,digit,digit
	db	digit,digit	; 0 thru 9
	db	0		; :
	db	scolon+$80	; ;
	db	lsid+$80	; low
	db	equalid		; =
	db	grid+$80	; high
	db	126		; ?
	db	atid		; @

;PrintTok LDA token
; LDX #0
; JSR PrintC
; JSR PutSp
; LDA addr
; LDX addr+1
; JSR PrintH
; JSR PutSp
; LDA nxtToken
; LDX #0
; JSR PrintC
; JSR PutSp
; LDA nxtAddr
; LDX nxtAddr+1
; JSR PrintH
; JMP PutEOL


$eject
;========================
;         MAIN.MSC
;=========================

;	LShift(val, cnt)
;	----------------
lsh1	proc	
..a	equ	aflast+1
..b	equ	aflast
..c	equ	afcur+1
..d	equ	afcur
..rl	equ	afsize
..rh	equ	afsize+1
..t1	equ	addr
..t2	equ	addr+1
..sign	equ	token

	sty	..d
lshift	ldy	..d
	beq	..lshret
	stx	..c
..lsh1	asl	a
	rol	..c
	dey	
	bne	..lsh1
	ldx	..c
..lshret rts	
	endproc


;	NextUp()
;	--------
nextup	proc
	ldy	#1
	bne	next		; uncond.
	endproc


;	NextDwn()
;	---------
nextdwn	proc
	ldy	#5
	endproc


;	Next(,,dir)
;	-----------
next	proc
	jsr	chkcur
	beq	next1
	lda	(cur),y
	beq	next1
	tax	
	dey	
	lda	(cur),y
	sta	cur
	txa	
	sta	cur+1
next1	rts	
	endproc


;	CurStr()
;	--------
curstr	proc
	lda	cur
	ldx	cur+1
	endproc


;	StrPtr()
;	--------
strptr	proc
	clc	
	adc	#6
	sta	arg0
	bcc	..sp1
	inx	
..sp1	stx	arg1
	rts	
	endproc


;	MNum()
;	------
mnum	proc
	lda	#0
	sta	afsize
	sta	afsize+1

..mn1	lda	nxttoken
	cmp	#timesid
	beq	..mn4		; qcode reference
	cmp	#lbrack
	beq	..mn5
	cmp	#record
	beq	mnvar
	cmp	#typet
	beq	mnvar
	cmp	#typet+8
	beq	mnvar
	cmp	#quote
	beq	..mnstr
	cmp	#undec
	beq	..mnundec
	bcs	mnvar
	jsr	getconst
	bcc	..mn2

mnvar	lda	#1
	jsr	nxtprop
..mnv1	jsr	rstp

..mn2	clc	
	adc	afsize
	sta	afsize
	txa	
	adc	afsize+1
..mn2a	sta	afsize+1
	jsr	nextchar
	cmp	#'+
	bne	..mn2b
	jsr	getnext
	bne	..mn1		; uncond.

..mn2b	ldy	#0
	cmp	#'^
	bne	..mn3
	lda	(afsize),y
	tax	
	iny	
	lda	(afsize),y
	stx	afsize
	jmp	..mn2a

..mn3	dec	choff		; put back character
	lda	afsize
	ldx	afsize+1
;	LDY #0
	rts	

..mn4	jsr	getcdoff	; qcode reference
	jmp	..mn2

..mn5	jsr	getcdoff	; table reference
	pha	
	txa	
	pha	
	bne	..mn8		; uncond.

..mnstr	jsr	copystr		; string ref
	jmp	..mn2

..mn6	lda	nxttoken	; body of table
	cmp	#rbrack
	beq	..mn9
	jsr	getconst
	ldy	#0
	jsr	storevar
	lda	op
	beq	..mn7		; byte?
	iny			; no, word
..mn7	tya	
	jsr	codeincr
..mn8	jsr	getnext
	bne	..mn6		; uncond.

..mnundec	lda	#1
	jsr	nxtprop
	tax	
	iny	
	lda	(props),y
	beq	varerr
	tay	
	sta	bank+lbank
	lda	#1
	jsr	gprop
	jsr	rstbank
	jmp	..mnv1

varerr	ldy	#varer
adrerr	jmp	splerr

..mn9	pla			; end of table
	tax	
	pla	
	jmp	..mn2
	endproc


;	GetConst(token)
;	---------------
getconst proc
	ldy	#conster
	cmp	#$81
	bcc	adrerr
	cmp	#constt+strt
	bcs	adrerr
	lda	nxtaddr
	ldx	nxtaddr+1
	rts	
	endproc


copystr	proc	
	jsr	getcdoff
	pha	
	txa	
	pha	

	ldy	#0
	lda	(nxtaddr),y	; size
	sta	(qcode),y
	tax	
	tay	
..cs1	lda	(nxtaddr),y
	sta	(qcode),y
	dey	
	bne	..cs1

	inx	
	txa	
	bne	..cs2
	inc	qcode+1
..cs2	jsr	codeincr
	inc	choff		; get rid of end quote
	pla	
	tax	
	pla	
	rts	
	endproc


;	GetCdOff()
;	----------
getcdoff proc
	clc	
	lda	qcode
	adc	codeoff
	pha	
	lda	qcode+1
	adc	codeoff+1
	tax	
	pla	
	rts	
	endproc


;	StoreVar(low, high, index)
;	--------------------------
storevar proc
	sta	(qcode),y
	iny	
	txa	
	sta	(qcode),y
	rts	
	endproc


lookup	proc	
	sty	arg2
	$if	ramzap
	 sta	(arg1),y	; zap RAM if any
	$else	
	 nop	
	 nop	
	$endif	

lu1	stx	arg1
	tax	
	ldy	#2
	lda	(arg1),y
	tay	
	txa	
..fml1	cmp	(arg1),y
	beq	..fmjmp
	dey	
	dey	
	dey	
	cpy	#2
	bne	..fml1

..fmjmp	dey	
	lda	(arg1),y
	sta	arg4
	dey	
	lda	(arg1),y
	sta	arg3
	jmp	(arg3)
	endproc


;	AlphaNum(char)
;	--------------
alphanum proc
	jsr	alpha
	bne	..anum2

num	cmp	#'0
	bmi	..anum1
	cmp	#':
	bmi	..anum2
..anum1	ldx	#0
..anum2	rts	
	endproc


;	Alpha(char)
;	-----------
alpha	proc
	pha	
	ora	#$20
	tax	
	pla	
	cpx	#'a
	bmi	..alpha1
	cpx	#$7b
	bmi	alpha2
..alpha1 ldx	#0
alpha2	rts	
	endproc


;	STIncr(size)
;	------------
stincr	proc
	clc	
	adc	symtab
	sta	symtab
	bcc	..s1
	 inc	symtab+1
..s1	lda	stmax
	cmp	symtab+1
	bcs	alpha2		; return

	ldy	#61		; out of s.t. space
	jmp	splerr
	endproc


;	CodeIncr(size)
;	--------------
codeincr proc
	clc	
	adc	qcode
	sta	qcode
	bcc	..c1
	 inc	qcode+1
..c1	lda	stbase
	cmp	qcode+1
	bcs	alpha2		; return

cderr	sta	bank+ebank
	jsr	splsetup	; reset compiler
	ldy	#cder		; out of qcode space
	jmp	splerr
	endproc


;	NxtProp(offset)
;	---------------
nxtprop	proc
	ldx	props
	stx	aflast
	ldx	props+1
	stx	aflast+1
	ldx	nxtaddr
	ldy	nxtaddr+1
	bne	gprop
	endproc


;	CProp(offset)
;	-------------
cprop	proc
	ldx	curproc
	ldy	curproc+1
	bne	gprop
	endproc


;	GetProp(offset)
;	---------------
getprop	proc
	ldx	addr
	ldy	addr+1
	endproc


;	GProp(offset, addr)
;	-------------------
gprop	proc
	stx	props
	sty	props+1
	ldx	props+1
	clc	
	adc	props
	bcc	..gp1
	inx	
..gp1	sec	
	ldy	#0
	adc	(props),y
	sta	props
	bcc	..gp2
	inx	
..gp2	stx	props+1
	iny	
	lda	(props),y
	tax	
	dey	
	lda	(props),y
	rts	
	endproc


rstp	proc	
	ldy	aflast
	sty	props
	ldy	aflast+1
	sty	props+1
	rts	
	endproc


;	JSRInd(addr)
;	------------
jsrind	proc
	sta	adress
	stx	adress+1
	jmp	(adress)
	endproc


$eject
;=======================
;	MAIN.BNK
;=======================

en0	db	5,"Error",$c0
	dw	error
	db	3,138,138,138

en1	db	3,"EOF",$9a
	dw	eof

en2	db	5,"color",$8a
	dw	$02fd

en3	db	4,"LIST",$8a
	dw	list

en4	db	6,"device",$8a
	dw	device

en5	db	5,"TRACE",$8a
	dw	trace


;	CStrt()
;	-------
cstart	proc
	ldy	#ebank
	sty	curbank
	sty	bank+ebank
	jmp	start
	endproc


;	GetName(char)
;	-------------
getname	proc
	sta	bank+lbank
	jsr	lgetname
	endproc


;	RstBank()
;	---------
rstbank	proc
	php	
	pha	
	tya	
	ldy	curbank
rbank1	sta	bank,y
	tay	
	pla	
	plp	
init	rts	
	endproc


;	Run(address)
;	------------
run	proc			; reset Error routine
	ldy	#low splerr
	sty	error+1
	ldy	#high splerr
	sty	error+2
	jsr	lproceed
	jsr	jsrind
	jmp	editbank
	endproc


;	Compile()
;	---------
compile	proc
	ldy	#cbank
	sty	curbank
	sty	bank+cbank
	jsr	ccompile
	endproc


;	EditBank()
;	----------
editbank proc
	php	
	pha	
	tya	
	ldy	#ebank
	sty	curbank
	jmp	rbank1
	endproc


;	GetAlias()
;	----------
getalias proc
	lda	#1
	jsr	getprop
	cpx	#0
	beq	..gal1
	sta	addr
	stx	addr+1
	sta	bank+lbank
	lda	#0
	jsr	getprop
	sta	token
	jmp	rstbank

..gal1	jmp	varerr
	endproc


;	GNlocal()
;	---------
gnlocal	proc
	sta	bank+lbank
	jsr	lgnlocal
	jmp	rstbank
	endproc


;	CStmtList()
;	-----------
cstmtlst proc
	ldy	#cbank
	sty	curbank
	sta	bank+cbank
	jsr	stmtlist
	jmp	editbank
	endproc


mgett1	proc	
	jsr	editbank
	jsr	gett1
	endproc


;	LProceed()
;	----------
lproceed proc
	ldy	#lbank
	sty	curbank
	sty	bank+lbank
	rts	
	endproc



options	proc	
	jsr	lproceed
	jsr	setopts
	jmp	editbank
	endproc


getkey	proc	
	sta	bank+lbank
	jsr	lgetkey
	jmp	rstbank
	endproc


splerr	proc	
	sta	bank+lbank
	jmp	lsplerr
	endproc


emloop	proc	
	jsr	editbank
	jmp	mloop
	endproc


getargs	proc	
	pha			; save arg type load flag
	sty	bank+lbank
	lda	#1
	jsr	getprop
	sta	addr
	stx	addr+1

	pla	
	bne	..ga2		; don't load arg types

	sta	abt		; A=0
	sta	abt+1		; flag as temp args
	sta	abt+2		; (default)

	ldy	#2
	lda	(props),y
	sta	numargs
	beq	..ga2
	tax	
	cpx	#9
	bcs	..ga2
..ga1	 iny	
	 lda	(props),y
	 dex	
	 sta	argtypes,x	; args inverted
	 bne	..ga1
..ga2	jmp	rstbank
	endproc


prth	proc			; call only from LBANK!
	sty	bank+ebank
	jsr	printh
	sty	bank+lbank
	jmp	chkerr
	endproc


; go directly to DOS, do NOT pass GO,
; do NOT collect $200, but setup LIB
;------------------------------------
dret	proc			; Dret()
	jsr	lproceed
	jmp	(dosvec)
	endproc

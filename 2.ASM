	list	on
$eject
;=========================
;         MAIN.IO
;=========================
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


;	Open(device, name, mode, opt)
;	-----------------------------
; returns status

open	proc	
	stx	arg5
	sty	arg6
	ldy	#3
	bne	xiostr
	endproc


;	Print(device, str)
;	------------------
print	proc
	stx	arg5
	sty	arg6
	ldx	#0
	stx	arg3
	ldy	#$09
	jsr	xiostr
	bne	print1
	 lda	#$0b
	 sta	$0342,x
	 lda	#eol
	 jmp	$e456
print1	rts	
	endproc


;	Close(device)
;	-------------
close	proc
	ldx	#high ml
	stx	arg6		; note: address must be non-zero to
				; fake out zero check in XIOstr
	$if	ramzap
	 sta	(arg5),y
	$else	
	 nop	
	 nop	
	$endif	

	ldy	#$0c
	bne	input1
	endproc


;	Input(device, str)
;	------------------
input	proc
	sty	arg6
	ldy	#$05
input1	stx	arg5
	ldx	#0
	stx	arg3
	endproc


;	XIOstr(device,,cmd,aux1,aux2,str)
;	---------------------------------
xiostr	proc	
	asl	a
	asl	a
	asl	a
	asl	a
	tax	
	tya	
	sta	$0342,x		; command
	lda	arg3
	beq	..xs1
	 sta	$034a,x		; aux1
	 lda	arg4
	 sta	$034b,x		; aux2
	 lda	#0
..xs1	tay	
	sta	$0349,x
	lda	(arg5),y
	sta	$0348,x		; size
	beq	print1		; return
	clc	
	lda	arg5
	adc	#1
	sta	$0344,x		; buf
	 lda	arg6
	 adc	#0
	 sta	$0345,x
	jmp	$e456
	endproc


;	Output(device, str)
;	-------------------
output	proc
	sty	arg6
	ldy	#$0b
	bne	input1
	endproc


;	DspStr(prompt, str, invert)
;	---------------------------
dspstr	proc	
	sty	arg12
	ldy	arg3
	sty	arg13
	ldy	#0
	sty	arg3
	ldy	arg4
	jsr	putstr

	lda	arg6		; PutStr size
	clc	
	adc	lmargin
	sta	colcrs
	jsr	scrrt

	ldy	#0
	lda	(arg12),y
	beq	..ds2
 	sta	arg3
	sty	arg4

..ds1	inc	arg4
	ldy	arg4
	lda	(arg12),y
	eor	arg2
	jsr	scrch
	dec	arg3
	bne	..ds1
..ds2	rts	
	endproc


;	RdBuf(device)
;	-------------
rdbuf	proc
; INC COLOR4
	nop	
	nop	
	nop	
	ldy	#0
	tax	
	lda	#240
	sta	(buf),y
	txa	
	ldx	buf
	ldy	buf+1
inputs	jsr	input
	sty	arg0
	lda	$0348,x		; size
	beq	..rb1
	 sec	
	 sbc	#1
..rb1	ldy	#0
	sta	(arg5),y
	ldy	arg0
	rts	
	endproc


;	WrtBuf(device)
;	--------------
wrtbuf	proc
	ldx	buf
	ldy	buf+1
	jmp	print
	endproc


;	RstCur()
;	--------
rstcur	proc
	ldy	curwdw
	lda	w1+wcur,y
	sta	cur
	lda	w1+wcur+1,y
	sta	cur+1
	jmp	ldbuf
	endproc


;	SysErr(,,errnum)
;	----------------
syserr	proc
	jsr	dspon
	tya	
	ldx	#0
	jsr	ctostr
	jsr	cmdcol
	lda	#$80
	sta	arg4
	lda	#high numbuf
	sta	arg3
	ldy	#low numbuf
	lda	#low sermsg
	ldx	#high sermsg
	jsr	dspstr
	jsr	rstcsr
	jsr	rstcol
	jmp	scrbell
	endproc

sermsg	db	7,"Error: "


;	CToStr(num) - Cardinal to string
;	--------------------------------
ctostr	proc
	sta	fr0
	stx	fr0+1
	jsr	ifp		; Cardinal to real
	endproc


;	RToStr() - real in FR0
;	----------------------
rtostr	proc
	jsr	fasc
	ldy	#$ff
	ldx	#0
..rts1	iny	
	inx	
	lda	(inbuff),y
	sta	numbuf,x
	bpl	..rts1
	eor	#$80
	sta	numbuf,x
	stx	numbuf
	rts	
	endproc


;	DspOff()
;	--------
dspoff	proc
	lda	tvdisp
	sta	sdmctl
	sta	dmactl
	rts	
	endproc


;	DspOn()
;	-------
dspon	proc
	lda	#$22
	sta	sdmctl
	sta	dmactl
	lda	bckgrnd		; background color
	sta	color4		; restore background
	rts	
	endproc


;	PrintC(num)
;	-----------
printc	proc
	jsr	ctostr
pnum	lda	device
	ldx	#low numbuf
	ldy	#high numbuf
	jmp	output
	endproc


;	OpenChan(mode)
;	--------------
openchan proc
	pha	
	lda	chan
	jsr	close
	pla	
	sta	arg3
			; check for default device
	lda	#':'
	ldy	#2
	cmp	(nxtaddr),y
	beq	..oc2
	 iny	
	 cmp	(nxtaddr),y
	 beq	..oc2
			; stuff in D: for device
	clc	
	lda	nxtaddr
	adc	#2
	sta	fr0
	 lda	nxtaddr+1
	 adc	#0
	 sta	fr0+1

	ldy	#0
	lda	(nxtaddr),y	; add 2 to length of string
	adc	#2		;  so we can insert 'D:'
	sta	(nxtaddr),y
	tay	
..oc1	lda	(nxtaddr),y	; move string up...
	sta	(fr0),y
	dey	
	bne	..oc1
	iny	
	lda	#'D'
	sta	(nxtaddr),y
	 iny	
	 lda	#':'
	 sta	(nxtaddr),y

..oc2	lda	chan
	ldx	nxtaddr
	ldy	nxtaddr+1
	jsr	open
	bpl	printbuf
	 jmp	splerr		; oopps error in open
	endproc


;	PrintBuf()
;	----------
printbuf proc
	lda	list
	bne	htcr1		; return
	 jmp	wrtbuf
	endproc


;	HToCar(buf,index)
;	-----------------
htocar	proc
	sty	cix
	sta	arg1
	stx	arg2
	lda	#0
	sta	fr0
	sta	fr0+1

..htc1	ldy	cix
	lda	(arg1),y
	sec	
	sbc	#'0'
	bmi	htcrtn
	cmp	#10
	bmi	..htcok
	cmp	#17
	bmi	htcrtn
	sbc	#7
	cmp	#16
	bpl	htcrtn

..htcok	sta	arg5
	lda	fr0
	ldx	fr0+1
	ldy	#4
	jsr	lsh1
	clc	
	adc	arg5
	sta	fr0
	stx	fr0+1
	inc	cix
	bne	..htc1		; uncond.
	endproc


;	RToCar()
;	--------
rtocar	proc
	jsr	fpi
	bcs	..rcerr

htcrtn	lda	fr0
	ldx	fr0+1
	ldy	cix
htcr1	rts	

..rcerr	ldy	#conster
	jmp	splerr
	endproc


;	SToReal(str, index)
;	-------------------
storeal	proc
	sty	cix
	sta	inbuff
	stx	inbuff+1
	jmp	afp
	endproc


;	PutSp()
;	-------
putsp	proc
	ldy	#$20
	bne	putchar
	endproc


;	PutEOL()
;	--------
puteol	proc
	ldy	#eol
	endproc


;	PutChar(,,char)
;	---------------
putchar	proc
	lda	device
	jmp	scrchar
	endproc


;	PutStr(str, invert, offset)
;	---------------------------
putstr	proc	
	sta	arg6
	stx	arg7
	sty	arg2

	sec	
	adc	arg3
	sta	arg4
	bcc	..ps1
	 inx	
..ps1	stx	arg5

	jsr	dsploc
	jsr	zapcsr

	ldy	#39
	lda	arg2
..ps2	sta	(arg0),y	; clear line
	 dey	
	 bpl	..ps2

	clc			; handle left margin
	lda	arg0
	adc	lmargin
	sta	arg0
	bcc	..ps3
	 inc	arg1

..ps3	iny			; sets Y to 0
	clc	
	lda	(arg6),y
	sbc	arg3
	bcc	..ps10		; no chars

	sta	arg6
	tay	
	lda	#0
	sta	arg7

	sec	
	lda	rmargin
	sbc	lmargin
	cmp	arg6
	beq	..ps3a		; handle EOL char
	bcs	..ps4		; length ok

	sta	arg6
	ldy	arg6		; length too long
..ps3a	lda	#$80
	sta	arg7

..ps4	lda	arg2
	eor	(arg4),y
	pha	
	and	#$60
	tax	
	pla	
	and	#$9f
	ora	chcvt,x
	sta	(arg0),y
	dey	
	bpl	..ps4

	ldy	arg6
	lda	arg7
	bne	..ps6
	lda	arg2
	bne	..ps7		; no EOL char if inverted
	iny	
..ps5	lda	eolch
	sta	(arg0),y
	jmp	..ps7

..ps6	eor	(arg0),y
	sta	(arg0),y

..ps7	lda	arg3
	beq	..ps9
..ps8	ldy	#0
	lda	(arg0),y
	eor	#$80
	sta	(arg0),y
..ps9	rts	

..ps10	lda	arg3
	bne	..ps8
	tay	
	beq	..ps5		; uncond.
	endproc


;	CmdCol()
;	--------
cmdcol	proc
	jsr	savecol
	jsr	rstcsr
	ldy	cmdln
	sty	rowcrs
	rts	
	endproc


;	SaveCol()
;	---------
savecol	proc
	lda	rowcrs
	sta	y
	lda	colcrs
	sta	x
	rts	
	endproc


;	RstCol()
;	--------
rstcol	proc
	lda	y
	sta	rowcrs
	lda	x
	sta	colcrs
	jsr	zapcsr
lftrt	jsr	scrlft
	jmp	scrrt
	endproc


;	ChkCur()
;	--------
chkcur	proc
	lda	cur+1
	bne	..ccret
ldtop	lda	top
	sta	cur
	lda	top+1
	sta	cur+1
..ccret	rts	
	endproc


;	LdBuf() load buf
;	----------------
ldbuf	proc
	jsr	chkcur
	bne	..ldb0
	 tay	
	 sta	(buf),y
	 rts	
..ldb0	jsr	curstr

ldbuf1	ldy	#0
	lda	(arg0),y
	sta	(buf),y
	tay	

..ldb1	lda	(arg0),y
	sta	(buf),y
	dey	
	bne	..ldb1
	rts	
	endproc


;	DspBuf() - display buffer
;	-------------------------
dspbuf	proc
	clc	
	lda	indent
	adc	choff
	sta	arg3
	ldy	#0
	lda	buf
	ldx	buf+1
	jmp	putstr
	endproc



;	DspLoc() get address of display
;	-------------------------------
dsploc	proc	
	lda	savmsc
	ldx	savmsc+1
	ldy	rowcrs
	beq	..dlocrt
..dloc1	clc	
	adc	#40
	bcc	..dloc2
	 inx	
..dloc2	dey	
	bne	..dloc1

..dlocrt sta	arg0
	stx	arg1
	rts	
	endproc


;	ZapCsr() get rid of old cursor
;	------------------------------
zapcsr	proc	
	lda	#low csrch
	sta	oldadr
	lda	#high csrch
	sta	oldadr+1
	rts	
	endproc


;	RstCsr() restore char under Csr
;	-------------------------------
rstcsr	proc	
	ldy	#0
	lda	oldchr
	sta	(oldadr),y
	rts	
	endproc

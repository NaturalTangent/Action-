; TITLE "STORAGE.MAC"

; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; Last modified June 17, 1983
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


slop	equ	7		; can't be less than 4

allocate	proc		; Allocate(size)
	sta	afsize		; save size
	stx	afsize+1
	lda	#$ff		; set best size
	sta	afbsze
	sta	afbsze+1
	lda	#low afbase	; last = base
	sta	aflast
	lda	#high afbase
	sta	aflast+1
..afl1	ldy	#0
	lda	(aflast),y	; cur = last(0)
	sta	afcur
	bne	..afl2		; while cur # 0
	iny	
	lda	(aflast),y
	sta	afcur+1
	bne	..afl3
	beq	..afl6		; done
..afl2	iny	
	lda	(aflast),y
	sta	afcur+1
..afl3	ldy	#3
	lda	(afcur),y	; get size
	cmp	afsize+1	; high bytes
	bcc	..afl5		; size too small
	bne	..afl4		; size too big
	dey	
	lda	(afcur),y
	cmp	afsize		; low bytes
	bcc	..afl5		; size too small
	beq	..afl9		; sizes equal

; Check for best fit

..afl4	ldy	#2
	lda	(afcur),y
	cmp	afbsze
	iny	
	lda	(afcur),y
	sbc	afbsze+1
	bcs	..afl5

; save best guess so far

	lda	(afcur),y
	sta	afbsze+1
	dey	
	lda	(afcur),y
	sta	afbsze
	lda	aflast
	sta	afbest
	lda	aflast+1
	sta	afbest+1

; get next entry in list and goto
; beginning of loop

..afl5	lda	afcur
	sta	aflast
	lda	afcur+1
	sta	aflast+1
	clc	
	bcc	..afl1

; no entry found, use best guess

..afl6	lda	afbsze+1
	cmp	#$ff
	beq	..afl10		; no free block

; see if we need to split block

	sec	
	lda	afbsze
	sbc	#slop
	sta	afbsze
	bcs	..afl7
	dec	afbsze+1
..afl7	lda	afbsze+1
	cmp	afsize+1
	bcc	..afl8		; use as is
	bne	..afl11		; split it
	lda	afbsze
	cmp	afsize
	bcs	..afl11		; split it

; don't split

..afl8	ldy	#0
	lda	(afbest),y	; cur =  best(0)
	sta	afcur
	iny	
	lda	(afbest),y
	sta	afcur+1

	lda	(afcur),y	; best(0) = cur(0)
	sta	(afbest),y
	dey	
	lda	(afcur),y
	sta	(afbest),y
	rts	

; found entry of right size

..afl9	ldy	#0
	lda	(afcur),y
	sta	(aflast),y
	iny	
	lda	(afcur),y
	sta	(aflast),y
..afl10	rts	

; split best block

..afl11	ldy	#0
	lda	(afbest),y	; cur = best(0)
	sta	afcur
	clc	
	adc	afsize
	sta	(afbest),y	; best(0)=cur+size
	sta	aflast		; last = cur + size
	iny	
	lda	(afbest),y
	sta	afcur+1
	adc	afsize+1
	sta	(afbest),y
	sta	aflast+1

	iny	
	sec	
	lda	(afcur),y
	sbc	afsize		; last(1) = bsze-size
	sta	(aflast),y
	lda	afsize
	sta	(afcur),y	; cur(1) = size
	iny	
	lda	(afcur),y
	sbc	afsize+1
	sta	(aflast),y
	lda	afsize+1
	sta	(afcur),y
	clc	
	bcc	..afl9


free	proc			; Free(block)
	sta	afbest
	stx	afbest+1

free1	lda	#low afbase	; cur = base
	sta	afcur
	lda	#high afbase
	sta	afcur+1

..afl12	lda	afcur		; last = cur
	sta	aflast
	lda	afcur+1
	sta	aflast+1

	ldy	#0
	lda	(aflast),y	; cur = last(0)
	sta	afcur
	cmp	afbest
	iny	
	lda	(aflast),y
	sta	afcur+1
	sbc	afbest+1
	bcs	..afl13		; while cur ULS block
	lda	afcur+1		; and cur # 0
	bne	..afl12
	lda	afcur
	bne	..afl12

..afl13	iny	
	clc	
	lda	(afbest),y
	adc	afbest
	tax	
	iny	
	lda	(afbest),y
	and	#$7f		; clear tag flag
	sta	(afbest),y
	adc	afbest+1
	cmp	afcur+1
	bne	..afl15
	cpx	afcur		; if cur =
	bne	..afl15		;  (block + block(1))
	dey	
	clc			; block(1) =
	lda	(afbest),y	;  block(1) +  cur(1)
	adc	(afcur),y
	sta	(afbest),y
	iny	
	lda	(afbest),y
	adc	(afcur),y
	sta	(afbest),y
	ldy	#0		; block(0) = cur(0)
	lda	(afcur),y
	sta	(afbest),y
	iny	
	lda	(afcur),y
	sta	(afbest),y
	clc	
	bcc	..afl16

;:AFL14 PLP
..afl15	ldy	#0		; block(0) = cur
	lda	afcur
	sta	(afbest),y
	iny	
	lda	afcur+1
	sta	(afbest),y

..afl16	iny			; if block =
	clc			; (last + last(1))
	lda	aflast
	adc	(aflast),y
	tax	
	iny	
	lda	aflast+1
	adc	(aflast),y
	cmp	afbest+1
	bne	..afl18
	cpx	afbest
	bne	..afl18

	clc			; last(1) =
	dey			;   last(1)+block(1)
	lda	(aflast),y
	adc	(afbest),y
	sta	(aflast),y
	iny	
	lda	(aflast),y
	adc	(afbest),y
	sta	(aflast),y

	ldy	#0		; last(0) = block(0)
	lda	(afbest),y
	sta	(aflast),y
	iny	
	lda	(afbest),y
	sta	(aflast),y
	rts	

;:AFL17 PLP
..afl18	ldy	#0		; last(0) = block
	lda	afbest
	sta	(aflast),y
	iny	
	lda	afbest+1
	sta	(aflast),y
	rts	


;         EDIT.MEM

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified March 9, 1983



getmem	proc			; GetMem(size)
	clc	
	adc	#4
	sta	afsize
	bcc	..gm0
	inx	
..gm0	stx	afsize+1
..gm1	jsr	allocate+4

	ldx	afcur+1
	beq	gmerr		; no memory allocated !
	clc	
	lda	afcur
	adc	#4
	bcc	..gm2
	inx	

..gm2	rts	

gmerr	ldy	#0
	jsr	syserr

	lda	sparem
	ldx	sparem+1
	ldy	allocerr
	bne	punt		; really out of memory
	inc	allocerr
	jsr	free
	jmp	..gm1		; retry

punt	jsr	savewd		; we're in big trouble
	jmp	rstwnd


freemem	proc			; FreeMem(addr)
	sec	
	sbc	#4
	bcs	freem1
	dex	
freem1	jmp	free


instb	proc			; InstB()
	lda	cur
	sta	arg3
	lda	cur+1
	sta	arg4
	jsr	instbuf
	sta	cur
	stx	cur+1
	rts	


instbuf	proc			; InstBuf(,,up)
	ldy	#0
	lda	(buf),y
	ldx	buf
	ldy	buf+1


instln	proc			; InstLn(sze,sloc,up)
	sta	arg0		; save sze
	stx	arg1		; save sloc
	sty	arg2
	clc	
	adc	#3
	ldx	#0
	jsr	getmem

	clc	
	adc	#2
	sta	arg5
	txa	
	adc	#0
	sta	arg6
	ldy	arg0
	beq	..il1a
..il1	lda	(arg1),y
	sta	(arg5),y
	dey	
	bne	..il1
..il1a	lda	arg0
	sta	(arg5),y

	lda	arg4
	bne	..il4		; up # 0

	lda	top		; down ..= top
	sta	arg5
	ldy	#4		; AFcur(2) ..= down
	sta	(afcur),y
	lda	top+1
	sta	arg6
	iny	
	sta	(afcur),y

	lda	afcur		; top ..= AFcur
	sta	top
	lda	afcur+1
	sta	top+1

	ldy	#0		; AFcur(0) ..= 0
	tya	
	sta	(afcur),y
	iny	
	sta	(afcur),y

..il2	lda	arg6
	bne	..il3		; down # 0
	lda	afcur		; bot ..= AFcur
	sta	bot
	ldx	afcur+1
	stx	bot+1
	rts	

..il3	ldy	#1
	lda	afcur+1		; @down ..= AFcur
	sta	(arg5),y
	dey	
	lda	afcur
	sta	(arg5),y
	ldx	afcur+1
	rts	

..il4	ldy	#4
	lda	(arg3),y
	sta	arg5		; down ..= Next(up)
	sta	(afcur),y	; AFcur(2) ..= down
	lda	afcur
	sta	(arg3),y	; up(2) ..= AFcur
	iny	
	lda	(arg3),y
	sta	arg6
	sta	(afcur),y
	lda	afcur+1
	sta	(arg3),y

	ldy	#0
	lda	arg3
	sta	(afcur),y
	iny	
	lda	arg4
	sta	(afcur),y

	jmp	..il2


delcur	proc			; DelCur()
	lda	cur
	ldx	cur+1
	jsr	delln
	sta	cur
	stx	cur+1
dln1	rts	


delln	proc			; DelLn(lineptr)
	cpx	#0
	beq	dln1
	sta	arg0
	stx	arg1
	ldy	#4
	lda	(arg0),y
	sta	arg4		; down ..= Next(ptr)
	iny	
	lda	(arg0),y
	sta	arg5

	ldy	#0
	lda	(arg0),y
	sta	arg2		; up ..= Prev(ptr)
	iny	
	lda	(arg0),y
	sta	arg3

	bne	..dln2		; up # 0
	lda	arg4
	sta	top		; top ..= down
	lda	arg5
	sta	top+1
	jmp	..dln3

..dln2	ldy	#4
	lda	arg4
	sta	(arg2),y	; up(2) ..= down
	iny	
	lda	arg5
	sta	(arg2),y

..dln3	lda	arg5
	bne	..dln4		; down # 0
	lda	arg2
	sta	bot		; bot ..= up
	lda	arg3
	sta	bot+1
	jmp	..dln5

..dln4	ldy	#0
	lda	arg2
	sta	(arg4),y	; down(0) ..= up
	iny	
	lda	arg3
	sta	(arg4),y

..dln5	lda	arg0
	ldx	arg1
	jsr	free

	lda	arg2
	ldx	arg3
	rts	


;         EDIT.CAR

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified July 29, 1983


emjmps	rts			; Seg catch all
	dw	0
	db	ebank		; curBank
	db	$df		; stMask
	jmp	splerr		; Error
	db	18		; wSize
	db	120		; line input max
	db	$20		; ChCvt2
	rts			; Exp catch all
	dw	0
	rts			; Dcl catch all
	dw	0
	rts			; CodeGen catch all
	dw	0
	rts			; ArrRef Catch all
zero	dw	0
	rts			; SPLEnd
	dw	0
	jmp	scrbell		; Alarm
	db	0		; EOLch (default = space)
ltab	dw	lshift		; LSH
	dw	rshift
	dw	multi
	dw	divi
	dw	remi
	dw	sargs
	db	$60		; ChCvt3
	db	$22		; tvDisp
	jmp	insrtch		; normal char
	rts			; ctrl-shift char
serial	dw	0		; serial number of ROM
; to be filled in before blowing ROM
	jmp	ismt		; STM catch all
	rts			; illegal monitor cmd
	db	$86
	db	$9d
	dw	istmres		; STMrAdr in EDIT.DEF

;Init RTS

start	jsr	initkeys	; get keyboard
	lda	warmst
	beq	cold
	lda	chcvt3
	cmp	#$60		; make sure RAM initialized
	bne	cold

..warm	lda	mpc		; see where we were
	beq	..w1
	jmp	mon1		; monitor
..w1	jmp	punt		; editor

cold	lda	#0
	tay	
..c0	sta	$0480,y		; zero RAM
	dey	
	bne	..c0

	ldy	#$3a
..cold1	lda	emjmps-1,y	; init RAM
	dey	
	sta	jmps,y
	bne	..cold1
; STY ChCvt1 ; Y=0

	jsr	einit		; init editor

;SPLInit PROC ; init compiler RAM
	$if	ramzap
	jsr	zap4
	$else	
	nop	
	nop	
	nop	
	$endif	
	ldx	#8		; 2K id space
	stx	stsp

	lda	#0
	ldx	#4
	ldy	bigst		; big s.t. ?
	beq	..si1		; no
	ldx	#6
..si1	jsr	getmem		; get hash table
	sta	stglobal	; qglobal hash table
	stx	stglobal+1
	ldy	bigst		; big s.t. ?
	beq	..si2		; no
	inx	
	inx	
	sta	stg2		; big s.t. hash table
	stx	stg2+1
..si2	inx	
	inx	
	sta	stlocal		; local hash table
	stx	stlocal+1

; RTS


;         EDIT.MAN

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified July 27, 1983



floop	proc	
; Main program for EDIT/FLASH
	lda	allocerr
	beq	..fm1
	lda	#low outmem
	ldx	#high outmem
	jsr	cmdmsg

..fm1	lda	curch
	sta	lastch
	jsr	getkey

	jsr	fcmsg1
	lda	curch

	ldy	kbcode
	cpy	#$c0		; Ctrl-Shft
	bcs	..fmcs

	ldy	lastch
	cpy	#$1b		; escape
	bne	..fmch
	cmp	#eol
	beq	floop
	jsr	insrtch
	jmp	floop

..fmcs	ldx	#low fmcscmd
	ldy	#high fmcscmd
	bne	..fmlu

..fmch	ldx	#low fmcmd
	ldy	#high fmcmd

..fmlu	jsr	lookup
	jmp	floop

fmcmd	dw	disptb		; default routine
	db	50		; table size
	dw	scrlup
	db	$1c
	dw	scrldwn
	db	$1d
	dw	scrlrt
	db	$1f
	dw	scrllft
zap2	db	$1e
	dw	delch
zap3	db	$fe
	dw	backsp
zap4	db	$7e
	dw	insrtch
	db	$60
	dw	insrtsp
	db	$ff
	dw	return
	db	eol
	dw	tab
	db	$7f
	dw	delete
	db	$9c
	dw	escape
	db	$1b
	dw	clear
	db	$7d
	dw	insrt
	db	$9d
	dw	settab
	db	$9f
	dw	clrtab
	db	$9e


fmcscmd	dw	disptb+3	; default
	db	71		; table size
	dw	front
	db	$f6
	dw	back
	db	$f7
	dw	pgup
	db	$ce
	dw	pgdwn
	db	$cf
	dw	indntl
	db	$e0
	dw	indntr
	db	$e2
	dw	fread
	db	$e8
	dw	fwrite
	db	$ee
	dw	paste
	db	$ca
	dw	insrtt
	db	$cd
	dw	monitor
	db	$e5
	dw	find
	db	$f8
	dw	subst
	db	$fe
	dw	wind1
	db	$df
	dw	wind2
	db	$de
	dw	delwd
	db	$fa
	dw	csbs
	db	$f4
	dw	csret
	db	$cc
	dw	undo
	db	$cb
	dw	topln
	db	$f9
	dw	endln
	db	$ea
	dw	settag
	db	$ed
	dw	loctag
	db	$fd


outmem	db	14," "
	db	+$80,"Out"
	db	" "
	db	+$80,"of"
	db	" "
	db	+$80,"Memory"


;         EDIT.CHR

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified September 8, 1983



insrtch	proc	
; InsrtCh() char in curCh
	jsr	setsp
..padbuf	ldy	#0
	lda	(buf),y
	cmp	linemax
	bcc	..pbuf0		; test line too long
	jsr	scrbell
	ldy	#0
	lda	(buf),y
..pbuf0	cmp	sp
	bcs	..pbuf2
	sta	arg0
	lda	sp
	sta	(buf),y
	ldy	arg0
	lda	#$20		; pad with spaces
..pbuf1	iny	
	sta	(buf),y
	cpy	sp
	bcc	..pbuf1
..pbret	ldy	sp
	lda	curch
	sta	(buf),y
	lda	#$ff
	sta	dirtyf
	jsr	dspbuf
	jmp	scrlrt

..pbuf2	ldx	insert
	beq	..pbret
; move buf right one char
..movert	adc	#0	; really 1, carry set
	sta	(buf),y
	tay	
..mrt1	dey	
	lda	(buf),y
	iny	
	sta	(buf),y
	dey	
	cpy	sp
	bne	..mrt1
	beq	..pbret


insrtsp	proc			; InsrtSp()
	lda	insert
	pha	
	lda	#$20
	sta	insert
	sta	curch
	jsr	insrtch
	pla	
	sta	insert
	jmp	scrlft


insrt	proc			; Insrt()
	jsr	clnln
	jsr	nextup
	sta	cur+1		; tricky
	jsr	insert2
	lda	#0
	jmp	npage1

insert2	lda	#0
	tay	
insert3	sta	(buf),y
	iny	
	sty	dirty
	jmp	instb


csret	proc	
; handle pad if any
	jsr	insrtsp
	jsr	delch

	ldy	#0
	lda	(buf),y
	pha	
	jsr	setsp
	sta	dirtyf		; always non-zero
	sec	
	sbc	#1
	sta	(buf),y
	jsr	clnln

	pla	
	sta	arg1
	inc	arg1
	lda	#0
	sta	arg0
	beq	..csr2
..csr1	lda	(buf),y
	inc	arg0
	ldy	arg0
	sta	(buf),y
	inc	sp
..csr2	ldy	sp
	cpy	arg1
	bcc	..csr1

	ldy	#0
	lda	arg0
	jsr	insert3
	jsr	nextup
	jsr	refresh
	jmp	ret2


return	proc			; Return()
	ldx	insert
	bne	csret
	jsr	chkdwn
	bne	ret2
..ret1	jsr	insert2
	jsr	nextup
	jsr	ldbuf
ret2	jsr	scrldwn
ret3	jmp	front


delete	proc			; Delete()
	jsr	clnln
	lda	delbuf
	ldx	delbuf+1
	stx	dirty
	ldy	lastch
	cpy	#$9c
	beq	..del1
	jsr	delfree
..del1	sta	arg3
	stx	arg4
	jsr	instbuf
	jsr	chkdwn		; last line ?
	bne	..del2		; no, delete it
	tay	
	sta	(buf),y
	iny	
	sty	dirtyf
	bne	ret3		; uncond.

..del2	jsr	delcur
	beq	..del3
	jsr	nextdwn
..del3	jsr	chkcur
	lda	#0
	jmp	npage1


deltop	proc			; DelTop()
	lda	delbuf+4
	ldx	delbuf+5
	sta	delnxt
	stx	delnxt+1


delend	proc			; DelEnd(ptr)
	cmp	#low delbuf
	bne	de1
	cpx	#high delbuf
de1	rts	


delfree	proc			; DelFree(bot)
	jsr	delend
	beq	de1
	jsr	delln
	bne	delfree		; uncond.


delnext	proc			; DelNext()
	ldy	#5
	lda	(delnxt),y
	tax	
	dey	
	lda	(delnxt),y
	sta	delnxt
	stx	delnxt+1
	jmp	delend


undo	proc	
	jsr	ldbuf
	jmp	front


delch	proc			; DeleteCh()
	jsr	chkcol
	bcc	cdwn1
	ldy	#0
	lda	(buf),y
	sta	dirtyf
	sec	
	sbc	#1
	sta	(buf),y
	ldy	sp
..dch1	iny	
	lda	(buf),y
	dey	
	sta	(buf),y
	iny	
	cpy	dirtyf
	bcc	..dch1		; really checking for =


rfrshbuf	proc		; RfrshBuf()
	jsr	dspbuf
	jmp	lftrt


chkdwn	proc			; ChkDwn()
	jsr	clnln
	beq	cdwn1
	ldy	#5
	lda	(cur),y
cdwn1	rts	


backsp	proc			; BackSp()
	jsr	setsp
	cmp	#2
	bcc	cdwn1
bsp1	jsr	scrllft
	jsr	setsp
	tay	
	lda	#$20
	sta	(buf),y
	sta	dirtyf
	lda	insert
	bne	delch
	jmp	rfrshbuf


csbs	proc	
	jsr	setsp
	cmp	#2
	bcs	bsp1
	jsr	chkcur
	beq	cdwn1		; no lines at all!
	ldy	#1
	lda	(cur),y
	beq	cdwn1		; no line to merge with
; merge
	jsr	scrlup
	jsr	back
	jsr	nextdwn
	sta	dirtyf
	jsr	curstr
	clc	
	ldy	#0
	lda	(buf),y
	sta	arg2
	adc	(arg0),y
	sta	(buf),y
	lda	(arg0),y
	beq	..cb2
	sta	arg3
..cb1	iny	
	sty	arg4
	lda	(arg0),y
	inc	arg2
	ldy	arg2
	sta	(buf),y
	ldy	arg4
	cpy	arg3
	bne	..cb1
..cb2	jsr	delcur
	jmp	refresh


;         EDIT.INI

; Copyright 1983 by Action Computer Services
; All rights reserved.

; last modified May 19, 1983


minit	proc			; initialize memory
	lda	memlo
	sta	afbase
	lda	memlo+1
	sta	afbase+1
	lda	#0
	tay	
	sta	(afbase),y
	iny	
	sta	(afbase),y
	sec	
	lda	memtop
	sbc	afbase
	iny	
	sta	(afbase),y
	lda	memtop+1
	sbc	afbase+1
	iny	
	sta	(afbase),y

	lda	#0		; allocate 2 pages of
	ldx	#2		; spare memory
	jsr	allocate
	lda	afcur
	sta	sparem
	ldx	afcur+1
	stx	sparem+1
miret	rts	


zerow	proc			; initialize window
	lda	#0
	ldx	#15
..zw1	dex			; zero page0 window table
	sta	sp,x
	bne	..zw1
	sta	dirtyf
	sta	inbuf
	tay	
	sta	(buf),y
	rts	


w2init	proc			; W2Init()
	jsr	ctrln
	lda	wsize
	sta	nlines
	sta	cmdln
	jsr	savworld
	lda	#w2-w1
	sta	numwd
	sta	curwdw
	jsr	zerow
	ldy	wsize
	iny	
	sty	ytop
	sec	
	lda	#23
	sbc	wsize
	sta	nlines
	bne	fcmsg		; uncond.


einit	proc	
	jsr	minit

	lda	#0
	ldx	#1
	jsr	allocate	; get edit buffer
	lda	afcur
	sta	buf
	ldx	afcur+1
	stx	buf+1

	lda	#$40
	sta	chcvt

	lda	#low delbuf
	sta	delbuf
	sta	delbuf+4
	lda	#high delbuf
	sta	delbuf+1
	sta	delbuf+5

winit	jsr	zerow

winit1	lda	#23
	sta	nlines
	sta	cmdln
	lda	#0
	sta	curwdw
	sta	ytop

fcmsg	jsr	ctrln
fcmsg1	lda	#low editc
	ldx	#high editc
	jmp	cmdmsg

editc	db	19,"ACTION! (c)1983 ACS"


;         EDIT.IO

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified July 29, 1983



getstr	proc	
; GetStr(prompt, str, invert)
	jsr	dspstr
..gs1	jsr	getkey
	tax	

	cpx	#$7e
	beq	..gs3		; backspace

	cpx	#$7d
	beq	..gs3		; clear

..gs1a	ldy	#0
	clc	
	lda	(arg12),y
	adc	#1

	cpx	#$1b		; ESC
	beq	..gs1b

	cpx	#eol
	beq	..gs2

	cpy	arg3		; first char?
	beq	..gs3		; yes, clear line

	stx	arg3
	ldx	colcrs
	cpx	rmargin
	bcs	..gs1		; don't go off screen

	sta	(arg12),y
	tay	
	lda	arg3
	sta	(arg12),y
	eor	arg2
	jsr	scrch
	jmp	..gs1

..gs1b	lda	#0
	sta	curch
	sta	(arg12),y
	iny	
	tya	
..gs2	tay	
	txa			; EOL
	sta	(arg12),y
	rts	

..gs3	stx	arg3
..gs4	ldy	#0
	lda	(arg12),y
	beq	..gs5
	sec	
	sbc	#1
	sta	(arg12),y

	jsr	scrlft

	lda	#$20
	eor	arg2
	jsr	scrch

	jsr	scrlft
	ldx	arg3
	cpx	#$7e
	bne	..gs4
	beq	..gs1

..gs5	cpx	#$7d
	beq	..gs1
	bne	..gs1a


fread	proc			; FRead()
	lda	#0
	sta	inbuf
	lda	#low rdmsg
	ldx	#high rdmsg
	ldy	#4
	jsr	fopen

..frd1	lda	#1
	jsr	rdbuf
	bmi	..fr3
	jsr	instb
	lda	allocerr
	beq	..frd1
	ldy	#22		; file to big
	bne	..fr4

..fr3	cpy	#$88		; EOF
	beq	..fr5
..fr4	jsr	syserr
..fr5	jsr	fw2
	jmp	ctrln

rdmsg	db	6,"Read? "


fwrite	proc			; FWrite()
	lda	#low wrtmsg
	ldx	#high wrtmsg
	ldy	#8
	jsr	fopen

	jsr	ldtop
	beq	..fw3
..fw1	jsr	ldbuf

; INC COLOR4 ; let user know we're here
	nop	
	nop	
	nop	

	lda	#1
	jsr	wrtbuf
	bmi	..fw3
	jsr	nextdwn
	bne	..fw1

	lda	#0
	sta	dirty
fw2	lda	#1
	jsr	close
	jsr	rstcur
	jmp	dspon

..fw3	jsr	syserr
	jmp	fw2

wrtmsg	db	7,"Write? "


fopen	proc			; FOpen(prompt, mode)
	sta	arg10
	stx	arg11
	sty	opmode

; JSR ClnLn ; in SaveWd
	jsr	savewd
	jsr	rstcsr

	ldy	#low inbuf
	lda	#high inbuf
	sta	arg3
	lda	arg10
	ldx	arg11
	jsr	cmdstr

	lda	#1
	jsr	close
	ldy	inbuf
	beq	..fo7
	ldx	opmode
	lda	#':
	cmp	inbuf+2
	beq	..fo2
	cmp	inbuf+3
	beq	..fo2
	iny	
	iny	
	sty	inbuf
..fo1	lda	inbuf,y
	sta	inbuf+2,y
	dey	
	bne	..fo1
	lda	#':
	sta	inbuf+2
	bne	..fo3		; uncond.

..fo2	lda	inbuf+1
	cmp	#'?		; read directory?
	bne	..fo4		; no
	ldx	#6
..fo3	lda	#'D
	sta	inbuf+1

..fo4	stx	arg3
	jsr	dspoff
	lda	#1
	sta	arg4		; clear high bit for cassette
	ldx	#low inbuf
	ldy	#high inbuf
	jsr	open
	bmi	..fo6
	lda	arg3		; see if directory
	eor	#6
	bne	..fo5
	sta	inbuf		; clear inbuf
..fo5	rts	

..fo6	pla	
	pla			; pop return
	jmp	syserr

..fo7	pla	
	pla	
	rts	

initkeys	proc	
	lda	#7
	jsr	close

	lda	#4
	sta	arg3		; read only
	lda	#7
	ldx	#low keybd
	ldy	#high keybd
	jmp	open

keybd	db	2,"K:"


gotkey	proc	
; Test if key in buffer
	lda	ch		; key down?
	eor	#$ff
	rts	


;         EDIT.WND

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified July 6, 1983




wind1	proc			; Wind1()
	lda	curwdw
	beq	wdret
	lda	#0
	pha	


swapwd	proc			; SwapWd()
	jsr	savworld
	pla	
	jmp	rstworld


wind2	proc			; Wind2()
	lda	curwdw
	bne	wdret
	lda	numwd
	bne	..w2
	jmp	w2init

..w2	lda	#w2-w1
	pha	
	bne	swapwd		; uncond.


savworld	proc		; SavWorld()
	jsr	clnln
	jsr	savecol
	jsr	rstcsr
	jsr	setsp
	jmp	savewd


wdret	rts	


clear	proc			; Clear()
	jsr	alarm
	lda	#low clearmsg
	ldx	#high clearmsg
	jsr	yesno
	bne	wdret
clr0	jsr	clnln
	lda	dirty
	beq	clr1
; JSR Alarm
	lda	#low dirtymsg
	ldx	#high dirtymsg
	jsr	yesno
	bne	wdret
clr1	jsr	freetags	; get rid of tags
	lda	bot
	ldx	bot+1
..clr2	jsr	delln
	bne	..clr2
	stx	cur+1
	stx	dirty
	stx	dirtyf
	stx	inbuf
	jmp	newpage


rstworld	proc		; RstWorld(window)
	sta	curwdw
	jsr	rstwd
	jsr	ldbuf
	jmp	rstcol


delwd	proc			; DelWd()
	lda	numwd
	beq	wdret
	jsr	alarm
	lda	#low delmsg
	ldx	#high delmsg
	jsr	yesno
	bne	wdret
..dw1	jsr	clr0
	lda	dirty
	bne	wdret
	ldy	#0
	sty	numwd
	cpy	curwdw
	bne	delwd2
	ldy	#w2-w1
delwd2	sty	curwdw
	jsr	rstwd
	jmp	winit1


clearmsg
	db	7,"CLEAR? "
delmsg	db	15,"Delete window? "
dirtymsg
	db	19,"Not saved, Delete? "


gettemp	proc			; GetTemp(msg)
	ldy	#0
gett1	sty	tempbuf
	ldy	#high tempbuf
	sty	arg3
	ldy	#low tempbuf


cmdstr	proc			; CmdStr(msg, buf)
	sta	arg0
	sty	arg2
	jsr	cmdcol
	lda	#$80
	sta	arg4
	lda	arg0
	ldy	arg2
	jsr	getstr
	jsr	rstcsr
	jmp	rstcol


yesno	proc			; YesNo(msg)
	jsr	gettemp
	ldy	tempbuf
	bne	..yn1
	iny	
	rts	

..yn1	lda	tempbuf+1
	ora	#$20
	cmp	#'y
	rts	


;         EDIT.DSP

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified July 29, 1983

	proc	

cmdmsg	proc			; CmdMsg(msg)
	sta	arg0
	jsr	cmdcol
	lda	#0
	sta	arg3
	lda	arg0
	ldy	#$80
	jsr	putstr
	jmp	rstcol


clnln	proc			; ClnLn()
	jsr	chkcur
	lda	dirtyf
	beq	..cll1
	sta	dirty
	lda	#0
	sta	dirtyf
	jsr	delcur
	jsr	instb
..cll1	jmp	chkcur


savewd	proc			; SaveWd()
	jsr	clnln
savwd1	clc	
	lda	#14
	tax	
	adc	curwdw
	tay	
..sw1	lda	sp,x
	sta	w1,y
	dey	
	dex	
	bpl	..sw1
	rts	


rstwd	proc			; RstWd() restore window
	clc	
	lda	#14
	tax	
	adc	curwdw
	tay	
..rw1	lda	w1,y
	sta	sp,x
	dey	
	dex	
	bpl	..rw1
rw2	rts	


endln	proc	
	jsr	clnln
	lda	bot
	sta	cur
	lda	bot+1
	sta	cur+1
; falls into CtrLn


ctrln	proc			; CtrLn() center line
	lda	#0
	sta	temps
	jsr	clnln
	beq	..cl0
	jsr	nextup
	beq	..cl0
	inc	temps
	jsr	nextup
	beq	..cl0
	inc	temps
..cl0	jsr	newpage
..cl1	lda	temps
	beq	rw2
	jsr	scrldwn
	dec	temps
	jmp	..cl1


topln	proc			; TopLn()
	jsr	clnln
	jsr	ldtop
; falls into NewPage


newpage	proc			; NewPage()
	lda	#0
	sta	lnum
npage1	sta	choff
	jsr	rstcsr		; for command line
	lda	lmargin
	sta	colcrs
; JMP Refresh ; do all the work

	proc	

refresh	proc			; Refresh()
	clc	
	lda	ytop
	adc	lnum
	sta	rowcrs
	jsr	savecol
	jsr	savewd
	inc	rowcrs
	jsr	nextdwn
	sta	arg9
	clc	
	lda	nlines
	sbc	lnum
	sta	arg10
	beq	..cl4

..cl1	ldy	#0
	lda	indent
	sta	arg3
	ldx	arg9
	beq	..cl5
	jsr	curstr

..cl2	jsr	putstr
	lda	arg9
	bne	..cl3
	tay	
	sta	(arg0),y
..cl3	inc	rowcrs
	jsr	nextdwn
	sta	arg9
	dec	arg10
	bne	..cl1

..cl4	jsr	rstcur
	jsr	rstcol
	jmp	rfrshbuf

..cl5	lda	#low zero
	ldx	#high zero
	bne	..cl2		; uncond.


;         EDIT.CMD

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified March 10, 1983

	proc	


front	proc			; Front()
	sec	
	lda	#0
	sbc	indent
	sta	choff
	jsr	dspbuf
	lda	lmargin
	jmp	rstcol+6


back	proc			; Back()
	ldy	#0
	lda	(buf),y
back0	pha	
	clc	
	adc	lmargin
	sec	
	sbc	rmargin
	bcs	..back1
	lda	#1
..back1	sbc	indent
	sta	choff
	jsr	dspbuf
	sec	
	pla	
	sbc	indent
	sec	
	sbc	choff
	clc	
	adc	lmargin
	jmp	rstcol+6


pgup	proc			; PgUp()
	sec	
	lda	lnum
	sbc	#2
	ldy	#1
	bne	page


pgdwn	proc			; PgDwn()
	ldy	#5
	sec	
	lda	#2
	sbc	lnum


page	proc	
	clc	
	adc	nlines
	sta	arg14
	dec	arg14
	beq	..page2
	sty	arg13
	jsr	clnln
..page1	ldy	arg13
	jsr	next
	dec	arg14
	bne	..page1
..page2	jmp	ctrln


paste	proc			; Paste()
	jsr	deltop
	beq	..pret
	stx	dirty
	jsr	clnln
	jsr	nextup
	sta	cur+1		; tricky, fake out top
	jsr	savwd1

	jsr	deltop
..p1	jsr	strptr
	jsr	ldbuf1
	jsr	instb
	lda	allocerr
	bne	..p2		; check for out of memory
	jsr	delnext
	bne	..p1

..p2	jsr	rstcur
	ldy	curwdw
	lda	w1+wcur+1,y
	beq	..p3
	jsr	nextdwn
..p3	lda	#0
	jmp	npage1

..pret	rts	


indntl	proc			; old IndentL()
	lda	indent
	beq	putrtn
	dec	indent
	jmp	ctrln


indntr	proc			; old IndentR()
	lda	indent
	bmi	putrtn
	inc	indent
	jmp	ctrln


insrtt	proc			; was InsertT
; InsrtT() insert/replace toggle
	lda	#low ..rmsg
	ldx	#high ..rmsg
	inc	insert
	beq	..it1
	lda	#$ff
	sta	insert
	lda	#low ..imsg
	ldx	#high ..imsg
..it1	jmp	cmdmsg

..imsg	db	6,"INSERT"
..rmsg	db	7,"REPLACE"


scrlinit	proc	
	sty	arg13
	jsr	clnln
	beq	..siret

	ldy	arg13
	jsr	next
	beq	..siret		; EOF

	lda	colcrs
	sta	x
; LDA choff
; BEQ ..SI1
	lda	#0
	sta	choff
	jsr	dspbuf
..si1	jmp	ldbuf

..siret	pla	
	pla	
putrtn	rts	


scrlup	proc			; ScrlUp()
	ldy	#1
	jsr	scrlinit
	dec	lnum
	bmi	..su2
	jmp	scrup

..su2	inc	lnum
	lda	ytop
	sta	y
	jsr	botln
	lda	nlines
	jsr	movedwn
	jsr	rstcol
	jmp	rfrshbuf


scrldwn	proc			; ScrlDwn()
	ldy	#5
	jsr	scrlinit
	ldx	lnum
	inx	
	cpx	nlines
	beq	..sd2
	stx	lnum
	jmp	scrdwn

..sd2	jsr	botln
	stx	y

	lda	nlines
	ldx	ytop
	jsr	moveup

	jsr	rstcol
	jsr	dspbuf
	jmp	rstcol


botln	proc			; BotLn()
	clc	
	lda	ytop
	adc	nlines
	tax	
	dex	
escape	rts	


chkcol	proc			; ChkCol()
	jsr	setsp
	ldy	#0
	lda	(buf),y
	cmp	sp
	bcs	chkc1
	jsr	back
	jsr	setsp
	clc	
chkc1	rts	


scrllft	proc			; ScrlLft()
	jsr	chkcol
	lda	lmargin
	cmp	colcrs
	bcc	..sl1

	clc	
	lda	choff
	adc	indent
	beq	chkc1

	dec	choff
	jsr	dspbuf
	jsr	scrrt
..sl1	jmp	scrlft


scrlrt	proc			; ScrlRt()
	jsr	chkcol
	bcc	chkc1

	lda	colcrs
	cmp	rmargin
	bcc	..sr2

	inc	choff
	jsr	dspbuf
	jsr	scrlft
..sr2	jmp	scrrt


setsp	proc			; SetSp()
	sec	
	lda	indent
	adc	choff
	clc	
	adc	colcrs
	sec	
	sbc	lmargin
	sta	sp
	rts	


movedwn	proc			; MoveDwn(cnt, row)
	ldy	#0-40
	sty	arg5
	ldy	#$ff
	bne	move


moveup	proc			; MoveUp(cnt, row)
	ldy	#40
	sty	arg5
	ldy	#0


move	proc	
	sty	arg6
	sta	arg4
	stx	rowcrs
	jsr	rstcsr
	jsr	dsploc		; get display address

	ldx	arg4
	dex	
..mu1	lda	arg0
	sta	arg2
	clc	
	adc	arg5
	sta	arg0
	lda	arg1
	sta	arg3
	adc	arg6
	sta	arg1

	ldy	#39
..mu2	lda	(arg0),y
	sta	(arg2),y
	dey	
	bpl	..mu2

	dex	
	bne	..mu1
	rts	


;         EDIT.TAG

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified March 16, 1983



settag	proc			; SetTag()
	jsr	tagid

	lda	tempbuf
	beq	notag

	jsr	clnln
	lda	tempbuf+1
	jsr	gettag
	bne	..st1		; tag already exists

; get a new tag
	lda	#8
	jsr	allocate
	ldy	#1
	lda	taglist+1
	sta	(afcur),y
	dey	
	lda	taglist
	sta	(afcur),y
	lda	afcur
	sta	taglist
	ldx	afcur+1
	stx	taglist+1

..st1	ldy	#4
	lda	tempbuf+1
	sta	(afcur),y
	iny	
	lda	cur
	sta	(afcur),y
	iny	
	lda	cur+1
	sta	(afcur),y
	iny	
	jsr	setsp
	sta	(afcur),y
; flag line as taged
	ldy	#3
	lda	(cur),y
	ora	#$80
	sta	(cur),y
	rts	


notag	proc			; NoTag()
	lda	#low ..ntmsg
	ldx	#high ..ntmsg
	jmp	cmdmsg

..ntmsg	db	11,"tag not set"


tagid	proc			; TagId()
	lda	#low ..stmsg
	ldx	#high ..stmsg
	jmp	gettemp

..stmsg	db	8,"tag id: "


loctag	proc			; LocTag()
	jsr	tagid
	lda	tempbuf
	beq	..ltret
	jsr	clnln
	lda	tempbuf+1
	jsr	gettag
	beq	notag
	ldy	#6
	lda	(afcur),y
	tax	
	dey	
	lda	(afcur),y
	jsr	findln
	beq	notag
	ldy	#3
	lda	(arg2),y
	bpl	notag
	ldy	#7
	lda	(afcur),y
	sta	sp
	lda	arg2
	sta	cur
	ldx	arg3
	stx	cur+1
	jmp	found


;GetTag PROC ; GetTag(tag)
gettag	sta	arg0
	lda	taglist
	ldx	taglist+1
	bne	..gt2
..ltret	rts	

..gt1	ldy	#4
	lda	(afcur),y
	cmp	arg0
	beq	..gt3
	ldy	#1
	lda	(afcur),y
	tax	
	dey	
	lda	(afcur),y
..gt2	sta	afcur
	stx	afcur+1
	txa	
	bne	..gt1
..gt3	ldx	afcur+1
	rts	


freetags	proc		; FreeTags()
	lda	taglist
	ldx	taglist+1
	beq	..ft2
..ft1	sta	afbest
	stx	afbest+1
	ldy	#0
	lda	(afbest),y
	sta	arg0
	iny	
	lda	(afbest),y
	sta	arg1
	jsr	free1
	lda	arg0
	ldx	arg1
	bne	..ft1
	stx	taglist+1
..ft2	rts	


findln	proc			; FindLn(line)
	sta	arg0
	stx	arg1
	lda	top
	ldx	top+1
	bne	..fl2
	rts	

..fl1	ldy	#5
	lda	(arg2),y
	tax	
	dey	
	lda	(arg2),y
..fl2	sta	arg2
	stx	arg3
	cmp	arg0
	bne	..fl3
	cpx	arg1
	beq	..fl4
..fl3	txa	
	bne	..fl1
..fl4	ldx	arg3
	rts	

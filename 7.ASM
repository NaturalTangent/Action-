
;         AMPL.MON
; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; last modified July 29, 1983
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


	proc	

; Monitor for ACTION!



monitor	proc	
	jsr	savworld
	lda	delbuf		; delete buffer bottom
	ldx	delbuf+1
	jsr	delfree		; get rid of delete buf
	lda	top+1
	sta	top1
mon1	jsr	scrinit
	ldx	#1
	stx	rowcrs
	stx	mpc
	dex	
	stx	cmdln
	stx	device
	jsr	splsetup

; LIST I

mloop	jsr	initkeys

; LIST *

	lda	dindex		; display mode
	beq	..mon2
	jsr	scrinit		; get Graphics(0)
..mon2	jsr	alarm
	jsr	rstcsr
	lda	#low mprompt
	ldx	#high mprompt
	jsr	gettemp
	ldy	tempbuf
	beq	mloop

	lda	#0
	sta	top+1
	sta	chan
	lda	#low tempbuf
	ldx	#high tempbuf
	ldy	sp
	iny			; make sure non-zero
	jsr	lexp1
	jsr	getnext

	lda	tempbuf+1
	ora	#$20
	ldx	#low mcmd
	ldy	#high mcmd
	jsr	lookup
	jmp	mloop


mquit	ldy	#0
	sty	mpc
	sty	subbuf
	sty	findbuf
	sty	dirtyf


rstwnd	proc	
	lda	#23
	sta	cmdln
	lda	numwd
	beq	..rw1
	lda	wsize
	sta	cmdln
	lda	#w2-w1
	jsr	paintw
	lda	#0
..rw1	jsr	paintw
	jsr	fcmsg1
	jmp	floop


paintw	proc			; PaintW(window)
	sta	curwdw
	jsr	rstwd
	jmp	found


mdump	proc	
	jsr	mprint
..md1	inc	arg11
	bne	..md2
	inc	arg12
..md2	lda	arg11
	ldx	arg12
	jsr	mp1
	jsr	gotkey
	beq	..md1
	ldx	#$ff
	stx	ch
	cmp	#$de
	bne	..md1
	rts	


mprint	jsr	mpsave
mp1	jsr	printc
	ldy	#',
	jsr	putchar
	lda	arg11
	ldx	arg12
	jsr	printh
	jsr	putsp
	ldy	#'=
	jsr	putchar
	jsr	putsp
	jsr	mpload
	tay	
	jsr	putchar
	jsr	putsp
	jsr	mpload
	jsr	printh
	jsr	putsp
	jsr	mpload
	ldx	#0
	jsr	printc
	jsr	putsp
	jsr	mpload
	jsr	printc
	jmp	puteol


mpload	ldy	#1
	lda	(arg11),y
	tax	
	dey	
	lda	(arg11),y
	rts	


mpsave	jsr	mnum
	sta	arg11
	stx	arg12
	rts	


boot	proc	
	lda	#low ..bmsg
	ldx	#high ..bmsg
	jsr	yesno
	bne	mwrt1
	jmp	cold

..bmsg	db	6,"Boot? "


mrun	lda	nxttoken
	cmp	#eofid
	beq	..mr1

	cmp	#quote		; compile and go?
	bne	..mr2		; no
	jsr	comp

..mr1	lda	$02e2
	ldx	$02e3
	bne	..mr3
mwrt1	rts	

..mr2	jsr	mnum
..mr3	jsr	run
	lda	#0
	sta	device
	rts	


mwrite	proc			; write object file
	lda	nxttoken
	cmp	#quote
	bne	mwrt1		; no output file!
	lda	$02e3
	beq	mwrt1		; no program!!
	lda	#1
	sta	chan
	lda	#8		; output
	jsr	openchan

; write header
	lda	#6
	sta	arg9
	lda	#$ff
	sta	arg10		; $FF
	sta	arg11		; $FF
	clc	
	lda	codebase	; starting address
	adc	codeoff
	sta	arg12
	lda	codebase+1
	adc	codeoff+1
	sta	arg13
	tax	

	clc			; ending address
	lda	arg12
	adc	codesize
	sta	arg14
	bne	..mw2
	dex	
..mw2	dec	arg14
	txa	
	adc	codesize+1
	sta	arg15
	jsr	mwout

; write the qcode
	ldx	#$10
	lda	#$0b		; output command
	sta	$0342,x
	lda	codebase
	sta	$0344,x		; address
	lda	codebase+1
	sta	$0345,x
	lda	codesize
	sta	$0348,x		; size
	lda	codesize+1
	sta	$0349,x
	jsr	$e456		; CIOV
	bmi	mwerr

; save start address
	ldx	#4
..mw3	lda	..mwinit,x
	sta	arg9,x
	dex	
	bpl	..mw3
	lda	$02e2
	sta	arg14
	lda	$02e3
	sta	arg15
	jsr	mwout

; close file
	lda	#1
	jmp	close

..mwinit	db	6
	dw	$02e2
	dw	$02e3


mwout	lda	#1
	ldx	#arg9
	ldy	#0
	jsr	output
	bmi	mwerr
	rts	


mxerr	ldy	#ender
mwerr	jmp	splerr


mx	proc			; execute command line
	lda	#0
	sta	codeoff
	sta	codeoff+1
	lda	qcode
	pha	
	lda	qcode+1
	pha	
	jsr	getnext
	jsr	cstmtlst
	cmp	#eofid
	bne	mxerr
	lda	#$60		; RTS
	ldy	#0
	sta	(qcode),y
	pla	
	tax	
	pla	
	jmp	run


comp	proc			; Comp()
	jsr	splsetup
	jsr	dspoff
	jsr	compile
	jmp	dspon


; see MAIN.BNK now
;Dret PROC ; Dret() go to DOS
; LDA DOSVEC
; LDX DOSVEC+1
; JMP JSRInd


proceed	proc			; Proceed()
	ldx	procsp
	beq	..p1
; LDA #< ..pmsg
; LDX #> ..pmsg
; JSR YesNo
; BNE ..p1
; LDX procSP ; break stack pointer

	lda	#0
	sta	procsp
	txs	
	jmp	lproceed

..p1	rts	

;:Pmsg DEFMSG "Proceed? "


printh	proc			; PrintH(num)
	sta	arg0
	stx	arg1
	lda	#4
	sta	arg2
	ldy	#'$
	jsr	putchar
..ph1	lda	#0
	ldx	#4
..ph2	asl	arg0
	rol	arg1
	rol	a
	dex	
	bne	..ph2
; CLC
	adc	#'0
	cmp	#':
	bmi	..ph3
	adc	#6
..ph3	tay	
	jsr	putchar
	dec	arg2
	bne	..ph1
	rts	


mcmd	dw	disptb+9	; unknown cmd
	db	35		; table size
	dw	boot
	db	'b
	dw	comp
	db	'c
	dw	dret
	db	'd
	dw	mquit
	db	'e
; .WORD Format
; .BYTE 'f
	dw	options
	db	'o
	dw	proceed
	db	'p
	dw	mrun
	db	'r
	dw	mwrite
	db	'w
	dw	mx
	db	'x
	dw	mprint
	db	'?
	dw	mdump
	db	'*

mprompt	db	1,">"


;         AMPL.INI

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified May 4, 1983



splsetup	proc		; SPLsetup()
	lda	#0
	tay	
	sta	sp
	sta	chan
	sta	symtab
	sta	$02e3
	sta	(buf),y
	sta	param
	sta	qglobal
	sta	stackptr
	sta	arrayptr+1
	sta	whaddr+1
	sta	curnxt+1
	sta	procsp

; clear qglobal s.t.
	ldx	bigst		; big s.t. ?
	beq	..spls0		; no
..s0	sta	(stg2),y
	iny	
	bne	..s0
..spls0	sta	(stglobal),y
	iny	
	bne	..spls0

; get last block in heap
	lda	afbase
	ldx	afbase+1
	sta	arg0
	stx	arg1
..spls1	ldy	#1
	lda	(arg0),y
	beq	..spls2
	tax	
	dey	
	lda	(arg0),y
	sta	arg0
	stx	arg1
	jmp	..spls1

..spls2	clc	
	lda	arg0
	adc	#4
	bcc	..spls3
	inc	arg1

..spls3	sta	codebase
	sta	qcode

	lda	arg1
	sta	codebase+1
	sta	qcode+1

	lda	memtop+1
	sta	stmax
	dec	stmax
	clc	
	sbc	stsp
	sta	stbase
	sta	symtab+1
	inc	symtab+1

	cmp	qcode+1
	bcs	..spls4

; can't allocate memory
	lda	sparem
	sta	symtab
	lda	sparem+1
	sta	symtab+1
alcerr	ldy	#alcer
	jmp	splerr

..spls4	lda	sparem
	sta	frame
	ldx	sparem+1
	inx	
	inx	
	stx	frame+1

	lda	#low stkbase
	sta	stack
	lda	#high stkbase
	sta	stack+1
	sta	cury		; unknown initial Y value

	rts	

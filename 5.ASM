
;            LIB.OPT

; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; last modified July 6, 1983
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


setopts	proc	
; Display On?
	ldx	#domsg-optmsg
	ldy	tvdisp
	jsr	..yn
	beq	..do1
	lda	#0
	beq	..do2
..do1	lda	#$22
..do2	sta	tvdisp


; Alarm?
	ldx	#amsg-optmsg
	ldy	alarm
	cpy	#$60
	jsr	..yn
	beq	..a1
	lda	#$60		; RTS
	bne	..a2
..a1	lda	#$4c		; JMP
..a2	sta	alarm


; Case sensitive?
	ldx	#cmsg-optmsg
	ldy	stmask
	cpy	#$df
	jsr	..yn
	beq	..c1
	lda	#$df
	bne	..c2
..c1	lda	#$ff
..c2	sta	stmask


; Trace On?
	ldx	#tmsg-optmsg
	ldy	trace
	jsr	..yn
	beq	..t1
	lda	#0
	beq	..t2
..t1	lda	#$ff
..t2	sta	trace


; List On?
	ldx	#lstmsg-optmsg
	ldy	list
	jsr	..yn
	beq	..lst1
	lda	#0
	beq	..lst2
..lst1	lda	#$ff
..lst2	sta	list


; window size
	lda	wsize
	jsr	..getstr
	ldx	#wmsg-optmsg
	jsr	..getnum
	cmp	#5
	bcs	..w0		; make sure at least 5
	lda	#5
..w0	cmp	#19
	bcc	..w1		; make sure less than 19
	lda	#18
..w1	sta	wsize
	ldx	numwd
	beq	..l1
	sta	w1+wnlns
	tay	
	iny	
	sty	w2+wytop
	sec	
	lda	#23
	sbc	wsize
	sta	w2+wnlns


; line size
..l1	lda	linemax
	jsr	..getstr
	ldx	#lmsg-optmsg
	jsr	..getnum
	sta	linemax


; left margin
	lda	lmargin
	jsr	..getstr
	ldx	#lmmsg-optmsg
	jsr	..getnum
	sta	lmargin


; EOL char
	lda	eolch
	tay	
	rol	a
	rol	a
	rol	a
	rol	a
	and	#3
	tax	
	tya	
	and	#$9f
	ora	..stoa,x
	tay	
	ldx	#emsg-optmsg
	jsr	..yn2
	lda	tempbuf+1
	tay	
	and	#$60
	tax	
	tya	
	and	#$9f
	ora	chcvt,x
	sta	eolch
	rts	


..yn	beq	..yn1
	ldy	#'Y
	bne	..yn2
..yn1	ldy	#'N
..yn2	sty	tempbuf+1
	ldy	#1
	jsr	gettmpbuf
	lda	tempbuf+1
	ldy	tempbuf
	bne	..yn5
	cmp	#$1b
	bne	..yn4
..yn3	pla	
	pla	
..yn4	rts	

..yn5	ora	#$20
	cmp	#'y
	rts	


..getstr	ldx	#0
	ldy	#high tempbuf
	sty	arg3
	ldy	#low tempbuf
	jmp	strc


..getnum	ldy	tempbuf
	jsr	gettmpbuf
	ldy	tempbuf
	bne	..gn0
	lda	tempbuf+1
	cmp	#$1b
	beq	..yn3
..gn0	lda	#low tempbuf
	ldx	#high tempbuf
	jsr	valb
	lda	args
..gn1	rts	


domsg	db	9,"Display?"

optmsg	equ	domsg-20	; see GetTemp

amsg	db	6,"Bell?"
cmsg	db	16,"Case sensitive?"
tmsg	db	7,"Trace?"
lstmsg	db	6,"List?"
wmsg	db	15,"Window 1 size:"
lmsg	db	11,"Line size:"
lmmsg	db	13,"Left margin:"
emsg	db	10,"EOL char:"

..stoa	db	$20,$40,$00,$60


gettmpbuf	proc	
	sty	arg2

; copy string to tempBuf+10
	ldy	#20
..gt1	lda	optmsg+20,x
	sta	tempbuf+10,y
	dex	
	dey	
	bpl	..gt1

; put space at end
	tay	
	lda	#' 
	sta	tempbuf+10,y

	lda	#low (tempbuf+10)
	ldx	#high (tempbuf+10)
	ldy	arg2
	jmp	mgett1


;         EDIT.FND

; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; last modified May 4, 1983
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



find	proc			; Find()
	jsr	setsp
	jsr	savewd
	lda	lastch
	cmp	#$f8
	beq	find2
	lda	#low findmsg
	ldx	#high findmsg
find1	ldy	#high findbuf
	sty	arg3
	ldy	#low findbuf
	jsr	cmdstr
	lda	#$f8
	sta	curch

find2	lda	findbuf
	beq	..f7

..f2	ldy	#0
	lda	(buf),y
	tay	
	iny	
	sty	arg0

..f3	ldy	sp
	iny	
	cpy	arg0
	bcs	..f5
	sty	sp
	ldx	#0

..f4	lda	(buf),y
	inx	
	cmp	findbuf,x
	bne	..f3
	iny	
	cpx	findbuf
	beq	found
	cpy	arg0
	bcc	..f4

..f5	jsr	nextdwn
	beq	..f6
	jsr	ldbuf
	lda	#0
	sta	sp
	beq	..f2

..f6	sta	curch
	jsr	rstcur
	jsr	ldbuf
	lda	#low notfnd
	ldx	#high notfnd
	jsr	cmdmsg
	lda	#0
..f7	sta	curch
	rts	

found	jsr	ctrln
	ldy	sp
	dey	
	tya	
	jsr	back0
	lda	#$fe
	rts	

notfnd	db	9,"not found"

findmsg	db	6,"Find? "


;         EDIT.SUB

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified September 8, 1983

	proc	

subst	proc			; Subst()
	jsr	setsp
	jsr	savewd
	lda	lastch
	cmp	#$7d
	beq	..s2
	pha	
	lda	#low submsg
	ldx	#high submsg
	ldy	#high subbuf
	sty	arg3
	ldy	#low subbuf
	jsr	cmdstr
	pla	
; check for ESC key
	ldx	subbuf
	bne	..s0
	ldx	subbuf+1
	cpx	#$1b
	beq	..s1
..s0	cmp	#$f8
	beq	..s3		; string already found
	lda	#low formsg
	ldx	#high formsg
	jsr	find1
	bne	..s3

..s1	rts	

..s2	jsr	find2
	beq	..s1
..s3	lda	#$7d
	sta	curch
	sta	dirtyf		; flag line as dirty
	sec	
	lda	subbuf
	sbc	findbuf		; get delta size
	sta	arg3
	php			; save status for test below
	bcs	..s4
	lda	#1
	sbc	arg3		; negate delta size
..s4	clc	
	adc	buf
	sta	arg0
	lda	#0
	tay	
	adc	buf+1
	sta	arg1
	lda	(buf),y
	plp	
	bcc	..s6		; need to remove space
	beq	..s8		; same size
; need to add space
	tay	
..s5	lda	(buf),y
	sta	(arg0),y
	dey	
	cpy	sp
	bcs	..s5
	bcc	..s8

..s6	sta	arg2
	ldy	sp
	dey	
..s7	iny	
	lda	(arg0),y
	sta	(buf),y
	cpy	arg2
	bcc	..s7

..s8	ldy	sp
	ldx	#0
	beq	..s10
..s9	inx	
	lda	subbuf,x
	sta	(buf),y
	iny	
..s10	cpx	subbuf
	bne	..s9
	clc	
	ldy	#0
	lda	(buf),y
	adc	arg3
	sta	(buf),y
	jmp	rfrshbuf


submsg	db	12,"Substitute? "

formsg	db	5,"for? "


;         EDIT.TAB

; Copyright 1983 by Action Computer Services
; All rights reserved.

; last modified March 9, 1983

	proc	


tab	proc			; Tab()
	jsr	setsp
	jsr	..tabpos

..t1	lda	tabmap,x
	beq	..t3
	and	..onbit,y
	beq	..t2
; found tab setting
	sty	arg0
	txa	
	asl	a
	asl	a
	asl	a
	ora	arg0
	jmp	back0		; do the tab

..t2	iny	
	cpy	#8
	bmi	..t1
..t3	ldy	#0
	inx	
	cpx	#15
	bmi	..t1
	rts	

..onbit	db	$80,$40,$20,$10,8,4,2,1,0
..offbit	db	$7f,$bf,$df,$ef,$f7,$fb,$fd,$fe,$ff


settab	jsr	..tabloc
	lda	tabmap,x
	ora	..onbit,y
	sta	tabmap,x
	rts	


clrtab	jsr	..tabloc
	lda	tabmap,x
	and	..offbit,y
	sta	tabmap,x
	rts	


..tabloc	jsr	setsp
	sec	
	sbc	#1
..tabpos	tay	
	lsr	a
	lsr	a
	lsr	a
	tax	
	tya	
	and	#7
	tay	
	cpx	#15
	bmi	..tp1
	ldy	#8
..tp1	rts	

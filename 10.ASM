
;         AMPL.SEG

; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; last modified October 15, 1983
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

; low segment list> ..:= low segment list> low segment> | low segment>
; low segment> ..:= low segment type> low heading> (<dcl list>) (<stmt list>)
; low segment type> ..:= PROC | low type> FUNC



segment	proc	
	cmp	#proc
	beq	..proc
	ldx	nxttoken
	cpx	#func
	beq	..func
	rts			; end of segment list

..proc	lda	#funct-vart+char-1
	sta	type
	bne	..func1		; uncond.

..func	clc	
	adc	#funct-vart
	sta	type
	jsr	getnext

..func1	jsr	makeentry
	jsr	segend
	lda	addr
	sta	curproc
	lda	addr+1
	sta	curproc+1
	sta	qglobal

	lda	#1
	jsr	stincr		; space for num args

	ldy	#3
	lda	#0		; no args yet
	sta	(props),y
	sta	argbytes

	tay	
..funcst	sta	(stlocal),y
	iny			; zap local st
	bne	..funcst

	lda	symtab
	sta	gbase
	lda	symtab+1
	sta	gbase+1

; space for arg list (8 bytes) and
; room for name of next proc/func
; up to 20 letters (24 bytes)
; unused space will be reclaimed
; see Params
	lda	#32
	jsr	stincr		; arg list space

	jsr	trashy

	lda	nxttoken
	eor	#equalid
	sta	param		; this is very tricky!!
	bne	..funchd
	jsr	ideq		; param must = 0 here
	iny	
	jsr	storprops
	ldy	#0
	lda	(props),y
	ora	#8
	sta	(props),y	; set Sys flag
	sta	param
	jsr	getnext

..funchd	jsr	getnext
	cmp	#lparen
	bne	argerr


; low heading> ..:= low id> (= low constant>) ( (<arg dcl list>) )
; low arg dcl list> ..:= low arg dcl list> , low dcl list> | low dcl list>


	jsr	getnext
	cmp	#rparen
	beq	..func2

..heading	jsr	declare
	ldx	lsttoken
	inc	lsttoken	; in case 2 ,'s
	cpx	#comma
	beq	..heading

	cmp	#rparen
	beq	..func2

argerr	ldy	#arger
	jmp	splerr

..func2	lda	param
	pha	
	lda	#0
	sta	param

	jsr	getnext
	jsr	declare		; locals

; handle procedure setup here
	pla	
	bmi	..f4		; system proc

; get beginning of arguments and
; save actual procedure address
	lda	#1
	jsr	cprop
	sta	arg0
	stx	arg1
	jsr	getcdoff
	jsr	storprops

; get space for proc variable
	lda	#$4c		; JMP
	jsr	push1
	jsr	getcdoff	; fill in address
	adc	#2
	bcc	..fh2
	inx	
..fh2	jsr	push2

; qcode to transfer arguments to
; local frame
..fh3	lda	argbytes
	beq	..func3		; no arguments
	cmp	#3
	bcs	..fh5
	cmp	#2
	lda	#$8d		; STA addr16
	ldx	arg0
	ldy	arg1
	bcc	..fh4
	lda	#$8e		; STX addr16
	inx	
	bne	..fh4
	iny	
..fh4	jsr	push3
	dec	argbytes
	jmp	..fh3

..f4	jmp	..func4

..fh5	ldx	#10
	jsr	jsrtable
	lda	arg0
	ldx	arg1
	ldy	argbytes
	dey	
	jsr	push3

..func3	lda	trace		; check for trace
	beq	..func4		; no trace
	lda	#$20		; JSR CTrace
	ldx	#low ctrace
	ldy	#high ctrace
	jsr	push3

	ldy	#0
	lda	(curproc),y
	tay	
	tax	
..f3a	lda	(curproc),y
	sta	(qcode),y
	dey	
	bpl	..f3a
	inx	
	txa	
	jsr	codeincr

	lda	arg0
	ldx	arg1
	jsr	push2

	lda	#3
	jsr	cprop
	tay	
	tax	
..f3b	lda	(props),y
	sta	(qcode),y
	dey	
	bpl	..f3b
	inx	
	txa	
	jsr	codeincr

..func4	jsr	stmtlist
	jmp	segment


;         AMPL.PF

; Copyright 1983 by Action Computer Services
; All Rights Reserved

; last modified November 3, 1983

	proc	


	proc			; PF()

..ld1	ldy	#0
	lda	(stack),y
	cmp	#arrayt
	bcs	..c5a
	inc	abt-args,x
	ldy	#7
	lda	(stack),y
	cmp	#tempt+bytet
	beq	..c5b
	dec	abt+1-args,x
	cpx	#args+2
	bcc	..c5b
	jsr	gops
	jsr	load2h
	lda	#$81		; STA
	jsr	op1h
	jmp	..c5b


pf	lda	#0		; load arg types flag
	jsr	getargs
	jsr	pushst
	jsr	getnext
	ldx	#args
	stx	argbytes
	ldx	nxttoken
	cpx	#rparen
	bne	..c4

	jsr	getnext
	bne	..c7		; uncond.

..c4	ldx	numargs
	ldy	#tempt+bytet
	lda	argtypes-1,x
	ldx	argbytes
	stx	abt+3
	cmp	#$7f
	bcs	..c5		; one byte arg
	sta	temps-args+1,x
	inc	argbytes
	iny	
..c5	sta	temps-args,x
	inc	argbytes
	txa	
	jsr	storst
	jsr	getexp
	dec	numargs
	bmi	callerr
	ldx	abt+3
	cpx	#args+3
	bcc	..ld1
..c5a	jsr	cgassign
..c5b	lda	token
	cmp	#comma
	beq	..c4

	cmp	#rparen
	bne	callerr
..c6	lda	argbytes
	cmp	#args+3
	bcs	..c8
	cmp	#args+2
	bcs	..c9
	cmp	#args+1
	bcs	..c10
..c7	jsr	trashy
	ldy	#1
	jsr	stkaddr
	lda	#$20		; JSR
	jmp	push3

..c8	ldx	#args+2
	jsr	..push
..c9	ldx	#args+1
	jsr	..push
..c10	ldx	#args
	jsr	..push
	jmp	..c7


callerr	jmp	argerr


..push	lda	abt-args,x
	bne	..p1
	lda	..ops-args,x
	ora	#$04
	jmp	push2

..p1	stx	arg0
	jsr	gops
	ldx	arg0
	lda	..ops-args,x
; all of this for LDX # and LDY #
; can't use OpXX for these instr.
	cpx	#args
	beq	..p4		; LDA instr.
	ldy	arg1
	bpl	..p3a		; record element
	cpy	#vart
	ldy	abt-args,x
	bcs	..p3		; not const.
	pha	
	sty	arg0
	ldy	#2
	jsr	loadi
	ldy	arg0
	bmi	..p2
	tax	
	pla	
	jsr	push2		; low byte of const
	jmp	cga1

..p2	pla	
..p2a	jmp	push2		; high byte

..p3a	ldy	abt-args,x
..p3	bpl	..p4
	ldx	arg3
	beq	..p2a
	jmp	op2h

..p4	jsr	op2l
	jmp	cga1

..ops	db	$a1,$a2,$a0	; LDA, LDX, LDY


;         AMPL.ARR

; Copyright 1983 by Action Computer Services
; All Rights reserved

; last modified June 7, 1983



arrref	proc			; ArrRef()
	ldx	nxttoken
	cpx	#lparen
	beq	..arr0
	cpx	#uparrow
	beq	..arr0
arrvar	ldy	#vart+cardt	; no index!
	sty	token
	cmp	#arrayt+8
	bcc	..arr1
arrconst	jsr	stconst
..arr1	jmp	pushst

..arptr	ldy	#0
	lda	(stack),y
	cmp	#arrayt+8
	bcs	..arpt1		; small array
	iny	
	jsr	stkp
	cpx	#0
	bne	..arpt1
; page zero pointer
	ldy	#1
	sta	(stack),y
	dey	
	lda	(stack),y
	ora	#$b0		; temp array mode
	sta	(stack),y
	rts	

..arpt1	jsr	zerost
	bne	..ar0		; uncond.

..arr0	jsr	pushnext
	cmp	#uparrow
	beq	..arptr
	jsr	getexp
	cmp	#rparen
	bne	arrerr
	ldx	op
	bne	arrerr
..ar0	ldy	#7
	lda	(stack),y
arra0	pha	
	lda	#vart+cardt
	sta	(stack),y
	lda	#plusid
	jsr	genops
	pla	
	cmp	#arrayt+8
	bcs	..arsmall
	and	#7
	tax	
	ora	#$b0		; temp array mode
	sta	arg7
	ldy	arg1
	cpy	#constt+strt
	ldy	#1		; clear Z flag if we branch
	bcs	..ar1
	lda	(stack),y
	iny	
	ora	(stack),y
..ar1	sta	fr1
	beq	..arint		; pointer
	ldy	vartype-1,x
	beq	..arbyte
; CPY #3
; BEQ ..ARReal
; integer or cardinal
..arint	jsr	gettemps
	lda	#$a1		; LDA
	ldx	fr1
	beq	..ari1
	jsr	load2l
	lda	#$0a		; ASL A
	ldx	#$08		; PHP
	ldy	#$18		; CLC
	jsr	push3
	lda	#$61		; ADC
	$if	ramzap
	sta	(arg8),y
	$else	
	nop	
	nop	
	$endif	
..ari1	jsr	op1l
	jsr	stempl
	lda	#$a1		; LDA
	ldx	fr1
	beq	..ari2
	jsr	load2h
	lda	#$2a		; ROL A
	ldx	#$28		; PLP, restore carry
	jsr	push2
	lda	#$61		; ADC
..ari2	jsr	op1h
	jmp	cgadd2

arrerr	ldy	#arrer		; bad array ref
	jmp	splerr

..arbyte	jmp	cg1

..arsmall	ldy	#7
	sta	(stack),y	; restore correct type
	lda	arg1
	bpl	arrerr		; can't index with bool.
	bit	arrmode
	bne	arrerr		; can't index with array
	ldy	#10
	sta	(stack),y
	ldy	#2
	jsr	loadi
	ldy	#11
	jsr	savstk
	jmp	popst


;         AMPL.CGU

; Copyright 1982 by Action Computer Services
; All Rights reserved

; last modified October 15, 1983

	proc	


loady	proc			; LoadY() value in arg12
	lda	cury
	cmp	arg12
	beq	..lyret
	jsr	push0
	cmp	#1
	bne	..ly2
	lda	#$88		; DEY
..ly1	jsr	insrt1
	jmp	..ly4

..ly2	cmp	#0
	bne	..ly3
	lda	#$c8		; INY
	bne	..ly1

..ly3	lda	#$a0
	ldx	arg12
	jsr	insrt2		; LDY #0 or #1

..ly4	lda	arg12
	sta	cury
	ldy	arg13

..lyret	rts	


trashy	proc			; TrashY()
	lda	#$ff
	sta	cury
	rts	


loadx	proc			; LoadX(,,offset)
; NOTE:  this proc can only be called
; from Op below, see ..LXC
	lda	(stack),y
	iny	
	bit	tempmode
	bne	..lxt
	bit	cnstmode
	beq	..lxc
; var to load
	jsr	stkprop
	beq	..lxz
	lda	#$ae		; LDX addr16
	jmp	push3

..lxt	lda	(stack),y
	tax	
	dec	temps-args,x
..lxz	lda	#$a6		; LDX addr
..lx1	jmp	push2

..lxc	lda	(stack),y
; TAX
; LDA #$A2 ; LDX data
; BNE ..LX1
	sta	arg12
	pla	
	pla	
	pla	
	tay	
	bne	..opv		; uncond.


..optype	and	#$20
	beq	..operr		; con. exp.
	jsr	stkaddr
	lda	arg12
	beq	..opv1
	inx	
	bne	..opv1
	iny	
	jmp	..opv1


;Load1L PROC ; Load1L()
load1l	lda	#$a1		; LDA op


;Op1L PROC ; Op1L(op)
op1l	pha	
	lda	arg2
	ldy	#8
oplow	ldx	#0
ophigh	stx	arg12
; NOTE:  the order of following
; comparisons is important!
	tax	
	bpl	..optype
	bit	procmode
	bne	..opp
	bit	arrmode
	bne	..opa		; array
	bit	tempmode
	bne	..opt		; temp
	bit	cnstmode
	beq	..opc		; constant
; var if we get here
..opv	jsr	stkprop
	beq	..opz		; page zero var
; 16 bit address
..opv1	pla	
	ora	#$0c		; addr16
	jmp	push3

..opp	inc	arg12		; skip JMP byte
	and	#8
	beq	..opv
..operr	jmp	conderr		; cond. exp.

..opa	bit	cnstmode
	bne	..opa2
	jsr	loady
; LDA arg7
; AND #$F7
; STA arg7 ; flag Y reg used
	lda	#0
	sta	arg12
	lda	#$10		; (addr),Y
..opa1	sta	arg10
	lda	(stack),y
	clc	
	adc	arg12
	cmp	#args
	bcc	..opc2
	cmp	#args+16
	bcs	..opc2
	tax	
	dec	temps-args,x	; free temp
	bcc	..opc3		; uncond.

..opa2	tya			; small array
	pha	
	iny	
	iny	
	jsr	loadx
	pla	
	tay	
	jsr	stkprop
	beq	..opa2a		; page zero
	pla	
	ora	#$1c		; addr16,X
	jmp	push3

..opa2a	pla	
	ora	#$14		; addr,X
	jmp	push2

..opc	lda	#$08		; data
	sta	arg10
	lda	arg12
	beq	..opc1
	iny	
..opc1	lda	(stack),y
..opc2	tax	
..opc3	pla	
	ora	arg10		; op mode
	jmp	push2

..opt	lda	#$04		; addr
	bne	..opa1		; uncond.

..opz	pla	
	ora	#$04		; addr
	jmp	push2


load2l	proc			; Load2L()
	lda	#$a1		; LDA op


op2l	proc			; Op2L(op)
	pha	
	lda	arg1
	ldy	#1
	jmp	oplow


load1h	proc			; Load1H()
	lda	#$a1		; LDA op


op1h	proc			; Op1H(op)
	ldx	arg4
	beq	ophz
	pha	
	lda	arg2
	ldy	#8
op1h1	ldx	#1
	jmp	ophigh


load2h	proc			; Load2H()
	lda	#$a1		; LDA op


op2h	proc			; Op2H(op)
	ldx	arg3
	beq	ophz
	pha	
	lda	arg1
	ldy	#1
	bne	op1h1

ophz	ora	#$08
	jmp	push2

arrmode	db	$10
cnstmode	db	$08
tempmode	db	$20
procmode	db	$40

; see CG
outtype	db	$82,3,$84,realt
	db	3,3,$84,realt
	db	$84,$84,$84,realt
	db	realt,realt,realt,realt


gettemps	proc		; GetTemps()
	ldx	#args+16
	ldy	#7
..gtl1	dex	
	dex	
	dey	
	bmi	..gtlerr	; exp. too complex
	lda	temps-args,x
	bne	..gtl1

	inc	temps-args,x
	lda	arg5		; see if byte temp
	beq	..gt2		; yes
	inc	temps-args+1,x
	$if	ramzap
	inc	sargs,x
	$else	
	nop	
	nop	
	nop	
	$endif	
..gt2	stx	arg9
	rts	

..gtlerr	jmp	experr


loadi	proc			; LoadI(,,offset)
	lda	(stack),y
	sta	arg15
	tax	
	dey	
	lda	(stack),y
	sta	arg14
	rts	


ldcdz	proc			; LdCdZ(,,stkoff)
	lda	#0


loadcd	proc			; LoadCd(cdoff,,stkoff)
	clc	
	adc	(stack),y
	sta	qcode
	iny	
	lda	#0
	adc	(stack),y
	sta	qcode+1
	rts	


savecd	proc			; SaveCd(,,offset)
	lda	qcode
	ldx	qcode+1
savstk	sta	(stack),y
	txa	
	iny	
	sta	(stack),y
	rts	


relop	proc			; RelOp()
	lda	arg6
	bpl	..ro1
	inc	arg8
..ro1	rts	


chkzero	proc	
	lda	arg3
	bne	..cz1
	lda	arg1
	bpl	..cz1		; not const
	cmp	#vart
	bcs	..cz1
	ldy	#1
	lda	(stack),y
..cz1	rts	


opcd1	proc			; OpCd1()
	ldx	arg8
	lda	cgopscd+1,x
	rts	


stkaddr	proc			; StkAddr(,,offset)
	lda	(stack),y
	tax	
	iny	
	lda	(stack),y
	tay	
	rts	


stkp	proc			; StkP(,,offset)
	jsr	stkaddr
	lda	#1
	jmp	gprop


stkpz	proc			; StkPZ(,,offset)
	lda	#0
stkps	proc			; StkPS(,,offset)
	sta	arg12
stkprop	proc			; StkProp(,,offset)
	jsr	stkp
	clc	
	adc	arg12
	tax	
	iny	
	lda	(props),y
	adc	#0
	tay	
	rts	


jsrtable	proc		; JSRTable(,index)
;.IF RAMzap
;  LDY LTab+1,X
;  LDA LTab,X
;.ELSE
	ldy	lsh+1,x
	lda	lsh,x
;.ENDIF
	tax	
	lda	#$20		; JSR
	jmp	push3


push0	proc			; Push0()
	sty	arg13
	ldy	qcode
	sty	arg14
	ldy	qcode+1
	sty	arg15
	ldy	#0
	rts	


pushtrue	proc		; PushTrue(op)
	jsr	push1
	ldy	#10
	jsr	savecd
	lda	#0		; no other true branches
	sta	arg9
; falls into Push1


push1	proc			; Push1(op)
	jsr	push0
	sta	(arg14),y
	beq	i11


insrt1	proc			; Insrt1(op)
	ldy	#1
	jsr	addcdsp
i11	iny	
	tya	
	jmp	codeincr


stemph	proc			; STempH()
	inc	arg9
	ldy	#12
	bne	stemp		; uncond.

stempl	proc			; STempL()
	ldy	#10
stemp	jsr	savecd
	lda	arg9
	tax	
	and	#$fe		; set to low address
	sta	arg9
	lda	#$85		; STA addr
; falls into Push2


push2	proc			; Push2(op,,data)
	jsr	push0
	sta	(arg14),y
	beq	i21


insrt2	proc			; Insrt2(op,data)
	ldy	#2
	jsr	addcdsp
i21	txa	
	iny	
	sta	(arg14),y
	bne	i11


push3	proc			; Push3(op,data16)
	jsr	push0
	sta	(arg14),y
	beq	i31


insrt3	proc			; Insrt3(op,data16)
	sty	arg13
	ldy	#3
i30	jsr	addcdsp
i31	txa	
	ldx	arg13
	iny	
	sta	(arg14),y
	bne	i21


addcdsp	proc	
; AddCdSp(,,size) add qcode space
; does NOT change qcode or codeOff
	pha	
	clc	
	tya	
	adc	arg14
	sta	arg10
	lda	#0
	adc	arg15
	sta	arg11
	sec	
	lda	qcode
	sbc	arg14

	tay	
	beq	..acsret
..acs1	lda	(arg14),y
	sta	(arg10),y
	dey	
	bne	..acs1

	lda	(arg14),y
	sta	(arg10),y

..acsret	pla	
	sta	(arg14),y
	rts	
›arrayt+8	; small array?
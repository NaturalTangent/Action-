$eject
;====================================
;         Main compiler entry
;====================================
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

ccompile	
spl	proc	
	jsr	splend

	lda	nxttoken
	cmp	#quote
	bne	..spl1		; no name
	 jsr	lget
	 jmp	..spl2

..spl1	lda	top1
	sta	top+1
	jsr	ldtop
	beq	..splrtn	; no program !
	jsr	getnext

..spl2	jsr	getnext

; <program> ..:= <module list> MODULE <module>
;                 | (MODULE) <module>
; <module> ..:= (<dcl list>) (<segment list>)

	jsr	declare
	jsr	segment

	cmp	#modid		; another module ?
	beq	..spl2		; yes

	cmp	#eofid
	bne	..spl4
	lda	#1		; save run address
	jsr	cprop
	sta	$02e2
	stx	$02e3

			; insert return, just in case
..rtn	lda	#$60		; RTS
	jsr	push1

			; get qcode size
	sec	
	lda	qcode
	sbc	codebase
	sta	codesize
	lda	qcode+1
	sbc	codebase+1
	sta	codesize+1

			; patch array addresses
	lda	arrayptr+1
; ORA arrayPtr
	beq	..splrtn

..spl3	ldy	#1
	lda	(arrayptr),y
	sta	arg1
	dey	
	lda	(arrayptr),y
	sta	arg0
	jsr	getcdoff
	sta	(arrayptr),y
	txa	
	iny	
	sta	(arrayptr),y

	clc	
	iny	
	lda	qcode
	adc	(arrayptr),y
	sta	qcode
	iny	
	lda	qcode+1
	adc	(arrayptr),y
	sta	qcode+1

	lda	arg0
	sta	arrayptr
	lda	arg1
	sta	arrayptr+1
	bne	..spl3
; LDA arrayPtr
; BNE ..SPL3

	lda	qcode
	cmp	memtop
	lda	qcode+1
	sbc	memtop+1
	bcs	..spl5

..splrtn	rts	

..spl4	jsr	getcdoff	; no main PROC
	sta	$02e2
	stx	$02e3
	jsr	stmtlist
	cmp	#eofid
	beq	..rtn

;EndErr LDY #0
; STY $2E3 		; zap run address
enderr	ldy	#ender
	jmp	fierr

..spl5	jmp	cderr		; out of qcode space



$eject
;=====================================
;	Declaration processing
;=====================================
; <dcl list> ..:= <dcl list> <dcl> | <dcl>
; <dcl> ..:= <simple dcl> | <array dcl> | <def dcl>

	proc	
..cderr	lda	#0		; reset qcode before err
	tay	
	jsr	loadcd
..derr	jmp	dclerr

..type	lda	#record-(vart-char)-1
	sta	type
	jsr	makeentry
	lda	addr
	ldx	addr+1
	ldy	#2
	jsr	savstk
	ldy	#0
	jsr	savecd
	jsr	getnext
	cmp	#equalid
	bne	..derr
	jsr	getnext
	cmp	#lbrack
	bne	..derr
	sec	
	lda	#0
	sbc	codeoff
	sta	qcode
	lda	#0
	sbc	codeoff+1
	sta	qcode+1
	jsr	getnext
..t1	cmp	#char
	bcc	..cderr
	cmp	#define
	bcs	..cderr
	tax	
	clc	
	adc	#typet-vart
	sta	type
	lda	varsize-char,x
	sta	afcur
..t2	jsr	makeentry
	lda	afcur
	jsr	codeincr
	jsr	getnext
	cmp	#comma
	beq	..t2
	cmp	#rbrack
	bne	..t1
	ldy	#2
	jsr	stkp
	ldx	qcode+1
	bne	..cderr
	lda	qcode
	ldy	#0
	jsr	storprops
	lda	#0
	tay	
	jsr	loadcd
	jsr	getnext

declare	jsr	dclend
	cmp	#char
	bcs	..dcl0
..drtn	rts	

..dcl0	cmp	#typeid
	beq	..type

	cmp	#record
	bne	..dcl1

			; record dcl.
	lda	#0
	jsr	getprop
	stx	afcur
	ldx	nxttoken
	lda	#typet-(vart-char)-1
	sta	type
	bne	..dcl2		; uncond.

..dcl1	cmp	#define
	beq	..define
	bcs	..drtn
	sta	type
	tax	
	ldy	varsize-char,x
	sty	afcur
	ldx	nxttoken
	cpx	#func
	beq	..drtn
	cpx	#array
	beq	..arrdcl
..dcl2	cpx	#pointer
	bne	..sdcl
	ldy	#0
	sty	afcur
	beq	..arrdcl	; uncond.


; <simple dcl> ..:= <type> <id eq list>
; <id eq list> ..:= <id eq list> , <id eq> | <id eq>
; <id eq> ..:= <id> (= <constant>)

..sdcl	jsr	makeentry

	ldx	param
	beq	..sdcl0
	jsr	params
	ldx	param
	bpl	..sdcl1
	bmi	..sdcl2

..sdcl0	lda	nxttoken
	cmp	#equalid
	bne	..sdcl1
	jsr	ideq
	iny	
	jsr	storprops
	jsr	getnext
	bne	..sdcl2

..sdcl1	lda	afcur
	jsr	codeincr

..sdcl2	jsr	getnext
	cmp	#comma
..sdcl3	beq	..sdcl
	jmp	declare


; <def dcl> ..:= DEFINE <def list>
; <def list> ..:= <def list> , <def> | <def>
; <def> ..:= <id> = <str const>

..define
	jsr	makeentry
	ldy	#0
	lda	#defid
	sta	(props),y
	jsr	getnext
	cmp	#equalid
	bne	dclerr
	lda	nxttoken
	cmp	#quote
	bne	dclerr
	ldy	#0
	lda	(symtab),y
	clc	
	adc	#2		; real size + EOL
	jsr	stincr
	jsr	getnext		; string itself
	jsr	getnext		; dummy string
	jsr	getnext
	cmp	#comma
..def1	bne	..sdcl3
	beq	..define

dclerr	ldy	#dcler
	jmp	splerr

; <array dcl> ..:= <type> ARRAY <array list>
; <array list> ..:= <array list> , <array> | <array>
; <array> ..:= <id> ((<constant>)) (= <constant>)

..arrdcl
	clc	
	adc	#8
	sta	type
	jsr	getnext
..arrd1	jsr	makeentry
	lda	#2
	sta	numargs		; variable space

	ldx	param
	bne	..arrd5

	lda	nxttoken
	ldx	afcur
	beq	..arrd2		; no size for pointers

	cmp	#lparen
	bne	..arrd2
	lda	#4
	sta	numargs
	lda	arrayptr
	ldx	arrayptr+1
	ldy	#0
	jsr	storevar
	jsr	getarsz
	jsr	getnext

			; check for small byte array
	ldy	#2
	lda	#0
	cmp	(qcode),y
	iny	
	lda	#1
	sbc	(qcode),y
	bcs	..arrd6		; size <= 256

..ard2a	jsr	getnext
	cmp	#rparen
	bne	dclerr
	lda	nxttoken
	cmp	#equalid
	beq	..ard2c

..arrd3	lda	numargs
	bne	..ard3a
			; small array
	ldy	#2
	lda	(qcode),y
	bne	..ard3b
	inc	qcode+1
	bne	..arrd4		; uncond.

			; array var
..ard3a	cmp	#4
	bmi	..ard3b

			; large array with memory
	ldx	qcode
	stx	arrayptr
	 ldx	qcode+1
	 stx	arrayptr+1

..ard3b	jsr	codeincr

..arrd4	jsr	getnext
	cmp	#comma
	beq	..arrd1
	jmp	declare

..arrd5	jsr	params
	ldx	param
	bpl	..arrd3
	bmi	..arrd4

..arrd2	cmp	#equalid
	bne	..arrd3
..ard2c	jsr	ideq
	ldy	numargs
	beq	..ard2b
	ldy	#0
	jsr	storevar
	jsr	getcdoff
..ard2b	ldy	#1
	jsr	storprops
	jsr	getnext
	lda	numargs
	jmp	..ard3b

..arrd6	ldy	#0
	lda	(props),y
	cmp	#arrayt+intt
	bcs	..ard2a
			; small byte array
	sty	numargs
	ora	#8
	sta	(props),y
	iny	
	jsr	getcdoff
	jsr	storprops
	bne	..ard2a		; uncond.


chkparam
	ldx	param
chkp	beq	derr
	pla	
	pla	
	jmp	getnext


;=========================
;	MakeEntry()
;	-----------
makeentry proc
	lda	nxttoken
	cmp	#undec
	beq	..me1
	bcs	..mev		; var of some kind

	cmp	#record
	beq	..mev

	cmp	#typet
	bcc	chkparam
	cmp	#eofid
	bcs	chkparam

..mev	lda	qglobal
	beq	chkp
	jsr	gnlocal
	cmp	#undec
	beq	..me0
derr	jmp	dclerr

..me0	sta	nxttoken
..me1	lda	#0
	jsr	nxtprop
	sec	
	lda	#vart-char
	adc	type
	sta	(props),y	; type
	and	#7
	tax	
	lda	vartype-1,x
	sta	op

	iny	
	jsr	getcdoff
	jsr	storprops
	jmp	getnext
	endproc


;=====================
;	IdEq()
;	------
ideq	proc
	jsr	getnext
	ldx	param
	bne	perr
	jmp	mnum
	endproc


;	GetArSz()
;	---------
getarsz	proc
	jsr	ideq
	sty	arg0		; Y should = 0
	sty	arg1
	ldy	afcur		; #elements * element size
..gas	clc	
	lda	arg0
	adc	afsize
	sta	arg0
	lda	arg1
	adc	afsize+1
	sta	arg1
	dey	
	bne	..gas
	tax	
	lda	arg0
	ldy	#2
	jmp	storevar
	endproc


;	StorProps(low, high, index)
;	---------------------------
storprops proc	
	sta	(props),y
	txa	
	iny	
	sta	(props),y
	rts	
	endproc


;ChkNext PROC ; ChkNext()
; LDA nxtToken
; CMP #undec
; BNE ..ChkN
; JSR GNlocal
;:ChkN JMP GetNext


;	Params()
;	--------
params	proc
	ldy	#0
	lda	(props),y	; get var type
	pha	
	lda	#3
	jsr	cprop
	cmp	#8
	bcs	perr
	adc	#1
	sta	(props),y
	tay	

			; see if time to update gbase
	ldx	nxttoken
	cpx	#rparen
	bne	..p1
			; see AMPL.SEG
	clc	
	adc	gbase
	sta	gbase
	bcc	..p1
	inc	gbase+1

..p1	pla	
	bmi	..par1
	cmp	#typet+8
	beq	..par2

perr	jmp	argerr

;:Par1 CMP #varT+realT
; BEQ PErr

..par1	cmp	#vart+intt
	bcc	..par3		; one byte arg
				; two byte arg
..par2	and	#$1f
	inc	argbytes

..par3	and	#$9f
	inc	argbytes
	sta	(props),y
	rts	
	endproc

varsize	db	1,1,2,2,2,6


$eject
;====================================
;	Statement processing
;====================================

; <stmt list> ..:= <stmt list> <stmt> | <stmt>
; <stmt> ..:= <assign> |
;            <array assign> |
;            <if> |
;            <for> |
;            <while> |
;            <do> |
;            <call> |
;            <return> |
;            EXIT

stmtlist proc	
	jsr	clrtemps
	sta	op
	jsr	smtend

	cmp	#lbrack
	bne	..sl5

			; machine qcode block
	jsr	trashy
..sl1	ldx	nxttoken
	cpx	#rbrack
	beq	..sl4
	jsr	mnum
	cpx	#0
	beq	..sl2
	jsr	push2		; 2 byte number
	bcs	..sl3		; uncond.

..sl2	jsr	push1		; single byte
..sl3	jsr	getnext
	bne	..sl1		; uncond.

..sl4	jsr	getnext
	jmp	nxtstmt

..sl5	ldx	nxttoken
	cmp	#vart+chart
	bcc	..sl6
	cmp	#funct
	bcc	assign
				; routine reference
	cpx	#lparen
	beq	call
	jsr	procref
	bne	ass0		; uncond.

..sl6	cmp	#undec
	bne	..sl7
	jsr	getalias
	bne	..sl5		; uncond.

..sl7	cmp	#typet
	bne	..sl8
	jsr	etype
	jmp	arass1

..sl8	cmp	#typet+8
	bne	..sl9
	jsr	etypea
	jmp	arass1

..sl9	ldx	#low stmtlst
	ldy	#high stmtlst
	jmp	lookup


; <call> ..:= <proc var>((<arglist>))
; <proc var> ..:= <id>
; <arglist> ..:= <arglist> , <exp> | <exp>

call	proc	
	jsr	pf
	jsr	popst
	jmp	nxtstmt


; <assign> ..:= <id> = <exp>

assign	proc	
	cmp	#arrayt
	bcs	arassign
ass0	jsr	pushnext
ass1	eor	#equalid
	bne	asserr
	jsr	pushop		; push 0 on op stack
	jsr	getnext
	sta	op
	cmp	#equalid
	bne	..ass2
	lda	#0
	sta	op
	jsr	copyst
				; check for temps
	iny	
	and	#$f8
	cmp	#arrayt+8
	bne	..a1a
	ldy	#3
	lda	(stack),y
..a1a	and	#$20
	beq	..a1b
	iny	
	lda	(stack),y
	tax	
				; incr temps
	cpx	#args		;
	bcc	..a1b		; are these 4 instr.
	cpx	#args+16	; needed?
	bcs	..a1b		;
	inc	temps-args,x
..a1b	jsr	getnext
..ass2	jsr	exp1
	jsr	cgassign
	jmp	stmtlist


asserr	ldy	#asser
	jmp	splerr


; <array assign> ..:= <id> ( <exp> ) = <exp>

arassign	proc	
	jsr	arrref
arass1	ldy	#0
	lda	(stack),y
	bpl	..ara1		; record element
	cmp	#vart
	bcc	asserr		; const
..ara1	jsr	getnext
	bne	ass1		; uncond.


; <if> ..:= IF <exp> THEN <stmt list
;          (ELSE <stmt list>) FI

ifstmt	proc	
	lda	#7
	jsr	getframe

	ldy	#5
	lda	#0
	sta	(frame),y

..if	jsr	condexp
	cmp	#then
	bne	thnerr
				; save current Y
	lda	cury
	ldy	#6
	sta	(frame),y

	jsr	nxtstmt

				; restore Y
	tax	
	ldy	#6
	lda	(frame),y
	sta	cury
	txa	

	cmp	#elseif
	bne	..else
	ldy	#4
	jsr	fadr1
	ldy	#4
	jsr	fcd1
	ldx	arg4
	ldy	arg5
	jsr	pushjmp
	jsr	frameadr
	jsr	fjmp1
	jmp	..if

..else	cmp	#else
	bne	..fi
	jsr	frameadr
	jsr	framecd
	ldy	#0		; flag as end of list
	jsr	pushjmp
	jsr	fjmp1
	jsr	nxtstmt

..fi	ldy	#fier
	cmp	#fi
	bne	fierr
	ldy	#4
	jsr	fadr1
	beq	if1		; if no ELSEIF
	jsr	fjmp1
if1	jsr	trashy
	jsr	frameadr
	beq	recret		; in case of DO loop
	jsr	fjmp1


;	RecRet() pops stack and returns
;	-------------------------------
recret	proc	
	jsr	freeframe
nxtstmt	jsr	getnext
	jmp	stmtlist
	endproc


;	pops stack
;	----------
freeframe proc	
	ldy	#0
	lda	(frame),y
	tax	
	iny	
	lda	(frame),y
	stx	frame
	sta	frame+1
	rts	


thnerr	ldy	#thener
sterr	jmp	splerr


; <do> ..:= DO <stmt list> (UNTIL <exp>) OD

dostmt	proc	
	jsr	doinit
	lda	#0
	ldy	#3
	sta	(frame),y
	bne	wh1		; uncond.


fierr	cmp	#undec
	bne	sterr
	jmp	varerr


; <while> ..:= WHILE <exp> <do>

whstmt	proc	
	jsr	doinit
	jsr	condexp

	ldy	#doer
	cmp	#do
	bne	sterr

wh1	jsr	nxtstmt

wh2	cmp	#untilid
	bne	..wh3
	jsr	condexp
	bne	..wh4		; uncond.

..wh3	ldy	#4
	jsr	fadr1
	jsr	pushjmp
	lda	token

..wh4	ldy	#oder
	cmp	#od
	bne	fierr

	ldy	#6
	jsr	fadr1
	stx	whaddr
	sty	whaddr+1
	jmp	if1
	endproc


;	EXITstmt()
;	----------
exitstmt proc
	ldy	#exiter
	ldx	whaddr+1
	beq	sterr

	ldy	#2		; get pointer to EXIT list
	lda	(whaddr),y
	tax	
	iny	
	lda	(whaddr),y
	pha	

	lda	qcode+1		; link in JMP for EXIT
	sta	(whaddr),y
	lda	qcode
	dey	
	sta	(whaddr),y

	pla	
	tay	
	jsr	pushjmp
	jmp	nxtstmt



; <for> ..:= FOR <id> = <exp> TO <exp>
;             (STEP <exp>) <do>

forerr	ldy	#forer
	bne	fierr


forstmt	proc	
	lda	#23
	jsr	getframe

	jsr	whadr
				; make sure simple var for index
	jsr	getnext
	cmp	#vart+chart
	bcc	forerr
	cmp	#arrayt
	bcc	..fs1
	cmp	#arrayt+realt
	bcs	forerr
	lda	#vart+cardt
	sta	token
				; get initial value
..fs1	ldy	#8
	sta	(frame),y
	iny	
	lda	addr
	ldx	addr+1
	jsr	fcd2
	jsr	pushnext
	cmp	#equalid
	bne	forerr
	jsr	getexp
	jsr	cgassign
				; set default STEP size
	lda	token
	cmp	#to
..f1	bne	forerr
	lda	#0
	ldx	#9
	ldy	#12
..fz	sta	(frame),y
	iny	
	dex	
	bne	..fz

	ldy	#8
	jsr	fstk
	lda	token
	and	#7
	ora	#constt
	ldx	#1
	ldy	#11
	jsr	fcd2
				; get ending value
	lda	#16
	jsr	forexp
				; get step value
	lda	token
	cmp	#step
	bne	..fnostep
	lda	#11
	jsr	forexp
	lda	token

..fnostep	cmp	#do
	bne	..f1
				; generate end test
	jsr	getcdoff
	ldy	#4
	jsr	fcd2
	jsr	trashy

	jsr	gops
	ldy	#16
	lda	(frame),y
	cmp	#vart
	bcs	..f3		; temp variable
				; constant
	iny	
	lda	(frame),y
	tax	
	lda	#$a9
	jsr	push2		; LDA #low
	lda	#$c1		; CMP
	jsr	op2l
	lda	arg3
	beq	..fbody
	ldy	#18
	lda	(frame),y
	tax	
..f2	lda	#$a9
	jsr	push2		; LDA #high
	jmp	..f4

..f3	ldy	#17
	sty	arg0
	lda	#$ad		; LDA addr16
	jsr	fexp2
	lda	#$c1		; CMP
	jsr	op2l
	lda	arg3
	beq	..fbody
	ldx	#0
	ldy	#16
	lda	(frame),y
	cmp	#vart+intt
	bcc	..f2		; only byte var
	lda	#$ad		; LDA addr16
	jsr	fexp2
..f4	lda	#$e1		; SBC
	jsr	op2h

..fbody	lda	arg3
	ror	a		; get type
	lda	#$b0		; BCS, CARD
	bcc	..f5
	lda	#$10		; BPL, INT
..f5	jsr	push1
	ldy	#21
	jsr	fcd1
	jsr	push1
	jsr	popst

	jsr	framecd
	ldy	#0
	jsr	pushjmp
				; save space for vars
	ldy	#16
	jsr	fmem
	ldy	#11
	jsr	fmem
				; handle symtab
	ldy	#11
	lda	(frame),y
	cmp	#vart
	bcc	..f6
	lda	symtab
	ldx	symtab+1
	iny	
	jsr	fcd2
	lda	#0
	tay	
	sta	(symtab),y
	lda	#4
	jsr	stincr
				; patch branch
..f6	ldy	#21
	jsr	fadr1
	jsr	comprel
				; handle stmt list
	jsr	nxtstmt
				; handle incr
	pha			; save token
	ldy	#8
	jsr	fstk
	jsr	copyst
	ldy	#11
	jsr	fstk
	lda	#plusid
	jsr	cgplus
	lda	arg5
	beq	..f7
	jsr	chstkeq		; see if INC
..f7	pha	
	jsr	cgassign
	pla	
	beq	..f8		; not INC
				; see if we can branch to top of loop
	pla	
	cmp	#untilid
	beq	..f9		; can't go to top of loop
	pha	

	clc	
	ldy	#4
	lda	(frame),y
	sbc	stkbase-9	; see CGPlus
	bpl	..f8
	tax	
	iny	
	lda	(frame),y
	sbc	stkbase-8
	cmp	#$ff
	bne	..f8		; yes, branch to top
	lda	stkbase-9
	sta	arg0
	lda	stkbase-8
	sta	arg1
	ldy	#0
	txa	
	sta	(arg0),y
..f8	pla	
..f9	sta	token
	jmp	wh2


forexp	proc	
	pha	
	jsr	getexp
	jsr	gops
	pla	
	sta	arg0
	jsr	..fe0
	jmp	popst

..fe0	lda	arg1
	cmp	#vart		; see if const
	bcs	..fe1
				; constant
	ldy	#11
	lda	(frame),y
	ldy	arg0
	sta	(frame),y
	ldy	#2
	jsr	loadi
	ldy	arg0
	iny	
	jmp	fcd2

..fe1	ldy	#8
	lda	(frame),y
	and	#7
	cmp	#intt
	bmi	..fe2
	lda	arg1
	and	#7
..fe2	ora	#vart
	ldy	#1
	sta	(symtab),y
	sta	arg2
	ldy	arg0
	sta	(frame),y
	inc	arg0

	lda	arg1
	bit	arrmode		; array?
	bne	..fevar		; yes
	bit	tempmode	; temp?
	bne	..ftemp		; yes
				; var of some kind
..fevar	jsr	load2l
	jsr	fexp1
	lda	arg2
	cmp	#vart+intt	; see if byte
	bcc	..fe3
	jsr	load2h
fexp1	lda	#$8d		; STA data16
fexp2	pha	
	ldy	arg0
	jsr	fadr1
	ldy	arg0
	jsr	fcd1
	iny	
	sty	arg0
	pla	
	ldx	arg4
	ldy	arg5
	jmp	push3

..fe3	rts	

..ftemp	ldy	#4
	jsr	loadi
	ldy	#1
	jsr	addcdsp
	ldy	#3
	lda	#0
	jsr	..ft1
	lda	arg2
	cmp	#vart+intt	; see if byte
	bcc	..fe3
	ldy	#5
	lda	#1
..ft1	jsr	loadcd
	jmp	fexp1


fmem	lda	(frame),y
	cmp	#vart
	bcc	..fe3		; const
	sty	arg2
	jsr	getcdoff	; save address for step
	ldy	#2
	sta	(symtab),y
	txa	
	iny	
	sta	(symtab),y
	ldy	arg2
	jsr	..fm1
	ldy	arg2
	lda	(frame),y
	cmp	#vart+intt
	bcc	..fe3		; byte only
	iny	
	iny	
..fm1	iny	
	jsr	fadr1
	jsr	fjmp1
	lda	#1
	jmp	codeincr


fstk	lda	(frame),y
	sta	token
	iny	
	jsr	fadr1
	stx	addr
	sty	addr+1
	jmp	pushst


doinit	proc	
	lda	#8
	jsr	getframe
	jsr	whadr
	jsr	getcdoff
	ldy	#4
	jsr	fcd2
	jmp	trashy



; <return> ..:= RETURN ((<exp>))

retstmt	proc	
	lda	#0
	jsr	cprop
	and	#7
	beq	..r1
	ora	#tempt
	tay	
	lda	#args
	jsr	storst
	ldx	nxttoken
	cpx	#lparen
	bne	reterr
	jsr	getnext
	jsr	getexp
	cmp	#rparen
	bne	reterr
	jsr	cgassign
..r1	lda	#$60
	jsr	push1
	jmp	nxtstmt

reterr	ldy	#reter
	jmp	splerr


condexp	proc			; CondExp()
	jsr	getexp
	pha	
	ldy	#0
	lda	(stack),y
	cmp	#condt
	beq	..cexp1
				; not boolean
	jsr	zerost
	lda	#neid
	jsr	codegen

..cexp1	pla			; token value
	pha	
	cmp	#od
	bne	..cexp2
				; until <exp> od
	ldy	#1
	jsr	stkaddr
	beq	..ce1a		; no JMPs
				; JMP to JMP to top of loop
				; yek!, should be improved
	jsr	filljmp		; fill in jmps

..ce1a	ldy	#4
	jsr	fadr1
	bne	..cexp3		; uncond.

..cexp2	jsr	framecd
	ldy	#1
	jsr	stkaddr

..cexp3	jsr	pushjmp

				; fill in branch addresses
	ldy	#4
	jsr	fillbr
	jsr	popst
	pla			; get token value
	rts	


whadr	proc	
	lda	whaddr
	ldx	whaddr+1
	ldy	#6
	jsr	fcd2
	lda	frame
	sta	whaddr
	lda	frame+1
	sta	whaddr+1
	rts	


fillbr	proc			; FillBr(,,offset)
	jsr	setrel
..fb1	jsr	savrel
	jsr	comprel
	jsr	loadn
	bne	..fb1
	rts	


frameadr	proc		; FrameAdr()
	ldy	#2
fadr1	lda	(frame),y
	tax	
	iny	
	lda	(frame),y
	tay	
fadr2	stx	arg4
	sty	arg5
	rts	

framecd	proc			; FrameCd()
	ldy	#2
fcd1	lda	qcode
	ldx	qcode+1
fcd2	sta	(frame),y
	iny	
	txa	
	sta	(frame),y
	rts	


filljmp	proc			; FillJmp(,addr)
	jsr	fadr2
fjmp1	jsr	saven
	jsr	getcdoff
	jsr	save4
	jsr	loadn
	bne	fjmp1
	rts	


save4	proc			; Save4(value)
	sta	(arg4),y
	iny	
	txa	
	sta	(arg4),y
	rts	


saven	proc			; SaveN()
	ldy	#1
	lda	(arg4),y
	sta	arg0
	iny	
	lda	(arg4),y
	sta	arg1
	dey	
	rts	


loadn	proc			; LoadN()
	lda	arg0
	ldx	arg1
	beq	..ln2		; is this needed anymore?
ln1	sta	arg4
	stx	arg5
..ln2	rts	


pushjmp	proc			; PushJMP(, addr)
	lda	#$4c		; JMP addr16
	jmp	push3


getframe	proc		; GetFrame(size)
	sta	arg0
	ldy	frame
	ldx	frame+1
	sec	
	tya	
	sbc	arg0
	sta	frame
	txa	
	sbc	#0
	sta	frame+1
	lda	frame
	cmp	sparem
	lda	frame+1
	sbc	sparem+1
	bcc	nsterr
	tya	
	ldy	#0
	jmp	fcd2

nsterr	ldy	#nster
	jmp	splerr


setrel	proc			; SetRel(,,offset)
	jsr	loadi
	jmp	ln1


savrel	proc	
	ldy	#0
	ldx	#0
	lda	(arg4),y
	beq	..sr2
	bpl	..sr1
	dex			; sign extend
..sr1	clc	
	adc	arg4
	sta	arg0
	txa	
	adc	arg5
..sr2	sta	arg1
	rts	


comprel	proc	
	lda	qcode
crel1	clc			; extra -1 for offset byte
crel2	sbc	arg4
	ldy	#0
	sta	(arg4),y
	rts	


clrtemps	proc	
	lda	#0
	ldx	#16
..sl0	sta	temps-1,x
	dex	
	bne	..sl0		; free temps
	rts	


stmtlst	dw	smtend		; not found
	db	20		; #entries*3 - 1
	dw	ifstmt
	db	ifid
	dw	forstmt
	db	forid
	dw	whstmt
	db	whileid
	dw	retstmt
	db	retid
	dw	dostmt
	db	do
	dw	exitstmt
	db	exitid


$eject
;=====================================
;	Expression processing
;=====================================

; <exp> ..:= <exp> XOR <equiv> | <equiv>
; <equiv> ..:= <equiv> OR <logical prod> | <logical prod>
; <logical prod> ..:= <logical prod> AND <relation> | <relation>
; <relation> ..:= <relation> <rel op> <add exp> | <add exp>
; <add exp> ..:= <add exp> <add op> <mult exp> | <mult exp>
; <mult exp> ..:= <mult exp> <mult op> <factor> | <factor>
; <factor> ..:= <unary op> <primary> | <primary>
; <primary> ..:= <constant> | <var> | ( <exp> )

; <rel op> ..:= # | = | <high  | < | high  | <= | high =
; <add op> ..:= + | -
; <mult op> ..:= * | / | LSH | RSH | REM
; <unary op> ..:= @ | -

;	GetExp()
;	--------
getexp	proc
	$if	ramzap
	 inc	cgopscd
	$else	
	 nop	
	 nop	
	 nop	
	$endif	
	jsr	getnext


exp	proc	
	lda	#0
	jsr	pushop
	lda	token		; always non-zero
	sta	op

exp1	jsr	expend
	cmp	#scolon
	bcc	..expop

	cmp	#rparen
	bne	..exp2
	ldx	op
	bne	eerr
	jsr	rollops
	cmp	#lparen
	beq	..exp7
	lda	token
	rts	

..exp2	cmp	#lparen
	bne	..exp3
	ldx	op
	bne	..exp6

eerr	jmp	experr

..exp3	ldx	op
	beq	..exp8
	ldx	#0
	stx	op
	cmp	#quote
	beq	..expstr

..exp3a	ldx	nxttoken
	cmp	#record
	beq	..exp3d		; record
	cmp	#typet
	bcc	eerr
	bne	..exp3c
..exp3b	jsr	etype
	bne	..exp7		; uncond.

..exp3c	cmp	#typet+8
	bcc	..exp3d		; field
	bne	..exp3e
	jsr	etypea
	jmp	..exp7

				; record name or field
..exp3d	cpx	#period
	bne	..exp3b
				; will generate error if falls through

..exp3e	cmp	#constt
	bcc	eerr		; missing operand?
	cmp	#arrayt
	bcs	..exp4		; array or func

	cmp	#undec
	beq	..expund
	cmp	#constt+realt
	beq	eerr		; real constant

..expvar
	jsr	pushnext
	bne	exp1		; uncond.

..exp4	cmp	#funct
	bcs	..expproc

..exparr
	jsr	arrref
	jmp	..exp7

..expop	ldx	op
	beq	..exp5
	cmp	#atid
	beq	..exp5
	cmp	#minusid
	bne	eerr
	lda	#uminusid
	sta	token
..exp5	tax	
	lda	prec-1,x
	sta	op
	jsr	rollops
	jsr	pushop
	lda	token
..exp6	jsr	pushop
..exp7	jsr	getnext
	jmp	exp1

..exp8	jsr	rollops
	cmp	#lparen
	beq	parenerr
..exp9	lda	token
	rts	

..expund
	jsr	getalias
	bne	..exp3a		; uncond.

..expproc
	bne	..expfunc
..expp1	jsr	procref
	bne	..expvar	; uncond.

..expstr
	lda	#$4c		; JMP around string
	jsr	push1
	jsr	getcdoff
	adc	#3		; includes size byte
	bcc	..es1
	 inx	
	 clc	
..es1	ldy	#0
	adc	(addr),y	; size
	bcc	..es2
	 inx	
..es2	jsr	push2

	jsr	copystr
	ldy	#constt+strt
	jsr	storst
	dec	choff
	jsr	getnext
	bne	..exp7		; uncond.


parenerr
	ldy	#parer
	jmp	splerr

				; qcode to handle function ref
..expfunc
	cmp	#funct+8
	beq	..expp1
	cpx	#lparen
	bne	..expp1
	lda	#17
	jsr	getframe

	ldy	#16
	lda	op
	sta	(frame),y
				; save temps
	sty	arg0
	lda	#args+15
	sta	arg1
..ef1	dec	arg0
	ldy	arg0
	lda	temps,y
	sta	(frame),y
	beq	..ef2
	lda	#$a5		; LDA addr
	ldx	arg1
	ldy	#$48		; PHA
	jsr	push3
	ldy	arg0
..ef2	dec	arg1
	cpy	#2
	bne	..ef1

	lda	temps
	bne	experr		; nested functions
	jsr	clrtemps

	jsr	pf		; call the function

				; restore temps
	ldy	#1
	sty	temps		; flag result reg.
	sty	arg0
	lda	#args+2
	sta	arg1
..ef3	inc	arg0
	ldy	arg0
	lda	(frame),y
	sta	temps,y
	beq	..ef4
	lda	#$68		; PLA
	ldx	#$85		; STA addr
	ldy	arg1
	jsr	push3
	ldy	arg0
..ef4	inc	arg1
	cpy	#15
	bne	..ef3

	iny	
	lda	(frame),y
	sta	op

	jsr	freeframe

				; set result type
	ldy	#0
	lda	(stack),y
	and	#7
	ora	#tempt
	ldx	#args
	jsr	savstk
	jmp	..exp7


;:ExpReal LDX vars
; LDY vars+1
; JSR FST0R
; LDA varsOff
; LDX varsOff+1
; JSR SST1
; LDA #6
; JSR VarIncr
; JMP ..Exp7

experr	ldy	#exper
eerr1	jmp	splerr


popop	proc			; PopOp()
	dec	stackptr
	bmi	experr		; this should never happen
	ldy	stackptr
	lda	opstack,y
	rts	


zerost	proc	
	lda	#0
	tax	
	ldy	#constt+bytet


storst	proc			; StorST(addr16,token)
	sty	token
sst1	sta	addr
	stx	addr+1


pushst	proc			; PushST()
	sec	
	lda	stack
	sbc	#7
	sta	stack
	bcc	experr
	ldy	#0
	lda	token
	sta	(stack),y
	iny	
	lda	addr
	ldx	addr+1
	jmp	savstk


etypep	proc	
	jsr	pushst
	jsr	getnext
	jsr	getnext
	ldy	#0
	sta	(stack),y
	tax	
	and	#$f8
	ldy	#typer
	cmp	#typet
	bne	eerr1
	txa	
	and	#7
	beq	eerr1
	sta	token
				; get offset
	lda	#1
	jmp	getprop


etype	proc	
	cpx	#period
	beq	..e1
				; record addr, size or field offset
				; A reg must be nonzero before call
	jmp	arrconst

..e1	jsr	etypep		; set type
				; get var address
	ldy	#1
	jsr	stkps
	tya	
	ldy	#2
	sta	(stack),y
	dey	
	txa	
	sta	(stack),y
	rts	

	proc	

etypea	proc	
	cpx	#period
	beq	..e1
	jmp	arrvar

..e1	jsr	etypep		; set type
	tay	
	lda	token
	pha	
	tya	
	ldy	#constt+bytet
	jsr	storst
	lda	#arrayt+bytet
	ldy	#7
	jsr	arra0
	ldy	#0
	pla	
	ora	#$b0		; temp array
	sta	(stack),y
	rts	


procref	proc	
	ldy	#funct+cardt	; make sure CARD
	cmp	#funct+8
	bcc	..pr1
stconst	jsr	getargs		; A#0, no arg types
	ldy	#constt+cardt	; sys proc
..pr1	sty	token
	rts	


copyst	proc			; CopyST()
	lda	stack
	ldx	stack+1
	jsr	ln1

	jsr	pushst

	ldy	#6
..cst1	lda	(arg4),y
	sta	(stack),y
	dey	
	bpl	..cst1
	rts	


rollops	proc			; RollOps()
	jsr	popop
	beq	..rops1
	cmp	#lparen
	beq	..rops1
	tax	
	ldy	prec-1,x
	cpy	op
	bcc	..rops1		; prec < op
				; check for simple add
	ldy	op		; see if end of exp
	bne	..ro2
	ldy	stack
	cpy	#low (stkbase-21)
	bne	..ro2
	cpx	#plusid
	beq	..ro0
	cpx	#rshid
	beq	..ro0
	cpx	#lshid
	bne	..ro2
..ro0	jsr	popop		; see if last op
	bne	..ro1
				; check for increament
				; We know at least this is an
				; assignment or an array subscript.
				; If ChStkEq in CGPlus is true then
				; this is an assignment.
	txa	
	cmp	#plusid
	bne	..rosh
	jsr	cgplus
	lda	#0
	rts	

..rosh	jsr	cgsh
	lda	#0
	rts	

..ro1	jsr	pushop
	txa	
..ro2	jsr	codegen
	jmp	rollops

..rops1	rts	


popst	proc			; PopST()
	clc	
	lda	stack
	adc	#7
	sta	stack
	rts	


pushop	proc			; PushOp(op)
	ldy	stackptr
	inc	stackptr
	sta	opstack,y
	rts	


pushnext proc		; PushNext()
	jsr	pushst
	jmp	getnext
	endproc


prec	db	5,5,6,6,2,3,4,4,4,4,4,4
	db	6,1,6,6,7,7


$eject
;==============================
;	Code generation
;==============================

genops	proc			; GenOps(op)
	sta	arg0
gops	ldy	#0
	lda	(stack),y
	sta	arg1
	and	#7
	tax	
	lda	vartype-1,x
	sta	arg3
	asl	a
	asl	a
	sta	arg5
	ldy	#7
	lda	(stack),y
	sta	arg2
	and	#7
	tax	
	lda	vartype-1,x
	sta	arg4
	ora	arg5
	tax	
	lda	outtype,x
	sta	arg6		; high bit on for card.
	and	#7		; get rid of flag bits
	tax	
	ora	#tempt
	sta	arg7
	lda	vartype-1,x
	sta	arg5		; output type

	jmp	push0


cgsh	proc	
	jsr	chasseq
	beq	cg1
..cgs1	lda	stkbase-20
	beq	..cgs5		; no shift!
	cmp	#5
	bcs	cg1		; too large a shift
				; whew!, we can now shift it
	ldy	arg0
	cpy	#rshid
	beq	..cgs2		; right shift
	lda	#$06		; ASL
	jsr	op1l
	lda	arg4
	beq	..cgs4
	lda	#$26		; ROL
	jsr	op1h
	jmp	..cgs4

..cgs2	lda	#$46		; LSR
	ldx	arg4
	beq	..cgs3
	jsr	op1h
	lda	#$66		; ROR
..cgs3	jsr	op1l

..cgs4	dec	stkbase-20
	bne	..cgs1
..cgs5	jmp	popst


codegen	proc			; CodeGen(op)
	jsr	genops
cg1	jsr	cgend
	lda	arg0
	asl	a
	clc	
	adc	arg0
	tay	
	lda	cgops-3,y
	sta	arg8
	lda	cgops-2,y
	ldx	cgops-1,y
	jmp	jsrind		; jmp to qcode for op


cgplus	proc			; CGPlus()
	jsr	chasseq
	beq	cg1
	lda	stkbase-20
	cmp	#1		; see if const = 1
	bne	cg1		; no
				; whew!, we can now increament it
	lda	#$e6		; INC
	jsr	op1l
	lda	arg4
	beq	..cga2		; byte var
	lda	#$d0		; BNE
	jsr	push1
	ldy	#12
	jsr	savecd
	lda	#0
	jsr	push1		; offset
	lda	#$e6		; INC
	jsr	op1h
	ldy	#13
	jsr	fillbr
..cga2	jmp	popst


cgexperr
	jmp	experr


cgassign	proc		; CGAssign()
	lda	#0
	jsr	genops
	jsr	cgend
	jsr	chstkeq		; see if INC
	bne	cga1		; yes, just return
	lda	arg1
	bpl	..ass1		; cond. exp. of record
	bit	tempmode	; rhs temp?
	bne	..cgat		; yes
	cmp	#vart		; const?
	bcs	..cgav		; no
				; rhs constant
	lda	arg2
	cmp	#arrayt		; simple var
	bcs	..cgav
				; if STY addr16,X was supported
				; BCC ..CGC0 ; yes
				; BIT tempMode ; lhs temp?
				; BNE ..CGAV ; yes, large array
..cgc0	ldx	arg4
	beq	..cgc1		; byte
	ldy	#2
	lda	(stack),y
	cmp	#2
	bcs	..cgavi
	sta	arg12
	jsr	loady
	lda	#$84		; STY
	jsr	op1h
..cgc1	ldy	#1
	lda	(stack),y
	cmp	#2
	bcs	..cgavb
	sta	arg12
	jsr	loady
	lda	#$84		; STY
	bne	..avb2		; uncond.

..ass1	cmp	#typet
	bcc	cgexperr	; cond. exp.

				; rhs var
..cgav	ldx	arg4		; lhs type=byte?
	beq	..cgavb		; yes
				; CPX #3	 ; lhs = int?
				; BNE ..CGAVI	 ; yes
				; lhs type = real
				; JMP AssErr
..cgavi	jsr	load2h
..avi1	lda	#$81		; STA
	jsr	op1h

..cgavb	jsr	load2l
..avb1	lda	#$81		; STA
..avb2	jsr	op1l

cga1	jsr	popst
	jmp	popst

..cgat	and	#$10		; rhs array?
	bne	..cgav		; yes

				; special case for arg0
	ldy	#1
	lda	(stack),y
	cmp	#args
	beq	..cgav		; function return value

	lda	arg4		; lhs byte?
	beq	..cgatb		; yes
				; int/card temp
	lda	arg2
	and	#$10		; array?
	bne	..cgata		; yes

	lda	arg3
	bne	..cgat1
				; rhs type is BYTE
	jsr	load2h		; generate LDA #0 instr.
	ldy	#5
	jsr	savecd

..cgat1	ldy	#4
	jsr	loadi
	ldy	#8
	lda	arg2
	and	#$60		; lhs proc or temp(argument)?
	bne	..cgat3		; yes
	jsr	stkpz
	beq	..cgat4		; page zero
	sty	arg13
	ldy	#1
	lda	#$8d		; STA addr16
	jsr	i30		; insert STA data16
	lda	#1
..cgat2	ldy	#5
	jsr	loadcd
	lda	#$81		; STA
	jsr	op1h
	jmp	cga1

..cgat3	and	#$40		; proc?
	bne	..cgavi		; yes, punt(not the best qcode)
	jsr	stkaddr		; temp (proc argument)
..cgat4	ldy	#1
	txa	
	sta	(arg14),y
	lda	#0
	beq	..cgat2
				; temp array
..cgata	lda	arg3
	beq	..cgavi
	ldy	#5
	jsr	ldcdz
	bne	..avi1		; uncond.

..cgatb	ldy	#3
	jsr	loadcd
	lda	arg3		; see if rhs BYTE or CHAR
	beq	..avb1		; yes
	jsr	trashy		; in case INT ARRAY in rhs
				; oh if I only had more qcode space!
				; could handle Y, see ..OpA in CGU
	bne	..avb1		; uncond.
	endproc


;	chasseq (mode)
;	--------------
chasseq	proc
	jsr	genops
	lda	arg1
	cmp	#vart		; see if const
	bcs	..cse2		; no
	lda	stkbase-19	; see if byte
	bne	..cse2		; no
				; see if left and right hand are =
;	JMP ChStkEq

chstkeq	ldx	#2
	lda	stkbase-7
	and	#$f8
	cmp	#$b0		; large array?
	beq	..cse2		; yes, can't INC or shift
	cmp	#arrayt+8	; small array?
	bne	..cse1		; no
	ldx	#5
..cse1	lda	stkbase-14,x
	cmp	stkbase-7,x
	bne	..cse2
	dex	
	bpl	..cse1
	rts	

..cse2	lda	#0
	rts	
	endproc


;	CGAdd()
;	-------
cgadd	proc
	lda	arg1
	bpl	..a3
	ora	arg2
	cmp	#vart		; see if both ops consts
	bcs	..a3		; not const
	lda	arg7
	and	#7
	ora	#constt
	sta	arg7
	ldy	#8
	ldx	arg8
	bne	..a1		; subtract constants
				; add constants
	clc	
	lda	(stack),y
	ldy	#1
	adc	(stack),y
	sta	arg9
	ldy	#9
	lda	(stack),y
	ldy	#2
	adc	(stack),y
	jmp	..a2

..a1	sec	
	lda	(stack),y
	ldy	#1
	sbc	(stack),y
	sta	arg9
	ldy	#9
	lda	(stack),y
	ldy	#2
	sbc	(stack),y

..a2	tax	
	beq	cgadd4
	lda	arg5
	bne	cgadd4
	lda	#constt+intt
	bne	cgadd5		; uncond.

				; normal add or sub.
..a3	ldx	arg8
	lda	cgopscd,x
	jsr	push1

cgadd1	jsr	gettemps

	jsr	load1l

	jsr	opcd1
	jsr	op2l

	jsr	stempl

	lda	arg5
	beq	cgadd3

	jsr	load1h

	jsr	opcd1
	jsr	op2h

cgadd2	jsr	stemph

cgadd3	ldx	#0
cgadd4	lda	arg7
cgadd5	ldy	#7
	sta	(stack),y
	iny	
	lda	arg9
	jsr	savstk
cgadd6	jmp	popst
	endproc


cgshift	proc	
	lda	arg5		; byte ?
	bne	cgmd		; no
	lda	arg1
	cmp	#vart		; see if constant
	bcs	cgmd		; no
	ldy	#1
	lda	(stack),y
	beq	cgadd6		; ignore shift
	cmp	#8		; shift high  7
	bcc	..s1		; no
	ldx	#0
	stx	arg9
	lda	#constt+bytet
	bne	cgadd5		; uncond.

..s1	sta	arg1
	lda	#$0a		; ASL A
	ldx	arg8
	beq	..s2
	lda	#$4a		; LSR A
..s2	sta	arg3
	jsr	gettemps
	jsr	load1l
..s3	lda	arg3		; shift Op
	jsr	push1
	dec	arg1
	bne	..s3
	jsr	stempl
	jmp	cgadd3
	endproc


cgmul	proc	
	lda	#tempt+intt	; force output to INT
	sta	arg5
	sta	arg7
	$if	ramzap
	sta	(adress),y
	$else	
	nop	
	nop	
	$endif	
cgdiv	jsr	load2h
	lda	#$85		; STA AFcur+1
	ldx	#afcur+1
	jsr	push2
cgmd	jsr	gettemps
	jsr	load2l
	lda	#$85		; STA AFcur
	ldx	#afcur
	jsr	push2
	lda	arg4
	beq	..md1		; first op byte
	jsr	load1h
	lda	#$aa		; TAX
	jsr	push1
..md1	jsr	load1l
	lda	arg4
	bne	..md2
	lda	#$a2		; LDX #0
	ldx	#0
	jsr	push2
..md2	ldx	arg8
	jsr	jsrtable
	jsr	stempl
	jsr	trashy
	lda	arg5
	beq	..md3
	lda	#$8a		; TXA
	jsr	push1
	jsr	stemph
..md3	jmp	cgadd3
	endproc


;	CGOr()
;	------
cgor	proc
	jsr	chkcond
	ldy	#12
	jsr	ldcdz
	ldy	#8
	jsr	stkaddr
	beq	..or1		; no JMPs
	jsr	filljmp

..or1	ldy	#5
	jsr	ldcdz
	ldy	#11		; link T2 to T1
	jsr	setrel
..or2	jsr	savrel
	jsr	loadn
	bne	..or2		; get end of T1
	ldy	#3
	lda	(stack),y
	sec	
	jsr	crel2		; patch in T2
	beq	and3		; uncond.


cgand	proc			; CGAnd()
	jsr	chkcond
	lda	stack
	ldx	stack+1
	jsr	ln1

..and1	jsr	saven		; patch addresses
	clc	
	lda	arg0
	adc	#3
	sta	(arg4),y
	iny	
	lda	(arg4),y
	adc	#0
	sta	(arg4),y
	jsr	loadn
	bne	..and1

	ldy	#13
	jsr	loadi
	ldy	#1
	jsr	save4		; link F1 to F2
	ldy	#8
	jsr	stkaddr
	lda	#$4c		; JMP
	jsr	insrt3		; patch in JMP false

	lda	qcode
	pha	
	clc	
	lda	arg14
	adc	#3
	sta	qcode
	ldy	#11
	jsr	fillbr		; make T1 -> Cond2
	pla	
	sta	qcode

	ldy	#4
	jsr	loadi
	clc	
	adc	#3
	bcc	..and2
	inx	
..and2	ldy	#10
	jsr	savstk

and3	ldy	#2
	jsr	loadi
	ldy	#8
	jsr	savstk

	ldy	#12
	jsr	savecd
	jsr	trashy		; just in case array in cond.
	jmp	popst		; done at last, whew!


chkcond	proc	
	lda	#condt
	cmp	arg1
	bne	..cc1
	cmp	arg2
	bne	conderr
	rts	

..cc1	pla	
	pla	
	jmp	cgadd1

conderr	ldy	#cnder
	jmp	splerr


cgeq	proc			; CGEq()
cgne	jsr	load1l
	jsr	chkzero
	beq	..cge0
	lda	#$41		; EOR
	jsr	op2l
..cge0	lda	arg5
	beq	cge2
	jsr	chkzero
	php			; save status
	beq	..cge1
	lda	#$d0		; BNE
	jsr	pushtrue
..cge1	lda	#$01		; ORA
	jsr	op1h
	plp			; ChkZero() status
	beq	cge2
	lda	#$41		; EOR
	jsr	op2h
	ldy	#11
	jsr	fillbr

cge2	jsr	opcd1
	jsr	pushtrue	; sets arg9 to zero
	lda	#condt
	sta	arg7
	ldy	#12
	jsr	savecd
	jmp	cgadd3


cgls	proc			; CGLS()
cgge	jsr	relop
	jsr	load1l
	lda	#$c1		; CMP
	jsr	op2l
	lda	arg5
	beq	cge2
	jsr	load1h
	lda	#$e1		; SBC
	jsr	op2h
	bcs	cge2		; uncond., see CodeIncr


cggr	proc			; CGGR()
cgle	jsr	relop
	jsr	load2l
	lda	#$c1		; CMP
	jsr	op1l
	lda	arg5
	beq	cge2
	jsr	load2h
	lda	#$e1		; SBC
	jsr	op1h
	bcs	cge2		; uncond., see CodeIncr


cgum	proc			; CGUM()
	lda	arg1
	and	#$78
	bne	..cgum1		; not constant
				; constant, just negate it
	sec	
	ldy	#0
	lda	#constt+intt
	sta	(stack),y
	sec	
	tya	
	iny	
	sbc	(stack),y
	sta	(stack),y
	iny	
	lda	#0
	sbc	(stack),y
	sta	(stack),y
	rts	

..cgum1	jsr	copyst
	ldy	#7
	lda	#constt+intt
	sta	(stack),y
	lda	#0
	tax	
	iny	
	jsr	savstk
	lda	#minusid
	jmp	codegen

	proc	

cgat	proc			; CGAt()
	lda	arg1
	cmp	#vart
	bcc	..cgat2
	cmp	#arrayt+8
	bcs	..cgaterr
	ldy	#1
	jsr	stkp
	iny	
	jsr	savstk
..cgat1	ldy	#0
	lda	#constt+cardt
	sta	(stack),y
	rts	

..cgat2	and	#$f8
	cmp	#typet		; check for record field
	beq	..cgat1
				; constant or cond. exp. (error)

..cgaterr	jmp	experr

	db	0		; for records!
vartype	db	0,0,1,2,2,3

; moved to CGU
;outtype .BYTE $82,3,$84,realT
; .BYTE 3,3,$84,realT
; .BYTE $84,$84,$84,realT
; .BYTE realT,realT,realT,realT

cgopscd	db	$18,$61		; CLC ADC
	db	$38,$e1		; SEC SBC
	db	$41,$21,$01	; EOR AND ORA
	db	$30,$90		; BMI BCC
	db	$10,$b0		; BPL BCS
	db	$f0,$d0		; BEQ BNE

cgops	db	0
	dw	cgadd
	db	2
	dw	cgadd		; minus
	db	4
	dw	cgmul		; multiply
	db	6
	dw	cgdiv		; divide
	db	5
	dw	cgor
	db	4
	dw	cgand
	db	10
	dw	cgeq
	db	11
	dw	cgne
	db	6
	dw	cggr
	db	8
	dw	cgge
	db	6
	dw	cgls
	db	8
	dw	cgle
	db	8
	dw	cgdiv		; remainder
	db	3
	dw	cgadd1		; XOR
	db	0
	dw	cgshift		; LSH
	db	2
	dw	cgshift		; RSH
	db	12
	dw	cgum		; unary minus
	db	0
	dw	cgat

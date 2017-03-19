;====================
;	EDIT.DEF
;====================
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

ramzap	equ	1	; to zap or not to zap, that is the question?

; Page Zero defs
;----------------
; Alloc/Free defs, also used by compiler
afbase	equ	$80
aflast	equ	$82
afcur	equ	$84
afsize	equ	$86
afbest	equ	$88
props	equ	$88
afbsze	equ	$8a
op	equ	$8a
lsttoken equ	$8b	; prev. token value

; current window data / comp. vars
;----------------------------------
sp	equ	$8c
choff	equ	$8d
lnum	equ	$8e
curproc equ	$8e	; 2 bytes
dirty	equ	$8f
top	equ	$90	; -> top line
bot	equ	$92	; -> bottom line
whaddr	equ	$92	; -> current DO frame
cur	equ	$94	; -> current line
x	equ	$96	; don't use in comp.
y	equ	$97	; don't use in comp.
nlines	equ	$98
chan	equ	$98	; current input file
ytop	equ	$99
defflg	equ	$99
indent	equ	$9a
stackptr equ	$9a	; op stack offset

buf	equ	$9b	; -> edit buf
insert	equ	$9d	; insert/replace flag
delnxt	equ	$9e	; ->, USED BY LEX

; arguments and temps
;---------------------
args	equ	$a0
arg0	equ	$a0
arg1	equ	$a1
arg2	equ	$a2
arg3	equ	$a3
arg4	equ	$a4
arg5	equ	$a5
arg6	equ	$a6
arg7	equ	$a7
arg8	equ	$a8
arg9	equ	$a9
arg10	equ	$aa
arg11	equ	$ab
arg12	equ	$ac
arg13	equ	$ad
arg14	equ	$ae
arg15	equ	$af

; compiler vars
;---------------
stbase	equ	$b0	; s.t. base (page)
stglobal equ	$b1	; qglobal hash table
stlocal equ	$b3	; local hash table
codeoff equ	$b5	; relocation offset
device	equ	$b7	; default device
qglobal equ	$b8	; qglobal/local flag
stack	equ	$b9	; value stack
frame	equ	$bb	; -> current frame
symtab	equ	$bd	; -> next s.t. entry
stmax	equ	$bf	; s.t. top (page)
addr	equ	$c0	; token address
token	equ	$c2	; token value

; following defs can be used during
; program execution (user program)
;-----------------------------------
dirtyf	equ	$c3
spln	equ	$c4	; error char
curln	equ	$c5	; error line
curnxt	equ	$c7	; next error line
nxtaddr equ	$c9	; next token address

		; note: $CA-$CD never referenced

stg2	equ	$ce	; only used if big s.t.
arrayptr equ	$d0	; array mem. list
spnxt	equ	$d2	; next error char
nxttoken equ	$d3	; next token value


; ACTION! vars ($480 - $57D)
;----------------------------
w1	equ	$0480	; window 1 data
top1	equ	$048f
chcvt	equ	$0490	; char convert
codebase equ	$0491	; 2 bytes
codesize equ	$0493	; 2 bytes
stsp	equ	$0495	; s.t. size (pages)
mpc	equ	$0496	; edit/mon flag
gbase	equ	$0497	; 2 bytes
type	equ	$0499
list	equ	$049a	; listing flag
numargs equ	$049b
cmdln	equ	$049c	; command line offset
param	equ	$049d
opmode	equ	$049e
curwdw	equ	$049f	; window memory offset
cury	equ	$04a0	; current Y reg (0/1/unknown)
lastch	equ	$04a1	; last char
curch	equ	$04a2	; current char
sparem	equ	$04a3	; -> spare mem
numwd	equ	$04a5	; number of windows
allocerr equ	$04a6	; INC on Alloc error
delbuf	equ	$04a7	; 6 bytes
frstchar equ	$04ad	; used for big s.t.
taglist equ	$04ae	; 2 bytes
chcvt1	equ	$04b0
w2	equ	$04b1	; window 2 data
bckgrnd equ	$04c0	; background color
procsp	equ	$04c1	; Break stack pointer
argbytes equ	$04c2
trace	equ	$04c3	; trace flag
bigst	equ	$04c4	; big s.t. flag

		; note: $4C5 available

jmps	equ	$04c6	; see EDIT.CAR

; Jump table goes to $4FF
;-------------------------
segend	equ	$04c6
curbank equ	$04c9
stmask	equ	$04ca
error	equ	$04cb
wsize	equ	$04ce
linemax equ	$04cf
chcvt2	equ	$04d0
expend	equ	$04d1
dclend	equ	expend+3
cgend	equ	dclend+3
arend	equ	cgend+3
splend	equ	arend+3
alarm	equ	splend+3
eolch	equ	alarm+3
lsh	equ	eolch+1

chcvt3	equ	$04f0
tvdisp	equ	$04f1
disptb	equ	$04f2
smtend	equ	$04f8
stmradr equ	$04fe

subbuf	equ	$0500		; 40 bytes
findbuf equ	$0528		; 40 bytes
numbuf	equ	$0550		; 24 bytes
stkbase equ	$0577

opstack equ	$0580

; $580 TO ? is used for output of
; FASC routine.  Should not exceed
; 16 bytes, $58F (worst case?).
;---------------------------------
tempbuf equ	$0590	; 40 bytes
argtypes equ	$05b8	;  8 bytes
eof	equ	$05c0	;  8 bytes
inbuf	equ	$05c8	; 36 bytes
abt	equ	$05ec	;  4 bytes
temps	equ	$05f0	; 16 bytes


; system vars
;-------------
warmst	equ	$08
dosvec	equ	$0a
dosini	equ	$0c
qcode	equ	$0e	; ap. high mem.
brkkey	equ	$11
rtclok	equ	$12
adress	equ	$64
lmargin equ	$52
rmargin equ	$53
rowcrs	equ	$54
colcrs	equ	$55
dindex	equ	$57
savmsc	equ	$58
oldrow	equ	$5a
oldcol	equ	$5b
oldadr	equ	$5e
oldchr	equ	$5d
csrch	equ	$5d
ramtop	equ	$6a
fr0	equ	$d4
fr1	equ	$e0
cix	equ	$f2
inbuff	equ	$f3
flptr	equ	$fc

sdmctl	equ	$022f
txtmsc	equ	$0294
tabmap	equ	$02a3
color4	equ	$02c8
memtop	equ	$02e5
memlo	equ	$02e7
ch	equ	$02fc
lbuff	equ	$0580	; fp ASCII buf
consol	equ	$d01f
kbcode	equ	$02f2	; Prior keyboard qcode (CH1 in OS listing)

dmactl	equ	$d400
wsync	equ	$d40a

;	floating point routines
;	-----------------------
afp	equ	$d800
fasc	equ	$d8e6
ifp	equ	$d9aa
fpi	equ	$d9d2
fadd	equ	$da66
fsub	equ	$da60
fmul	equ	$dadb
fdiv	equ	$db28
log	equ	$decd
log10	equ	$ded1
exp10	equ	$ddcc
plyevl	equ	$dd40
zfr0	equ	$da44
zf1	equ	$da46
fld0r	equ	$dd89
fld0p	equ	$dd8d
fld1r	equ	$dd98
fld1p	equ	$dd9c
fst0r	equ	$dda7
fst0p	equ	$ddab
fmove	equ	$ddb6
coldsv	equ	$e477


; window record offsets
;-----------------------
wsp	equ	0
wch	equ	1
wlnum	equ	2
wdirty	equ	3
wtop	equ	4
wbot	equ	6
wcur	equ	8
wx	equ	10
wy	equ	11
wnlns	equ	12	; num lines
wytop	equ	13
windent equ	14


; system defs
;-------------
eol	equ	$9b
esc	equ	$1b


; bank switching defs
;---------------------
ml	equ	$b000
el	equ	$a000
ll	equ	$a000
cl	equ	$a000
bank	equ	$d500
ebank	equ	1
lbank	equ	0
cbank	equ	9

$title(ACTION! 3.6 - 11/4/83)
$pagewidth=80
	list	off

; Copyright 1983 by Clinton W Parker
; All Rights Reserved
; last modified November 4, 1983
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


	org	$bffa		; setup Left cartridge
	dw	cstart
	dw	$0500		; boot disk and start cart.
	dw	init

	include	"1.asm"

	org	ml
version	db	$36
date	db	$1,$17,$84	; assemble date of latest version!


	include	"2.asm"
propid	ldx	$a0
	include	"3.asm"
main

;	ACTION! 3.6 - S.T.
;	------------------
	org	ll
	include	"4.asm"
	include	"5.asm"

cpyright
	db	"ACTION! (c)1983 Action Computer Services"

	org	ll+$0fff
	db	lbank
doc

;	ACTION! 3.6 - Editor
;	--------------------
	org	el
	include	"6.asm"
	include	"7.asm"

	org	el+$0fff
	db	ebank

	org	ml+$08d8
	include	"8.asm"

editend

;	"ACTION! 3.6 - Compiler
;	-----------------------
	org	cl
	include	"9.asm"

cright	db	"ACTION! (c)1983 Action Computer Services"

	org	cl+$0fff
	db	cbank

	org	ml+$0a80
	include	"10.asm"

amplfin
	end

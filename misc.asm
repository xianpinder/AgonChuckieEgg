;============================================================================================================
;
; 888b     d888 8888888 .d8888b.   .d8888b.  
; 8888b   d8888   888  d88P  Y88b d88P  Y88b 
; 88888b.d88888   888  Y88b.      888    888 
; 888Y88888P888   888   "Y888b.   888        
; 888 Y888P 888   888      "Y88b. 888        
; 888  Y8P  888   888        "888 888    888 
; 888   "   888   888  Y88b  d88P Y88b  d88P 
; 888       888 8888888 "Y8888P"   "Y8888P"  
;
;============================================================================================================
;
; Miscellaneous routines
;
; Written by Christian Pinder. 2024
;============================================================================================================

; Returns length of zero terminated string at HL in BC
strlen:
					push	af
					push	hl
					xor		a
					ld		bc,000000
@loop:
					cp		(hl)
					jr		z,@done
					inc		hl
					inc		bc
					jr		@loop
@done:
					pop		hl
					pop		af
					ret


;============================================================================================================
strcpy_array:
					call	index_array

; Copy zero terminated string in HL to DE.
strcpy:
					push	af
					push	de
					push	hl
@loop:
					ld		a,(hl)
					ld		(de),a
					inc		hl
					inc		de
					or		a
					jr		nz,@loop

					pop		hl
					pop		de
					pop		af
					ret

;============================================================================================================

; Concatenate zero terminated string in HL onto string in DE.
strcat:
					push	af
					push	de
					push	hl

					xor		a
					ex		de,hl
					dec		hl
@findzero:
					inc		hl
					cp		(hl)
					jr		nz,@findzero
@copy:
					ld		a,(de)
					ld		(hl),a
					inc		hl
					inc		de
					or		a
					jr		nz,@copy

					pop		hl
					pop		de
					pop		af
					ret

;============================================================================================================

; HL = HL[A * 3]
index_array:
					push	bc
					ld		bc,0
					ld		c,a
					add		hl,bc
					add		hl,bc
					add		hl,bc
					ld		hl,(hl)
					pop		bc
					ret

;============================================================================================================

; unsigned HL to ascii string. HL = number to convert, IX = address of string space, A = num digits, Carry set = div 10
fmt_uhltoa:
					push	af
					ld		c,a
					ld		b,7

					jr		nc,@nodot
					dec		b
					dec		c
@nodot:
					ld		a,8
					sub		c
					ld		c,a

					ld		de,-10000000
					call	@num1
					ld		de,-1000000
					call	@num1
					ld		de,-100000
					call	@num1
					ld		de,-10000
					call	@num1
					ld		de,-1000
					call	@num1
					ld		de,-100
					call	@num1
					ld		de,-10
					call	@num1
					pop		af
					jr		nc,@nodot2
					ld		a,'.'
					ld		(ix+0),a
					inc		ix
@nodot2:
					ld		de,-1

@num1:
					ld		a,'0'-1
@num2:				inc		a
					add		hl,de
					jr		c,@num2
					sbc		hl,de

					ld		d,a

					ld		a,b
					or		a
					jr		z,@doit
@notneg:
					ld		a,d
					cp		a,'0'
					jr		nz,@notzero
					dec		b
					ld		d,' '
					ld		a,c
					or		a
					jr		z,@doit
					dec		c
					ret
@notzero:
					ld		b,0
@doit:
					ld		(ix+0),d
					inc		ix

					ret

;============================================================================================================

; unsigned int in HL to zero-terminated string in IX
utoa:
					push	af
					push	bc
					push	de
					push	hl

					ld		b,7

					ld		de,-10000000
					call	@num1
					ld		de,-1000000
					call	@num1
					ld		de,-100000
					call	@num1
					ld		de,-10000
					call	@num1
					ld		de,-1000
					call	@num1
					ld		de,-100
					call	@num1
					ld		de,-10
					call	@num1
					ld		de,-1
					call	@num1

					ld		(ix+0),0
					pop		hl
					pop		de
					pop		bc
					pop		af
					ret
@num1:
					ld		a,'0'-1
@num2:				inc		a
					add		hl,de
					jr		c,@num2
					sbc		hl,de

					ld		d,a

					ld		a,b
					or		a
					jr		z,@doit

					ld		a,d
					cp		a,'0'
					jr		nz,@notzero
					dec		b
					ret
@notzero:
					ld		b,0
@doit:
					ld		(ix+0),d
					inc		ix
					ret

;============================================================================================================

; signed int in HL to zero-terminated string in IX
itoa:
					push	hl
					add		hl,hl
					pop		hl
					jp		nc,utoa					; HL is positive so jump to utoa

					ld		(ix+0),'-'				; write out a minus sign
					inc		ix

					push	de
					ex		de,hl
					or		a
					sbc		hl,hl
					sbc		hl,de					; HL = -HL
					pop		de
					jp		utoa					; utoa for now positive number

;============================================================================================================

hexhltoa:
					dec		sp
					push	hl
					inc		sp
					pop		bc					; B = HLu
					ld		a,b
					call	@hex8toa
					ld		a,h
					call	@hex8toa
					ld		a,l
@hex8toa:
					ld		c,a
					rra
					rra
					rra
					rra
					call	@conv
					ld		a,c
@conv:
					and		$0F
					add		a,$90
					daa
					adc		a,$40
					daa
					ld		(ix+0),a
					inc		ix
					ret

;============================================================================================================

clampHL:
					push	de

					push	hl
					or		a
					sbc		hl,bc
					add		hl,hl
					pop		hl
					jr		nc,@donelower
					push	bc
					pop		hl
@donelower:
					pop		de

					push	hl
					or		a
					sbc		hl,de
					pop		hl
					ret		m
					ex		de,hl
					ret

;============================================================================================================

; maxAL: A = max(A,L)
maxAL: 
					cp		l
					ret		nc
					ld		a,l
					ret

;============================================================================================================

; minAL: A = min(A,L)
minAL: 
					cp		l
					ret		c
					ld		a,l
					ret

;============================================================================================================

; maxHLDE: HL = max(HL,DE)
maxHLDE:
					or		a
					sbc		hl,de
					add		hl,de
					ret		nc
					ex		de,hl
					ret

;============================================================================================================

; minHLDE: HL = min(HL,DE)
minHLDE:
					or		a
					sbc		hl,de
					add		hl,de
					ret		c
					ex		de,hl
					ret

;============================================================================================================

; HL = abs(HL)
absHL:
					ex		de,hl
; HL = abs(DE)
absDE:
					or		a,a
					sbc		hl,hl
					sbc		hl,de
					ret		p
					ex		de,hl
					ret

;============================================================================================================

addHLA:
					push	de
					ld		de,0
					ld		e,a
					add		hl,de
					pop		de
					ret

;============================================================================================================

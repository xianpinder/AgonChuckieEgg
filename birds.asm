;============================================================================================================
;
; 888888b.  8888888 8888888b.  8888888b.   .d8888b.  
; 888  "88b   888   888   Y88b 888  "Y88b d88P  Y88b 
; 888  .88P   888   888    888 888    888 Y88b.      
; 8888888K.   888   888   d88P 888    888  "Y888b.   
; 888  "Y88b  888   8888888P"  888    888     "Y88b. 
; 888    888  888   888 T88b   888    888       "888 
; 888   d88P  888   888  T88b  888  .d88P Y88b  d88P 
; 8888888P" 8888888 888   T88b 8888888P"   "Y8888P"  
;
;============================================================================================================
;
; Ostriches and the big duck.
;
; Game design by Nigel Alderton.
; BBC Micro port written by Doug Anderson.
; Originally published by A&F Software 1983.
; Copyright (C) A&F Software 1983.
;
; Game logic based on 6502 disassembly by Rich Talbot-Watkins.
; Agon port by Christian Pinder. 2024
;
;============================================================================================================

MAX_OSTRICHES:		EQU		5
OSY_INF_SIZE:		EQU		7

; ostrich info
OS_PX:				EQU		0		; pixel x
OS_PY:				EQU		1		; pixel y
OS_CX:				EQU		2		; cell	x
OS_CY:				EQU		3		; cell	y
OS_STATUS:			EQU		4		; status
OS_ANIM:			EQU		5		; animation frame
OS_DIR:				EQU		6		; direction

;============================================================================================================

ostrich_info:		ds		OSY_INF_SIZE*MAX_OSTRICHES
rndseed:			db		0,0,0,0

;============================================================================================================

draw_birds:
					ld		a,(num_ostriches)
					or		a
					jr		z,@no_osy

					ld		b,a
					xor		a
@osy_loop:
					call	draw_ostrich
					inc		a
					djnz	@osy_loop

@no_osy:
					ret

;============================================================================================================

osy_index:
					push	de
					ld		d,OSY_INF_SIZE
					ld		e,a
					mlt		de
					ld		ix,ostrich_info
					add		ix,de
					pop		de
					ret

;============================================================================================================

draw_ostrich:
					push	af
					push	bc
					push	de
					push	hl
					push	ix

					call	osy_index

					add		a,SPR_OSTRICH1
					ld		h,a

					ld		b,(ix+OS_ANIM)
					call	sprite_set_frame

					ld		d,(ix+OS_PX)
					ld		e,(ix+OS_PY)
					ld		a,(ix+OS_ANIM)
					cp		8
					jr		c,@noteatleft
					ld		a,d
					sub		a,8
					ld		d,a
@noteatleft:
					call	calc_screen_xy
					ld		a,h
					call	sprite_set_xy
					ld		a,h
					call	sprite_draw

					pop		ix
					pop		hl
					pop		de
					pop		bc
					pop		af
					ret


;============================================================================================================


move_birds:
					ld		a,(update_counter)
					inc		a
					ld		(update_counter),a
					cp		8
					jr		nz,@skipduck

					xor		a
					ld		(update_counter),a
					;call	move_duck
					ret
@skipduck:
					cp		4
					jr		nz,move_ostriches
					;call	decrease_time
					ret

;============================================================================================================

move_ostriches:
					ld		hl,currentbirdindex
					dec		(hl)
					ld		a,(hl)
					bit		7,a
					jr		z,@dontresetbirdindex

; Reset index to walking speed... if this is greater than the number of birds, it'll do
; nothing for the excess updates

					ld		a,(birdwalkingspeed)
					ld		(hl),a
@dontresetbirdindex:

					ld		hl,num_ostriches
					cp		(hl)
					call	c,move_ostrich
					ret

;============================================================================================================

move_ostrich:
					call	osy_index

					ld		a,(ix+OS_STATUS)
					or		a
					jr		z,@birdwalking
					cp		1
					jp		z,animatebird
					jp		birdeatingseed

@birdwalking:
					ld		d,(ix+OS_CX)
					ld		e,(ix+OS_CY)

					ld		c,0

; Test block below left
					push	de
					dec		d
					dec		e
					call	get_grid_cell
					pop		de
					bit		BIT_PLATFORM,a
					jr		z,@noplatformtotheleft
					set		0,c
@noplatformtotheleft:
	
; Test block below right

					push	de
					inc		d
					dec		e
					call	get_grid_cell
					pop		de
					bit		BIT_PLATFORM,a
					jr		z,@noplatformtotheright
					set		1,c
@noplatformtotheright:
	
; Test block directly below

					push	de
					dec		e
					call	get_grid_cell
					pop		de
					bit		BIT_LADDER,a
					jr		z,@noladderbelow
					set		3,c
@noladderbelow:
	
; Test block above
					push	de
					inc		e
					inc		e
					call	get_grid_cell
					pop		de
					bit		BIT_LADDER,a
					jr		z,@noladderabove
					set		2,c
@noladderabove:

; Look at possible movement options
					call	countsetbits
					cp		1
					jr		nz,@morethanonechoice

; Only one direction possible
					ld		(ix+OS_DIR),c
					jr		birdgotdirection
	
; If more than one direction, first consider only those which don't double back on ourselves
@morethanonechoice:
					ld		a,(ix+OS_DIR)
					cp		4
					jr		nc,@birdmovingupdown
					xor		$FC
					jr		@birdmovingleftright

@birdmovingupdown:
					xor		$F3

@birdmovingleftright:
					and		c
					ld		c,a
					call	countsetbits
					cp		1
					jr		nz,@stillmorethanonechoice

; Have settled at one choice - use it
					ld		(ix+OS_DIR),c
					jr		birdgotdirection


; Still a choice - roll a dice....
@stillmorethanonechoice:
					ld		b,c

; mask valid directions with random number until we get a value with only one bit set
@tryrandomdirectionloop:
					call	rnd
					ld		a,(rndseed)
					and		b
					ld		c,a
					call	countsetbits
					cp		1
					jr		nz,@tryrandomdirectionloop

					ld		(ix+OS_DIR),c

birdgotdirection:
					ld		a,(ix+OS_DIR)
					and		3
					jr		z,animatebird
					and		1
					jr		z,@newbirddirright

; Move bird left
					push	de
					dec		d
					call	get_grid_cell
					pop		de
					jr		@birdmovedhorizontally

; Move bird right
@newbirddirright:
					push	de
					inc		d
					call	get_grid_cell
					pop		de

@birdmovedhorizontally:
					bit		BIT_GRAIN,a
					jr		z,animatebird

					ld		(ix+OS_STATUS),2
					jr		animatebird

birdeatingseed:
					cp		4
					jr		nz,animatebird

; just ate seed - first find seed position

					ld		d,(ix+OS_CX)
					ld		e,(ix+OS_CY)
					ld		a,(ix+OS_DIR)

					dec		d
					and		1
					jr		nz,@foundseedpos
					inc		d
					inc		d
@foundseedpos:
					call	get_grid_cell
					bit		BIT_GRAIN,a
					jr		z,animatebird

; remove the seed from the game
					call	undraw_cell
					xor		a
					call	set_grid_cell


animatebird:
					ld		a,(ix+OS_STATUS)
					cp		2
					jp		nc,@animatebirdeating

					ld		a,(ix+OS_DIR)
					srl		a
					jr		c,@animatebirdleft
					srl		a
					jr		c,@animatebirdright
					srl		a
					jr		c,@animatebirdup

@animatebirddown:
					ld		a,(ix+OS_PY)
					sub		4
					ld		(ix+OS_PY),a

					ld		a,(ix+OS_STATUS)
					or		a
					jr		z,@animatebirddown2
					dec		(ix+OS_CY)
@animatebirddown2:
					ld		a,4
					jr		@animatebird2

@animatebirdup:
					ld		a,(ix+OS_PY)
					add		a,4
					ld		(ix+OS_PY),a

					ld		a,(ix+OS_STATUS)
					or		a
					jr		z,@animatebirdup2

					inc		(ix+OS_CY)

@animatebirdup2:
					ld		a,4
					jr		@animatebird2

@animatebirdleft:
					ld		a,(ix+OS_PX)
					sub		a,4
					ld		(ix+OS_PX),a

					ld		a,(ix+OS_STATUS)
					or		a
					jr		z,@animatebirdleft2
					dec		(ix+OS_CX)
@animatebirdleft2:
					ld		a,2
					jr		@animatebird2

@animatebirdright:
					ld		a,(ix+OS_PX)
					add		a,4
					ld		(ix+OS_PX),a

					ld		a,(ix+OS_STATUS)
					or		a
					jr		z,@animatebirdright2
					inc		(ix+OS_CX)
@animatebirdright2:
					xor		a
					jr		@animatebird2

@animatebird2:
					ld		(ix+OS_ANIM),a

					ld		a,(ix+OS_STATUS)
					xor		1
					ld		(ix+OS_STATUS),a

					add		a,(ix+OS_ANIM)
					ld		(ix+OS_ANIM),a
					ret

@animatebirdeating:
					ld		a,(ix+OS_STATUS)
					add		a,a
					and		31
					ld		(ix+OS_STATUS),a
					or		a
					jr		z,@finishedeating
					ld		a,6

@finishedeating:
					ld		b,a

					ld		a,(ix+OS_DIR)
					cp		1
					jr		nz,@eatingright
					inc		b
					inc		b
@eatingright:
					ld		a,(ix+OS_STATUS)
					cp		8
					jr		nz,@eatingsecondframe
					inc		b

@eatingsecondframe:
					ld		(ix+OS_ANIM),b
					ret

;============================================================================================================

; Counts number of set bits in C
countsetbits:
					push	bc

					ld		b,0
					ld		a,c
@loop:
					add		a,a
					jr		nc,@skipinc
					inc		b
@skipinc:
					or		a
					jr		nz,@loop

					ld		a,b
					pop		bc
					ret

;============================================================================================================

rnd_init:
					ld		a,$76
					ld		(rndseed),a
					ld		(rndseed+1),a
					ld		(rndseed+2),a
					ld		(rndseed+3),a
					ret
;============================================================================================================

rnd:
					push	ix
					ld		ix,rndseed
					ld		a,(ix+0)
					and		$48
					add		$38
					sla		a
					sla		a
					rl		(ix+3)
					rl		(ix+2)
					rl		(ix+1)
					rl		(ix+0)
					pop		ix
					ret
;============================================================================================================

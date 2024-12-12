;============================================================================================================
;
; 888    888        d8888 8888888b.  8888888b. Y88b   d88P 
; 888    888       d88888 888   Y88b 888   Y88b Y88b d88P  
; 888    888      d88P888 888    888 888    888  Y88o88P   
; 8888888888     d88P 888 888   d88P 888   d88P   Y888P    
; 888    888    d88P  888 8888888P"  8888888P"     888     
; 888    888   d88P   888 888 T88b   888 T88b      888     
; 888    888  d8888888888 888  T88b  888  T88b     888     
; 888    888 d88P     888 888   T88b 888   T88b    888     
;
;============================================================================================================
;
; Hen-House Harry the player's character.
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

draw_harry:
					ld		a,0
					call	gfx_set_pen
					ld		bc,0
					ld		de,0
					call	gfx_move
					ld		bc,511
					ld		de,45
					call	gfx_draw_filled_rect

					ld		a,(harry_x)
					ld		d,a
					ld		a,(harry_y)
					ld		e,a
					call	calc_screen_xy

					ld		a,SPR_HARRY
					call	sprite_set_xy

					ld		a,SPR_HARRY
					call	sprite_draw

					;call	debug_harry
					ret



;============================================================================================================

; set_harry_xy: set the x,y co-ords of player, the cell they are on and the position within the cell
; B = x position, C = y position
set_harry_xy:

; set harry_x, harry_frac_x, harry_cell_x

					ld		a,b
					cp		240
					jr		c,@notnegx
					xor		a
					jr		@setx
@notnegx:
					cp		153
					jr		c,@setx
					ld		a,152
@setx:
					ld		(harry_x),a
					add		a,3
					ld		b,a
					and		7
					ld		(harry_frac_x),a			; harry_frac_x = (harry_x + 3) & 7
					ld		a,b
					srl		a
					srl		a
					srl		a
					ld		(harry_cell_x),a			; harry_cell_x = (harry_x + 3) / 8

; set harry_y, harry_frac_y, harry_cell_y

					ld		a,c
					cp		5
					jr		nc,@lowy
					ld		b,60
					ld		c,32
					jr		set_harry_xy
@lowy:
					ld		(harry_y),a
					and		7
					ld		(harry_frac_y),a			; harry_frac_x = harry_x & 7
					ld		a,c
					sub		16
					srl		a
					srl		a
					srl		a
					ld		(harry_cell_y),a			; harry_frac_y = (harry_x - 16) / 8
					ret			

;============================================================================================================

; D = harry_cell_x, E = harry_cell_y
get_harry_cellxy:
					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					ret


;============================================================================================================

check_harry_keys:
					ld		b,0
					ld		c,1
					ld		a,(key_num_right)
					call	@check_move_key
					sla		c
					ld		a,(key_num_left)
					call	@check_move_key
					sla		c
					ld		a,(key_num_down)
					call	@check_move_key
					sla		c
					ld		a,(key_num_up)
					call	@check_move_key
					sla		c
					ld		a,(key_num_jump)
					call	@check_move_key

					ld		a,b
					ld		(key_bits),a
					ret

@check_move_key:
					call	kbd_check_down
					ret		z
					ld		a,b
					or		c
					ld		b,a
					ret

;============================================================================================================
move_harry:
					call	check_harry_keys

					ld		b,0						; harry_move_x
					ld		c,0						; harry_move_y

					ld		a,(key_bits)

					rra
					jr		nc,@noright
					inc		b
@noright:
					rra
					jr		nc,@noleft
					dec		b
@noleft:
					rra
					jr		nc,@nodown
					dec		c
@nodown:
					rra
					jr		nc,@noup
					inc		c
@noup:
					sla		c

					ld		a,b
					ld		(harry_move_x),a
					ld		a,c
					ld		(harry_move_y),a

					ld		a,(harry_move_type)
					cp		MOVE_WALKING
					jr		z,do_walking

					cp		MOVE_JUMPING
					jp		z,do_jumping

					cp		MOVE_CLIMBING
					jp		z,do_climbing

					cp		MOVE_FALLING
					jp		z,do_falling

					jp		ride_lift

;============================================================================================================

do_walking:

					ld		a,(key_bits)
					bit		4,a
					jp		nz,try_to_jump

					ld		a,(harry_move_y)
					or		a
					jr		z,@notclimbing

					ld		a,(harry_frac_x)
					cp		3
					jr		nz,@notclimbing
	
					ld		a,(harry_move_y)
					add		a,a
					jr		c,@try_climb_down

					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					inc		e
					inc		e
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		z,@notclimbing
					jr		@do_climb

@try_climb_down:
					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					dec		e
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		z,@notclimbing

@do_climb:
					xor		a
					ld		(harry_move_x),a
					ld		a,MOVE_CLIMBING
					ld		(harry_move_type),a
					jr		@do_platform_move


@notclimbing:
					xor		a
					ld		(harry_move_y),a

					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					dec		e

					ld		a,(harry_frac_x)
					ld		b,a
					ld		a,(harry_move_x)
					add		a,b
					bit		7,a
					jr		z,@notnegx
					dec		d
					jr		@donechkx
@notnegx:
					cp		8
					jr		c,@donechkx
					inc		d
@donechkx:
					call	get_grid_cell

					bit		BIT_PLATFORM,a
					jr		nz,@issolid

					ld		d,0
					ld		e,255
					ld		a,(harry_move_x)
					ld		b,a
					ld		a,(harry_frac_x)
					add		a,b
					and		7
					cp		4
					jr		nc,@dropleft
					ld		e,1
					inc		d
@dropleft:
					ld		a,e
					ld		(harry_jump_dir),a
					ld		a,d
					ld		(harry_jump_fdist),a
					ld		a,MOVE_FALLING
					ld		(harry_move_type),a
@issolid:
					call	check_side_move
					jr		nc,@do_platform_move
					xor		a
					ld		(harry_move_x),a
@do_platform_move:
					ld		a,(harry_move_x)
					or		a
					jr		z,@notmoving
					ld		(harry_facing),a
@notmoving:
					jr		update_harry_xy

;============================================================================================================

; update harry_x, harry_frac_x, harry_cell_x
update_harry_xy:
					ld		a,(harry_move_x)
					ld		b,a
					ld		a,(harry_x)
					add		a,b
					ld		b,a
					ld		a,(harry_move_y)
					ld		c,a
					ld		a,(harry_y)
					add		a,c
					ld		c,a
					call	set_harry_xy

					ld		b,0
					ld		a,(harry_facing)
					or		a
					jr		z,@playerupdownanim
					bit		7,a
					jr		z,@playerrightanim
					ld		b,3
@playerrightanim:
					ld		a,(harry_frac_x)
					srl		a
					jr		@calcplayeranim

@playerupdownanim:
					ld		b,6
					ld		a,(harry_frac_y)
					srl		a

@calcplayeranim:
					tst		2
					jr		z,@first2frames
					and		1
					add		a,a
@first2frames:
					ld		c,a

					ld		a,(harry_move_type)
					cp		MOVE_CLIMBING
					jr		nz,@animnotclimbing

					ld		a,(harry_move_y)
					or		a
					jr		nz,@makeplayeranim
					ld		c,0
					jr		@makeplayeranim

@animnotclimbing:	
					ld		a,(harry_move_x)
					or		a
					jr		nz,@makeplayeranim
					ld		c,0
@makeplayeranim:
					ld		a,b
					add		a,c
					ld		b,a
					ld		a,SPR_HARRY
					call	sprite_set_frame

; check to see if we have collected any eggs or grain

					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					ld		a,(harry_frac_y)
					cp		4
					jr		c,@skipgetabove
					inc		e
@skipgetabove:
					call	get_grid_cell
					bit		BIT_EGG,a
					jr		nz,@gotegg
					bit		BIT_GRAIN,a
					jr		nz,@gotgrain
					ret

; Harry collected an egg
@gotegg:

; remove the egg from the map
					call	undraw_cell
					xor		a
					call	set_grid_cell

; decrease the number of eggs left to collect
					ld		hl,num_eggs
					dec		(hl)

; TODO make egg collected sound

; TODO score points
					ret	
	
@gotgrain:
					call	undraw_cell
					xor		a
					call	set_grid_cell

; TODO make grain collected sound

; TODO score points

; TODO stall the timer

					ret
;============================================================================================================

check_side_move:
					ld		a,(harry_move_x)
					or		a
					ret		z
					add		a,a
					jr		nc,check_move_right

check_move_left:
					ld		a,(harry_x)
					or		a
					jr		z,no_side_move

					ld		a,(harry_frac_x)
					cp		2
					jr		nc,can_side_move

					ld		a,(harry_move_y)
					cp		2
					jr		z,can_side_move

					ld		a,(harry_cell_x)
					ld		d,a
					dec		d
					ld		a,(harry_cell_y)
					ld		e,a

					ld		a,(harry_frac_y)
					ld		b,a
					ld		a,(harry_move_y)
					add		a,b
					cp		8
					jr		c,@check_left
					add		a,a
					jr		nc,@check_aboveleft
					dec		e
					jr		@check_left
@check_aboveleft:
					inc		e
@check_left:
					call	get_grid_cell
					cp		CELL_PLATFORM
					jr		z,no_side_move
					ld		a,(harry_move_y)
					add		a,a
					jr		nc,can_side_move

					ld		a,(harry_cell_x)
					ld		d,a
					dec		d
					inc		e
					call	get_grid_cell
					cp		CELL_PLATFORM
					jr		z,no_side_move
can_side_move:
					or		a
					ret
no_side_move:
					scf
					ret

check_move_right:
					ld		a,(harry_x)
					cp		152
					jr		nc,no_side_move

					ld		a,(harry_frac_x)
					cp		5
					jr		c,can_side_move

					ld		a,(harry_move_y)
					cp		2
					jr		z,can_side_move

					ld		a,(harry_cell_x)
					ld		d,a
					inc		d
					ld		a,(harry_cell_y)
					ld		e,a

					ld		a,(harry_frac_y)
					ld		b,a
					ld		a,(harry_move_y)
					add		a,b
					cp		8
					jr		c,@check_right
					add		a,a
					jr		nc,@check_aboveright
					dec		e
					jr		@check_right
@check_aboveright:
					inc		e
@check_right:
					call	get_grid_cell
					cp		CELL_PLATFORM
					jr		z,no_side_move
					ld		a,(harry_move_y)
					add		a,a
					jr		nc,can_side_move

					ld		a,(harry_cell_x)
					ld		d,a
					inc		d
					inc		e
					call	get_grid_cell
					cp		CELL_PLATFORM
					jr		z,no_side_move
					jr		can_side_move


;============================================================================================================

old_move_y:			db		0

do_jumping:
					ld		a,(harry_jump_dir)
					ld		(harry_move_x),a
					ld		a,(harry_move_y)
					ld		(old_move_y),a

					ld		a,(harry_jump_fdist)
					srl		a
					srl		a
					cp		6
					jr		c,@maxed
					ld		a,6
@maxed:
					neg
					add		a,2
					ld		(harry_move_y),a

					ld		hl,harry_jump_fdist
					inc		(hl)

					ld		a,(harry_y)
					cp		220
					jr		c,@yokay
					ld		a,255
					ld		(harry_move_y),a
					ld		a,12
					ld		(harry_jump_fdist),a
					jp		@checkjumponlift
@yokay:

					ld		a,(harry_frac_x)
					ld		b,a
					ld		a,(harry_move_x)
					add		a,b
					cp		3
					jp		nz,@notcatchmid
					ld		a,(old_move_y)
					or		a
					jr		z,@notcatchmid
					add		a,a
					jr		c,@trycatchdown

					call	get_harry_cellxy
					inc		e
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		nz,@catchup

					call	get_harry_cellxy
					inc		e
					ld		a,(harry_frac_y)
					cp		4
					jr		c,@skipincy
					inc		e
@skipincy:
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		z,@notcatchmid

@catchup:
					ld		a,MOVE_CLIMBING
					ld		(harry_move_type),a

					ld		a,(harry_frac_y)
					ld		b,a
					ld		a,(harry_move_y)
					add		a,b
					and		1
					jr		z,@alreadyalignedok1
					ld		a,(harry_move_y)
					inc		a
					ld		(harry_move_y),a
@alreadyalignedok1:
					jp		@jumpmove

@trycatchdown:
					call	get_harry_cellxy
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		z,@notcatchmid

					call	get_harry_cellxy
					inc		e
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		z,@notcatchmid

					ld		a,MOVE_CLIMBING
					ld		(harry_move_type),a

					ld		a,(harry_move_y)
					ld		b,a
					ld		a,(harry_frac_y)
					add		a,b
					and		1
					jr		z,@alreadyalignedok2
					ld		a,b
					dec		a
					ld		(harry_move_y),a
@alreadyalignedok2:
					jp		@jumpmove

@notcatchmid:
					ld		a,(harry_move_y)
					ld		b,a
					ld		a,(harry_frac_y)
					add		a,b
					jr		z,@jumponyboundary
					bit		7,a
					jr		z,@jumpaboveyboundary

					call	get_harry_cellxy
					dec		e
					call	get_grid_cell
					bit		BIT_PLATFORM,a
					jr		z,@checkjumponlift

					ld		a,MOVE_WALKING
					ld		(harry_move_type),a

					ld		a,(harry_frac_y)
					neg
					ld		(harry_move_y),a
					jr		@checkjumponlift

@jumponyboundary:
					call	get_harry_cellxy
					dec		e
					call	get_grid_cell
					bit		BIT_PLATFORM,a
					jr		z,@checkjumponlift
					ld		a,MOVE_WALKING
					ld		(harry_move_type),a
					jr		@checkjumponlift

@jumpaboveyboundary:
					cp		8
					jr		nz,@checkjumponlift
					call	get_harry_cellxy
					call	get_grid_cell
					bit		BIT_PLATFORM,a
					jr		z,@checkjumponlift
					ld		a,MOVE_WALKING
					ld		(harry_move_type),a
					jr		@checkjumponlift

@checkjumponlift:
					ld		a,(has_lifts)
					or		a
					jr		z,@nolifttolandon
	
					ld		a,(harry_x)
					ld		b,a
					ld		a,(lifts_x)
					dec		a
					cp		b
					jr		nc,@nolifttolandon
					add		a,10
					cp		b
					jr		c,@nolifttolandon

					ld		a,(harry_y)
					sub		a,17
					ld		d,a
					sub		2
					ld		e,a
					ld		a,(harry_move_y)
					add		a,e
					ld		e,a

					ld		a,(lift1_y)
					ld		b,a
					cp		d
					jr		z,@hitlift1
					jr		nc,@checklift2
					cp		e
					jr		c,@checklift2
@hitlift1:
					ld		a,(which_lift)
					or		a
					jr		nz,@skipadj1
					inc		b
@skipadj1:
					ld		a,b
					jr		@moveupwithlift

@checklift2:
					ld		a,(lift2_y)
					ld		b,a
					cp		d
					jr		z,@hitlift2
					jr		nc,@nolifttolandon
					cp		e
					jr		c,@nolifttolandon

@hitlift2:
					ld		a,(which_lift)
					or		a
					jr		z,@skipadj2
					inc		b
@skipadj2:
					ld		a,b

@moveupwithlift:
					sub		d
					inc		a
					ld		(harry_move_y),a
					xor		a
					ld		(harry_jump_fdist),a
					ld		a,MOVE_ON_LIFT
					ld		(harry_move_type),a
					jr		@jumpmove		

@nolifttolandon:
					call	check_side_move
					jr		nc,@jumpmove

					ld		a,(harry_move_x)
					neg
					ld		(harry_move_x),a
					ld		(harry_jump_dir),a

@jumpmove:
					jp		update_harry_xy

;============================================================================================================

try_to_jump:
					xor		a
					ld		(harry_jump_fdist),a
					ld		a,MOVE_JUMPING
					ld		(harry_move_type),a
					ld		a,(harry_move_x)
					ld		(harry_jump_dir),a
					or		a
					jr		z,@nochangefacing
					ld		(harry_facing),a
@nochangefacing:
					jp		do_jumping

;============================================================================================================

do_climbing:

					ld		a,(key_bits)
					bit		4,a
					jr		nz,try_to_jump

					ld		a,(harry_move_x)
					or		a
					jr		z,@justupdown

					ld		a,(harry_frac_y)
					or		a
					jr		nz,@justupdown

					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					dec		e
					call	get_grid_cell
					bit		BIT_PLATFORM,a
					jr		z,@justupdown

					xor		a
					ld		(harry_move_y),a
					ld		a,MOVE_WALKING
					ld		(harry_move_type),a
					jr		@ladder_move

@justupdown:
					xor		a
					ld		(harry_move_x),a

					ld		a,(harry_move_y)
					or		a
					jr		z,@ladder_move

					ld		a,(harry_frac_y)
					or		a
					jr		nz,@ladder_move

					ld		a,(harry_move_y)
					add		a,a
					jr		c,@climb_down

					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					inc		e
					inc		e
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		nz,@ladder_move
					xor		a
					ld		(harry_move_y),a
					jr		@ladder_move

@climb_down:
					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					dec		e
					call	get_grid_cell
					bit		BIT_LADDER,a
					jr		nz,@ladder_move
					xor		a
					ld		(harry_move_y),a

@ladder_move:
					xor		a
					ld		(harry_facing),a
					jp		update_harry_xy

;============================================================================================================

do_falling:
					ld		a,(harry_jump_fdist)
					inc		a
					ld		(harry_jump_fdist),a
					cp		4
					jr		nc,@falldown

					ld		a,(harry_jump_dir)
					ld		(harry_move_x),a
					ld		a,255
					ld		(harry_move_y),a
					jr		@fallmain
@falldown:
					xor		a
					ld		(harry_move_x),a
					ld		a,(harry_jump_fdist)
					srl		a
					srl		a
					cp		4
					jr		c,@maxed
					ld		a,3
@maxed:
					cpl
					ld		(harry_move_y),a
@fallmain:
					ld		a,(harry_move_y)
					ld		b,a
					ld		a,(harry_frac_y)
					add		a,b
					jr		z,@fallingonyboundary
					jp		p,@fallingmove

					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					dec		e
					call	get_grid_cell
					bit		BIT_PLATFORM,a
					jr		z,@fallingmove

					ld		a,MOVE_WALKING
					ld		(harry_move_type),a
	
					ld		a,(harry_frac_y)
					neg
					ld		(harry_move_y),a
					jr		@fallingmove

@fallingonyboundary:
					ld		a,(harry_cell_x)
					ld		d,a
					ld		a,(harry_cell_y)
					ld		e,a
					dec		e
					call	get_grid_cell
					bit		BIT_PLATFORM,a
					jr		z,@fallingmove

					ld		a,MOVE_WALKING
					ld		(harry_move_type),a

@fallingmove:
					jp		update_harry_xy

;============================================================================================================

ride_lift:
					ld		a,(key_bits)
					and		$10
					jp		nz,try_to_jump

					ld		a,(harry_x)
					ld		b,a
					ld		a,(lifts_x)
					dec		a
					cp		b
					jr		nc,@offlift
					add		a,10
					cp		b
					jr		nc,@onlift

@offlift:
					xor		a
					ld		(harry_jump_fdist),a
					ld		(harry_jump_dir),a
					ld		a,MOVE_FALLING
					ld		(harry_move_type),a

@onlift:
					ld		a,1
					ld		(harry_move_y),a

					ld		a,(harry_move_x)
					or		a
					jr		z,@skipfacing
					ld		(harry_facing),a
@skipfacing:
					call	check_side_move
					jr		nc,@canmove
					xor		a
					ld		(harry_move_x),a
@canmove:
					ld		a,(harry_y)
					cp		220
					jr		nc,@nottop
					ld		a,1
					ld		(harry_killed),a
@nottop:
					jp		update_harry_xy

;============================================================================================================

debug_harry:
					ld		a,1
					call	gfx_set_pen
					ld		bc,0
					ld		de,0
					call	gfx_move
					ld		bc,511
					ld		de,45
					call	gfx_draw_filled_rect

					ld		a,15
					call	gfx_set_pen

					or		a
					sbc		hl,hl
					ld		a,(harry_frac_x)
					ld		l,a
					ld		ix,txt_num_fx
					call	utoa
					ld		hl,txt_harry_fx
					call	gfx_draw_text

					or		a
					sbc		hl,hl
					ld		a,(harry_cell_x)
					ld		l,a
					ld		ix,txt_num_cx
					call	utoa
					ld		hl,txt_harry_cx
					call	gfx_draw_text

					or		a
					sbc		hl,hl
					ld		a,(harry_x)
					ld		l,a
					ld		ix,txt_num_wx
					call	utoa
					ld		hl,txt_harry_wx
					call	gfx_draw_text

					or		a
					sbc		hl,hl
					ld		a,(harry_frac_y)
					ld		l,a
					ld		ix,txt_num_fy
					call	utoa
					ld		hl,txt_harry_fy
					call	gfx_draw_text

					or		a
					sbc		hl,hl
					ld		a,(harry_cell_y)
					ld		l,a
					ld		ix,txt_num_cy
					call	utoa
					ld		hl,txt_harry_cy
					call	gfx_draw_text

					ret


txt_harry_fx:		db		2,1,1
					db		"Frac X: "
txt_num_fx:			db		"   ",0


txt_harry_cx:		db		2,1,20
					db		"Cell X: "
txt_num_cx:			db		"   ",0

txt_harry_wx:		db		2,1,40
					db		"World X: "
txt_num_wx:			db		"   ",0



txt_harry_fy:		db		2,3,1
					db		"Frac Y: "
txt_num_fy:			db		"   ",0


txt_harry_cy:		db		2,3,20
					db		"Cell Y: "
txt_num_cy:			db		"   ",0

;============================================================================================================
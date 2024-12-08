;                             _____  ____  _   _                       
;                       /\   / ____|/ __ \| \ | |                      
;                      /  \ | |  __| |  | |  \| |                      
;                     / /\ \| | |_ | |  | | . ` |                      
;                    / ____ \ |__| | |__| | |\  |                      
;   _____ _    _ _  /_/  __\_\_____|\____/|_|_\_|  ______ _____  _____ 
;  / ____| |  | | |  | |/ ____| |/ /_   _|  ____| |  ____/ ____|/ ____|
; | |    | |__| | |  | | |    | ' /  | | | |__    | |__ | |  __| |  __ 
; | |    |  __  | |  | | |    |  <   | | |  __|   |  __|| | |_ | | |_ |
; | |____| |  | | |__| | |____| . \ _| |_| |____  | |___| |__| | |__| |
;  \_____|_|  |_|\____/ \_____|_|\_\_____|______| |______\_____|\_____|
;                                                                      
; Game design by Nigel Alderton.
; BBC Micro port written by Doug Anderson.
; Originally published by A&F Software 1983.
; Copyright (C) A&F Software 1983.
;
; Game logic based on 6502 disassembly by Rich Talbot-Watkins.
; Agon port by Christian Pinder. 2024

IMG_BLANK:			EQU		1
IMG_PLATFORM:		EQU		2
IMG_EGG:			EQU		3
IMG_LADDER:			EQU		4
IMG_GRAIN:			EQU		5
IMG_CAGE:			EQU		6
IMG_LIFT:			EQU		7
IMG_HARRY_RIGHT_1:	EQU		8
IMG_HARRY_RIGHT_2:	EQU		9
IMG_HARRY_RIGHT_3:	EQU		10
IMG_HARRY_LEFT_1:	EQU		11
IMG_HARRY_LEFT_2:	EQU		12
IMG_HARRY_LEFT_3:	EQU		13
IMG_HARRY_CLIMB_1:	EQU		14
IMG_HARRY_CLIMB_2:	EQU		15
IMG_HARRY_CLIMB_3:	EQU		16

IMG_NUM_BITMAPS:	EQU		16

SPR_HARRY:			EQU		0
SPR_LIFT1:			EQU		1
SPR_LIFT2:			EQU		2

GRID_WIDTH:			EQU		20
GRID_HEIGHT:		EQU		25

TILE_WIDTH:			EQU		24
TILE_HEIGHT:		EQU		12

CELL_EMPTY:			EQU		0
CELL_PLATFORM:		EQU		1
CELL_LADDER:		EQU		2
CELL_EGG:			EQU		4
CELL_GRAIN:			EQU		8

BIT_PLATFORM:		EQU		0
BIT_LADDER:			EQU		1
BIT_EGG:			EQU		2
BIT_GRAIN:			EQU		3

MOVE_WALKING:		EQU		0
MOVE_CLIMBING:		EQU		1
MOVE_JUMPING:		EQU		2
MOVE_FALLING:		EQU		3
MOVE_ON_LIFT:		EQU		4

VIEW_X_OFFSET:		EQU		16
VIEW_Y_OFFSET:		EQU		84


					INCLUDE "init.asm"
					INCLUDE "screen.asm"
					INCLUDE "input.asm"
					INCLUDE "misc.asm"
					INCLUDE "time.asm"
					INCLUDE "sprites.asm"
					INCLUDE	"levels.asm"

;============================================================================================================

main:
					ld		a,8								; mos_sysvars
					rst.lil	$08
					ld		(sys_timer_addr), ix
					ld		(mos_vars_addr),ix

; Detect if we are using VDP 2.10.0 or later.
; Switch into mode 20 and then read back the mode from the sysvars.
; If we can't switch to mode 20 then an older firmware is in use.

					res		4,(ix+4)
					ld		hl,vdu_mode_20
					call	vdu
@waitformode:
					bit		4,(ix+4)
					jr		z,@waitformode
									
					ld		a,(ix+$27)
					cp		a,20
					jr		z,@newmodes

					ld		hl,str_no_new_modes
					call	printz
					ret
@newmodes:
                    call    gfx_init_384
					call	kbd_init
					call	initbatchvdu
					call	update_gtime
					call	create_sprites

					xor		a
					call	expand_level
					call	init_harry
					call	gfx_vsync
					call	draw_level
					call	gfx_flip
					call	gfx_present

@game_loop:
					call	gfx_vsync

					ld		c,0
					ld		a,KBD_1
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_2
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_3
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_4
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_5
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_6
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_7
					call	kbd_check_pressed
					call	nz,change_level

					inc		c
					ld		a,KBD_8
					call	kbd_check_pressed
					call	nz,change_level

					call	move_lift
					call	move_harry

					call	draw_lifts
					call	draw_harry

					;call	gfx_vsync
					call	gfx_flip
					call	gfx_present

					jr		@game_loop

;============================================================================================================

create_sprites:
					ld		a,SPR_HARRY
					ld		c,SPR_TYPE_XORBACK
					ld		b,9
					ld		hl,harry_frames
					ld		d,24
					ld		e,24
					call	sprite_create
					ld		a,SPR_HARRY
					ld		b,0
					call	sprite_set_frame

					ld		a,SPR_LIFT1
					ld		c,SPR_TYPE_XOR
					ld		b,1
					ld		hl,lift_frames
					ld		d,39
					ld		e,6
					call	sprite_create

					ld		a,SPR_LIFT2
					ld		c,SPR_TYPE_XOR
					ld		b,1
					ld		hl,lift_frames
					ld		d,39
					ld		e,6
					call	sprite_create
					ret

;============================================================================================================

change_level:
					push	bc
					ld		a,c
					call	expand_level
					call	init_harry
					;call	gfx_vsync
					call	draw_level
					;call	gfx_flip
					;call	gfx_present
					pop		bc
					ret

;============================================================================================================

; D = x, E = y. returns BC = screen_x, DE = screen_y
calc_screen_xy:
					ld		b,3
					ld		c,d
					mlt		bc
					ld		hl,VIEW_X_OFFSET
					add		hl,bc
					ld		b,h
					ld		c,l

					ld		d,3
					mlt		de
					srl		d
					rr		e
					ld		hl,383
					or		a
					sbc		hl,de
					ex		de,hl
					ret

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

draw_lifts:
					ld		a,(has_lifts)
					or		a
					ret		z

					ld		a,(lifts_x)
					ld		d,a
					ld		a,(lift1_y)
					ld		e,a
					call	calc_screen_xy
					ld		a,SPR_LIFT1
					call	sprite_set_xy
					call	sprite_draw

					ld		a,(lifts_x)
					ld		d,a
					ld		a,(lift2_y)
					ld		e,a
					call	calc_screen_xy
					ld		a,SPR_LIFT2
					call	sprite_set_xy
					call	sprite_draw

					ret

;============================================================================================================


init_harry:
					ld		b,60
					ld		c,32
					call	set_harry_xy
					ld		a,6
					ld		(harry_sprite_num),a
					ld		a,MOVE_WALKING
					ld		(harry_move_type),a
					ld		a,1
					ld		(harry_facing),a

					ld		a,8
					ld		(lift1_y),a
					ld		a,90
					ld		(lift2_y),a
					xor		a
					ld		(which_lift),a
					ret

;============================================================================================================

check_move_key:
					call	kbd_check_down
;					call	kbd_check_pressed
					ret		z
					ld		a,b
					or		c
					ld		b,a
					ret

check_keys:
					ld		b,0
					ld		c,1
					ld		a,(key_num_right)
					call	check_move_key
					sla		c
					ld		a,(key_num_left)
					call	check_move_key
					sla		c
					ld		a,(key_num_down)
					call	check_move_key
					sla		c
					ld		a,(key_num_up)
					call	check_move_key
					sla		c
					ld		a,(key_num_jump)
					call	check_move_key

					ld		a,b
					ld		(key_bits),a
					ret

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

move_harry:
					call	check_keys

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
					;ld		a,(harry_x)
					;and		1
					;add		b
					;ld		b,a
					ld		a,b
					add		a,c
					ld		b,a
					ld		a,SPR_HARRY
					call	sprite_set_frame

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

expand_level:
					and		7
					ld		hl,level_array
					call	index_array
					push	hl
					pop		ix

					ld		a,12
					ld		(num_eggs),a

					lea		hl,ix+0
					ld		de,num_platforms
					ld		bc,5
					ldir
					lea		ix,ix+5

					ld		hl,level_grid
					ld		bc,GRID_WIDTH * GRID_HEIGHT
@clear_loop:
					ld		(hl),0
					inc		hl
					dec		bc
					ld		a,b
					or		c
					jr		nz,@clear_loop

					ld		a,(num_platforms)
					ld		b,a
@platforms:
					ld		e,(ix+0)					; platform y
					ld		d,(ix+1)					; platform start_x
					ld		c,(ix+2)					; platform end_x
					inc		c
@do_platform:
					ld		a,CELL_PLATFORM
					call	set_grid_cell
					inc		d
					ld		a,d
					cp		c
					jr		nz,@do_platform
					lea		ix,ix+3
					djnz	@platforms

					ld		a,(num_ladders)
					ld		b,a
@ladders:
					ld		d,(ix+0)					; ladder x
					ld		e,(ix+1)					; ladder start_y
					ld		c,(ix+2)					; ladder end_y
					inc		c
@do_ladder:
					ld		a,CELL_LADDER
					call	set_grid_cell
					inc		e
					ld		a,e
					cp		c
					jr		nz,@do_ladder
					lea		ix,ix+3
					djnz	@ladders

					ld		a,(has_lifts)
					or		a
					jr		z,@done_lifts
					ld		a,(ix+0)
					inc		ix
					add		a,a
					add		a,a
					add		a,a
					ld		(lifts_x),a
@done_lifts:
					ld		a,(num_eggs)
					ld		b,a
@do_eggs:
					ld		d,(ix+0)
					ld		e,(ix+1)
					ld		a,CELL_EGG
					call	set_grid_cell
					lea		ix,ix+2
					djnz	@do_eggs

					ld		a,(num_grain)
					ld		b,a
@do_grain:
					ld		d,(ix+0)
					ld		e,(ix+1)
					ld		a,CELL_GRAIN
					call	set_grid_cell
					lea		ix,ix+2
					djnz	@do_grain

					lea		hl,ix+0
					ld		de,ostriches_xy
					ld		bc,10
					ldir

					ret

;============================================================================================================

move_lift:
					ld		a,(has_lifts)
					or		a
					ret		z

					ld		a,(lift1_y)
					ld		e,a
					ld		a,(which_lift)
					or		a
					jr		z,@lift1
					ld		a,(lift2_y)
					ld		e,a
@lift1:
					inc		e
					inc		e
					ld		a,e
					cp		224
					jr		nz,@onscreen
					ld		e,6
@onscreen:
					ld		a,(which_lift)
					or		a
					jr		z,@update1
					ld		a,e
					ld		(lift2_y),a
					jr		@switchlift
@update1:
					ld		a,e
					ld		(lift1_y),a

@switchlift:
					ld		a,(which_lift)
					cpl
					ld		(which_lift),a
					ret
	
;============================================================================================================

; D = X, E = Y, A = type
set_grid_cell:
					push	bc

					ld		h,e
					ld		l,GRID_WIDTH
					mlt		hl
					ld		bc,0
					ld		c,d
					add		hl,bc
					ld		bc,level_grid
					add		hl,bc
					or		(hl)
					ld		(hl),a

					pop		bc
					ret

;============================================================================================================

; get_grid_cell: D = X, E = Y. returns A = type
get_grid_cell:
					ld		a,d
					cp		20
					jr		c,@xokay
					xor		a
					ret
@xokay:
					ld		a,e
					cp		25
					jr		c,@yokay
					xor		a
					ret
@yokay:
					push	bc

					ld		h,e
					ld		l,GRID_WIDTH
					mlt		hl
					ld		bc,0
					ld		c,d
					add		hl,bc
					ld		bc,level_grid
					add		hl,bc
					ld		a,(hl)

					pop		bc
					ret

;============================================================================================================

draw_level:
					call	clear_playarea
					ld		a,IMG_CAGE
					ld		bc,16
					ld		de,47
					call	gfx_draw_bitmap

					ld		hl,level_grid
					ld		de,0
@do_cell:
					ld		a,(hl)
					inc		hl
					or		a
					call	nz,draw_cell
					inc		d
					ld		a,d
					cp		GRID_WIDTH
					jr		nz,@do_cell
					ld		d,0
					inc		e
					ld		a,e
					cp		GRID_HEIGHT
					jr		nz,@do_cell

					call	gfx_flush
					ret

;============================================================================================================

draw_cell:
					push	de
					push	hl
					ld		c,a
					or		a
					ld		a,IMG_BLANK
					jr		z,@gotimage

					ld		a,IMG_LADDER
					bit		BIT_LADDER,c
					jr		nz,@gotimage

					ld		a, IMG_PLATFORM
					bit		BIT_PLATFORM,c
					jr		nz,@gotimage

					ld		a, IMG_EGG
					bit		BIT_EGG,c
					jr		nz,@gotimage

					ld		a,IMG_GRAIN
@gotimage:
					push	af
					ld		b,TILE_WIDTH
					ld		c,d
					mlt		bc
					ld		hl,VIEW_X_OFFSET
					add		hl,bc
					push	hl
					pop		bc

					ld		a,GRID_HEIGHT-1
					sub		e
					ld		d,TILE_HEIGHT
					ld		e,a
					mlt		de
					ld		hl,VIEW_Y_OFFSET
					add		hl,de
					ex		de,hl

					pop		af
					call	gfx_draw_bitmap

					pop		hl
					pop		de
					ret

;============================================================================================================

num_platforms:   	db	    0							; number of platforms
num_ladders:		db	    0							; number of ladders
has_lifts:			db	    0							; lifts flag
num_grain:			db	    0							; number of grain piles
num_ostriches:		db	    0							; number of ostriches to start with
num_eggs:			db		0
lifts_x:			db		0
ostriches_xy:		ds		10
level_grid:			ds		GRID_WIDTH * GRID_HEIGHT
harry_screen_x:		dl		232
harry_screen_y:		dl		329

harry_x:			db		0
harry_y:			db		0
harry_sprite_num:	db		0
harry_cell_x:		db		0
harry_cell_y:		db		0
harry_frac_x:		db		0
harry_frac_y:		db		0
harry_facing:		db		0
harry_move_type:	db		0
harry_move_x:		db		0
harry_move_y:		db		0
harry_jump_dir:		db		0
harry_jump_fdist:	db		0

lift1_y:			db		0
lift2_y:			db		0
which_lift:			db		0

harry_killed:		db		0

harry_frames:		db		IMG_HARRY_RIGHT_1, IMG_HARRY_RIGHT_2, IMG_HARRY_RIGHT_3
					db		IMG_HARRY_LEFT_1, IMG_HARRY_LEFT_2, IMG_HARRY_LEFT_3
					db		IMG_HARRY_CLIMB_1, IMG_HARRY_CLIMB_2, IMG_HARRY_CLIMB_3

lift_frames:		db		IMG_LIFT

key_num_right:		db		KBD_X
key_num_left:		db		KBD_Z
key_num_down:		db		KBD_COMMA
key_num_up:			db		KBD_L
key_num_jump:		db		KBD_SEMICOLON
key_bits:			db		0

;============================================================================================================

images_384:
					dl		blank384_img
					dl		platform384_img
					dl		egg384_img
					dl		ladder384_img
					dl		grain384_img
					dl		cage384_img
					dl		lift384_img
					dl		harryright1_img
					dl		harryright2_img
					dl		harryright3_img
					dl		harryleft1_img
					dl		harryleft2_img
					dl		harryleft3_img
					dl		harryclimb1_img
					dl		harryclimb2_img
					dl		harryclimb3_img

blank384_img:		db		24,12
					incbin	"gfx/blank.raw"

platform384_img:	db		24,12
					incbin	"gfx/platform.raw"

egg384_img:			db		24,12
					incbin	"gfx/egg.raw"

ladder384_img:		db		24,12
					incbin	"gfx/ladder.raw"

grain384_img:		db		24,12
					incbin	"gfx/grain.raw"

cage384_img:		db		69,72
					incbin	"gfx/cage.raw"

lift384_img:		db		39,6
					incbin	"gfx/lift.raw"

harryright1_img:	db		24,24
					incbin	"gfx/harryright1.raw"

harryright2_img:	db		24,24
					incbin	"gfx/harryright2.raw"

harryright3_img:	db		24,24
					incbin	"gfx/harryright3.raw"

harryleft1_img:		db		24,24
					incbin	"gfx/harryleft1.raw"

harryleft2_img:		db		24,24
					incbin	"gfx/harryleft2.raw"

harryleft3_img:		db		24,24
					incbin	"gfx/harryleft3.raw"

harryclimb1_img:	db		24,24
					incbin	"gfx/harryclimb1.raw"

harryclimb2_img:	db		24,24
					incbin	"gfx/harryclimb2.raw"

harryclimb3_img:	db		24,24
					incbin	"gfx/harryclimb3.raw"

;============================================================================================================
sys_timer_addr:		dl		0
mos_vars_addr:		dl		0

vdu_mode_20:		db		2,22,20

str_no_new_modes:	db		22,1,"You will need to update to the latest Console8 VDP to run this game.\r\n",0

vdu_write_buffer:	db		23, 0, $A0, 1,0, 0
vdu_write_buf_len:	dw		0
vdu_buffer:			ds		8192


bitmap_create:
					db		23, 27, $20
bitmap_buffer_id3:	db		0, $B1						; select buffer $B1xx
					db		23, 27, $21
bitmap_buffer_w:	db		0,0
bitmap_buffer_h:	db		0,0
					db		1							; RGBA2222

bitmap_buffer_header:
					db		23, 0, $A0
bitmap_buffer_id1:	db		0, $B1, 2					; clear buffer $B1xx
					db		23, 0, $A0
bitmap_buffer_id2:	db		0, $B1, 0					; write block to buffer $B1xx
bitmap_buffer_len:	dw		0
bitmap_buffer:		ds		65536

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

IMG_BLANK:			EQU		0
IMG_PLATFORM:		EQU		1
IMG_EGG:			EQU		2
IMG_LADDER:			EQU		3
IMG_GRAIN:			EQU		4
IMG_CAGE:			EQU		5
IMG_LIFT:			EQU		6
IMG_HARRY_RIGHT_1:	EQU		7
IMG_HARRY_RIGHT_2:	EQU		8
IMG_HARRY_RIGHT_3:	EQU		9
IMG_HARRY_LEFT_1:	EQU		10
IMG_HARRY_LEFT_2:	EQU		11
IMG_HARRY_LEFT_3:	EQU		12
IMG_HARRY_CLIMB_1:	EQU		13
IMG_HARRY_CLIMB_2:	EQU		14
IMG_HARRY_CLIMB_3:	EQU		15
IMG_OSY_RIGHT_1:	EQU		16
IMG_OSY_RIGHT_2:	EQU		17
IMG_OSY_LEFT_1:		EQU		18
IMG_OSY_LEFT_2:		EQU		19
IMG_OSY_CLIMB_1:	EQU		20
IMG_OSY_CLIMB_2:	EQU		21
IMG_OSY_EAT_RIGHT_1: EQU	22
IMG_OSY_EAT_RIGHT_2: EQU	23
IMG_OSY_EAT_LEFT_1:	EQU		24
IMG_OSY_EAT_LEFT_2:	EQU		25
IMG_LET_C:			EQU		26
IMG_LET_H:			EQU		27
IMG_LET_U:			EQU		28
IMG_LET_K:			EQU		29
IMG_LET_I:			EQU		30
IMG_LET_E:			EQU		31
IMG_LET_G:			EQU		32
IMG_DUCK_RIGHT_1:	EQU		33
IMG_DUCK_RIGHT_2:	EQU		34
IMG_DUCK_LEFT_1:	EQU		35
IMG_DUCK_LEFT_2:	EQU		36
IMG_LIFE:			EQU		37

IMG_NUM_BITMAPS:	EQU		38

SPR_HARRY:			EQU		0
SPR_LIFT1:			EQU		1
SPR_LIFT2:			EQU		2
SPR_OSTRICH1:		EQU		3
SPR_OSTRICH2:		EQU		4
SPR_OSTRICH3:		EQU		5
SPR_OSTRICH4:		EQU		6
SPR_OSTRICH5:		EQU		7
SPR_DUCK:			EQU		8

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
					INCLUDE "sound.asm"
					INCLUDE "harry.asm"
					INCLUDE "birds.asm"
					INCLUDE	"levels.asm"
					INCLUDE	"attract.asm"

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
					call	snd_init
					call	initbatchvdu
					call	update_gtime
					call	create_sprites
					call	init_sounds
@begin:
					call	title_screen

					call	new_game
@new_level:
					call	reset_bonus
					call	expand_level
@restart:
					call	start_level
@game_loop:
					call	gfx_vsync

					call	move_lift
					call	move_harry
					call	move_birds
					call	check_collisions

					call	draw_lifts
					call	draw_harry
					call	draw_duck
					call	harry_sounds
					call	draw_birds

					call	gfx_flip
					call	gfx_present

					ld		a,(num_eggs)
					or		a
					jr		nz,@stilleggs

					call	award_bonus
					ld		hl,level
					inc		(hl)
					jr		@new_level
@stilleggs:
					ld		a,(harry_killed)
					or		a
					jr		nz,@harrydead

					ld		a,(harry_y)
					cp		19
					jr		c,@harrydead

					jp		@game_loop


@harrydead:
					call	play_tune
					ld		hl,lives
					dec		(hl)
					jr		nz,@restart

					call	game_over
					call	check_hiscore

					jp		@begin

;============================================================================================================

play_tune:
					ld		ix,@tune_data
					ld		b,(ix+0)
					inc		ix
@loop:
					push	bc

					ld		c,2						; channel 2
					ld		b,126					; target volume 126
					ld		l,(ix+0)
					ld		h,(ix+1)				; read pitch
					ld		e,(ix+2)
					ld		d,(ix+3)				; read duration
					call	snd_play_sound

					lea		ix,ix+4
					pop		bc
					djnz	@loop
					ret
@tune_data:
					db		16					; number of notes

; pairs of pitch and duration
					dw		200,	200
					dw		224,	100
					dw		200,	200
					dw		178,	100
					dw		168,	200
					dw		133,	100
					dw		150,	200
					dw		126,	100
					dw		133,	600
					dw		133,	50
					dw		150,	50
					dw		168,	50
					dw		178,	50
					dw		200,	50
					dw		252,	50
					dw		267,	50

;============================================================================================================

create_sprites:
					ld		a,SPR_HARRY
					ld		c,SPR_TYPE_XORBACK
					ld		b,9
					ld		hl,harry_frames
					call	sprite_create
					ld		a,SPR_HARRY
					ld		b,0
					call	sprite_set_frame

					ld		a,SPR_LIFT1
					ld		c,SPR_TYPE_XOR
					ld		b,1
					ld		hl,lift_frames
					call	sprite_create

					ld		a,SPR_LIFT2
					ld		c,SPR_TYPE_XOR
					ld		b,1
					ld		hl,lift_frames
					call	sprite_create

					ld		a,SPR_OSTRICH1
					ld		c,SPR_TYPE_XORBACK
					ld		b,10
					ld		hl,ostrich_frames
					call	sprite_create


					ld		a,SPR_OSTRICH2
					ld		c,SPR_TYPE_XORBACK
					ld		b,10
					ld		hl,ostrich_frames
					call	sprite_create

					ld		a,SPR_OSTRICH3
					ld		c,SPR_TYPE_XORBACK
					ld		b,10
					ld		hl,ostrich_frames
					call	sprite_create

					ld		a,SPR_OSTRICH4
					ld		c,SPR_TYPE_XORBACK
					ld		b,10
					ld		hl,ostrich_frames
					call	sprite_create

					ld		a,SPR_OSTRICH5
					ld		c,SPR_TYPE_XORBACK
					ld		b,10
					ld		hl,ostrich_frames
					call	sprite_create

					ld		a,SPR_DUCK
					ld		c,SPR_TYPE_XORBACK
					ld		b,4
					ld		hl,duck_frames
					call	sprite_create

					ret

;============================================================================================================

init_sounds:
					ld		hl,vol_env_1
					call	snd_set_vol_env

					ld		hl,vol_env_2
					call	snd_set_vol_env

					ld		hl,vol_env_3
					call	snd_set_vol_env
					ret


vol_env_1:			db		1			; channel 1
					dw		10			; attack for 10ms
					dw		10			; decay for 10ms
					db		0			; no sustain
					dw		0			; no release

vol_env_2:			db		2			; channel 2
					dw		2			; attack for 10ms
					dw		19			; decay for 130ms
					db		127			; sustain at target volume
					dw		29			; release for 200ms

vol_env_3:			db		0			; channel 0
					dw		20			; attack for 10ms
					dw		0			; no decay
					db		127			; sustain at target volume
					dw		10			; release for 10ms

;============================================================================================================
start_level:
					call	init_level
					call	init_harry
					call	ready_player
					call	gfx_vsync
					call	draw_level
					call	gfx_flip
					call	gfx_present
					ret
;============================================================================================================

ready_player:
					call	gfx_vsync
					call	gfx_clear_screen
					call	gfx_graph_text

					ld		a,GFX_PEN_YELLOW
					call	gfx_set_pen

					ld		a,15
					ld		hl,txt_get_ready
					call	gfx_write_centre_text

					ld		a,GFX_PEN_CYAN
					call	gfx_set_pen

					ld		a,17
					ld		hl,txt_player_1
					call	gfx_write_centre_text

					call	gfx_present

					ld		bc,120*3
					call	wait_delay

					ret


txt_get_ready:		db		"Get Ready",0
txt_player_1:		db		"Player 1",0


;============================================================================================================

game_over:
					ld		hl,vdu_gm_rect
					ld		bc,vdu_gm_rect_end - vdu_gm_rect
					call	batchvdu

					call	gfx_graph_text

					ld		a,GFX_PEN_CYAN
					call	gfx_set_pen

					ld		a,22
					ld		hl,txt_game_over
					call	gfx_write_centre_text

					ld		a,24
					ld		hl,txt_player_1
					call	gfx_write_centre_text

					call	gfx_present

					ld		bc,120*3
					call	wait_delay
					ret

txt_game_over:		db		"G A M E   O V E R",0

vdu_gm_rect:		db		18, 0, 0					; GCOL 0,0
					db		25, 4						; MOVE
					dw		112,183						; 112,183
					db		25,$65						; RECTANGLE
					dw		403,258						; 403,258
vdu_gm_rect_end:

;============================================================================================================

; D = x, E = y. returns BC = screen_x, DE = screen_y
calc_screen_xy:
					push	af
					push	hl
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
					pop		hl
					pop		af
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

add_to_score:
					ld		hl,(score)
					add		hl,bc
					ld		(score),hl
					ld		hl,(score_extra)
					add		hl,bc
					ld		(score_extra),hl
					ld		bc,10000
					or		a
					sbc		hl,bc
					jr		c,draw_score
					ld		(score_extra),hl
					ld		hl,lives
					inc		(hl)
					call	draw_lives
draw_score:
					ld		hl,(score)
					ld		ix,@txt_score_num
					call	utoz7

					ld		hl,@txt_score
					ld		bc,@txt_score_end - @txt_score
					call	batchvdu

					ret

@txt_score:			db		31,11,2
@txt_score_num:		db		"0000000"
@txt_score_end:

;============================================================================================================
decrease_time:
					ld		a,(stalltime)
					or		a
					jr		z,@nostall
					dec		a
					ld		(stalltime),a
					ret
@nostall:
					ld		hl,(countdown)
					dec		hl
					ld		(countdown),hl

					ld		a,h
					or		l
					jr		nz,@stilltime
					ld		a,1
					ld		(harry_killed),a
@stilltime:
					call	draw_time

					ld		hl,(bonus)
					ld		a,l
					or		h
					ret		z

; every 5 ticks the bonus is decreased by 10 points

					ld		a,(bonus_ticker)
					dec		a
					ld		(bonus_ticker),a
					ret		nz

					ld		a,5
					ld		(bonus_ticker),a

decrease_bonus:
					ld		hl,(bonus)
					ld		bc,-10
					add		hl,bc
					ld		(bonus),hl
				
draw_bonus:
					ld		hl,(bonus)
					ld		ix,@txt_bonus_num
					call	utoz4

					ld		hl,@txt_bonus
					ld		bc,@txt_bonus_end - @txt_bonus
					call	batchvdu

					ret

@txt_bonus:			db		31,42,4
@txt_bonus_num:		db		"0000"
@txt_bonus_end:	


draw_time:
					ld		hl,(countdown)
					ld		ix,@txt_time_num
					call	utoz3

					ld		hl,@txt_time
					ld		bc,@txt_time_end - @txt_time
					call	batchvdu

					ret

@txt_time:			db		31,58,4
@txt_time_num:		db		"000"
@txt_time_end:


;============================================================================================================

award_bonus:
					xor		a
@bonus_loop:
					push	af
					call	gfx_vsync

					ld		b,4
@decbonus:
					ld		hl,(bonus)
					ld		a,h
					or		l
					jr		z,@done
					push	bc
					ld		bc,10
					call	add_to_score
					call	decrease_bonus
					pop		bc
					djnz	@decbonus

					pop		af
					push	af
					or		a
					jr		nz,@nosound

					ld		a,4					; high pitch noise
					ld		c,0					; channel 0 (noise)
					ld		d,1					; duration 1/20th second			
					ld		b,100				; target volume 100
					call	snd_play_beeb_sound
@nosound:
					call	gfx_present

					pop		af
					xor		1
					jr		@bonus_loop
@done:
					pop		af
					call	gfx_present
					ld		bc,120
					call	wait_delay
					ret

;============================================================================================================


; starting a new game
new_game:
					ld		a,5
					ld		(lives),a
					or		a
					sbc		hl,hl
					ld		(score),hl
					ld		(score_extra),hl
					xor		a
					ld		(level),a
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

; set initial position of the duck

					ld		a,4
					ld		(duck_x),a
					ld		a,204
					ld		(duck_y),a
					xor		a
					ld		(duck_x_speed),a
					ld		(duck_y_speed),a
					ld		(duck_anim),a

; determine how many birds appear

					ld		hl,num_ostriches
					ld		a,(difficulty)
					cp		1
					jr		nz,@notphase2
					ld		(hl),0

@notphase2:
; 5 birds from phase 4 onwards
					cp		3
					jr		c,@notphase1or3
					ld		(hl),5
@notphase1or3:

; init ostriches
					ld		b,5
					ld		ix,ostrich_info
@initbirdloop:
					ld		a,(ix+OS_CX)
					add		a,a
					add		a,a
					add		a,a
					ld		(ix+OS_PX),a

					ld		a,(ix+OS_CY)
					add		a,a
					add		a,a
					add		a,a
					add		a,20
					ld		(ix+OS_PY),a

					ld		(ix+OS_STATUS),0
					ld		(ix+OS_ANIM),0
					ld		(ix+OS_DIR),2

					lea		ix,ix+OSY_INF_SIZE
					djnz	@initbirdloop

					ret

;============================================================================================================

init_level:
					ld		a,(level)
					ld		b,a
					and		7
					ld		(screen),a
					ld		a,b
					srl		a
					srl		a
					srl		a
					ld		(difficulty),a

; whether we have a big bird or not

					ld		hl,bigbirdflag
					xor		a
					ld		(hl),a
					ld		a,(difficulty)
					or		a
					jr		z,@noduck
					inc		(hl)
@noduck:
					xor		a
					ld		(update_counter),a
					ld		(currentbirdindex),a

					ld		b,8
					ld		a,(difficulty)
					cp		4
					jr		c,@notfast
					ld		b,5
@notfast:
					ld		a,b
					ld		(birdwalkingspeed),a

					xor		a
					ld		(extralifeflag),a
					ld		(harry_killed),a
					ld		(stalltime),a
					ld		hl,900
					ld		(countdown),hl

					call	rnd_init

					ld		hl,ostriches_xy
					ld		ix,ostrich_info
					ld		b,5
@osyloop:
					ld		a,(hl)
					ld		(ix+OS_CX),a
					inc		hl

					ld		a,(hl)
					ld		(ix+OS_CY),a
					inc		hl

					lea		ix,ix+OSY_INF_SIZE
					djnz	@osyloop

					ret	

;============================================================================================================

reset_bonus:
					ld		a,(level)
					inc		a
					cp		10
					jr		c,@lt10
					ld		a,9
@lt10:
					ld		l,a
					ld		h,250
					mlt		hl
					add		hl,hl
					add		hl,hl						; HL = A * 1000
					ld		(bonus),hl

					ld 		a,5
					ld		(bonus_ticker),a
					ret

;============================================================================================================

expand_level:
					ld		a,(level)
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
					pop		bc

					or		a
					jr		z,@clearcell
					or		(hl)
					ld		(hl),a
					ret
@clearcell:
					ld		(hl),a
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

draw_lives:
					ld		a,(lives)
					dec		a
					ret		z
					cp		7
					jr		c,@skipmax
					ld		a,7
@skipmax:
					ld		ix,80
@loop:
					push	af

					ld		a,IMG_LIFE
					lea		bc,ix+0
					ld		de,26
					call	gfx_draw_bitmap

					pop		af
					lea		ix,ix+10
					dec		a
					jr		nz,@loop
					ret

;============================================================================================================

draw_level:
					call	clear_playarea
					ld		a,IMG_CAGE
					ld		bc,16
					ld		de,51
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

					ld		hl,txt_top_info
					ld		bc,txt_top_info_end - txt_top_info
					call	batchvdu

					ld		ix,@txt_level_num
					ld		a,(level)
					inc		a
					push	af
					or		a
					sbc		hl,hl
					ld		l,a
					call	utoz3

					pop		af
					cp		100
					jr		nc,@is3digits
					ld		a,32
					ld		(@txt_level_num),a
@is3digits:
					ld		hl,@txt_level
					ld		bc,@txt_level_end - @txt_level
					call	batchvdu

					call	draw_score
					call	draw_time
					call	draw_bonus
					call	draw_lives
					ret

@txt_level:			db		31,24,4
@txt_level_num:		db		" 00"
@txt_level_end:	

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
undraw_cell:
					call	gfx_gcol_xor
					call	draw_cell
					call	gfx_gcol_paint
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

duck_x:				db		0
duck_y:				db		0
duck_dir:			db		0
duck_x_speed:		db		0
duck_y_speed:		db		0
duck_anim:			db		0

harry_killed:		db		0
update_counter:		db		0
level:				db		0
screen:				db		0
difficulty:			db		0
bigbirdflag:		db		0
currentbirdindex:	db		0
birdwalkingspeed:	db		0
extralifeflag:		db		0
;playerdieflag:		db		0
stalltime:			db		0
lives:				db		0
score:				dl		0
score_extra:		dl		0
countdown:			dl		0
bonus:				dl		0
bonus_ticker:		db		0

harry_frames:		db		IMG_HARRY_RIGHT_1, IMG_HARRY_RIGHT_2, IMG_HARRY_RIGHT_3
					db		IMG_HARRY_LEFT_1, IMG_HARRY_LEFT_2, IMG_HARRY_LEFT_3
					db		IMG_HARRY_CLIMB_1, IMG_HARRY_CLIMB_2, IMG_HARRY_CLIMB_3

lift_frames:		db		IMG_LIFT

ostrich_frames:		db		IMG_OSY_RIGHT_1, IMG_OSY_RIGHT_2, IMG_OSY_LEFT_1, IMG_OSY_LEFT_2
					db		IMG_OSY_CLIMB_1, IMG_OSY_CLIMB_2
					db		IMG_OSY_EAT_RIGHT_1, IMG_OSY_EAT_RIGHT_2, IMG_OSY_EAT_LEFT_1, IMG_OSY_EAT_LEFT_2

duck_frames:		db		IMG_DUCK_RIGHT_1, IMG_DUCK_RIGHT_2, IMG_DUCK_LEFT_1, IMG_DUCK_LEFT_2

key_num_up:			db		KBD_A
key_num_down:		db		KBD_Z
key_num_left:		db		KBD_COMMA
key_num_right:		db		KBD_PERIOD
key_num_jump:		db		KBD_SPACE
key_bits:			db		0


txt_top_info:		db		4
					db		17,13,17,128
					db		31,2,1
					db		"_______ _________"
					db		31,2,3
					db		"__________     ___________       ____________     __________"
					db		17,0,17,128+13
					db		31,2,2
					db		" SCORE ",9," 0000000 "
					db		31,2,4
					db		" PLAYER 1 ",9,9,9,9,9
					db		" LEVEL  01 ",9,9,9,9,9,9,9
					db		" BONUS 0000 ",9,9,9,9,9
					db		" TIME 000 "
txt_top_info_end:

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
					dl		birdright1_img
					dl		birdright2_img
					dl		birdleft1_img
					dl		birdleft2_img
					dl		birdclimb1_img
					dl		birdclimb2_img
					dl		birdeatright1_img
					dl		birdeatright2_img
					dl		birdeatleft1_img
					dl		birdeatleft2_img
					dl		let_c_img
					dl		let_h_img
					dl		let_u_img
					dl		let_k_img
					dl		let_i_img
					dl		let_e_img
					dl		let_g_img
					dl		duckright1_img
					dl		duckright2_img
					dl		duckleft1_img
					dl		duckleft2_img
					dl		life_img


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

birdright1_img:		db		24,30
					incbin	"gfx/birdright1.raw"
birdright2_img:		db		24,30
					incbin	"gfx/birdright2.raw"
birdleft1_img:		db		24,30
					incbin	"gfx/birdleft1.raw"
birdleft2_img:		db		24,30
					incbin	"gfx/birdleft2.raw"
birdclimb1_img:		db		24,30
					incbin	"gfx/birdclimb1.raw"
birdclimb2_img:		db		24,33
					incbin	"gfx/birdclimb2.raw"
birdeatright1_img:	db		48,30
					incbin	"gfx/birdeatright1.raw"
birdeatright2_img:	db		48,30
					incbin	"gfx/birdeatright2.raw"
birdeatleft1_img:	db		48,30
					incbin	"gfx/birdeatleft1.raw"
birdeatleft2_img:	db		48,30
					incbin	"gfx/birdeatleft2.raw"

let_c_img:			db		45,45
					incbin	"gfx/letc.raw"
let_h_img:			db		45,45
					incbin	"gfx/leth.raw"
let_u_img:			db		45,45
					incbin	"gfx/letu.raw"
let_k_img:			db		45,45
					incbin	"gfx/letk.raw"
let_i_img:			db		45,45
					incbin	"gfx/leti.raw"
let_e_img:			db		45,45
					incbin	"gfx/lete.raw"
let_g_img:			db		45,45
					incbin	"gfx/letg.raw"

duckright1_img:		db		48,36
					incbin	"gfx/duckright1.raw"
duckright2_img:		db		48,36
					incbin	"gfx/duckright2.raw"
duckleft1_img:		db		48,36
					incbin	"gfx/duckleft1.raw"
duckleft2_img:		db		48,36
					incbin	"gfx/duckleft2.raw"

life_img:			db		9,3
					incbin	"gfx/life.raw"


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

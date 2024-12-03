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
; BBC Micro port by Doug Anderson.
; Originally published by A&F Software 1983.
; Copyright (C) A&F Software 1983.
;
; Agon port by Christian Pinder. 2024

IMG_BLANK:			EQU		1
IMG_PLATFORM:		EQU		2
IMG_EGG:			EQU		3
IMG_LADDER:			EQU		4
IMG_GRAIN:			EQU		5
IMG_CAGE:			EQU		6
IMG_NUM_BITMAPS:	EQU		6

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


VIEW_X_OFFSET:		EQU		16
VIEW_Y_OFFSET:		EQU		84


					INCLUDE "init.asm"
					INCLUDE "screen.asm"
					INCLUDE "input.asm"
					INCLUDE "misc.asm"
					INCLUDE "time.asm"
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

					xor		a
					call	expand_level
					call	gfx_vsync
					call	draw_level
					call	gfx_flip
					call	gfx_present

@game_loop:
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

					jr		@game_loop

change_level:
					push	bc
					ld		a,c
					call	expand_level
					call	gfx_vsync
					call	draw_level
					call	gfx_flip
					call	gfx_present
					pop		bc
					ret

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

;============================================================================================================

images_384:
					dl		blank384_img
					dl		platform384_img
					dl		egg384_img
					dl		ladder384_img
					dl		grain384_img
					dl		cage384_img

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

;============================================================================================================
sys_timer_addr:		dl		0
mos_vars_addr:		dl		0

vdu_mode_20:		db		2,22,20

str_no_new_modes:	db		22,1,"You will need to update to the latest Console8 VDP to run this game.\r\n",0

vdu_write_buffer:	db		23, 0, $A0, 1,0, 0
vdu_write_buf_len:	dw		0
vdu_buffer:			ds		4096


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

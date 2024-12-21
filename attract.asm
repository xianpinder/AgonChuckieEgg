;============================================================================================================
;
;        d8888 88888888888 88888888888 8888888b.         d8888  .d8888b. 88888888888 
;       d88888     888         888     888   Y88b       d88888 d88P  Y88b    888     
;      d88P888     888         888     888    888      d88P888 888    888    888     
;     d88P 888     888         888     888   d88P     d88P 888 888           888     
;    d88P  888     888         888     8888888P"     d88P  888 888           888     
;   d88P   888     888         888     888 T88b     d88P   888 888    888    888     
;  d8888888888     888         888     888  T88b   d8888888888 Y88b  d88P    888     
; d88P     888     888         888     888   T88b d88P     888  "Y8888P"     888     
;
;============================================================================================================
;
; Attract screens, high scores and key selection
;
; Written by Christian Pinder. 2024
;============================================================================================================

title_screen:
					call	update_gtime

					ld		ix,attract_timer
					ld		bc,120*10
					ld		de,120*10
					call	init_timer

					xor		a
					ld		(@attract_screen),a

					ld		hl,vdu_clear_screen
					ld		bc,2
					call	batchvdu

					call	logo_and_stuff
@attract:
					call	gfx_vsync

					ld		a,GFX_PEN_BLACK
					call	gfx_set_pen
					ld		bc,0
					ld		de,90
					call	gfx_move
					ld		bc,511
					ld		de,310
					call	gfx_draw_filled_rect

					ld		a,(@attract_screen)
					or		a
					call	z,show_hiscores
					dec		a
					call	z,show_credits
					dec		a
					call	z,show_keys

					call	gfx_flip
					call	gfx_present

@title_loop:
					ld		a,KBD_S
					call	kbd_check_down
					ret		nz

					ld		a,KBD_K
					call	kbd_check_down
					jr		z,@notK
					call	key_select
					jr		title_screen
@notK:
					call	update_gtime
					ld		ix,attract_timer
					call	update_timer
					jr		nc,@title_loop

					ld		a,(@attract_screen)
					inc		a
					cp		3
					jr		nz,@nowrap
					xor		a
@nowrap:
					ld		(@attract_screen),a
					jr		@attract

@attract_screen:	db		0

;============================================================================================================

show_hiscores:
					ld		a,GFX_PEN_YELLOW
					call	gfx_set_pen

					ld		a,10
					ld		hl,txt_highscores
					call	gfx_write_centre_text

					call	update_highscores
					ld		hl,txt_hiscore_table
					call	gfx_draw_text
					ret

;============================================================================================================

show_credits:
					ld		a,GFX_PEN_GREEN
					call	gfx_set_pen

					ld		a,14
					ld		hl,txt_credits1
					call	gfx_write_centre_text

					ld		a,16
					ld		hl,txt_credits2
					call	gfx_write_centre_text

					ld		a,18
					ld		hl,txt_credits3
					call	gfx_write_centre_text

					ld		a,20
					ld		hl,txt_credits4
					call	gfx_write_centre_text

					ld		a,22
					ld		hl,txt_credits5
					call	gfx_write_centre_text

					ret

;============================================================================================================

key_select:
					xor		a
					ld		(key_num_up),a
					ld		(key_num_down),a
					ld		(key_num_left),a
					ld		(key_num_right),a
					ld		(key_num_jump),a

					call	gfx_vsync

					ld		hl,vdu_clear_screen
					ld		bc,2
					call	batchvdu

					ld		a,GFX_PEN_YELLOW
					call	gfx_set_pen

					ld		a,5
					ld		hl,txt_key
					call	gfx_write_centre_text

					ld		a,7
					call	hl,txt_selection
					call	gfx_write_centre_text

					ld		a,GFX_PEN_CYAN
					call	gfx_set_pen

					ld		hl,txt_key_up
					ld		de,key_num_up
					call	@get_key

					ld		hl,txt_key_down
					ld		de,key_num_down
					call	@get_key

					ld		hl,txt_key_left
					ld		de,key_num_left
					call	@get_key

					ld		hl,txt_key_right
					ld		de,key_num_right
					call	@get_key

					ld		hl,txt_key_jump
					ld		de,key_num_jump
					call	@get_key

					call	kbd_wait_nokey

					ret

@get_key:
					push	de
					call	gfx_draw_text
					call	gfx_present
					call	kbd_wait_nokey
					call	@read_key
					pop		hl
					ld		(hl),a
					call	kbd_get_keyname
					call	gfx_draw_text
					call	gfx_present
					ret

@read_key:
					ld		ix,key_num_up
@dup:
					call	kbd_wait_key
					cp		(ix+0)
					jr		z,@dup
					cp		(ix+1)
					jr		z,@dup
					cp		(ix+2)
					jr		z,@dup
					cp		(ix+3)
					jr		z,@dup
					cp		(ix+4)
					jr		z,@dup
					ret

;============================================================================================================

show_keys:
					ld		a,GFX_PEN_YELLOW
					call	gfx_set_pen

					ld		a,10
					ld		hl,txt_keys
					call	gfx_write_centre_text

					ld		a,GFX_PEN_CYAN
					call	gfx_set_pen

					ld		hl,txt_key_up
					call	gfx_draw_text

					ld		a,(key_num_up)
					call	kbd_get_keyname
					call	gfx_draw_text

					ld		hl,txt_key_down
					call	gfx_draw_text

					ld		a,(key_num_down)
					call	kbd_get_keyname
					call	gfx_draw_text

					ld		hl,txt_key_left
					call	gfx_draw_text

					ld		a,(key_num_left)
					call	kbd_get_keyname
					call	gfx_draw_text

					ld		hl,txt_key_right
					call	gfx_draw_text

					ld		a,(key_num_right)
					call	kbd_get_keyname
					call	gfx_draw_text

					ld		hl,txt_key_jump
					call	gfx_draw_text

					ld		a,(key_num_jump)
					call	kbd_get_keyname
					call	gfx_draw_text

					ret

;============================================================================================================

logo_and_stuff:
					ld		ix,title_letters
@let_loop:
					ld		a,(ix+0)
					or		a
					jr		z,@donelet
					ld		c,(ix+1)
					ld		b,(ix+2)
					ld		de,23
					call	gfx_draw_bitmap
					lea		ix,ix+3
					jr		@let_loop
@donelet:
					ld		hl,txt_instruct
					ld		bc,txt_instruct_end - txt_instruct
					call	batchvdu

					ret

;============================================================================================================

update_highscores:
					ld		c,0
					ld		b,10
					ld		iy,high_scores
@loop:
					ld		d,c
					ld		e,26
					mlt		de
					ld		ix,txt_scorelist+6
					add		ix,de
					ld		hl,(iy+0)
					ld		a,8
					or		a
					call	fmt_uhltoa

					ld		d,8
					lea		iy,iy+3	
@copyname:
					ld		a,(iy+0)
					ld		(ix+2),a
					inc		ix
					inc		iy
					dec		d
					jr		nz,@copyname

					inc		c
					djnz	@loop
					ret

;============================================================================================================

attract_timer:		dl      0,0,0,0

vdu_clear_screen:
					db		26,16

txt_instruct:		db		4
					db		31,15,42
					db		17,11,"Press "
					db		17,14,"S"
					db		17,11," to start, "
					db		17,14,"K"
					db		17,11," to change keys"
					db		5
txt_instruct_end:

txt_key:			db		"K E Y",0
txt_selection:		db		"S E L E C T I O N",0

txt_keys:			db		"K E Y S",0
txt_key_up:			db		2,14,45,"   Up . . . . ",2,14,80,0
txt_key_down:		db		2,16,45," Down . . . . ",2,16,80,0
txt_key_left:		db		2,18,45," Left . . . . ",2,18,80,0
txt_key_right:		db		2,20,45,"Right . . . . ",2,20,80,0
txt_key_jump:		db		2,22,45," Jump . . . . ",2,22,80,0

txt_credits1:		db		"Originally published by A&F Software",0
txt_credits2:		db		"Copyright (c) A&F Software 1983",0
txt_credits3:		db		"Game design by Nigel Alderton",0
txt_credits4:		db		"BBC Micro port by Doug Anderson",0
txt_credits5:		db		"Agon port by Christian Pinder",0

txt_highscores:		db		"H I G H S C O R E S",0

txt_hiscore_table:
					db		1,GFX_PEN_GREEN
					db		2,12,44
txt_scorelist:
					db		" 1        0000  NAME    ",10,10
					db		" 2        0000  NAME    ",10,10
					db		" 3        0000  NAME    ",10,10
					db		" 4        0000  NAME    ",10,10
					db		" 5        0000  NAME    ",10,10
					db		" 6        0000  NAME    ",10,10
					db		" 7        0000  NAME    ",10,10
					db		" 8        0000  NAME    ",10,10
					db		" 9        0000  NAME    ",10,10
					db		"10        0000  NAME    ",0

high_scores:
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "
					dl		1000
					db		"A&F     "

title_letters:
					db		IMG_LET_C
					dw		5
					db		IMG_LET_H
					dw		53
					db		IMG_LET_U
					dw		101
					db		IMG_LET_C
					dw		149
					db		IMG_LET_K
					dw		197
					db		IMG_LET_I
					dw		245
					db		IMG_LET_E
					dw		293
					db		IMG_LET_E
					dw		365
					db		IMG_LET_G
					dw		413
					db		IMG_LET_G
					dw		461
					db		0
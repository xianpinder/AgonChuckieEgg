;============================================================================================================
;
;  .d8888b.  8888888b.  8888888b.  8888888 88888888888 8888888888 .d8888b.  
; d88P  Y88b 888   Y88b 888   Y88b   888       888     888       d88P  Y88b 
; Y88b.      888    888 888    888   888       888     888       Y88b.      
;  "Y888b.   888   d88P 888   d88P   888       888     8888888    "Y888b.   
;     "Y88b. 8888888P"  8888888P"    888       888     888           "Y88b. 
;       "888 888        888 T88b     888       888     888             "888 
; Y88b  d88P 888        888  T88b    888       888     888       Y88b  d88P 
;  "Y8888P"  888        888   T88b 8888888     888     8888888888 "Y8888P"  
;
;============================================================================================================
;
; Doing sprites like it's 1988.
;
; Written by Christian Pinder. 2024
;============================================================================================================

MAX_SPRITES:		EQU		10
SPR_INF_SIZE:		EQU		50

; Four types of sprite are supported:
;
; SPR_TYPE_PAINT:	A write-only sprite. Draws the sprite on to the screen but has no way of undrawing it.
;					Use this if you are double-buffering and re-drawing the playfield every frame.
;
; SPR_TYPE_XOR:		Xor on, Xor off. Simple sprite that uses xor to write and remove it
;					If the sprite goes over something then the colours will look odd. You can use palette to fix this.
;
;SPR_TYPE_SAVEBACK:	Saves the background before painting the sprite. Uses saved background to erase sprite.
;					Doesn't play well with overlapping sprites. Very fussy about the draw order.
;
;SPR_TYPE_XORBACK:	Uses xor trickery to allow SAVEBACK type sprites to be drawn/undrawn/redrawn in any order.
;					You can even use XOR and XORBACK sprites together without worring about overlap.
;					Bit buggy on real hardware at the moment. Work in progress.

SPR_TYPE_PAINT:		EQU		0
SPR_TYPE_XOR:		EQU		1
SPR_TYPE_SAVEBACK:	EQU		2
SPR_TYPE_XORBACK:	EQU		3

;============================================================================================================

;
; Sprite information structure
;

; 0				number of frames
; 1				current frame
; 2,3,4			address of frame list
; 5,6,7			screen x
; 8,9,10		screen y
; 11			width
; 12			height
; 13,14,15		background x
; 16,17,18		background y
; 19			background bitmap number
; 20			background saved flag
; 21			current image number
; 22			render type

; Useful equates for access the sprite info via IX/IY

SP_NF:				EQU		0
SP_CF:				EQU		1
SP_FL:				EQU		2
SP_SX:				EQU		5
SP_SY:				EQU		8
SP_W:				EQU		11
SP_H:				EQU		12
SP_BX:				EQU		13
SP_BY:				EQU		16
SP_BN:				EQU		19
SP_BS:				EQU		20
SP_CI:				EQU		21
SP_RT:				EQU		22

;============================================================================================================

sprite_create:
					push	ix
					call	spr_index
					ld		(ix+SP_NF),b			; number of frames
					ld		(ix+SP_CF),0			; current frame
					ld		(ix+SP_FL),hl			; address of frame list
					ld		(ix+SP_RT),c			; sprite render type
					or		a
					sbc		hl,hl
					ld		(ix+SP_SX),hl			; sprite screen x
					ld		(ix+SP_SY),hl			; sprite screen y
					ld		(ix+SP_BX),hl			; background x
					ld		(ix+SP_BY),hl			; background y
					;or		128
					ld		(ix+SP_BN),a			; background image number
					;call	spr_grab_back
					ld		(ix+SP_BS),0			; no background saved yet

					call	spr_set_image
					pop		ix
					ret

;============================================================================================================

sprite_set_frame:
					push	ix
					call	spr_index
					ld		(ix+SP_CF),b
					call	spr_set_image
					pop		ix
					ret

;============================================================================================================

sprite_set_xy:
					push	ix
					call	spr_index
					ld		(ix+SP_SX),bc
					ld		(ix+SP_SY),de
					pop		ix
					ret

;============================================================================================================

sprite_get_xy:
					push	ix
					call	spr_index
					ld		bc,(ix+SP_SX)
					ld		de,(ix+SP_SY)
					pop		ix
					ret

;============================================================================================================

sprite_draw:
					push	ix
					call	spr_index

					ld		a,(ix+SP_RT)
					or		a
					jr		nz,@not_zero
					call	spr_paint
					jr		@done
@not_zero:
					dec		a
					jp		nz,@not_one
					call	spr_xor
					jr		@done
@not_one:
					dec		a
					jr		nz,@not_two
					call	spr_saveback
					jr		@done
@not_two:
					dec		a
					jr		nz,@done
					call	spr_xorback
@done:
					pop		ix
					ret

;============================================================================================================

; clear background saved flag on all sprites. use if playfield cleared.
sprite_invalidate_all:
					ld		b,MAX_SPRITES
					ld		ix,sprite_list
					xor		a
@loop:
					ld		(ix+SP_BS),a
					lea		ix,ix+SPR_INF_SIZE
					djnz	@loop
					ret

;============================================================================================================

spr_index:
					push	de
					ld		d,SPR_INF_SIZE
					ld		e,a
					mlt		de
					ld		ix,sprite_list
					add		ix,de
					pop		de
					ret

;============================================================================================================

spr_set_image:
					push	af
					push	de
					push	hl

					ld		de,0
					ld		e,(ix+SP_CF)			; E = sprite current frame
					ld		hl,(ix+SP_FL)			; HL = address of frame list
					add		hl,de
					ld		a,(hl)					; A = image number for current frame
					ld		(ix+SP_CI),a

					call	gfx_get_bitmap_wh
					ld		(ix+SP_W),d				; image width
					ld		(ix+SP_H),e				; image height

					pop		hl
					pop		de
					pop		af
					ret

;============================================================================================================

spr_update_bxy:
					ld		bc,(ix+SP_SX)
					ld		de,(ix+SP_SY)
					ld		(ix+SP_BX),bc
					ld		(ix+SP_BY),de
					ret


;============================================================================================================

spr_grab_back:
					push	ix
					push	iy

					ld		bc,(ix+SP_SX)
					ld		de,(ix+SP_SY)
					ld		(ix+SP_BS),1

					ld		iy,vdu_save_back
					ld		(iy+5),c
					ld		(iy+6),b
					ld		(iy+7),e
					ld		(iy+8),d
					ld		a,(ix+SP_W)
					dec		a
					ld		(iy+11),a
					ld		a,(ix+SP_H)
					dec		a
					ld		(iy+13),a
					ld		a,(ix+SP_BN)
					ld		(iy+18),a

					lea		hl,iy+0
					ld		bc,vdu_save_back_end - vdu_save_back
					call	batchvdu
					pop		iy
					pop		ix
					ret

;============================================================================================================

spr_xor_buff:
					push	ix
					push	iy
					ld		iy,vdu_xor_buffers
					ld		h,$FA
					ld		l,(ix+SP_BN)
					ld		(iy+6),l
					ld		(iy+7),h
					ld		(iy+18),l
					ld		(iy+19),h

					ld		l,(ix+SP_W)
					ld		h,(ix+SP_H)
					mlt		hl
					ld		(iy+12),l
					ld		(iy+13),h
					ld		(iy+24),l
					ld		(iy+25),h

					ld		h,$B1
					ld		l,(ix+SP_CI)
					ld		(iy+26),l
					ld		(iy+27),h

					lea		hl,iy+0
					ld		bc,vdu_xor_buffers_end - vdu_xor_buffers
					call	batchvdu
					pop		iy
					pop		ix
					ret

;============================================================================================================

; draw the sprite at its new location
spr_paint:
					ld		a,(ix+SP_CI)
					ld		bc,(ix+SP_SX)
					ld		de,(ix+SP_SY)
					call	gfx_draw_bitmap
					ret

;============================================================================================================

spr_xor:
					ld		hl,vdu_gcol_xor
					ld		bc,3
					call	batchvdu

					ld		a,(ix+SP_BS)
					or		a
					jr		z,@noback

					ld		a,(ix+SP_BN)
					ld		bc,(ix+SP_BX)
					ld		de,(ix+SP_BY)
					call	gfx_draw_bitmap			; erase the sprite				
@noback:
					call	spr_update_bxy
					ld		a,(ix+SP_CI)
					ld		(ix+SP_BN),a
					ld		(ix+SP_BS),1

					call	spr_paint

					ld		hl,vdu_gcol_paint
					ld		bc,3
					call	batchvdu
					ret

;============================================================================================================

spr_saveback:
					ld		a,(ix+SP_BS)
					or		a
					jr		z,@noback
					ld		a,(ix+SP_BN)
					ld		bc,(ix+SP_BX)
					ld		de,(ix+SP_BY)
					call	gfx_draw_bitmap8			; erase the sprite				
@noback:
					call	spr_update_bxy
					call	spr_grab_back
					call	spr_paint
					ret

;============================================================================================================

spr_xorback:
					ld		a,(ix+SP_BS)
					or		a
					jr		z,@noback

					ld		hl,vdu_gcol_xor
					ld		bc,3
					call	batchvdu

					ld		a,(ix+SP_BN)
					ld		bc,(ix+SP_BX)
					ld		de,(ix+SP_BY)
					call	gfx_draw_bitmap8			; erase the sprite

					ld		hl,vdu_gcol_paint
					ld		bc,3
					call	batchvdu
@noback:
					call	spr_update_bxy
					call	spr_grab_back
					call	spr_paint
					call	spr_xor_buff
					ret

;============================================================================================================

vdu_save_back:
					db		23, 0, $CA				; flush the render queue

					db		25,4					; move absolute
					db		0,0						; x
					db		0,0						; y
					db		25,0					; move relative
					db		0,0						; dx
					db		0,0						; dy
					db		23, 27, 1				; capture screen to bitmap
					db		0						; bitmap number
					db		0, 0, 0					; padding
vdu_save_back_end:

vdu_xor_buffers:
					db		23, 0, $CA				; flush the render queue

					db		23, 0, $A0				; AND all bytes in buffer with %00111111
					db		0,0						; bufferId
					db		5, $45, 0,0
					db		0,0						; count
					db		%00111111

					db		23, 0, $A0				; Xor background and sprite bitmaps together
					db		0,0						; bufferId
					db		5, $E7, 0,0
					db		0,0						; count
					db		0,0						; buffer2id
					db		0,0
vdu_xor_buffers_end:

vdu_gcol_xor:		db		18,3,0
vdu_gcol_paint:		db		18,0,0

sprite_list:		ds		MAX_SPRITES * SPR_INF_SIZE

;============================================================================================================
;
;  .d8888b.   .d8888b.  8888888b.  8888888888 8888888888 888b    888 
; d88P  Y88b d88P  Y88b 888   Y88b 888        888        8888b   888 
; Y88b.      888    888 888    888 888        888        88888b  888 
;  "Y888b.   888        888   d88P 8888888    8888888    888Y88b 888 
;     "Y88b. 888        8888888P"  888        888        888 Y88b888 
;       "888 888    888 888 T88b   888        888        888  Y88888 
; Y88b  d88P Y88b  d88P 888  T88b  888        888        888   Y8888 
;  "Y8888P"   "Y8888P"  888   T88b 8888888888 8888888888 888    Y888 
;
;============================================================================================================
;
; Screen and graphics routines
;
; Written by Christian Pinder. 2024
;============================================================================================================

					MACRO vdu_gcol arg1, arg2
						db	18, arg1, arg2
					ENDMACRO

					MACRO vdu_move arg1, arg2
						db		25,4
						dw		arg1,arg2
					ENDMACRO

					MACRO vdu_draw arg1, arg2
						db		25, 5
						dw		arg1,arg2
					ENDMACRO

					MACRO vdu_tri arg1, arg2, arg3, arg4, arg5, arg6
						db		25, 4
						dw		arg1,arg2						; MOVE x1, y1
						db		25, 4
						dw		arg3,arg4						; MOVE x2, y2
						db		25,85
						dw		arg5,arg6						; TRIANGLE x3, y3
					ENDMACRO

;								    x      y     w     h
					MACRO vdu_rect arg1, arg2, arg3, arg4
						db		25, 4
						dw		arg1,arg2						; MOVE x, y
						db		25, 4
						dw		arg1,arg2+arg4					; MOVE x, y+h
						db		25,85
						dw		arg1+arg3,arg2					; TRIANGLE x+w, y
						db		25, 4
						dw		arg1,arg2+arg4					; MOVE x, y+h
						db		25,85
						dw		arg1+arg3,arg2+arg4				; TRIANGLE x+w, y+h
					ENDMACRO

;============================================================================================================

GFX_PEN_BLACK:			EQU		0					; 000000
GFX_PEN_DARK_RED:		EQU		1					; 800000
GFX_PEN_DARK_GREEN:		EQU		2					; 008000
GFX_PEN_DARK_YELLOW:	EQU		3					; AAAA00
GFX_PEN_DARK_BLUE:		EQU		4					; 000080
GFX_PEN_DARK_MAGENTA:	EQU		5					; 550000
GFX_PEN_DARK_CYAN:		EQU		6					; 008080
GFX_PEN_GREY:			EQU		7					; 808080
GFX_PEN_DARK_GREY:		EQU		8					; 404040
GFX_PEN_RED:			EQU		9					; FF0000
GFX_PEN_GREEN:			EQU		10					; 00FF00
GFX_PEN_YELLOW:			EQU		11					; FFFF00
GFX_PEN_BLUE:			EQU		12					; 0000FF
GFX_PEN_MAGENTA:		EQU		13					; FF00FF
GFX_PEN_CYAN:			EQU		14					; 00FFFF
GFX_PEN_WHITE:			EQU		15					; FFFFFF

;============================================================================================================

gfx_init_bitmaps:
					ld		b,IMG_NUM_BITMAPS
					ld		a,1
@loop:
					ld		hl,(ix+0)
					lea		ix,ix+3
					call	gfx_upload_bitmap
					inc		a
					djnz	@loop
					ret

;============================================================================================================

gfx_init_384:
					ld		hl, vdu_startup_384
					call	vdu

					xor		a
					ld		(double_buffer),a

					;ld		hl,vdu_palette
					;call	vdu

					ld		ix,images_384
					call	gfx_init_bitmaps
					ret

vdu_startup_384:	db		16
					db		22, 20								; MODE 20 512x384 64 colours single-buffered
					db		23, 0, $C0, 0						; logical screen scaling off
					db		23, 1, 0							; disable text cursor
					db		5									; write text at graphics cursor
					db		23, 0, $A0, $FF,$FF, 2				; clear all command buffers

;============================================================================================================
clear_playarea:
					ld		bc, vdu_clg_end - @vdu_clg_area
					ld		hl, @vdu_clg_area
					call	batchvdu
					call	sprite_invalidate_all
					ret

@vdu_clg_area:
					db		24								; set graphics viewport
					dw		0
clg_area_bottom:	dw		511
clg_area_right:		dw		383
clg_area_top:		dw		50								; 0,539,359,50 left, bottom, right, top,
					db		16								; CLG
vdu_clg_end:

;============================================================================================================
gfx_present_twice:
					ld		a,(double_buffer)
					or		a
					jr		z,gfx_present

					call	sendbatchvdu
					call	callbatchvdu_twice
					jr		gfx_present_wait

gfx_present:
					call	sendbatchvdu
					call	callbatchvdu
gfx_present_wait:
					ld		hl,frame_counter
					inc		(hl)
					
					ld		hl,(sys_timer_addr)
					ld		b,(hl)
					ld		a,(vsync_counter)
					cp		b
					jr		nz,@frame2
@wait:
					ld		a,(hl)
					cp		b
					jr		z, @wait
					ld		b,a
@frame2:

@wait2:
					ld		a,(hl)
					cp		b
					jr		z, @wait2

					ld		(vsync_counter),a

					call	update_gtime
					ret

vsync_counter:		db		0


;============================================================================================================

sendbatchvdu:
					ret		; BATCH VDU BUFFERING DISABLED FOR NOW

					ld		bc,(vdu_buf_count)
					ld		a,b
					or		c
					ret		z

					ld		hl,vdu_write_buf_len
					ld		(hl),c
					inc		hl
					ld		(hl),b
					inc		bc
					inc		bc
					inc		bc
					inc		bc
					inc		bc
					inc		bc
					inc		bc
					inc		bc
					ld		hl,vdu_write_buffer
@loop:
@wait_CTS:
					in0		a,($A2)
					tst		a, 8					; Check Port D, bit 3 (CTS)
					jr		nz, @wait_CTS
@TX1:
					in0		a,($C5)					; Get the line status register
					and 	$40						; Check for TX empty
					jr		z, @TX1					; If not set, then TX is not empty so wait until it is

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 1
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 2
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 3
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 4
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 5
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 6
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 7
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 8
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 9
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 10
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 11
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 12
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 13
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 14
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 15
					dec		bc
					ld		a,b
					or		c
					jp		z, @done

					ld		a,(hl)
					inc		hl
					out0	($C0),A					; Write the character to the UART transmit buffer 16

					dec		bc
					ld		a,b
					or		c
					jp		nz, @loop
@done:
					ret
callbatchvdu:
					ret		; BATCH VDU BUFFERING DISABLED FOR NOW

					ld		hl,vdu_call_buffer
					call	vdu
initbatchvdu:
					or		a
					sbc		hl,hl
					ld		(vdu_buf_count),hl
					ld		hl,vdu_buffer
					ld		(vdu_buf_ptr),hl
					ret

callbatchvdu_twice:
					ret		; BATCH VDU BUFFERING DISABLED FOR NOW

					ld		hl,vdu_call_buffer_twice
					call	vdu
					jr		initbatchvdu

batchvdu:
					push	de	
					rst.lil	$18
					pop		de
					ret

					; BATCH VDU BUFFERING DISABLED FOR NOW

					push	de
					push	hl
					ld		hl,(vdu_buf_count)
					add		hl,bc
					ld		(vdu_buf_count),hl
					pop		hl
					ld		de,(vdu_buf_ptr)
					ldir
					ld		(vdu_buf_ptr),de
					pop		de
					ret



vdu_buf_count:		dl		0
vdu_buf_ptr:		dl		0
vdu_call_buffer:	db		12, 23, 0, $A0, 1,0, 1,  23, 0, $A0, 1,0, 2

vdu_call_buffer_twice:
					db		18
					db		23, 0, $A0, 1,0, 1				; call command buffer 1
					db		23, 0, $A0, 1,0, 1				; call command buffer 1
					db		23, 0, $A0, 1,0, 2				; clear command buffer 1

;============================================================================================================

vdu:				ld		bc,$000000
					ld		c,(hl)				; BC = number of bytes to send
					inc		hl
					ld		a,b					; A = 0
					rst.lil	18h
					ret

vduxl:				ld		bc,(hl)				; BC = number of bytes to send				
					inc		hl
					inc		hl
					inc		hl
					xor		a
					rst.lil	18h
					ret

;============================================================================================================
;
;	Graphics primitives
;
;============================================================================================================

gfx_vsync:
					ld		a,(double_buffer)
					or		a
					jr		z, gfx_vsync_or_flip
					ret

gfx_flip:
					ld		a,(double_buffer)
					or		a
					jr		nz, gfx_vsync_or_flip
					ret

gfx_vsync_or_flip:
					push	bc
					push	hl
					ld		hl,vdu_flip_codes
					ld		bc,3
					call	batchvdu
					pop		hl
					pop		bc
					ret


gfx_flush:
					push	bc
					push	hl
					ld		hl,vdu_flush
					ld		bc,3
					call	batchvdu
					pop		hl
					pop		bc
					ret
;============================================================================================================

; BC = x1, DE = y, HL = x2

gfx_draw_hline:
					push	bc
					push	hl
					push	ix
					ld		ix,@vdu_hline_codes
					ld		(ix+2),c
					ld		(ix+3),b
					ld		(ix+4),e
					ld		(ix+5),d
					ld		(ix+8),l
					ld		(ix+9),h
					ld		(ix+10),e
					ld		(ix+11),d
					lea		hl,ix+0
					ld		bc,12
					call	batchvdu
					pop		ix
					pop		hl
					pop		bc
					ret

@vdu_hline_codes:	db		25, 4, 0, 0, 0, 0			; MOVE x,y
					db		25, 5, 0, 0, 0, 0	 		; DRAW x,y

;============================================================================================================

;
; gfx_move : move graphics cursor to x,y
; BC = x, DE = y
;
gfx_move:
					push	bc
					push	de
					push	hl

					ld		hl,vdu_move_codes+2
					ld		(hl),c
					inc		hl
					ld		(hl),b
					inc		hl
					ld		(hl),e
					inc		hl
					ld		(hl),d
					ld		hl,vdu_move_codes
					ld		bc,6
					call	batchvdu

					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

; plot pixel BC = x, DE = y
gfx_plot_pixel:
					push	bc
					push	de
					push	hl

					ld		hl,vdu_pixel_codes+2
					ld		(hl),c
					inc		hl
					ld		(hl),b
					inc		hl
					ld		(hl),e
					inc		hl
					ld		(hl),d
					ld		hl,vdu_pixel_codes
					ld		bc,6
					call	batchvdu

					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

gfx_draw_line:
					push	bc
					push	de
					push	hl
				
					ld		hl,vdu_draw_codes+2
					ld		(hl),c
					inc		hl
					ld		(hl),b
					inc		hl
					ld		(hl),e
					inc		hl
					ld		(hl),d
					ld		hl,vdu_draw_codes
					ld		bc,6
					call	batchvdu

					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

; draw filled rectangle BC = x, DE = y
gfx_draw_filled_rect:
					push	bc
					push	de
					push	hl
				
					ld		hl,vdu_fillrect_codes+2
					ld		(hl),c
					inc		hl
					ld		(hl),b
					inc		hl
					ld		(hl),e
					inc		hl
					ld		(hl),d
					ld		hl,vdu_fillrect_codes
					ld		bc,6
					call	batchvdu

					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

gfx_draw_circle:
					push	ix
					ld		ix,@vdu_circle_codes
					ld		(ix+2),c
					ld		(ix+3),b
					ld		(ix+4),e
					ld		(ix+5),d
					ld		(ix+8),l
					ld		(ix+9),h
					ld		hl,@vdu_circle_codes
					ld		bc,12
					call	batchvdu
					pop		ix
					ret

@vdu_circle_codes:	db		25, 4, 0, 0, 0, 0
					db		25,145, 0,0 ,0,0

;============================================================================================================

gfx_draw_filled_circle:
					push	ix
					ld		ix,@vdu_circle_codes
					ld		(ix+2),c
					ld		(ix+3),b
					ld		(ix+4),e
					ld		(ix+5),d
					ld		(ix+8),l
					ld		(ix+9),h
					ld		hl,@vdu_circle_codes
					ld		bc,12
					call	batchvdu
					pop		ix
					ret

@vdu_circle_codes:	db		25, 4, 0, 0, 0, 0
					db		25,153, 0,0 ,0,0

;============================================================================================================

gfx_draw_triangle:
					push	bc
					push	de
					push	hl
				
					ld		hl,vdu_triangle_codes+2
					ld		(hl),c
					inc		hl
					ld		(hl),b
					inc		hl
					ld		(hl),e
					inc		hl
					ld		(hl),d
					ld		hl,vdu_triangle_codes
					ld		bc,6
					call	batchvdu

					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

gfx_pen_colour:
					push	bc
					push	de
					push	hl
				
					ld		hl,gfx_current_pen
					cp		(hl)
					jr		z,@skip
					ld		(hl),a
				
					ld		(vdu_pen_codes+2),a
					ld		hl,vdu_pen_codes
					ld		bc,3
					call	batchvdu
@skip:
					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

gfx_set_pen:
					push	bc
					push	de
					push	hl
				
					ld 		(gfx_current_pen),a
					ld		(vdu_pen_codes+2),a
					ld		hl,vdu_pen_codes
					ld		bc,3
					call	batchvdu
@skip:
					pop		hl
					pop		de
					pop		bc
					ret

;============================================================================================================

; gfx_draw_bitmap: A = bitmap ID, BC = xpos, DE = ypos
gfx_draw_bitmap:
					push	ix
					ld		ix,@vdu_draw_bitmap
					ld		(ix+3),a
					ld		(ix+7),c
					ld		(ix+8),b
					ld		(ix+9),e
					ld		(ix+10),d
					lea		hl,ix+0
					ld		bc,11
					call	batchvdu
					pop		ix
					ret

@vdu_draw_bitmap:	db 		23, 27, $20, 0, $B1
					db		25, $ED, 0, 0, 0, 0
					;db		23, 27, 3, 0, 0, 0, 0

;============================================================================================================

; gfx_draw_bitmap: A = bitmap number (8 bit), BC = xpos, DE = ypos
gfx_draw_bitmap8:
					push	ix
					ld		ix,@vdu_draw_bitmap
					ld		(ix+3),a
					ld		(ix+6),c
					ld		(ix+7),b
					ld		(ix+8),e
					ld		(ix+9),d
					lea		hl,ix+0
					ld		bc,10
					call	batchvdu
					pop		ix
					ret

@vdu_draw_bitmap:	db 		23, 27, 0, 0
					db		25, $ED, 0, 0, 0, 0
;============================================================================================================

gfx_write_centre_text:
					push	hl
					call	strlen
					ld		b,a
					ld		a,(half_txt_columns)
					sub		c
					ld		c,a
					call	gfx_move_txt
					pop		hl
					jr		gfx_draw_text

;============================================================================================================


gfx_draw_cstring:
					call	strlen
					call	batchvdu
					ret

;============================================================================================================

; set pen colour : 1,pen
; move row,col	 : 2,row,col
; set paper		 : 3,paper
; new line		 : 10

gfx_draw_text:
					ld		bc,(vdu_buf_count)
					ld		de,(vdu_buf_ptr)
@loop:
					ld		a,(hl)
					inc		hl
					or		a
					jr		z,@done
					cp		1
					jr		z,@setpen
					cp		2
					jr		z,@move
					cp		3
					jr		z,@setpaper
					cp		10
					jr		z,@newline
					ld		(de),a
					inc		de
					inc		bc
					jr		@loop
@done:
					ld		(vdu_buf_ptr),de
					ld		(vdu_buf_count),bc
					ret
@newline:
					ld		(vdu_buf_ptr),de
					ld		(vdu_buf_count),bc

					push	hl
					ld		hl,txt_start_x
					ld		c,(hl)
					inc		hl
					ld		b,(hl)
					pop		hl
					inc		b
					call	gfx_move_txt
					jp		gfx_draw_text

@setpen:
					ld		a,(hl)
					inc		hl
					push	hl
					ld		hl,gfx_current_pen
					bit		7,a
					jr		z,@ispen
					ld		hl,gfx_current_paper
@ispen:
					cp		(hl)
					jr		z,@donepen

					ld		(hl),a

					ld		a,18
					ld		(de),a
					inc		de
					inc		bc

					xor		a
					ld		(de),a
					inc		de
					inc		bc

					ld		a,(hl)
					ld		(de),a
					inc		de
					inc		bc
@donepen:
					pop		hl
					jr		@loop

@setpaper:
					ld		a,(hl)
					inc		hl
					push	hl
					ld		hl,gfx_current_paper
					cp		(hl)
					jr		z,@donepaper

					ld		(hl),a

					ld		a,18
					ld		(de),a
					inc		de
					inc		bc

					xor		a
					ld		(de),a
					inc		de
					inc		bc

					ld		a,(hl)
					or		128
					ld		(de),a
					inc		de
					inc		bc
@donepaper:
					pop		hl
					jp		@loop


@move:
					ld		(vdu_buf_ptr),de
					ld		(vdu_buf_count),bc

					ld		b,(hl)
					inc		hl
					ld		c,(hl)
					inc		hl
					call	gfx_move_txt
					jp		gfx_draw_text

;============================================================================================================

; on entry: A = text row | on exit: DE = gfx y pos
gfx_get_text_row:
					or		a
					sbc		hl,hl
					ld		l,a
					add		hl,hl
					ld		de,txt_screen_rows
					add		hl,de
					ld		e,(hl)
					inc		hl
					ld		d,(hl)
					ret

;============================================================================================================

; B = row, C = column
gfx_move_txt:
					push	af
					push	de
					push	hl

					ld		hl,txt_start_x
					ld		(hl),c
					inc		hl
					ld		(hl),b

					or		a
					sbc		hl,hl
					ld		l,b
					add		hl,hl
					ld		de,txt_screen_rows
					add		hl,de
					ld		e,(hl)
					inc		hl
					ld		d,(hl)

					or		a
					sbc		hl,hl

					ld		l,c
					add		hl,hl
					add		hl,hl
					ld		b,h
					ld		c,l

					call	gfx_move

					pop		hl
					pop		de
					pop		af
					ret

@vdu_move_txt:		db 		31,0,0

txt_start_x:		db		0


;============================================================================================================

; gfx_upload_bitmap: convert an indexed bitmap to ABGR 8-bit (RGBA2222) and upload it to the VDP
; HL = address of bitmap data
; A = bitmap number
gfx_upload_bitmap:
					push	af
					push	bc
					push	ix

					ld		(bitmap_buffer_id1),a
					ld		(bitmap_buffer_id2),a
					ld		(bitmap_buffer_id3),a

					push	hl
					pop		ix							; IX = HL = start of bitmap data

					ld		h,(ix + 0)					; B = width of bitmap
					ld		l,(ix + 1)					; C = height of bitmap
					inc		ix
					inc		ix

					ld		a,h
					ld		(bitmap_buffer_w),a
					ld		a,l
					ld		(bitmap_buffer_h),a

					mlt		hl							; HL = H * L (total number of bytes in data)
					ld		b,h
					ld		c,l

					ld		a,l
					ld		(bitmap_buffer_len),a
					ld		a,h
					ld		(bitmap_buffer_len+1),a

					ld		de,14
					add		hl,de						; add 14 bytes for the VDU command codes
					push	hl

					ld		iy,bitmap_buffer
					;ld		de,0
@expandloop:
					ld		e,(ix+0)
					inc		ix
					ld		hl,@palette2222
					add		hl,de
					ld		a,(hl)
					ld		(iy+0),a
					inc		iy
					dec		bc
					ld		a,b
					or		c
					jr		nz,@expandloop

					pop		bc							; BC = size of data to send
					ld		hl,bitmap_buffer_header
					rst.lil	18h

					ld		hl,bitmap_create
					ld		bc,13
					rst.lil	18h

					pop		ix
					pop		bc
					pop		af
					ret

@palette2222:
					db		%11000000					; 0
					db		%11000010					; 1
					db		%11001000					; 2
					db		%11001010					; 3
					db		%11100000					; 4
					db		%11100010					; 5
					db		%11101000					; 6
					db		%11101010					; 7
					db		%11010101					; 8
					db		%11000011					; 9
					db		%11001100					; 10
					db		%11001111					; 11
					db		%11110000					; 12
					db		%11110011					; 13
					db		%11111100					; 14
					db		%11111111					; 15
					db		%00000000					; 16

;============================================================================================================

; Print a zero-terminated string
printz:
					push	af
					push	bc
					ld		bc,0
					xor		a
					rst.lil	18h
					pop		bc
					pop		af
					ret

;============================================================================================================

line_codes:
vdu_move_codes:		db		25, 4, 0, 0, 0, 0			; MOVE x,y
vdu_draw_codes:		db		25, 5, 0, 0, 0, 0	 		; DRAW x,y
vdu_pixel_codes:	db		25, 69, 0, 0, 0, 0	 		; PIXEL x,y
vdu_triangle_codes:	db		25, $55, 0, 0, 0, 0			; TRIANGLE x,y
vdu_fillrect_codes:	db		25, 101, 0, 0, 0, 0			; RECTANGLE FILL x,y
vdu_flip_codes:		db		23, 0, $C3					; flip screen buffers
vdu_pen_codes:		db		18, 0,0						; GCOL 0,a
vdu_flush:			db		23, 0, $CA
gfx_current_pen:	db		255
gfx_current_paper:	db		0

half_txt_columns:	db		64							; text columns / 2

txt_screen_rows:	dw		0, 9, 19, 28, 38, 48, 57, 67, 76, 86, 96, 105, 115, 124, 134, 144, 153, 163, 172, 182, 192
					dw		201, 211, 220, 230, 240, 249, 259, 268, 278, 288, 297, 307, 316, 326, 336, 345, 355, 364, 374

double_buffer:		db		0
frame_counter:		dl		0

;============================================================================================================

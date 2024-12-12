;============================================================================================================
;
; 8888888 888b    888 8888888b.  888     888 88888888888 
;   888   8888b   888 888   Y88b 888     888     888     
;   888   88888b  888 888    888 888     888     888     
;   888   888Y88b 888 888   d88P 888     888     888     
;   888   888 Y88b888 8888888P"  888     888     888     
;   888   888  Y88888 888        888     888     888     
;   888   888   Y8888 888        Y88b. .d88P     888     
; 8888888 888    Y888 888         "Y88888P"      888     
;
;============================================================================================================
;
; Input routines (keyboard, mouse, game controllers).
;
; Written by Christian Pinder. 2024
;============================================================================================================

;============================================================================================================
;
; Keyboard routines
;
;============================================================================================================

KBD_APPLICATION:	EQU	127
KBD_AT:				EQU	71
KBD_BACKSPACE:		EQU	47
KBD_BREAK:			EQU	44
KBD_CAPSLOCK:		EQU	64
KBD_CARET:			EQU	24
KBD_COLON:			EQU	72
KBD_COMMA:			EQU	102
KBD_DELETE:			EQU	89
KBD_END:			EQU	105
KBD_EQUALS:			EQU	93
KBD_ESCAPE:			EQU	112
KBD_GRAVEACCENT:	EQU	45
KBD_HOME:			EQU	62
KBD_INSERT:			EQU	61
KBD_KP_0:			EQU	106
KBD_KP_1:			EQU	107
KBD_KP_2:			EQU	124
KBD_KP_3:			EQU	108
KBD_KP_4:			EQU	122
KBD_KP_5:			EQU	123
KBD_KP_6:			EQU	26
KBD_KP_7:			EQU	27
KBD_KP_8:			EQU	42
KBD_KP_9:			EQU	43
KBD_KP_DELETE:		EQU	75
KBD_KP_DIVIDE:		EQU	74
KBD_KP_ENTER:		EQU	60
KBD_KP_MINUS:		EQU	59
KBD_KP_MULTIPLY:	EQU	91
KBD_KP_PERIOD:		EQU	76
KBD_KP_PLUS:		EQU	58
KBD_LALT:			EQU	5
KBD_LCTRL:			EQU	4
KBD_LEFTBRACKET:	EQU	56
KBD_LGUI:			EQU	125
KBD_LSHIFT:			EQU	3
KBD_MINUS:			EQU	23
KBD_NUMLOCK:		EQU	77
KBD_PAGEDOWN:		EQU	78
KBD_PAGEUP:			EQU	63
KBD_PERIOD:			EQU	103
KBD_PRINTSCREEN:	EQU	32
KBD_RALT:			EQU	8
KBD_RCTRL:			EQU	7
KBD_RETURN:			EQU	73
KBD_RGUI:			EQU	126
KBD_RIGHTBRACKET:	EQU	88
KBD_RSHIFT:			EQU	6
KBD_SCROLLLOCK:		EQU	31
KBD_SEMICOLON:		EQU	87
KBD_SLASH:			EQU	104
KBD_SPACE:			EQU	98
KBD_TAB:			EQU	96
KBD_UNDERSCORE:		EQU	95

KBD_UP:				EQU	57
KBD_DOWN:			EQU	41
KBD_LEFT:			EQU	25
KBD_RIGHT:			EQU	121

KBD_F1:				EQU	113
KBD_F2:				EQU	114
KBD_F3:				EQU	115
KBD_F4:				EQU	20
KBD_F5:				EQU	116
KBD_F6:				EQU	117
KBD_F7:				EQU	22
KBD_F8:				EQU	118
KBD_F9:				EQU	119
KBD_F10:			EQU	30
KBD_F11:			EQU	28
KBD_F12:			EQU	29

KBD_0:				EQU	39
KBD_1:				EQU	48
KBD_2:				EQU	49
KBD_3:				EQU	17
KBD_4:				EQU	18
KBD_5:				EQU	19
KBD_6:				EQU	52
KBD_7:				EQU	36
KBD_8:				EQU	21
KBD_9:				EQU	38
KBD_A:				EQU	65
KBD_B:				EQU	100
KBD_C:				EQU	82
KBD_D:				EQU	50
KBD_E:				EQU	34
KBD_F:				EQU	67
KBD_G:				EQU	83
KBD_H:				EQU	84
KBD_I:				EQU	37
KBD_J:				EQU	69
KBD_K:				EQU	70
KBD_L:				EQU	86
KBD_M:				EQU	101
KBD_N:				EQU	85
KBD_O:				EQU	54
KBD_P:				EQU	55
KBD_Q:				EQU	16
KBD_R:				EQU	51
KBD_S:				EQU	81
KBD_T:				EQU	35
KBD_U:				EQU	53
KBD_V:				EQU	99
KBD_W:				EQU	33
KBD_X:				EQU	66
KBD_Y:				EQU	68
KBD_Z:				EQU	97

KBD_NUM_KEYS:		EQU		128

;============================================================================================================

kbd_set_repeat:
					ld		(kbd_repeat),hl
					ret

;============================================================================================================

kbd_init:
					ld		a,$1e
					rst.lil	$08
					ld		(mos_keymap_addr),ix

					ld		hl,30						; 1/4 of a second
					call	kbd_set_repeat
kbd_reset:
					ld		hl, kbd_states
					xor		a
					ld		b,KBD_NUM_KEYS
@clear_loop:
					ld		(hl),a
					inc		hl
					djnz	@clear_loop

					ld		bc,0
					ld		de,0
					ld		ix,kbd_timer
					jp		init_timer

mos_keymap_addr:	dl		0
;============================================================================================================

; check if a key is down. A = keycode. returns NZ if down, Z if up.
kbd_check_down:
					push	bc
					push	de
					push	hl

					ld		de,(mos_keymap_addr)
					or		a
					sbc		hl,hl
					ld		l,a
					srl		l
					srl		l
					srl		l
					add		hl,de
					ex		de,hl

					or		a
					sbc		hl,hl
					and		7
					ld		l,a
					ld		bc,@bit_masks
					add		hl,bc

					ld		a,(de)
					and		(hl)

					pop		hl
					pop		de
					pop		bc					
					ret

@bit_masks:			db		1,2,4,8,16,32,64,128

;============================================================================================================

; non-repeating key check. A = keycode. returns NZ if pressed.
; key has to be released and pressed again to register another press.
kbd_check_pressed:
					push	bc
					push	hl

					or		a
					sbc		hl,hl
					ld		l,a
					ld		bc,kbd_states
					add		hl,bc

					call	kbd_check_down
					jr		nz,@pressed
					xor		a
					ld		(hl),a
					jr		@done
@pressed:
					ld		a,(hl)
					or		a
					jr		z,@notchecked
					xor		a
					jr		@done

@notchecked:
					inc		a
					ld		(hl),a
@done:
					pop		hl
					pop		bc
					ret

;============================================================================================================

; repeating key check. A = keycode. returns NZ if down, Z if up.
; registers the same key being held down on a repeat timer.
kbd_check_repeat:
					push	bc
					push	hl
					push	ix

					ld		ix,kbd_timer

					or		a
					sbc		hl,hl
					ld		l,a
					ld		bc,kbd_states
					add		hl,bc

					call	kbd_check_down
					jr		nz,@pressed
					xor		a
					ld		(hl),a
					jr		@done
@pressed:
					ld		a,(hl)
					or		a
					jr		z,@notchecked

					call	update_timer
					jr		c,@notchecked

					xor		a
					jr		@done

@notchecked:
					ld		(hl),1

					ld		bc,(kbd_repeat)
					ld		de,0
					call	init_timer

					or		1						; clear the zero flag
@done:
					pop		ix
					pop		hl
					pop		bc
					ret

;============================================================================================================

kbd_read_down:
					push	bc
					push	hl

					ld		hl,(mos_keymap_addr)
					ld		b,16
					ld		c,0
@loop:
					ld		a,(hl)
					or		a
					jr		nz,@found

					inc		hl
					inc		c
					djnz	@loop

; if we get to here then nothing was pressed
					or		a							; clear the carry flag
					jr		@done						; pop saved registers and return

; we found a key down
@found:
					sla		c
					sla		c
					sla		c							; C = C * 8
@rotate:
					inc		c
					rra
					jr		nc,@rotate
					scf
@done:
					pop		hl
					pop		bc
					ret

;============================================================================================================

kbd_wait_key:
					call	kbd_read_down
					jr		nc,kbd_wait_key
					ret

;============================================================================================================

kbd_timer:			dl		0,0				; ix+0, ix+3
					dl		0				; ix+6
					dl		0				; ix+9

kbd_repeat:			dl		0

kbd_states:			ds		KBD_NUM_KEYS





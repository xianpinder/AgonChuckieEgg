;============================================================================================================
;
; 88888888888 8888888 888b     d888 8888888888 
;     888       888   8888b   d8888 888        
;     888       888   88888b.d88888 888        
;     888       888   888Y88888P888 8888888    
;     888       888   888 Y888P 888 888        
;     888       888   888  Y8P  888 888        
;     888       888   888   "   888 888        
;     888     8888888 888       888 8888888888 
;
;============================================================================================================
;
; Game time and timer routines
;
; Written by Christian Pinder. 2024
;============================================================================================================


global_time:		dl		0
global_time_hi:		dl		0

; a timer is four longs
;timer:             dl      0,0,0,0

;============================================================================================================

update_gtime:
					ld		hl,(sys_timer_addr)
					ld		de,global_time
					ldi
					ldi
					ldi
					ldi
					ret

;============================================================================================================

; IX = timer, BC = count, DE = interval (120 ticks equals one second)
init_timer:
					ld		hl,(global_time)
					ld		(ix+0),hl
					ld		hl,(global_time_hi)
					ld		(ix+3),hl
					ld		(ix+6),bc		; number of ticks until timer goes off
					ld		(ix+9),de		; interval
					ret

;============================================================================================================

; update_timer: IX = timer. Returns carry set if timer has gone off, otherwise carry clear
update_timer:
					push	de
					push	hl

; if the coutdown and the interval are both zero then
; the timer is turned off so return

					ld		a,(ix+6)
					or		(ix+7)
					or		(ix+8)
					or		(ix+9)
					or		(ix+10)
					or		(ix+11)
					jr		z,@done

; calculate how long it has been since the timer started
					ld		hl,(global_time)
					ld		de,(ix+0)
					or		a
					sbc		hl,de					; HL = global_time - timer_start

; if time_since_start >= countdown then the timer goes off
					ld		de,(ix+6)
					or		a
					sbc		hl,de					; HL = time_since_start - countdown
					jr		nc,@goneoff
					or		a
					jr		@done

; timer has gone off
@goneoff:
					ld		hl,(ix+9)
					ld		(ix+6),hl				; countdown = interval
					ld		hl,(global_time)
					ld		(ix+0),hl
					ld		hl,(global_time_hi)
					ld		(ix+3),hl				; timer_start = now
					scf
@done:
					pop		hl
					pop		de
					ret

;============================================================================================================

wait_delay:
					push	de
					push	hl
					push	ix

					ld		ix,(sys_timer_addr)
					ld		hl,(ix+0)
					add		hl,bc
					ex		de,hl
@loop:
					ld		hl,(ix+0)
					or		a
					sbc		hl,de
					jr		c,@loop

					pop		ix
					pop		hl
					pop		de
					ret
;============================================================================================================

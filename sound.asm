;============================================================================================================
;
;  .d8888b.   .d88888b.  888     888 888b    888 8888888b.  
; d88P  Y88b d88P" "Y88b 888     888 8888b   888 888  "Y88b 
; Y88b.      888     888 888     888 88888b  888 888    888 
;  "Y888b.   888     888 888     888 888Y88b 888 888    888 
;     "Y88b. 888     888 888     888 888 Y88b888 888    888 
;       "888 888     888 888     888 888  Y88888 888    888 
; Y88b  d88P Y88b. .d88P Y88b. .d88P 888   Y8888 888  .d88P 
;  "Y8888P"   "Y88888P"   "Y88888P"  888    Y888 8888888P"  
;
;============================================================================================================
;
; Sound routines
; Written by Christian Pinder. 2024
;
;============================================================================================================
snd_init:
					ld		hl,vdu_snd_init
					ld		bc,vdu_snd_init_end - vdu_snd_init
					rst.lil	$18

					ret

;============================================================================================================

; HL = address of envelope data
snd_set_vol_env:
					push	bc
					push	de
					push	hl

					ld		bc,8
					ld		de,vdu_vol_env+3
					ldi
					inc		de
					inc		de
					ldir

					ld		hl,vdu_vol_env
					ld		bc,13
					call	batchvdu

					pop		hl
					pop		de
					pop		bc
					ret


;============================================================================================================

; B = volume
; C = channel
; DE = duration
; HL = pitch
snd_play_sound:
					push	ix

					ld		ix,vdu_play_sound
					ld		(ix+3),c
					ld		(ix+5),b
					ld		(ix+6),l
					ld		(ix+7),h
					ld		(ix+8),e
					ld		(ix+9),d
					lea		hl,ix+0
					ld		bc,10
					call	batchvdu

					pop		ix
					ret

;============================================================================================================

; A = pitch
; B = volume
; C = channel
; D = duration
snd_play_beeb_sound:
					push	ix
					ld		ix,vdu_play_sound

; save frequency in HL
					or		a
					sbc		hl,hl
					ld		l,a

; Set the duration (agon duration = 50 * beeb duration)
					ld		e,50
					mlt		de
					ld		(ix+8),e
					ld		(ix+9),d

; Set the volume. Beeb uses -15 (loudest) to 0 (silent).
; volume > 0 means use an envelope (will be target volume for agon style envelope)

					ld		a,b
					bit		7,a
					jr		z,@use_envelope
					neg
; scale 0..15 to 0..127
					ld		d,17
					ld		e,a
					mlt		de
					srl		e
					ld		a,e
@use_envelope:
					ld		(ix+5),a

; Set the channel
					ld		a,c
					and		3
					jr		nz,@notnoise

; Beeb channel zero is noise generator.
; Pitch is number from 0..7 which indicates type of noise.
; We simulate types 4,5,6 using VIC noise frequency.
					ld		(ix+3),a							; set channel to zero

					ld		a,l
					cp		4
					jr		nz,@nothigh
					ld		hl,120
					jr		@setnoise
@nothigh:
					cp		5
					jr		nz,@notmed
					ld		hl,64
					jr		@setnoise
@notmed:
					ld		hl,40
@setnoise:
					ld		(ix+6),l
					ld		(ix+7),h
					jr		@donepitch
@notnoise:
					ld		(ix+3),a

; Look up the frequency for the beeb pitch value
					add		hl,hl
					ld		de,beeb_freq_table
					add		hl,de
					ld		a,(hl)
					inc		hl
					ld		(ix+6),a
					ld		a,(hl)
					ld		(ix+7),a
@donepitch:
					lea		hl,ix+0
					ld		bc,10
					call	batchvdu

					pop		ix
					ret

;============================================================================================================

vdu_play_sound:
					db 		23, 0, $85		; audio commands
					db		0				; channel
					db		0				; 0 = play sound command
					db		0				; volume
					db		0,0				; frequency
					db		0,0				; duration

vdu_vol_env:
					db		23, 0, $85		; audio commands
					db		0				; channel
					db		6				; 6 = volume envelope
					db		1				; 1 = ADSR
					db		0,0				; attack
					db		0,0				; decay
					db		0				; sustain
					db		0,0				; release

vdu_snd_init:
					db		23, 0, $85, 0, 4, 5			; set channel 0 to VIC noise

					db		23, 0, $85, 0, 13
					dw		4000
vdu_snd_init_end:	


; Table to match BBC Micro sound pitch values (0-255) to their frequency.
; Based on Acorn MOS 1.00 and channel 1 (other channels differ slightly).
beeb_freq_table:
					dw		 124,  126,  128,  129,  131,  133,  135,  137,  139,  141
					dw		 143,  145,  148,  150,  152,  154,  156,  158,  161,  163
					dw		 166,  168,  170,  172,  176,  178,  181,  183,  186,  189
					dw		 191,  194,  197,  200,  203,  206,  209,  212,  214,  217
					dw		 221,  224,  228,  231,  234,  237,  240,  244,  248,  252
					dw		 255,  259,  263,  267,  271,  274,  278,  282,  286,  290
					dw		 296,  300,  304,  309,  313,  317,  321,  326,  332,  336
					dw		 341,  345,  351,  356,  361,  367,  372,  378,  382,  388
					dw		 394,  399,  406,  411,  418,  424,  430,  436,  443,  450
					dw		 456,  463,  468,  475,  481,  488,  496,  504,  510,  519
					dw		 527,  534,  541,  548,  558,  566,  573,  581,  592,  601
					dw		 610,  619,  625,  635,  644,  654,  665,  672,  683,  691
					dw		 702,  714,  723,  735,  744,  758,  767,  776,  791,  801
					dw		 812,  822,  839,  850,  862,  874,  887,  899,  912,  926
					dw		 940,  954,  962,  977,  992, 1008, 1025, 1042, 1059, 1068
					dw		1087, 1096, 1116, 1136, 1147, 1168, 1190, 1202, 1225, 1238
					dw		1250, 1276, 1289, 1316, 1330, 1344, 1374, 1389, 1404, 1437
					dw		1453, 1471, 1488, 1524, 1543, 1563, 1582, 1603, 1623, 1645
					dw		1689, 1712, 1736, 1761, 1786, 1812, 1838, 1866, 1894, 1923
					dw		1923, 1953, 1984, 2016, 2049, 2083, 2119, 2155, 2193, 2193
					dw		2232, 2273, 2315, 2358, 2404, 2404, 2451, 2500, 2500, 2551
					dw		2604, 2660, 2660, 2717, 2778, 2778, 2841, 2907, 2907, 2976
					dw		2976, 3049, 3125, 3125, 3205, 3205, 3289, 3289, 3378, 3472
					dw		3472, 3571, 3571, 3676, 3676, 3788, 3788, 3906, 3906, 3906
					dw		4032, 4032, 4167, 4167, 4310, 4310, 4464, 4464, 4464, 4630
					dw		4630, 4808, 4808, 4808, 5000, 5000
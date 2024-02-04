/*
 *  Uzebox Kernel - Mode 72, Sprite mode 4
 *  Copyright (C) 2017 Sandor Zsuga (Jubatian)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Uzebox is a reserved trade mark
*/

;=============================================================================
;
; Video mode 72, Sprite mode 4
;
; 2 x 60 pixels wide RAM sprites split up in the following manner:
; 0 - 3: 12 - 16 - 16 - 16 pixels, data is straight.
; 4 - 7: 12 - 16 - 16 - 16 pixels, data is mirrored.
; Individual components can be moved on X axis. For sprite 4, new colors and a
; new data offset can be used which can be utilized to set up mirroring. This
; is the largest possible horizontal coverage.
;
; Sprites are available in the following manner:
;
; +--------------+--------------+--------------+
; | m72_bull_cnt | Main sprites | Bullets      |
; +==============+==============+==============+
; |        (any) |    8 (0 - 7) |    0 (none)  |
; +--------------+--------------+--------------+
;
;=============================================================================



.section .text



;
; Scanline notes:
;
; The horizontal layout with borders is constructed to show as if there were
; 24 tiles (or 48 in text mode).
;
; Cycles:
;
; Entry:                 ; (1631)
; out   PIXOUT,  (zero)  ; (1698) Black border begins
; cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
; sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
; out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
; Last cycle:            ; ( 461)
;
; Registers:
;
;  r1: r0: Temp
;  r2:     Background color
;  r3- r5: Temp (Could be sprite colors)
;  r6-r16: Background colors
; r17:     Border color
; r18:     Physical scanline (use to check sprite Y)
; r19:     Log. scanline (no usage)
; r20:     Temp, starts out being Zero (can be used for black border)
; r21:     Temp, usually used by sp_next
; r22-r24: Temp
; r25:     Temp, starts out being Bullet count
;  ZH: ZL: Work pointer (code tiling etc.)
;  YH: YL: Work pointer (for sprite data access)
;  XH: XL: Line buffer access
;
; Return sequence (after last cycle):
;
; ldi   ZL,      15
; out   STACKL,  ZL
; pop   r0
; out   PIXOUT,  r0      ; ( 466) Pixel 0
; jmp   m72_graf_scan_b
;
; Video stack top = LB_STACK - 1 may be used
;



;
; Entry point
;
m72_sp4:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	ldi   r24,     15           ; (1634) 60px wide sprites


	; (1634) Sprite 0 init

	ldi   ZL,      lo8(v_sprd + (5 * 0))
	ldi   ZH,      hi8(v_sprd + (5 * 0))
	ld    r0,      Z+      ; ( 4) YPos
	add   r0,      r18     ; ( 5) Line within sprite acquired
	ld    XL,      Z+      ; ( 7) Height
	cp    r0,      XL
	brcc  sp4_0ina         ; ( 9 / 10)
	mul   r0,      r24     ; (11) r24 = 15; 60px wide sprites
	ldd   YL,      Z + 40  ; (13) OffLo
	add   YL,      r0
	ldd   YH,      Z + 41  ; (16) OffHi + Mirror on bit 7
	adc   YH,      r1
	ldd   XL,      Z + 42  ; (19) XPos
	ld    r3,      Z+      ; (21) Color 1
	ld    r4,      Z+      ; (23) Color 2
	ld    r5,      Z+      ; (25) Color 3

	ldi   ZL,      lo8(v_sprd + (5 * 4) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 4) + 2)
	ldd   r22,     Z + 40  ; (29) OffLo
	add   r22,     r0
	ldd   r23,     Z + 41  ; (32) OffHi + Mirror on bit 7
	adc   r23,     r1
	ldd   r0,      Z + 42  ; (35) XPos of Sprite 4
	ld    r1,      Z+      ; (37) Color 1
	ld    r24,     Z+      ; (39) Color 2
	ld    r25,     Z+      ; (41) Color 3

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp4_0beg         ; (1678)

sp4_0ina:
	brne  sp4_0nnx         ; (11 / 12)
	WAIT  YL,      52      ; (63)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	rcall sp4_next         ; (1756)
	ldi   ZL,      lo8(v_sprd + (5 * 1) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 1) + 2)
	rcall sp4_next         ; (1816)
	WAIT  YL,      7       ; ( 3)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	ldi   ZL,      lo8(v_sprd + (5 * 2) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 2) + 2)
	rcall sp4_next         ; (  65)
	ldi   ZL,      lo8(v_sprd + (5 * 3) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 3) + 2)
	rcall sp4_next         ; ( 125)
	WAIT  YL,      14      ; ( 139)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	ldi   ZL,      lo8(v_sprd + (5 * 4) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 4) + 2)
	rcall sp4_next         ; ( 201)
	ldi   ZL,      lo8(v_sprd + (5 * 5) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 5) + 2)
	rcall sp4_next         ; ( 261)
	ldi   ZL,      lo8(v_sprd + (5 * 6) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 6) + 2)
	rcall sp4_next         ; ( 321)
	WAIT  YL,      32      ; ( 353)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	ldi   ZL,      lo8(v_sprd + (5 * 7) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 7) + 2)
	rcall sp4_next         ; ( 414)
	WAIT  YL,      45      ; ( 459)
	ldi   r20,     15      ; ( 460) For STACKL
	rjmp  sp4_0end         ; ( 462)
sp4_0nnx:
	WAIT  YL,      51
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  YL,      125
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  YL,      134
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  YL,      212
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  YL,      105     ; ( 459)
	ldi   r20,     15      ; ( 460) For STACKL
	rjmp  sp4_0end         ; ( 462)

sp4_0beg:


	; (1678) (59 + 4 - 2)

	ld    ZL,      Y+      ; ( 4)
	icall                  ; (21)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	lpm   ZL,      Z
	; -----------------
	ld    ZL,      Y+      ; (23)
	icall                  ; (40)
	ld    ZL,      Y+      ; (42)
	icall                  ; (59)

	; (1739) (78)

	lds   XL,      (v_sprd + (5 * 1) + 44) ; XPos of Sprite 1
	ld    ZL,      Y+      ; ( 4)
	icall                  ; (21)
	ld    ZL,      Y+      ; (23)
	icall                  ; (40)
	ld    ZL,      Y+      ; (42)
	icall                  ; (59)
	ld    ZL,      Y+      ; (61)
	icall                  ; (78)

	; (1817) (78 + 3)

	lds   XL,      (v_sprd + (5 * 2) + 44) ; XPos of Sprite 2
	ld    ZL,      Y+      ; ( 4)
	ld    r20,     Y+      ; (+2)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	icall                  ; (21)
	mov   ZL,      r20     ; (23) (-1)
	icall                  ; (40)
	ld    ZL,      Y+      ; (42)
	icall                  ; (59)
	ld    ZL,      Y+      ; (61)
	icall                  ; (78)

	; (  78) (78 + 2)

	lds   XL,      (v_sprd + (5 * 3) + 44) ; XPos of Sprite 3
	ld    ZL,      Y+      ; ( 4)
	icall                  ; (21)
	ld    ZL,      Y+      ; (23)
	icall                  ; (40)
	ld    ZL,      Y+      ; (42)
	icall                  ; (59)
	ld    ZL,      Y+      ; (61)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	icall                  ; (78)

	; ( 158) (59 + 3)

	movw  YL,      r22
	mov   XL,      r0
	mov   r3,      r1
	movw  r4,      r24
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 14  ; ( 4)
	icall                  ; (21)
	ldd   ZL,      Y + 13  ; (23)
	icall                  ; (40)
	ldd   ZL,      Y + 12  ; (42)
	icall                  ; (59)

	; ( 220) (78)

	lds   XL,      (v_sprd + (5 * 5) + 44) ; XPos of Sprite 5
	ldd   ZL,      Y + 11  ; ( 4)
	icall                  ; (21)
	ldd   ZL,      Y + 10  ; (23)
	icall                  ; (40)
	ldd   ZL,      Y + 9   ; (42)
	icall                  ; (59)
	ldd   ZL,      Y + 8   ; (61)
	icall                  ; (78)

	; ( 298) (78 + 1 + 13 - 1)

	lds   XL,      (v_sprd + (5 * 6) + 44) ; XPos of Sprite 6
	ldd   ZL,      Y + 7   ; ( 4)
	icall                  ; (21)
	ldd   ZL,      Y + 6   ; (23)
	icall                  ; (40)
	ldd   ZL,      Y + 5   ; (42)
	; --- (Preload) ---
	ldi   r20,     15      ; For STACKL
	ldd   r0,      Y + 4
	ldd   r1,      Y + 3
	ldd   r21,     Y + 2
	ldd   r22,     Y + 1
	ld    r23,     Y
	lds   r25,     (v_sprd + (5 * 7) + 44) ; XPos of Sprite 7
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	icall                  ; (59)
	mov   ZL,      r0      ; (61) (-1)
	icall                  ; (78)

	; ( 389) (78 - 5)

	mov   XL,      r25     ; ( 2) (-1) XPos of Sprite 7
	mov   ZL,      r1      ; ( 4) (-1)
	icall                  ; (21)
	mov   ZL,      r21     ; (23) (-1)
	icall                  ; (40)
	mov   ZL,      r22     ; (42) (-1)
	icall                  ; (59)
	mov   ZL,      r23     ; (61) (-1)
	icall                  ; (78)

sp4_0end:


	; ( 462) Go on to next line

	out   STACKL,  r20
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b



;
; Load next sprite code for sprite modes. Assumes entry with rcall.
;
; Z: Must point to the appropriate entry in the sprite list (v_sprd) + 2.
; Y: Used to copy next sprite data
; r21: Temp
;
sp4_next:

	sbiw  ZL,      2
	ldd   YL,      Z + 40  ; ( 5) NextLo
	ldd   YH,      Z + 41  ; ( 7) NextHi
	cpi   YH,      0
	breq  sp4_next_lie     ; (11 / 12)
	ld    r21,     Y+
	st    Z+,      r21     ; (15) YPos
	ld    r21,     Y+
	st    Z+,      r21     ; (19) Height
	ld    r21,     Y+
	std   Z + 40,  r21     ; (23) OffLo
	ld    r21,     Y+
	std   Z + 41,  r21     ; (27) OffHi
	ld    r21,     Y+
	cpi   r21,     176
	brcs  .+2
	ldi   r21,     176
	std   Z + 42,  r21     ; (34) XPos
	ld    r21,     Y+
	st    Z+,      r21     ; (38) Col0
	ld    r21,     Y+
	st    Z+,      r21     ; (42) Col1
	ld    r21,     Y+
	st    Z+,      r21     ; (46) Col2
	ld    r21,     Y+
	std   Z + 35,  r21     ; (50) NextLo
	ld    r21,     Y+
	std   Z + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp4_next_lie:
	std   Z + 0,   YH
	std   Z + 1,   YH      ; (16)
	adiw  ZL,      5       ; (18)
	WAIT  r21,     36      ; (54)
	ret                    ; (58)

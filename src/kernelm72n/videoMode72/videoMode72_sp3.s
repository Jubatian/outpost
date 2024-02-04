/*
 *  Uzebox Kernel - Mode 72, Sprite mode 3
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
; Video mode 72, Sprite mode 3
;
; 16 pixels wide RAM sprites grouped in pairs (0 - 1; 2 - 3; 4 - 5). The pairs
; share all properties expect X position (so of sprites 1, 3 and 5 only X is
; used). Sprite data is 32 pixels wide.
;
; Sprites are available in the following manner:
;
; +--------------+--------------+--------------+
; | m72_bull_cnt | Main sprites | Bullets      |
; +==============+==============+==============+
; |        (any) |    6 (0 - 5) |    2 (0 - 1) |
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
m72_sp3:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	ldi   r24,     8            ; (1634) 32px wide sprites

	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)


	; (1636) Bullet 0 (42)

	rcall sp_bullet


	; (1678) (Padding)

	rjmp  .


	; (1680) Bullet 1 (36 + 1)

	ld    ZL,      Y
	ldd   ZH,      Y + 1
	ld    r4,      Z+      ; ( 6) YPos
	add   r4,      r18     ; ( 7) Line within sprite acquired
	ld    XL,      Z+      ; ( 9) Xpos
	cpi   XL,      176
	brcs  .+2
	ldi   XL,      176     ; (12) Limit Xpos
	ld    r3,      Z+      ; (14) Color
	ld    r5,      Z+      ; (16) Height (bits 2-7) & Width (bits 0-1)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	lsr   r5               ; (17)
	brcc  sp3_b1_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp3_b1_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp3_b1_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp3_b1_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp3_b1_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp3_b1_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp3_b1end        ; (36)
sp3_b1_13:
	lsr   r5               ; (20)
	brcc  sp3_b1_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp3_b1_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp3_b1_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp3_b1_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp3_b1_ni        ; (32)
sp3_b1_2:
	cp    r5,      r4      ; (22)
	brcs  sp3_b1_i1        ; (23 / 24)
	rjmp  sp3_b1_2e        ; (25)
sp3_b1_1:
	cp    r5,      r4      ; (23)
	brcs  sp3_b1_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp3_b1_1e        ; (28)
sp3_b1_i0:
	nop                    ; (24)
sp3_b1_i1:
	nop                    ; (25)
sp3_b1_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp3_b1_ni        ; (32)
sp3_b1_x0:
	nop
sp3_b1_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp3_b1end:


	; (1717) (Padding)

	nop


	; (1718) Sprite 4 & 5 (183 + 2)

	ldi   ZL,      lo8(v_sprd + (5 * 4))
	ldi   ZH,      hi8(v_sprd + (5 * 4))
	ld    r0,      Z+      ; ( 4) YPos
	add   r0,      r18     ; ( 5) Line within sprite acquired
	ld    XL,      Z+      ; ( 7) Height
	cp    r0,      XL
	brcc  sp3_4ina         ; ( 9 / 10)
	mul   r0,      r24     ; (11) r24 = 8; 32px wide sprites
	ldd   YL,      Z + 40  ; (13) OffLo
	add   YL,      r0
	ldd   YH,      Z + 41  ; (16) OffHi + Mirror on bit 7
	adc   YH,      r1
	ldd   XL,      Z + 42  ; (19) XPos
	ld    r3,      Z+      ; (21) Color 1
	ld    r4,      Z+      ; (23) Color 2
	ld    r5,      Z+      ; (25) Color 3
	brpl  sp3_4nor         ; (26 / 27) Mirroring flag
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 7   ; (29)
	icall                  ; (46)
	ldd   ZL,      Y + 6   ; (48)
	icall                  ; (65)
	ldd   ZL,      Y + 5   ; (67)
	icall                  ; (84)
	ldd   ZL,      Y + 4   ; (86)
	icall                  ; (103)
	lds   XL,      (v_sprd + (5 * 5) + 44) ; XPos of Sprite 5
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	ldd   ZL,      Y + 3   ; (107)
	icall                  ; (124)
	ldd   ZL,      Y + 2   ; (126)
	icall                  ; (143)
	ldd   ZL,      Y + 1   ; (145)
	rjmp  sp3_4mie         ; (147)
sp3_4ina:
	brne  sp3_4nnx         ; (11 / 12)
	rcall sp3_next         ; (69)
	WAIT  YL,      36      ; (105)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  YL,      16      ; (121)
	ldi   ZL,      lo8(v_sprd + (5 * 5) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 5) + 2)
	rcall sp3_next         ; (181)
	rjmp  sp3_4end         ; (183)
sp3_4nnx:
	WAIT  YL,      93
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  YL,      76
	rjmp  sp3_4end         ; (183)
sp3_4nor:
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ld    ZL,      Y+      ; (31)
	icall                  ; (48)
	ld    ZL,      Y+      ; (50)
	icall                  ; (67)
	ld    ZL,      Y+      ; (69)
	icall                  ; (86)
	ld    ZL,      Y+      ; (88)
	icall                  ; (105)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	lds   XL,      (v_sprd + (5 * 5) + 44) ; XPos of Sprite 5
	ld    ZL,      Y+      ; (109)
	icall                  ; (126)
	ld    ZL,      Y+      ; (128)
	icall                  ; (145)
	ld    ZL,      Y+      ; (147)
sp3_4mie:
	icall                  ; (164)
	ld    ZL,      Y       ; (166)
	icall                  ; (183)
sp3_4end:


	; (  83) Sprite 2 & 3 (183 + 2 + 8)

	; --- (Preload) ---
	lds   r20,     (v_sprd + (5 * 0) + 0) ; YPos
	lds   r25,     (v_sprd + (5 * 0) + 1) ; Height
	lds   r22,     (v_sprd + (5 * 0) + 42) ; OffLo
	lds   r23,     (v_sprd + (5 * 0) + 43) ; OffHi + Mirror on bit 7
	; -----------------
	ldi   ZL,      lo8(v_sprd + (5 * 2))
	ldi   ZH,      hi8(v_sprd + (5 * 2))
	ld    r0,      Z+      ; ( 4) YPos
	add   r0,      r18     ; ( 5) Line within sprite acquired
	ld    XL,      Z+      ; ( 7) Height
	cp    r0,      XL
	brcc  sp3_2ina         ; ( 9 / 10)
	mul   r0,      r24     ; (11) r24 = 8; 32px wide sprites
	ldd   YL,      Z + 40  ; (13) OffLo
	add   YL,      r0
	ldd   YH,      Z + 41  ; (16) OffHi + Mirror on bit 7
	adc   YH,      r1
	ldd   XL,      Z + 42  ; (19) XPos
	ld    r3,      Z+      ; (21) Color 1
	ld    r4,      Z+      ; (23) Color 2
	ld    r5,      Z+      ; (25) Color 3
	brpl  sp3_2nor         ; (26 / 27) Mirroring flag
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 7   ; (29)
	icall                  ; (46)
	ldd   ZL,      Y + 6   ; (48)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	icall                  ; (65)
	ldd   ZL,      Y + 5   ; (67)
	icall                  ; (84)
	ldd   ZL,      Y + 4   ; (86)
	icall                  ; (103)
	lds   XL,      (v_sprd + (5 * 3) + 44) ; XPos of Sprite 3
	ldd   ZL,      Y + 3   ; (107)
	icall                  ; (124)
	ldd   ZL,      Y + 2   ; (126)
	icall                  ; (143)
	ldd   ZL,      Y + 1   ; (145)
	rjmp  sp3_2mie         ; (147)
sp3_2ina:
	brne  sp3_2nnx         ; (11 / 12)
	WAIT  YL,      37      ; (48)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  YL,      15      ; (63)
	rcall sp3_next         ; (121)
	ldi   ZL,      lo8(v_sprd + (5 * 3) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 3) + 2)
	rcall sp3_next         ; (181)
	rjmp  sp3_2end         ; (183)
sp3_2nnx:
	WAIT  YL,      36
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  YL,      133
	rjmp  sp3_2end         ; (183)
sp3_2nor:
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ld    ZL,      Y+      ; (31)
	icall                  ; (48)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	ld    ZL,      Y+      ; (50)
	icall                  ; (67)
	ld    ZL,      Y+      ; (69)
	icall                  ; (86)
	ld    ZL,      Y+      ; (88)
	icall                  ; (105)
	lds   XL,      (v_sprd + (5 * 3) + 44) ; XPos of Sprite 3
	ld    ZL,      Y+      ; (109)
	icall                  ; (126)
	ld    ZL,      Y+      ; (128)
	icall                  ; (145)
	ld    ZL,      Y+      ; (147)
sp3_2mie:
	icall                  ; (164)
	ld    ZL,      Y       ; (166)
	icall                  ; (183)
sp3_2end:


	; ( 276) Sprite 0 & 1 (183 + 11 - 9)

	add   r20,     r18     ; Line within sprite acquired
	cp    r20,     r25
	brcc  sp3_0ina         ; ( 9 / 10)
	mul   r20,     r24     ; (11) r24 = 8; 32px wide sprites
	movw  YL,      r22
	add   YL,      r0
	adc   YH,      r1
	lds   XL,      (v_sprd + (5 * 0) + 44) ; (19) XPos
	lds   r3,      (v_sprd + (5 * 0) + 2) ; (21) Color 1
	lds   r4,      (v_sprd + (5 * 0) + 3) ; (23) Color 2
	lds   r5,      (v_sprd + (5 * 0) + 4) ; (25) Color 3
	brpl  sp3_0nor         ; (26 / 27) Mirroring flag
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 7   ; (29)
	icall                  ; (46)
	ldd   ZL,      Y + 6   ; (48)
	icall                  ; (65)
	ldd   ZL,      Y + 5   ; (67)
	icall                  ; (84)
	ldd   ZL,      Y + 4   ; (86)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	lpm   r20,     Z
	lpm   r20,     Z
	rjmp  .
	rjmp  .
	; -----------------
	icall                  ; (103)
	lds   XL,      (v_sprd + (5 * 1) + 44) ; XPos of Sprite 1
	ldd   ZL,      Y + 3   ; (107)
	icall                  ; (124)
	ldd   ZL,      Y + 2   ; (126)
	icall                  ; (143)
	ldd   ZL,      Y + 1   ; (145)
	rjmp  sp3_0mie         ; (147)
sp3_0ina:
	brne  sp3_0nnx         ; (11 / 12)
	ldi   ZL,      lo8(v_sprd + (5 * 0) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 0) + 2)
	rcall sp3_next         ; (71)
	WAIT  YL,      5 + 10 - 3 ; (76 + 10 - 3) (-3 is for preloaded offset)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  YL,      45      ; (121)
	ldi   ZL,      lo8(v_sprd + (5 * 1) + 2)
	ldi   ZH,      hi8(v_sprd + (5 * 1) + 2)
	rcall sp3_next         ; (181)
	rjmp  sp3_0end         ; (183)
sp3_0nnx:
	WAIT  YL,      64 + 10 - 3
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  YL,      105
	rjmp  sp3_0end         ; (183)
sp3_0nor:
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ld    ZL,      Y+      ; (31)
	icall                  ; (48)
	ld    ZL,      Y+      ; (50)
	icall                  ; (67)
	ld    ZL,      Y+      ; (69)
	icall                  ; (86)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	lpm   r20,     Z
	lpm   r20,     Z
	rjmp  .
	rjmp  .
	; -----------------
	ld    ZL,      Y+      ; (88)
	icall                  ; (105)
	lds   XL,      (v_sprd + (5 * 1) + 44) ; XPos of Sprite 1
	ld    ZL,      Y+      ; (109)
	icall                  ; (126)
	ld    ZL,      Y+      ; (128)
	icall                  ; (145)
	ld    ZL,      Y+      ; (147)
sp3_0mie:
	icall                  ; (164)
	ld    ZL,      Y       ; (166)
	icall                  ; (183)
sp3_0end:


	; ( 461) Go on to next line

	ldi   ZL,      15
	out   STACKL,  ZL
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
sp3_next:

	sbiw  ZL,      2
	ldd   YL,      Z + 40  ; ( 5) NextLo
	ldd   YH,      Z + 41  ; ( 7) NextHi
	cpi   YH,      0
	breq  sp3_next_lie     ; (11 / 12)
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
sp3_next_lie:
	std   Z + 0,   YH
	std   Z + 1,   YH      ; (16)
	adiw  ZL,      5       ; (18)
	WAIT  r21,     36      ; (54)
	ret                    ; (58)

/*
 *  Uzebox Kernel - Mode 72, Sprite mode 0
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
; Video mode 72, Sprite mode 0
;
; 8 pixels wide ROM (0x0000 - 0x70FF) / RAM sprites
;
; Sprites are available in the following manner:
;
; +--------------+--------------+--------------+
; | m72_bull_cnt | Main sprites | Bullets      |
; +==============+==============+==============+
; |        0 - 1 |    8 (0 - 7) |    1 (0    ) |
; +--------------+--------------+--------------+
; |        2 - 3 |    7 (0 - 6) |    3 (0 - 2) |
; +--------------+--------------+--------------+
; |        4 - 5 |    6 (0 - 5) |    5 (0 - 4) |
; +--------------+--------------+--------------+
; |        6 -   |    5 (0 - 4) |    6 (0 - 5) |
; +--------------+--------------+--------------+
;
; Bullets display below sprites.
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



sp0_bl0:
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      14
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  ZL,      6
	rjmp  sp0_0beg         ; (1706)



;
; Entry point
;
m72_sp0:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	ldi   r24,     2            ; (1634) 8px wide sprites

	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)


	; (1636) Bullet 0 (42)

	rcall sp_bullet


	; (1678) Sprite / Bullet decision

	cpi   r25,     2
	brcs  sp0_bl0          ; (1680 / 1681) 0 - 1 bullets


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
	lsr   r5               ; (17)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	brcc  sp0_b1_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp0_b1_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp0_b1_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp0_b1_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp0_b1_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp0_b1_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp0_b1end        ; (36)
sp0_b1_13:
	lsr   r5               ; (20)
	brcc  sp0_b1_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp0_b1_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp0_b1_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp0_b1_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp0_b1_ni        ; (32)
sp0_b1_2:
	cp    r5,      r4      ; (22)
	brcs  sp0_b1_i1        ; (23 / 24)
	rjmp  sp0_b1_2e        ; (25)
sp0_b1_1:
	cp    r5,      r4      ; (23)
	brcs  sp0_b1_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp0_b1_1e        ; (28)
sp0_b1_i0:
	nop                    ; (24)
sp0_b1_i1:
	nop                    ; (25)
sp0_b1_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp0_b1_ni        ; (32)
sp0_b1_x0:
	nop
sp0_b1_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp0_b1end:


	; (1717) Bullet 2 (42)

	rcall sp_bullet


	; (1759) Bullet decision

	cpi   r25,     4
	brcc  sp0_bl4          ; 4 or more bullets
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      12
	rjmp  sp0_1beg         ; (1777)
sp0_bl4:


	; (1762) Bullet 3 (42)

	rcall sp_bullet


	; (1804) Bullet 4 (36 + 3)

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
	lsr   r5               ; (17)
	brcc  sp0_b4_13        ; (18 / 19)
	; --- (Display) ---
	nop
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	lsr   r5               ; (19)
	brcc  sp0_b4_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp0_b4_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp0_b4_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp0_b4_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp0_b4_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp0_b4end        ; (36)
sp0_b4_13:
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	nop
	; -----------------
	lsr   r5               ; (20)
	brcc  sp0_b4_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp0_b4_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp0_b4_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp0_b4_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp0_b4_ni        ; (32)
sp0_b4_2:
	cp    r5,      r4      ; (22)
	brcs  sp0_b4_i1        ; (23 / 24)
	rjmp  sp0_b4_2e        ; (25)
sp0_b4_1:
	cp    r5,      r4      ; (23)
	brcs  sp0_b4_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp0_b4_1e        ; (28)
sp0_b4_i0:
	nop                    ; (24)
sp0_b4_i1:
	nop                    ; (25)
sp0_b4_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp0_b4_ni        ; (32)
sp0_b4_x0:
	nop
sp0_b4_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp0_b4end:


	; (  23) Bullet decision

	cpi   r25,     6
	brcc  sp0_bl6          ; 6 or more bullets
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	add   r20,     r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	ldd   r22,     Y + 3   ; YPos
	add   r22,     r18     ; Line within sprite acquired
	ldd   r23,     Y + 4   ; ( 5) Height
	; -----------------
	WAIT  ZL,      1
	rjmp  sp0_2beg         ; (  40)
sp0_bl6:


	; (  26) Bullet 5 (42)

	rcall sp_bullet


	; (  68) Transfer to sprites

	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	; --- (Preload) ---
	ld    r22,     Y+      ; YPos
	add   r22,     r18     ; Line within sprite acquired
	ld    r23,     Y+      ; ( 5) Height
	; -----------------
	WAIT  ZL,      31
	rjmp  sp0_3beg         ; ( 108)



	; (1706) Sprite 0 (71)

sp0_0beg:
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp0_0ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_0mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_0mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_0mie         ; (36)
sp0_0mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_0mie         ; (36)
sp0_0ina:
	brne  sp0_0nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      2
	rjmp  sp0_0end         ; (71)
sp0_0nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      57
	rjmp  sp0_0end         ; (71)
sp0_0nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_0nre         ; (35)
sp0_0mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_0nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_0nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_0mie:
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_0end:


	; (1777) Sprite 1 (71 + 10 + 2)

sp0_1beg:
	; --- (Preload) ---
	ldd   r22,     Y + 5   ; YPos
	add   r22,     r18     ; Line within sprite acquired
	ldd   r23,     Y + 6   ; ( 5) Height
	; -----------------
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp0_1ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_1mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_1mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_1mie         ; (36)
sp0_1mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_1mie         ; (36)
sp0_1ina:
	brne  sp0_1nnx         ; ( 9 / 10)
	rcall sp0_next1        ; (67)
	WAIT  ZL,      2
sp0_1com:
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	add   r20,     r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	; -----------------
	rjmp  sp0_1end         ; (71)
sp0_1nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      29      ; (41)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  ZL,      26
	rjmp  sp0_1com         ; (69)
sp0_1nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_1nre         ; (35)
sp0_1mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_1nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_1nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_1mie:
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	add   r20,     r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_1end:


	; (  40) Sprite 2 (71 - 5)

sp0_2beg:
	cp    r20,     r1
	brcc  sp0_2ina         ; ( 7 /  8)
	mul   r20,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_2mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_2mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_2mie         ; (36)
sp0_2mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_2mie         ; (36)
sp0_2ina:
	brne  sp0_2nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      2
	rjmp  sp0_2end         ; (71)
sp0_2nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      57
	rjmp  sp0_2end         ; (71)
sp0_2nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_2nre         ; (35)
sp0_2mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_2nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_2nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_2mie:
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_2end:


	; ( 106) Sprite 3 (71 - 3 + 2)

	adiw  YL,      2
sp0_3beg:
	cp    r22,     r23
	brcc  sp0_3ina         ; ( 7 /  8)
	mul   r22,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_3mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_3mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_3mie         ; (36)
sp0_3mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_3mie         ; (36)
sp0_3ina:
	brne  sp0_3nnx         ; ( 9 / 10)
	rcall sp0_next3        ; (67)
	WAIT  ZL,      2
	rjmp  sp0_3end         ; (71)
sp0_3nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      24      ; (36)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  ZL,      33
	rjmp  sp0_3end         ; (71)
sp0_3nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_3nre         ; (35)
sp0_3mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_3nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_3nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_3mie:
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_3end:


	; ( 176) Sprite 4 (71)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp0_4ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_4mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_4mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_4mie         ; (36)
sp0_4mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_4mie         ; (36)
sp0_4ina:
	brne  sp0_4nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      2
	rjmp  sp0_4end         ; (71)
sp0_4nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      57
	rjmp  sp0_4end         ; (71)
sp0_4nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_4nre         ; (35)
sp0_4mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_4nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_4nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_4mie:
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_4end:


	; ( 247) Sprite 5 (71)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp0_5ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_5mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_5mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_5mie         ; (36)
sp0_5mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_5mie         ; (36)
sp0_5ina:
	brne  sp0_5nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      2
	rjmp  sp0_5end         ; (71)
sp0_5nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      57
	rjmp  sp0_5end         ; (71)
sp0_5nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_5nre         ; (35)
sp0_5mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_5nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_5nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_5mie:
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_5end:


	; ( 318) Sprite 6 (71 + 1 + 2)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp0_6ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_6mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_6mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	mov   ZL,      r1      ; (34)
	rjmp  sp0_6mie         ; (36)
sp0_6mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	mov   ZL,      r1      ; (34)
	rjmp  sp0_6mie         ; (36)
sp0_6ina:
	brne  sp0_6nnx         ; ( 9 / 10)
	rcall sp0_next6        ; (67) (+1)
	WAIT  ZL,      1
sp0_6com:
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	; -----------------
	rjmp  sp0_6end         ; (71)
sp0_6nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      23      ; (35)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  ZL,      32
	rjmp  sp0_6com         ; (69)
sp0_6nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_6nre         ; (35)
sp0_6mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_6nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_6nre:
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	; -----------------
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_6mie:
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_6end:


	; ( 392) Sprite 7 (71 - 2)

	add   r20,     r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r20,     r1
	brcc  sp0_7ina         ; ( 7 /  8)
	mul   r20,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp0_7mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp0_7mra         ; (26 / 27)
	lpm   r1,      Z+      ; (29)
	lpm   r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_7mie         ; (36)
sp0_7mra:
	subi  ZH,      0x70    ; (28)
	ld    r1,      Z+      ; (30)
	ld    r0,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	mov   ZL,      r1      ; (34)
	rjmp  sp0_7mie         ; (36)
sp0_7ina:
	brne  sp0_7nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      2
	rjmp  sp0_7end         ; (71)
sp0_7nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      57
	rjmp  sp0_7end         ; (71)
sp0_7nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    ZL,      Z       ; (33)
	rjmp  sp0_7nre         ; (35)
sp0_7mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp0_7nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   ZL,      Z       ; (34)
	nop                    ; (35)
sp0_7nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp0_7mie:
	icall                  ; (53)
	mov   ZL,      r0      ; (54)
	icall                  ; (71)
sp0_7end:


	; ( 461) Go on to next line

	ldi   ZL,      15
	out   STACKL,  ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b



;
; Load next sprite code for sprite modes. Assumes entry with rcall.
;
; Y: Must point to the appropriate entry in the sprite list (v_sprd) + 2.
; Z: Used to copy next sprite data
; r21: Temp
;
sp0_next1:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp0_next1_lie    ; (11 / 12)
	ld    r21,     Z+
	st    Y+,      r21     ; (15) YPos
	ld    r21,     Z+
	st    Y+,      r21     ; (19) Height
	ld    r21,     Z+
	std   Y + 40,  r21     ; (23) OffLo
	ld    r21,     Z+
	std   Y + 41,  r21     ; (27) OffHi
	ld    r21,     Z+
	cpi   r21,     176
	brcs  .+2
	ldi   r21,     176
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	std   Y + 42,  r21     ; (34) XPos
	ld    r21,     Z+
	st    Y+,      r21     ; (38) Col0
	ld    r21,     Z+
	st    Y+,      r21     ; (42) Col1
	ld    r21,     Z+
	st    Y+,      r21     ; (46) Col2
	ld    r21,     Z+
	std   Y + 35,  r21     ; (50) NextLo
	ld    r21,     Z+
	std   Y + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp0_next1_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     14      ; (32)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  r21,     22      ; (54)
	ret                    ; (58)

sp0_next3:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp0_next3_lie    ; (11 / 12)
	ld    r21,     Z+
	st    Y+,      r21     ; (15) YPos
	ld    r21,     Z+
	st    Y+,      r21     ; (19) Height
	ld    r21,     Z+
	std   Y + 40,  r21     ; (23) OffLo
	ld    r21,     Z+
	std   Y + 41,  r21     ; (27) OffHi
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	ld    r21,     Z+
	cpi   r21,     176
	brcs  .+2
	ldi   r21,     176
	std   Y + 42,  r21     ; (34) XPos
	ld    r21,     Z+
	st    Y+,      r21     ; (38) Col0
	ld    r21,     Z+
	st    Y+,      r21     ; (42) Col1
	ld    r21,     Z+
	st    Y+,      r21     ; (46) Col2
	ld    r21,     Z+
	std   Y + 35,  r21     ; (50) NextLo
	ld    r21,     Z+
	std   Y + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp0_next3_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     9       ; (27)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  r21,     27      ; (54)
	ret                    ; (58)

sp0_next6:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp0_next6_lie    ; (11 / 12)
	ld    r21,     Z+
	st    Y+,      r21     ; (15) YPos
	ld    r21,     Z+
	st    Y+,      r21     ; (19) Height
	ld    r21,     Z+
	std   Y + 40,  r21     ; (23) OffLo
	ld    r21,     Z+
	; --- (Display) ---
	nop
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	std   Y + 41,  r21     ; (27) OffHi
	ld    r21,     Z+
	cpi   r21,     176
	brcs  .+2
	ldi   r21,     176
	std   Y + 42,  r21     ; (34) XPos
	ld    r21,     Z+
	st    Y+,      r21     ; (38) Col0
	ld    r21,     Z+
	st    Y+,      r21     ; (42) Col1
	ld    r21,     Z+
	st    Y+,      r21     ; (46) Col2
	ld    r21,     Z+
	std   Y + 35,  r21     ; (50) NextLo
	ld    r21,     Z+
	std   Y + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp0_next6_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     7 + 1   ; (25)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  r21,     29      ; (54)
	ret                    ; (58)

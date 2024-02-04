/*
 *  Uzebox Kernel - Mode 72, Sprite mode 2
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
; Video mode 72, Sprite mode 2
;
; 12 pixels wide ROM (0x0000 - 0x70FF) / RAM sprites
;
; Sprites are available in the following manner:
;
; +--------------+--------------+--------------+
; | m72_bull_cnt | Main sprites | Bullets      |
; +==============+==============+==============+
; |        0 - 2 |    6 (0 - 5) |    2 (0 - 1) |
; +--------------+--------------+--------------+
; |        2 - 3 |    5 (0 - 3) |    4 (0 - 3) |
; +--------------+--------------+--------------+
; |        4 -   |    4 (0 - 2) |    6 (0 - 5) |
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
m72_sp2:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	ldi   r24,     3            ; (1634) 12px wide sprites

	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)


	; (1636) Bullet 0 (36)

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
	brcc  sp2_b0_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp2_b0_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp2_b0_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp2_b0_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp2_b0_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp2_b0_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp2_b0end        ; (36)
sp2_b0_13:
	lsr   r5               ; (20)
	brcc  sp2_b0_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp2_b0_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp2_b0_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp2_b0_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp2_b0_ni        ; (32)
sp2_b0_2:
	cp    r5,      r4      ; (22)
	brcs  sp2_b0_i1        ; (23 / 24)
	rjmp  sp2_b0_2e        ; (25)
sp2_b0_1:
	cp    r5,      r4      ; (23)
	brcs  sp2_b0_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp2_b0_1e        ; (28)
sp2_b0_i0:
	nop                    ; (24)
sp2_b0_i1:
	nop                    ; (25)
sp2_b0_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp2_b0_ni        ; (32)
sp2_b0_x0:
	nop
sp2_b0_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp2_b0end:


	; (1672) Bullet 1 (36 + 2)

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
	brcc  sp2_b1_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp2_b1_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp2_b1_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	; --- (Display) ---
	nop
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp2_b1_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp2_b1_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp2_b1_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp2_b1end        ; (36)
sp2_b1_13:
	lsr   r5               ; (20)
	brcc  sp2_b1_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp2_b1_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp2_b1_2e:
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	nop
	; -----------------
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp2_b1_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp2_b1_ni        ; (32)
sp2_b1_2:
	cp    r5,      r4      ; (22)
	brcs  sp2_b1_i1        ; (23 / 24)
	rjmp  sp2_b1_2e        ; (25)
sp2_b1_1:
	cp    r5,      r4      ; (23)
	brcs  sp2_b1_i2        ; (24 / 25)
	; --- (Display) ---
	nop
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	rjmp  .                ; (26)
	rjmp  sp2_b1_1e        ; (28)
sp2_b1_i0:
	nop                    ; (24)
sp2_b1_i1:
	nop                    ; (25)
sp2_b1_i2:
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	nop
	; -----------------
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp2_b1_ni        ; (32)
sp2_b1_x0:
	nop
sp2_b1_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp2_b1end:


	; (1710) Bullet decision

	cpi   r25,     3
	brcc  sp2_bl3          ; 3 or more bullets
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      1
	rjmp  sp2_0beg         ; (1717)
sp2_bl3:


	; (1713) Bullet 2 (42)

	rcall sp_bullet


	; (1755) Bullet 3 (42)

	rcall sp_bullet


	; (1797) Bullet decision

	cpi   r25,     5
	brcc  sp2_bl5          ; 5 or more bullets
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      6
	rjmp  sp2_1beg         ; (1809)
sp2_bl5:


	; (1800) Bullet 4 (36 + 3)

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
	brcc  sp2_b4_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp2_b4_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp2_b4_i0        ; (22 / 23)
	; --- (Display) ---
	nop
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp2_b4_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp2_b4_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp2_b4_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp2_b4end        ; (36)
sp2_b4_13:
	lsr   r5               ; (20)
	brcc  sp2_b4_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	; --- (Display) ---
	nop
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	brcs  sp2_b4_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp2_b4_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp2_b4_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp2_b4_ni        ; (32)
sp2_b4_2:
	cp    r5,      r4      ; (22)
	; --- (Display) ---
	nop
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	brcs  sp2_b4_i1        ; (23 / 24)
	rjmp  sp2_b4_2e        ; (25)
sp2_b4_1:
	cp    r5,      r4      ; (23)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	nop
	; -----------------
	brcs  sp2_b4_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp2_b4_1e        ; (28)
sp2_b4_i0:
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	nop
	; -----------------
	nop                    ; (24)
sp2_b4_i1:
	nop                    ; (25)
sp2_b4_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp2_b4_ni        ; (32)
sp2_b4_x0:
	nop
sp2_b4_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp2_b4end:


	; (  19) Bullet 5 (42)

	rcall sp_bullet


	; (  61) Bullets done, transfer

	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      18
	rjmp  sp2_2beg         ; (83)


	; (1717) Sprite 0 (92)

sp2_0beg:
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; Height
	cp    r0,      r1
	brcc  sp2_0ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 3; 12px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp2_0mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp2_0mra         ; (26 / 27)
	lpm   r21,     Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	lpm   r0,      Z+      ; (35)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_0mie         ; (38)
sp2_0mra:
	subi  ZH,      0x70    ; (28)
	ld    r21,     Z+      ; (30)
	ld    r1,      Z+      ; (32)
	ld    r0,      Z+      ; (34)
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_0mie         ; (38)
sp2_0ina:
	brne  sp2_0nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      23
	rjmp  sp2_0end         ; (92)
sp2_0nnx:
	adiw  YL,      3
	WAIT  ZL,      78
	rjmp  sp2_0end         ; (92)
sp2_0nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	rjmp  sp2_0nre         ; (37)
sp2_0mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp2_0nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
sp2_0nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp2_0mie:
	mov   ZL,      r21     ; (39)
	icall                  ; (56)
	mov   ZL,      r1      ; (57)
	icall                  ; (74)
	mov   ZL,      r0      ; (75)
	icall                  ; (92)
sp2_0end:


	; (1809) Sprite 1 (92 + 2)

sp2_1beg:
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; Height
	cp    r0,      r1
	brcc  sp2_1ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 3; 12px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp2_1mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp2_1mra         ; (26 / 27)
	lpm   r21,     Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	lpm   r0,      Z+      ; (35)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_1mie         ; (38)
sp2_1mra:
	subi  ZH,      0x70    ; (28)
	ld    r21,     Z+      ; (30)
	ld    r1,      Z+      ; (32)
	ld    r0,      Z+      ; (34)
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_1mie         ; (38)
sp2_1ina:
	lpm   ZL,      Z
	lpm   ZL,      Z       ; (14)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	brne  sp2_1nnx         ; (15 / 16)
	rcall sp_next          ; (73)
	WAIT  ZL,      17
	rjmp  sp2_1end         ; (92)
sp2_1nnx:
	adiw  YL,      3
	WAIT  ZL,      72
	rjmp  sp2_1end         ; (92)
sp2_1nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	rjmp  sp2_1nre         ; (37)
sp2_1mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp2_1nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
sp2_1nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp2_1mie:
	mov   ZL,      r21     ; (39)
	icall                  ; (56)
	mov   ZL,      r1      ; (57)
	icall                  ; (74)
	mov   ZL,      r0      ; (75)
	icall                  ; (92)
sp2_1end:


	; (  83) Sprite 2 (92 + 7 + 2)

sp2_2beg:
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; Height
	cp    r0,      r1
	brcc  sp2_2ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 3; 12px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp2_2mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp2_2mra         ; (26 / 27)
	lpm   r21,     Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	lpm   r0,      Z+      ; (35)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_2mie         ; (38)
sp2_2mra:
	subi  ZH,      0x70    ; (28)
	ld    r21,     Z+      ; (30)
	ld    r1,      Z+      ; (32)
	ld    r0,      Z+      ; (34)
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_2mie         ; (38)
sp2_2ina:
	brne  sp2_2nnx         ; ( 9 / 10)
	rcall sp2_next2        ; (67) (+1)
	WAIT  ZL,      22
	rjmp  sp2_2end         ; (92)
sp2_2nnx:
	adiw  YL,      3
	WAIT  ZL,      44      ; (56)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  ZL,      34
	rjmp  sp2_2end         ; (92)
sp2_2nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	rjmp  sp2_2nre         ; (37)
sp2_2mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp2_2nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
sp2_2nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp2_2mie:
	mov   ZL,      r21     ; (39)
	icall                  ; (56)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	mov   ZL,      r1      ; (57)
	icall                  ; (74)
	mov   ZL,      r0      ; (75)
	icall                  ; (92)
sp2_2end:
	; --- (Padding) ---
	lpm   ZL,      Z
	rjmp  .
	rjmp  .
	; -----------------


	; ( 184) Sprite 3 (92)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; Height
	cp    r0,      r1
	brcc  sp2_3ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 3; 12px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp2_3mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp2_3mra         ; (26 / 27)
	lpm   r21,     Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	lpm   r0,      Z+      ; (35)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_3mie         ; (38)
sp2_3mra:
	subi  ZH,      0x70    ; (28)
	ld    r21,     Z+      ; (30)
	ld    r1,      Z+      ; (32)
	ld    r0,      Z+      ; (34)
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_3mie         ; (38)
sp2_3ina:
	brne  sp2_3nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      23
	rjmp  sp2_3end         ; (92)
sp2_3nnx:
	adiw  YL,      3
	WAIT  ZL,      78
	rjmp  sp2_3end         ; (92)
sp2_3nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	rjmp  sp2_3nre         ; (37)
sp2_3mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp2_3nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
sp2_3nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp2_3mie:
	mov   ZL,      r21     ; (39)
	icall                  ; (56)
	mov   ZL,      r1      ; (57)
	icall                  ; (74)
	mov   ZL,      r0      ; (75)
	icall                  ; (92)
sp2_3end:


	; ( 276) Sprite 4 (92 + 2 + 1)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; Height
	cp    r0,      r1
	brcc  sp2_4ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 3; 12px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp2_4mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp2_4mra         ; (26 / 27)
	lpm   r21,     Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	lpm   r0,      Z+      ; (35)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_4mie         ; (38)
sp2_4mra:
	subi  ZH,      0x70    ; (28)
	ld    r21,     Z+      ; (30)
	ld    r1,      Z+      ; (32)
	ld    r0,      Z+      ; (34)
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_4mie         ; (38)
sp2_4ina:
	brne  sp2_4nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      8       ; (75)
sp2_4com:
	; --- (Preload) ---
	ld    r0,      Y+      ; YPos
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  ZL,      15
	rjmp  sp2_4end         ; (92)
sp2_4nnx:
	adiw  YL,      3
	WAIT  ZL,      61
	rjmp  sp2_4com         ; (75)
sp2_4nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	rjmp  sp2_4nre         ; (37)
sp2_4mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp2_4nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
sp2_4nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp2_4mie:
	mov   ZL,      r21     ; (39)
	icall                  ; (56)
	mov   ZL,      r1      ; (57)
	icall                  ; (74)
	mov   ZL,      r0      ; (75)
	; --- (Preload) ---
	ld    r0,      Y+      ; YPos
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	icall                  ; (95)
sp2_4end:


	; ( 371) Sprite 5 (92 - 2)

	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; Height
	cp    r0,      r1
	brcc  sp2_5ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 3; 12px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp2_5mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp2_5mra         ; (26 / 27)
	lpm   r21,     Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	lpm   r0,      Z+      ; (35)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_5mie         ; (38)
sp2_5mra:
	subi  ZH,      0x70    ; (28)
	ld    r21,     Z+      ; (30)
	ld    r1,      Z+      ; (32)
	ld    r0,      Z+      ; (34)
	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp2_5mie         ; (38)
sp2_5ina:
	brne  sp2_5nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      23
	rjmp  sp2_5end         ; (92)
sp2_5nnx:
	adiw  YL,      3
	WAIT  ZL,      78
	rjmp  sp2_5end         ; (92)
sp2_5nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	rjmp  sp2_5nre         ; (37)
sp2_5mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp2_5nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
sp2_5nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp2_5mie:
	mov   ZL,      r21     ; (39)
	icall                  ; (56)
	mov   ZL,      r1      ; (57)
	icall                  ; (74)
	mov   ZL,      r0      ; (75)
	icall                  ; (92)
sp2_5end:


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
sp2_next2:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp2_next2_lie    ; (11 / 12)
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
	std   Y + 42,  r21     ; (34) XPos
	ld    r21,     Z+
	st    Y+,      r21     ; (38) Col0
	ld    r21,     Z+
	st    Y+,      r21     ; (42) Col1
	ld    r21,     Z+
	st    Y+,      r21     ; (46) Col2
	; --- (Display) ---
	nop
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	ld    r21,     Z+
	std   Y + 35,  r21     ; (50) NextLo
	ld    r21,     Z+
	std   Y + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp2_next2_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     28 + 1  ; (46)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  r21,     8       ; (54)
	ret                    ; (58)

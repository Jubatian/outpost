/*
 *  Uzebox Kernel - Mode 72, Sprite mode 1
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
; Video mode 72, Sprite mode 1
;
; 16 pixels wide ROM (0x0000 - 0x70FF) / RAM sprites
;
; Sprites are available in the following manner:
;
; +--------------+--------------+--------------+
; | m72_bull_cnt | Main sprites | Bullets      |
; +==============+==============+==============+
; |        0 - 1 |    5 (0 - 4) |    1 (0    ) |
; +--------------+--------------+--------------+
; |        2 - 4 |    4 (0 - 3) |    4 (0 - 3) |
; +--------------+--------------+--------------+
; |        5 -   |    3 (0 - 2) |    7 (0 - 6) |
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



sp1_bl0:
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      14
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  ZL,      10
	rjmp  sp1_0beg         ; (1710)



;
; Entry point
;
m72_sp1:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	ldi   r24,     4            ; (1634) 16px wide sprites

	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)


	; (1636) Bullet 0 (42)

	rcall sp_bullet


	; (1678) Sprite / Bullet decision

	cpi   r25,     2
	brcs  sp1_bl0          ; (1680 / 1681) 0 - 1 bullets


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
	brcc  sp1_b1_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp1_b1_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp1_b1_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp1_b1_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp1_b1_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp1_b1_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp1_b1end        ; (36)
sp1_b1_13:
	lsr   r5               ; (20)
	brcc  sp1_b1_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp1_b1_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp1_b1_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp1_b1_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp1_b1_ni        ; (32)
sp1_b1_2:
	cp    r5,      r4      ; (22)
	brcs  sp1_b1_i1        ; (23 / 24)
	rjmp  sp1_b1_2e        ; (25)
sp1_b1_1:
	cp    r5,      r4      ; (23)
	brcs  sp1_b1_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp1_b1_1e        ; (28)
sp1_b1_i0:
	nop                    ; (24)
sp1_b1_i1:
	nop                    ; (25)
sp1_b1_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp1_b1_ni        ; (32)
sp1_b1_x0:
	nop
sp1_b1_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp1_b1end:


	; (1717) Bullet 2 (42)

	rcall sp_bullet


	; (1759) Bullet 3 (42)

	rcall sp_bullet


	; (1801) Sprite / Bullet decision

	cpi   r25,     5
	brcc  sp1_bl5          ; 5 or more bullets
	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      16
	rjmp  sp1_1beg         ; (   3)
sp1_bl5:


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
	brcc  sp1_b4_13        ; (18 / 19)
	; --- (Display) ---
	nop
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	lsr   r5               ; (19)
	brcc  sp1_b4_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp1_b4_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp1_b4_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp1_b4_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp1_b4_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp1_b4end        ; (36)
sp1_b4_13:
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	nop
	; -----------------
	lsr   r5               ; (20)
	brcc  sp1_b4_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp1_b4_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp1_b4_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp1_b4_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp1_b4_ni        ; (32)
sp1_b4_2:
	cp    r5,      r4      ; (22)
	brcs  sp1_b4_i1        ; (23 / 24)
	rjmp  sp1_b4_2e        ; (25)
sp1_b4_1:
	cp    r5,      r4      ; (23)
	brcs  sp1_b4_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp1_b4_1e        ; (28)
sp1_b4_i0:
	nop                    ; (24)
sp1_b4_i1:
	nop                    ; (25)
sp1_b4_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp1_b4_ni        ; (32)
sp1_b4_x0:
	nop
sp1_b4_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp1_b4end:


	; (  23) Bullet 5 (42)

	rcall sp_bullet


	; (  65) Bullet 6 (42)

	rcall sp_bullet


	; ( 107) Bullets done, transfer

	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	WAIT  ZL,      8
	rjmp  sp1_2beg         ; ( 119)


	; (1710) Sprite 0 (113 + 3)

sp1_0beg:
	ld    r0,      Y+      ; ( 2) YPos
	add   r0,      r18     ; ( 3) Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp1_0ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 4; 16px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp1_0mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp1_0mra         ; (26 / 27)
	lpm   r22,     Z+      ; (29)
	lpm   r21,     Z+      ; (32)
	lpm   r1,      Z+      ; (35)
	lpm   r0,      Z+      ; (38)
sp1_0mre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp1_0mie         ; (41)
sp1_0mra:
	subi  ZH,      0x70    ; (28)
	ld    r22,     Z+      ; (30)
	ld    r21,     Z+      ; (32)
	ld    r1,      Z+      ; (34)
	ld    r0,      Z+      ; (36)
	rjmp  sp1_0mre         ; (38)
sp1_0ina:
	brne  sp1_0nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      44
	rjmp  sp1_0end         ; (113)
sp1_0nnx:
	adiw  YL,      3
	WAIT  ZL,      99
	rjmp  sp1_0end         ; (113)
sp1_0nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	ld    r22,     Z+      ; (37)
	nop
	rjmp  sp1_0nre         ; (40)
sp1_0mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp1_0nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
	lpm   r22,     Z+      ; (40)
sp1_0nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp1_0mie:
	mov   ZL,      r22     ; (42)
	icall                  ; (59)
	mov   ZL,      r21     ; (60)
	icall                  ; (77)
	mov   ZL,      r1      ; (78)
	icall                  ; (95)
	mov   ZL,      r0      ; (96)
	icall                  ; (113)
sp1_0end:
sp1_1beg:
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	nop
	; -----------------


	; (   6) Sprite 1 (113)

	ld    r0,      Y+      ; ( 2) YPos
	add   r0,      r18     ; ( 3) Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp1_1ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 4; 16px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp1_1mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp1_1mra         ; (26 / 27)
	lpm   r22,     Z+      ; (29)
	lpm   r21,     Z+      ; (32)
	lpm   r1,      Z+      ; (35)
	lpm   r0,      Z+      ; (38)
sp1_1mre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp1_1mie         ; (41)
sp1_1mra:
	subi  ZH,      0x70    ; (28)
	ld    r22,     Z+      ; (30)
	ld    r21,     Z+      ; (32)
	ld    r1,      Z+      ; (34)
	ld    r0,      Z+      ; (36)
	rjmp  sp1_1mre         ; (38)
sp1_1ina:
	brne  sp1_1nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      44
	rjmp  sp1_1end         ; (113)
sp1_1nnx:
	adiw  YL,      3
	WAIT  ZL,      99
	rjmp  sp1_1end         ; (113)
sp1_1nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	ld    r22,     Z+      ; (37)
	nop
	rjmp  sp1_1nre         ; (40)
sp1_1mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp1_1nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
	lpm   r22,     Z+      ; (40)
sp1_1nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp1_1mie:
	mov   ZL,      r22     ; (42)
	icall                  ; (59)
	mov   ZL,      r21     ; (60)
	icall                  ; (77)
	mov   ZL,      r1      ; (78)
	icall                  ; (95)
	mov   ZL,      r0      ; (96)
	icall                  ; (113)
sp1_1end:


	; ( 119) Sprite 2 (113 + 2)

sp1_2beg:
	ld    r0,      Y+      ; ( 2) YPos
	add   r0,      r18     ; ( 3) Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp1_2ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 4; 16px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	ldd   XL,      Y + 42  ; (16) XPos
	ld    r3,      Y+      ; (18) Color 1
	ld    r4,      Y+      ; (20) Color 2
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	ld    r5,      Y+      ; (22) Color 3
	adc   ZH,      r1
	brmi  sp1_2mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp1_2mra         ; (26 / 27)
	lpm   r22,     Z+      ; (29)
	lpm   r21,     Z+      ; (32)
	lpm   r1,      Z+      ; (35)
	lpm   r0,      Z+      ; (38)
sp1_2mre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp1_2mie         ; (41)
sp1_2mra:
	subi  ZH,      0x70    ; (28)
	ld    r22,     Z+      ; (30)
	ld    r21,     Z+      ; (32)
	ld    r1,      Z+      ; (34)
	ld    r0,      Z+      ; (36)
	rjmp  sp1_2mre         ; (38)
sp1_2ina:
	lpm   ZL,      Z
	lpm   ZL,      Z
	lpm   ZL,      Z
	lpm   ZL,      Z       ; (20)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	brne  sp1_2nnx         ; (21 / 22)
	rcall sp_next          ; (79)
	WAIT  ZL,      32
	rjmp  sp1_2end         ; (113)
sp1_2nnx:
	adiw  YL,      3
	WAIT  ZL,      87
	rjmp  sp1_2end         ; (113)
sp1_2nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	ld    r22,     Z+      ; (37)
	nop
	rjmp  sp1_2nre         ; (40)
sp1_2mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp1_2nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
	lpm   r22,     Z+      ; (40)
sp1_2nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp1_2mie:
	mov   ZL,      r22     ; (42)
	icall                  ; (59)
	mov   ZL,      r21     ; (60)
	icall                  ; (77)
	mov   ZL,      r1      ; (78)
	icall                  ; (95)
	mov   ZL,      r0      ; (96)
	icall                  ; (113)
sp1_2end:


	; ( 234) Sprite 3 (113)

	ld    r0,      Y+      ; ( 2) YPos
	add   r0,      r18     ; ( 3) Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp1_3ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 4; 16px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp1_3mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp1_3mra         ; (26 / 27)
	lpm   r22,     Z+      ; (29)
	lpm   r21,     Z+      ; (32)
	lpm   r1,      Z+      ; (35)
	lpm   r0,      Z+      ; (38)
sp1_3mre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp1_3mie         ; (41)
sp1_3mra:
	subi  ZH,      0x70    ; (28)
	ld    r22,     Z+      ; (30)
	ld    r21,     Z+      ; (32)
	ld    r1,      Z+      ; (34)
	ld    r0,      Z+      ; (36)
	rjmp  sp1_3mre         ; (38)
sp1_3ina:
	brne  sp1_3nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      44
	rjmp  sp1_3end         ; (113)
sp1_3nnx:
	adiw  YL,      3
	WAIT  ZL,      99
	rjmp  sp1_3end         ; (113)
sp1_3nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	ld    r22,     Z+      ; (37)
	nop
	rjmp  sp1_3nre         ; (40)
sp1_3mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp1_3nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
	lpm   r22,     Z+      ; (40)
sp1_3nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp1_3mie:
	mov   ZL,      r22     ; (42)
	icall                  ; (59)
	mov   ZL,      r21     ; (60)
	icall                  ; (77)
	mov   ZL,      r1      ; (78)
	icall                  ; (95)
	mov   ZL,      r0      ; (96)
	icall                  ; (113)
sp1_3end:


	; ( 347) Sprite 4 (113 + 1)

	ld    r0,      Y+      ; ( 2) YPos
	add   r0,      r18     ; ( 3) Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	brcc  sp1_4ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 4; 16px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp1_4mir         ; (24 / 25) Mirroring flag
	cpi   ZH,      0x71    ; (25)
	brcc  sp1_4mra         ; (26 / 27)
	lpm   r22,     Z+      ; (29)
	lpm   r21,     Z+      ; (32)
	lpm   r1,      Z+      ; (35)
	lpm   r0,      Z+      ; (38)
sp1_4mre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp1_4mie         ; (41)
sp1_4mra:
	subi  ZH,      0x70    ; (28)
	ld    r22,     Z+      ; (30)
	ld    r21,     Z+      ; (32)
	ld    r1,      Z+      ; (34)
	ld    r0,      Z+      ; (36)
	rjmp  sp1_4mre         ; (38)
sp1_4ina:
	brne  sp1_4nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	WAIT  ZL,      44
	rjmp  sp1_4end         ; (113)
sp1_4nnx:
	adiw  YL,      3
	WAIT  ZL,      99
	rjmp  sp1_4end         ; (113)
sp1_4nra:
	subi  ZH,      0xF0    ; (29)
	ld    r0,      Z+      ; (31)
	ld    r1,      Z+      ; (33)
	ld    r21,     Z+      ; (35)
	ld    r22,     Z+      ; (37)
	nop
	rjmp  sp1_4nre         ; (40)
sp1_4mir:
	cpi   ZH,      0xF1    ; (26)
	brcc  sp1_4nra         ; (27 / 28)
	andi  ZH,      0x7F    ; (28)
	lpm   r0,      Z+      ; (31)
	lpm   r1,      Z+      ; (34)
	lpm   r21,     Z+      ; (37)
	lpm   r22,     Z+      ; (40)
sp1_4nre:
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp1_4mie:
	mov   ZL,      r22     ; (42)
	icall                  ; (59)
	mov   ZL,      r21     ; (60)
	icall                  ; (77)
	mov   ZL,      r1      ; (78)
	icall                  ; (95)
	mov   ZL,      r0      ; (96)
	icall                  ; (113)
sp1_4end:


	; ( 461) Go on to next line

	ldi   ZL,      15
	out   STACKL,  ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b

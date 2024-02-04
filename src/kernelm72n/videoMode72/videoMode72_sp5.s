/*
 *  Uzebox Kernel - Mode 72, Sprite mode 5
 *  Copyright (C) 2018 Sandor Zsuga (Jubatian)
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
; Video mode 72, Sprite mode 5
;
; 8 pixels wide ROM (0x0000 - 0x7FFF) sprites
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
; Sprites are lower priority than bullets (unlike in Sprite mode 0).
; RAM sprites are not supported.
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
m72_sp5:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	ldi   r24,     2            ; (1634) 8px wide sprites


	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)


	; (1636) Sprite 0 (69 + 9 + 1)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp5_0ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_0mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_0mie         ; (33)
sp5_0ina:
	brne  sp5_0nnx         ; ( 9 / 10)
	rcall sp5_next0        ; (67)
sp5_0com:
	; --- (Preload) ---
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	ldd   r22,     Y + 3   ; YPos
	ldd   r23,     Y + 4   ; ( 5) Height
	; -----------------
	rjmp  sp5_0end         ; (69)
sp5_0nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      49      ; (61)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  ZL,      4       ; (65)
	rjmp  sp5_0com         ; (67)
sp5_0mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_0mie:
	mov   ZL,      r1      ; (34)
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	; --- (Preload) ---
	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	ldd   r22,     Y + 3   ; YPos
	ldd   r23,     Y + 4   ; ( 5) Height
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	icall                  ; (69)
sp5_0end:


	; (1715) Sprite 1 (69 - 5)

	cp    r0,      r1
	brcc  sp5_1ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_1mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_1mie         ; (33)
sp5_1ina:
	brne  sp5_1nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	rjmp  sp5_1end         ; (69)
sp5_1nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      55
	rjmp  sp5_1end         ; (69)
sp5_1mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_1mie:
	mov   ZL,      r1      ; (34)
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_1end:


	; (1779) Sprite 2 (69 - 2 + 12 + 2)

	adiw  YL,      2
	add   r22,     r18     ; Line within sprite acquired
	cp    r22,     r23
	brcc  sp5_2ina         ; ( 7 /  8)
	mul   r22,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_2mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_2mie         ; (33)
sp5_2ina:
	brne  sp5_2nnx         ; ( 9 / 10)
	rcall sp5_next2        ; (67) (+1)
sp5_2com:
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	add   r20,     r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	ldd   r22,     Y + 3   ; YPos
	add   r22,     r18     ; Line within sprite acquired
	ldd   r23,     Y + 4   ; ( 5) Height
	nop
	; -----------------
	rjmp  sp5_2end         ; (69)
sp5_2nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      34      ; (46)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  ZL,      19 + 1
	rjmp  sp5_2com         ; (67)
sp5_2mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_2mie:
	mov   ZL,      r1      ; (34)
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	add   r20,     r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	ldd   r22,     Y + 3   ; YPos
	add   r22,     r18     ; Line within sprite acquired
	ldd   r23,     Y + 4   ; ( 5) Height
	rjmp  .
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_2end:


	; (  40) Sprite 3 (69 - 5)

	cp    r20,     r1
	brcc  sp5_3ina         ; ( 7 /  8)
	mul   r20,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_3mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_3mie         ; (33)
sp5_3ina:
	brne  sp5_3nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	rjmp  sp5_3end         ; (69)
sp5_3nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      55
	rjmp  sp5_3end         ; (69)
sp5_3mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_3mie:
	mov   ZL,      r1      ; (34)
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_3end:


	; ( 104) Sprite 4 (69 - 3 + 4 + 2)

	adiw  YL,      2
	cp    r22,     r23
	brcc  sp5_4ina         ; ( 7 /  8)
	mul   r22,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_4mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_4mie         ; (33)
sp5_4ina:
	brne  sp5_4nnx         ; ( 9 / 10)
	rcall sp5_next4        ; (67)
sp5_4com:
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	ld    r1,      Y+      ; ( 5) Height
	; -----------------
	rjmp  sp5_4end         ; (69)
sp5_4nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      26
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  ZL,      27
	rjmp  sp5_4com         ; (67)
sp5_4mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_4mie:
	mov   ZL,      r1      ; (34)
	; --- (Preload) ---
	ld    r20,     Y+      ; YPos
	ld    r1,      Y+      ; ( 5) Height
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_4end:


	; ( 176) Bullet decision

	cpi   r25,     6
	brcs  sp5_bnn6
	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)
	WAIT  ZL,      32
	rjmp  sp5_ble6         ; ( 214)
sp5_bnn6:


	; ( 179) Sprite 5 (69 - 4)

	add   r20,     r18     ; Line within sprite acquired
	cp    r20,     r1
	brcc  sp5_5ina         ; ( 7 /  8)
	mul   r20,     r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_5mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_5mie         ; (33)
sp5_5ina:
	brne  sp5_5nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	rjmp  sp5_5end         ; (69)
sp5_5nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      55
	rjmp  sp5_5end         ; (69)
sp5_5mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_5mie:
	mov   ZL,      r1      ; (34)
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_5end:


	; ( 244) Bullet decision

	cpi   r25,     4
	brcs  sp5_bnn5
	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)
	WAIT  ZL,      6
	rjmp  sp5_ble5         ; ( 256)
sp5_bnn5:


	; ( 247) Sprite 6 (69)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp5_6ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_6mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_6mie         ; (33)
sp5_6ina:
	brne  sp5_6nnx         ; ( 9 / 10)
	rcall sp_next          ; (67)
	rjmp  sp5_6end         ; (69)
sp5_6nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      55
	rjmp  sp5_6end         ; (69)
sp5_6mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_6mie:
	mov   ZL,      r1      ; (34)
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_6end:


	; ( 316) Bullet decision

	cpi   r25,     2
	brcs  sp5_bnn3
	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)
	WAIT  ZL,      18
	rjmp  sp5_ble3         ; ( 340)
sp5_bnn3:


	; ( 319) Sprite 7 (69 + 1)

	ld    r0,      Y+      ; YPos
	add   r0,      r18     ; Line within sprite acquired
	ld    r1,      Y+      ; ( 5) Height
	cp    r0,      r1
	brcc  sp5_7ina         ; ( 7 /  8)
	mul   r0,      r24     ; ( 9) r24 = 2; 8px wide sprites
	ldd   ZL,      Y + 40  ; (11) OffLo
	add   ZL,      r0
	ldd   ZH,      Y + 41  ; (14) OffHi + Mirror on bit 7
	adc   ZH,      r1
	ldd   XL,      Y + 42  ; (17) XPos
	ld    r3,      Y+      ; (19) Color 1
	ld    r4,      Y+      ; (21) Color 2
	ld    r5,      Y+      ; (23) Color 3
	brmi  sp5_7mir         ; (24 / 25) Mirroring flag
	lpm   r1,      Z+      ; (27)
	lpm   r0,      Z+      ; (30)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	rjmp  sp5_7mie         ; (33)
sp5_7ina:
	brne  sp5_7nnx         ; ( 9 / 10)
	rcall sp5_next7        ; (67)
	rjmp  sp5_7end         ; (69)
sp5_7nnx:
	adiw  YL,      3       ; (12)
	WAIT  ZL,      22      ; (34)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  ZL,      33
	rjmp  sp5_7end         ; (69)
sp5_7mir:
	andi  ZH,      0x7F    ; (26)
	lpm   r0,      Z+      ; (29)
	lpm   r1,      Z+      ; (32)
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
sp5_7mie:
	mov   ZL,      r1      ; (34)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	icall                  ; (51)
	mov   ZL,      r0      ; (52)
	icall                  ; (69)
sp5_7end:


	; ( 389) To bullets

	ldi   YL,      lo8(V_BUPT)
	ldi   YH,      hi8(V_BUPT)
	WAIT  ZL,      26
	rjmp  sp5_ble1         ; ( 419)


sp5_ble6:

	; ( 214) Bullets: 6

	rcall sp_bullet        ; (42)

sp5_ble5:

	; ( 256) Bullets: 5

	rcall sp_bullet        ; (42)

sp5_ble4:

	; ( 298) Bullets: 4

	rcall sp_bullet        ; (42)

sp5_ble3:

	; ( 340) Bullets: 3

	ld    ZL,      Y
	ldd   ZH,      Y + 1
	ld    r4,      Z+      ; ( 6) YPos
	add   r4,      r18     ; ( 7) Line within sprite acquired
	ld    XL,      Z+      ; ( 9) Xpos
	ld    r3,      Z+      ; (11) Color
	ld    r5,      Z+      ; (13) Height (bits 2-7) & Width (bits 0-1)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	cpi   XL,      176
	brcs  .+2
	ldi   XL,      176     ; (16) Limit Xpos
	lsr   r5               ; (17)
	brcc  sp5_b2_13        ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp5_b2_2         ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp5_b2_i0        ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp5_b2_1e:
	st    X+,      r3      ; (30) 4th pixel
	breq  sp5_b2_x1        ; (31 / 32) At last px of sprite: Load next sprite
	nop
sp5_b2_ni:
	adiw  YL,      2       ; (34)
	rjmp  sp5_b2end        ; (36)
sp5_b2_13:
	lsr   r5               ; (20)
	brcc  sp5_b2_1         ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp5_b2_i1        ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp5_b2_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp5_b2_x0        ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp5_b2_ni        ; (32)
sp5_b2_2:
	cp    r5,      r4      ; (22)
	brcs  sp5_b2_i1        ; (23 / 24)
	rjmp  sp5_b2_2e        ; (25)
sp5_b2_1:
	cp    r5,      r4      ; (23)
	brcs  sp5_b2_i2        ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp5_b2_1e        ; (28)
sp5_b2_i0:
	nop                    ; (24)
sp5_b2_i1:
	nop                    ; (25)
sp5_b2_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp5_b2_ni        ; (32)
sp5_b2_x0:
	nop
sp5_b2_x1:
	st    Y+,      ZL
	st    Y+,      ZH      ; (36)
sp5_b2end:

sp5_ble2:

	; ( 377) Bullets: 2

	rcall sp_bullet        ; (42)

sp5_ble1:

	; ( 419) Bullets: 1

	rcall sp_bullet        ; (42)

sp5_ble0:

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
sp5_next0:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp5_next0_lie    ; (11 / 12)
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
	ld    r21,     Z+
	std   Y + 35,  r21     ; (50) NextLo
	ld    r21,     Z+
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	std   Y + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp5_next0_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     34      ; (52)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  r21,     2       ; (54)
	ret                    ; (58)

sp5_next2:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp5_next2_lie    ; (11 / 12)
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
	; --- (Display) ---
	nop
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
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
sp5_next2_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     18 + 1  ; (36)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  r21,     18      ; (54)
	ret                    ; (58)

sp5_next4:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp5_next4_lie    ; (11 / 12)
	ld    r21,     Z+
	st    Y+,      r21     ; (15) YPos
	ld    r21,     Z+
	st    Y+,      r21     ; (19) Height
	ld    r21,     Z+
	std   Y + 40,  r21     ; (23) OffLo
	ld    r21,     Z+
	std   Y + 41,  r21     ; (27) OffHi
	ld    r21,     Z+
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
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
sp5_next4_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     11      ; (29)
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  r21,     25      ; (54)
	ret                    ; (58)

sp5_next7:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp5_next7_lie    ; (11 / 12)
	ld    r21,     Z+
	st    Y+,      r21     ; (15) YPos
	ld    r21,     Z+
	st    Y+,      r21     ; (19) Height
	ld    r21,     Z+
	std   Y + 40,  r21     ; (23) OffLo
	ld    r21,     Z+
	; --- (Display) ---
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
sp5_next7_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     7       ; (25)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  r21,     29      ; (54)
	ret                    ; (58)

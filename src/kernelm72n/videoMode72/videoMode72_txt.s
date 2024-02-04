/*
 *  Uzebox Kernel - Mode 72, Text mode
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



.section .text



;
; Code blocks for scanline generation
;
; Register allocation:
;
;  r1: r0: Temp (multiplication)
; r11:r10: FG:BG colors
;     r17: Border color
;     r19: Row counter
;     r22: 4 (Size of AT_HEAD blocks in words)
;     r23: ROM row select for character images
;       X: Count of tiles (just to have sbiw saving a word)
;       Y: VRAM
;       Z: Temp
;
.macro AT_HEAD px0, px1, midl
	out   PIXOUT,  \px0    ; bit0: Px0
	ld    ZL,      Y+
	out   PIXOUT,  \px1    ; bit1: Px1
	rjmp  \midl
.endm
.macro AT_MIDL px2, px3, px4, tail
	mov   ZH,      r23     ; r23: Row select
	out   PIXOUT,  \px2    ; bit2: Px2
	sbiw  XL,      1       ; X: Tilecount
	out   PIXOUT,  \px3    ; bit3: Px3
	lpm   r0,      Z
	out   PIXOUT,  \px4    ; bit4: Px4
	rjmp  \tail
.endm
.macro AT_TAIL px5, px6, px7, endc
	out   PIXOUT,  \px5    ; bit5: Px5
	breq  \endc
	mul   r0,      r22     ; r22: 4 (size of AT_HEAD blocks in words)
	out   PIXOUT,  \px6    ; bit6: Px6
	movw  ZL,      r0
	subi  ZL,      lo8(-(pm(at_b)))
	out   PIXOUT,  \px7    ; bit7: Px7
	sbci  ZH,      hi8(-(pm(at_b)))
	ijmp
.endm
.macro AT_ENDC px6, px7
	nop
	out   PIXOUT,  \px6    ; bit6: Px6
	sbiw  YL,      1       ; Back extra load
	out   PIXOUT,  \px7    ; bit7: Px7
	rjmp  at_exit
.endm
at_exit:
	out   PIXOUT,  r17     ; (1586) Colored border begins
	inc   r19              ; Row counter increment
	andi  r19,     0x07
	breq  .+4
	sbiw  YL,      40      ; (1591) Only increment VRAM if at end of tile row
	ret                    ; (1595)
	nop
	ret                    ; (1595)



at_t0:	AT_TAIL r10, r10, r10, at_e0
at_t2:	AT_TAIL r11, r10, r10, at_e0
at_e0:	AT_ENDC      r10, r10
at_t4:	AT_TAIL r10, r11, r10, at_e4
at_t6:	AT_TAIL r11, r11, r10, at_e4
at_e4:	AT_ENDC      r11, r10
at_t8:	AT_TAIL r10, r10, r11, at_e8
at_tA:	AT_TAIL r11, r10, r11, at_e8
at_e8:	AT_ENDC      r10, r11
at_tC:	AT_TAIL r10, r11, r11, at_eC
at_tE:	AT_TAIL r11, r11, r11, at_eC
at_eC:	AT_ENDC      r11, r11

at_m00:	AT_MIDL r10, r10, r10, at_t0
at_m04:	AT_MIDL r11, r10, r10, at_t0
at_m08:	AT_MIDL r10, r11, r10, at_t0
at_m0C:	AT_MIDL r11, r11, r10, at_t0
at_m10:	AT_MIDL r10, r10, r11, at_t0
at_m14:	AT_MIDL r11, r10, r11, at_t0
at_m18:	AT_MIDL r10, r11, r11, at_t0
at_m1C:	AT_MIDL r11, r11, r11, at_t0
at_m20:	AT_MIDL r10, r10, r10, at_t2
at_m24:	AT_MIDL r11, r10, r10, at_t2
at_m28:	AT_MIDL r10, r11, r10, at_t2
at_m2C:	AT_MIDL r11, r11, r10, at_t2
at_m30:	AT_MIDL r10, r10, r11, at_t2
at_m34:	AT_MIDL r11, r10, r11, at_t2
at_m38:	AT_MIDL r10, r11, r11, at_t2
at_m3C:	AT_MIDL r11, r11, r11, at_t2
at_m40:	AT_MIDL r10, r10, r10, at_t4
at_m44:	AT_MIDL r11, r10, r10, at_t4
at_m48:	AT_MIDL r10, r11, r10, at_t4
at_m4C:	AT_MIDL r11, r11, r10, at_t4
at_m50:	AT_MIDL r10, r10, r11, at_t4
at_m54:	AT_MIDL r11, r10, r11, at_t4
at_m58:	AT_MIDL r10, r11, r11, at_t4
at_m5C:	AT_MIDL r11, r11, r11, at_t4
at_m60:	AT_MIDL r10, r10, r10, at_t6
at_m64:	AT_MIDL r11, r10, r10, at_t6
at_m68:	AT_MIDL r10, r11, r10, at_t6
at_m6C:	AT_MIDL r11, r11, r10, at_t6
at_m70:	AT_MIDL r10, r10, r11, at_t6
at_m74:	AT_MIDL r11, r10, r11, at_t6
at_m78:	AT_MIDL r10, r11, r11, at_t6
at_m7C:	AT_MIDL r11, r11, r11, at_t6
at_m80:	AT_MIDL r10, r10, r10, at_t8
at_m84:	AT_MIDL r11, r10, r10, at_t8
at_m88:	AT_MIDL r10, r11, r10, at_t8
at_m8C:	AT_MIDL r11, r11, r10, at_t8
at_m90:	AT_MIDL r10, r10, r11, at_t8
at_m94:	AT_MIDL r11, r10, r11, at_t8
at_m98:	AT_MIDL r10, r11, r11, at_t8
at_m9C:	AT_MIDL r11, r11, r11, at_t8
at_mA0:	AT_MIDL r10, r10, r10, at_tA
at_mA4:	AT_MIDL r11, r10, r10, at_tA
at_mA8:	AT_MIDL r10, r11, r10, at_tA
at_mAC:	AT_MIDL r11, r11, r10, at_tA
at_mB0:	AT_MIDL r10, r10, r11, at_tA
at_mB4:	AT_MIDL r11, r10, r11, at_tA
at_mB8:	AT_MIDL r10, r11, r11, at_tA
at_mBC:	AT_MIDL r11, r11, r11, at_tA
at_mC0:	AT_MIDL r10, r10, r10, at_tC
at_mC4:	AT_MIDL r11, r10, r10, at_tC
at_mC8:	AT_MIDL r10, r11, r10, at_tC
at_mCC:	AT_MIDL r11, r11, r10, at_tC
at_mD0:	AT_MIDL r10, r10, r11, at_tC
at_mD4:	AT_MIDL r11, r10, r11, at_tC
at_mD8:	AT_MIDL r10, r11, r11, at_tC
at_mDC:	AT_MIDL r11, r11, r11, at_tC
at_mE0:	AT_MIDL r10, r10, r10, at_tE
at_mE4:	AT_MIDL r11, r10, r10, at_tE
at_mE8:	AT_MIDL r10, r11, r10, at_tE
at_mEC:	AT_MIDL r11, r11, r10, at_tE
at_mF0:	AT_MIDL r10, r10, r11, at_tE
at_mF4:	AT_MIDL r11, r10, r11, at_tE
at_mF8:	AT_MIDL r10, r11, r11, at_tE
at_mFC:	AT_MIDL r11, r11, r11, at_tE

at_b:	AT_HEAD r10, r10, at_m00
	AT_HEAD r11, r10, at_m00
	AT_HEAD r10, r11, at_m00
	AT_HEAD r11, r11, at_m00
	AT_HEAD r10, r10, at_m04
	AT_HEAD r11, r10, at_m04
	AT_HEAD r10, r11, at_m04
	AT_HEAD r11, r11, at_m04
	AT_HEAD r10, r10, at_m08
	AT_HEAD r11, r10, at_m08
	AT_HEAD r10, r11, at_m08
	AT_HEAD r11, r11, at_m08
	AT_HEAD r10, r10, at_m0C
	AT_HEAD r11, r10, at_m0C
	AT_HEAD r10, r11, at_m0C
	AT_HEAD r11, r11, at_m0C
	AT_HEAD r10, r10, at_m10
	AT_HEAD r11, r10, at_m10
	AT_HEAD r10, r11, at_m10
	AT_HEAD r11, r11, at_m10
	AT_HEAD r10, r10, at_m14
	AT_HEAD r11, r10, at_m14
	AT_HEAD r10, r11, at_m14
	AT_HEAD r11, r11, at_m14
	AT_HEAD r10, r10, at_m18
	AT_HEAD r11, r10, at_m18
	AT_HEAD r10, r11, at_m18
	AT_HEAD r11, r11, at_m18
	AT_HEAD r10, r10, at_m1C
	AT_HEAD r11, r10, at_m1C
	AT_HEAD r10, r11, at_m1C
	AT_HEAD r11, r11, at_m1C
	AT_HEAD r10, r10, at_m20
	AT_HEAD r11, r10, at_m20
	AT_HEAD r10, r11, at_m20
	AT_HEAD r11, r11, at_m20
	AT_HEAD r10, r10, at_m24
	AT_HEAD r11, r10, at_m24
	AT_HEAD r10, r11, at_m24
	AT_HEAD r11, r11, at_m24
	AT_HEAD r10, r10, at_m28
	AT_HEAD r11, r10, at_m28
	AT_HEAD r10, r11, at_m28
	AT_HEAD r11, r11, at_m28
	AT_HEAD r10, r10, at_m2C
	AT_HEAD r11, r10, at_m2C
	AT_HEAD r10, r11, at_m2C
	AT_HEAD r11, r11, at_m2C
	AT_HEAD r10, r10, at_m30
	AT_HEAD r11, r10, at_m30
	AT_HEAD r10, r11, at_m30
	AT_HEAD r11, r11, at_m30
	AT_HEAD r10, r10, at_m34
	AT_HEAD r11, r10, at_m34
	AT_HEAD r10, r11, at_m34
	AT_HEAD r11, r11, at_m34
	AT_HEAD r10, r10, at_m38
	AT_HEAD r11, r10, at_m38
	AT_HEAD r10, r11, at_m38
	AT_HEAD r11, r11, at_m38
	AT_HEAD r10, r10, at_m3C
	AT_HEAD r11, r10, at_m3C
	AT_HEAD r10, r11, at_m3C
	AT_HEAD r11, r11, at_m3C
	AT_HEAD r10, r10, at_m40
	AT_HEAD r11, r10, at_m40
	AT_HEAD r10, r11, at_m40
	AT_HEAD r11, r11, at_m40
	AT_HEAD r10, r10, at_m44
	AT_HEAD r11, r10, at_m44
	AT_HEAD r10, r11, at_m44
	AT_HEAD r11, r11, at_m44
	AT_HEAD r10, r10, at_m48
	AT_HEAD r11, r10, at_m48
	AT_HEAD r10, r11, at_m48
	AT_HEAD r11, r11, at_m48
	AT_HEAD r10, r10, at_m4C
	AT_HEAD r11, r10, at_m4C
	AT_HEAD r10, r11, at_m4C
	AT_HEAD r11, r11, at_m4C
	AT_HEAD r10, r10, at_m50
	AT_HEAD r11, r10, at_m50
	AT_HEAD r10, r11, at_m50
	AT_HEAD r11, r11, at_m50
	AT_HEAD r10, r10, at_m54
	AT_HEAD r11, r10, at_m54
	AT_HEAD r10, r11, at_m54
	AT_HEAD r11, r11, at_m54
	AT_HEAD r10, r10, at_m58
	AT_HEAD r11, r10, at_m58
	AT_HEAD r10, r11, at_m58
	AT_HEAD r11, r11, at_m58
	AT_HEAD r10, r10, at_m5C
	AT_HEAD r11, r10, at_m5C
	AT_HEAD r10, r11, at_m5C
	AT_HEAD r11, r11, at_m5C
	AT_HEAD r10, r10, at_m60
	AT_HEAD r11, r10, at_m60
	AT_HEAD r10, r11, at_m60
	AT_HEAD r11, r11, at_m60
	AT_HEAD r10, r10, at_m64
	AT_HEAD r11, r10, at_m64
	AT_HEAD r10, r11, at_m64
	AT_HEAD r11, r11, at_m64
	AT_HEAD r10, r10, at_m68
	AT_HEAD r11, r10, at_m68
	AT_HEAD r10, r11, at_m68
	AT_HEAD r11, r11, at_m68
	AT_HEAD r10, r10, at_m6C
	AT_HEAD r11, r10, at_m6C
	AT_HEAD r10, r11, at_m6C
	AT_HEAD r11, r11, at_m6C
	AT_HEAD r10, r10, at_m70
	AT_HEAD r11, r10, at_m70
	AT_HEAD r10, r11, at_m70
	AT_HEAD r11, r11, at_m70
	AT_HEAD r10, r10, at_m74
	AT_HEAD r11, r10, at_m74
	AT_HEAD r10, r11, at_m74
	AT_HEAD r11, r11, at_m74
	AT_HEAD r10, r10, at_m78
	AT_HEAD r11, r10, at_m78
	AT_HEAD r10, r11, at_m78
	AT_HEAD r11, r11, at_m78
	AT_HEAD r10, r10, at_m7C
	AT_HEAD r11, r10, at_m7C
	AT_HEAD r10, r11, at_m7C
	AT_HEAD r11, r11, at_m7C
	AT_HEAD r10, r10, at_m80
	AT_HEAD r11, r10, at_m80
	AT_HEAD r10, r11, at_m80
	AT_HEAD r11, r11, at_m80
	AT_HEAD r10, r10, at_m84
	AT_HEAD r11, r10, at_m84
	AT_HEAD r10, r11, at_m84
	AT_HEAD r11, r11, at_m84
	AT_HEAD r10, r10, at_m88
	AT_HEAD r11, r10, at_m88
	AT_HEAD r10, r11, at_m88
	AT_HEAD r11, r11, at_m88
	AT_HEAD r10, r10, at_m8C
	AT_HEAD r11, r10, at_m8C
	AT_HEAD r10, r11, at_m8C
	AT_HEAD r11, r11, at_m8C
	AT_HEAD r10, r10, at_m90
	AT_HEAD r11, r10, at_m90
	AT_HEAD r10, r11, at_m90
	AT_HEAD r11, r11, at_m90
	AT_HEAD r10, r10, at_m94
	AT_HEAD r11, r10, at_m94
	AT_HEAD r10, r11, at_m94
	AT_HEAD r11, r11, at_m94
	AT_HEAD r10, r10, at_m98
	AT_HEAD r11, r10, at_m98
	AT_HEAD r10, r11, at_m98
	AT_HEAD r11, r11, at_m98
	AT_HEAD r10, r10, at_m9C
	AT_HEAD r11, r10, at_m9C
	AT_HEAD r10, r11, at_m9C
	AT_HEAD r11, r11, at_m9C
	AT_HEAD r10, r10, at_mA0
	AT_HEAD r11, r10, at_mA0
	AT_HEAD r10, r11, at_mA0
	AT_HEAD r11, r11, at_mA0
	AT_HEAD r10, r10, at_mA4
	AT_HEAD r11, r10, at_mA4
	AT_HEAD r10, r11, at_mA4
	AT_HEAD r11, r11, at_mA4
	AT_HEAD r10, r10, at_mA8
	AT_HEAD r11, r10, at_mA8
	AT_HEAD r10, r11, at_mA8
	AT_HEAD r11, r11, at_mA8
	AT_HEAD r10, r10, at_mAC
	AT_HEAD r11, r10, at_mAC
	AT_HEAD r10, r11, at_mAC
	AT_HEAD r11, r11, at_mAC
	AT_HEAD r10, r10, at_mB0
	AT_HEAD r11, r10, at_mB0
	AT_HEAD r10, r11, at_mB0
	AT_HEAD r11, r11, at_mB0
	AT_HEAD r10, r10, at_mB4
	AT_HEAD r11, r10, at_mB4
	AT_HEAD r10, r11, at_mB4
	AT_HEAD r11, r11, at_mB4
	AT_HEAD r10, r10, at_mB8
	AT_HEAD r11, r10, at_mB8
	AT_HEAD r10, r11, at_mB8
	AT_HEAD r11, r11, at_mB8
	AT_HEAD r10, r10, at_mBC
	AT_HEAD r11, r10, at_mBC
	AT_HEAD r10, r11, at_mBC
	AT_HEAD r11, r11, at_mBC
	AT_HEAD r10, r10, at_mC0
	AT_HEAD r11, r10, at_mC0
	AT_HEAD r10, r11, at_mC0
	AT_HEAD r11, r11, at_mC0
	AT_HEAD r10, r10, at_mC4
	AT_HEAD r11, r10, at_mC4
	AT_HEAD r10, r11, at_mC4
	AT_HEAD r11, r11, at_mC4
	AT_HEAD r10, r10, at_mC8
	AT_HEAD r11, r10, at_mC8
	AT_HEAD r10, r11, at_mC8
	AT_HEAD r11, r11, at_mC8
	AT_HEAD r10, r10, at_mCC
	AT_HEAD r11, r10, at_mCC
	AT_HEAD r10, r11, at_mCC
	AT_HEAD r11, r11, at_mCC
	AT_HEAD r10, r10, at_mD0
	AT_HEAD r11, r10, at_mD0
	AT_HEAD r10, r11, at_mD0
	AT_HEAD r11, r11, at_mD0
	AT_HEAD r10, r10, at_mD4
	AT_HEAD r11, r10, at_mD4
	AT_HEAD r10, r11, at_mD4
	AT_HEAD r11, r11, at_mD4
	AT_HEAD r10, r10, at_mD8
	AT_HEAD r11, r10, at_mD8
	AT_HEAD r10, r11, at_mD8
	AT_HEAD r11, r11, at_mD8
	AT_HEAD r10, r10, at_mDC
	AT_HEAD r11, r10, at_mDC
	AT_HEAD r10, r11, at_mDC
	AT_HEAD r11, r11, at_mDC
	AT_HEAD r10, r10, at_mE0
	AT_HEAD r11, r10, at_mE0
	AT_HEAD r10, r11, at_mE0
	AT_HEAD r11, r11, at_mE0
	AT_HEAD r10, r10, at_mE4
	AT_HEAD r11, r10, at_mE4
	AT_HEAD r10, r11, at_mE4
	AT_HEAD r11, r11, at_mE4
	AT_HEAD r10, r10, at_mE8
	AT_HEAD r11, r10, at_mE8
	AT_HEAD r10, r11, at_mE8
	AT_HEAD r11, r11, at_mE8
	AT_HEAD r10, r10, at_mEC
	AT_HEAD r11, r10, at_mEC
	AT_HEAD r10, r11, at_mEC
	AT_HEAD r11, r11, at_mEC
	AT_HEAD r10, r10, at_mF0
	AT_HEAD r11, r10, at_mF0
	AT_HEAD r10, r11, at_mF0
	AT_HEAD r11, r11, at_mF0
	AT_HEAD r10, r10, at_mF4
	AT_HEAD r11, r10, at_mF4
	AT_HEAD r10, r11, at_mF4
	AT_HEAD r11, r11, at_mF4
	AT_HEAD r10, r10, at_mF8
	AT_HEAD r11, r10, at_mF8
	AT_HEAD r10, r11, at_mF8
	AT_HEAD r11, r11, at_mF8
	AT_HEAD r10, r10, at_mFC
	AT_HEAD r11, r10, at_mFC
	AT_HEAD r10, r11, at_mFC
	AT_HEAD r11, r11, at_mFC



;
; Text mode row entry point
;
;  r0: r1: Temp
;      r4: Foreground (1) color
;      r5: Background (0) color
; r10-r11: Temp
;     r17: Border color
;     r19: Row to render (low 3 bits used, incremented)
; r22-r23: Temp
;       X: Temp
;       Y: VRAM pointer (increments by 40 at end of tile rows)
;       Z: Temp
;
; Enter in cycle 429.
;
m72_txt_row:

	WAIT  ZL,      15

	lds   r23,     m72_charrom
	andi  r19,     0x07
	add   r23,     r19     ; Tile row select
	mov   r11,     r4      ; FG
	mov   r10,     r5      ; BG
	ldi   XH,      0
	ldi   XL,      40      ; Count of tiles to render
	ldi   r22,     4

	ld    ZL,      Y+      ; Tile 0
	mov   ZH,      r23     ; r23: Row select
	lpm   r0,      Z
	mul   r0,      r22     ; r22: 4 (size of AT_HEAD blocks in words)
	movw  ZL,      r0
	subi  ZL,      lo8(-(pm(at_b)))
	sbci  ZH,      hi8(-(pm(at_b)))
	ijmp

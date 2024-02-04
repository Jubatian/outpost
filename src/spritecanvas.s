/**
 * @file
 *
 *  Outpost in the dragon's maw
 *  Copyright (C) 2024 Sandor Zsuga (Jubatian)
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
*/



.section .text



/*
** Places a pixel on a canvas made up from adjacent sprites
**
** Inputs:
** r25:r24: Canvas start pointer
**     r22: Pixel X position
**     r20: Pixel Y position
**     r18: Pixel colour (0 - 3)
**     r16: Canvas height
** Clobbers:
** r0, r1 (set zero), r18, r20, r21, r22, r24, r25, X
*/
.global spritecanvas_putpixel
spritecanvas_putpixel:

	movw  XL,      r24

	; Pixel X position:
	; bit 0-1: Pixel select within byte
	; bit 2-3: Byte within 16 px wide sprite
	; bit 4-7: Sprite column

	mov   r24,     r22
	swap  r24
	andi  r24,     0x0F
	mul   r24,     r16     ; Addition by Sprite column
	ldi   r21,     0
	add   r20,     r0
	adc   r21,     r1      ; Adds to Y (sprites follow each other)
	eor   r1,      r1      ; Keep it zero for C ABI
	lsl   r20
	rol   r21
	lsl   r20
	rol   r21              ; To bytes
	add   XL,      r20
	adc   XH,      r21     ; Got row position

	ldi   r20,     3       ; For masking the pixel
	andi  r18,     3       ; Sanitize pixel
	andi  r22,     0x0F
	lsr   r22
	brcs  .+8
	lsl   r20
	lsl   r20
	lsl   r18
	lsl   r18
	lsr   r22
	brcs  .+4
	swap  r20
	swap  r18

	add   XL,      r22
	adc   XH,      r1      ; Got byte position
	ld    r22,     X
	com   r20
	and   r22,     r20     ; Mask off old pixel
	or    r22,     r18     ; Add in new pixel
	st    X,       r22
	ret



/*
** Clears canvas made up from adjacent sprites
**
** Inputs:
** r25:r24: Canvas start pointer
**     r22: Canvas width in 16px wide sprites
**     r20: Canvas height
** Clobbers:
** r0, r1 (set zero) r22, r24, r25, X
*/
.global spritecanvas_clear
spritecanvas_clear:

	movw  XL,      r24

	lsl   r22
	lsl   r22
	mul   r22,     r20
	add   r24,     r0
	adc   r25,     r1
	eor   r1,      r1
sclr_lp:
	st    X+,      r1
	st    X+,      r1
	st    X+,      r1
	st    X+,      r1
	cpse  XL,      r24
	rjmp  sclr_lp
	cpse  XH,      r25
	rjmp  sclr_lp
	ret



/*
** Places downscaled image on canvas
**
** Note on scaling fractions: Although 1 can not be given, in the practice it
** is possible as the fractions begin with 255, not 0 (so using 255 will give
** the desired result of no scaling effectively).
**
** The result image combines onto the existing one (should be cleared), with
** higher pixel values taking precedence.
**
** Inputs:
** r25:r24: Canvas start pointer
** r23:r22: Source ROM image start pointer
**     r21: Height of ROM image (pixels)
**     r20: Width of ROM image (pixels)
**     r19: Y start position
**     r18: X start position
**     r17: Scaling fraction Y
**     r16: Scaling fraction X
**     r14: Canvas height
** Clobbers:
** r0, r1 (set zero), r18 - r25, X, Z
*/
.global spritecanvas_drawscaled
spritecanvas_drawscaled:

	push  r17
	push  r16
	push  r15
	push  r14
	push  r13
	push  r12
	push  r11
	push  r10
	push  r9
	push  r8
	push  r7

	movw  XL,      r24
	movw  ZL,      r22
	movw  r12,     r16     ; Scaling fractions in r12 (X) and r13 (Y)

	eor   r15,     r15
	lsl   r14
	rol   r15
	lsl   r14
	rol   r15              ; Canvas height converted to bytes

	ldi   r25,     0
	lsl   r19
	rol   r25
	lsl   r19
	rol   r25
	add   XL,      r19
	adc   XH,      r25     ; Y start position

dsca_xstartlp:
	subi  r18,     0x10
	brcs  dsca_xstartlp_end
	add   XL,      r14
	adc   XH,      r15
	rjmp  dsca_xstartlp
dsca_xstartlp_end:
	subi  r18,     0xF0    ; X sprite column start position added

	ldi   r19,     0       ; Will hold start byte position
dsca_xstartbytelp:
	subi  r18,     0x04
	brcs  dsca_xstartbytelp_end
	adiw  XL,      1
	inc   r19
	rjmp  dsca_xstartbytelp
dsca_xstartbytelp_end:
	subi  r18,     0xFC    ; X sprite byte start position added

	ldi   r25,     0xFF    ; Y fractional position
	com   r19
	com   r18
	andi  r19,     3
	andi  r18,     3
	inc   r19              ; X start byte and pixel positions:
	inc   r18              ; Make these down-counters, 4 => 0
	movw  r8,      r18

dsca_ylp:
	subi  r21,     1
	brcc  .+2
	rjmp  dsca_ylpend      ; Count down source height

	mov   r22,     r20     ; Source width counter
	ldi   r23,     1       ; Source pixel counter within byte (fetch immediately)
	ldi   r24,     0xFF    ; X fractional position
	mov   r17,     r8      ; Destination pixel counter within byte
	mov   r16,     r9      ; Destination byte counter within sprite column
	movw  r10,     XL      ; Save current pointer for next row

dsca_xlp:
	subi  r22,     1
	brcs  dsca_xlpend      ; Count down source width

	dec   r23
	brne  .+4
	ldi   r23,     4
	lpm   r7,      Z+      ; Next source byte

	ldi   r19,     0
	lsl   r7
	rol   r19
	lsl   r7
	rol   r19              ; Source pixel to place

	ldi   r18,     3       ; Pixel mask
	cpi   r17,     3
	brcc  dsca_xlp_10
	cpi   r17,     2
	breq  dsca_xlp_11
	rjmp  dsca_xlp_1
dsca_xlp_10:
	swap  r19
	swap  r18
	breq  dsca_xlp_1
dsca_xlp_11:
	lsl   r19
	lsl   r19
	lsl   r18
	lsl   r18
dsca_xlp_1:

	ld    r0,      X
	mov   r1,      r0
	and   r1,      r18
	cp    r19,     r1
	brcs  dsca_xlp_2
	com   r18
	and   r0,      r18
	or    r0,      r19
dsca_xlp_2:
	st    X,       r0      ; Pixel stored if was higher

	add   r24,     r12     ; X fraction
	brcc  dsca_xlp
	dec   r17
	brne  dsca_xlp
	ldi   r17,     4
	adiw  XL,      1
	dec   r16
	brne  dsca_xlp
	ldi   r16,     4
	sbiw  XL,      4
	add   XL,      r14
	adc   XH,      r15
	rjmp  dsca_xlp

dsca_xlpend:
	movw  XL,      r10

	add   r25,     r13     ; Y fraction
	brcc  .+2
	adiw  XL,      4
	rjmp  dsca_ylp

dsca_ylpend:

	eor   r1,      r1
	pop   r7
	pop   r8
	pop   r9
	pop   r10
	pop   r11
	pop   r12
	pop   r13
	pop   r14
	pop   r15
	pop   r16
	pop   r17
	ret



/*
** Mirrors left of sprite into right, middle pixel centered
**
** Inputs:
** r25:r24: Sprite data start pointer
**     r22: Sprite height
** Clobbers:
** r20, r21, r22, r23, r24, r25, X
*/
.global spritecanvas_mirror15px
spritecanvas_mirror15px:

	movw  XL,      r24

	cpi   r22,     0
	breq  sm15_lpend
sm15_lp:
	ld    r24,     X+
	ld    r25,     X+

	mov   r23,     r25
	andi  r23,     0x0C
	swap  r23
	mov   r21,     r23
	mov   r23,     r25
	andi  r23,     0x30
	or    r21,     r23
	andi  r25,     0xC0
	swap  r25
	or    r21,     r25
	mov   r23,     r24
	andi  r23,     0x03
	or    r21,     r23

	mov   r23,     r24
	andi  r23,     0x0C
	swap  r23
	mov   r20,     r23
	mov   r23,     r24
	andi  r23,     0x30
	or    r20,     r23
	andi  r24,     0xC0
	swap  r24
	or    r20,     r24

	st    X+,      r21
	st    X+,      r20
	dec   r22
	brne  sm15_lp
sm15_lpend:
	ret

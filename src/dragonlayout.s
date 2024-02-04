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


;
; Dragon layouts. Provides layouts which can be populated with dragons of
; given sizes in a manner suitable for the limitations of the video mode's
; sprite capabilities.
;
; Dragon sizes and corresponding health ranges:
; 0: 8 - 63 (1 sprite)
; 1: 64 - 511 (1 sprite)
; 2: 512 - 4095 (2 sprites)
; 3: 4096 - 65535 (4 sprites)
;
; Layout bytes specify dragons. The bottom 2 bits are the dragon size, the
; top 6 are Y increment compared to previous dragon. 0xFF ends the list. Up
; to 16 dragons may appear in a wave.
;


.equ dragonlayout_cnt, 10

dragonlayout_00:
	.byte (0 << 2) + 0, (7 << 2) + 0, (13<< 2) + 0, (2 << 2) + 0
	.byte (15<< 2) + 0, (8 << 2) + 0, (11<< 2) + 0, (6 << 2) + 0, 0xFF
dragonlayout_01:
	.byte (0 << 2) + 0, (5 << 2) + 0, (11<< 2) + 0, (9 << 2) + 0
	.byte (4 << 2) + 0, (7 << 2) + 0, (8 << 2) + 0, (12<< 2) + 0
	.byte (1 << 2) + 0, (6 << 2) + 0, (13<< 2) + 0, (2 << 2) + 0
	.byte (7 << 2) + 0, (3 << 2) + 0, (10<< 2) + 0, (5 << 2) + 0, 0xFF
dragonlayout_02:
	.byte (0 << 2) + 0, (7 << 2) + 0, (5 << 2) + 0, (1 << 2) + 0
	.byte (11<< 2) + 1, (8 << 2) + 0, (3 << 2) + 0, (7 << 2) + 0
	.byte (2 << 2) + 0, (9 << 2) + 0, (4 << 2) + 0, (10<< 2) + 1
	.byte (2 << 2) + 0, (9 << 2) + 1, (8 << 2) + 0, (3 << 2) + 0, 0xFF
dragonlayout_03:
	.byte (0 << 2) + 0, (2 << 2) + 0, (10<< 2) + 1, (9 << 2) + 0
	.byte (4 << 2) + 1, (8 << 2) + 0, (2 << 2) + 0, (7 << 2) + 1
	.byte (9 << 2) + 0, (6 << 2) + 1, (12<< 2) + 1, (5 << 2) + 0
	.byte (6 << 2) + 0, (9 << 2) + 1, (13<< 2) + 0, (1 << 2) + 0, 0xFF
dragonlayout_04:
	.byte (0 << 2) + 0, (3 << 2) + 1, (9 << 2) + 0, (12<< 2) + 1
	.byte (7 << 2) + 2, (4 << 2) + 0, (13<< 2) + 1, (3 << 2) + 0
	.byte (7 << 2) + 1, (14<< 2) + 2, (11<< 2) + 1, (8 << 2) + 1
	.byte (3 << 2) + 0, (6 << 2) + 1, (2 << 2) + 1, (10<< 2) + 0, 0xFF
dragonlayout_05:
	.byte (0 << 2) + 1, (1 << 2) + 0, (13<< 2) + 2, (14<< 2) + 1
	.byte (6 << 2) + 1, (16<< 2) + 2, (12<< 2) + 1, (2 << 2) + 1
	.byte (15<< 2) + 2, (11<< 2) + 0, (19<< 2) + 2, (8 << 2) + 1
	.byte (4 << 2) + 0, (9 << 2) + 1, (16<< 2) + 2, (3 << 2) + 0, 0xFF
dragonlayout_06:
	.byte (0 << 2) + 1, (1 << 2) + 0, (13<< 2) + 2, (14<< 2) + 2
	.byte (12<< 2) + 1, (6 << 2) + 1, (9 << 2) + 2, (18<< 2) + 2
	.byte (9 << 2) + 1, (3 << 2) + 1, (20<< 2) + 2, (7 << 2) + 2
	.byte (21<< 2) + 0, (5 << 2) + 1, 0xFF
dragonlayout_07:
	.byte (0 << 2) + 1, (2 << 2) + 1, (16<< 2) + 2, (13<< 2) + 2
	.byte (28<< 2) + 3, (21<< 2) + 1, (7 << 2) + 1, (11<< 2) + 2
	.byte (17<< 2) + 2, (13<< 2) + 2, (14<< 2) + 1, (5 << 2) + 1, 0xFF
dragonlayout_08:
	.byte (0 << 2) + 2, (2 << 2) + 1, (13<< 2) + 1, (11<< 2) + 2
	.byte (28<< 2) + 3, (35<< 2) + 3, (23<< 2) + 1, (1 << 2) + 1
	.byte (14<< 2) + 2, (18<< 2) + 2, (10<< 2) + 1, (4 << 2) + 1, 0xFF
dragonlayout_09:
	.byte (0 << 2) + 2, (10<< 2) + 2, (29<< 2) + 3, (35<< 2) + 3
	.byte (37<< 2) + 3, (23<< 2) + 2, (14<< 2) + 2, (18<< 2) + 2
	.byte (9 << 2) + 2, 0xFF


dragonlayout_map:
	.byte   0,   8, lo8(dragonlayout_00), hi8(dragonlayout_00)
	.byte   5,  16, lo8(dragonlayout_01), hi8(dragonlayout_01)
	.byte  12,  20, lo8(dragonlayout_02), hi8(dragonlayout_02)
	.byte  18,  32, lo8(dragonlayout_03), hi8(dragonlayout_03)
	.byte  24,  40, lo8(dragonlayout_04), hi8(dragonlayout_04)
	.byte  32,  54, lo8(dragonlayout_05), hi8(dragonlayout_05)
	.byte  36,  66, lo8(dragonlayout_06), hi8(dragonlayout_06)
	.byte  48,  88, lo8(dragonlayout_07), hi8(dragonlayout_07)
	.byte  54, 120, lo8(dragonlayout_08), hi8(dragonlayout_08)
	.byte  72, 255, lo8(dragonlayout_09), hi8(dragonlayout_09)


; (Frame Max)  Mirror ID  XDisp YDisp
dragonlayout_comps_0:
	.byte  50
	.byte  0x00 + 15, 0xF8, 0xFA
	.byte  0xFF
	.byte  100
	.byte  0x00 + 14, 0xF8, 0xFA
	.byte  0xFF
	.byte  130
	.byte  0x00 + 15, 0xF8, 0xFA
	.byte  0xFF
	.byte  155
	.byte  0x00 + 16, 0xF8, 0xFA
	.byte  0xFF
	.byte  205
	.byte  0x00 + 17, 0xF8, 0xFA
	.byte  0xFF
	.byte  255
	.byte  0x00 + 16, 0xF8, 0xFA
	.byte  0xFF

; (Frame Max)  Mirror ID  XDisp YDisp
dragonlayout_comps_1:
	.byte  30
	.byte  0x00 + 18, 0xF8, 0xF8
	.byte  0xFF
	.byte  60
	.byte  0x00 + 24, 0xF8, 0xF8
	.byte  0xFF
	.byte  95
	.byte  0x00 + 23, 0xF8, 0xF8
	.byte  0xFF
	.byte  135
	.byte  0x00 + 22, 0xF8, 0xF8
	.byte  0xFF
	.byte  175
	.byte  0x00 + 21, 0xF8, 0xF8
	.byte  0xFF
	.byte  215
	.byte  0x00 + 20, 0xF8, 0xF8
	.byte  0xFF
	.byte  255
	.byte  0x00 + 19, 0xF8, 0xF8
	.byte  0xFF

; (Frame Max)  Mirror ID  XDisp YDisp
dragonlayout_comps_2:
	.byte  30
	.byte  0x00 + 25, 0xF1, 0xF4
	.byte  0x80 + 25, 0x00, 0xF4
	.byte  0xFF
	.byte  60
	.byte  0x00 + 31, 0xF1, 0xF4
	.byte  0x80 + 31, 0x00, 0xF4
	.byte  0xFF
	.byte  95
	.byte  0x00 + 30, 0xF1, 0xF4
	.byte  0x80 + 30, 0x00, 0xF4
	.byte  0xFF
	.byte  135
	.byte  0x00 + 29, 0xF1, 0xF4
	.byte  0x80 + 29, 0x00, 0xF4
	.byte  0xFF
	.byte  175
	.byte  0x00 + 28, 0xF1, 0xF4
	.byte  0x80 + 28, 0x00, 0xF4
	.byte  0xFF
	.byte  215
	.byte  0x00 + 27, 0xF1, 0xF4
	.byte  0x80 + 27, 0x00, 0xF4
	.byte  0xFF
	.byte  255
	.byte  0x00 + 26, 0xF1, 0xF4
	.byte  0x80 + 26, 0x00, 0xF4
	.byte  0xFF

; (Frame Max)  Mirror ID  XDisp YDisp
; Note, the smaller wingtip sprites come at the last positions so the sprite
; mux would first have to place the bigger body sprites
dragonlayout_comps_3:
	.byte  30
	.byte  0x00 + 39, 0xF1, 0xE8
	.byte  0x80 + 39, 0x00, 0xE8
	.byte  0x00 + 32, 0xE1, 0xFE
	.byte  0x80 + 32, 0x10, 0xFE
	.byte  0xFF
	.byte  60
	.byte  0x00 + 45, 0xF1, 0xE8
	.byte  0x80 + 45, 0x00, 0xE8
	.byte  0x00 + 38, 0xE1, 0xFB
	.byte  0x80 + 38, 0x10, 0xFB
	.byte  0xFF
	.byte  95
	.byte  0x00 + 44, 0xF1, 0xE8
	.byte  0x80 + 44, 0x00, 0xE8
	.byte  0x00 + 37, 0xE1, 0xF5
	.byte  0x80 + 37, 0x10, 0xF5
	.byte  0xFF
	.byte  135
	.byte  0x00 + 43, 0xF1, 0xE8
	.byte  0x80 + 43, 0x00, 0xE8
	.byte  0x00 + 36, 0xE1, 0xF8
	.byte  0x80 + 36, 0x10, 0xF8
	.byte  0xFF
	.byte  175
	.byte  0x00 + 42, 0xF1, 0xE8
	.byte  0x80 + 42, 0x00, 0xE8
	.byte  0x00 + 35, 0xE1, 0xFE
	.byte  0x80 + 35, 0x10, 0xFE
	.byte  0xFF
	.byte  215
	.byte  0x00 + 41, 0xF1, 0xE8
	.byte  0x80 + 41, 0x00, 0xE8
	.byte  0x00 + 34, 0xE1, 0x00
	.byte  0x80 + 34, 0x10, 0x00
	.byte  0xFF
	.byte  255
	.byte  0x00 + 40, 0xF1, 0xE8
	.byte  0x80 + 40, 0x00, 0xE8
	.byte  0x00 + 33, 0xE1, 0x00
	.byte  0x80 + 33, 0x10, 0x00
	.byte  0xFF


; Colours: Blue (0-3), Green (0-7), Red (0-7)
dragonlayout_cols:
	.byte  (2<<6) + (6<<3) + (7), (1<<6) + (3<<3) + (5), (1<<6) + (4<<3) + (7)
	.byte  (2<<6) + (0<<3) + (0), (2<<6) + (6<<3) + (5), (3<<6) + (3<<3) + (2)
	.byte  (1<<6) + (3<<3) + (0), (2<<6) + (6<<3) + (4), (1<<6) + (7<<3) + (4)
	.byte  (1<<6) + (6<<3) + (5), (1<<6) + (6<<3) + (5), (2<<6) + (7<<3) + (5)
	.byte  (1<<6) + (7<<3) + (5), (1<<6) + (6<<3) + (6), (2<<6) + (7<<3) + (6)
	.byte  (1<<6) + (0<<3) + (1), (2<<6) + (5<<3) + (5), (2<<6) + (7<<3) + (7)
	.byte  (1<<6) + (0<<3) + (0), (2<<6) + (5<<3) + (5), (3<<6) + (7<<3) + (7)
	.byte  (1<<6) + (0<<3) + (0), (2<<6) + (6<<3) + (5), (3<<6) + (7<<3) + (7)
	.byte  (2<<6) + (3<<3) + (7), (2<<6) + (3<<3) + (4), (2<<6) + (5<<3) + (7)
	.byte  (2<<6) + (1<<3) + (7), (2<<6) + (2<<3) + (4), (2<<6) + (4<<3) + (7)
	.byte  (1<<6) + (1<<3) + (1), (0<<6) + (3<<3) + (2), (2<<6) + (1<<3) + (1)
	.byte  (1<<6) + (1<<3) + (0), (0<<6) + (3<<3) + (1), (2<<6) + (1<<3) + (1)
	.byte  (1<<6) + (0<<3) + (0), (0<<6) + (3<<3) + (1), (2<<6) + (1<<3) + (0)
	.byte  (1<<6) + (0<<3) + (0), (0<<6) + (2<<3) + (1), (2<<6) + (1<<3) + (0)
	.byte  (0<<6) + (3<<3) + (4), (1<<6) + (6<<3) + (6), (1<<6) + (4<<3) + (7)
	.byte  (0<<6) + (2<<3) + (5), (1<<6) + (6<<3) + (7), (1<<6) + (3<<3) + (7)


.balign 2


/*
** Get a dragon layout suitable for the turn
**
** Inputs:
**     r24: Layout selection roll (could be a random number, should be small)
** r23:r22: Current turn
** Outputs:
**     r24: Layout index selected
** Clobbers:
** r22, r23, r25, Z
*/
.global dragonlayout_getid
dragonlayout_getid:
	cpi   r23,     0
	breq  .+2
	ldi   r22,     0xFF    ; Clip to 255
dragonlayout_gft_loop1:
	ldi   ZL,      lo8(dragonlayout_map)
	ldi   ZH,      hi8(dragonlayout_map)
	ldi   r23,     0
dragonlayout_gft_loop2:
	lpm   r25,     Z+
	cp    r22,     r25
	lpm   r25,     Z+
	brcs  dragonlayout_gft_nofit
	cp    r25,     r22
	brcs  dragonlayout_gft_nofit
	subi  r24,     1
	brcs  dragonlayout_gft_done
dragonlayout_gft_nofit:
	adiw  ZL,      2
	inc   r23
	cpi   r23,     dragonlayout_cnt
	brcs  dragonlayout_gft_loop2
	rjmp  dragonlayout_gft_loop1
dragonlayout_gft_done:
	mov   r24,     r23
	ret



/*
** Internal function to prepare pointer to a dragon layout
**
** Inputs:
**     r24: Layout to use
** Outputs:
**       Z: Pointer to the layout
** Clobbers:
** r25
*/
dragonlayout_preplayoutptr:
	ldi   ZL,      lo8(dragonlayout_map)
	ldi   ZH,      hi8(dragonlayout_map)
	lsl   r24
	lsl   r24
	sbci  r24,     0xFE    ; Add 2 to position on pointer to layout
	ldi   r25,     0
	add   ZL,      r24
	adc   ZH,      r25
	lpm   r24,     Z+
	lpm   r25,     Z+
	movw  ZL,      r24     ; On the beginning of the list
	ret



/*
** Get maximum dragon size on a layout
**
** Inputs:
**     r24: Layout to check for max. size
** Outputs:
**     r24: Maximum dragon size on the layout (0-3)
** Clobbers:
** r25, Z
*/
.global dragonlayout_getmaxsize
dragonlayout_getmaxsize:
	rcall dragonlayout_preplayoutptr
	ldi   r24,     0       ; Collect max size
dragonlayout_gm_loop:
	lpm   r25,     Z+
	cpi   r25,     0xFF
	breq  dragonlayout_gm_end
	andi  r25,     3
	cp    r24,     r25
	brcc  dragonlayout_gm_loop
	mov   r24,     r25
	rjmp  dragonlayout_gm_loop
dragonlayout_gm_end:
	ret



/*
** Get count of dragons on a layout
**
** Inputs:
**     r24: Layout to check for count of dragons
** Outputs:
**     r24: Count of dragons
** Clobbers:
** r25, Z
*/
.global dragonlayout_getcount
dragonlayout_getcount:
	rcall dragonlayout_preplayoutptr
	ldi   r24,     0xFF    ; Count length
dragonlayout_gc_loop:
	inc   r24
	lpm   r25,     Z+
	cpi   r25,     0xFF
	brne  dragonlayout_gc_loop
	ret



/*
** Get a dragon from a layout
**
** Inputs:
**     r24: Layout index to use
**     r22: Dragon index to use
** Outputs:
**     r25: Dragon size (0-3), 0xFF if no more available
**     r24: Dragon Y position, 0xFF if no more available
** Clobbers:
** r23, Z
*/
.global dragonlayout_getdragon
dragonlayout_getdragon:
	rcall dragonlayout_preplayoutptr
	ldi   r24,     0       ; Y position
dragonlayout_gd_loop:
	lpm   r25,     Z+
	cpi   r25,     0xFF
	breq  dragonlayout_gd_invalid
	mov   r23,     r25
	lsr   r25
	lsr   r25
	add   r24,     r25     ; Accumulate Y position
	subi  r22,     1
	brcc  dragonlayout_gd_loop
	mov   r25,     r23
	andi  r25,     0x03
	ret
dragonlayout_gd_invalid:
	ldi   r24,     0xFF
	ret



/*
** Get dragon sprite component list
**
** Inputs:
**     r24: Dragon size (0-3)
**     r22: Frame of animation (0: Idle gliding)
** Outputs:
** r25:r24: Component list ID
** Clobbers:
** r23, Z
*/
.global dragonlayout_getcomplist
dragonlayout_getcomplist:
	cpi   r24,     1
	brcs  dragonlayout_gcl_0
	breq  dragonlayout_gcl_1
	cpi   r24,     3
	brcs  dragonlayout_gcl_2
	ldi   ZL,      lo8(dragonlayout_comps_3)
	ldi   ZH,      hi8(dragonlayout_comps_3)
	rjmp  dragonlayout_gcl_frameloop
dragonlayout_gcl_2:
	ldi   ZL,      lo8(dragonlayout_comps_2)
	ldi   ZH,      hi8(dragonlayout_comps_2)
	rjmp  dragonlayout_gcl_frameloop
dragonlayout_gcl_1:
	ldi   ZL,      lo8(dragonlayout_comps_1)
	ldi   ZH,      hi8(dragonlayout_comps_1)
	rjmp  dragonlayout_gcl_frameloop
dragonlayout_gcl_0:
	ldi   ZL,      lo8(dragonlayout_comps_0)
	ldi   ZH,      hi8(dragonlayout_comps_0)
	; Walk through data until arriving at correct frame
dragonlayout_gcl_frameloop:
	lpm   r23,     Z+
	cp    r23,     r22
	brcc  dragonlayout_gcl_framegot
dragonlayout_gcl_dataloop:
	lpm   r23,     Z+
	cpi   r23,     0xFF
	breq  dragonlayout_gcl_frameloop
	adiw  ZL,      2
	rjmp  dragonlayout_gcl_dataloop
dragonlayout_gcl_framegot:
	movw  r24,     ZL
	ret



/*
** Get dragon sprite component
**
** Inputs:
** r25:r24: Component list ID
**     r22: Sprite component ID
** Outputs:
**     r25: Sprite index (0 - 126); X mirror flag on Bit 7. 0xFF: End
**     r24: X displacement (2's complement)
** r23:r22: Y displacement (2's complement)
** Clobbers:
** Z
*/
.global dragonlayout_getcomponent
dragonlayout_getcomponent:
	movw  ZL,      r24
	mov   r23,     r22
dragonlayout_gcp_loop:
	lpm   r25,     Z+
	cpi   r25,     0xFF
	breq  dragonlayout_gcp_end
	lpm   r24,     Z+
	lpm   r22,     Z+
	subi  r23,     1
	brcc  dragonlayout_gcp_loop
	sbrs  r22,     7
	inc   r23              ; 0xFF or 0x00, sign extend of r22
	ret
dragonlayout_gcp_end:
	mov   r24,     r25
	movw  r22,     r24
	ret



/*
** Get dragon colouring
**
** Inputs:
**     r24: Strength class
** Outputs:
**     r25: 0
**     r24: Colour 1
**     r23: Colour 2
**     r22: Colour 3
** Clobbers:
** Z
*/
.global dragonlayout_getcolours
dragonlayout_getcolours:
	cpi   r24,     15
	brcs  .+2
	ldi   r24,     15
	ldi   r25,     0
	ldi   ZL,      lo8(dragonlayout_cols)
	ldi   ZH,      hi8(dragonlayout_cols)
	add   ZL,      r24
	adc   ZH,      r25
	lsl   r24
	add   ZL,      r24
	adc   ZH,      r25
	lpm   r24,     Z+
	lpm   r23,     Z+
	lpm   r22,     Z+
	ret

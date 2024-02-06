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


.equ text_strcnt, 18

text_strlist:
	.byte lo8(text_str_gold), hi8(text_str_gold)
	.byte lo8(text_str_pop), hi8(text_str_pop)
	.byte lo8(text_str_swaps), hi8(text_str_swaps)
	.byte lo8(text_str_turn), hi8(text_str_turn)
	.byte lo8(text_str_end), hi8(text_str_end)
	.byte lo8(text_str_endsel), hi8(text_str_endsel)
	.byte lo8(text_str_buypop), hi8(text_str_buypop)
	.byte lo8(text_str_buypopsel), hi8(text_str_buypopsel)
	.byte lo8(text_str_buyswap), hi8(text_str_buyswap)
	.byte lo8(text_str_buyswapsel), hi8(text_str_buyswapsel)
	.byte lo8(text_str_buyanyswap), hi8(text_str_buyanyswap)
	.byte lo8(text_str_buyanyswapsel), hi8(text_str_buyanyswapsel)
	.byte lo8(text_str_gameover), hi8(text_str_gameover)
	.byte lo8(text_str_survived), hi8(text_str_survived)
	.byte lo8(text_str_survmonths), hi8(text_str_survmonths)
	.byte lo8(text_str_title), hi8(text_str_title)
	.byte lo8(text_str_titledesc1), hi8(text_str_titledesc1)
	.byte lo8(text_str_titledesc2), hi8(text_str_titledesc2)

text_str_gold:
	.asciz "Gold:"
text_str_pop:
	.asciz "Pop:"
text_str_swaps:
	.asciz "Swaps:"
text_str_turn:
	.asciz "Month:"
text_str_end:
	.asciz " end "
text_str_endsel:
	.byte 0x0E
	.ascii "END"
	.byte 0x0F, 0
text_str_buypop:
	.asciz " pop "
text_str_buypopsel:
	.byte 0x0E
	.ascii "POP"
	.byte 0x0F, 0
text_str_buyswap:
	.asciz " swap "
text_str_buyswapsel:
	.byte 0x0E
	.ascii "SWAP"
	.byte 0x0F, 0
text_str_buyanyswap:
	.asciz " anyswap "
text_str_buyanyswapsel:
	.byte 0x0E
	.ascii "ANYSWAP"
	.byte 0x0F, 0
text_str_gameover:
	.asciz "Game Over"
text_str_survived:
	.asciz "Survived for "
text_str_survmonths:
	.asciz " months"
text_str_title:
	.asciz "in the Dragon's Maw"
text_str_titledesc1:
	.asciz "a game by Jubatian"
text_str_titledesc2:
	.asciz "for the Uzebox console"

.balign 2



/*
** Fills in a string from the string list, returning its size
**
** Inputs:
** r25:r24: Target data pointer
**     r22: String selector
** Outputs:
** r25:r24: Length of string
** Clobbers:
** r22, r23, X, Z
*/
.global text_genstring
text_genstring:
	movw  XL,      r24
	ldi   r24,     0
	ldi   r25,     0
	cpi   r22,     text_strcnt
	brcc  text_genstring_end
	ldi   r23,     0
	lsl   r22
	rol   r23
	ldi   ZL,      lo8(text_strlist)
	ldi   ZH,      hi8(text_strlist)
	add   ZL,      r22
	adc   ZH,      r23
	lpm   r22,     Z+
	lpm   r23,     Z+
	movw  ZL,      r22
	rjmp  text_genstring_loop_e
text_genstring_loop:
	st    X+,      r22
	adiw  r24,     1
text_genstring_loop_e:
	lpm   r22,     Z+
	cpi   r22,     0
	brne  text_genstring_loop
text_genstring_end:
	ret



/*
** Fill area with data
**
** Inputs:
** r25:r24: Target data pointer
**     r22: Data byte to fill with
** r21:r20: Fill length
** Outputs:
** Clobbers:
** r24, r25, X
*/
.global text_fill
text_fill:
	movw  XL,      r24
	movw  r24,     r20
	sbiw  r24,     1
	brcs  text_fill_end
text_fill_loop:
	st    X+,      r22
	sbiw  r24,     1
	brcc  text_fill_loop
text_fill_end:
	ret



/*
** Converts 16 bits decimal input to 32 bits BCD output.
**
** Double-dabble would be the obvious way to do it, however the >=5 case on
** the low nibbles can not really be detected efficiently. The crude solution
** here ends up being faster.
**
** Inputs:
** r25:r24: 16 bits value to convert
** Outputs:
** r25:r24:r23:r22: BCD result
** Clobbers:
*/
.global text_bin16bcd
text_bin16bcd:

	; 5th digit (10000s)

	ldi   r22,     0xFF    ; For digits 5-6 (6 of course remaining zero)
	subi  r22,     0xFF    ; Add 1 for each subtraction of 10000
	subi  r24,     lo8(10000)
	sbci  r25,     hi8(10000)
	brcc  .-8
	subi  r24,     lo8(-10000)
	sbci  r25,     hi8(-10000)

	; 4th digit (1000s)

	ldi   r23,     0xEF    ; For digits 3-4
	subi  r23,     0xF0    ; Add 10 (BCD) for each subtraction of 1000
	subi  r24,     lo8(1000)
	sbci  r25,     hi8(1000)
	brcc  .-8
	subi  r24,     lo8(-1000)
	sbci  r25,     hi8(-1000)

	; 3rd digit (100s)

	subi  r23,     0xFF    ; Add 1 for each subtraction of 100
	subi  r24,     lo8(100)
	sbci  r25,     hi8(100)
	brcc  .-8
	subi  r24,     lo8(-100)

	; 2nd digit (10s)

	ldi   r25,     0xF0    ; For digits 1-2
	subi  r25,     0xF0    ; Add 10 (BCD) for each subtraction of 10
	subi  r24,     lo8(10)
	brcc  .-6
	subi  r24,     lo8(-10)

	; 1st digit (1s)

	add   r25,     r24

	; Sort digits to their return locations and done

	mov   r24,     r22     ; Digits 5-6 into r24
	mov   r22,     r25     ; Digits 1-2 into r22
	ldi   r25,     0       ; Digits 7-8 are zero
	ret

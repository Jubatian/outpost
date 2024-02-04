/*
 *  Alternative Mini VSync mixer for the Uzebox Kernel
 *  Copyright (C) 2024 Sandor Zsuga (Jubatian)
 *  Original Uzebox Kernel Copyright (C) 2008-2009 Alec Bourque
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


/*
 *  This is an alternative to the original Uzebox Vsync Mixer aiming for
 *  smaller ROM and RAM usage.
 *
 *  Note that it is not straightforward to put it in the original kernel as of
 *  this version, designed to work with the Flight of a Dragon modified
 *  kernel, however there are not too many differences to address if so.
 *
 *  - The FoaD kernel uses the GPIO registers for Sync tracking, not ZL
 *    register bits in update_sound.
 *  - The FoaD kernel amends a one cycle timing error in the original kernel
 *    affecting update_sound.
 *  - Initializing the mix buffer is a callable function in contrast to the
 *    original kernel doing it directly in Initialize() in uzeboxCore.c
 *  - The mixer buffer (mix_buf) can be smaller, so the MIX_BANK_SIZE
 *    definition (defines.h) could be changed to achieve this. It should be
 *    at least 140 for adequate operation (280 bytes buffer).
 *
 *  The activities in update_sound_buffer_fast match those of the original
 *  kernel, so video modes working directly with it due to their HSync
 *  activities should work without changes with this mixer.
 *
 *  Space saving: The ROM waves are not used, so the inclusion of the default
 *  waves can be dropped without replacement. This mixer has a fixed set of
 *  waveforms as follows:
 */


#include <avr/io.h>
#include <defines.h>


.global update_sound_buffer_fast
.global update_sound
.global process_music
.global initialize_mixer

.global mix_buf
.global mix_pos
.global sound_enabled

.global mixer



.section .bss



mix_buf:      .space MIX_BUF_SIZE
mix_pos:      .space 2
mix_wrpos:    .space 2

sound_enabled: .space 1

; Accessed in C code as MixerStruct
mixer:

tr1_vol:      .space 1
tr1_step_lo:  .space 1
tr1_step_hi:  .space 1
tr1_pos_frac: .space 1
tr1_pos:      .space 1
tr1_waveform: .space 1

tr2_vol:      .space 1
tr2_step_lo:  .space 1
tr2_step_hi:  .space 1
tr2_pos_frac: .space 1
tr2_pos:      .space 1
tr2_waveform: .space 1

tr3_vol:      .space 1
tr3_step_lo:  .space 1
tr3_step_hi:  .space 1
tr3_pos_frac: .space 1
tr3_pos:      .space 1
tr3_waveform: .space 1

mixer_end:



.section .text



;
; Initializes the sound mixer
;
; Inputs:
; Outputs:
; Clobbers:
; r23, r24, r25, Z
;
initialize_mixer:

	ldi   ZL,      lo8(mix_buf)
	ldi   ZH,      hi8(mix_buf)
	sts   mix_pos + 0, ZL
	sts   mix_pos + 1, ZH
	sts   mix_wrpos + 0, ZL
	sts   mix_wrpos + 1, ZH
	ldi   r24,     lo8(mix_buf + MIX_BUF_SIZE)
	ldi   r25,     hi8(mix_buf + MIX_BUF_SIZE)
	ldi   r23,     0x80
initmixer_lp:
	st    Z+,      r23
	cpse  ZL,      r24
	rjmp  initmixer_lp
	cpse  ZH,      r25
	rjmp  initmixer_lp

	; Rest is good as zero-initialized data, the volumes being zero
	; notably would sort things out proper

	ret



;
; Process tracks into the mixer buffer
;
; The original kernel would call high-level music processing from here as
; well, that may be readded if desirable.
;
; Clobbers:
; Assume C call (r0, r1 set zero, r18-r25, X, Z)
;
process_music:

	; (Call kernel's ProcessMusic here if sound_enabled is set)

	; Mix buffer is to be filled ahead from the current write pointer
	; (mix_pos) to the current read pointer (mix_wrpos). The normal kernel
	; calls this from the video frame IT, however the FoaD kernel rather
	; from WaitVSync, thus there it can be interrupted. Read accordingly.

procm_read_lp:
	lds   XL,      mix_pos + 0
	lds   XH,      mix_pos + 1
	lds   r23,     mix_pos + 0
	cpse  XL,      r23     ; If low byte changed (IT happened), just retry
	rjmp  procm_read_lp

	push  r2
	push  r3
	push  r4
	push  r5
	push  r6
	push  r7
	push  r8
	push  r9
	push  r10
	push  r11
	push  r12
	push  r13
	push  r14
	push  r15
	push  r16
	push  r17

	lds   ZL,      mix_wrpos + 0
	lds   ZH,      mix_wrpos + 1

	lds   r2,      tr1_step_lo
	lds   r3,      tr1_step_hi
	lds   r4,      tr1_pos_frac
	lds   r5,      tr1_pos
	lds   r20,     tr1_waveform
	lds   r16,     tr1_vol

	lds   r6,      tr2_step_lo
	lds   r7,      tr2_step_hi
	lds   r8,      tr2_pos_frac
	lds   r9,      tr2_pos
	lds   r21,     tr2_waveform
	lds   r17,     tr2_vol

	lds   r10,     tr3_step_lo
	lds   r11,     tr3_step_hi
	lds   r12,     tr3_pos_frac
	lds   r13,     tr3_pos
	lds   r22,     tr3_waveform
	lds   r18,     tr3_vol

procm_mixloop:

	add   r4,      r2
	adc   r5,      r3
	mov   r19,     r5
	cpi   r20,     1
	breq  .+4              ; 1: Square wave
	brcc  .+8              ; 2: Triangle wave (2 or above)
	rjmp  .+12             ; 0: Incrementing sawtooth
	cpi   r19,     0x80
	sbc   r19,     r19     ; 50% Square wave
	rjmp  .+6
	lsl   r19
	sbc   r0,      r0
	eor   r19,     r0      ; Triangle wave
	subi  r19,     0x80
	mulsu r19,     r16     ; Apply volume
	sbc   r0,      r0      ; Sign extend
	mov   r24,     r1
	mov   r25,     r0      ; Start off mix buffer value

	add   r8,      r6
	adc   r9,      r7
	mov   r19,     r9
	cpi   r21,     1
	breq  .+4              ; 1: Square wave
	brcc  .+8              ; 2: Triangle wave (2 or above)
	rjmp  .+12             ; 0: Incrementing sawtooth
	cpi   r19,     0x80
	sbc   r19,     r19     ; 50% Square wave
	rjmp  .+6
	lsl   r19
	sbc   r0,      r0
	eor   r19,     r0      ; Triangle wave
	subi  r19,     0x80
	mulsu r19,     r17     ; Apply volume
	sbc   r0,      r0      ; Sign extend
	add   r24,     r1
	adc   r25,     r0      ; Accumulate mix buffer value

	add   r12,     r10
	adc   r13,     r11
	mov   r19,     r13
	cpi   r22,     1
	breq  .+4              ; 1: Square wave
	brcc  .+8              ; 2: Triangle wave (2 or above)
	rjmp  .+12             ; 0: Incrementing sawtooth
	cpi   r19,     0x80
	sbc   r19,     r19     ; 50% Square wave
	rjmp  .+6
	lsl   r19
	sbc   r0,      r0
	eor   r19,     r0      ; Triangle wave
	subi  r19,     0x80
	mulsu r19,     r18     ; Apply volume
	sbc   r0,      r0      ; Sign extend
	add   r24,     r1
	adc   r25,     r0      ; Accumulate mix buffer value

	subi  r24,     0x80
	sbci  r25,     0xFF
	cpi   r25,     0
	breq  .+6              ; 0: In proper 8 bits range
	ldi   r24,     0
	brmi  .+2              ; Negative: Clip to zero
	dec   r24              ; Positive: Clip to 0xFF
	st    Z+,      r24

	ldi   r24,     hi8(mix_buf + MIX_BUF_SIZE)
	cpi   ZL,      lo8(mix_buf + MIX_BUF_SIZE)
	cpc   ZH,      r24
	brcs  .+4
	ldi   ZL,      lo8(mix_buf)
	ldi   ZH,      hi8(mix_buf)

	cpse  ZL,      XL
	rjmp  procm_mixloop
	cpse  ZH,      XH
	rjmp  procm_mixloop

	sts   tr1_pos_frac, r4
	sts   tr1_pos, r5

	sts   tr2_pos_frac, r8
	sts   tr2_pos, r9

	sts   tr3_pos_frac, r12
	sts   tr3_pos, r13

	sts   mix_wrpos + 0, ZL
	sts   mix_wrpos + 1, ZH

	eor   r1,      r1
	pop   r17
	pop   r16
	pop   r15
	pop   r14
	pop   r13
	pop   r12
	pop   r11
	pop   r10
	pop   r9
	pop   r8
	pop   r7
	pop   r6
	pop   r5
	pop   r4
	pop   r3
	pop   r2
	ret



;
; Update sound buffer on a HSync, compact routine
;
; This is called by some Vsync mixer only video modes, so retains
; compatibility with the original kernel in register usage and cycle count.
;
; Inputs:
; Outputs:
; Clobbers:
; r16, r17, Z
;
update_sound_buffer_fast:
	lds   ZL,      mix_pos + 0
	lds   ZH,      mix_pos + 1
	ld    r16,     Z+
	sts   _SFR_MEM_ADDR(OCR2A), r16 ; (8) Output audio sample to PWM
	ldi   r16,     hi8(mix_buf + MIX_BUF_SIZE)
	cpi   ZL,      lo8(mix_buf + MIX_BUF_SIZE)
	cpc   ZH,      r16
	ldi   r16,     lo8(mix_buf)
	ldi   r17,     hi8(mix_buf)
	brcs  .+2
	movw  ZL,      r16              ; (15)
	sts   mix_pos + 0, ZL
	sts   mix_pos + 1, ZH           ; (19)
	nop
	ret                             ; (24) Original kernel's cycles



;
; Update sound buffer on a HSync, conventional call
;
; This is called on all HSyncs normally (unless the video mode itself used
; the routine above or possibly did the update by itself).
;
; The normal kernel would receive the video phase in ZL, and the short pulses
; are a cycle off compared to this implementation suiting the FoaD kernel.
;
; Inputs:
; Outputs:
; Clobbers:
; ZH
;
update_sound:
	push  r16
	push  r17
	push  r18
	push  ZL                        ; (8)

	lds   ZL,      mix_pos + 0
	lds   ZH,      mix_pos + 1
	ld    r16,     Z+
	sts   _SFR_MEM_ADDR(OCR2A), r16 ; (16) Output audio sample to PWM
	ldi   r16,     hi8(mix_buf + MIX_BUF_SIZE)
	cpi   ZL,      lo8(mix_buf + MIX_BUF_SIZE)
	cpc   ZH,      r16
	ldi   r16,     lo8(mix_buf)
	ldi   r17,     hi8(mix_buf)
	brcs  .+2
	movw  ZL,      r16              ; (23)
	sts   mix_pos + 0, ZL
	sts   mix_pos + 1, ZH           ; (27)

	ldi   ZH,      7
	dec   ZH
	brne  .-4
	rjmp  .

	pop   ZL
	pop   r18
	pop   r17
	pop   r16

	;--- Video sync update ( 68 cy LOW pulse) ---
	sbic  _SFR_IO_ADDR(GPIOR0), 0
	sbi   _SFR_IO_ADDR(SYNC_PORT), SYNC_PIN
	;--------------------------------------------
	sbis  _SFR_IO_ADDR(GPIOR0), 0
	rjmp  .+2
	ret                             ; Short pulse return (Part of VBlank)

	ldi   ZH,      21
	dec   ZH
	brne  .-4

	;--- Video sync update (136 cy LOW pulse) ---
	sbic  _SFR_IO_ADDR(GPIOR0), 1
	sbi   _SFR_IO_ADDR(SYNC_PORT), SYNC_PIN
	;--------------------------------------------
	sbis  _SFR_IO_ADDR(GPIOR0), 1
	rjmp  .                         ; (Just maintain cycle count compatibility here)

	ret                             ; Normal HSync return

/*
 *  Alternative VSync mixer for the Uzebox Kernel
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
 *  This VSync mixer was specifically made for Outpost in the Dragon's Maw
 *  with an aim to trim sizes. Smaller RAM buffer, and the waveforms designed
 *  to mix with a 128 character 1bpp ASCII font (these fonts have 256 byte
 *  long rows, so the upper 128 bytes would remain unused if only the ASCII
 *  range is used).
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

; Normal Uzebox kernel's MixerStruct

mixer:

.equ MIX_VOL,        0
.equ MIX_STEP_LO,    1
.equ MIX_STEP_HI,    2
.equ MIX_POS_FRAC,   3
.equ MIX_POS,        4
.equ MIX_WAVEFORM,   5

.equ CHANNEL0_MIXER, 0
	.space 6
.equ CHANNEL1_MIXER, 6
	.space 6
.equ CHANNEL2_MIXER, 12
	.space 6

mixer_end:

; Extended channel parameters, continuing from normal params

.equ MEXT_FSWEEP_LO, 0
.equ MEXT_FSWEEP_HI, 1
.equ MEXT_VSWEEP_LO, 2
.equ MEXT_VSWEEP_HI, 3
.equ MEXT_FVIBSTEP,  4
.equ MEXT_FVIBPOS,   5
.equ MEXT_FVIBWAVE,  6
.equ MEXT_VVIBSTEP,  7
.equ MEXT_VVIBPOS,   8
.equ MEXT_VVIBWAVE,  9
.equ MEXT_STEP_FLO,  10
.equ MEXT_STEP_VLO,  11

.equ CHANNEL0_MEXT,  18
	.space 12
.equ CHANNEL1_MEXT,  30
	.space 12
.equ CHANNEL2_MEXT,  42
	.space 12



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
	push  YL
	push  YH

	lds   YL,      mix_wrpos + 0
	lds   YH,      mix_wrpos + 1

	ldi   ZL,      lo8(mixer)
	ldi   ZH,      hi8(mixer)

	ldd   r14,     Z + (CHANNEL0_MIXER + MIX_POS_FRAC)
	ldd   r4,      Z + (CHANNEL0_MIXER + MIX_POS)
	ldd   r5,      Z + (CHANNEL0_MIXER + MIX_WAVEFORM)

	ldd   r15,     Z + (CHANNEL1_MIXER + MIX_POS_FRAC)
	ldd   r8,      Z + (CHANNEL1_MIXER + MIX_POS)
	ldd   r9,      Z + (CHANNEL1_MIXER + MIX_WAVEFORM)

	ldd   r20,     Z + (CHANNEL2_MIXER + MIX_POS_FRAC)
	ldd   r12,     Z + (CHANNEL2_MIXER + MIX_POS)
	ldd   r13,     Z + (CHANNEL2_MIXER + MIX_WAVEFORM)

	ldi   r19,     0

procm_mixloop:

	; Process effects. Effect processing occurs for every 33 samples,
	; this overall gives 8 effect ticks per frame (262 lines which is
	; 2 short of 33 * 8).

	subi  r19,     1
	brcs  .+2
	rjmp  procm_mixloop_endeff
	ldi   r19,     33

	ldi   ZL,      lo8(mixer)
	ldi   ZH,      hi8(mixer)
	ldd   r21,     Z + (CHANNEL0_MEXT + MEXT_FSWEEP_HI)
	ldd   r22,     Z + (CHANNEL0_MEXT + MEXT_FSWEEP_LO)
	ldd   r24,     Z + (CHANNEL0_MEXT + MEXT_STEP_FLO)
	ldd   r10,     Z + (CHANNEL0_MIXER + MIX_STEP_LO)
	ldd   r11,     Z + (CHANNEL0_MIXER + MIX_STEP_HI)
	ldd   r18,     Z + (CHANNEL0_MIXER + MIX_VOL)
	rcall process_music_freqslide
	std   Z + (CHANNEL0_MEXT + MEXT_STEP_FLO), r23
	std   Z + (CHANNEL0_MIXER + MIX_STEP_LO),  r10
	std   Z + (CHANNEL0_MIXER + MIX_STEP_HI),  r11
	ldd   r21,     Z + (CHANNEL0_MEXT + MEXT_VSWEEP_HI)
	ldd   r22,     Z + (CHANNEL0_MEXT + MEXT_VSWEEP_LO)
	ldd   r23,     Z + (CHANNEL0_MEXT + MEXT_STEP_VLO)
	rcall process_music_volslide
	std   Z + (CHANNEL0_MEXT + MEXT_STEP_VLO), r23
	std   Z + (CHANNEL0_MIXER + MIX_VOL),      r18
	ldd   r22,     Z + (CHANNEL0_MEXT + MEXT_FVIBPOS)
	ldd   r23,     Z + (CHANNEL0_MEXT + MEXT_FVIBWAVE)
	ldd   r24,     Z + (CHANNEL0_MEXT + MEXT_VVIBPOS)
	ldd   r25,     Z + (CHANNEL0_MEXT + MEXT_VVIBWAVE)
	ldd   r0,      Z + (CHANNEL0_MEXT + MEXT_FVIBSTEP)
	ldd   r1,      Z + (CHANNEL0_MEXT + MEXT_VVIBSTEP)
	rcall process_music_vibrato
	ldi   ZL,      lo8(mixer)
	ldi   ZH,      hi8(mixer)
	std   Z + (CHANNEL0_MEXT + MEXT_FVIBPOS), r22
	std   Z + (CHANNEL0_MEXT + MEXT_VVIBPOS), r24
	movw  r2,      r10
	mov   r16,     r18

	ldd   r21,     Z + (CHANNEL1_MEXT + MEXT_FSWEEP_HI)
	ldd   r22,     Z + (CHANNEL1_MEXT + MEXT_FSWEEP_LO)
	ldd   r24,     Z + (CHANNEL1_MEXT + MEXT_STEP_FLO)
	ldd   r10,     Z + (CHANNEL1_MIXER + MIX_STEP_LO)
	ldd   r11,     Z + (CHANNEL1_MIXER + MIX_STEP_HI)
	ldd   r18,     Z + (CHANNEL1_MIXER + MIX_VOL)
	rcall process_music_freqslide
	std   Z + (CHANNEL1_MEXT + MEXT_STEP_FLO), r23
	std   Z + (CHANNEL1_MIXER + MIX_STEP_LO),  r10
	std   Z + (CHANNEL1_MIXER + MIX_STEP_HI),  r11
	ldd   r21,     Z + (CHANNEL1_MEXT + MEXT_VSWEEP_HI)
	ldd   r22,     Z + (CHANNEL1_MEXT + MEXT_VSWEEP_LO)
	ldd   r23,     Z + (CHANNEL1_MEXT + MEXT_STEP_VLO)
	rcall process_music_volslide
	std   Z + (CHANNEL1_MEXT + MEXT_STEP_VLO), r23
	std   Z + (CHANNEL1_MIXER + MIX_VOL),      r18
	ldd   r22,     Z + (CHANNEL1_MEXT + MEXT_FVIBPOS)
	ldd   r23,     Z + (CHANNEL1_MEXT + MEXT_FVIBWAVE)
	ldd   r24,     Z + (CHANNEL1_MEXT + MEXT_VVIBPOS)
	ldd   r25,     Z + (CHANNEL1_MEXT + MEXT_VVIBWAVE)
	ldd   r0,      Z + (CHANNEL1_MEXT + MEXT_FVIBSTEP)
	ldd   r1,      Z + (CHANNEL1_MEXT + MEXT_VVIBSTEP)
	rcall process_music_vibrato
	ldi   ZL,      lo8(mixer)
	ldi   ZH,      hi8(mixer)
	std   Z + (CHANNEL1_MEXT + MEXT_FVIBPOS), r22
	std   Z + (CHANNEL1_MEXT + MEXT_VVIBPOS), r24
	movw  r6,      r10
	mov   r17,     r18

	ldd   r21,     Z + (CHANNEL2_MEXT + MEXT_FSWEEP_HI)
	ldd   r22,     Z + (CHANNEL2_MEXT + MEXT_FSWEEP_LO)
	ldd   r24,     Z + (CHANNEL2_MEXT + MEXT_STEP_FLO)
	ldd   r10,     Z + (CHANNEL2_MIXER + MIX_STEP_LO)
	ldd   r11,     Z + (CHANNEL2_MIXER + MIX_STEP_HI)
	ldd   r18,     Z + (CHANNEL2_MIXER + MIX_VOL)
	rcall process_music_freqslide
	std   Z + (CHANNEL2_MEXT + MEXT_STEP_FLO), r23
	std   Z + (CHANNEL2_MIXER + MIX_STEP_LO),  r10
	std   Z + (CHANNEL2_MIXER + MIX_STEP_HI),  r11
	ldd   r21,     Z + (CHANNEL2_MEXT + MEXT_VSWEEP_HI)
	ldd   r22,     Z + (CHANNEL2_MEXT + MEXT_VSWEEP_LO)
	ldd   r23,     Z + (CHANNEL2_MEXT + MEXT_STEP_VLO)
	rcall process_music_volslide
	std   Z + (CHANNEL2_MEXT + MEXT_STEP_VLO), r23
	std   Z + (CHANNEL2_MIXER + MIX_VOL),      r18
	ldd   r22,     Z + (CHANNEL2_MEXT + MEXT_FVIBPOS)
	ldd   r23,     Z + (CHANNEL2_MEXT + MEXT_FVIBWAVE)
	ldd   r24,     Z + (CHANNEL2_MEXT + MEXT_VVIBPOS)
	ldd   r25,     Z + (CHANNEL2_MEXT + MEXT_VVIBWAVE)
	ldd   r0,      Z + (CHANNEL2_MEXT + MEXT_FVIBSTEP)
	ldd   r1,      Z + (CHANNEL2_MEXT + MEXT_VVIBSTEP)
	rcall process_music_vibrato
	ldi   ZL,      lo8(mixer)
	ldi   ZH,      hi8(mixer)
	std   Z + (CHANNEL2_MEXT + MEXT_FVIBPOS), r22
	std   Z + (CHANNEL2_MEXT + MEXT_VVIBPOS), r24

procm_mixloop_endeff:

	; Process samples

	add   r14,     r2
	adc   r4,      r3
	movw  ZL,      r4
	brmi  .+4              ; 0x80 - 0xFF is OK where it is
	ori   ZL,      0x80
	inc   ZH               ; 0x00 - 0x7F is placed a bank higher
	lpm   r22,     Z
	mulsu r22,     r16     ; Apply volume
	sbc   r0,      r0      ; Sign extend
	mov   r24,     r1
	mov   r25,     r0      ; Start off mix buffer value

	add   r15,     r6
	adc   r8,      r7
	movw  ZL,      r8
	brmi  .+4              ; 0x80 - 0xFF is OK where it is
	ori   ZL,      0x80
	inc   ZH               ; 0x00 - 0x7F is placed a bank higher
	lpm   r22,     Z
	mulsu r22,     r17     ; Apply volume
	sbc   r0,      r0      ; Sign extend
	add   r24,     r1
	adc   r25,     r0      ; Accumulate mix buffer value

	add   r20,     r10
	adc   r12,     r11
	movw  ZL,      r12
	brmi  .+4              ; 0x80 - 0xFF is OK where it is
	ori   ZL,      0x80
	inc   ZH               ; 0x00 - 0x7F is placed a bank higher
	lpm   r22,     Z
	mulsu r22,     r18     ; Apply volume
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
	st    Y+,      r24

	ldi   r24,     hi8(mix_buf + MIX_BUF_SIZE)
	cpi   YL,      lo8(mix_buf + MIX_BUF_SIZE)
	cpc   YH,      r24
	brcs  .+4
	ldi   YL,      lo8(mix_buf)
	ldi   YH,      hi8(mix_buf)

	cpse  YL,      XL
	rjmp  procm_mixloop
	cpse  YH,      XH
	rjmp  procm_mixloop

	ldi   ZL,      lo8(mixer)
	ldi   ZH,      hi8(mixer)

	std   Z + (CHANNEL0_MIXER + MIX_POS_FRAC), r14
	std   Z + (CHANNEL0_MIXER + MIX_POS),      r4

	std   Z + (CHANNEL1_MIXER + MIX_POS_FRAC), r15
	std   Z + (CHANNEL1_MIXER + MIX_POS),      r8

	std   Z + (CHANNEL2_MIXER + MIX_POS_FRAC), r20
	std   Z + (CHANNEL2_MIXER + MIX_POS),      r12

	sts   mix_wrpos + 0, YL
	sts   mix_wrpos + 1, YH

	eor   r1,      r1
	pop   YH
	pop   YL
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
; Process frequency slide on a channel
;
; Inputs:
; r21:r22: Slide multiplier High:Low (0x8000: No slide)
; r11:r10: Step High:Low
;     r24: Step fraction
; Outputs:
; r11:r10: New Step High:Low
;     r23: New Step fraction
; Clobbers:
; r0, r1, r24, r25
;
process_music_freqslide:

	mul   r24,     r22
	mov   r25,     r1
	ldi   r23,     0
	mul   r24,     r21
	add   r25,     r0
	adc   r23,     r1
	sbc   r24,     r24     ; 0xFF if carry, 0 otherwise
	andi  r24,     1
	mul   r10,     r22
	add   r25,     r0
	adc   r23,     r1
	brcc  .+2
	inc   r24
	mul   r10,     r21
	add   r23,     r0
	adc   r24,     r1
	sbc   r25,     r25     ; 0xFF if carry, 0 otherwise
	andi  r25,     1
	mul   r11,     r22
	add   r23,     r0
	adc   r24,     r1
	brcc  .+2
	inc   r25
	mul   r11,     r21
	add   r24,     r0
	adc   r25,     r1
	lsl   r23
	rol   r24
	rol   r25
	movw  r10,     r24
	ret



;
; Process volume slide on a channel
;
; Inputs:
; r21:r22: Step High:Low (0: No slide)
; r18:r23: Volume Whole:Fraction
; Outputs:
; r18:r23: New Volume Whole:Fraction
; Clobbers:
; r0, r1, r24, r25
;
process_music_volslide:

	add   r23,     r22
	adc   r18,     r21
	sbrc  r21,     7
	rjmp  process_music_volslide_neg
	brcc  process_music_volslide_end
	ldi   r18,     0xFF
	ldi   r23,     0xFF
	ret
process_music_volslide_neg:
	brcs  process_music_volslide_end
	ldi   r18,     0
	ldi   r23,     0
process_music_volslide_end:
	ret



;
; Process vibrato (frequency / volume) for a channel
;
; Inputs:
; r23:r22: Frequency waveform and position
;     r0:  Frequency step
; r25:r24: Volume waveform and position
;     r1:  Volume step
; r11:r10: Step High:Low
;     r18: Volume
; Outputs:
;     r22: Updated frequency position
;     r24: Updated volume position
; r11:r10: New Step High:Low
;     r18: New Volume
; Clobbers:
; r0, r1, r21, r23, t25, Z
;
process_music_vibrato:

	movw  ZL,      r22
	add   r22,     r0
	sbrs  ZL,      7
	inc   ZH               ; 0x00 - 0x7F is placed a bank higher
	ori   ZL,      0x80
	lpm   r23,     Z       ; r23: Frequency shift (signed)

	movw  ZL,      r24
	add   r24,     r1
	sbrs  ZL,      7
	inc   ZH               ; 0x00 - 0x7F is placed a bank higher
	ori   ZL,      0x80
	lpm   r25,     Z       ; r25: Volume shift (signed)

	asr   r23
	asr   r23
	asr   r23
	asr   r23              ; Divide by 16 for ~1 whole tone up/down range
	subi  r23,     0x80    ; Unsigned, 128 should be center
	mul   r10,     r23
	mov   r21,     r1
	mul   r11,     r23
	add   r0,      r21
	brcc  .+2
	inc   r1
	lsl   r0
	rol   r1
	movw  r10,     r0      ; New step value

	subi  r25,     0x7F    ; Unsigned, 128 should be center, however...
	breq  .+4              ; 0 => 256 - keep volume unchanged!
	mul   r18,     r25
	mov   r18,     r1      ; New volume
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

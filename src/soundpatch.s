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



#include "freqs.h"



.section .text



;
; Sound patch commands, high 4 bits
;
.equ CMD_WFREQ,      0x00 ; Set Waveform (low 4 bits) and Frequency, 2 bytes follow
.equ CMD_WFREQJUMP,  0x10 ; WFREQ and Jump to address (4 bytes)
.equ CMD_VOLSWEEP,   0x20 ; 12 bits Volume Sweep (high 12 bits of sweep value)
.equ CMD_FREQSWEEP,  0x30 ; 12 bits Frequency sweep (low 12 bits, sign extended)
.equ CMD_VOLVIB,     0x40 ; Volume Vibrato, low 4 bits waveform, 1 byte step
.equ CMD_FREQVIB,    0x50 ; Frequency Vibrato, low 4 bits waveform, 1 byte step
.equ CMD_VOLUME,     0x60 ; Coarse immediate Volume set (16 levels)
.equ CMD_LOWPRI,     0xD0 ; Low priority section start + Wait 1-16 ticks
.equ CMD_WAIT,       0xE0 ; Wait 1-16 ticks
.equ CMD_END,        0xF0 ; End of patch, free to be taken over

;
; Waveforms
;
.equ WAVE_SAW,       0
.equ WAVE_NOISE,     1
.equ WAVE_TRIANGLE,  2
.equ WAVE_SQUARE,    3



patchdata:

patch_match:
    .byte CMD_WFREQ + WAVE_TRIANGLE, hi8(FREQS_A5), lo8(FREQS_A5)
    .byte CMD_VOLUME + 0x5
    .byte CMD_VOLSWEEP + 0xF, 0xF6
    .byte CMD_WAIT + 4
    .byte CMD_WFREQ + WAVE_TRIANGLE, hi8(FREQS_B5), lo8(FREQS_B5)
    .byte CMD_VOLUME + 0x4
    .byte CMD_VOLSWEEP + 0xF, 0xF6
    .byte CMD_WAIT + 4
    .byte CMD_WFREQ + WAVE_TRIANGLE, hi8(FREQS_C6), lo8(FREQS_C6)
    .byte CMD_VOLUME + 0x3
    .byte CMD_VOLSWEEP + 0xF, 0xF6
    .byte CMD_WAIT + 3
    .byte CMD_LOWPRI + 3
    .byte CMD_END

patch_arrow0:
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 9
    .byte CMD_WFREQ + WAVE_TRIANGLE, hi8(FREQS_D4), lo8(FREQS_D4)
patch_arrow0_entry:
    .byte CMD_VOLUME + 0x8
    .byte CMD_VOLSWEEP + 0xF, 0xF6
    .byte CMD_FREQSWEEP + 0xF, 0xE0
    .byte CMD_WAIT + 4
    .byte CMD_FREQSWEEP + 0xF, 0xF8
    .byte CMD_LOWPRI + 4
    .byte CMD_END

patch_arrow1:
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 11
    .byte CMD_WFREQJUMP + WAVE_TRIANGLE, hi8(FREQS_E4), lo8(FREQS_E4), lo8(patch_arrow0_entry - patchdata)

patch_cannon:
    .byte CMD_WFREQ + WAVE_NOISE, hi8(FREQS_A2), lo8(FREQS_A2)
    .byte CMD_FREQVIB + WAVE_TRIANGLE, 37
    .byte CMD_VOLUME + 0xA
    .byte CMD_VOLSWEEP + 0xF, 0xE0
    .byte CMD_FREQSWEEP + 0x9, 0x00
    .byte CMD_WAIT + 2
    .byte CMD_VOLSWEEP + 0xF, 0xF6
    .byte CMD_FREQSWEEP + 0xF, 0xF0
    .byte CMD_WAIT + 2
    .byte CMD_LOWPRI + 4
    .byte CMD_END

patch_chomp:
    .byte CMD_WFREQ + WAVE_NOISE, hi8(FREQS_G3), lo8(FREQS_G3)
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 37
    .byte CMD_FREQVIB + WAVE_SQUARE, 31
    .byte CMD_FREQSWEEP + 0x0, 0x50
    .byte CMD_VOLUME + 0x4
    .byte CMD_VOLSWEEP + 0x0, 0xF0
    .byte CMD_WAIT + 1
    .byte CMD_VOLSWEEP + 0xF, 0xF8
    .byte CMD_WAIT + 2
    .byte CMD_VOLSWEEP + 0xF, 0xE4
    .byte CMD_FREQSWEEP + 0xB, 0x00
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 19
    .byte CMD_WAIT + 4
    .byte CMD_FREQSWEEP + 0xF, 0xF0
    .byte CMD_WAIT + 6
    .byte CMD_LOWPRI + 10
    .byte CMD_END

patch_die0:
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 11
    .byte CMD_FREQVIB + WAVE_SAW, 5
    .byte CMD_WFREQ + WAVE_NOISE, hi8(FREQS_G1), lo8(FREQS_G1)
patch_die0_entry:
    .byte CMD_FREQSWEEP + 0x0, 0x30
    .byte CMD_VOLUME + 0x4
    .byte CMD_VOLSWEEP + 0x0, 0x50
    .byte CMD_WAIT + 2
    .byte CMD_VOLSWEEP + 0xF, 0xF0
    .byte CMD_WAIT + 4
    .byte CMD_FREQSWEEP + 0xF, 0xD0
    .byte CMD_WAIT + 6
    .byte CMD_LOWPRI + 10
    .byte CMD_END

patch_die1:
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 7
    .byte CMD_FREQVIB + WAVE_SAW, 6
    .byte CMD_WFREQJUMP + WAVE_NOISE, hi8(FREQS_C2), lo8(FREQS_C2), lo8(patch_die0_entry - patchdata)

patch_swap:
    .byte CMD_WFREQ + WAVE_NOISE, hi8(FREQS_F1), lo8(FREQS_F1)
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 5
    .byte CMD_FREQVIB + WAVE_SQUARE, 11
    .byte CMD_FREQSWEEP + 0x0, 0x0C
    .byte CMD_VOLSWEEP + 0x0, 0x30
    .byte CMD_WAIT + 2
    .byte CMD_VOLSWEEP + 0xF, 0xF8
    .byte CMD_LOWPRI + 10
    .byte CMD_END

patch_test:

patch_a3:
    .byte CMD_WFREQJUMP + WAVE_TRIANGLE, hi8(FREQS_A3), lo8(FREQS_A3), lo8(patch_bb3_entry - patchdata)

patch_c4:
    .byte CMD_WFREQJUMP + WAVE_TRIANGLE, hi8(FREQS_C4), lo8(FREQS_C4), lo8(patch_bb3_entry - patchdata)

patch_db4:
    .byte CMD_WFREQJUMP + WAVE_TRIANGLE, hi8(FREQS_Db4), lo8(FREQS_Db4), lo8(patch_bb3_entry - patchdata)

patch_bb3:
    .byte CMD_WFREQ + WAVE_TRIANGLE, hi8(FREQS_Bb3), lo8(FREQS_Bb3)
patch_bb3_entry:
    .byte CMD_VOLUME + 0x7
    .byte CMD_VOLSWEEP + 0xF, 0xFD
    .byte CMD_LOWPRI + 1
    .byte CMD_END

patch_desc2:
    .byte CMD_FREQVIB + WAVE_SQUARE, 5
    .byte CMD_WFREQJUMP + WAVE_SAW, hi8(FREQS_F4), lo8(FREQS_F4), lo8(patch_desc1_entry - patchdata)

patch_desc1:
    .byte CMD_VOLVIB + WAVE_TRIANGLE, 7
    .byte CMD_WFREQ + WAVE_SQUARE, hi8(FREQS_C4), lo8(FREQS_C4)
patch_desc1_entry:
    .byte CMD_VOLUME + 0
    .byte CMD_VOLSWEEP + 0x0, 0x30
    .byte CMD_FREQSWEEP + 0xF, 0xF8
    .byte CMD_WAIT + 6
    .byte CMD_VOLSWEEP + 0xF, 0xFF
    .byte CMD_LOWPRI + 15
    .byte CMD_END

patch_step:
    .byte CMD_WFREQ + WAVE_NOISE, hi8(FREQS_C3), lo8(FREQS_C3)
    .byte CMD_VOLUME + 0x4
    .byte CMD_VOLSWEEP + 0xF, 0x80
    .byte CMD_LOWPRI + 3
    .byte CMD_END

patchlist:
    .byte lo8(patch_step - patchdata)
    .byte lo8(patch_swap - patchdata)
    .byte lo8(patch_die0 - patchdata)
    .byte lo8(patch_die1 - patchdata)
    .byte lo8(patch_chomp - patchdata)
    .byte lo8(patch_cannon - patchdata)
    .byte lo8(patch_arrow0 - patchdata)
    .byte lo8(patch_arrow1 - patchdata)
    .byte lo8(patch_match - patchdata)
    .byte lo8(patch_c4 - patchdata)
    .byte lo8(patch_db4 - patchdata)
    .byte lo8(patch_bb3 - patchdata)
    .byte lo8(patch_a3 - patchdata)
    .byte lo8(patch_desc1 - patchdata)
    .byte lo8(patch_desc2 - patchdata)



.equ PT_C4,  9
.equ PT_DB4, 10
.equ PT_BB3, 11
.equ PT_A3,  12

tunedata:

tune_end:
    .byte PT_BB3, 60
    .byte PT_BB3, 45
    .byte PT_BB3, 15
    .byte PT_BB3, 120

    .byte PT_BB3, 60
    .byte PT_BB3, 45
    .byte PT_BB3, 15
    .byte PT_BB3, 60
    .byte PT_DB4, 45
    .byte PT_C4,  15

    .byte PT_DB4, 5
    .byte PT_C4,  40
    .byte PT_BB3, 15
    .byte PT_BB3, 45
    .byte PT_A3,  15
    .byte PT_BB3, 0

tunelist:
    .byte lo8(tune_end - tunedata)



.balign 2



.section .bss



patch_channels:
	.space       2 * 3
.equ CHAN_POS,       0
.equ CHAN_FLAGS,     1
.equ CHAN_FLAG_RUN,  0x80
.equ CHAN_FLAG_HPRI, 0x40
.equ CHAN_FLAG_WAIT, 0x20
.equ CHAN_FLAG_NOPE, 0x10
.equ CHAN_FLAG_TIME, 0x0F

tune_tick:
	.space       1
tune_chans:
	.space       1
tune_offs:
	.space       1



.section .text


/**
 * @brief   Initializes audio
 *
 * Makes sure everything is silent and ready to play
 */
.global soundpatch_init
soundpatch_init:

	ldi   r24,     0
	call  sound_ll_reseteffects
	ldi   r24,     1
	call  sound_ll_reseteffects
	ldi   r24,     2
	call  sound_ll_reseteffects
	rjmp  soundpatch_silence_resetdata



/**
 * @brief   Processes a tick for tune play
 *
 * Advances playing tunes as appropriate, call every frame
 */
.global soundpatch_tunetick
soundpatch_tunetick:

	lds   r24,     tune_tick
	subi  r24,     1
	brcs  soundpatch_tunetick_end
	sts   tune_tick, r24
	brne  soundpatch_tunetick_end
	lds   ZL,      tune_offs
	ldi   ZH,      0
	subi  ZL,      lo8(-(tunedata))
	sbci  ZH,      hi8(-(tunedata))
	lpm   r22,     Z+
	lpm   r24,     Z+
	subi  ZL,      lo8(tunedata)
	sts   tune_offs, ZL
	sts   tune_tick, r24
	lds   r24,     tune_chans
	rcall soundpatch_play
soundpatch_tunetick_end:
	ret



/**
 * @brief   Processes a tick
 *
 * Advances playing patches as appropriate, call every frame
 */
.global soundpatch_tick
soundpatch_tick:

	rcall soundpatch_tunetick

	push  r13
	push  r14
	push  r15
	push  r16
	push  r17
	push  YL
	push  YH
	ldi   YL,      lo8(patch_channels)
	ldi   YH,      hi8(patch_channels)

soundpatch_tick_chloop:

	ldd   r16,     Y + CHAN_FLAGS
	sbrs  r16,     7       ; CHAN_FLAG_RUN
	rjmp  soundpatch_tick_chloop_chdone
	sbrs  r16,     5       ; CHAN_FLAG_WAIT
	rjmp  soundpatch_tick_chloop_volwaitdone
	mov   r24,     YL
	subi  r24,     lo8(patch_channels)
	lsr   r24              ; r24: Channel number 0-3
	call  sound_ll_getvolume
	cpi   r24,     0
	breq  .+2
	rjmp  soundpatch_tick_chloop_chdone
	andi  r16,     (0xFF ^ CHAN_FLAG_WAIT)
	std   Y + CHAN_FLAGS, r16
	mov   r24,     YL
	subi  r24,     lo8(patch_channels)
	lsr   r24              ; r24: Channel number 0-3
	call  sound_ll_reseteffects

soundpatch_tick_chloop_volwaitdone:

	mov   r17,     r16
	andi  r17,     CHAN_FLAG_TIME
	breq  soundpatch_tick_chloop_proc
	dec   r16
	std   Y + CHAN_FLAGS, r16
	rjmp  soundpatch_tick_chloop_chdone

soundpatch_tick_chloop_proc:

	ldd   ZL,      Y + CHAN_POS

soundpatch_tick_chloop_procrecalc:

	ldi   ZH,      0
	subi  ZL,      lo8(-(patchdata))
	sbci  ZH,      hi8(-(patchdata))

soundpatch_tick_chloop_procnext:

	lpm   r17,     Z+
	mov   r24,     YL
	subi  r24,     lo8(patch_channels)
	lsr   r24              ; r24: Channel number 0-3
	mov   r25,     r17
	andi  r25,     0xF0
	mov   r22,     r17
	andi  r22,     0x0F    ; r22: Low 4 bits of command byte
	cpi   r25,     CMD_WAIT
	breq  soundpatch_tick_chloop_wait
	brcc  soundpatch_tick_chloop_end
	cpi   r25,     CMD_LOWPRI
	breq  soundpatch_tick_chloop_lowpri
	cpi   r25,     CMD_FREQVIB
	breq  soundpatch_tick_chloop_freqvib
	brcc  soundpatch_tick_chloop_volume
	cpi   r25,     CMD_FREQSWEEP
	breq  soundpatch_tick_chloop_freqsweep
	brcc  soundpatch_tick_chloop_volvib
	cpi   r25,     CMD_WFREQJUMP
	breq  soundpatch_tick_chloop_wfreqjump
	brcc  soundpatch_tick_chloop_volsweep

soundpatch_tick_chloop_wfreq:
soundpatch_tick_chloop_wfreqjump:

	mov   r13,     r24
	movw  r14,     ZL
	call  sound_ll_setwaveform
	mov   r24,     r13
	call  sound_ll_resetsample
	mov   r24,     r13
	movw  ZL,      r14
	lpm   r23,     Z+
	lpm   r22,     Z+     ; r23:r22: Frequency to use
	movw  r14,     ZL
	ldi   r20,     0      ; r20: Volume to use, start with 0
	call  sound_ll_note
	sbrs  r17,     4      ; Set: CMD_WFREQJUMP
	rjmp  soundpatch_tick_chloop_procnext_zl
	movw  ZL,      r14
	lpm   ZL,      Z
	rjmp  soundpatch_tick_chloop_procrecalc

soundpatch_tick_chloop_lowpri:

	andi  r16,     (0xFF ^ CHAN_FLAG_HPRI)

soundpatch_tick_chloop_wait:

	or    r16,     r22
	std   Y + CHAN_FLAGS, r16
	subi  ZL,      lo8(patchdata)
	std   Y + CHAN_POS, ZL
	rjmp  soundpatch_tick_chloop_chdone

soundpatch_tick_chloop_end:

	andi  r16,     (0xFF ^ CHAN_FLAG_RUN)
	std   Y + CHAN_FLAGS, r16
	rjmp  soundpatch_tick_chloop_chdone

soundpatch_tick_chloop_freqvib:

	lpm   r20,     Z+     ; r20: Step size
	movw  r14,     ZL
	call  sound_ll_setfreqvib
	rjmp  soundpatch_tick_chloop_procnext_zl

soundpatch_tick_chloop_volvib:

	lpm   r20,     Z+     ; r20: Step size
	movw  r14,     ZL
	call  sound_ll_setvolvib
	rjmp  soundpatch_tick_chloop_procnext_zl

soundpatch_tick_chloop_volume:

	mov   r20,     r22
	swap  r20
	or    r22,     r20    ; r22: Volume extended to 8 bits
	movw  r14,     ZL
	call  sound_ll_setvolume
	rjmp  soundpatch_tick_chloop_procnext_zl

soundpatch_tick_chloop_freqsweep:

	ldi   r23,     0x80
	sbrc  r22,     3      ; 0x00 - 0x07: Positive (upwards) sweep
	ldi   r23,     0x70
	or    r23,     r22
	lpm   r22,     Z+     ; r22: Low byte of sweep
	movw  r14,     ZL
	call  sound_ll_setfreqsweep
	rjmp  soundpatch_tick_chloop_procnext_zl

soundpatch_tick_chloop_volsweep:

	swap  r22             ; Bits 12-15 of volume sweep
	lpm   r20,     Z+     ; Bits 4-11 of volume sweep
	swap  r20
	mov   r23,     r20
	andi  r23,     0x0F
	or    r23,     r22    ; r23: Volume sweep high
	andi  r20,     0xF0
	mov   r22,     r20    ; r22: Volume sweep low
	movw  r14,     ZL
	call  sound_ll_setvolsweep
soundpatch_tick_chloop_procnext_zl:
	movw  ZL,      r14
	rjmp  soundpatch_tick_chloop_procnext

soundpatch_tick_chloop_chdone:

	adiw  YL,      2
	cpi   YL,      lo8(patch_channels + 6)
	breq  .+2
	rjmp  soundpatch_tick_chloop

	pop   YH
	pop   YL
	pop   r17
	pop   r16
	pop   r15
	pop   r14
	pop   r13
	ret



/**
 * @brief   Plays a sound
 *
 * Channel may be automatically selected. The sound won't play if no channel
 * is available.
 *
 * Inputs:
 * r24:     Channels to consider for playing
 * r22:     The sound to play
 */
.global soundpatch_play
soundpatch_play:

	ldi   ZL,      lo8(patch_channels)
	ldi   ZH,      hi8(patch_channels)
	ldd   r18,     Z + (0 + CHAN_FLAGS)
	ldd   r19,     Z + (2 + CHAN_FLAGS)
	ldd   r20,     Z + (4 + CHAN_FLAGS)
	sbrs  r24,     0
	ori   r18,     CHAN_FLAG_NOPE
	sbrs  r24,     1
	ori   r19,     CHAN_FLAG_NOPE
	sbrs  r24,     2
	ori   r20,     CHAN_FLAG_NOPE

	; First look for a channel which is properly free

	mov   r21,     r18
	andi  r21,     (CHAN_FLAG_RUN | CHAN_FLAG_NOPE | CHAN_FLAG_HPRI)
	breq  soundpatch_play_ch0
	mov   r21,     r19
	andi  r21,     (CHAN_FLAG_RUN | CHAN_FLAG_NOPE | CHAN_FLAG_HPRI)
	breq  soundpatch_play_ch1
	mov   r21,     r20
	andi  r21,     (CHAN_FLAG_RUN | CHAN_FLAG_NOPE | CHAN_FLAG_HPRI)
	breq  soundpatch_play_ch2

	; If no luck, consider low priority channels for taking over

	mov   r21,     r18
	andi  r21,     (CHAN_FLAG_RUN | CHAN_FLAG_NOPE)
	breq  soundpatch_play_ch0
	mov   r21,     r19
	andi  r21,     (CHAN_FLAG_RUN | CHAN_FLAG_NOPE)
	breq  soundpatch_play_ch1
	mov   r21,     r20
	andi  r21,     (CHAN_FLAG_RUN | CHAN_FLAG_NOPE)
	breq  soundpatch_play_ch2

	; Could not get it playing

	ret

soundpatch_play_ch2:
	adiw  ZL,      2
soundpatch_play_ch1:
	adiw  ZL,      2
soundpatch_play_ch0:

	; Start sound on channel

	movw  r18,     ZL
	ldi   ZL,      lo8(patchlist)
	ldi   ZH,      hi8(patchlist)
	eor   r1,      r1
	add   ZL,      r22
	adc   ZH,      r1
	lpm   r22,     Z
	movw  ZL,      r18
	ldi   r24,     (CHAN_FLAG_RUN | CHAN_FLAG_HPRI | CHAN_FLAG_WAIT)
	std   Z + CHAN_POS,   r22
	std   Z + CHAN_FLAGS, r24

	mov   r24,     ZL
	subi  r24,     lo8(patch_channels)
	lsr   r24              ; r24: Channel number 0-3
	ldi   r23,     0xF8
	ldi   r22,     0x00    ; Sweep channel volume quickly down
	jmp   sound_ll_setvolsweep



/**
 * @brief   Play a tune
 *
 * Plays a tune on the given channel (a sequence of sounds with its own
 * timing)
 *
 * @param   chans:  Channel(s) to play on
 * @param   tune:   The tune to play
 */
.global soundpatch_playtune
soundpatch_playtune:

	mov   ZL,      r22
	ldi   ZH,      0
	subi  ZL,      lo8(-(tunelist))
	sbci  ZH,      hi8(-(tunelist))
	lpm   r22,     Z
	sts   tune_offs, r22
	sts   tune_chans, r24
	ldi   r22,     1
	sts   tune_tick, r22
	ret



/**
 * @brief   Silences all channels
 *
 * Drives volumes down to zero in a few frames to silence audio
 */
.global soundpatch_silence
soundpatch_silence:

	ldi   r24,     0       ; Channel
	ldi   r23,     0xFE
	ldi   r22,     0x00    ; Sweep channel volume down
	call  sound_ll_setvolsweep
	ldi   r24,     1       ; Channel
	ldi   r23,     0xFE
	ldi   r22,     0x00    ; Sweep channel volume down
	call  sound_ll_setvolsweep
	ldi   r24,     2       ; Channel
	ldi   r23,     0xFE
	ldi   r22,     0x00    ; Sweep channel volume down
	call  sound_ll_setvolsweep

soundpatch_silence_resetdata:

	ldi   ZL,      lo8(patch_channels)
	ldi   ZH,      hi8(patch_channels)
	eor   r1,      r1
soundpatch_silence_lp:
	st    Z+,      r1
	cpi   ZL,      lo8(patch_channels + 6)
	brne  soundpatch_silence_lp

	ret

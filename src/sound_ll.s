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
; Low Level sound - this interacts closely with the modified VSync mixer of
; the kernel (mixer from soundMixerVsync.s), driving it by writing into its
; channel structures. This is the way the game generates sound, the normal
; Uzebox kernel sound / music engine is not present.
;

.equ MIX_VOL,        0
.equ MIX_STEP_LO,    1
.equ MIX_STEP_HI,    2
.equ MIX_POS_FRAC,   3
.equ MIX_POS,        4
.equ MIX_WAVEFORM,   5

.equ CHANNEL0_MIXER, 0
.equ CHANNEL1_MIXER, 6
.equ CHANNEL2_MIXER, 12

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
.equ CHANNEL1_MEXT,  30
.equ CHANNEL2_MEXT,  42



.equ SOUND_LL_WAVEPTR_SAW,       m72_charrom_data
.equ SOUND_LL_WAVEPTR_NOISE,     m72_charrom_data + 512
.equ SOUND_LL_WAVEPTR_TRIANGLE,  m72_charrom_data + 1024
.equ SOUND_LL_WAVEPTR_SQUARE,    m72_charrom_data + 1536



;
; Internal routine to set up mixer address
;
sound_ll_int_setmixer:
	cpi   r24,     3
	brcs  .+2
	ldi   r24,     0
	ldi   r25,     (CHANNEL1_MIXER - CHANNEL0_MIXER)
	mul   r24,     r25
	movw  ZL,      r0
	subi  ZL,      lo8(-(mixer + CHANNEL0_MIXER))
	sbci  ZH,      hi8(-(mixer + CHANNEL0_MIXER))
	eor   r1,      r1
	ret



;
; Internal routine to set up mixer extended address
;
sound_ll_int_setmixext:
	cpi   r24,     3
	brcs  .+2
	ldi   r24,     0
	ldi   r25,     (CHANNEL1_MEXT - CHANNEL0_MEXT)
	mul   r24,     r25
	movw  ZL,      r0
	subi  ZL,      lo8(-(mixer + CHANNEL0_MEXT))
	sbci  ZH,      hi8(-(mixer + CHANNEL0_MEXT))
	eor   r1,      r1
	ret



/**
 * Outputs note onto channel
 *
 * Does not change other parameters, so if needed, be sure to set waveforms,
 * cancel slides.
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * r23:r22: Frequency value to use, definition from freqs.h
 * r20:     Volume to use, 0 ends the note
 */
.global sound_ll_note
sound_ll_note:
	rcall sound_ll_int_setmixer
	std   Z + MIX_VOL,        r20
	std   Z + MIX_STEP_LO,    r22
	std   Z + MIX_STEP_HI,    r23
	ret


/**
 * @brief   Resets sample position on a channel
 *
 * Resets sample position on a channel, use if starting a note at nonzero
 * volume to avoid clicking.
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 */
.global sound_ll_resetsample
sound_ll_resetsample:
	rcall sound_ll_int_setmixer
	std   Z + MIX_POS_FRAC,   r1
	std   Z + MIX_POS,        r1
	ret



/**
 * Resets effects on a channel
 *
 * Resets sweeps and vibrato to have no effect on the given channel
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 */
.global sound_ll_reseteffects
sound_ll_reseteffects:
	rcall sound_ll_int_setmixext
	std   Z + MEXT_FSWEEP_LO, r1
	std   Z + MEXT_VSWEEP_LO, r1
	std   Z + MEXT_VSWEEP_HI, r1
	std   Z + MEXT_FVIBSTEP,  r1
	std   Z + MEXT_VVIBSTEP,  r1
	std   Z + MEXT_STEP_FLO,  r1
	std   Z + MEXT_STEP_VLO,  r1
	std   Z + MEXT_FVIBPOS,   r1  ; This triangle wave position is 0
	ldi   r24,     0x80
	std   Z + MEXT_FSWEEP_HI, r24
	ldi   r24,     0x40
	std   Z + MEXT_VVIBPOS,   r24 ; This triangle wave position is max (0x7F)
	ldi   r24,     hi8(SOUND_LL_WAVEPTR_TRIANGLE)
	std   Z + MEXT_FVIBWAVE,  r24
	std   Z + MEXT_VVIBWAVE,  r24
	ret



/**
 * @brief   Set channel volume
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * r22:     Volume level to set
 */
.global sound_ll_setvolume
sound_ll_setvolume:
	rcall sound_ll_int_setmixer
	std   Z + MIX_VOL,        r22
	ret



/**
 * @brief   Get current channel volume
 *
 * Can be used for testing whether the channel is silent
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * Outputs:
 * r24:     Current volume level
 */
.global sound_ll_getvolume
sound_ll_getvolume:
	rcall sound_ll_int_setmixer
	ldd   r24,     Z + MIX_VOL
	ret



/**
 * @brief   Set main waveform
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * r22:     Waveform to use
 */
.global sound_ll_setwaveform
sound_ll_setwaveform:
	rcall sound_ll_int_setmixer
	andi  r22,     3
	lsl   r22
	subi  r22,     hi8(-(SOUND_LL_WAVEPTR_SAW))
	std   Z + MIX_WAVEFORM,   r22
	ret



/**
 * @brief   Set frequency sweep
 *
 * A sweep value of 0x8000 is idle, above that, sweeps upwards, below that,
 * downwards.
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * r23:r22: Sweep value
 */
.global sound_ll_setfreqsweep
sound_ll_setfreqsweep:
	rcall sound_ll_int_setmixext
	std   Z + MEXT_FSWEEP_LO, r22
	std   Z + MEXT_FSWEEP_HI, r23
	ret



/**
 * @brief   Set volume sweep
 *
 * A sweep value of 0 is idle, above that, sweeps upwards, while the 2's
 * complement negatives (0x8000 - 0xFFFF) sweep downwards.
 *
 * @param   chan:   Channel to use (0-2)
 * @param   sweep:  Sweep value
 */
.global sound_ll_setvolsweep
sound_ll_setvolsweep:
	rcall sound_ll_int_setmixext
	std   Z + MEXT_VSWEEP_LO, r22
	std   Z + MEXT_VSWEEP_HI, r23
	ret



/**
 * @brief   Set frequency vibrato
 *
 * Note that negative step values can also be achieved by wrapping around
 * (such as 0xFF would be equivalent to -1)
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * r22:     Waveform to use
 * r20:     Step size (there are 8 steps per frame)
 */
.global sound_ll_setfreqvib
sound_ll_setfreqvib:
	rcall sound_ll_int_setmixext
	std   Z + MEXT_FVIBSTEP,  r20
	andi  r22,     3
	lsl   r22
	subi  r22,     hi8(-(SOUND_LL_WAVEPTR_SAW))
	std   Z + MEXT_FVIBWAVE,  r22
	ret



/**
 * @brief   Set volume vibrato
 *
 * Note that negative step values can also be achieved by wrapping around
 * (such as 0xFF would be equivalent to -1)
 *
 * Inputs:
 * r24:     Channel to use (0-2)
 * r22:     Waveform to use
 * r20:     Step size (there are 8 steps per frame)
 */
.global sound_ll_setvolvib
sound_ll_setvolvib:
	rcall sound_ll_int_setmixext
	std   Z + MEXT_VVIBSTEP,  r20
	andi  r22,     3
	lsl   r22
	subi  r22,     hi8(-(SOUND_LL_WAVEPTR_SAW))
	std   Z + MEXT_VVIBWAVE,  r22
	ret

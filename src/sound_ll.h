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


#ifndef SOUND_LL_H
#define SOUND_LL_H


#include <stdint.h>
#include <stdbool.h>
#include "freqs.h"



/** @{ */
/** Available waveforms */
#define SOUND_LL_WAVE_SAW       0U
#define SOUND_LL_WAVE_NOISE     1U
#define SOUND_LL_WAVE_TRIANGLE  2U
#define SOUND_LL_WAVE_SQUARE    3U
/** @} */



/**
 * @brief   Outputs note onto channel
 *
 * Does not change other parameters, so if needed, be sure to set waveforms,
 * cancel slides.
 *
 * @param   chan:   Channel to use (0-2)
 * @param   freqval: Frequency value to use, definition from freqs.h
 * @param   vol:    Volume to use, 0 ends the note
 */
void sound_ll_note(uint8_t chan, uint16_t freqval, uint8_t vol);


/**
 * @brief   Resets sample position on a channel
 *
 * Resets sample position on a channel, use if starting a note at nonzero
 * volume to avoid clicking.
 *
 * @param   chan:   Channel to use (0-2)
 */
void sound_ll_resetsample(uint8_t chan);


/**
 * @brief   Resets effects on a channel
 *
 * Resets sweeps and vibrato to have no effect on the given channel.
 *
 * @param   chan:   Channel to use (0-2)
 */
void sound_ll_reseteffects(uint8_t chan);


/**
 * @brief   Set channel volume
 *
 * @param   chan:   Channel to use (0-2)
 * @param   vol:    Volume to use
 */
void sound_ll_setvolume(uint8_t chan, uint8_t vol);


/**
 * @brief   Get current channel volume
 *
 * Can be used for testing whether the channel is silent
 *
 * @param   chan:   Channel to use (0-2)
 * @return          Current volume level
 */
uint8_t sound_ll_getvolume(uint8_t chan);


/**
 * @brief   Set main waveform
 *
 * @param   chan:   Channel to use (0-2)
 * @param   vform:  Waveform to use
 */
void sound_ll_setwaveform(uint8_t chan, uint8_t vform);


/**
 * @brief   Set frequency sweep
 *
 * A sweep value of 0x8000 is idle, above that, sweeps upwards, below that,
 * downwards.
 *
 * @param   chan:   Channel to use (0-2)
 * @param   sweep:  Sweep value
 */
void sound_ll_setfreqsweep(uint8_t chan, uint16_t sweep);


/**
 * @brief   Set volume sweep
 *
 * A sweep value of 0 is idle, above that, sweeps upwards, while the 2's
 * complement negatives (0x8000 - 0xFFFF) sweep downwards.
 *
 * @param   chan:   Channel to use (0-2)
 * @param   sweep:  Sweep value
 */
void sound_ll_setvolsweep(uint8_t chan, uint16_t sweep);


/**
 * @brief   Set frequency vibrato
 *
 * Note that negative step values can also be achieved by wrapping around
 * (such as 0xFF would be equivalent to -1)
 *
 * @param   chan:   Channel to use (0-2)
 * @param   vform:  Waveform to use
 * @param   step:   Step size (there are 8 steps per frame)
 */
void sound_ll_setfreqvib(uint8_t chan, uint8_t vform, uint8_t step);


/**
 * @brief   Set volume vibrato
 *
 * Note that negative step values can also be achieved by wrapping around
 * (such as 0xFF would be equivalent to -1)
 *
 * @param   chan:   Channel to use (0-2)
 * @param   vform:  Waveform to use
 * @param   step:   Step size (there are 8 steps per frame)
 */
void sound_ll_setvolvib(uint8_t chan, uint8_t vform, uint8_t step);


#endif

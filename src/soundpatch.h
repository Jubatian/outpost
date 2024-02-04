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


#ifndef SOUNDPATCH_H
#define SOUNDPATCH_H


#include <stdint.h>
#include <stdbool.h>



/** @{ */
/** Available sounds */
#define SOUNDPATCH_STEP      0U
#define SOUNDPATCH_SWAP      1U
#define SOUNDPATCH_DIE0      2U
#define SOUNDPATCH_DIE1      3U
#define SOUNDPATCH_CHOMP     4U
#define SOUNDPATCH_CANNON    5U
#define SOUNDPATCH_ARROW0    6U
#define SOUNDPATCH_ARROW1    7U
#define SOUNDPATCH_MATCH     8U
#define SOUNDPATCH_TEST      9U
/** @} */

/** @{ */
/** Audio channels (bits for combining) */
#define SOUNDPATCH_CH_0      1U
#define SOUNDPATCH_CH_1      2U
#define SOUNDPATCH_CH_2      4U
#define SOUNDPATCH_CH_ALL    7U
/** @} */



/**
 * @brief   Initializes audio
 *
 * Makes sure everything is silent and ready to play
 */
void soundpatch_init(void);


/**
 * @brief   Processes a tick
 *
 * Advances playing patches as appropriate, call every frame
 */
void soundpatch_tick(void);


/**
 * @brief   Plays a sound
 *
 * Channel may be automatically selected. The sound won't play if no channel
 * is available.
 *
 * @param   chans:  Channels to consider for playing
 * @param   sound:  The sound to play
 */
void soundpatch_play(uint8_t chans, uint8_t sound);


/**
 * @brief   Silences all channels
 *
 * Drives volumes down to zero in a few frames to silence audio
 */
void soundpatch_silence(void);


#endif

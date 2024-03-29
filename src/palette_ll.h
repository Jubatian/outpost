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


#ifndef PALETTE_LL_H
#define PALETTE_LL_H

#include <stdint.h>



/**
 * @brief   Fade in / out background palette
 *
 * Only fades colours 0 - 14, colour 15 is reserved for border
 *
 * @param   flev:   Fade level, 255: Full intensity, 0: Black
 */
void Palette_LL_Fade(uint_fast8_t flev);


/**
 * @brief   Fade in by internal state
 *
 * Fades by modifying internal state, allowing for continuous fades
 *
 * @param   fladd:  Addition to fade level
 */
void Palette_LL_FadeIn(uint_fast8_t fladd);


/**
 * @brief   Fade out by internal state
 *
 * Fades by modifying internal state, allowing for continuous fades
 *
 * @param   flsub:  Subtraction from fade level
 */
void Palette_LL_FadeOut(uint_fast8_t flsub);


/**
 * @brief   Fade a single colour
 *
 * @param   col:    Colour to fade
 * @param   flev:   Fade level, 255: Full intensity, 0: Black
 * @return          Result colour
 */
uint_fast8_t Palette_LL_FadeColour(uint_fast8_t col, uint_fast8_t flev);


#endif

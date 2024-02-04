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


#ifndef DRAGONLAYOUT_H
#define DRAGONLAYOUT_H


#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Get a dragon layout suitable for the turn
 *
 * Pass it a random number (should be on the small side, below ~20, for this
 * to not take too long), returns a layout ID to use, suitable for the passed
 * turn.
 *
 * @param   roll:   Layout selection roll
 * @param   turn:   Current turn
 * @return          Dragon layout index
 */
uint8_t dragonlayout_getid(uint8_t roll, uint16_t turn);


/**
 * @brief   Get maximum dragon size on the layout
 *
 * @param   lyidx:  Layout index to check
 * @return          Maximum dragon size on the layout (0-3)
 */
uint8_t dragonlayout_getmaxsize(uint8_t lyidx);


/**
 * @brief   Get number of dragons in the layout
 *
 * @param   lyidx:  Layout index to check
 * @return          Number of dragon available in the layout
 */
uint8_t dragonlayout_getcount(uint8_t lyidx);


/**
 * @brief   Get a dragon from the layout
 *
 * Returned dragons are in top to bottom Y order by ID
 *
 * - bits  0- 7: Y position of the dragon, 0xFF if no more available
 * - bits  8-15: Dragon size (0-3), 0xFF if no more available
 *
 * @param   lyidx:  Layout index to use (from dragonlayout_getid())
 * @param   drgid:  Dragon index
 * @return          Combined parameters of dragon
 */
uint16_t dragonlayout_getdragon(uint8_t lyidx, uint8_t drgid);


/**
 * @brief   Get dragon sprite component list
 *
 * Returns dragon sprite component list ID for a given dragon size and frame
 * combination (Frame 0 is idle gliding). The sprite component list then can
 * be used to output the dragon.
 *
 * @param   dsize:  Dragon size (0-3)
 * @param   frame:  Animation frame (0: Idle gliding)
 * @return          Component list ID
 */
uint16_t dragonlayout_getcomplist(uint8_t dsize, uint8_t frame);


/**
 * @brief   Get dragon sprite properties
 *
 * Provides dragon sprite index and placement properties. Iterate through
 * until arriving at the end.
 *
 * - bits  0-15: Y displacement (2's complement)
 * - bits 16-23: X displacement (2's complement)
 * - bits 24-30: Sprite ID (0-126), 0xFF together with X mirror marks end
 * - bit     31: X mirror
 *
 * @param   clist:  Component list ID
 * @param   comp:   Sprite component ID
 */
uint32_t dragonlayout_getcomponent(uint16_t clist, uint8_t comp);


/**
 * @brief   Get dragon colouring by strenght class
 *
 * Return value:
 * - bits  0- 7: Colour 3
 * - bits  8-15: Colour 2
 * - bits 16-23: Colour 1
 *
 * @param   dstr:   Dragon strength class (0-15)
 * @return          Colouring of dragon
 */
uint32_t dragonlayout_getcolours(uint8_t dstr);


#endif

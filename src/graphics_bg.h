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


#ifndef GRAPHICS_BG_H
#define GRAPHICS_BG_H

#include "playfield.h"


/** @{ */
/** Background dimensions in tiles */
#define GRAPHICS_BG_WIDTH    20U
#define GRAPHICS_BG_HEIGHT   25U
/** @} */

/** @{ */
/** Item tiles outside the Playfield */
#define GRAPHICS_BG_FOREST   0x01U
#define GRAPHICS_BG_FOREDGE  0x02U
/** @} */


/**
 * @brief   Get background data pointer
 *
 * The background tileset is 20x25 (for a 160x200 area), ideally this should
 * be read-only, allowing this module to populate it proper (the return is
 * not const to allow for the graphics engine to take it).
 *
 * @return          Pointer to background tiles (500 bytes)
 */
uint8_t* Graphics_BG_GetVRAM(void);


/**
 * @brief   Place an item tile (2x3; 16x24 size)
 *
 * Item tiles are identified by their upper-left corner, the rest are added
 * automatically. Playfield definitions are set up to work with the tileset
 * proper.
 *
 * @param   item:   Item ID to draw
 * @param   xpos:   Background X position
 * @param   ypos:   Background Y position
 */
void Graphics_BG_DrawItem(uint_fast8_t item, uint_fast8_t xpos,  uint_fast8_t ypos);


/**
 * @brief   Draw playfield
 *
 * Draws the playfield and surrounding tiles, this area occupies the upper 21
 * rows. Playfield activities are taken into account displaying appropriate
 * background animations (as far as can be done by tile boundaries).
 */
void Graphics_BG_DrawPlayfield(void);


/**
 * @brief   Get town area
 *
 * Returns pointer to the town area (20 * 4 tiles) for filling in.
 *
 * @return          Pointer to town area (80 bytes)
 */
uint8_t* Graphics_BG_GetTownPtr(void);


#endif

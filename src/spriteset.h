/**
 * @file
 *
 *  Outpost in the dragon's maw
 *  Copyright (C) 2023 Sandor Zsuga (Jubatian)
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


#ifndef SPRITESET_H
#define SPRITESET_H


#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Return sprite data pointer
 *
 * @param   spri:   Sprite index
 * @return          Data pointer of sprite (In program memory)
 */
void* spriteset_getdataptr(uint8_t spri);


/**
 * @brief   Return sprite height
 *
 * @param   spri:   Sprite index
 * @return          Height of sprite
 */
uint8_t spriteset_getheight(uint8_t spri);


#endif

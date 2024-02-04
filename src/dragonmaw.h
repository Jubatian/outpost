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


#ifndef DRAGONMAW_H
#define DRAGONMAW_H


#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Return image data pointer
 *
 * @return          Data pointer of image (In program memory)
 */
void* img_dragonmaw_getdataptr(void);


/**
 * @brief   Return image width
 *
 * @return          Width of image
 */
uint8_t img_dragonmaw_getwidth(void);


/**
 * @brief   Return image height
 *
 * @return          Height of image
 */
uint8_t img_dragonmaw_getheight(void);


/**
 * @brief   Return pixel at given position
 *
 * @param   xpos:   Pixel X position
 * @param   ypos:   Pixel Y position
 * @return          Pixel value (0-3)
 */
uint8_t img_dragonmaw_getpixel(uint8_t xpos, uint8_t ypos);


/**
 * @brief   Return byte at given position
 *
 * @param   xbpos:  Byte X position
 * @param   ypos:   Y position
 * @return          Byte value
 */
uint8_t img_dragonmaw_getbyte(uint8_t xbpos, uint8_t ypos);


#endif

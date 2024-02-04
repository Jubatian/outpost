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


#ifndef SPRITECANVAS_H
#define SPRITECANVAS_H


#include <stdint.h>



/**
 * @brief   Places pixel on a sprite canvas
 *
 * The sprite canvas is a set of sprites placed side by side, this function
 * allows for using such construct (16 pixels wide 2bpp sprites) as a canvas.
 *
 * @param   data:   Canvas data pointer (leftmost sprite's top)
 * @param   xpos:   Pixel X position
 * @param   ypos:   Pixel Y position
 * @param   col:    Pixel colour (0 - 3)
 * @param   chgt:   Canvas height
 */
void spritecanvas_putpixel(uint8_t* data, uint8_t xpos, uint8_t ypos, uint8_t col, uint8_t chgt);


/**
 * @brief   Clears sprite canvas
 *
 * @param   data:   Canvas data pointer (leftmost sprite's top)
 * @param   cwdt:   Canvas width in count of 16px wide sprites
 * @param   chgt:   Canvas height
 */
void spritecanvas_clear(uint8_t* data, uint8_t cwdt, uint8_t chgt);


/**
 * @brief   Places downscaled image on canvas
 *
 * The result image combines onto the existing one (canvas should normally be
 * cleared before call), with higher pixel values taking precedence. This is
 * to improve details in downscaled images assuming colour 3 holds the most
 * important elements (works well with lineart style).
 *
 * Note on scaling fractions: Although 1 can not be given, in the practice it
 * is possible as the fractions begin with 255, not 0 (so using 255 will give
 * the desired result of no scaling effectively).
 *
 * @param   data:   Canvas data pointer (leftmost sprite's top)
 * @param   src:    Source ROM image pointer
 * @param   srchw:  Height (bits 8-15) and Width (bits 0-7) of source
 * @param   dstyx:  Destination Y (bits 8-15) and X (bits 0-7) positions
 * @param   scale:  Scaling fraction Y (bits 8-15) and X (bits 0-7)
 * @param   chgt:   Canvas height
 */
void spritecanvas_drawscaled(uint8_t* data, uint8_t const* src,
    uint16_t srchw, uint16_t dstyx, uint16_t scale, uint8_t chgt);


/**
 * @brief   Mirrors sprite around its middle pixel
 *
 * The resulting data is 15 pixels wide with the last pixel empty.
 *
 * @param   data:   Sprite data pointer
 * @param   shgt:   Sprite height
 */
void spritecanvas_mirror15px(uint8_t* data, uint8_t shgt);


#endif

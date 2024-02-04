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


#ifndef SPRITE_LL_H
#define SPRITE_LL_H


#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>


/** Sprite flag: X Mirrored */
#define SPRITE_LL_FLAG_XFLIP  1U
/** Sprite flag: In RAM */
#define SPRITE_LL_FLAG_RAM    2U

/** Size of a sprite in bytes for allocations */
#define SPRITE_LL_SPR_SIZE    10U
/** Size of a bullet in bytes for allocations */
#define SPRITE_LL_BUL_SIZE    4U


/**
 * @brief   Initializes or re-initializes sprites
 *
 * Clears all sprite lists to be empty, after this no sprites or bullets would
 * display until adding some. The horizontal maximum sprite count affects
 * available bullets (5: 1 bullet, 4: 4 bullets, 3: 7 bullets). The passed
 * buffer is used for the sprite lists, the bigger it is, more sprites are
 * available. Mode 72's internal sprite structure is 10 bytes in size. Same
 * for bullets, where an entry is 4 bytes.
 *
 * @param   hcount: Horizontal max sprites
 * @param   sprbuf: Sprite buffer to use
 * @param   sprlen: Sprite buffer size in bytes
 * @param   bulbuf: Bullet buffer to use
 * @param   bullen: Bullet buffer size in bytes
 */
void Sprite_LL_Init(uint_fast8_t hcount,
    void* sprbuf, uint_fast16_t sprlen,
    void* bulbuf, uint_fast16_t bullen);


/**
 * @brief   Resets sprites
 *
 * Clears all sprite lists to be empty, after this no sprites or bullets would
 * display until adding some.
 */
void Sprite_LL_Reset(void);


/**
 * @brief   Adds a sprite for display
 *
 * Adds only if it appears that it can be displayed (that is, other sprites
 * on the same scanline wouldn't interfere).
 *
 * Note that back-to-back sprite multiplexing is not possible (at least 1
 * empty row has to be left between sprites, so back-to-back sprites will
 * necessarily be sorted into different columns!). Use sprite height to work
 * around this (sprites can be arbitrarily tall).
 *
 * Interface note: Uses function parameters (despite having a bit too many of
 * them) as this is more efficient on the AVR-8 than having a structure filled
 * and passed.
 *
 * @param   xpos:   Sprite X position (16: Left edge)
 * @param   ypos:   Sprite Y position (32: Top edge)
 * @param   height: Sprite height
 * @param   col1:   Colour of '1' pixels
 * @param   col2:   Colour of '2' pixels
 * @param   col3:   Colour of '3' pixels
 * @param   data:   Sprite data pointer (can be either ROM or RAM)
 * @param   flags:  Flags (See SPRITE_LL_FLAG_xxx)
 * @return          True if the sprite would display OK
 */
bool Sprite_LL_Add(uint_fast8_t xpos, uint_fast8_t ypos,
    uint_fast8_t height,
    uint_fast8_t col1, uint_fast8_t col2, uint_fast8_t col3,
    uint8_t const* data, uint_fast8_t flags);


/**
 * @brief   Adds a bullet for display
 *
 * Adds only if it appears that it can be displayed (that is, other bullets
 * on the same scanline wouldn't interfere).
 *
 * @param   xpos:   Bullet X position (16: Left edge)
 * @param   ypos:   Bullet Y position (32: Top edge)
 * @param   width:  Bullet width (1-4 pixels)
 * @param   height: Bullet height
 * @param   col:    Bullet colour
 * @return          True if the bullet would display OK
 */
bool Sprite_LL_AddBullet(uint_fast8_t xpos, uint_fast8_t ypos,
    uint_fast8_t width, uint_fast8_t height, uint_fast8_t col);


#endif

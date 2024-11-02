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


#ifndef GRSPRITE_H
#define GRSPRITE_H

#include <stdint.h>
#include <stdbool.h>


/** Types of sprite arrangements available for the game */
typedef enum{
 GRSPRITE_ARR_SWAP,
 GRSPRITE_ARR_WAVE
}grsprite_arrangement_tdef;

/** Types of cursors available */
typedef enum{
 GRSPRITE_CURSOR_HOVER,
 GRSPRITE_CURSOR_SELECT,
 GRSPRITE_CURSOR_DELETE,
 GRSPRITE_CURSOR_ANYSWAP,
}grsprite_cursor_tdef;



/**
 * @brief   Setup sprites
 *
 * Sets up sprites for given usage. When allocating pools from the passed
 * buffer, sprites have priority over bullets (what's left of the buffer goes
 * to bullets).
 *
 * @param   arrtyp: Arrangement type
 * @param   buf:    RAM buffer for sprites & bullets
 * @param   len:    RAM buffer lenght in bytes
 * @param   sprcnt: Preferred sprite count (rest will be bullets)
 */
void GrSprite_Init(grsprite_arrangement_tdef arrtyp,
    void* buf, uint_fast16_t len,
    uint_fast8_t sprcnt);


/**
 * @brief   Change sprite arrangement
 *
 * @param   arrtyp: Arrangement type
 * @param   sprcnt: Preferred sprite count (rest will be bullets)
 */
void GrSprite_ChangeArrangement(grsprite_arrangement_tdef arrtyp,
    uint_fast8_t sprcnt);


/**
 * @brief   Reset (clears) sprites
 */
void GrSprite_Reset(void);


/**
 * @brief   Add a cursor at playfield position
 *
 * The cursor frame ranges from 0-255 providing animation or progression
 *
 * @param   ctyp:   Cursor type
 * @param   frame:  Cursor frame
 * @param   xpos:   Playfield X position
 * @param   ypos:   Playfield Y position
 */
void GrSprite_Cursor(grsprite_cursor_tdef ctyp, uint_fast8_t frame,
    uint_fast8_t xpos, uint_fast8_t ypos);


/**
 * @brief   Add all dragons of the currently ongoing wave
 */
void GrSprite_AddDragons(void);


/**
 * @brief   Add dragon attack indicators for the coming wave
 *
 * @param   maxcnt: Maximum number of indicators to add (ordered by strenght)
 */
void GrSprite_AddDragonIndicators(uint_fast8_t maxcnt);


/**
 * @brief   Add all bullets currently active
 */
void GrSprite_AddBullets(void);


#endif

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


#ifndef PLAYFIELD_H
#define PLAYFIELD_H

#include <stdint.h>
#include <stdbool.h>


/** @{ */
/** Playfield dimensions. Playfield row (y) 0 is the row from where items
 *  slide in, not an active playable row. */
#define PLAYFIELD_WIDTH     6U
#define PLAYFIELD_HEIGHT    7U
/** @} */

/** @{ */
/** Items on the playfield - resource and corresponding levels are adjacent.
 *  Layout is to allow for separating item type and level by masks while also
 *  reserving 30 slots for an item type to align with graphics tiles (5 levels
 *  starting with the bare resource, 6 graphics tile makes an item) */
#define PLAYFIELD_EMPTY     0x00U
#define PLAYFIELD_GOLD      0x20U
#define PLAYFIELD_ROCK      0x80U
#define PLAYFIELD_TOWER1    0x81U
#define PLAYFIELD_TOWER2    0x82U
#define PLAYFIELD_TOWER3    0x83U
#define PLAYFIELD_TOWER4    0x84U
#define PLAYFIELD_WOOD      0xA0U
#define PLAYFIELD_ARROW1    0xA1U
#define PLAYFIELD_ARROW2    0xA2U
#define PLAYFIELD_ARROW3    0xA3U
#define PLAYFIELD_ARROW4    0xA4U
#define PLAYFIELD_IRON      0xC0U
#define PLAYFIELD_CANNON1   0xC1U
#define PLAYFIELD_CANNON2   0xC2U
#define PLAYFIELD_CANNON3   0xC3U
#define PLAYFIELD_CANNON4   0xC4U
#define PLAYFIELD_FRUIT     0xE0U
#define PLAYFIELD_SUPPLY1   0xE1U
#define PLAYFIELD_SUPPLY2   0xE2U
#define PLAYFIELD_SUPPLY3   0xE3U
#define PLAYFIELD_SUPPLY4   0xE4U
/** @} */

/** @{ */
/** Activity types. The MDEL activity is for matching tiles which get erased,
 *  while MATCH is for where the higher level tile would appear. The two SWAPs
 *  allow for distinguishing first and second parameters (for above / below
 *  display when drawing) */
#define PLAYFIELD_ACT_IDLE  0U
#define PLAYFIELD_ACT_FALL  1U
#define PLAYFIELD_ACT_SWAP1 2U
#define PLAYFIELD_ACT_SWAP2 3U
#define PLAYFIELD_ACT_MDEL  4U
#define PLAYFIELD_ACT_MATCH 5U
/** @} */


/** Playfield activity report structure */
typedef struct{
 bool     active;   /**< True if the playfield is still changing */
 bool     match;    /**< True if a match occurred in this tick */
 uint8_t  gold;     /**< Gold generated in this tick if any */
}playfield_activity_tdef;


/**
 * @brief   Reset playfield
 *
 * Resets the playfield populating it with an initial set of resources. The
 * resources might form combinations.
 */
void Playfield_Reset(void);

/**
 * @brief   Process a playfield tick
 *
 * @param   report: Report structure filled in
 */
void Playfield_Tick(playfield_activity_tdef* report);

/**
 * @brief   Swap two items
 *
 * Can swap any two items here (normally it is adjacent items swapped). The
 * action triggers possible matches, which can be processed in subsequent
 * ticks. Out of bounds items are ignored (no swap). Playfield row 0 (ypos
 * zero) is out of bounds as it is to provide new items sliding in.
 *
 * @param   xpos1:  X position of item 1
 * @param   ypos1:  Y position of item 1
 * @param   xpos2:  X position of item 2
 * @param   ypos2:  Y position of item 2
 * @return          True if a swap is initiated (both items are valid)
 */
bool Playfield_Swap(
    uint_fast8_t xpos1, uint_fast8_t ypos1,
    uint_fast8_t xpos2, uint_fast8_t ypos2);

/**
 * @brief   Delete an item
 *
 * Deletes an item causing those above to slide into its place.
 *
 * @param   xpos:   X position of item
 * @param   ypos:   Y position of item
 * @return          True if a deletion is initiated (item is valid)
 */
bool Playfield_Delete(uint_fast8_t xpos, uint_fast8_t ypos);

/**
 * @brief   Get current item at location
 *
 * @param   xpos:   X position of item
 * @param   ypos:   Y position of item
 * @return          Item ID
 */
uint_fast8_t Playfield_GetItem(uint_fast8_t xpos, uint_fast8_t ypos);

/**
 * @brief   Get item's activity at location
 *
 * @param   xpos:   X position of item
 * @param   ypos:   Y position of item
 * @return          Activity type the item is undergoing
 */
uint_fast8_t Playfield_GetActivity(uint_fast8_t xpos, uint_fast8_t ypos);

/**
 * @brief   Get activity tick
 *
 * This counter counts between 0 and 255 as the activity progresses ahead.
 *
 * @param   xpos:   X position of item
 * @param   ypos:   Y position of item
 * @return          Activity tick counter
 */
uint_fast8_t Playfield_GetTick(uint_fast8_t xpos, uint_fast8_t ypos);

/**
 * @brief   Get target X position
 *
 * This is the target of a MOVE action
 *
 * @param   xpos:   X position of item
 * @param   ypos:   Y position of item
 * @return          Target X position
 */
uint_fast8_t Playfield_GetTargetX(uint_fast8_t xpos, uint_fast8_t ypos);

/**
 * @brief   Get target Y position
 *
 * This is the target of a MOVE action
 *
 * @param   xpos:   X position of item
 * @param   ypos:   Y position of item
 * @return          Target Y position
 */
uint_fast8_t Playfield_GetTargetY(uint_fast8_t xpos, uint_fast8_t ypos);


#endif

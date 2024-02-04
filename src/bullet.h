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


#ifndef BULLET_H
#define BULLET_H


#include <stdint.h>
#include <stdbool.h>



/** Bullet types */
typedef enum{
 BULLET_TOWER,
 BULLET_ARROW,
 BULLET_CANNON,
 BULLET_FRAG
}bullet_type_tdef;

/** Launch return types */
typedef enum{
 BULLET_LAUNCH_OK,
 BULLET_LAUNCH_NOTARGET,
 BULLET_LAUNCH_FULL
}bullet_launch_tdef;

/** Bullet properties */
typedef struct{
 uint8_t xpos; /** Bullet X position (playfield relative) */
 uint8_t ypos; /** Bullet Y position (playfield relative) */
 uint8_t dir;  /** Bullet's travel direction, 0: Up, clockwise */
 bullet_type_tdef btype; /** Bullet type */
}bullet_params_tdef;



/**
 * @brief   Returns item size for this component
 *
 * @return         Item size in bytes
 */
uint_fast8_t Bullet_ItemSize(void);


/**
 * @brief   Initializes work buffer for bullets
 *
 * Pass it a buffer and item count to use for bullets. This buffer is used
 * only when the module is active.
 *
 * @param   buf:    RAM buffer to put bullet structures in
 * @param   bcount: Maximum count of bullets
 */
void Bullet_Init(void* buf, uint_fast8_t bcount);


/**
 * @brief   Resets bullets
 */
void Bullet_Reset(void);


/**
 * @brief   Process a bullet activity tick
 */
void Bullet_Tick(void);


/**
 * @brief   Launch a bullet
 *
 * A suitable target is attempted to be selected automatically for it, returns
 * accordingly. Returns BULLET_LAUNCH_FULL if there are too many bullets in
 * play already (suggestion: this case accumulate damage for a later bullet).
 *
 * Note that the BULLET_FRAG type is for cannon splash fragments, which are
 * generated automatically where needed.
 *
 * @param   xpos:   Playfield X location (0 - 5)
 * @param   ypos:   Playfield Y location (1 - 6)
 * @param   btype:  Bullet type (BULLET_FRAG can not be used)
 * @param   dmg:    Damage
 * @return          Launch status
 */
bullet_launch_tdef Bullet_Launch(uint_fast8_t xpos, uint_fast8_t ypos,
    bullet_type_tdef btype, uint_fast16_t dmg);


/**
 * @brief   Get current active bullet count
 *
 * @return          Current count of active bullets
 */
uint_fast8_t Bullet_GetCount(void);


/**
 * @brief   Get bullet parameters
 *
 * @param   id:     Bullet ID to get parameters for
 * @param   bpars:  Parameters filled in
 */
void Bullet_GetParams(uint_fast8_t id, bullet_params_tdef* bpars);


#endif

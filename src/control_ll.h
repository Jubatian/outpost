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


#ifndef CONTROL_LL_H
#define CONTROL_LL_H


#include <stdint.h>
#include <stdbool.h>


/** @{ */
/** Control definitions used by the game */
#define CONTROL_LL_UP         0x10U
#define CONTROL_LL_DOWN       0x20U
#define CONTROL_LL_LEFT       0x40U
#define CONTROL_LL_RIGHT      0x80U
#define CONTROL_LL_MENU       0x04U
#define CONTROL_LL_ACTION     0x01U
#define CONTROL_LL_ALTERN     0x02U
/** @} */

/** Mask for all controls */
#define CONTROL_LL_ALL        0xFFU


/**
 * @brief   Check controller activity
 *
 * Check if any control was triggered since last checked. Triggers are cleared
 * as requested, allowing to delay action if needed so.
 *
 * @param   cmask:  Clear mask, use CONTROL_LL_ALL for all
 * @return          Control activity
 */
uint_fast8_t Control_LL_Get(uint_fast8_t cmask);


/**
 * @brief   Check control hold
 *
 * Note: Call after Control_LL_Get as that one fetches controller data
 *
 * @return          Contol holds (set if held)
 */
uint_fast8_t Control_LL_GetHolds(void);


#endif

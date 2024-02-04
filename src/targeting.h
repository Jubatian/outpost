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


#ifndef TARGETING_H
#define TARGETING_H


#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Returns buffer size needed for this component
 *
 * @return         Buffer size in bytes
 */
uint_fast16_t Targeting_Size(void);


/**
 * @brief   Initializes work buffer for targeting
 *
 * Pass it a buffer to use for targeting. This buffer is used only when the
 * module is active.
 *
 * @param   buf:    RAM buffer to put targeting data in
 */
void Targeting_Init(void* buf);


/**
 * @brief   Resets targeting
 */
void Targeting_Reset(void);


/**
 * @brief   Process a targeting tick
 */
void Targeting_Tick(void);


#endif

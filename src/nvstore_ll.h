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


#ifndef NVSTORE_LL_H
#define NVSTORE_LL_H


#include <stdint.h>
#include <stdbool.h>


/** Nonvolatile storage size in bytes */
#define NVSTORE_LL_SIZE  30U


/**
 * @brief   Read nonvolatile storage (blocking)
 *
 * @param   data:   Data buffer to fill up. Not altered if no data
 * @return          If data was loaded, true, false if there is no data
 */
bool NVStore_LL_Read(uint8_t* data);


/**
 * @brief   Write nonvolatile storage (blocking)
 *
 * @param   data:   Data to write out, must be at least NVSTORE_LL_SIZE long
 * @return          If success writing out, true
 */
bool NVStore_LL_Write(uint8_t const* data);


#endif

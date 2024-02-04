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


#ifndef MEMSETUP_H
#define MEMSETUP_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>


/** Memory arrangement setups */
typedef enum{
 MEMSETUP_GAMESWAP,
 MEMSETUP_GAMEWAVE,
 MEMSETUP_MENU
}memsetup_arrangement_tdef;



/**
 * @brief   Setup memory allocation
 *
 * Sets memory and resource allocation for a given usage
 *
 * @param   arrtyp: Arrangement type
 */
void MemSetup(memsetup_arrangement_tdef arrtyp);


/**
 * @brief   Get work area pointer
 *
 * Some arrangements provide a work area, if not, the return is NULL
 */
uint8_t* MemSetup_GetWorkArea(void);


#endif

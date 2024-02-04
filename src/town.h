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


#ifndef TOWN_H
#define TOWN_H

#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Clears town
 */
void Town_Reset(void);


/**
 * @brief   Sets town population
 *
 * The town is adjusted to fit, if population is added, adding houses,
 * expanding the boundary, if removed, leaving rubble behind (when population
 * is added later again, the rubble is rebuilt).
 *
 * @param   pop:    Population to set
 */
void Town_SetPop(uint_fast16_t pop);


#endif

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


#ifndef HISCORE_H
#define HISCORE_H


#include <stdint.h>
#include <stdbool.h>


/** Maximum name string lenght (characters) for a score entry */
#define HISCORE_NAME_MAX  10U

/** Number of entries in the high score table */
#define HISCORE_TABLE_SIZE  3U


/**
 * @brief   Check if score is eligible for the high score table
 *
 * @param   months: Months survived
 * @param   pop:    Total population (all eaten by dragons now)
 */
bool HiScore_IsEligible(uint_fast8_t months, uint_fast16_t pop);


/**
 * @brief   Send new entry to high score table
 *
 * The name string can be zero-terminated, but reading it would cut off at
 * HISCORE_NAME_MAX if longer. The entry is ignored if it isn't eligible.
 *
 * @param   name:   Name string, can be zero terminated early.
 * @param   months: Months survived
 * @param   pop:    Total population (all eaten by dragons now)
 */
void HiScore_Send(uint8_t const* name, uint_fast8_t months, uint_fast16_t pop);


/**
 * @brief   Request high score elements
 *
 * If the entry doesn't exist, returns blank (spaces for name, zero for score
 * elements).
 *
 * @param   rank:   Which entry to query, begins at 0 for 1st place.
 * @param   name:   Returns the name, space padded to HISCORE_NAME_MAX
 * @param   months: Returns the months survived
 * @param   pop:    Returns the total population
 */
void HiScore_Get(
    uint_fast8_t rank, uint8_t* name, uint_fast8_t* months, uint_fast16_t* pop);


#endif

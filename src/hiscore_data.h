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


#ifndef HISCORE_DATA_H
#define HISCORE_DATA_H


#include <stdint.h>
#include <stdbool.h>


/** ASCII character to raw high score data */
#define HISCORE_ASCII2RAW(asciichar) (\
 ((asciichar) == ' ') ? 0U : \
 (((asciichar) >= 'a') && ((asciichar) <= 'z')) ? (1U + ((asciichar) - 'a')) : \
 (((asciichar) >= 'A') && ((asciichar) <= 'Z')) ? (27U + ((asciichar) - 'A')) : \
 (((asciichar) >= '0') && ((asciichar) <= '9')) ? (53U + ((asciichar) - '0')) : \
 ((asciichar) == '-') ? 63U : \
 63U)


/**
 * @brief   Fill in default high score data
 *
 * @param   dest:   Destination to fill with the data (3x HISCORE_NAME_MAX)
 */
void HiScore_Data_Fill(uint8_t* dest);


/**
 * @brief   Fill in default name
 *
 * @param   dest:   Destination raw name to fill in (HISCORE_NAME_MAX bytes)
 */
void HiScore_Data_FillName(uint8_t* dest);


#endif

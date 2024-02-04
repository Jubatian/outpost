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


#ifndef GRTEXT_LL_H
#define GRTEXT_LL_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>



/**
 * @brief   Setup text mode
 *
 * Sets up as many text rows as fits in the passed buffer (40 bytes per row)
 *
 * @param   buf:    RAM buffer for text rows
 * @param   len:    RAM buffer lenght in bytes
 * @param   defcol: Default boundary colour when no text row is displaying
 */
void GrText_LL_Init(void* buf, uint_fast16_t len, uint_fast8_t defcol);


/**
 * @brief   Set text area parameters
 *
 * @param   lines:  Number of lines visible (truncated to available text rows)
 * @param   ontop:  On the top if true, on the bottom if false
 * @param   bndcol: Boundary line colour
 * @param   bgcol:  Background colour
 * @param   fgcol:  Foreground colour
 */
void GrText_LL_SetParams(uint_fast8_t lines, bool ontop,
    uint_fast8_t bndcol, uint_fast8_t bgcol, uint_fast8_t fgcol);


/**
 * @brief   Get maximum height of text area in lines
 *
 * This includes all padding
 *
 * @return          Maximum number of lines the text area may occupy
 */
uint_fast8_t GrText_LL_GetMaxLines(void);


/**
 * @brief   Get text row pointer
 *
 * Returns pointer to given text row (NULL if row doesn't exist)
 *
 * @param   row:    Row to return pointer for (40 bytes)
 * @return          Pointer to row data or NULL if row doesn't exit
 */
uint8_t* GrText_LL_GetRowPtr(uint_fast8_t row);


#endif

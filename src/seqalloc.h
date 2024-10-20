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


#ifndef SEQALLOC_H
#define SEQALLOC_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>


/**
 * @brief   Reset memory allocator
 *
 * Frees all memory to allow for starting anew.
 */
void SeqAlloc_Reset(void);


/**
 * @brief   Allocate memory
 *
 * Allocates the requested amount of memory. This memory is available until
 * the next Reset of this module. If there is not enough memory, halts.
 *
 * @param   count:  Number of bytes to allocate
 */
void* SeqAlloc(uint_fast16_t count);


/**
 * @brief   Query free heap
 *
 * @return          Bytes free
 */
uint_fast16_t SeqAlloc_CountFreeBytes(void);


#endif

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


#include "seqalloc.h"


/** Size of available memory to allocate */
#define SEQALLOC_HEAPSIZE  2048U


/** Memory available to be allocated */
static uint8_t seqalloc_heap[SEQALLOC_HEAPSIZE];

/** Current end of allocated memory */
static uint_fast16_t seqalloc_end = 0U;



void SeqAlloc_Reset(void)
{
 seqalloc_end = 0U;
}



void* SeqAlloc(uint_fast16_t count)
{
 uint_fast16_t newend = seqalloc_end + count;
 if ((newend > SEQALLOC_HEAPSIZE) || (newend < seqalloc_end)){
  while (true); /* Out of memory, get stuck here */
 }
 void* allocatedmem = &seqalloc_heap[seqalloc_end];
 seqalloc_end = newend;
 return allocatedmem;
}



uint_fast16_t SeqAlloc_CountFreeBytes(void)
{
 return (SEQALLOC_HEAPSIZE - seqalloc_end);
}

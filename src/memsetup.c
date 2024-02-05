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


#include "memsetup.h"
#include "grsprite.h"
#include "grtext_ll.h"
#include "dragonwave.h"
#include "bullet.h"
#include "targeting.h"


/** Size of memory pool */
#define MEMSETUP_POOLSIZE  2048U


/** Memory pool available for various usages */
static uint8_t memsetup_pool[MEMSETUP_POOLSIZE];

/** Work area pointer */
static uint8_t* memsetup_workarea;



void MemSetup(memsetup_arrangement_tdef arrtyp)
{
 uint_fast16_t dpos = 0U;
 grsprite_arrangement_tdef sprarr;

 switch (arrtyp){
  case MEMSETUP_GAMEWAVE:
  case MEMSETUP_GAMESWAP:
   sprarr = GRSPRITE_ARR_WAVE;
   if (arrtyp == MEMSETUP_GAMESWAP){
    sprarr = GRSPRITE_ARR_SWAP;
   }
   GrText_LL_Init(&memsetup_pool[dpos], 40U, 0U);
   dpos += 40U;
   DragonWave_Init(&memsetup_pool[dpos]);
   dpos += DragonWave_Size();
   Bullet_Init(&memsetup_pool[dpos], 80U);
   dpos += Bullet_ItemSize() * 80U;
   Targeting_Init(&memsetup_pool[dpos]);
   dpos += Targeting_Size();
   GrSprite_Init(sprarr, &memsetup_pool[dpos], MEMSETUP_POOLSIZE - dpos, 32U);
   memsetup_workarea = NULL;
   break;
  case MEMSETUP_MENU:
   GrText_LL_Init(&memsetup_pool[dpos], 160U, 0U);
   dpos += 160U;
   memsetup_workarea = &memsetup_pool[dpos];
   break;
  case MEMSETUP_TITLE:
   GrText_LL_Init(&memsetup_pool[dpos], 1000U, 0U);
   dpos += 1000U;
   memsetup_workarea = &memsetup_pool[dpos];
   break;
  default:
   break;
 }
}



uint8_t* MemSetup_GetWorkArea(void)
{
 return memsetup_workarea;
}

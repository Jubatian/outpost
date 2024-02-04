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


#include "town.h"
#include "graphics_bg.h"
#include "random.h"



/** How much population a house would contain */
#define TOWN_HOUSE_POP   5U



/** Last set population, to shortcut when there is no change */
static uint_fast16_t town_lastpop;



/**
 * @brief   Generate a column of grass
 *
 * @param   tiles:  Tile data to operate on
 * @param   column: Column address
 */
static void Town_GenGrass(uint8_t* tiles, uint_fast8_t column)
{
 uint_fast8_t rnd = random_get();
 tiles[column + (GRAPHICS_BG_WIDTH * 1U)] = 0x42U;
 tiles[column + (GRAPHICS_BG_WIDTH * 2U)] = (rnd & 1U) + 0x40U;
 rnd >>= 1;
 tiles[column + (GRAPHICS_BG_WIDTH * 3U)] = (rnd & 1U) + 0x40U;
}



/**
 * @brief   Generate a column
 *
 * @param   tiles:  Tile data to operate on
 * @param   column: Column address
 * @param   tid:    Tile ID to fill with
 */
static void Town_GenColumn(uint8_t* tiles, uint_fast8_t column, uint_fast8_t tid)
{
 tiles[column + (GRAPHICS_BG_WIDTH * 1U)] = tid;
 tiles[column + (GRAPHICS_BG_WIDTH * 2U)] = tid;
 tiles[column + (GRAPHICS_BG_WIDTH * 3U)] = tid;
}



/**
 * @brief   Expand town boundaries
 */
static void Town_ExpandBounds(void)
{
 uint8_t* tiles = Graphics_BG_GetTownPtr();

 uint_fast8_t lwall = 0U;
 uint_fast8_t rwall = 0U;

 while (lwall < GRAPHICS_BG_WIDTH){
  if (tiles[lwall] == 0x49U){ /* Left corner piece - existing wall */
   break;
  }
  lwall ++;
 }

 while (rwall < GRAPHICS_BG_WIDTH){
  if (tiles[rwall] == 0x4EU){ /* Right corner piece - existing wall */
   break;
  }
  rwall ++;
 }

 if (lwall < GRAPHICS_BG_WIDTH){
  tiles[lwall + 1U] = 0x4CU;
  tiles[lwall] = 0x4BU;
  Town_GenGrass(tiles, lwall);
  if (lwall > 0U){
   lwall --;
   tiles[lwall] = 0x4AU;
   Town_GenGrass(tiles, lwall);
   if (lwall > 0U){
    lwall --;
    tiles[lwall] = 0x49U;
    Town_GenColumn(tiles, lwall, 0x48U);
   }
  }
 }

 if (rwall < GRAPHICS_BG_WIDTH){
  tiles[rwall - 1U] = 0x4BU;
  tiles[rwall] = 0x4CU;
  Town_GenGrass(tiles, rwall);
  if (rwall < (GRAPHICS_BG_WIDTH - 1U)){
   rwall ++;
   tiles[rwall] = 0x4DU;
   Town_GenGrass(tiles, rwall);
   if (rwall < (GRAPHICS_BG_WIDTH - 1U)){
    rwall ++;
    tiles[rwall] = 0x4EU;
    Town_GenColumn(tiles, rwall, 0x4FU);
   }
  }
 }
}



/**
 * @brief   Attempt to randomly place a house
 *
 * @return          True if success doing so
 */
bool Town_PlaceHouse(void)
{
 uint8_t* tiles = Graphics_BG_GetTownPtr();

 /* Randomly select a house type to place */

 uint_fast8_t htid = random_get() & 3U;
 if (htid == 3U){
  htid = 0x54U; /* Horizontal big house */
 }else{
  htid = 0x50U + htid; /* Small houses and Vertical big house */
 }

 /* Set horizontal bounds (the current walls) */

 uint_fast8_t lbound = GRAPHICS_BG_WIDTH;
 uint_fast8_t rbound = 0U;

 while (lbound > 0U){
  if (tiles[lbound - 1U] == 0x49U){ /* Left corner piece - existing wall */
   break;
  }
  lbound --;
 }

 while (rbound < GRAPHICS_BG_WIDTH){
  if (tiles[rbound] == 0x4EU){ /* Right corner piece - existing wall */
   break;
  }
  rbound ++;
 }

 /* Count free spaces permitting a house on */

 uint_fast8_t xpos = lbound;
 uint_fast8_t ypos = 1U;
 uint_fast8_t freecnt = 0U;

 while (ypos < 4U){
  if ((tiles[xpos + (GRAPHICS_BG_WIDTH * ypos)] & 0xF8U) == 0x40U){
   freecnt ++; /* Grass: Free tile */
  }
  xpos ++;
  if (xpos >= rbound){
   xpos = lbound;
   ypos ++;
  }
 }

 if (freecnt < 2U){
  return false; /* Too dense, abort */
 }

 /* Attempt placing a house */

 uint_fast8_t tries = 3U;
 uint_fast8_t mask = 0x1FU;
 if (freecnt < 4U){
  mask = 0x07U; /* Save on some scans if getting dense */
 }

 while (tries != 0U){
  tries --;
  uint_fast8_t rnd = (random_get() & mask) + 1U;
  xpos = lbound;
  ypos = 1U;
  while (true){
   if ((tiles[xpos + (GRAPHICS_BG_WIDTH * ypos)] & 0xF8U) == 0x40U){
    rnd --;
    if (rnd == 0U){
     break; /* Use this tile */
    }
   }
   xpos ++;
   if (xpos >= rbound){
    xpos = lbound;
    ypos ++;
    if (ypos >= 4U){
     ypos = 1U;
    }
   }
  }

  /* Try to actually put the house here - does it fit? */

  uint_fast8_t tid1;
  uint_fast8_t tid2;
  uint_fast8_t tid3;
  bool         fit;
  switch (htid){

   case 0x50U:
   case 0x51U:
    tiles[xpos + (GRAPHICS_BG_WIDTH * ypos)] = htid;
    return true; /* Small houses fit on a single tile */

   case 0x52U:
   case 0x53U: /* Big vertical house */
    tid1 = tiles[xpos + (GRAPHICS_BG_WIDTH * 1U)] & 0x1FU;
    tid2 = tiles[xpos + (GRAPHICS_BG_WIDTH * 2U)] & 0x1FU;
    tid3 = tiles[xpos + (GRAPHICS_BG_WIDTH * 3U)] & 0x1FU;
    fit = true;
    if ((ypos == 1U) || (ypos == 3U)){
     if ((tid2 >= 0x12U) && (tid2 <= 0x15U)){ /* Blocked by big house */
      fit = false;
     }else{
      if (ypos == 3U){
       ypos = 2U;
      }
     }
    }else{ /* ypos == 2U */
     if ((tid3 < 0x12U) || (tid3 > 0x15U)){ /* Good fit as-is */
     }else{
      if ((tid1 < 0x12U) || (tid1 > 0x15U)){
       ypos = 1U;
      }else{
       fit = false;
      }
     }
    }
    if (fit){
     tiles[xpos + (GRAPHICS_BG_WIDTH * (ypos + 1U))] = 0x52U;
     tiles[xpos + (GRAPHICS_BG_WIDTH * (ypos     ))] = 0x53U;
     return true; /* Large vertical house placed */
    }
    break;

   case 0x54U:
   case 0x55U: /* Big horizontal house */
    if ((xpos > 0U) && (xpos < (GRAPHICS_BG_WIDTH - 1U))){
     tid1 = tiles[(xpos - 1U) + (GRAPHICS_BG_WIDTH * ypos)] & 0x1FU;
     tid3 = tiles[(xpos + 1U) + (GRAPHICS_BG_WIDTH * ypos)] & 0x1FU;
     fit = true;
     if (((tid3 >= 0x12U) && (tid3 <= 0x15U)) || ((tid3 & 0x18U) == 0x08U)){
      if (((tid1 >= 0x12U) && (tid1 <= 0x15U)) || ((tid1 & 0x18U) == 0x08U)){
       /* Big house parts or the wall (0x48 - 0x4F) blocking */
       fit = false;
      }else{
       xpos --;
      }
     }
    }
    if (fit){
     tiles[(xpos + 0U) + (GRAPHICS_BG_WIDTH * ypos)] = 0x54U;
     tiles[(xpos + 1U) + (GRAPHICS_BG_WIDTH * ypos)] = 0x55U;
     return true; /* Large horizontal house placed */
    }
    break;

   default:
    return false; /* Called with invalid house tile ID */
  }
 }

 return false; /* Out of attempts for placing house */
}



void Town_Reset(void)
{
 uint8_t* tiles = Graphics_BG_GetTownPtr();

 /* Add field */

 for (uint_fast8_t xpos = 0U; xpos < GRAPHICS_BG_WIDTH; xpos ++){
  tiles[xpos] = 0x42U; /* Grass with path on top */
  uint_fast8_t rnd = random_get();
  tiles[xpos + (GRAPHICS_BG_WIDTH * 1U)] = (rnd & 1U) + 0x40U;
  rnd >>= 1;
  tiles[xpos + (GRAPHICS_BG_WIDTH * 2U)] = (rnd & 1U) + 0x40U;
  rnd >>= 1;
  tiles[xpos + (GRAPHICS_BG_WIDTH * 3U)] = (rnd & 1U) + 0x40U;
 }

 /* Add initial boundaries (walls) */

 uint_fast8_t lwall = ((GRAPHICS_BG_WIDTH / 2U) - 3U);
 uint_fast8_t rwall = ((GRAPHICS_BG_WIDTH / 2U) + 2U);
 for (uint_fast8_t xpos = lwall; xpos <= rwall; xpos ++){
  tiles[xpos] = 0x49U + (xpos - lwall); /* Top walls */
  Town_GenGrass(tiles, xpos);
 }
 Town_GenColumn(tiles, lwall, 0x48U);
 Town_GenColumn(tiles, rwall, 0x4FU);

 town_lastpop = 0U;
}



void Town_SetPop(uint_fast16_t pop)
{
 if (town_lastpop == pop){
  return; /* No need to do anything */
 }
 town_lastpop = pop;

 uint8_t* tiles = Graphics_BG_GetTownPtr();
 uint8_t* titer;

 /* Count intact houses for current population capacity */

 uint_fast8_t hcount = 0U;
 titer = &(tiles[GRAPHICS_BG_WIDTH]);
 for (uint_fast8_t ypos = 1U; ypos < 4U; ypos ++){
  for (uint_fast8_t xpos = 0U; xpos < GRAPHICS_BG_WIDTH; xpos ++){
   if (((*titer) & 0xF0U) == 0x50U){
    hcount ++; /* Tiles 0x50 - 0x5F are intact houses */
   }
   titer ++;
  }
 }

 /* If everyone is housed, if population is too low, ruin a house, otherwise
 ** done and return. */

 uint_fast16_t hspace = (uint_fast16_t)(hcount) * TOWN_HOUSE_POP;
 if (pop <= hspace){

  if ((pop + (TOWN_HOUSE_POP * 2U)) <= hspace){
   uint_fast8_t rnd = (random_get() & 0x3FU) + 1U;
   uint_fast8_t ypos = 1U;
   uint_fast8_t xpos = 0U;
   titer = &(tiles[GRAPHICS_BG_WIDTH]);
   while (true){
    uint_fast8_t tid = *titer;
    if ((tid & 0xF0U) == 0x50U){
     rnd --;
     if (rnd == 0U){
      break; /* Ruin this house */
     }
    }
    titer ++;
    xpos ++;
    if (xpos >= GRAPHICS_BG_WIDTH){
     xpos = 0U;
     ypos ++;
     if (ypos >= 4U){
      ypos = 1U;
      titer = &(tiles[GRAPHICS_BG_WIDTH]);
     }
    }
   }
   uint_fast8_t tid = tiles[(ypos * GRAPHICS_BG_WIDTH) + xpos];
   switch (tid){
    case 0x52U:
     tiles[((ypos - 1U) * GRAPHICS_BG_WIDTH) + xpos] += 0x20U;
     break;
    case 0x53U:
     tiles[((ypos + 1U) * GRAPHICS_BG_WIDTH) + xpos] += 0x20U;
     break;
    case 0x54U:
     tiles[(ypos * GRAPHICS_BG_WIDTH) + (xpos + 1U)] += 0x20U;
     break;
    case 0x55U:
     tiles[(ypos * GRAPHICS_BG_WIDTH) + (xpos - 1U)] += 0x20U;
     break;
    default:
     break;
   }
   tiles[(ypos * GRAPHICS_BG_WIDTH) + xpos] = tid + 0x20U;
  }

  return;
 }

 /* Need new housing. See if some ruins can be restored (if any) */

 titer = &(tiles[GRAPHICS_BG_WIDTH]);
 for (uint_fast8_t ypos = 1U; ypos < 4U; ypos ++){
  for (uint_fast8_t xpos = 0U; xpos < GRAPHICS_BG_WIDTH; xpos ++){
   uint_fast8_t tid = *titer;
   if ((tid & 0xF0U) == 0x70U){
    /* Tiles 0x70 - 0x7F are ruined houses. Hacky solution to restore bigger
    ** ones, going with the assumption multi-tile ones were set up
    ** correctly. */
    switch (tid){
     case 0x72U:
      tiles[((ypos - 1U) * GRAPHICS_BG_WIDTH) + xpos] -= 0x20U;
      break;
     case 0x73U:
      tiles[((ypos + 1U) * GRAPHICS_BG_WIDTH) + xpos] -= 0x20U;
      break;
     case 0x74U:
      tiles[(ypos * GRAPHICS_BG_WIDTH) + (xpos + 1U)] -= 0x20U;
      break;
     case 0x75U:
      tiles[(ypos * GRAPHICS_BG_WIDTH) + (xpos - 1U)] -= 0x20U;
      break;
     default:
      break;
    }
    *titer = tid - 0x20U;
    /* House restored, so done here */
    return;
   }
   titer ++;
  }
 }

 /* If reached here, a new house needs to be placed somewhere */

 if (!(Town_PlaceHouse())){
  Town_ExpandBounds();
  Town_PlaceHouse();
 }
}

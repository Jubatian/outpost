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


#include "playfield.h"
#include "random.h"



/** Match temporary flag used (and cleared up) during processing */
#define PLAYFIELD_FLAG_MATCH 0x80U


/** Playfield items */
static uint8_t playfield_items[PLAYFIELD_HEIGHT][PLAYFIELD_WIDTH];
/** Actions and ticks */
static uint8_t playfield_acts[PLAYFIELD_HEIGHT][PLAYFIELD_WIDTH];
/** Target coords. Also used for match counting for PLAYFIELD_ACT_MATCH. */
static uint8_t playfield_targets[PLAYFIELD_HEIGHT][PLAYFIELD_WIDTH];

/** Combo gold counter (to count combos while active) */
static uint_fast8_t playfield_combo;



/**
 * @brief   Generate random starter item at position
 *
 * @param   xpos:   Target X position
 * @param   ypos:   Target Y position
 */
static void Playfield_GenItem(uint_fast8_t xpos, uint_fast8_t ypos)
{
 uint_fast8_t ritem = random_get() & 0xFFU;
 while (ritem >= 125U){ ritem -= 125U; }
 while (ritem >=  25U){ ritem -=  25U; }
 while (ritem >=   5U){ ritem -=   5U; }
 switch (ritem){
  case 4U: ritem = PLAYFIELD_FRUIT; break;
  case 3U: ritem = PLAYFIELD_IRON;  break;
  case 2U: ritem = PLAYFIELD_WOOD;  break;
  case 1U: ritem = PLAYFIELD_ROCK;  break;
  default: ritem = PLAYFIELD_GOLD;  break;
 }
 playfield_items[ypos][xpos] = ritem;
 playfield_acts [ypos][xpos] = PLAYFIELD_ACT_IDLE << 4;
}



void Playfield_Reset(void)
{
 /* Start with empty playfield which would cause a gradual fill-up from the
 ** top: Easier (no need for special case to initiate match search) and also
 ** generates visual feedback starting the game, the field populating */
 for (uint_fast8_t ypos = 0U; ypos < PLAYFIELD_HEIGHT; ypos ++){
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   playfield_items[ypos][xpos] = PLAYFIELD_EMPTY;
   playfield_acts [ypos][xpos] = PLAYFIELD_ACT_IDLE << 4;
  }
 }
#ifdef STRESSTEST
 /* Stress testing setup, approximates the maximum damage output and activity
 ** in normal gameplay (assuming ~6 of each tower adjacent to a market is
 ** achieved) */
 for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
  playfield_items[6U][xpos] = PLAYFIELD_CANNON4;
  playfield_items[5U][xpos] = PLAYFIELD_SUPPLY4;
  playfield_items[4U][xpos] = PLAYFIELD_ARROW4;
  playfield_items[3U][xpos] = PLAYFIELD_TOWER4;
  playfield_items[2U][xpos] = PLAYFIELD_SUPPLY4;
 }
#endif
 playfield_combo = 0U;
}



/**
 * @brief   Match check item
 *
 * @param   item:   item to check against
 * @param   xpos:   X position of item to check
 * @param   ypos:   Y position of item to check
 * @return          true if matching
 */
static bool Playfield_IsMatch(uint_fast8_t item, uint_fast8_t xpos, uint_fast8_t ypos)
{
  return ( (playfield_items[ypos][xpos] == item) &&
           ( (playfield_acts[ypos][xpos] & (~PLAYFIELD_FLAG_MATCH)) ==
             (PLAYFIELD_ACT_IDLE << 4) ) );
}



void Playfield_Tick(playfield_activity_tdef* report)
{
 bool         active = false;
 bool         match  = false;
 uint_fast8_t gold   = 0U;
 uint_fast8_t ypos;

 /* First pass: Advance ticks where applicable, completing moves as needed.
 ** These generate temporary markers (FLAG_MATCH into acts) for triggering
 ** matches. Completing matches however happen here with the corresponding
 ** game logic levelling up and counting in gold. */

 ypos = PLAYFIELD_HEIGHT;
 while (ypos > 0U){
  ypos --;
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   uint_fast8_t acts = playfield_acts[ypos][xpos] & (~PLAYFIELD_FLAG_MATCH);
   uint_fast8_t tick;
   tick = acts & 0xFU;
   acts >>= 4;
   if (acts != PLAYFIELD_ACT_IDLE){
    active = true;
    tick = (tick + 1U) & 0xFU;
    if (tick == 0U){
     if ( (acts == PLAYFIELD_ACT_FALL) ||
          (acts == PLAYFIELD_ACT_SWAP1) ||
          (acts == PLAYFIELD_ACT_SWAP2) ){
      /* Fall or swap - moving item */
      uint_fast8_t tgx = playfield_targets[ypos][xpos];
      uint_fast8_t tgy = tgx >> 4;
      tgx &= 0xFU;
      uint_fast8_t tgi = playfield_items[tgy][tgx];
      playfield_items[tgy][tgx] = playfield_items[ypos][xpos];
      playfield_acts [tgy][tgx] = PLAYFIELD_FLAG_MATCH | (PLAYFIELD_ACT_IDLE << 4);
      if (acts != PLAYFIELD_ACT_FALL){
       playfield_items[ypos][xpos] = tgi;
       playfield_acts [ypos][xpos] = PLAYFIELD_FLAG_MATCH | (PLAYFIELD_ACT_IDLE << 4);
      }else{
       /* Fall: Becomes empty in this iteration, next row going upwards would
       ** most likely fill this in */
       playfield_items[ypos][xpos] = PLAYFIELD_EMPTY;
       playfield_acts [ypos][xpos] = PLAYFIELD_ACT_IDLE << 4;
      }
     }else if (acts == PLAYFIELD_ACT_MDEL){
      /* A match is completing, mark it off for deletion */
      playfield_items[ypos][xpos] = PLAYFIELD_EMPTY;
      playfield_acts [ypos][xpos] = PLAYFIELD_ACT_IDLE << 4;
     }else if (acts == PLAYFIELD_ACT_MATCH){
      /* A match is completing, higher level tile (except for Gold where this
      ** is just used for counting) appears here. Assume only matchable tiles
      ** arrive here. Relies on the numeric arrangement of item definitions.
      ** Note that the newly levelled up tile might trigger a chain! */
      uint_fast8_t item = playfield_items[ypos][xpos];
      uint_fast8_t ilev = item & 7U;
      uint_fast8_t count = playfield_targets[ypos][xpos];
      if (item == PLAYFIELD_GOLD){
       playfield_items[ypos][xpos] = PLAYFIELD_EMPTY;
       gold += count * 2U;
       count -= 3U;
      }else if (ilev >= 4U){
       count = 0U;
      }else if ((count < 5U) || (ilev >= 3U)){
       playfield_items[ypos][xpos] = item + 1U;
       count -= 3U;
      }else{
       playfield_items[ypos][xpos] = item + 2U;
       count -= 3U; /* Not -5: Full gold bonus on big matches */
      }
      playfield_acts[ypos][xpos] = PLAYFIELD_FLAG_MATCH | (PLAYFIELD_ACT_IDLE << 4);
      for (uint_fast8_t gcnt = 0U; gcnt < count; gcnt ++){
       gold += (gcnt + 1U) * (ilev + 1U);
      }
      gold += playfield_combo;
      playfield_combo += 3U;
     }
    }else{
     playfield_acts[ypos][xpos] = (acts << 4) + tick;
    }
   }
  }
 }

 /* Second pass: Add top row items ready to move in if necessary (Note that in
 ** the first pass, top row slots may turn empty if the item fell off) */

 for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
  if (playfield_items[0U][xpos] == PLAYFIELD_EMPTY){
   Playfield_GenItem(xpos, 0U);
  }
 }

 /* Third pass: Get items falling wherever possible, overriding matching (fall
 ** has higher priority than matches) */

 ypos = PLAYFIELD_HEIGHT;
 while (ypos > 1U){
  ypos --;
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   bool empty = (playfield_items[ypos][xpos] == PLAYFIELD_EMPTY);
   if (!empty){
    empty = ((playfield_acts[ypos][xpos] >> 4) == PLAYFIELD_ACT_FALL);
   }
   if (empty){
    if (playfield_items[ypos - 1U][xpos] != PLAYFIELD_EMPTY){
     uint_fast8_t acts = playfield_acts[ypos - 1U][xpos];
     acts &= ~PLAYFIELD_FLAG_MATCH;
     if ((acts >> 4) == PLAYFIELD_ACT_IDLE){
      active = true;
      playfield_acts[ypos - 1U][xpos] = PLAYFIELD_ACT_FALL << 4;
      playfield_targets[ypos - 1U][xpos] = (ypos << 4) | xpos;
     }
    }
   }
  }
 }

 /* Fourth pass: Completed moves got flagged (PLAYFIELD_FLAG_MATCH) which need
 ** to be investigated for matching patterns. On all of these it is sufficient
 ** to scan a cross around the item to see whether there are 3 or more lining
 ** up horizontally or vertically. */

 for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
  if (playfield_acts[0U][xpos] == PLAYFIELD_FLAG_MATCH){
   playfield_acts[0U][xpos] = PLAYFIELD_ACT_IDLE << 4;
  }
 }
 ypos = PLAYFIELD_HEIGHT;
 while (ypos > 1U){
  ypos --;
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   if (playfield_acts[ypos][xpos] == PLAYFIELD_FLAG_MATCH){
    playfield_acts[ypos][xpos] = PLAYFIELD_ACT_IDLE << 4;
    uint_fast8_t item = playfield_items[ypos][xpos];
    uint_fast8_t ilev = item & 7U;
    if ((item != PLAYFIELD_EMPTY) && (ilev < 4U)){ /* Suitable to match */
     uint_fast8_t xlen = 1U;
     uint_fast8_t ylen = 1U;
     uint_fast8_t xchk;
     uint_fast8_t ychk;
     /* Count horizontal matching tiles */
     xchk = xpos;
     while (xchk > 0U){
      xchk --;
      if (Playfield_IsMatch(item, xchk, ypos)){
       xlen ++;
      }else{
       break;
      }
     }
     xchk = xpos;
     while (xchk < (PLAYFIELD_WIDTH - 1U)){
      xchk ++;
      if (Playfield_IsMatch(item, xchk, ypos)){
       xlen ++;
      }else{
       break;
      }
     }
     /* Count vertical matching tiles */
     ychk = ypos;
     while (ychk > 1U){
      ychk --;
      if (Playfield_IsMatch(item, xpos, ychk)){
       ylen ++;
      }else{
       break;
      }
     }
     ychk = ypos;
     while (ychk < (PLAYFIELD_HEIGHT - 1U)){
      ychk ++;
      if (Playfield_IsMatch(item, xpos, ychk)){
       ylen ++;
      }else{
       break;
      }
     }
     if (xlen < 3U){ xlen = 1U; }
     if (ylen < 3U){ ylen = 1U; }
     if (xlen >= 3U){
      /* Horizontally there are 3 or more matching tiles - mark extras */
      xchk = xpos;
      while (xchk > 0U){
       xchk --;
       if (Playfield_IsMatch(item, xchk, ypos)){
        playfield_acts[ypos][xchk] = PLAYFIELD_ACT_MDEL << 4;
       }else{
        break;
       }
      }
      xchk = xpos;
      while (xchk < (PLAYFIELD_WIDTH - 1U)){
       xchk ++;
       if (Playfield_IsMatch(item, xchk, ypos)){
        playfield_acts[ypos][xchk] = PLAYFIELD_ACT_MDEL << 4;
       }else{
        break;
       }
      }
     }
     if (ylen >= 3U){
      /* Vertically there are 3 or more matching tiles - mark extras */
      ychk = ypos;
      while (ychk > 1U){
       ychk --;
       if (Playfield_IsMatch(item, xpos, ychk)){
        playfield_acts[ychk][xpos] = PLAYFIELD_ACT_MDEL << 4;
       }else{
        break;
       }
      }
      ychk = ypos;
      while (ychk < (PLAYFIELD_HEIGHT - 1U)){
       ychk ++;
       if (Playfield_IsMatch(item, xpos, ychk)){
        playfield_acts[ychk][xpos] = PLAYFIELD_ACT_MDEL << 4;
       }else{
        break;
       }
      }
     }
     if ((xlen >= 3U) || (ylen >= 3U)){
      /* There was a match */
      playfield_acts[ypos][xpos] = PLAYFIELD_ACT_MATCH << 4;
      playfield_targets[ypos][xpos] = (xlen + ylen) - 1U;
      match = true;
     }
    }
   }
  }
 }

 /* Clear combo counter if activity ended */

 if (!active){
  playfield_combo = 0U;
 }

 /* Done this tick, generate report */

 report->active = active;
 report->match  = match;
 report->gold   = gold;
}



bool Playfield_Swap(
    uint_fast8_t xpos1, uint_fast8_t ypos1,
    uint_fast8_t xpos2, uint_fast8_t ypos2)
{
 if ((xpos1 >= PLAYFIELD_WIDTH) || (ypos1 >= PLAYFIELD_HEIGHT) || (ypos1 == 0U)){
  return false;
 }
 if ((xpos2 >= PLAYFIELD_WIDTH) || (ypos2 >= PLAYFIELD_HEIGHT) || (ypos2 == 0U)){
  return false;
 }
 if (playfield_items[ypos1][xpos1] == PLAYFIELD_EMPTY){
  return false;
 }
 if (playfield_items[ypos2][xpos2] == PLAYFIELD_EMPTY){
  return false;
 }
 playfield_acts[ypos1][xpos1] = PLAYFIELD_ACT_SWAP1 << 4;
 playfield_acts[ypos2][xpos2] = PLAYFIELD_ACT_SWAP2 << 4;
 playfield_targets[ypos1][xpos1] = (ypos2 << 4) | xpos2;
 playfield_targets[ypos2][xpos2] = (ypos1 << 4) | xpos1;
 return true;
}



bool Playfield_Delete(uint_fast8_t xpos, uint_fast8_t ypos)
{
 if ((xpos >= PLAYFIELD_WIDTH) || (ypos >= PLAYFIELD_HEIGHT) || (ypos == 0U)){
  return false;
 }
 if (playfield_items[ypos][xpos] == PLAYFIELD_EMPTY){
  return false;
 }
 playfield_items[ypos][xpos] = PLAYFIELD_EMPTY;
 playfield_acts[ypos][xpos] = PLAYFIELD_ACT_IDLE << 4;
 return true;
}



uint_fast8_t Playfield_GetItem(uint_fast8_t xpos, uint_fast8_t ypos)
{
 if ((xpos >= PLAYFIELD_WIDTH) || (ypos >= PLAYFIELD_HEIGHT)){
  return PLAYFIELD_EMPTY;
 }
 return playfield_items[ypos][xpos];
}



uint_fast8_t Playfield_GetActivity(uint_fast8_t xpos, uint_fast8_t ypos)
{
 if ((xpos >= PLAYFIELD_WIDTH) || (ypos >= PLAYFIELD_HEIGHT)){
  return PLAYFIELD_ACT_IDLE;
 }
 return (playfield_acts[ypos][xpos] >> 4);
}



uint_fast8_t Playfield_GetTick(uint_fast8_t xpos, uint_fast8_t ypos)
{
 if ((xpos >= PLAYFIELD_WIDTH) || (ypos >= PLAYFIELD_HEIGHT)){
  return 0U;
 }
 return (playfield_acts[ypos][xpos] & 0xFU) * 0x11U;
}



uint_fast8_t Playfield_GetTargetX(uint_fast8_t xpos, uint_fast8_t ypos)
{
 if ((xpos >= PLAYFIELD_WIDTH) || (ypos >= PLAYFIELD_HEIGHT)){
  return 0U;
 }
 return (playfield_targets[ypos][xpos] & 0xFU);
}



uint_fast8_t Playfield_GetTargetY(uint_fast8_t xpos, uint_fast8_t ypos)
{
 if ((xpos >= PLAYFIELD_WIDTH) || (ypos >= PLAYFIELD_HEIGHT)){
  return 0U;
 }
 return (playfield_targets[ypos][xpos] >> 4);
}

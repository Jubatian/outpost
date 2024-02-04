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



#include "dragonwave.h"
#include "dragonlayout.h"
#include "random.h"
#include "soundpatch.h"



/** Internal dragon structure to track one */
typedef struct{
 uint16_t curhp;   /**< Current health, could be zero if dying */
 uint16_t maxhp;   /**< Maximum (initial) health */
 uint16_t ypos;    /**< Vertical position, 2's complement */
 uint8_t  xpos;    /**< Horizontal position */
 uint8_t  dsizstr; /**< Dragon size (0-3 low nybble) and strength (0-15 high nybble) */
 uint8_t  flyfr;   /**< Flight frame, 0: glide, 1-255: wing cycle */
 uint8_t  diefr;   /**< Death frame, 0: OK, 1-255 dying */
}dragonwave_drgi_tdef;


/** Dragon structures */
dragonwave_drgi_tdef* dragonwave_dragons;

/** Count of dragons currently active (up to DRAGONWAVE_MAX_DRAGONS) */
uint_fast8_t          dragonwave_dcount;

/** Dragon travel speed divider */
uint_fast8_t          dragonwave_speeddiv;



/**
 * @brief   Copy a dragon structure
 *
 * @param   dest:   Destination
 * @param   src:    Source
 */
static void DragonWave_Copy(dragonwave_drgi_tdef* dest, dragonwave_drgi_tdef const* src)
{
 dest->curhp   = src->curhp;
 dest->maxhp   = src->maxhp;
 dest->ypos    = src->ypos;
 dest->xpos    = src->xpos;
 dest->dsizstr = src->dsizstr;
 dest->flyfr   = src->flyfr;
 dest->diefr   = src->diefr;
}



/**
 * @brief   Get health from dragon size and strength
 *
 * @param   dsizstr: Dragon size and strength (Same as field in structure)
 * @return          Max health points the dragon should have
 */
static uint_fast16_t DragonWave_GetMaxHealth(uint_fast8_t dsizstr)
{
 uint_fast8_t dstr = ((dsizstr >> 4) & 0xFU) + 1U;
 switch (dsizstr & 3U){
  case 0U: return (uint_fast16_t)(dstr) * 8U;
  case 1U: return (uint_fast16_t)(dstr) * 48U;
  case 2U: return (uint_fast16_t)(dstr) * 320U;
  default: return (uint_fast16_t)(dstr) * 2048U;
 }
}



/**
 * @brief   Delete a dragon from the list of active dragons
 *
 * @param   drgid:  Dragon ID to delete
 */
static void DragonWave_Delete(uint_fast8_t drgid)
{
 if (drgid >= dragonwave_dcount){
  return;
 }
 for (uint_fast8_t cpid = drgid + 1U; cpid < dragonwave_dcount; cpid ++){
  DragonWave_Copy(&dragonwave_dragons[cpid - 1U], &dragonwave_dragons[cpid]);
 }
 dragonwave_dcount --;
}



/**
 * @brief   Generate an X position
 *
 * Produces a random X position with an aim to exclude the previous X position
 * (avoid putting dragons atop each other), and organizing them into visible
 * columns with a little variety. Range is 0-95 (one tile is 16 pixels wide).
 *
 * @param   pxpos1: Previous X position 1
 * @param   pxpos2: Previous X position 2
 * @return          New X position
 */
static uint_fast8_t DragonWave_GenXPos(uint_fast8_t pxpos1, uint_fast8_t pxpos2)
{
 uint_fast8_t rnd = random_get();
 uint_fast8_t nxpos = rnd & 0x1FU;
 if       (nxpos >= 24U){
  nxpos += 24U;
 }else if (nxpos >= 16U){
  nxpos += 16U;
 }else if (nxpos >= 8U){
  nxpos += 8U;
 }else{
 }
 nxpos += 4U;
 if (pxpos1 > pxpos2){
  uint_fast8_t tmp = pxpos2;
  pxpos2 = pxpos1;
  pxpos1 = tmp;
 }
 if ((nxpos >> 4) >= (pxpos1 >> 4)){
  nxpos += 16U;
 }
 if ((nxpos >> 4) >= (pxpos2 >> 4)){
  nxpos += 16U;
 }
 return nxpos;
}



/**
 * @brief   Return current sum of dragon health
 *
 * @return          Combined health of all dragons
 */
static uint_fast32_t DragonWave_GetSummedHp(void)
{
 uint_fast32_t hpsum = 0U;
 for (uint_fast8_t drgid = 0U; drgid < dragonwave_dcount; drgid ++){
  hpsum += dragonwave_dragons[drgid].curhp;
 }
 return hpsum;
}



uint_fast16_t DragonWave_Size(void)
{
 return (sizeof(dragonwave_drgi_tdef)) * DRAGONWAVE_MAX_DRAGONS;
}



void DragonWave_Init(void* buf)
{
 dragonwave_dragons = buf;
 dragonwave_dcount = 0U;
 dragonwave_speeddiv = 0U;
}



/**
 * @brief   Randomly boost dragons keeping below target HP
 *
 * @param   targethp: Target to keep below
 * @param   minsiz: Minimum dragon size to boost
 */
static void DragonWave_Boost(uint_fast32_t targethp, uint_fast8_t minsiz)
{
 uint_fast32_t hpsum = DragonWave_GetSummedHp();
 for (uint_fast8_t drgid = 0U; drgid < dragonwave_dcount; drgid ++){
  uint_fast8_t dsiz = dragonwave_dragons[drgid].dsizstr;
  uint_fast8_t dstr = dsiz >> 4;
  dsiz &= 3U;
  if (dsiz >= minsiz){
   uint_fast8_t newdstr = dstr + (random_get() & 0x07U);
   if (newdstr > 15U){
    newdstr = 15U;
   }
   if (newdstr > dstr){
    uint_fast8_t dsizstr = dsiz + (newdstr << 4);
    uint_fast16_t newhp = DragonWave_GetMaxHealth(dsizstr);
    uint_fast16_t curhp = dragonwave_dragons[drgid].curhp;
    uint_fast32_t newsum = (hpsum - curhp) + newhp;
    if (newsum <= targethp){
     hpsum = newsum;
     dragonwave_dragons[drgid].curhp = newhp;
     dragonwave_dragons[drgid].maxhp = newhp;
     dragonwave_dragons[drgid].dsizstr = dsizstr;
    }
   }
  }
 }
}



void DragonWave_Setup(uint_fast16_t turn)
{
 /* Dragon layout to use */
 uint_fast8_t lyidx = dragonlayout_getid(random_get() & 0x1FU, turn);

 /* Target health point total for the dragons composing the wave. Results in
 ** a minimum of 8 for turn 0, which is one small dragon. */
 uint_fast32_t turnhp = ((turn * 10U) >> 2) + 3U;
 if (turn >= 24U){
  /* Crank the pressure up somewhat at the 2nd year */
  turnhp = ((turn * 11U) >> 2) - 3U;
 }
 uint_fast32_t targethp = turnhp * turnhp;

 /* Begin with populating the table, picking up all dragons at minimum health
 ** for their size. Add only enough dragons to stay below the target
 ** (filtering out both big dragons and ensuring approaching the target from
 ** below). Also count largest dragons, one of those will need to be kept */
 uint_fast8_t lylen = dragonlayout_getcount(lyidx);
 uint_fast8_t pxpos = DragonWave_GenXPos(40U, 56U);
 uint_fast8_t cxpos = DragonWave_GenXPos(pxpos, 40U);
 uint_fast8_t dpos = 0U;
 uint_fast16_t hpacc = 0U;
 uint_fast8_t largestdcount = 0U;
 uint_fast8_t largestdsiz = 0U;
 for (uint_fast8_t drgid = 0U; drgid < lylen; drgid ++){
  uint_fast16_t dpars = dragonlayout_getdragon(lyidx, drgid);
  uint_fast16_t ypos = dpars & 0xFFU;
  uint_fast8_t  dsiz = (dpars >> 8) & 0x03U;
  uint_fast16_t hp = DragonWave_GetMaxHealth(dsiz);
  uint_fast16_t testhp = hpacc + hp;
  if (testhp <= targethp){
   hpacc = testhp;
   uint_fast8_t tmpxpos = cxpos;
   cxpos = DragonWave_GenXPos(cxpos, pxpos);
   pxpos = tmpxpos;
   dragonwave_drgi_tdef* dragon = &(dragonwave_dragons[dpos]);
   dragon->curhp = hp;
   dragon->maxhp = hp;
   dragon->ypos = (ypos - 256U) & 0xFFFFU;
   dragon->xpos = cxpos;
   dragon->dsizstr = dsiz;
   dragon->flyfr = 0U;
   dragon->diefr = 0U;
   if (largestdsiz < dsiz){
    largestdsiz = dsiz;
    largestdcount = 0U;
   }
   if (largestdsiz == dsiz){
    largestdcount ++;
   }
   dpos ++;
  }
 }
 dragonwave_dcount = dpos;
 if (dpos == 0U){
  /* Should not happen normally (only if target hp is set too low for early
  ** waves, or a poorly made dragon wave missing small dragons). Just bail
  ** out, in terms of game, the wave will just go amiss with no dragons
  ** coming */
  return;
 }

 /* Boost dragons randomly, keeping below the target (two passes for a
 ** chance to get some high HP dragons) */
 DragonWave_Boost(targethp, 0U);
 DragonWave_Boost(targethp, 0U);

 /* Drop some dragons, but only such which wouldn't get the HP sum down too
 ** much (to avoid tossing bigger dragons of the wave, which could then make
 ** it impossible to get the remaining HP up to target). Keep one of the
 ** largest dragons in any case. */
 uint_fast8_t curid = 0U;
 uint_fast8_t dropcnt = dragonwave_dcount * 2U;
 uint_fast32_t maxdrop = targethp >> 2;
 if (maxdrop < 48U){
  maxdrop = 48U; /* To allow tossing small dragons in early waves */
 }
 uint_fast32_t hpsum = DragonWave_GetSummedHp();

 while (dropcnt != 0U){
  uint_fast8_t rmask = 0x03U;
  uint_fast32_t maxcomp = targethp - maxdrop;
  if (hpsum < maxcomp){ rmask = 0x0FU; }
  maxcomp -= maxdrop;
  if (hpsum < maxcomp){ rmask = 0x3FU; }
  maxcomp -= maxdrop;
  if (hpsum < maxcomp){ break; }
  if ((random_get() & rmask) == 0U){
   uint_fast16_t curhp = dragonwave_dragons[curid].curhp;
   uint_fast8_t dsiz = dragonwave_dragons[curid].dsizstr & 3U;
   if (curhp < maxdrop){
    if ((dsiz != largestdsiz) || (largestdcount > 1U)){
     if (dsiz == largestdsiz){
      largestdcount --;
     }
     DragonWave_Delete(curid);
     hpsum -= curhp;
    }
   }
  }
  curid += 5U;
  uint_fast8_t dcount = dragonwave_dcount;
  while (curid > dcount){
   curid -= dcount;
  }
  dropcnt --;
 }

 /* Boost dragons randomly, keeping below the target. Multiple iterations to
 ** get them approaching closer to the target. */
 for (uint_fast8_t smin = largestdsiz; smin > 0U; smin --){
  DragonWave_Boost(targethp, smin);
 }
 DragonWave_Boost(targethp, 0U);
 DragonWave_Boost(targethp, 0U);

 /* Push dragons down if they are too far from Y = 0 to avoid waiting too much
 ** for the wave to actually begin */
 uint_fast16_t lasty = dragonwave_dragons[dragonwave_dcount - 1U].ypos;
 if (lasty < 0xFFE0U){
  uint_fast16_t yadj = 0xFFE0U - lasty;
  for (uint_fast8_t drgid = 0U; drgid < lylen; drgid ++){
   dragonwave_dragons[drgid].ypos += yadj;
  }
 }
}



void DragonWave_Tick(void)
{
 if (DragonWave_IsEnded()){
  return;
 }

 dragonwave_drgi_tdef* dragon = &(dragonwave_dragons[0]);
 uint_fast8_t drgid = 0U;

 while (drgid < dragonwave_dcount){

  bool dead = false;

  if (dragonwave_speeddiv == 0U){
   dragon->ypos ++;
  }

  uint_fast8_t flyfr = dragon->flyfr;
  if (flyfr == 0U){
   if ((random_get() & 0x3FU) == 0U){
    /* Gives a random amount of flaps as 7 isn't a divisor of 256, so will
    ** wrap a couple of times depending on this initial value until arriving
    ** to 0 again */
    flyfr += (random_get() & 7U);
   }
  }else{
   flyfr += 7U;
  }
  dragon->flyfr = flyfr & 0xFFU;

  uint_fast8_t diefr = dragon->diefr;
  if (diefr != 0U){
   diefr = (diefr + 15U) & 0xFFU; /* Ends with 0; 17 * 15 = 255, from 1 */
   dragon->diefr = diefr;
   if (diefr == 0U){
    DragonWave_Delete(drgid);
    dead = true;
   }
  }

  if (!dead){
   dragon ++;
   drgid ++;
  }
 }

 if (dragonwave_speeddiv == 0U){
  dragonwave_speeddiv = 1U;
 }else{
  dragonwave_speeddiv --;
 }
}



bool DragonWave_IsEnded(void)
{
 return (dragonwave_dcount == 0U);
}



uint_fast8_t DragonWave_PopArriving(void)
{
 if (dragonwave_dcount == 0U){
  return 0xFFU;
 }
 uint_fast8_t  lastdrg = dragonwave_dcount - 1U;
 uint_fast16_t ypos = dragonwave_dragons[lastdrg].ypos;
 if ((ypos >= 225U) && (ypos < 0x8000U)){
  /* Arriving dragon; 225 is used for this check as by then the dragon should
  ** be visually below the edge of the playfield */
  uint_fast8_t siz = dragonwave_dragons[lastdrg].dsizstr & 3U;
  DragonWave_Delete(lastdrg);
  return siz;
 }else{
  return 0xFFU;
 }
}



uint_fast8_t DragonWave_Count(void)
{
 return dragonwave_dcount;
}



void DragonWave_GetDragon(uint_fast8_t idx, dragonwave_dragon_tdef* dpars)
{
 uint_fast16_t ypos;
 uint_fast8_t xpos;
 uint_fast8_t dsiz;
 uint_fast8_t dstr;
 uint_fast8_t flyfr;
 uint_fast8_t diefr;
 if (idx >= dragonwave_dcount){
  ypos = 0U;
  xpos = 0U;
  dsiz = 0U;
  dstr = 0U;
  flyfr = 0U;
  diefr = 0xFFU;
 }else{
  dragonwave_drgi_tdef const* dragon = &(dragonwave_dragons[idx]);
  ypos = dragon->ypos;
  xpos = dragon->xpos;
  dsiz = dragon->dsizstr;
  flyfr = dragon->flyfr;
  diefr = dragon->diefr;
  dstr = dsiz >> 4;
  dsiz &= 3U;
 }
 dpars->ypos = ypos;
 dpars->xpos = xpos;
 dpars->dsize = dsiz;
 dpars->svar = dstr;
 dpars->flyfr = flyfr;
 dpars->diefr = diefr;
}



uint_fast8_t DragonWave_ReadPositions(uint8_t* posbuf)
{
 uint_fast8_t rcount = 0U;
 uint_fast8_t dcount = dragonwave_dcount;
 dragonwave_drgi_tdef const* dragon = &(dragonwave_dragons[0]);
 while (dcount != 0U){
  uint_fast16_t ypos = dragon->ypos;
  uint_fast8_t  xpos = dragon->xpos;
  uint_fast8_t  diefr = dragon->diefr;
  dragon ++;
  if ((diefr == 0U) && (ypos < 192U)){
   *posbuf = ypos;
   posbuf ++;
   *posbuf = xpos;
   posbuf ++;
   rcount ++;
  }
  dcount --;
 }
 return rcount;
}



bool DragonWave_HitPoint(uint_fast8_t xpos, uint_fast8_t ypos, uint_fast16_t dmg)
{
 dragonwave_drgi_tdef* dragon = &(dragonwave_dragons[0]);
 for (uint_fast8_t drgid = 0U; drgid < dragonwave_dcount; drgid ++){
  uint_fast16_t dypos16 = dragon->ypos;
  uint_fast8_t  dxpos = dragon->xpos;
  uint_fast8_t  dypos;
  if (dypos16 < 200U){
   dypos = dypos16;
   if (((ypos + 8U) >= dypos) && (ypos <= (dypos + 8U))){
    if (((xpos + 8U) >= dxpos) && (xpos <= (dxpos + 8U))){
     uint_fast16_t oldhp = dragon->curhp;
     if (oldhp > dmg){
      dragon->curhp = oldhp - dmg;
      return true;
     }else if (oldhp != 0U){
      dragon->curhp = 0U;
      dragon->diefr = 1U;
      soundpatch_play(SOUNDPATCH_CH_ALL, SOUNDPATCH_DIE0 + (random_get() & 1U));
      return true;
     }else{
      /* Already dying dragon */
     }
    }
   }
  }
  dragon ++;
 }
 return false;
}



void DragonWave_HitSplash(uint_fast8_t xpos, uint_fast8_t ypos, uint_fast16_t dmg)
{
 dragonwave_drgi_tdef* dragon = &(dragonwave_dragons[0]);
 for (uint_fast8_t drgid = 0U; drgid < dragonwave_dcount; drgid ++){
  uint_fast16_t dypos16 = dragon->ypos;
  uint_fast8_t  dxpos = dragon->xpos;
  uint_fast8_t  dypos;
  if (dypos16 < 200U){
   dypos = dypos16;
   if (((ypos + 32U) >= dypos) && (ypos <= (dypos + 32U))){
    if (((xpos + 24U) >= dxpos) && (xpos <= (dxpos + 24U))){
     uint_fast16_t oldhp = dragon->curhp;
     if (oldhp > dmg){
      dragon->curhp = oldhp - dmg;
     }else if (oldhp != 0U){
      dragon->curhp = 0U;
      dragon->diefr = 1U;
      soundpatch_play(SOUNDPATCH_CH_ALL, SOUNDPATCH_DIE0 + (random_get() & 1U));
     }else{
      /* Already dying dragon */
     }
    }
   }
  }
  dragon ++;
 }
}

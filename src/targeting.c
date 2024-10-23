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


#include "targeting.h"
#include "bullet.h"
#include "playfield.h"
#include "soundpatch.h"
#include "random.h"



/** Damage accumulation buffer */
static uint16_t* targeting_dmgacc;

/** Cooldown until next shot */
static uint8_t*  targeting_cooldown;



uint_fast16_t Targeting_Size(void)
{
 uint_fast8_t itemsize = sizeof(uint8_t) + sizeof(uint16_t);
 return (PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH) * itemsize;
}



void Targeting_Init(void* buf)
{
 targeting_dmgacc = buf;
 uint_fast8_t dmgsize = (PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH) * sizeof(uint16_t);
 targeting_cooldown = &(((uint8_t*)(buf))[dmgsize]);
 Targeting_Reset();
}



void Targeting_Reset(void)
{
 for (uint_fast8_t tpos = 0U; tpos < (PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH); tpos ++){
  targeting_dmgacc[tpos] = 0U;
  targeting_cooldown[tpos] = 0U;
 }
 Bullet_Reset();
}



/**
 * @brief   Combine supply items
 *
 * @param   pitem:  Previous item, start with PLAYFIELD_FRUIT
 * @param   column: Column to check item at
 * @param   row:    Row to check item at
 * @return          Highest supply item class between prev. and current
 */
static uint_fast8_t Targeting_CombineSupply(uint_fast8_t pitem,
    uint_fast8_t column, uint_fast8_t row)
{
 uint_fast8_t citem = Playfield_GetItem(column, row);
 /* A bit hackish approach to save size and cost: Supply items are the last
 ** ones, incrementally, so simple comparison works! */
 if (citem > pitem){
  return citem;
 }else{
  return pitem;
 }
}



void Targeting_Tick(void)
{
 uint16_t* dmgaccbuf = targeting_dmgacc;
 uint8_t* cooldownbuf = targeting_cooldown;

 for (uint_fast8_t row = 0U; row < PLAYFIELD_HEIGHT; row ++){
  for (uint_fast8_t column = 0U; column < PLAYFIELD_WIDTH; column ++){

   uint_fast8_t cooldown = *cooldownbuf;
   uint_fast16_t dmgacc = *dmgaccbuf;

   if (cooldown != 0U){
    cooldown --;
    *cooldownbuf = cooldown;
   }else{
    uint_fast8_t  pfitem = Playfield_GetItem(column, row);
    bool          shooter = true;
    uint_fast16_t dmg = 0U;
    uint_fast8_t  cdown = 0U;
    switch (pfitem){
     case PLAYFIELD_ARROW1:  dmg =   8U; cdown = 128U; break;
     case PLAYFIELD_ARROW2:  dmg =  10U; cdown =  52U; break;
     case PLAYFIELD_ARROW3:  dmg =  12U; cdown =  20U; break;
     case PLAYFIELD_ARROW4:  dmg =  16U; cdown =   8U; break;
     case PLAYFIELD_TOWER1:  dmg =   8U; cdown = 104U; break;
     case PLAYFIELD_TOWER2:  dmg =  10U; cdown =  44U; break;
     case PLAYFIELD_TOWER3:  dmg =  12U; cdown =  16U; break;
     case PLAYFIELD_TOWER4:  dmg =  18U; cdown =   8U; break;
     case PLAYFIELD_CANNON1: dmg =  16U; cdown = 255U; break;
     case PLAYFIELD_CANNON2: dmg =  20U; cdown =  96U; break;
     case PLAYFIELD_CANNON3: dmg =  26U; cdown =  40U; break;
     case PLAYFIELD_CANNON4: dmg =  32U; cdown =  16U; break;
     default: shooter = false; break;
    }

    if (shooter){

     uint_fast8_t supply = PLAYFIELD_FRUIT;
     supply = Targeting_CombineSupply(supply, column - 1U, row);
     supply = Targeting_CombineSupply(supply, column, row - 1U);
     supply = Targeting_CombineSupply(supply, column + 1U, row);
     supply = Targeting_CombineSupply(supply, column, row + 1U);
     switch (supply){
      case PLAYFIELD_SUPPLY1:
       cdown = (cdown >> 2) + (cdown >> 1); /* 0.75 */
       dmg = dmg + (dmg >> 1); /* 1.5 */
       break;
      case PLAYFIELD_SUPPLY2:
       cdown = (cdown >> 3) + (cdown >> 1); /* 0.625 */
       dmg = (dmg << 1); /* 2.0 */
       break;
      case PLAYFIELD_SUPPLY3:
       cdown = (cdown >> 1); /* 0.5 */
       dmg = (dmg << 1) + (dmg >> 1); /* 2.5 */
       break;
      case PLAYFIELD_SUPPLY4:
       cdown = (cdown >> 1) - (cdown >> 3); /* 0.375 */
       dmg = (dmg << 1) + dmg; /* 3.0 */
       break;
      default:
       break;
     }
     if (cdown == 0U){
      cdown = 1U;
     }

     bullet_type_tdef btype;
     switch (pfitem){
      case PLAYFIELD_ARROW1:
      case PLAYFIELD_ARROW2:
      case PLAYFIELD_ARROW3:
      case PLAYFIELD_ARROW4: btype = BULLET_ARROW;  break;
      case PLAYFIELD_TOWER1:
      case PLAYFIELD_TOWER2:
      case PLAYFIELD_TOWER3:
      case PLAYFIELD_TOWER4: btype = BULLET_TOWER;  break;
      default:               btype = BULLET_CANNON; break;
     }

     bullet_launch_tdef lstat = 0U;;
     lstat = Bullet_Launch(column, row, btype, dmg + dmgacc);
     switch (lstat){
      case BULLET_LAUNCH_OK:
       /* Launched OK, set up cooldown */
       *cooldownbuf = cdown - 1U;
       *dmgaccbuf = 0U;
       if (btype == BULLET_CANNON){
        soundpatch_play(SOUNDPATCH_CH_0 | SOUNDPATCH_CH_1, SOUNDPATCH_CANNON);
       }else{
        soundpatch_play(SOUNDPATCH_CH_0 | SOUNDPATCH_CH_1, SOUNDPATCH_ARROW0 + (random_get() & 1U));
       }
       break;
      case BULLET_LAUNCH_FULL:
       /* Need to accumulate damage for a later shot */
       if (dmgacc < 0x8000U){ dmgacc += (dmg / cdown); }
       *dmgaccbuf = dmgacc;
       break;
      default: /* BULLET_LAUNCH_NOTARGET */
       /* Some damage might be accumulated, don't clear that, let it getting
       ** used if later could success with targeting */
       break;
     }
    }
   }

   dmgaccbuf ++;
   cooldownbuf ++;
  }
 }
}

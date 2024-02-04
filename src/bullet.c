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



#include "bullet.h"
#include "dragonwave.h"
#include "random.h"



/** @{ */
/** Bullet internal types */
#define BULLET_ITYPE_TOWER   0x00U
#define BULLET_ITYPE_ARROW   0x40U
#define BULLET_ITYPE_CANNON  0x80U
#define BULLET_ITYPE_FRAG    0xC0U
#define BULLET_ITYPE_MASK    0xC0U
/** @} */



/** Bullet data */
typedef struct{
 uint16_t dmg;   /** Damage */
 uint8_t  flags; /** Type and directional flags */
 uint8_t  xpos;  /** Bullet X position (playfield relative) */
 uint8_t  ypos;  /** Bullet Y position (playfield relative) */
}bullet_data_tdef;



/** Bullet data buffer */
static bullet_data_tdef* bullet_data;

/** Maximum bullet count */
static uint_fast8_t      bullet_max;

/** Active bullet count */
static uint_fast8_t      bullet_count;

/** Tick divider for tower arrow time-to-live counts */
static uint_fast8_t      bullet_tickdiv;



uint_fast8_t Bullet_ItemSize(void)
{
 return sizeof(bullet_data_tdef);
}



void Bullet_Init(void* buf, uint_fast8_t bcount)
{
 bullet_data = buf;
 bullet_max = bcount;
 Bullet_Reset();
}



void Bullet_Reset(void)
{
 bullet_count = 0U;
 bullet_tickdiv = 0U;
}



/**
 * @brief   Deletes a bullet
 *
 * @param   id:     Bullet ID to delete
 */
static void Bullet_Delete(uint_fast8_t id)
{
 /* This needs to run well enough on the AVR, the compiler only uses Z for
 ** displacement addressing, so needed to guide it to get OK code using a
 ** single pointer */
 bullet_data_tdef* data = &bullet_data[id];
 for (uint_fast8_t pos = id + 1U; pos < bullet_count; pos ++){
  uint_fast16_t dmg = data[1].dmg;
  uint_fast8_t flags = data[1].flags;
  uint_fast8_t xpos = data[1].xpos;
  uint_fast8_t ypos = data[1].ypos;
  data[0].dmg = dmg;
  data[0].flags = flags;
  data[0].xpos = xpos;
  data[0].ypos = ypos;
  data ++;
 }
 bullet_count --;
}



void Bullet_Tick(void)
{
 uint_fast8_t tickdiv = bullet_tickdiv;
 tickdiv ^= 1U;
 bullet_tickdiv = tickdiv;

 uint_fast8_t bulid = 0U;

 while (bulid < bullet_count){
  bullet_data_tdef* data = &bullet_data[bulid];
  uint_fast16_t dmg = data->dmg;
  uint_fast8_t flags = data->flags;
  uint_fast8_t xpos = data->xpos;
  uint_fast8_t ypos = data->ypos;
  uint_fast8_t ttl;
  bool delete = false;

  switch (flags & BULLET_ITYPE_MASK){

   case BULLET_ITYPE_TOWER:
    if (DragonWave_HitPoint(xpos, ypos, dmg)){
     delete = true;
    }else{
     ttl = (flags >> 4) & 0x3U;
     if (ttl == 0U){
      delete = true;
     }else{
      ttl -= tickdiv;
      data->flags = (flags & 0xCFU) + (ttl << 4);
      uint_fast8_t dir = flags & 0xFU;
      switch (dir){
       case  0U:             ypos -= 6U; break;
       case  1U: xpos += 1U; ypos -= 4U; break;
       case  2U: xpos += 2U; ypos -= 3U; break;
       case  3U: xpos += 3U; ypos -= 2U; break;
       case  4U: xpos += 4U;             break;
       case  5U: xpos += 3U; ypos += 2U; break;
       case  6U: xpos += 2U; ypos += 3U; break;
       case  7U: xpos += 1U; ypos += 4U; break;
       case  8U:             ypos += 6U; break;
       case  9U: xpos -= 1U; ypos += 4U; break;
       case 10U: xpos -= 2U; ypos += 3U; break;
       case 11U: xpos -= 3U; ypos += 2U; break;
       case 12U: xpos -= 4U;             break;
       case 13U: xpos -= 3U; ypos -= 2U; break;
       case 14U: xpos -= 2U; ypos -= 3U; break;
       default:  xpos -= 1U; ypos -= 4U; break;
      }
      if ((xpos >= 0x80U) && (xpos < 0xE0U)){
       delete = true;
      }
      if (ypos >= 200U){
       delete = true;
      }
     }
    }
    break;

   case BULLET_ITYPE_ARROW:
    if (DragonWave_HitPoint(xpos, ypos, dmg)){
     delete = true;
    }else{
     uint_fast8_t dir = (flags >> 4) & 3U;
     switch (dir){
      case 0U: xpos += 4U; ypos -= 6U; break;
      case 1U: xpos += 4U; ypos += 6U; break;
      case 2U: xpos -= 4U; ypos += 6U; break;
      default: xpos -= 4U; ypos -= 6U; break;
     }
     if ((xpos >= 0x80U) && (xpos < 0xE0U)){
      delete = true;
     }
     if (ypos >= 200U){
      delete = true;
     }
    }
    break;

   case BULLET_ITYPE_CANNON:
    ttl = flags & 0x3FU;
    if (ttl == 0U){
     delete = true;
     /* Hit, deal damage and create fragments (these for visuals only) */
     DragonWave_HitSplash(xpos, ypos, dmg);
     if ((bullet_count + 20U) < bullet_max){
      /* Only create fragments if there are plenty of bullet slots still
      ** available */
      for (uint_fast8_t dir = 0U; dir < 4U; dir ++){
       uint_fast8_t rnd = random_get();
       if ((rnd & 7U) != 0U){
        bullet_data_tdef* frag = &bullet_data[bullet_count];
        bullet_count ++;
        frag->xpos = xpos;
        frag->ypos = ypos;
        frag->dmg  = 0U;
        frag->flags = BULLET_ITYPE_FRAG | (dir << 4) | (((rnd >> 4) & 0x7U) + 8U);
       }
      }
     }
    }else{
     ttl --;
     data->flags = BULLET_ITYPE_CANNON | ttl;
     if (ypos == 0U){
      delete = true;
     }else{
      ypos -= 5U;
     }
    }
    break;

   default: /* BULLET_ITYPE_FRAG */
    ttl = flags & 0xFU;
    if (ttl == 0U){
     delete = true;
    }else{
     ttl --;
     data->flags = (flags & 0xF0U) + ttl;
     uint_fast8_t dir = (flags >> 4) & 3U;
     switch (dir){
      case 0U: xpos ++; ypos --; break;
      case 1U: xpos ++; ypos ++; break;
      case 2U: xpos --; ypos ++; break;
      default: xpos --; ypos --; break;
     }
    }
    break;
  }

  if (delete){
   Bullet_Delete(bulid);
  }else{
   data->xpos = xpos;
   data->ypos = ypos;
   bulid ++;
  }
 }
}



bullet_launch_tdef Bullet_Launch(uint_fast8_t xpos, uint_fast8_t ypos,
    bullet_type_tdef btype, uint_fast16_t dmg)
{
 if (bullet_count >= bullet_max){
  return BULLET_LAUNCH_FULL;
 }

 uint8_t drgxylist[DRAGONWAVE_MAX_DRAGONS * 2U];
 uint_fast8_t dcount = DragonWave_ReadPositions(&(drgxylist[0]));

 if (dcount == 0U){
  return BULLET_LAUNCH_NOTARGET;
 }

 uint_fast8_t pixelxpos = ((xpos * 16U) +  8U) & 0xFFU;
 uint_fast8_t pixelypos = ((ypos * 24U) + 12U) & 0xFFU;
 bool found = false; /* Target found? */

 if (btype == BULLET_TOWER){

  /* Stone towers can target the squares around them */
  uint_fast8_t targetid = dcount * 2U;
  uint_fast8_t targetx;
  uint_fast8_t targety;
  while (targetid > 0U){
   targetid -= 2U;
   targety = drgxylist[targetid] / 24U;
   if ((targety <= (ypos + 1U)) && ((targety + 1U) >= ypos)){
    targetx = drgxylist[targetid + 1U] >> 4;
    if ((targetx <= (xpos + 1U)) && ((targetx + 1U) >= xpos)){
     found = true;
     break;
    }
   }
  }
  if (found){
   uint_fast8_t dir;
   uint_fast8_t pixeltgy = drgxylist[targetid];
   uint_fast8_t pixeltgx = drgxylist[targetid + 1U];
   uint_fast8_t diffx;
   uint_fast8_t diffy;
   uint_fast8_t rnd = random_get();
   if (pixelxpos < pixeltgx){
    diffx = pixeltgx - pixelxpos;
   }else{
    diffx = pixelxpos - pixeltgx;
   }
   if (pixelypos < pixeltgy){
    diffy = pixeltgy - pixelypos;
   }else{
    diffy = pixelypos - pixeltgy;
   }
   if (diffx < 8U){
    /* Within the tower's column */
    if (pixelypos > pixeltgy){
     dir = 0U; /* Up */
     pixelypos -= 9U;
    }else{
     dir = 8U; /* Down */
     pixelypos += 9U;
    }
    pixelxpos = (pixelxpos - 4U) + (rnd & 7U);
   }else{
    /* On a side */
    if (diffy >= 12U){
     if (pixelypos > pixeltgy){
      dir = 2U; /* Up - Right */
     }else{
      dir = 6U; /* Down - Right */
     }
    }else if (diffy >= 4U){
     if (pixelypos > pixeltgy){
      dir = 3U; /* Up - Right */
     }else{
      dir = 5U; /* Down - Right */
     }
    }else{
     dir = 4U; /* Right side */
    }
    if (pixelxpos < pixeltgx){
     /* On the right */
     pixelxpos += 6U;
    }else{
     /* On the left */
     pixelxpos -= 6U;
     dir = 16U - dir;
    }
    pixelypos = (pixelypos - 4U) + (rnd & 7U);
   }
   bullet_data_tdef* bullet = &bullet_data[bullet_count];
   bullet_count ++;
   bullet->xpos = pixelxpos;
   bullet->ypos = pixelypos;
   bullet->dmg  = dmg;
   bullet->flags = BULLET_ITYPE_TOWER | 0x30U | dir;
  }

 }else if (btype == BULLET_ARROW){

  /* Ballista towers can target diagonally excluding the tower itself */
  uint_fast8_t targetid = dcount * 2U;
  uint_fast8_t targetx;
  uint_fast8_t targety;
  uint_fast8_t coordif = (xpos - ypos) & 0xFFU;
  uint_fast8_t coorsum = (xpos + ypos) & 0xFFU;
  while (targetid > 0U){
   targetid -= 2U;
   targety = drgxylist[targetid] / 24U;
   targetx = drgxylist[targetid + 1U] >> 4;
   uint_fast8_t tcdif = (targetx - targety) & 0xFFU;
   uint_fast8_t tcsum = (targetx + targety) & 0xFFU;
   if ((tcdif == coordif) || (tcsum == coorsum)){
    if (targetx != xpos){
     found = true;
     break;
    }
   }
  }
  if (found){
   uint_fast8_t dir;
   uint_fast8_t pixeltgy = drgxylist[targetid];
   uint_fast8_t pixeltgx = drgxylist[targetid + 1U];
   if (pixelxpos < pixeltgx){
    if (pixelypos > pixeltgy){
     dir = 0U;
     pixelypos -= 9U;
    }else{
     dir = 1U;
     pixelypos += 9U;
    }
    pixelxpos += 6U;
   }else{
    if (pixelypos > pixeltgy){
     dir = 3U;
     pixelypos -= 9U;
    }else{
     dir = 2U;
     pixelypos += 9U;
    }
    pixelxpos -= 6U;
   }
   bullet_data_tdef* bullet = &bullet_data[bullet_count];
   bullet_count ++;
   bullet->xpos = pixelxpos;
   bullet->ypos = pixelypos;
   bullet->dmg  = dmg;
   bullet->flags = BULLET_ITYPE_ARROW | (dir << 4);
  }

 }else if (btype == BULLET_CANNON){

  /* Cannons can target ahead of them, excluding the square directly ahead */
  uint_fast8_t targetid = dcount * 2U;
  uint_fast8_t targetx;
  uint_fast8_t targety;
  while (targetid > 0U){
   targetid -= 2U;
   targety = drgxylist[targetid] / 24U;
   if ((targety + 1U) < ypos){
    targetx = drgxylist[targetid + 1U] >> 4;
    if (targetx == xpos){
     found = true;
     break;
    }
   }
  }
  if (found){
   uint_fast8_t ttl = (ypos - targety) * 4U;
   bullet_data_tdef* bullet = &bullet_data[bullet_count];
   bullet_count ++;
   bullet->xpos = pixelxpos;
   bullet->ypos = pixelypos;
   bullet->dmg  = dmg;
   bullet->flags = BULLET_ITYPE_CANNON | ttl;
  }

 }else{
 }

 if (!found){
  return BULLET_LAUNCH_NOTARGET;
 }
 return BULLET_LAUNCH_OK;
}



uint_fast8_t Bullet_GetCount(void)
{
 return bullet_count;
}



void Bullet_GetParams(uint_fast8_t id, bullet_params_tdef* bpars)
{
 uint_fast8_t xpos;
 uint_fast8_t ypos;
 uint_fast8_t flags;

 if (id >= bullet_count){
  xpos = 0U;
  ypos = 0U;
  flags = 0U;
 }else{
  bullet_data_tdef* bullet = &bullet_data[id];
  xpos = bullet->xpos;
  ypos = bullet->ypos;
  flags = bullet->flags;
 }

 uint_fast8_t dir;
 bullet_type_tdef btype;
 switch (flags & BULLET_ITYPE_MASK){
  case BULLET_ITYPE_TOWER:
   btype = BULLET_TOWER;
   dir = (flags & 0xFU) << 4;
   break;
  case BULLET_ITYPE_ARROW:
   btype = BULLET_ARROW;
   dir = ((flags & 0x30U) << 2) + 0x20U;
   break;
  case BULLET_ITYPE_FRAG:
   btype = BULLET_FRAG;
   dir = ((flags & 0x30U) << 2) + 0x20U;
   break;
  default: /* BULLET_ITYPE_CANNON */
   btype = BULLET_CANNON;
   dir = 0U;
   break;
 }

 bpars->xpos = xpos;
 bpars->ypos = ypos;
 bpars->dir = dir;
 bpars->btype = btype;
}

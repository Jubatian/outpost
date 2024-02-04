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


#include "grsprite.h"
#include "spriteset.h"
#include "sprite_ll.h"
#include "playfield.h"
#include "dragonwave.h"
#include "dragonlayout.h"
#include "bullet.h"



void GrSprite_Init(grsprite_arrangement_tdef arrtyp,
    void* buf, uint_fast16_t len,
    uint_fast8_t sprcnt)
{
 uint8_t* buf8 = (uint8_t*)(buf);
 uint_fast16_t sprbytes = (uint_fast16_t)(sprcnt) * SPRITE_LL_SPR_SIZE;
 if (sprbytes > len){
  sprbytes = len;
 }
 uint_fast8_t hcount;
 switch (arrtyp){
  case GRSPRITE_ARR_SWAP: hcount = 5U; break;
  case GRSPRITE_ARR_WAVE: hcount = 4U; break;
  default:                hcount = 4U; break;
 }
 Sprite_LL_Init(hcount, buf8, sprbytes, &buf8[sprbytes], len - sprbytes);
}



void GrSprite_Reset(void)
{
 Sprite_LL_Reset();
}



void GrSprite_Cursor(grsprite_cursor_tdef ctyp, uint_fast8_t frame,
    uint_fast8_t xpos, uint_fast8_t ypos)
{
 if (xpos >= PLAYFIELD_WIDTH){ return; }
 if (ypos >= (256U / 24U)){ return; }
 xpos = (xpos * 16U) + 16U + 32U; /* Align with playfield left */
 ypos = (ypos * 24U) + 32U;       /* Align with playfield top */

 uint_fast8_t ssel;
 uint_fast8_t col1;
 uint_fast8_t col2;
 uint_fast8_t col3;

 switch (ctyp){
  case GRSPRITE_CURSOR_HOVER:
   /* Could possibly highlight tile reach here */
   ssel = 0U;
   col1 = 0xF6U;
   col2 = 0xF6U;
   col3 = 0xF6U;
   break;
  case GRSPRITE_CURSOR_SELECT:
   ssel = (frame >> 6) & 1U;
   col1 = 0U;
   if (((frame >> 7) & 1U) != 0U){
    col2 = 0xFFU;
    col3 = 0U;
   }else{
    col2 = 0U;
    col3 = 0xFFU;
   }
   break;
  case GRSPRITE_CURSOR_ANYSWAP:
   ssel = (frame >> 6) & 1U;
   col1 = 0x01U;
   if (((frame >> 7) & 1U) != 0U){
    col2 = 0x37U;
    col3 = 0x01U;
   }else{
    col2 = 0x01U;
    col3 = 0x37U;
   }
   break;
  case GRSPRITE_CURSOR_DELETE:
   col1 = 0x5FU;
   col2 = 0x5FU;
   col3 = 0x5FU;
   ssel = 2U + (((uint_fast16_t)(frame) * 12U) >> 8);
   Sprite_LL_Add(xpos, ypos + (12U - ((ssel + 1U) >> 1)),
       spriteset_getheight(ssel),
       col1, col2, col3,
       spriteset_getdataptr(ssel),
       0U);
   ssel = 0U;
   break;
  default:
   ssel = 0U;
   col1 = 0xFFU;
   col2 = 0xFFU;
   col3 = 0xFFU;
   break;
 }

 Sprite_LL_Add(xpos, ypos,
     spriteset_getheight(ssel),
     col1, col2, col3,
     spriteset_getdataptr(ssel),
     0U);
}



void GrSprite_AddDragons(void)
{
 if (DragonWave_IsEnded()){
  return;
 }
 uint_fast8_t dcount = DragonWave_Count();
 for (uint_fast8_t drgid = 0U; drgid < dcount; drgid ++){
  dragonwave_dragon_tdef dpars;
  DragonWave_GetDragon(drgid, &dpars);
  uint_fast8_t compid = 0U;
  uint_fast8_t col1;
  uint_fast8_t col2;
  uint_fast8_t col3;
  if (dpars.diefr == 0U){
   uint_fast32_t cols = dragonlayout_getcolours(dpars.svar);
   col1 = (cols >> 16) & 0xFFU;
   col2 = (cols >>  8) & 0xFFU;
   col3 = (cols      ) & 0xFFU;
  }else{
   col1 = 255U - dpars.diefr;
   col1 = (col1 & 0xC0U) + ((col1 >> 2) & 0x38U) + ((col1 >> 5) & 0x07U);
   col2 = col1;
   col3 = col1;
  }
  uint_fast16_t clist = dragonlayout_getcomplist(dpars.dsize, dpars.flyfr);
  while (true){
   uint_fast32_t dcomp = dragonlayout_getcomponent(clist, compid);
   uint_fast8_t sprid = (dcomp >> 24) & 0xFFU;
   uint_fast8_t xpos = (dcomp >> 16) & 0xFFU;
   uint_fast16_t ypos = dcomp & 0xFFFFU;
   if (sprid == 0xFFU){
    break; /* End of sprite component list */
   }
   xpos += dpars.xpos;
   ypos += dpars.ypos;
   xpos += 16U + 32U; /* Align with playfield left */
   ypos += 32U;       /* Align with playfield top */
   xpos &= 0xFFU;
   ypos &= 0xFFFFU;
   uint_fast8_t flags = 0U;
   if ((sprid & 0x80U) != 0U){
    flags |= SPRITE_LL_FLAG_XFLIP;
    sprid &= 0x7FU;
   }
   uint_fast8_t sheight = spriteset_getheight(sprid);
   uint8_t const* sdata = spriteset_getdataptr(sprid);
   uint_fast16_t yend = (ypos + sheight) & 0xFFFFU;
   if ((yend > 32U) && (yend < 0x8000U) && ((ypos < 232U) || (ypos >= 0x8000U)))
   {
    /* Sprite has displayed portion */
    if ((ypos >= 0x8000U) || (ypos < 32U)){
     /* Bottom end of tall sprite is in the visible region, needs adjustment
     ** to get it displaying (the top can not be in the 2's complement
     ** negative, neither can it be 0 due to low level sprite limitations) */
     uint_fast8_t yadj = (32U - ypos) & 0xFFU;
     sdata += (uint_fast16_t)(yadj) * 4U;
     sheight -= yadj;
     ypos = 32U;
    }
    Sprite_LL_Add(xpos, ypos,
        sheight,
        col1, col2, col3,
        sdata,
        flags);
   }
   compid ++;
  }
 }
}



void GrSprite_AddBullets(void)
{
 uint_fast8_t bcount = Bullet_GetCount();
 for (uint_fast8_t bulid = 0U; bulid < bcount; bulid ++){
  bullet_params_tdef bpars;
  Bullet_GetParams(bulid, &bpars);
  uint_fast8_t col;
  uint_fast8_t xpos = bpars.xpos + (16U + 32U); /* Align with playfield left */
  uint_fast8_t ypos = bpars.ypos + 32U;         /* Align with playfield top */
  xpos &= 0xFFU;
  ypos &= 0xFFU;
  switch (bpars.btype){
   case BULLET_CANNON:
    col = 0x40U;
    break;
   case BULLET_FRAG:
    col = 0x5FU;
    break;
   default:
    col = 0xBFU;
    break;
  }
  Sprite_LL_AddBullet(xpos, ypos, 1U, 2U, col);
 }
}

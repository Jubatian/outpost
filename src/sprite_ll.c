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



#include "sprite_ll.h"
#include <uzebox.h>


/** Sprite buffer (all sprites) */
sprite_t* sprite_ll_sprbuf;
/** Bullet buffer (all bullets) */
bullet_t* sprite_ll_bulbuf;

/** Count of sprites in a sprite buffer (all columns) */
uint_fast8_t sprite_ll_sprmax;
/** Count of bullets in a bullet buffer (single column) */
uint_fast8_t sprite_ll_bulmax;

/** Count of sprite columns available */
uint_fast8_t sprite_ll_sprcols;
/** Count of bullet columns available */
uint_fast8_t sprite_ll_bulcols;

/** Count of sprites added */
uint_fast8_t sprite_ll_sprcnt;
/** Count of bullets added in each column */
uint_fast8_t sprite_ll_bulcnt[8];
/** Column order with least amount of items first */
uint_fast8_t sprite_ll_bulord[8];



void Sprite_LL_Init(uint_fast8_t hcount,
    void* sprbuf, uint_fast16_t sprlen,
    void* bulbuf, uint_fast16_t bullen)
{
 sprite_ll_sprbuf = (sprite_t*)(sprbuf);
 sprite_ll_bulbuf = (bullet_t*)(bulbuf);
 /* Depends on sprite mode, this is set up for mode 1 (16px wide sprites) */
 switch (hcount){
  case 3U: sprite_ll_sprcols = 3U; sprite_ll_bulcols = 7U; break;
  case 5U: sprite_ll_sprcols = 5U; sprite_ll_bulcols = 1U; break;
  default: sprite_ll_sprcols = 4U; sprite_ll_bulcols = 4U; break;
 }
 sprite_ll_sprmax = (sprlen / (sizeof(sprite_t)));
 sprite_ll_bulmax = (bullen / (sizeof(bullet_t) * sprite_ll_bulcols));
 m72_bull_cnt = sprite_ll_bulcols;
 Sprite_LL_Reset();
}



void Sprite_LL_Reset(void)
{
 for (uint_fast8_t col = 0U; col < sprite_ll_sprcols; col ++){
  sprites[col] = NULL;
 }
 for (uint_fast8_t col = 0U; col < sprite_ll_bulcols; col ++){
  if (sprite_ll_bulmax == 0U){
   bullets[col] = &m72_bull_end;
  }else{
   bullet_t* blist = &(sprite_ll_bulbuf[sprite_ll_bulmax * col]);
   blist[0].ypos   = 0U;
   blist[0].height = 0U;
   sprite_ll_bulcnt[col] = 1U;
   sprite_ll_bulord[col] = col;
   bullets[col] = blist;
  }
 }
 sprite_ll_sprcnt = 0U;
}



bool Sprite_LL_Add(uint_fast8_t xpos, uint_fast8_t ypos,
    uint_fast8_t height,
    uint_fast8_t col1, uint_fast8_t col2, uint_fast8_t col3,
    uint8_t const* data, uint_fast8_t flags)
{
 /* Sprite has to chain in somewhere where it fits. Try to keep putting them
 ** in the first column, spilling over into subsequent columns as necessary */

 if (sprite_ll_sprcnt >= sprite_ll_sprmax){ return false; }

 uint_fast8_t sprcnt = sprite_ll_sprcnt;
 uint_fast8_t column;
 sprite_t volatile* target = &sprite_ll_sprbuf[sprcnt];

 /* Prepare target with sprite data assuming it would fit somewhere (it will
 ** be simply discarded if not). Data pointer is assumed to be within
 ** permitted ranges for the sprite mode. */

 ypos = (0U - ypos) & 0xFFU;
 target->ypos   = ypos;
 target->height = height;
 uint_fast16_t flipa = 0U;
 if ((flags & SPRITE_LL_FLAG_XFLIP) != 0U){ flipa = 0x8000U; }
 if ((flags & SPRITE_LL_FLAG_RAM) != 0U){
  target->off = (((uint16_t)(data) & 0xFFFU) + 0x7000U) + flipa;
 }else{
  target->off = ((uint16_t)(data) & 0x7FFFU) + flipa;
 }
 target->xpos   = xpos;
 target->col1   = col1;
 target->col2   = col2;
 target->col3   = col3;
 target->next   = NULL;

 /* Chain sprite in if possible. Note: volatile qualifier use is a bit
 ** troubled due to the chained list's next pointer not having the qualifier,
 ** nothing much can be done about that (apart from changing that Mode 72
 ** structure to have the qualifier) */

 height += 1U; /* Phantom 1px extra height to accommodate for mode limits */
 bool fit = false;

 for (column = 0U; column < sprite_ll_sprcols; column ++){
  fit = true;
  sprite_t volatile* curr = sprites[column];
  if (curr == NULL){
   /* No sprites in this column yet - put it in this column then! */
   sprites[column] = target;
   break;
  }
  uint_fast8_t cypos = curr->ypos;
  if (cypos < ypos){ /* New sprite is above */
   /* Sprite needs to chain before the first element if it fits */
   if ((ypos >= height) && (cypos <= (ypos - height))){
    /* Fits - chain it in */
    target->next = (sprite_t*)(curr); /* Note: Intentional cast removing "volatile" */
    sprites[column] = target;
    break;
   }else{
    /* Doesn't fit, need to try next column */
    fit = false;
   }
  }
  sprite_t volatile* prev = curr;
  curr = curr->next;
  while (curr != NULL){
   cypos = curr->ypos;
   if (cypos < ypos){ /* New sprite is above */
    /* Sprite needs to chain in before this one if it doesn't overlap with
    ** either the previous or the current sprite */
    uint_fast8_t pypos   = prev->ypos;
    uint_fast8_t pheight = prev->height + 1U; /* Phantom 1px extra for mux */
    if ( (ypos  >= height ) && (cypos <= (ypos  - height )) &&
         (pypos >= pheight) && (ypos  <= (pypos - pheight)) ){
     /* Fits - chain it in */
     target->next = (sprite_t*)(curr); /* Note: Intentional cast removing "volatile" */
     prev->next = (sprite_t*)(target); /* Note: Intentional cast removing "volatile" */
    }else{
     /* Doesn't fit, need to try next column */
     fit = false;
    }
    break; /* Note: Only leaves while loop! */
   }
   prev = curr;
   curr = curr->next;
  }
  if (curr != NULL){ /* Left while loop with a break above, sort it out */
   if (fit){ break; } /* New sprite got chained in above, done */
  }else{
   /* If processing got here (while loop exited due to landing on NULL), new
   ** sprite is below all in the list - check for overlap and chain in at the
   ** end if fits */
   uint_fast8_t pypos   = prev->ypos;
   uint_fast8_t pheight = prev->height + 1U; /* Phantom 1px extra for mux */
   if ( (pypos >= pheight) && (ypos <= (pypos - pheight)) ){
    /* Fits - chain it in */
    prev->next = (sprite_t*)(target); /* Note: Intentional cast removing "volatile" */
    break;
   }else{
    /* Doesn't fit, need to try next column (if any) */
    fit = false;
   }
  }
 }

 if (fit){
  sprite_ll_sprcnt = sprcnt + 1U;
 }
 return fit;
}



bool Sprite_LL_AddBullet(uint_fast8_t xpos, uint_fast8_t ypos,
    uint_fast8_t width, uint_fast8_t height, uint_fast8_t col)
{
 /* Bullet has to be placed somewhere where it fits. This is different to
 ** sprites as the bullet lists aren't chained. Attempts to place new bullet
 ** in the column with the least items in it, moving to columns with more
 ** items if it doesn't fit. */

 ypos = (0U - ypos) & 0xFFU;

 uint_fast8_t tgidx;
 uint_fast8_t tgpos;
 uint_fast8_t column;
 bool         fit = false;
 for (tgidx = 0U; tgidx < sprite_ll_bulcols; tgidx ++){
  column = sprite_ll_bulord[tgidx];
  tgpos  = 0U;
  fit    = true;
  bullet_t volatile* blist = bullets[column];
  uint_fast8_t cypos = blist[tgpos].ypos;
  if (cypos <= ypos){ /* New bullet is above or at (handles ypos = 0 against terminator) */
   /* Bullet needs to insert before the first element if it fits */
   if ((ypos >= height) && (cypos <= (ypos - height))){
    /* Fits - done, found where to put it! */
    break;
   }else{
    /* Doesn't fit, need to try next column */
    fit = false;
   }
  }
  tgpos ++;
  while (fit){
   cypos = blist[tgpos].ypos;
   if (cypos <= ypos){ /* New bullet is above or at (handles ypos = 0 against terminator) */
    /* Bullet needs to insert before this one if it doesn't overlap with
    ** either the previous or the current bullet */
    uint_fast8_t pypos   = blist[tgpos - 1U].ypos;
    uint_fast8_t pheight = blist[tgpos - 1U].height >> 2;
    if ( (ypos  >= height ) && (cypos <= (ypos  - height )) &&
         (pypos >= pheight) && (ypos  <= (pypos - pheight)) ){
     /* Fits - done, found where to put it! */
     break; /* Note: Only leaves while loop! */
    }else{
     /* Doesn't fit, need to try next column */
     fit = false;
    }
   }
   tgpos ++;
  }
  /* Since the bullet list has a termination (ypos = 0), the insertion is
  ** always above it (so no appending to end of list). Here it either did fit
  ** or not, the did fit case needs to be handled as above only the while loop
  ** exited. */
  if (fit){ break; }
 }

 uint_fast8_t cnt;
 if (fit){
  cnt = sprite_ll_bulcnt[column];
  if (cnt >= sprite_ll_bulmax){
   /* Column found is already full, need to bail */
   fit = false;
  }
 }

 if (fit){
  bullet_t volatile* blist = bullets[column];
  height = (height << 2) | (width & 3U);
  /* Insert in a hopefully not too disruptive manner in case display interrupt
  ** strikes in */
  blist[cnt].ypos   = 0U; /* New termination */
  blist[cnt].height = 0U;
  for (uint_fast8_t pos = tgpos; pos < cnt; pos ++){
   uint_fast8_t typos   = blist[pos].ypos;
   uint_fast8_t txpos   = blist[pos].xpos;
   uint_fast8_t tcol    = blist[pos].col;
   uint_fast8_t theight = blist[pos].height;
   blist[pos].ypos   = ypos;
   blist[pos].xpos   = xpos;
   blist[pos].col    = col;
   blist[pos].height = height;
   ypos   = typos;
   xpos   = txpos;
   col    = tcol;
   height = theight;
  }
  cnt ++;
  sprite_ll_bulcnt[column] = cnt;
  /* Reorder columns by count of bullets ("bubble up" this column by swaps) */
  for (uint_fast8_t pos = (tgidx + 1U); pos < sprite_ll_bulcols; pos ++){
   uint_fast8_t colpos = sprite_ll_bulord[pos];
   if (cnt > sprite_ll_bulcnt[colpos]){
    sprite_ll_bulord[pos] = sprite_ll_bulord[pos - 1U];
    sprite_ll_bulord[pos - 1U] = colpos;
   }else{
    break;
   }
  }
 }

 return fit;
}

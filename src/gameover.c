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


#include "gameover.h"
#include "dragonmaw.h"
#include "spritecanvas.h"
#include "memsetup.h"
#include "sprite_ll.h"
#include "palette_ll.h"
#include "control_ll.h"
#include "grtext_ll.h"
#include "game.h"
#include "text.h"

#include <uzebox.h>


/** Gameover activity */
static bool         gameover_active = false;

/** Gameover sequence frame */
static uint_fast8_t gameover_frame;

/** Gameover sequence - fadeout frame */
static uint_fast8_t gameover_fadeframe;

/** Dragon slice cycle */
static uint_fast8_t gameover_slice;

/** Work buffer */
static uint8_t*     game_workbuf;



void GameOver_Start(void)
{
 MemSetup(MEMSETUP_MENU);
 uint8_t* buf = MemSetup_GetWorkArea();
 if (buf == NULL){
  return;
 }

 Sprite_LL_Init(5U, buf, 100U, NULL, 0U);
 game_workbuf = &buf[100];

 gameover_frame = 0U;
 gameover_fadeframe = 0U;
 gameover_slice = 0U;
 gameover_active = true;
}



/**
 * @brief   Draw a slice of the dragon
 *
 * Drawing the dragon is costly, so allow for splitting it up into manageable
 * pieces. Upper and lower halves, 68 pixels tall each.
 *
 * @param   slice:  Which slice to draw (0 - 1)
 * @param   scale:  Scaling (255: Full size)
 */
static void GameOver_DragonSlice(uint_fast8_t slice, uint_fast8_t scale)
{
 slice &= 1U;

 uint8_t* sprcanvas = game_workbuf;
 sprcanvas += (68U * 4U) * (uint_fast16_t)(slice);

 spritecanvas_clear(sprcanvas, 1U, 68U);
 spritecanvas_clear(sprcanvas + (136U * 4U), 1U, 68U);
 spritecanvas_clear(sprcanvas + (136U * 8U), 1U, 68U);

 if (scale == 0U){
  return;
 }

 uint8_t const* idata = img_dragonmaw_getdataptr();
 uint_fast8_t dwidth = img_dragonmaw_getwidth();
 uint_fast8_t dheight = 136U / 2U;

 uint_fast8_t height = ((dheight * (uint_fast16_t)(scale)) + 255U) >> 8;
 uint_fast8_t ystart = 0U;

 if (slice != 0U){
  idata += 68U * (uint_fast16_t)(dwidth >> 2);
 }else{
  ystart = (dheight - height);
 }

 uint_fast8_t width = ((dwidth * (uint_fast16_t)(scale)) + 255U) >> 8;
 uint_fast8_t xpos = dwidth - width;

 spritecanvas_drawscaled(
     sprcanvas, idata,
     ((uint_fast16_t)(dheight) << 8) + dwidth,
     ((uint_fast16_t)(ystart) << 8) + xpos,
     ((uint_fast16_t)(scale) << 8) + scale,
     136U);

 spritecanvas_mirror15px(sprcanvas + (136U * 8U), 68U);
}



/**
 * @brief   Output numeric data
 *
 * @param   dest:  Destination to output to
 * @param   val:   Value to output
 * @param   dig:   Number of digits
 */
static void GameOver_DecOut(uint8_t* dest, uint_fast16_t val, uint_fast8_t dig)
{
 uint_fast32_t bcd = text_bin16bcd(val);
 while (dig != 0U){
  dig --;
  uint_fast8_t cchr = (bcd >> (4U * dig)) & 0xFU;
  cchr += '0';
  *dest = cchr;
  dest ++;
 }
}



bool GameOver_Frame(void)
{
 if (!gameover_active){
  return false;
 }

 Palette_LL_FadeOut(8U);
 if (gameover_fadeframe < (256U - 8U)){

  gameover_fadeframe += 8U;
  return true;

 }else if (gameover_frame == 0U){

  /* Temporary solution, scaling is costly to render! Will figure out what to
  ** do with this later more proper. */
  SetRenderingParameters(FIRST_RENDER_LINE + 10U, 140U);
  GrText_LL_SetParams(0U, false, 0xFFU, 0x00U, 0x00U);
  uint8_t* sprcanvas = game_workbuf;
  spritecanvas_clear(sprcanvas, 3U, 136U);
  gameover_frame ++;

 }else{

  uint_fast8_t yadj = 32U;
  if (gameover_frame >= 130U){
   yadj += 10U;
  }

  Sprite_LL_Reset();
  uint_fast8_t col1 = (1U << 6) + (2U << 3) + 2U;
  uint_fast8_t col2 = (2U << 6) + (5U << 3) + 5U;
  uint_fast8_t col3 = (3U << 6) + (7U << 3) + 7U;
  uint8_t* sprcanvas = game_workbuf;
  Sprite_LL_Add(
      56U, yadj, 136U,
      col1, col2, col3,
      sprcanvas + 0U, SPRITE_LL_FLAG_RAM);
  Sprite_LL_Add(
      72U, yadj, 136U,
      col1, col2, col3,
      sprcanvas + (136U * 4U), SPRITE_LL_FLAG_RAM);
  Sprite_LL_Add(
      88U, yadj, 136U,
      col1, col2, col3,
      sprcanvas + (136U * 8U), SPRITE_LL_FLAG_RAM);
  Sprite_LL_Add(
      103U, yadj, 136U,
      col1, col2, col3,
      sprcanvas + (136U * 4U), SPRITE_LL_FLAG_RAM | SPRITE_LL_FLAG_XFLIP);
  Sprite_LL_Add(
      119U, yadj, 136U,
      col1, col2, col3,
      sprcanvas + 0U, SPRITE_LL_FLAG_RAM | SPRITE_LL_FLAG_XFLIP);


  if (gameover_frame < 128U){

   GameOver_DragonSlice(gameover_slice, gameover_frame * 2U);
   gameover_slice ++;
   gameover_frame ++;

  }else if (gameover_frame < 130U){

   GameOver_DragonSlice(gameover_slice, 0xFFU);
   gameover_slice ++;
   gameover_frame ++;

  }else if (gameover_frame < 131U){

   SetRenderingParameters(FIRST_RENDER_LINE, FRAME_LINES);
   (void)(Control_LL_Get(CONTROL_LL_ALL));
   gameover_frame ++;

  }else{

   GrText_LL_SetParams(40U, false, 0x00U, 0x00U, 0xFFU);
   uint8_t* textarea = GrText_LL_GetRowPtr(0U);
   text_fill(textarea, 0U, 160U);
   uint_fast8_t pos = 15U;
   pos += text_genstring(&textarea[pos], TEXT_GAMEOVER);
   pos = 8U + (2U * 40U);
   pos += text_genstring(&textarea[pos], TEXT_SURVIVED);
   GameOver_DecOut(&textarea[pos], Game_Score_Turns(), 3U);
   pos += 3U;
   pos += text_genstring(&textarea[pos], TEXT_SURVMONTHS);

   uint_fast8_t ctrl = Control_LL_Get(CONTROL_LL_ALL);
   if (ctrl != 0U){
    gameover_active = false;
   }

  }
 }

 return true;
}

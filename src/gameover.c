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
#include "sprite_ll.h"
#include "palette_ll.h"
#include "control_ll.h"
#include "grtext_ll.h"
#include "game.h"
#include "text.h"
#include "soundpatch.h"
#include "hiscore.h"
#include "seqalloc.h"

#include <uzebox.h>


/** High score entry first retrigger delay (frames) */
#define GAMEOVER_BUTTON_FIRSTDELAY  60U

/** High score entry continued retrigger delay (frames) */
#define GAMEOVER_BUTTON_REPEATDELAY  10U


/** Gameover activity */
static bool         gameover_active = false;

/** Gameover sequence frame */
static uint_fast8_t gameover_frame;

/** Gameover sequence - fadeout frame */
static uint_fast8_t gameover_fadeframe;

/** Dragon slice cycle */
static uint_fast8_t gameover_slice;

/** Sprite canvas where the dragon is rendered */
static uint8_t*     gameover_sprcanvas;

/** Text area buffer */
static uint8_t*     gameover_textarea;

/** Name (raw) for high-score entry. Having it here as static allows it to
 *  persist across plays which is nice, we have enough RAM! */
static uint8_t      gameover_rawname[HISCORE_NAME_MAX];

/** Cursor position for high-score entry */
static uint_fast8_t gameover_cursor;

/** Uppercase selector for high-score entry */
static bool         gameover_uppercase;

/** Score entry retrigger mask to compare against held buttons */
static uint_fast8_t gameover_retriggermask;

/** Score entry retrigger countdown */
static uint_fast8_t gameover_retriggertick;



void GameOver_Start(void)
{
 SeqAlloc_Reset();
 /* Used for the sprite canvas, 136 lines tall, 3 sprites wide, 16px (4 bytes)
 ** wide sprites. The right of the dragon is mirrored from the left. Text area
 ** joins afterwards so it can later use sprite canvas area for more text for
 ** high score entry. */
 gameover_sprcanvas = SeqAlloc((136U * 12U) + (5U * 40U));
 gameover_textarea = gameover_sprcanvas + (136U * 12U);
 /* These clear any text area and sprites, however leave the background there.
 ** The entry to the game over screen is fading out that background. */
 GrText_LL_Init(gameover_textarea, (5U * 40U), 0U);
 Sprite_LL_Init(5U, SeqAlloc(100U), 100U, NULL, 0U);
 gameover_frame = 0U;
 gameover_fadeframe = 0U;
 gameover_slice = 0U;
 gameover_cursor = 0U;
 gameover_uppercase = true;
 gameover_retriggermask = 0U;
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

 uint8_t* sprcanvas = gameover_sprcanvas;
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
 * @brief   High score entry logic
 *
 * Call every frame, does the high score entry (without affecting other areas
 * of the screen). The name is entered into gameover_rawname[].
 *
 * @return          True once the name is ready to be saved.
 */
static bool GameOver_ScoreEntry(void)
{
 uint8_t* textarea = GrText_LL_GetRowPtr(0U);
 text_fill(textarea, 0x20U, 40U);
 text_fill(textarea + 80U, 0x20U, 40U);
 uint_fast8_t endtxt = TEXT_ENDSEL;
 if (gameover_cursor < HISCORE_NAME_MAX){
  textarea[gameover_cursor + 12U] = '|';
  textarea[gameover_cursor + 80U + 12U] = '|';
  endtxt = TEXT_END;
 }
 text_genstring(&textarea[40U + 23U], endtxt);
 HiScore_DepackRaw(&gameover_rawname[0], &textarea[40U + 12U]);

 uint_fast8_t ctrl = Control_LL_Get(CONTROL_LL_ALL);
 if (ctrl != 0U){
  gameover_retriggermask = ctrl;
  gameover_retriggertick = GAMEOVER_BUTTON_FIRSTDELAY;
 }else{
  if (gameover_retriggermask != 0U){
   if (gameover_retriggermask != Control_LL_GetHolds()){
    gameover_retriggermask = 0U;
   }else if (gameover_retriggertick != 0U){
    gameover_retriggertick --;
   }else{
    gameover_retriggertick = GAMEOVER_BUTTON_REPEATDELAY;
    ctrl = gameover_retriggermask;
   }
  }
 }

 bool nameentered = false;

 if (gameover_cursor < HISCORE_NAME_MAX){

  uint_fast8_t currentchar = gameover_rawname[gameover_cursor];
  bool adjustcase = false;
  if ((ctrl & CONTROL_LL_UP) != 0U){
   currentchar = (currentchar - 1U) & 0x3FU;
   if (currentchar == HISCORE_ASCII2RAW('z')){
    /* Jump over lowercase range on an 'A' => 'z' transition */
    currentchar = (HISCORE_ASCII2RAW('a') - 1U) & 0x3FU;
   }
   adjustcase = true;
  }
  if ((ctrl & CONTROL_LL_DOWN) != 0U){
   currentchar = (currentchar + 1U) & 0x3FU;
   if (currentchar == HISCORE_ASCII2RAW('A')){
    /* Jump over uppercase range on a 'z' => 'A' transition */
    currentchar = (HISCORE_ASCII2RAW('Z') + 1U) & 0x3FU;
   }
   adjustcase = true;
  }
  if ((ctrl & CONTROL_LL_ACTION) != 0U){
   gameover_uppercase = !gameover_uppercase;
   adjustcase = true;
  }
  if (adjustcase){
   if (gameover_uppercase){
    if ((currentchar >= HISCORE_ASCII2RAW('a')) && (currentchar <= HISCORE_ASCII2RAW('z'))){
     currentchar = (currentchar - HISCORE_ASCII2RAW('a')) + HISCORE_ASCII2RAW('A');
    }
   }else{
    if ((currentchar >= HISCORE_ASCII2RAW('A')) && (currentchar <= HISCORE_ASCII2RAW('Z'))){
     currentchar = (currentchar - HISCORE_ASCII2RAW('A')) + HISCORE_ASCII2RAW('a');
    }
   }
  }
  gameover_rawname[gameover_cursor] = currentchar;

 }else{

  if ((ctrl & CONTROL_LL_ACTION) != 0U){
   /* On <END>, like in the main game's menu, confirm selection */
   nameentered = true;
  }

 }

 if ((ctrl & CONTROL_LL_LEFT) != 0U){
  if (gameover_cursor > 0){ gameover_cursor --; }
 }
 if ((ctrl & CONTROL_LL_RIGHT) != 0U){
  /* Allows walking past name characters onto <END> */
  if (gameover_cursor < HISCORE_NAME_MAX){ gameover_cursor ++; }
 }
 if (((ctrl & CONTROL_LL_ALTERN) != 0U) || ((ctrl & CONTROL_LL_MENU) != 0U)){
  /* The Menu / Alternative action buttons here are supplementary, jumping to
  ** the <END> and confirming (convenient if already the right name is there
  ** from a previous play) */
  if (gameover_cursor < HISCORE_NAME_MAX){
   gameover_cursor = HISCORE_NAME_MAX;
  }else{
   nameentered = true;
  }
 }

 return nameentered;
}



bool GameOver_Frame(void)
{
 if (!gameover_active){
  return false;
 }

 uint_fast8_t months = Game_Score_Turns();
 uint_fast16_t pop = Game_Score_Pop();

 Palette_LL_FadeOut(8U);
 if (gameover_fadeframe < (256U - 8U)){

  gameover_fadeframe += 8U;
  return true;

 }else if (gameover_frame == 0U){

  soundpatch_play(SOUNDPATCH_CH_1, SOUNDPATCH_DESC1);
  soundpatch_play(SOUNDPATCH_CH_2, SOUNDPATCH_DESC2);

  /* Temporary solution, scaling is costly to render! Will figure out what to
  ** do with this later more proper... Probably will stick permanent :p */
  SetRenderingParameters(FIRST_RENDER_LINE + 10U, 140U);
  GrText_LL_SetParams(0U, false, 0xFFU, 0x00U, 0x00U);
  uint8_t* sprcanvas = gameover_sprcanvas;
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

  if (gameover_frame >= 224U){
   uint_fast8_t flev = (255U - gameover_frame) * 8U;
   col1 = Palette_LL_FadeColour(col1, flev);
   col2 = Palette_LL_FadeColour(col2, flev);
   col3 = Palette_LL_FadeColour(col3, flev);
  }

  uint8_t* sprcanvas = gameover_sprcanvas;
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

   soundpatch_playtune(SOUNDPATCH_CH_0, SOUNDPATCH_TUNE_END);
   SetRenderingParameters(FIRST_RENDER_LINE, FRAME_LINES);
   (void)(Control_LL_Get(CONTROL_LL_ALL));
   gameover_frame ++;

  }else if (gameover_frame < 224U){

   GrText_LL_SetParams(40U, false, 0x00U, 0x00U, 0xFFU);
   uint8_t* textarea = GrText_LL_GetRowPtr(0U);
   text_fill(textarea, 0x20U, (5U * 40U));
   uint_fast8_t pos = 15U;
   pos += text_genstring(&textarea[pos], TEXT_GAMEOVER);
   pos = 9U + (2U * 40U);
   pos += text_genstring(&textarea[pos], TEXT_SURVIVED);
   pos += text_decout(&textarea[pos], months);
   pos += text_genstring(&textarea[pos], TEXT_SURVMONTHS);
   pos = 1U + (3U * 40U);
   pos += text_decout(&textarea[pos], pop);
   pos += text_genstring(&textarea[pos], TEXT_DEADPOP);

   uint_fast8_t ctrl = Control_LL_Get(CONTROL_LL_ALL);
   if (ctrl != 0U){
    gameover_frame = 224U;
   }

  }else if (gameover_frame < 254U){

   /* Dragon fades out */
   gameover_frame ++;

  }else if (gameover_frame < 255U){

   /* Reposition text mode to give high score entry where the dragon was
   ** while keeping the bottom text intact */
   Sprite_LL_Reset();
   GrText_LL_Init(gameover_textarea - (10U * 40U), (15U * 40U), 0U);
   GrText_LL_SetParams(40U + (10U * 8U), false, 0x00U, 0x00U, 0xFFU);
   uint8_t* textarea = GrText_LL_GetRowPtr(0U);
   text_fill(textarea, 0x20U, (10U * 40U));
   gameover_frame ++;
   if (gameover_rawname[0] == 0U){
    /* Fill in default name if appears to be empty (if a name is persisting
    ** from a previous play, keep it for the player) */
    HiScore_Data_FillName(&gameover_rawname[0]);
   }
   if (!HiScore_IsEligible(months, pop)){
    gameover_active = false; /* Exit here if no high score */
   }

  }else{

   if (GameOver_ScoreEntry()){
    HiScore_SendRaw(&gameover_rawname[0], months, pop);
    gameover_active = false;
   }

  }
 }

 return true;
}

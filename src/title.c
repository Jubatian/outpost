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


#include "title.h"
#include "palette_ll.h"
#include "control_ll.h"
#include "grtext_ll.h"
#include "sprite_ll.h"
#include "random.h"
#include "text.h"
#include "seqalloc.h"

#include <uzebox.h>


/** Title activity */
static bool         title_active = false;

/** Title sequence frame */
static uint_fast8_t title_frame;

/** Title sequence - fadeout frame */
static uint_fast8_t title_fadeframe;



void Title_Start(void)
{
 SeqAlloc_Reset();
 /* No sprites or bullets, this only ensures clearing whatever may have been
 ** displaying from the heap. */
 Sprite_LL_Init(5U, NULL, 0U, NULL, 0U);
 GrText_LL_Init(SeqAlloc(1000U), 1000U, 0U);
 title_frame = 0U;
 title_fadeframe = 0U;
 title_active = true;
}



bool Title_Frame(void)
{
 if (!title_active){
  return false;
 }

 Palette_LL_FadeOut(8U);
 if (title_fadeframe < (256U - 8U)){

  title_fadeframe += 8U;
  return true;

 }else if (title_frame == 0U){

  /* Display title screen */

  GrText_LL_SetParams(200U, false, 0x00U, 0x00U, 0xFFU);
  uint8_t* textarea;
  textarea = GrText_LL_GetRowPtr(0U);
  text_fill(textarea, 0x20U, 1000U);

  /* Title graphics */

  textarea = GrText_LL_GetRowPtr(9U);
  for (uint_fast8_t ypos = 0U; ypos < 2U; ypos ++){
   for (uint_fast8_t xpos = 0U; xpos < 12U; xpos ++){
    textarea[(ypos * 40U) + (xpos + 14U)] = (ypos << 4) + xpos;
   }
  }
  textarea[(2U * 40U) + (5U + 14U)] = 0x0CU;

 }else if (title_frame == 30U){

  uint8_t* textarea = GrText_LL_GetRowPtr(13U);
  uint_fast8_t pos = 10U;
  text_genstring(&textarea[pos], TEXT_TITLE);

 }else if (title_frame == 90U){

  uint8_t* textarea = GrText_LL_GetRowPtr(16U);
  uint_fast8_t pos = 11U;
  text_genstring(&textarea[pos], TEXT_TITLEDESC1);

 }else if (title_frame == 120U){

  uint8_t* textarea = GrText_LL_GetRowPtr(17U);
  uint_fast8_t pos = 9U;
  text_genstring(&textarea[pos], TEXT_TITLEDESC2);

 }else if (title_frame == 254U){

  uint8_t* textarea = GrText_LL_GetRowPtr(20U);
  uint_fast8_t pos = 18U;
  text_genstring(&textarea[pos], TEXT_VERSION);

 }else{
 }

 if (title_frame < 255U){
  title_frame ++;
 }

 uint_fast8_t ctrl = Control_LL_Get(CONTROL_LL_ALL);
 if (ctrl != 0U){
  title_active = false;
 }

 /* Consume a random number - this randomizes the beginning layout depending
 ** on the amoung of time elapsed before starting the game */
 (void)(random_get());

 return true;
}

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


#include "graphics_bg.h"



/** Background tiles */
static uint8_t graphics_bg_vram[GRAPHICS_BG_HEIGHT * GRAPHICS_BG_WIDTH];



uint8_t* Graphics_BG_GetVRAM(void)
{
 return &graphics_bg_vram[0];
}



void Graphics_BG_DrawItem(uint_fast8_t item, uint_fast8_t xpos,  uint_fast8_t ypos)
{
 if ((xpos >= (GRAPHICS_BG_WIDTH - 1U)) || (ypos >= (GRAPHICS_BG_HEIGHT - 2U))){
  return;
 }
 uint_fast16_t addr = xpos + (ypos * GRAPHICS_BG_WIDTH);
 graphics_bg_vram[addr + 0U] = item;
 graphics_bg_vram[addr + 1U] = item + 5U;
 graphics_bg_vram[addr + GRAPHICS_BG_WIDTH + 0U] = item + 10U;
 graphics_bg_vram[addr + GRAPHICS_BG_WIDTH + 1U] = item + 15U;
 graphics_bg_vram[addr + (2U * GRAPHICS_BG_WIDTH) + 0U] = item + 20U;
 graphics_bg_vram[addr + (2U * GRAPHICS_BG_WIDTH) + 1U] = item + 25U;
}



/**
 * @brief   Draw moving item
 *
 * @param   xpos:   X position of item on playfield
 * @param   ypos:   Y position of item on playfield
 */
static void Graphics_BG_DrawPF_Move(uint_fast8_t xpos, uint_fast8_t ypos)
{
 uint_fast8_t x1 = (xpos * 2U);
 uint_fast8_t y1 = (ypos * 3U);
 uint_fast8_t x2 = (Playfield_GetTargetX(xpos, ypos) * 2U);
 uint_fast8_t y2 = (Playfield_GetTargetY(xpos, ypos) * 3U);
 uint_fast8_t tick = Playfield_GetTick(xpos, ypos);
 if (tick != 0U){
  x1 = ((((uint_fast16_t)(x1)) * (256U - tick)) + (((uint_fast16_t)(x2)) * tick)) >> 8;
  y1 = ((((uint_fast16_t)(y1)) * (256U - tick)) + (((uint_fast16_t)(y2)) * tick)) >> 8;
 }
 Graphics_BG_DrawItem(Playfield_GetItem(xpos, ypos), 4U + x1, y1);
}



void Graphics_BG_DrawPlayfield(void)
{
 /* Non-moving tiles on the playfield (moving ones substituted with empty to
 ** be drawn next pass) */

 for (uint_fast8_t ypos = 1U; ypos < PLAYFIELD_HEIGHT; ypos ++){
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   uint_fast8_t act   = Playfield_GetActivity(xpos, ypos);
   uint_fast8_t item  = Playfield_GetItem(xpos, ypos);
   bool         flash = (act == PLAYFIELD_ACT_MDEL);
   bool         flup  = false;
   if (act == PLAYFIELD_ACT_MATCH){
    if (item == PLAYFIELD_GOLD){
     flash = true;
    }else{
     flup  = true;
    }
   }
   if (act == PLAYFIELD_ACT_MDEL){
    flash = true;
   }
   if ((flash) || (flup)){
    uint_fast8_t tick = Playfield_GetTick(xpos, ypos);
    if (((tick >> 6) & 1U) == 0U){
     if (flup){
      item ++;
     }else{
      item = PLAYFIELD_EMPTY;
     }
    }
   }
   Graphics_BG_DrawItem(item,  4U + (xpos * 2U), ypos * 3U);
  }
 }

 /* Moving tiles, drawn in a separate pass as they could be anywhere over the
 ** playfield (so avoid overrides by idle items). Ordering of swapping tiles
 ** are made so the first parameter of a swap is drawn above the second. */

 for (uint_fast8_t ypos = 0U; ypos < PLAYFIELD_HEIGHT; ypos ++){
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   uint_fast8_t act = Playfield_GetActivity(xpos, ypos);
   if ((act == PLAYFIELD_ACT_SWAP2) || (act == PLAYFIELD_ACT_FALL)){
    Graphics_BG_DrawPF_Move(xpos, ypos);
   }
  }
 }
 for (uint_fast8_t ypos = 0U; ypos < PLAYFIELD_HEIGHT; ypos ++){
  for (uint_fast8_t xpos = 0U; xpos < PLAYFIELD_WIDTH; xpos ++){
   uint_fast8_t act = Playfield_GetActivity(xpos, ypos);
   if (act == PLAYFIELD_ACT_SWAP1){
    Graphics_BG_DrawPF_Move(xpos, ypos);
   }
  }
 }

 /* Bounding trees */

 for (uint_fast8_t ypos = 0U; ypos < 18U; ypos += 3U){
  Graphics_BG_DrawItem(GRAPHICS_BG_FOREST,  0U, ypos);
  Graphics_BG_DrawItem(GRAPHICS_BG_FOREST,  2U, ypos);
  Graphics_BG_DrawItem(GRAPHICS_BG_FOREST, 16U, ypos);
  Graphics_BG_DrawItem(GRAPHICS_BG_FOREST, 18U, ypos);
 }
 for (uint_fast8_t xpos = 4U; xpos < 16U; xpos += 2U){
  Graphics_BG_DrawItem(GRAPHICS_BG_FOREDGE, xpos, 0U);
 }
 Graphics_BG_DrawItem(GRAPHICS_BG_FOREDGE,  0U, 18U);
 Graphics_BG_DrawItem(GRAPHICS_BG_FOREDGE,  2U, 18U);
 Graphics_BG_DrawItem(GRAPHICS_BG_FOREDGE, 16U, 18U);
 Graphics_BG_DrawItem(GRAPHICS_BG_FOREDGE, 18U, 18U);
}



uint8_t* Graphics_BG_GetTownPtr(void)
{
 return &graphics_bg_vram[(GRAPHICS_BG_HEIGHT - 4U) * GRAPHICS_BG_WIDTH];
}

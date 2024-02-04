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



#include "palette_ll.h"
#include <uzebox.h>
#include <avr/pgmspace.h>



/** Current fade level */
static uint_fast8_t palette_ll_flev;



void Palette_LL_Fade(uint_fast8_t flev)
{
 palette_ll_flev = flev;
 uint_fast16_t flevadj = (uint_fast16_t)(flev) + 1U;
 for (uint_fast8_t ppos = 0U; ppos < 15U; ppos ++){
  uint_fast8_t col = pgm_read_byte(m72_defpalette + ppos);
  uint_fast8_t red   = ((flevadj * (col & 0x07U)) >> 8) & 0x07U;
  uint_fast8_t green = ((flevadj * (col & 0x38U)) >> 8) & 0x38U;
  uint_fast8_t blue  = ((flevadj * (col & 0xC0U)) >> 8) & 0xC0U;
  palette[ppos] = red | green | blue;
 }
}



void Palette_LL_FadeIn(uint_fast8_t fladd)
{
 uint_fast8_t flev = (palette_ll_flev + fladd) & 0xFFU;
 if (flev < palette_ll_flev){
  flev = 0xFFU;
 }
 if (flev != palette_ll_flev){
  Palette_LL_Fade(flev);
 }
}



void Palette_LL_FadeOut(uint_fast8_t flsub)
{
 uint_fast8_t flev = (palette_ll_flev - flsub) & 0xFFU;
 if (flev > palette_ll_flev){
  flev = 0U;
 }
 if (flev != palette_ll_flev){
  Palette_LL_Fade(flev);
 }
}

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


#include "grtext_ll.h"
#include <uzebox.h>



/** Text row data pointer */
static uint8_t*     grtext_ll_vram = NULL;

/** Count of rows available for text */
static uint_fast8_t grtext_ll_rowmax = 0U;

/** Default boundary colour */
static uint_fast8_t grtext_ll_defcol = 0U;



void GrText_LL_Init(void* buf, uint_fast16_t len, uint_fast8_t defcol)
{
 grtext_ll_vram = (uint8_t*)(buf);
 grtext_ll_rowmax = len / 40U;
 grtext_ll_defcol = defcol;
 m72_tt_vram  = grtext_ll_vram;
 m72_tb_vram  = grtext_ll_vram;
 m72_tt_trows = grtext_ll_rowmax;
 m72_tb_trows = grtext_ll_rowmax;
 m72_tt_pad   = 1U;
 m72_tb_pad   = 1U;
 bordercolor  = defcol;
 GrText_LL_SetParams(0U, true, 0U, 0U, 0U);
}



void GrText_LL_SetParams(uint_fast8_t lines, bool ontop,
    uint_fast8_t bndcol, uint_fast8_t bgcol, uint_fast8_t fgcol)
{
 if (grtext_ll_rowmax == 0U){ lines = 0U; }
 uint_fast8_t maxhgt = GrText_LL_GetMaxLines();
 if (lines > maxhgt){ lines = maxhgt; }

 uint_fast8_t defcol = grtext_ll_defcol;
 uint_fast8_t boutcol;

 if ((lines == 0U) || (!ontop)){
  m72_tt_hgt = 0U;
  boutcol = defcol;
 }else{
  m72_tt_hgt = lines;
  m72_tt_bcol = bgcol;
  m72_tt_fcol = fgcol;
  boutcol = bndcol;
 }
 m72_tt_col = boutcol;
 m72_lt_col = boutcol;

 if ((lines == 0U) || (ontop)){
  m72_tb_hgt = 0U;
  boutcol = defcol;
 }else{
  m72_tb_hgt = lines;
  m72_tb_bcol = bgcol;
  m72_tb_fcol = fgcol;
  boutcol = bndcol;
 }
 m72_tb_col = boutcol;
 m72_lb_col = boutcol;
}



uint_fast8_t GrText_LL_GetMaxLines(void)
{
 if (grtext_ll_rowmax == 0U){ return 0U; }
 return (3U + (8U * grtext_ll_rowmax));
}



uint8_t* GrText_LL_GetRowPtr(uint_fast8_t row)
{
 uint8_t* rptr = NULL;
 if (row < grtext_ll_rowmax){ rptr = &grtext_ll_vram[row * 40U]; }
 return rptr;
}

/*
 *  Uzebox Kernel - Mode 72
 *  Copyright (C) 2016 Sandor Zsuga (Jubatian)
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
 *
 *  Uzebox is a reserved trade mark
*/

#include <avr/io.h>
#include <avr/pgmspace.h>
#include "uzebox.h"
#if (M40_C64_GRAPHICS != 0)
#include "../videoMode40/data/c64_graphics.inc"
#endif
#if (M40_C64_ALPHA != 0)
#include "../videoMode40/data/c64_alpha.inc"
#endif
#if (M40_C64_MIXED != 0)
#include "../videoMode40/data/c64_mixed.inc"
#endif
#if (M40_IBM_ASCII != 0)
#include "../videoMode40/data/ibm_ascii.inc"
#endif
#if (M40_MATTEL != 0)
#include "../videoMode40/data/mattel.inc"
#endif


/* Callback invoked by UzeboxCore.Initialize() */
void InitializeVideoMode(){

	u8 i;

	for (i = 0U; i < 16U; i++)
	{
#if (M72_DUMMY_BG == 0)
		palette[i] = pgm_read_byte(&(m72_defpalette[i]));
#else
		palette[i] = 0U;
#endif
	}

	/* Starts in text mode to allow for properly initializing a game area
	** later by the user. */

	m72_config   = 0xF0U; /* Sprites off, replaces, extends off */
	m72_tt_hgt   = 255U;  /* Top text area: max */
	m72_tb_hgt   = 0U;    /* Bottom text area: off */
	m72_tt_trows = 0U;    /* Top text area: no tile rows */
	m72_tt_pad   = 1U;    /* Top text area: 1 pixel padding */
	m72_tb_trows = 0U;    /* Bottom text area: no tile rows */
	m72_tb_pad   = 1U;    /* Bottom text area: 1 pixel padding */
	m72_tt_fcol  = 0xFFU; /* Top text area foreground: white */
	m72_tt_bcol  = 0x00U; /* Top text area background: black */
	m72_tb_fcol  = 0xFFU; /* Bottom text area foreground: white */
	m72_tb_bcol  = 0x00U; /* Bottom text area background: black */
	m72_tt_col   = 0xFFU; /* Top boundary line: white */
	m72_tb_col   = 0xFFU; /* Bottom boundary line: white */
	m72_lt_col   = 0xFFU; /* T.T boundary line: white */
	m72_lb_col   = 0xFFU; /* T.B boundary line: white */
#if   (M40_IBM_ASCII != 0)
	m72_charrom  = ((u16)(m40_ibm_ascii)) >> 8;
#elif (M40_C64_MIXED != 0)
	m72_charrom  = ((u16)(m40_c64_mixed)) >> 8;
#elif (M40_C64_ALPHA != 0)
	m72_charrom  = ((u16)(m40_c64_alpha)) >> 8;
#elif (M40_C64_GRAPHICS != 0)
	m72_charrom  = ((u16)(m40_c64_graphics)) >> 8;
#elif (M40_MATTEL != 0)
	m72_charrom  = ((u16)(m40_mattel)) >> 8;
#else
	m72_charrom  = ((u16)(&(M72_DEF_CHARROM[0]))) >> 8;
#endif
	m72_reset    = 0U;    /* Frame reset disabled */
#if (M72_USE_XPOS != 0)
	m72_xpos     = 0U;    /* Game area bg. X position: 0 */
#endif
	m72_ypos     = 0U;    /* Game area bg. Y position: 0 */
	m72_bull_cnt = 0U;    /* Count of bullet sprites */
	m72_bull_end.ypos   = 0U;
	m72_bull_end.height = 0U;

	/* Fill in sprite and bullet pointers to empty */

	for (i = 0U; i < 8U; i++)
	{
		sprites[i] = NULL;
		bullets[i] = &m72_bull_end;
	}
}

/* Callback invoked during vsync */
void VideoModeVsync(){
}

/* Callback invoked by UzeboxCore.Initialize() */
void DisplayLogo(){
}

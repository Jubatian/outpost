/*
 *  Uzebox Kernel - Video Mode 72
 *  Copyright (C) 2017 Sandor Zsuga (Jubatian)
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

/**
 * ===========================================================================
 *
 * Global defines for video mode 72
 *
 * ===========================================================================
 */

#pragma once

#define VMODE_ASM_SOURCE   "videoMode72/videoMode72.s"
#define VMODE_C_SOURCE     "videoMode72/videoMode72.c"
#define VMODE_C_PROTOTYPES "videoMode72/videoMode72.h"
#define VMODE_FUNC         sub_video_mode72


/* Definitions are for a normal scrolling game area */

#define TILE_HEIGHT        8
#define TILE_WIDTH         8
#define SCREEN_TILES_H     21
#ifndef SCREEN_TILES_V
#define SCREEN_TILES_V     25
#endif
#define VRAM_TILES_H       SCREEN_TILES_H
#ifndef VRAM_TILES_V
#define VRAM_TILES_V       SCREEN_TILES_V
#endif

#ifndef FIRST_RENDER_LINE
#define FIRST_RENDER_LINE  31
#endif

#ifndef FRAME_LINES
#define FRAME_LINES        ((SCREEN_TILES_V * TILE_HEIGHT) + 2)
#endif

/* VRAM characteristics */

#define VRAM_SIZE          (VRAM_TILES_H * VRAM_TILES_V)
#define VRAM_ADDR_SIZE     1
#define VRAM_PTR_TYPE      unsigned char

/* Constrain to VSync mixer */

#if SOUND_MIXER == MIXER_TYPE_INLINE
#error Invalid compilation option (-DSOUND_MIXER=1): Inline audio mixer not supported for video mode 72
#endif

/*
** Line buffer location. Low 8 bits must be zero, the full RAM bank is
** used. This memory area may be used outside the video frame for any purpose,
** but the video frame will override it. The default solution places it on the
** top, moving the stack below.
*/

#ifndef M72_LBUFFER_OFF
#define UZEBOX_STACK_TOP   0x0FFF
#define M72_LBUFFER_OFF    0x1000
#endif

/*
** The sprite modes to compile in. Use only the modes you actually need to
** save ROM space. This is a bitmask, for example setting bit 0 enables sprite
** mode 0.
*/
#ifndef M72_SPRITE_MODES
#define M72_SPRITE_MODES   0x0001
#endif

/*
** Maximal height used, set this to the maximum you want to write in
** render_lines_count. This determines the size of certain allocations.
*/

#ifndef M72_MAXHEIGTH
#define M72_MAXHEIGTH      FRAME_LINES
#endif

/*
** Enable reloading the logical row address for every game area scanline. This
** uses the same buffer like scanline recoloring (so the two features can not
** coexist within the game area, there if this is enabled, scanline recoloring
** will behave as if it was turned off). Reloading the logical row address is
** useful for independently scrolling vertical slices, useful for certain
** types of games (such as racers to create the illusion of hills).
*/

#ifndef M72_SLINE_ENA
#define M72_SLINE_ENA      0
#endif
#ifdef  M72_SCOLOR_ENA
#if ((M72_SCOLOR_ENA == 0) && (M72_SLINE_ENA != 0))
#error You must not turn off M72_SCOLOR_ENA if you want to use M72_SLINE_ENA
#endif
#endif

/*
** Enable recoloring on each scanline. The background color or the border
** color may be replaced using this feature.
*/
#ifndef M72_SCOLOR_ENA
#define M72_SCOLOR_ENA     M72_SLINE_ENA
#endif

/*
** Allow specifying tile start address for every scanline instead of every
** row including pixel precise horizontal scrolling. This is useful for
** independently scrolling scanlines, for example to create per scanline
** parallax effects. It needs 2 bytes of RAM for every scanline.
*/
#ifndef M72_USE_LINE_ADDR
#define M72_USE_LINE_ADDR  0
#endif

/*
** Number of scanlines used when M72_USE_LINE_ADDR is enabled. Set this
** according to which logical scanlines you will use, if you need to use all
** (such as to realize vertical scrolling), set it to 512. If you use
** M72_SLINE_ENA, set it according to the scanlines you will actually use.
*/
#ifndef M72_LINE_ADDR_ROWS
#define M72_LINE_ADDR_ROWS M72_MAXHEIGHT
#endif

/*
** Use X position. This disables the parallax scrolling capability to offer a
** simpler interface (you can specify an X shift to the left by 0 - 7 pixels
** in m72_xpos instead of having to write all VRAM row offsets).
*/
#ifndef M72_USE_XPOS
#define M72_USE_XPOS       0
#endif

/*
** The name of an 512 byte aligned section if you use one. By defining such a
** section, you can pack Mode 72's 512 byte aligned data together, saving ROM
** space.
*/
#ifndef M72_ALIGNED_SEC
#define M72_ALIGNED_SEC    .text.align512
#endif

/*
** Use dummy (empty) background.
*/
#ifndef M72_DUMMY_BG
#define M72_DUMMY_BG       0
#endif

/*
** Pointer to default character ROM image for text mode. If you use a single
** character ROM generated by the charrom generator, you don't need to touch
** this. You may also use Mode 40's definitions to get tilesets.
*/
#ifndef M72_DEF_CHARROM
#define M72_DEF_CHARROM    m72_charrom_data
#endif

/*
** Highest offset of stack to use after a reset (m72_reset set to non-null, so
** upon every frame the main program restarts with a given function). You
** should probably leave this alone (pointing at the line buffer's bank, thus
** saving RAM when using the reset feature).
*/
#ifndef M72_RESET_STACK
#define M72_RESET_STACK    (M72_LBUFFER_OFF + 255)
#endif

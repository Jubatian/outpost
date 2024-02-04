/*
 *  Uzebox Kernel - Mode 72
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
 * Function prototypes for video mode 72
 * ===========================================================================
 */

#pragma once

#include <avr/io.h>

/* Normal sprite structure. Chained list */

typedef struct sprite_s{
 u8  ypos;    /* Sprite Y position, negated, 32 (224): Top edge */
 u8  height;  /* Sprite height */
 u16 off;     /* Sprite address; bit15: Mirror flag */
 u8  xpos;    /* Sprite X position, 16: Left edge */
 u8  col1;    /* Color of '1' pixels */
 u8  col2;    /* Color of '2' pixels */
 u8  col3;    /* Color of '3' pixels */
 struct sprite_s* next; /* Next sprite, NULL for end of list */
}sprite_t;

/* Bullet sprite structure */

typedef struct{
 u8  ypos;    /* Bullet Y position, negated, 32 (224): Top edge */
 u8  xpos;    /* Bullet X position, 16: Left edge */
 u8  col;     /* Color */
 u8  height;  /* Width (bit0-1: 1-4 px) and Height (bit2-7: 1 - 64 px) */
}bullet_t;

/* Provided by VideoMode72.s */

extern volatile sprite_t* sprites[8];
extern volatile bullet_t* bullets[8];
extern volatile u8  palette[16];
extern volatile u8  bordercolor;
#if (M72_SCOLOR_ENA != 0)
extern volatile u8  m72_scolor[M72_MAXHEIGHT];
#endif
#if (M72_USE_LINE_ADDR != 0)
extern volatile u16 m72_rowoff[M72_LINE_ADDR_ROWS];
#else
extern volatile u16 m72_rowoff[32];
#endif
extern volatile u8  m72_config;
#if (M72_USE_XPOS != 0)
extern volatile u8  m72_xpos;
#endif
extern volatile u8  m72_ypos;
extern volatile u8  m72_charrom;

extern volatile u8* m72_tt_vram;
extern volatile u8  m72_tt_trows;
extern volatile u8  m72_tt_pad;
extern volatile u8  m72_tt_hgt;
extern volatile u8  m72_tt_bcol;
extern volatile u8  m72_tt_fcol;
extern volatile u8  m72_tt_col;
extern volatile u8  m72_lt_col;

extern volatile u8* m72_tb_vram;
extern volatile u8  m72_tb_trows;
extern volatile u8  m72_tb_pad;
extern volatile u8  m72_tb_hgt;
extern volatile u8  m72_tb_bcol;
extern volatile u8  m72_tb_fcol;
extern volatile u8  m72_tb_col;
extern volatile u8  m72_lb_col;

extern volatile u8  m72_bull_cnt;
extern bullet_t     m72_bull_end;

extern volatile u16 m72_reset;

extern void M72_Halt(void);
extern void M72_Seq(void);

/* Provided by the user tileset & character ROM */

extern const u8  m72_defpalette[];
extern const u16 m72_deftilerows[];
extern const u8  M72_DEF_CHARROM[];

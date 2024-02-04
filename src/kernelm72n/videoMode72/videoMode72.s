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

;=============================================================================
;
; Video mode 72
;
; Code tiles + "Hard" sprites mode, VSync mixer only
;
; 160 pixels width (7 cycles / pixel, same as NTSC C64 full width)
; 320 pixels wide 1bpp text mode alternative (3.5 cycles / pixel)
; 8 pixels / tile (20 tiles H-scrolling, 40 tiles in text mode)
; Tiles can have up to 16 colors selected from palette
; 160 pixels wide mode can have sprites overlayed
; Up to 20 3 color + transparency sprites in various configurations
;
;=============================================================================
;
; Graphics frame structure:
;
; Px0     Px16                                                   Px176   Px192
; +-------+----------------------------------------------------------+-------+
; |       | Top boundary line: m72_tt_col                            |       |
; |     --+----------------------------------------------------------+--     |
; |       |                                                          |       |
; |       | Text mode, top (40 tiles wide)                           |       |
; |       | m72_tt_vram:  Pointer to VRAM for this part              |       |
; |       | m72_tt_trows: Number of tile rows this part has          |       |
; |       | m72_tt_pad:   Padding in pixels to T.T boundary line     |       |
; |       | m72_tt_hgt:   Height in pixels including padding and     |       |
; |       |               Top boundary line                          |       |
; |       | m72_tt_bcol:  Background color                           |       |
; |       | m72_tt_fcol:  Foreground color                           |       |
; |       |                                                          |       |
; |     --+----------------------------------------------------------+--     |
; |       | T.T boundary line: m72_lt_col                            |       |
; |     --+----------------------------------------------------------+--     |
; |       |                                                          |       |
; |       | Game area (20 visible tiles, 21 logical tiles)           |       |
; |       | palette:      16 color palette (col. 15 is border color) |       |
; |       | m72_rowoff:   Defines the VRAM for this part             |       |
; |       |                                                          |       |
; |     --+----------------------------------------------------------+--     |
; |       | T.B boundary line: m72_lb_col                            |       |
; |     --+----------------------------------------------------------+--     |
; |       |                                                          |       |
; |       | Text mode, bottom (40 tiles wide)                        |       |
; |       | m72_tb_vram:  Pointer to VRAM for this part              |       |
; |       | m72_tb_trows: Number of tile rows this part has          |       |
; |       | m72_tb_pad:   Padding in pixels to T.B boundary line     |       |
; |       | m72_tb_hgt:   Height in pixels including padding and     |       |
; |       |               Bottom boundary line                       |       |
; |       | m72_tb_bcol:  Background color                           |       |
; |       | m72_tb_fcol:  Foreground color                           |       |
; |       |                                                          |       |
; |     --+----------------------------------------------------------+--     |
; |       | Bottom boundary line: m72_tb_col                         |       |
; +-------+----------------------------------------------------------+-------+
;
; The T.T & T.B boundary lines are always visible.
;
; Game area's logical size is render_lines_count - 2, located between the T.T
; and T.B boundary lines. The text modes cover it up when their respective
; heights are nonzero. First visible line of the game area (without overlays)
; is 32.
;
;=============================================================================
;
; The mode needs a code tileset and palette source provided by the user.
;
; The following global symbols are required:
;
; m72_defpalette:
;     16 bytes at arbitrary location in ROM, defining the default palette.
;     This palette is loaded upon initialization into palette.
;
; m72_deftilerows:
;     A generated tileset which is used for background.
;
;=============================================================================



;
; sprite_t* sprites[];
;
; 10 sprite entry pointers. Their structure is as follows:
; ypos:   Y position, negated, 32 (224): Top edge
; height: Sprite height
; offlo:  Sprite start offset (low)
; offhi:  Sprite start offset (high), X Mirror flag on bit15
; xpos:   X position, 16: Left edge
; col1:   Color of '1' pixels (BBGGGRRR byte)
; col2:   Color of '2' pixels (BBGGGRRR byte)
; col3:   Color of '3' pixels (BBGGGRRR byte)
; nextlo: Next sprite pointer (low)
; nexthi: Next sprite pointer (high)
;
.global sprites

;
; bullet_t* bullets[];
;
; 10 bullet entry pointers. Their structure is as follows:
; ypos:   Y position, negated, 32 (224): Top edge
; xpos:   X position, 16: Left edge
; col:    Color (BBGGGRRR byte)
; height: Width (bit0-1: 1-4 px) and Height (bit2-7: 1 - 64 px)
;
.global bullets

;
; unsigned char palette[];
;
; 16 bytes specifying the 16 colors potentially used by the tiles. The colors
; are in BBGGGRRR format (normal Uzebox colors).
;
.global palette

;
; unsigned char bordercolor;
;
; The border color, same as palette[15]. Use to set a global color for the
; horizontal borders.
;
.global bordercolor

#if (M72_SCOLOR_ENA != 0)
;
; unsigned char m72_scolor[];
;
; Scanline color replacements, as many bytes as many scanlines are used. They
; are used to replace colors on every line based on the settings in
; m72_config.
;
.global m72_scolor
#endif

;
; unsigned int m72_rowoff[];
;
; Row start offsets in pixels (bits 0-11: RAM offset; bits 12-14: Scroll).
; This can be used to set up the VRAM for the game area background. Normally
; it has 32 entries to set up 32 individual tile rows, but with
; M72_USE_LINE_ADDR it may be configured to have as many entries as many
; scanlines are used.
;
.global m72_rowoff

;
; unsigned char m72_config;
;
; Selects configuration & sprite mode.
;
; bit 0: Ignore boundary line colors if set (uses border color instead)
; bit 1: Game area color 0 replace on every scanline if set
; bit 2: Border color replace / extend on every scanline if set
; bit 3: Text area background color replace on every scanline if set
; bit 4-7: Sprite mode to use
;
; If border color replace is set, on boundary lines, the boundary line color
; (m72_lt_col and m72_lb_col) will extend into the borders.
;
; Border color replace / extend has effect even without M72_SCOLOR_ENA: this
; case in the game area, color 0 will replace the normal border color (so the
; normal border color will only be used for text overlays).
;
; Ignoring boundary line colors may be useful in combination with
; M72_SCOLOR_ENA, allowing to color them using the color replaces.
;
.global m72_config

#if (M72_USE_XPOS != 0)
;
; unsigned char m72_xpos;
;
; X position for game area background.
;
; Sets the left shift by 0 - 7 pixels for the game area background (only if
; this feature is enabled, otherwise X fine scrolling is done by the
; m72_rowoff offset table).
;
.global m72_xpos
#endif

;
; unsigned char m72_ypos;
;
; Y position for game area background.
;
; Sets the topmost row in the game area, can be used for Y scrolling.
;
.global m72_ypos

;
; unsigned char m72_charrom;
;
; 2K Character generator ROM pointer for text modes. Each row takes 256 bytes,
; pixels within bytes are ordered so leftmost pixels are generated by the
; higher bits. Selects a 256 byte bank where the character ROM begins.
;
.global m72_charrom

;
; unsigned int m72_reset;
;
; Reset vector where the video frame render will reset upon return with an
; empty stack. It should be a function with void parameters and void return.
; If this is set zero, the feature is turned off. If the feature is used, then
; the stack will be reset to M72_RESET_STACK (by default this is the line
; buffer's bank, thus freeing the previous location of the stack).
;
.global m72_reset

;
; unsigned char m72_bull_cnt;
;
; Count of bullet sprites. This affects the sprite engines: increasing bullet
; count decreases available main sprites.
;
.global m72_bull_cnt

;
; bullet_t m72_bull_end;
;
; A prepared empty bullet, can be used to terminate bullet lists. By default
; bullet lists point to this so no bullets are displayed.
;
.global m72_bull_end

;
; void M72_Halt(void);
;
; Halts program execution. Use with reset (m72_reset non-null) to terminate
; components which are supposed to be terminated by a new frame. This is not
; required, but by the C language a function call is necessary to enforce a
; sequence point (so every side effect completes before the call including
; writes to any globals).
;
.global M72_Halt

;
; void M72_Seq(void);
;
; Sequence point. Use with reset (m72_reset non-null) to enforce a sequence
; point, so everything is carried out which is before. This is not required,
; but by the C language a function call is necessary to enforce a sequence
; point (so every side effect completes before the call including writes to
; any globals).
;
.global M72_Seq

;
; Top text area parameters. See Graphics frame structure.
;
.global m72_tt_vram
.global m72_tt_trows
.global m72_tt_pad
.global m72_tt_hgt
.global m72_tt_bcol
.global m72_tt_fcol
.global m72_tt_col
.global m72_lt_col

;
; Bottom text area parameters. See Graphics frame structure.
;
.global m72_tb_vram
.global m72_tb_trows
.global m72_tb_pad
.global m72_tb_hgt
.global m72_tb_bcol
.global m72_tb_fcol
.global m72_tb_col
.global m72_lb_col



; IO port offsets

#define PIXOUT         VIDEO_PORT
#define GPR0           _SFR_IO_ADDR(GPIOR0)
#define GPR1           _SFR_IO_ADDR(GPIOR1)
#define GPR2           _SFR_IO_ADDR(GPIOR2)
#define STACKL         0x3D
#define STACKH         0x3E
#define AUDOUT         _SFR_MEM_ADDR(OCR2A)
#define SYNC           _SFR_IO_ADDR(SYNC_PORT)
#define SYNC_P         SYNC_PIN

; Offsets within user accessible sprite descriptors

#define SP_OFF         0
#define SP_BANK        1
#define SP_XPOS        2
#define SP_YPOS        3
#define SP_HEIGHT      4
#define SP_COL1        5
#define SP_COL2        6
#define SP_COL3        7

; Various variables at the line buffer's end
; Line buffer:
;   0 -  15: Non-visible left pixels
;  16 - 175: Visible pixels (160)
; 176 - 191: Non-visible right pixels

; Sprite processing code
#define LB_SPR         254
; Top of video stack (init STACKL to this - 1), 4 bytes (2 call levels)
#define LB_STACK       254
; Globals
#define LB_TT_VRAM     192
#define LB_TT_TROWS    194
#define LB_TT_PAD      195
#define LB_TT_HGT      196
#define LB_TT_BCOL     197
#define LB_TT_FCOL     198
#define LB_TT_COL      199
#define LB_LT_COL      200
#define LB_TB_VRAM     201
#define LB_TB_TROWS    203
#define LB_TB_PAD      204
#define LB_TB_HGT      205
#define LB_TB_BCOL     206
#define LB_TB_FCOL     207
#define LB_TB_COL      208
#define LB_LB_COL      209
#define LB_RESET       210
#define LB_BULL_CNT    212
#define LB_BULL_END    213
; Bullet pointers
#define LB_BUPT        219
; Saved registers
#define LB_S_GP0       235
#define LB_S_GP1       236
#define LB_S_GP2       237
#define LB_S_SPL       238
#define LB_S_SPH       239
; Top text area calculated dimensions
#define LB_TT_CTBL     240
#define LB_TT_CEXT     241
#define LB_TT_CROW     242
#define LB_TT_CPAD     243
#define LB_TT_CBBL     244
; Bottom text area calculated dimensions
#define LB_TB_CTBL     245
#define LB_TB_CEXT     246
#define LB_TB_CROW     247
#define LB_TB_CPAD     248
#define LB_TB_CBBL     249

; Full variable offsets
#define V_BUPT         (M72_LBUFFER_OFF + LB_BUPT)
#define V_S_GP0        (M72_LBUFFER_OFF + LB_S_GP0)
#define V_S_GP1        (M72_LBUFFER_OFF + LB_S_GP1)
#define V_S_GP2        (M72_LBUFFER_OFF + LB_S_GP2)
#define V_S_SPL        (M72_LBUFFER_OFF + LB_S_SPL)
#define V_S_SPH        (M72_LBUFFER_OFF + LB_S_SPH)
#define V_TT_CTBL      (M72_LBUFFER_OFF + LB_TT_CTBL)
#define V_TT_CEXT      (M72_LBUFFER_OFF + LB_TT_CEXT)
#define V_TT_CROW      (M72_LBUFFER_OFF + LB_TT_CROW)
#define V_TT_CPAD      (M72_LBUFFER_OFF + LB_TT_CPAD)
#define V_TT_CBBL      (M72_LBUFFER_OFF + LB_TT_CBBL)
#define V_TB_CTBL      (M72_LBUFFER_OFF + LB_TB_CTBL)
#define V_TB_CEXT      (M72_LBUFFER_OFF + LB_TB_CEXT)
#define V_TB_CROW      (M72_LBUFFER_OFF + LB_TB_CROW)
#define V_TB_CPAD      (M72_LBUFFER_OFF + LB_TB_CPAD)
#define V_TB_CBBL      (M72_LBUFFER_OFF + LB_TB_CBBL)



.section .bss

	; Globals

	sprites:       .space 2 * 8      ; Sprite pointers
	bullets:       .space 2 * 8      ; Bullet pointers
	palette:       .space 15         ; Game area palette
	bordercolor:   .space 1          ; Border color (last index of game area pal.)
#if (M72_SCOLOR_ENA != 0)
	m72_scolor:    .space M72_MAXHEIGHT
#endif
#if (M72_USE_LINE_ADDR != 0)
	m72_rowoff:    .space (M72_LINE_ADDR_ROWS * 2)
#else
	m72_rowoff:    .space 64
#endif

	m72_config:    .space 1          ; Mode 72 configuration
#if (M72_USE_XPOS != 0)
	m72_xpos:      .space 1          ; X position for game background
#endif
	m72_ypos:      .space 1          ; Y position for game background
	m72_charrom:   .space 1          ; Character generator ROM address high

.equ	m72_tt_vram,   (M72_LBUFFER_OFF + LB_TT_VRAM)
.equ	m72_tt_trows,  (M72_LBUFFER_OFF + LB_TT_TROWS)
.equ	m72_tt_pad,    (M72_LBUFFER_OFF + LB_TT_PAD)
.equ	m72_tt_hgt,    (M72_LBUFFER_OFF + LB_TT_HGT)
.equ	m72_tt_bcol,   (M72_LBUFFER_OFF + LB_TT_BCOL)
.equ	m72_tt_fcol,   (M72_LBUFFER_OFF + LB_TT_FCOL)
.equ	m72_tt_col,    (M72_LBUFFER_OFF + LB_TT_COL)
.equ	m72_lt_col,    (M72_LBUFFER_OFF + LB_LT_COL)

.equ	m72_tb_vram,   (M72_LBUFFER_OFF + LB_TB_VRAM)
.equ	m72_tb_trows,  (M72_LBUFFER_OFF + LB_TB_TROWS)
.equ	m72_tb_pad,    (M72_LBUFFER_OFF + LB_TB_PAD)
.equ	m72_tb_hgt,    (M72_LBUFFER_OFF + LB_TB_HGT)
.equ	m72_tb_bcol,   (M72_LBUFFER_OFF + LB_TB_BCOL)
.equ	m72_tb_fcol,   (M72_LBUFFER_OFF + LB_TB_FCOL)
.equ	m72_tb_col,    (M72_LBUFFER_OFF + LB_TB_COL)
.equ	m72_lb_col,    (M72_LBUFFER_OFF + LB_LB_COL)

.equ	m72_reset,     (M72_LBUFFER_OFF + LB_RESET)

.equ	m72_bull_cnt,  (M72_LBUFFER_OFF + LB_BULL_CNT)
.equ	m72_bull_end,  (M72_LBUFFER_OFF + LB_BULL_END)

	; Locals

	v_sprd:        .space 10 * 8     ; Copied off sprite data

.section .text




;
; Video frame renderer
;

sub_video_mode72:

;
; Entry happens in cycle 467.
;

	; Store away GPIO regs & stack, prepare video stack

	in    r0,      GPR0
	sts   V_S_GP0, r0
	in    r0,      GPR1
	sts   V_S_GP1, r0
	in    r0,      GPR2
	sts   V_S_GP2, r0
	in    r0,      STACKH
	sts   V_S_SPH, r0
	in    r0,      STACKL
	sts   V_S_SPL, r0
	ldi   r18,     hi8(M72_LBUFFER_OFF)
	out   STACKH,  r18
	ldi   r18,     LB_STACK - 1
	out   STACKL,  r18     ; ( 486)

	; Prepare main sprites for each column

	ldi   YL,      lo8(v_sprd)
	ldi   YH,      hi8(v_sprd)
	ldi   XL,      lo8(sprites)
	ldi   XH,      hi8(sprites)
	ldi   r24,     8       ; ( 491)
pre_ls:
	ld    r25,     X+      ; ( 2)
	std   Y + 40,  r25
	ld    r25,     X+
	std   Y + 41,  r25
	adiw  YL,      2       ; (10)
	rcall sp_next          ; (68)
	rjmp  .
	dec   r24
	brne  pre_ls           ; (73) (583; 1074)

	; Copy off bullet entry list

	ldi   ZL,      lo8(V_BUPT)
	ldi   ZH,      hi8(V_BUPT)
	ldi   XL,      lo8(bullets)
	ldi   XH,      hi8(bullets)
	ldi   r24,     8       ; (1079)
pre_lb:
	ld    r25,     X+
	st    Z+,      r25
	ld    r25,     X+
	st    Z+,      r25
	dec   r24
	brne  pre_lb           ; (11) (87; 1166)

	; Load mode 72 config & selected sprite mode's entry point

	lds   ZL,      m72_config
	out   GPR0,    ZL
	andi  ZL,      0xF0
	swap  ZL
	mov   r20,     ZL
	lsl   r20
	add   ZL,      r20     ; (1175) ZL = Mode * 3
	in    XH,      STACKH
	ldi   XL,      LB_SPR
	clr   ZH
	subi  ZL,      lo8(-(pm(pre_ldspm)))
	sbci  ZH,      hi8(-(pm(pre_ldspm)))
	ijmp                   ; (1181)

pre_ldspm:
#if ((M72_SPRITE_MODES & 0x0001) != 0)
	ldi   r24,     lo8(pm(m72_sp0))
	ldi   r25,     hi8(pm(m72_sp0))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0002) != 0)
	ldi   r24,     lo8(pm(m72_sp1))
	ldi   r25,     hi8(pm(m72_sp1))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0004) != 0)
	ldi   r24,     lo8(pm(m72_sp2))
	ldi   r25,     hi8(pm(m72_sp2))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0008) != 0)
	ldi   r24,     lo8(pm(m72_sp3))
	ldi   r25,     hi8(pm(m72_sp3))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0010) != 0)
	ldi   r24,     lo8(pm(m72_sp4))
	ldi   r25,     hi8(pm(m72_sp4))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0020) != 0)
	ldi   r24,     lo8(pm(m72_sp5))
	ldi   r25,     hi8(pm(m72_sp5))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0040) != 0)
	ldi   r24,     lo8(pm(m72_sp6))
	ldi   r25,     hi8(pm(m72_sp6))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0080) != 0)
	ldi   r24,     lo8(pm(m72_sp7))
	ldi   r25,     hi8(pm(m72_sp7))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0100) != 0)
	ldi   r24,     lo8(pm(m72_sp8))
	ldi   r25,     hi8(pm(m72_sp8))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0200) != 0)
	ldi   r24,     lo8(pm(m72_sp9))
	ldi   r25,     hi8(pm(m72_sp9))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0400) != 0)
	ldi   r24,     lo8(pm(m72_sp10))
	ldi   r25,     hi8(pm(m72_sp10))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x0800) != 0)
	ldi   r24,     lo8(pm(m72_sp11))
	ldi   r25,     hi8(pm(m72_sp11))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x1000) != 0)
	ldi   r24,     lo8(pm(m72_sp12))
	ldi   r25,     hi8(pm(m72_sp12))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x2000) != 0)
	ldi   r24,     lo8(pm(m72_sp13))
	ldi   r25,     hi8(pm(m72_sp13))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
#if ((M72_SPRITE_MODES & 0x4000) != 0)
	ldi   r24,     lo8(pm(m72_sp14))
	ldi   r25,     hi8(pm(m72_sp14))
	rjmp  pre_ldspe
#else
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe
#endif
	ldi   r24,     lo8(pm(m72_sp15))
	ldi   r25,     hi8(pm(m72_sp15))
	rjmp  pre_ldspe

pre_ldspe:
	st    X+,      r25
	st    X+,      r24     ; (1189)

	; Padding

	WAIT  r24,     179     ; (1368)

	; Load border color into r17

	lds   r17,     bordercolor ; (1370)

	; Precalculate heights of various areas

	lds   r20,     render_lines_count ; (1372)

	; Top text area and the Top boundary line. Normally the T.T boundary
	; line should belong to the top text area, but it is rather mixed up
	; with the Top boundary line as a boundary line is needed to prepare
	; the game area (which is the T.T boundary line just above it).

	lds   r21,     m72_tt_pad
	lds   r22,     m72_tt_trows
	lds   r23,     m72_tt_hgt
	lsl   r22
	lsl   r22
	lsl   r22              ; Get line count from tile row count
	subi  r20,     1       ; Max. height allowed for top text area
	brcc  .+2              ; (1383 / 1384)
	rjmp  fr_zero_height   ; (1385) Zero height frame, nothing to render
	cp    r20,     r23
	brcc  .+2
	mov   r23,     r20     ; Limit to this height
	mov   r18,     r23
	ldi   r19,     1       ; Size of Top boundary line
	cp    r18,     r19
	brcc  .+2
	mov   r19,     r18
	sub   r18,     r19
	sts   V_TT_CTBL, r19   ; Top boundary line: Either 1 or 0 lines
	ldi   r19,     1
	sts   V_TT_CBBL, r19   ; T.T boundary line: Always 1 line
	cp    r18,     r21
	brcc  .+2
	mov   r21,     r18     ; Padding lines
	sub   r18,     r21
	sts   V_TT_CPAD, r21
	cp    r18,     r22
	brcc  .+2
	mov   r22,     r18     ; Tile row lines
	sub   r18,     r22
	sts   V_TT_CROW, r22
	sts   V_TT_CEXT, r18   ; Extra lines beyond tile row lines
	mov   r16,     r23
	inc   r16              ; Begin line of game area
	sub   r20,     r23     ; (1415) Remaining lines from the frame

	; T.B boundary line: should only be missing if there are no more
	; scanlines to render (Z flag set if so)

	ldi   r19,     1
	brne  .+2
	ldi   r19,     0       ; T.B boundary line: None if no more lines
	sts   V_TB_CTBL, r19
	breq  .+2
	dec   r20              ; (1422) One less lines remaining

	; Bottom text area and T.B boundary line.

	lds   r21,     m72_tb_pad
	lds   r22,     m72_tb_trows
	lds   r23,     m72_tb_hgt
	lsl   r22
	lsl   r22
	lsl   r22              ; Get line count from tile row count
	cp    r20,     r23
	brcc  .+2
	mov   r23,     r20     ; Limit to this height
	mov   r18,     r23
	ldi   r19,     1       ; Size of Bottom boundary line
	cp    r18,     r19
	brcc  .+2
	mov   r19,     r18
	sub   r18,     r19
	sts   V_TB_CBBL, r19   ; Bottom boundary line: Either 1 or 0 lines
	cp    r18,     r21
	brcc  .+2
	mov   r21,     r18     ; Padding lines
	sub   r18,     r21
	sts   V_TB_CPAD, r21
	cp    r18,     r22
	brcc  .+2
	mov   r22,     r18     ; Tile row lines
	sub   r18,     r22
	sts   V_TB_CROW, r22
	sts   V_TB_CEXT, r18   ; Extra lines beyond tile row lines
	sub   r20,     r23     ; (1457) Remaining lines: Game area height

	; Game area: all the remaining size.

	add   r16,     r20
	subi  r16,     0x100 - 31
	out   GPR2,    r16     ; (1460) Game area end point

	; Prepare scanline counter.

	ldi   r18,     31      ; (1461)

	; Transfer

	WAIT  r20,     236     ; (1697) Fall through to Top boundary line



;
; Top boundary line.
;
; Enters in cycle 1697.
;
tt_tbl_entry:

	lds   r16,     V_TT_CTBL
	cpi   r16,     0
	brne  .+2              ; (1701 / 1702)
	rjmp  tt_ext_entry     ; (1703) None to draw

	; Draw top boundary line

	WAIT  r20,     97      ; (1799)

	; Load color

	lds   r20,     m72_tt_col
	rcall m72_bl_colors    ; (1820 = 0) (19 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, then go on to top text area extra lines

	inc   r18              ; (1703) Fall through to text area extra lines



;
; Top text area extra lines (beyond tile row count).
;
; Enters in cycle 1703.
;
tt_ext_entry:

	lds   r16,     V_TT_CEXT
	cpi   r16,     0
	brne  tt_ext_loope     ; (1707 / 1708)
	rjmp  tt_row_entry     ; (1709) None to draw: go on to rows

	; Draw extra lines

tt_ext_loop:

	WAIT  r20,     2       ; (1708)

tt_ext_loope:

	WAIT  r20,     91      ; (1799)

	; Load colors

	rcall m72_tt_colors    ; (1820 = 0) (21 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, loop

	inc   r18
	dec   r16
	brne  tt_ext_loop      ; (1705 / 1706)

	WAIT  r20,     4       ; (1709) Fall through to text area tile rows



;
; Top text area tile rows.
;
; Enters in cycle 1709.
;
tt_row_entry:

	lds   r16,     V_TT_CROW
	cpi   r16,     0
	brne  tt_row_prep      ; (1713 / 1714)
	rjmp  tt_pad_entry     ; (1715) None to draw: go on to padding

	; Draw extra lines

tt_row_prep:

	lds   YL,      m72_tt_vram + 0
	lds   YH,      m72_tt_vram + 1
	lds   r19,     m72_tt_trows
	lsl   r19
	lsl   r19
	lsl   r19
	sub   r19,     r16     ; (1724) Scanline in tile row to start at
	mov   r22,     r19
	lsr   r22
	lsr   r22
	lsr   r22
	ldi   r23,     40
	mul   r22,     r23
	add   YL,      r0
	adc   YH,      r1      ; (1733) VRAM offset to start at
	rjmp  tt_row_loope     ; (1735)

tt_row_loop:

	WAIT  r20,     29      ; (1735)

tt_row_loope:

	WAIT  r20,     64      ; (1799) (Will need loop preparation, at least a start row calculation)

	; Load colors

	rcall m72_tt_colors    ; (1820 = 0) (21 cycles)

	; Generate line

	rcall m72_txtline      ; (1702)

	; Next scanline, loop

	inc   r18
	dec   r16
	brne  tt_row_loop      ; (1705 / 1706)

	WAIT  r20,     10      ; (1715) Fall through to padding lines



;
; Top text area padding lines.
;
; Enters in cycle 1715.
;
tt_pad_entry:

	lds   r16,     V_TT_CPAD
	cpi   r16,     0
	brne  tt_pad_loope     ; (1719 / 1720)
	rjmp  ga_tran_entry    ; (1721) None to draw: transfer to game area

	; Draw extra lines

tt_pad_loop:

	WAIT  r20,     14      ; (1720)

tt_pad_loope:

	WAIT  r20,     79      ; (1799)

	; Load colors

	rcall m72_tt_colors    ; (1820 = 0) (21 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, loop

	inc   r18
	dec   r16
	brne  tt_pad_loop      ; (1705 / 1706)

	WAIT  r20,     16      ; (1721) Fall through to game area transfer



;
; Transfer to game area code
;
; Enters in cycle 1721.
;
ga_tran_entry:

	WAIT  r20,     34      ; (1755)

	; Load game area palette into r2 and r6 - r16 (r3, r4 and r5 will be
	; loaded with colors 1, 2 and 3 within the scanline code, to allow
	; using these registers in sprite modes).

	lds   r2,      palette
	ldi   XL,      lo8(palette + 4)
	ldi   XH,      hi8(palette + 4)
	ld    r6,      X+
	ld    r7,      X+
	ld    r8,      X+
	ld    r9,      X+
	ld    r10,     X+
	ld    r11,     X+
	ld    r12,     X+
	ld    r13,     X+
	ld    r14,     X+
	ld    r15,     X+
	ld    r16,     X+      ; (1781)

	; Prepare logical row counter. No scan line increment (r18) since it
	; is pre-incremented in the game area scanline code.

	lds   r19,     m72_ypos
	add   r19,     r18     ; Compensate for possible overlay
	subi  r19,     32      ; (1785)

	; Prepare for line buffer fill

	in    XH,      STACKH
	ldi   XL,      16      ; (1787)

	; Load colors (T.T boundary line)

	lds   r20,     m72_lt_col
	rcall m72_bl_colors    ; (1808) (19 cycles)

	; Fill in line buffer for T.T boundary line

	rcall gap_t4           ; (   3)
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	rcall gap_t6           ; (  24)
	rcall gap_t8           ; (  47)
	rcall gap_t8           ; (  70)
	rcall gap_t8           ; (  93)
	rcall gap_t8           ; ( 116)
	rcall gap_t8           ; ( 139)
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	nop
	st    X+,      r20
	st    X+,      r20     ; ( 146)
	rcall gap_t8           ; ( 169)
	rcall gap_t8           ; ( 192)
	rcall gap_t8           ; ( 215)
	rcall gap_t8           ; ( 238)
	rcall gap_t8           ; ( 261)
	rcall gap_t8           ; ( 284)
	rcall gap_t8           ; ( 307)
	rcall gap_t8           ; ( 330)
	rcall gap_t8           ; ( 353)
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins (T.T boundary line)
	rcall gap_t4           ; ( 369)
	rcall gap_t8           ; ( 392)
	rcall gap_t8           ; ( 415)
	rcall gap_t8           ; ( 438)
	rcall gap_t8           ; ( 461)

	ldi   ZL,      15
	out   STACKL,  ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b

gap_t8:
	st    X+,      r20
gap_t7:
	st    X+,      r20
gap_t6:
	st    X+,      r20
gap_t5:
	st    X+,      r20
gap_t4:
	st    X+,      r20
gap_t3:
	st    X+,      r20
gap_t2:
	st    X+,      r20
gap_t1:
	st    X+,      r20
	ret



;
; Game area lead-out code. This produces the last line of the game area in
; which no new line is rendered into the line buffer. The scanline counter
; (r18) is set properly. No need to do anything, just render the line and
; transfer to T.B boundary line.
;
; Enters in cycle 512.
;
m72_gtxt_tran:

	pop   r0
	out   PIXOUT,  r0      ; ( 515) Pixel 7
	ldi   r20,     152
	rjmp  .
gtx_loop:
	nop
	pop   r0
	out   PIXOUT,  r0      ; Pixels 8 - 159
	dec   r20
	brne  gtx_loop
	ldi   ZL,      LB_STACK - 1
	out   STACKL,  ZL      ; Restore stack to work as stack
	rjmp  .
	out   PIXOUT,  r17     ; (1586)
	WAIT  r20,     110
	clr   r20
	out   PIXOUT,  r20     ; (1698) Black border begins



;
; T.B boundary line.
;
; Enters in cycle 1698.
;
tb_tbl_entry:

	lds   r16,     V_TB_CTBL
	cpi   r16,     0
	brne  .+2              ; (1702 / 1703)
	rjmp  tb_pad_entry     ; (1704) None to draw

	; Draw top boundary line

	WAIT  r20,     96      ; (1799)

	; Load color

	lds   r20,     m72_lb_col
	rcall m72_bl_colors    ; (1820 = 0) (19 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, then go on to top text area extra lines

	inc   r18              ; (1703)
	WAIT  r20,     1       ; (1704) Fall through to padding lines



;
; Bottom text area padding lines.
;
; Enters in cycle 1704.
;
tb_pad_entry:

	lds   r16,     V_TB_CPAD
	cpi   r16,     0
	brne  tb_pad_loope     ; (1708 / 1709)
	rjmp  tb_row_entry     ; (1710) None to draw: go on to rows

	; Draw extra lines

tb_pad_loop:

	WAIT  r20,     3       ; (1709)

tb_pad_loope:

	WAIT  r20,     90      ; (1799)

	; Load colors

	rcall m72_tb_colors    ; (1820 = 0) (21 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, loop

	inc   r18
	dec   r16
	brne  tb_pad_loop      ; (1705 / 1706)

	WAIT  r20,     5       ; (1710) Fall through to rows



;
; Bottom text area tile rows.
;
; Enters in cycle 1710.
;
tb_row_entry:

	lds   r16,     V_TB_CROW
	cpi   r16,     0
	brne  tb_row_prep      ; (1714 / 1715)
	rjmp  tb_ext_entry     ; (1716) None to draw: go on to extra lines

	; Draw extra lines

tb_row_prep:

	lds   YL,      m72_tb_vram + 0
	lds   YH,      m72_tb_vram + 1
	clr   r19              ; Tile row to start at: zero
	rjmp  tb_row_loope     ; (1722)

tb_row_loop:

	WAIT  r20,     16      ; (1722)

tb_row_loope:

	WAIT  r20,     77      ; (1799) (Will need loop preparation, at least a start row calculation)

	; Load colors

	rcall m72_tb_colors    ; (1820 = 0) (21 cycles)

	; Generate line

	rcall m72_txtline      ; (1702)

	; Next scanline, loop

	inc   r18
	dec   r16
	brne  tb_row_loop      ; (1705 / 1706)

	WAIT  r20,     11      ; (1716) Fall through to extra lines



;
; Bottom text area extra lines (beyond tile row count).
;
; Enters in cycle 1716.
;
tb_ext_entry:

	lds   r16,     V_TB_CEXT
	cpi   r16,     0
	brne  tb_ext_loope     ; (1720 / 1721)
	rjmp  tb_bbl_entry     ; (1722) None to draw: go on to bottom boundary line

	; Draw extra lines

tb_ext_loop:

	WAIT  r20,     15      ; (1721)

tb_ext_loope:

	WAIT  r20,     78      ; (1799)

	; Load colors

	rcall m72_tb_colors    ; (1820 = 0) (21 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, loop

	inc   r18
	dec   r16
	brne  tb_ext_loop      ; (1705 / 1706)

	WAIT  r20,     17      ; (1722) Fall through to bottom boundary line



;
; Bottom boundary line.
;
; Enters in cycle 1722.
;
tb_bbl_entry:

	lds   r16,     V_TB_CBBL
	cpi   r16,     0
	brne  .+2              ; (1726 / 1727)
	rjmp  fr_leadout       ; (1728) None to draw

	; Draw top boundary line

	WAIT  r20,     72      ; (1799)

	; Load color

	lds   r20,     m72_tb_col
	rcall m72_bl_colors    ; (1820 = 0) (19 cycles)

	; Generate line

	rcall m72_blankline    ; (1702)

	; Next scanline, then go on to top text area extra lines

	inc   r18              ; (1703)
	WAIT  r20,     23      ; (1726)
	rjmp  fr_leadout       ; (1728)



;
; Exit points.
;
; fr_zero_height: 1385
; fr_leadout:     1728
;
fr_zero_height:

	WAIT  r20,     343     ; (1728)

fr_leadout:

	WAIT  r20,     95      ; (   3)
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	rcall m72_sample       ; (  31)

	; Update sync pulse counter

	lds   r20,     render_lines_count
	lds   ZL,      sync_pulse
	inc   r20              ; One extra line for this leadout
	sub   ZL,      r20
	sts   sync_pulse, ZL   ; (  39)

	; Set vsync flag & flip field

	lds   ZL,      sync_flags
	ldi   r20,     SYNC_FLAG_FIELD
	ori   ZL,      SYNC_FLAG_VSYNC
	eor   ZL,      r20
	sts   sync_flags, ZL   ; (  46)

	; Restore clobbered stuff

	lds   r0,      V_S_GP0
	out   GPR0,    r0
	lds   r0,      V_S_GP1
	out   GPR1,    r0
	lds   r0,      V_S_GP2
	out   GPR2,    r0
	lds   r0,      V_S_SPH
	out   STACKH,  r0
	lds   r0,      V_S_SPL
	out   STACKL,  r0      ; (  61)

	; Prepare for frame reset check

	lds   r24,     m72_reset + 0
	lds   r25,     m72_reset + 1

	; Generate sync

	WAIT  r20,     74
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high

	; Clear any pending timer interrupt

	ldi   ZL,      (1<<OCF1A)
	sts   _SFR_MEM_ADDR(TIFR1), ZL

	; Determine return path (normal or reset)

	mov   r1,      r24
	or    r1,      r25
	brne  .+2              ; Nonzero: Perform a reset to the given address
	ret                    ; Zero: Normal video mode return
	ldi   r22,     lo8(M72_RESET_STACK)
	ldi   r23,     hi8(M72_RESET_STACK)
	out   STACKL,  r22
	out   STACKH,  r23
	clr   r1               ; Clear r1 for C
	push  r24
	push  r25              ; Push return address onto stack
	reti                   ; End of frame interrupt (bypassing kernel)



;
; Game area line calculation code (interleaved with first few pixels)
;
; Scanline notes:
;
; The horizontal layout with borders is constructed to show as if there were
; 24 tiles (or 48 in text mode).
;
; Cycles:
;
; out PIXOUT, (zero) ; (1698) Black border begins
; cbi SYNC,   SYNC_P ; (   5) Sync pulse goes low
; sbi SYNC,   SYNC_P ; ( 141) Sync pulse goes high
; out PIXOUT, r17    ; ( 354) Next scanline colored border begins
;
m72_graf_scan_b:

	; Display line starts here, sprite blocks jump here
	;
	; Entry must be made as follows:
	;
	; ldi   ZL,      15
	; out   STACKL,  ZL
	; pop   r0
	; out   PIXOUT,  r0      ; ( 466) Pixel 0
	; jmp   m72_graf_scan_b
	;
	;  r1: r0: Temp
	;  r2-r17: Colors (r2: Bg, r17: Border)
	; r18:     Physical scanline
	; r19:     Logical scanline
	; r20-r23: Temp
	; r24
	; r25:     Loaded with bullet count
	; XH: XL:  Line buffer, target
	; YH: YL:  VRAM
	; ZH: ZL:  Work pointer
	;
	; GPIOR0:
	; 0: Sprite priority select for multiplexing
	; 1: Color 0 (bg) loading enabled from scanline color list
	; 2: Color 15 (border) loading enabled from scanline color list
	;
	; GPIOR1:
	; Preloaded color
	;
	; GPIOR2:
	; Split point into text mode or end of frame (checked in text mode)

	; Preload sound sample & increment pointer (VSync mixer)

	ldi   r22,     hi8(MIX_BUF_SIZE + mix_buf)
	pop   r0
	out   PIXOUT,  r0      ; ( 473) Pixel 1
	lds   ZL,      mix_pos + 0
	lds   ZH,      mix_pos + 1
	pop   r0
	out   PIXOUT,  r0      ; ( 480) Pixel 2
	ld    r23,     Z+      ; Load next sample
	sts   AUDOUT,  r23     ; Sample output is a bit delayed, no big problem
	pop   r0
	out   PIXOUT,  r0      ; ( 487) Pixel 3
	cpi   ZL,      lo8(MIX_BUF_SIZE + mix_buf)
	cpc   ZH,      r22
	ldi   r22,     lo8(mix_buf)
	ldi   r23,     hi8(mix_buf)
	pop   r0
	out   PIXOUT,  r0      ; ( 494) Pixel 4
	brlo  .+2
	movw  ZL,      r22
	sts   mix_pos + 0, ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 501) Pixel 5
	sts   mix_pos + 1, ZH

	; Increment scanline counters & check end condition

	inc   r18
	in    r1,      GPR2    ; Terminating scanline
	pop   r0
	out   PIXOUT,  r0      ; ( 508) Pixel 6
	cp    r18,     r1
	brne  .+2
	rjmp  m72_gtxt_tran    ; ( 512) Transfer to text mode
	inc   r19              ; ( 512)

	; Preload color or logical scanline

#if (M72_SCOLOR_ENA != 0)
	pop   r0
	out   PIXOUT,  r0      ; ( 515) Pixel 7
	mov   ZL,      r18
	clr   ZH
	subi  ZL,      lo8(m72_scolor - 31)
	sbci  ZH,      hi8(m72_scolor - 31)
	pop   r0
	out   PIXOUT,  r0      ; ( 522) Pixel 8
#if (M72_SLINE_ENA != 0)
	ld    r19,     Z
	out   GPR1,    r2      ; Extend color 0 into border if log. line reload is used
#else
	ld    r23,     Z
	out   GPR1,    r23
#endif
#else
	pop   r0
	out   PIXOUT,  r0      ; ( 515) Pixel 7
	rjmp  .
	rjmp  .
	pop   r0
	out   PIXOUT,  r0      ; ( 522) Pixel 8
	rjmp  .
	out   GPR1,    r2      ; Extend color 0 into border if no M72_SCOLOR_ENA
#endif

	; Preparations for sprite output, load bullet count and invert
	; physical scanline counter (will be reverted on sprite exit)

	nop
	pop   r0
	out   PIXOUT,  r0      ; ( 529) Pixel 9
	lds   r25,     m72_bull_cnt

	; Fetch VRAM entry offset & pixel (X scroll). Either one row offset
	; for each line or each tile row.

	ldi   ZH,      0x01
	mov   ZL,      r19
	pop   r0
	out   PIXOUT,  r0      ; ( 536) Pixel 10
#if (M72_USE_LINE_ADDR != 0)
	clr   ZH
	lsl   ZL
	rol   ZH
	subi  ZL,      lo8(-(m72_rowoff))
	pop   r0
	out   PIXOUT,  r0      ; ( 543) Pixel 11
	sbci  ZH,      hi8(-(m72_rowoff))
#else
	lsr   ZL
	lsr   ZL
	andi  ZL,      0x3E
	subi  ZL,      lo8(-(m72_rowoff - 0x0100))
	pop   r0
	out   PIXOUT,  r0      ; ( 543) Pixel 11
	sbci  ZH,      hi8(-(m72_rowoff - 0x0100))
#endif

	; Calculate VRAM entry offset & pixel (X scroll)

#if (M72_USE_XPOS == 0)
	ld    YL,      Z+
	nop
	pop   r0
	out   PIXOUT,  r0      ; ( 550) Pixel 12
	ld    YH,      Z+
	mov   ZL,      YH
	andi  YH,      0x0F    ; Y: VRAM offset
	pop   r0
	out   PIXOUT,  r0      ; ( 557) Pixel 13
	swap  ZL
	ldi   XL,      16
#else
	ld    YL,      Z+
	nop
	pop   r0
	out   PIXOUT,  r0      ; ( 550) Pixel 12
	ld    YH,      Z+
	nop
	ldi   XL,      16
	pop   r0
	out   PIXOUT,  r0      ; ( 557) Pixel 13
	lds   ZL,      m72_xpos
#endif
	andi  ZL,      0x07
	sub   XL,      ZL      ; 0-7 pixels left shift
	pop   r0
	out   PIXOUT,  r0      ; ( 564) Pixel 14

	; Reload palette entries 1 - 3, which regs could be used by sprites

	lds   r3,      palette + 1
	lds   r4,      palette + 2
	pop   r0
	out   PIXOUT,  r0      ; ( 571) Pixel 15
	lds   r5,      palette + 3

	; Jump to appropriate tile row render code

	mov   ZL,      r19     ; Logical scanline => tile row select
	andi  ZL,      0x07
	pop   r0
	out   PIXOUT,  r0      ; ( 578) Pixel 16
	clr   ZH
	subi  ZL,      lo8(-(pm(m72_deftilerows)))
	sbci  ZH,      hi8(-(pm(m72_deftilerows)))
	ldi   r20,     20      ; 20 visible tiles
	pop   r0
	out   PIXOUT,  r0      ; ( 585) Pixel 17
	pop   r21
	pop   r1
	pop   r0
	out   PIXOUT,  r21     ; ( 592) Pixel 18
	clt
	ijmp



;
; VSync mixer output
;
m72_sample:
	ldi   r22,     hi8(MIX_BUF_SIZE + mix_buf)
	lds   ZL,      mix_pos + 0
	lds   ZH,      mix_pos + 1
	ld    r23,     Z+      ; Load next sample
	sts   AUDOUT,  r23
	cpi   ZL,      lo8(MIX_BUF_SIZE + mix_buf)
	cpc   ZH,      r22
	ldi   r22,     lo8(mix_buf)
	ldi   r23,     hi8(mix_buf)
	brlo  .+2
	movw  ZL,      r22
	sts   mix_pos + 0, ZL
	sts   mix_pos + 1, ZH
	ret                    ; (23)



;
; Empty line output. r17: border, r20: background, r22, r23, Z: clobbered
;
m72_blankline:
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	rcall m72_sample       ; (  31)
	WAIT  r22,     108
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	WAIT  r22,     212
	out   PIXOUT,  r17     ; ( 354) Colored border begins
	WAIT  r22,     111
	out   PIXOUT,  r20     ; ( 466) Background begins
	WAIT  r22,     1119
	out   PIXOUT,  r17     ; (1586) Colored border begins
	WAIT  r22,     110
	clr   r22
	out   PIXOUT,  r22     ; (1698) Black border begins
	ret                    ; (1702)



;
; Text line output. See m72_txt_row in videoMode72_txt.s
; Prepares bg & fg colors from r20 and r21 respectively.
;
m72_txtline:
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	rcall m72_sample       ; (  31)
	WAIT  r22,     108
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	WAIT  r22,     212
	out   PIXOUT,  r17     ; ( 354) Colored border begins
	WAIT  r22,     69      ; ( 423)
	mov   r4,      r21     ; ( 424) Foreground (1) color
	mov   r5,      r20     ; ( 425) Background (0) color
	call  m72_txt_row      ; (1595)
	WAIT  r22,     101
	clr   r22
	out   PIXOUT,  r22     ; (1698) Black border begins
	ret                    ; (1702)



;
; Boundary line color loads. In r20 the appropriate line color has to be
; prepared.
;
m72_bl_colors:
	lds   r21,     m72_config
#if (M72_SCOLOR_ENA != 0)
	mov   ZL,      r18
	clr   ZH
	subi  ZL,      lo8(m72_scolor - 31)
	sbci  ZH,      hi8(m72_scolor - 31)
	ld    ZL,      Z
#else
	rjmp  .
	rjmp  .
	lds   ZL,      bordercolor
#endif
	sbrc  r21,     0       ; Boundary line colors disabled?
	mov   r20,     ZL      ; If so, use the border color
	sbic  GPR0,    2       ; Color 15 (border) loading enabled?
	mov   r17,     r20     ; If so, load boundary line color
	ret                    ; (16)



;
; Top text region color loads. r20: background, r21: foreground
;
m72_tt_colors:
	lds   r20,     m72_tt_bcol
	lds   r21,     m72_tt_fcol
#if (M72_SCOLOR_ENA != 0)
	mov   ZL,      r18
	clr   ZH
	subi  ZL,      lo8(m72_scolor - 31)
	sbci  ZH,      hi8(m72_scolor - 31)
	ld    r22,     Z
#else
	rjmp  .
	rjmp  .
	lds   r22,     bordercolor
#endif
	sbic  GPR0,    2       ; Border color loading / expansion enabled?
	mov   r17,     r22     ; If so, load it
	sbic  GPR0,    3       ; Background color replace enabled?
	mov   r20,     r22     ; If so, replace it
	ret                    ; (18)



;
; Bottom text region color loads. r20: background, r21: foreground
;
m72_tb_colors:
	lds   r20,     m72_tb_bcol
	lds   r21,     m72_tb_fcol
#if (M72_SCOLOR_ENA != 0)
	mov   ZL,      r18
	clr   ZH
	subi  ZL,      lo8(m72_scolor - 31)
	sbci  ZH,      hi8(m72_scolor - 31)
	ld    r22,     Z
#else
	rjmp  .
	rjmp  .
	lds   r22,     bordercolor
#endif
	sbic  GPR0,    2       ; Border color loading / expansion enabled?
	mov   r17,     r22     ; If so, load it
	sbic  GPR0,    3       ; Background color replace enabled?
	mov   r20,     r22     ; If so, replace it
	ret                    ; (18)



;
; Always available empty sprite mode (15)
;
m72_sp15:
	WAIT  r20,     66      ; (1631 + 66)
	out   PIXOUT,  r20     ; (1698) Black border begins
	WAIT  r20,     125
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	WAIT  r20,     134
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	WAIT  r20,     212
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	WAIT  r20,     107     ; ( 461)
	ldi   ZL,      15
	out   STACKL,  ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b



#if (M72_DUMMY_BG != 0)
;
; Blank tileset code (background color, sprites only)
;
; Use as template to build the code tiles (note the 2x rjmp entry, can be used
; for code tile row reuse schemes).
;
m72_deftilerows:
	rjmp  bts_row_00
	rjmp  bts_row_01
	rjmp  bts_row_02
	rjmp  bts_row_03
	rjmp  bts_row_04
	rjmp  bts_row_05
	rjmp  bts_row_06
	rjmp  bts_row_07

bts_row_00:
bts_row_01:
bts_row_02:
bts_row_03:
bts_row_04:
bts_row_05:
bts_row_06:
bts_row_07:
	nop                    ; Normally ldi ZH, hi8(pm(rowmap))
	out   PIXOUT,  r1      ; ( 599) Pixel 19
	jmp   bts_entry

bts_rowmap:
	rjmp  bts_cbsel        ; Normally 256 entries / row

bts_cbsel:
	rjmp  bts_cblock

bts_cblock:
	out   PIXOUT,  r1
	st    X+,      r2
	st    X+,      r2
	st    X+,      r2
	out   PIXOUT,  r22
	st    X+,      r2
	st    X+,      r2
	st    X+,      r2
	out   PIXOUT,  r23
	st    X+,      r2
	st    X+,      r2
	rjmp  bts_common

bts_common:
	out   PIXOUT,  r0
	breq  bts_exit         ; Uses Z flag
	pop   r0
bts_entry:
	dec   r20              ; Remaining tile count (Z flag sets accordingly)
	rjmp  .                ; Normally ld ZL, Y+
	out   PIXOUT,  r0
	pop   r0
	pop   r21
	pop   r1
	out   PIXOUT,  r0
	pop   r22
	pop   r23
	pop   r0
	out   PIXOUT,  r21
	rjmp  bts_rowmap       ; Normally ijmp
bts_exit:
	brts  bts_exitf        ; (1582 / 1621)
	mov   r22,     r17
	mov   r23,     r17
	movw  r0,      r22
	out   PIXOUT,  r17     ; (1586)
	rjmp  .                ; Normally ld ZL, Y+
	set                    ; T reg indicates final exit condition
	rjmp  bts_rowmap       ; Normally ijmp
bts_exitf:
	sbic  GPR0,    1       ; (1622) Color 0 (bg) loading enabled?
	in    r2,      GPR1    ; (1623) If so, load it
	sbic  GPR0,    2       ; (1624) Color 15 (border) loading enabled?
	in    r17,     GPR1    ; (1625) If so, load it
	ldi   ZL,      LB_SPR - 1 ; (1626) 254(HI):255(LO): Sprite conf
	out   STACKL,  ZL      ; (1627)
	ret                    ; (1631)
#endif



;
; void M72_Halt(void);
;
; Halts program execution. Use with reset (m72_reset non-null) to terminate
; components which are supposed to be terminated by a new frame. This is not
; required, but by the C language a function call is necessary to enforce a
; sequence point (so every side effect completes before the call including
; writes to any globals).
;
.section .text.M72_Halt
M72_Halt:
	rjmp  M72_Halt



;
; void M72_Seq(void);
;
; Sequence point. Use with reset (m72_reset non-null) to enforce a sequence
; point, so everything is carried out which is before. This is not required,
; but by the C language a function call is necessary to enforce a sequence
; point (so every side effect completes before the call including writes to
; any globals).
;
.section .text.M72_Seq
M72_Seq:
	ret



.section .text



;
; Bullet code. 42 cycles (35 + 3 for rcall). This can be used to reduce sprite
; mode sizes where there are cycles to afford the 6 cycle overhead (an
; unrolled bullet is 36 cycles).
;
sp_bullet:
	ld    ZL,      Y
	ldd   ZH,      Y + 1
	ld    r4,      Z+      ; ( 6) YPos
	add   r4,      r18     ; ( 7) Line within sprite acquired
	ld    XL,      Z+      ; ( 9) Xpos
	cpi   XL,      176
	brcs  .+2
	ldi   XL,      176     ; (12) Limit Xpos
	ld    r3,      Z+      ; (14) Color
	ld    r5,      Z+      ; (16) Height (bits 2-7) & Width (bits 0-1)
	lsr   r5               ; (17)
	brcc  sp_b_13          ; (18 / 19)
	lsr   r5               ; (19)
	brcc  sp_b_2           ; (20 / 21)
	cp    r5,      r4      ; (21)
	brcs  sp_b_i0          ; (22 / 23)
	st    X+,      r3      ; (24) 1st pixel
	st    X+,      r3      ; (26) 2nd pixel
	st    X+,      r3      ; (28) 3rd pixel
sp_b_1e:
	st    X+,      r3      ; (30) 4th pixel
	brne  sp_b_ni          ; (31 / 32) At last px of sprite: Load next sprite
sp_b_x0:
	st    Y+,      ZL
	st    Y+,      ZH      ; (35)
	ret                    ; (39)
sp_b_ni:
	nop
	adiw  YL,      2       ; (35)
	ret                    ; (39)
sp_b_13:
	lsr   r5               ; (20)
	brcc  sp_b_1           ; (21 / 22)
	cp    r5,      r4      ; (22)
	brcs  sp_b_i1          ; (23 / 24)
	st    X+,      r3      ; (25) 1st pixel
sp_b_2e:
	st    X+,      r3      ; (27) 2nd pixel
	st    X+,      r3      ; (29) 3rd pixel
	breq  sp_b_x0          ; (30 / 31) At last px of sprite: Load next sprite
	rjmp  sp_b_ni          ; (32)
sp_b_2:
	cp    r5,      r4      ; (22)
	brcs  sp_b_i1          ; (23 / 24)
	rjmp  sp_b_2e          ; (25)
sp_b_1:
	cp    r5,      r4      ; (23)
	brcs  sp_b_i2          ; (24 / 25)
	rjmp  .                ; (26)
	rjmp  sp_b_1e          ; (28)
sp_b_i0:
	nop                    ; (24)
sp_b_i1:
	nop                    ; (25)
sp_b_i2:
	lpm   XL,      Z       ; (28)
	rjmp  .
	rjmp  sp_b_ni          ; (32)



;
; Load next sprite code for sprite modes. Assumes entry with rcall.
;
; Y: Must point to the appropriate entry in the sprite list (v_sprd) + 2.
; Z: Used to copy next sprite data
; r21: Temp
;
sp_next:

	sbiw  YL,      2
	ldd   ZL,      Y + 40  ; ( 7) NextLo
	ldd   ZH,      Y + 41  ; ( 9) NextHi
	cpi   ZH,      0
	breq  sp_next_lie      ; (11 / 12)
	ld    r21,     Z+
	st    Y+,      r21     ; (15) YPos
	ld    r21,     Z+
	st    Y+,      r21     ; (19) Height
	ld    r21,     Z+
	std   Y + 40,  r21     ; (23) OffLo
	ld    r21,     Z+
	std   Y + 41,  r21     ; (27) OffHi
	ld    r21,     Z+
	cpi   r21,     176
	brcs  .+2
	ldi   r21,     176
	std   Y + 42,  r21     ; (34) XPos
	ld    r21,     Z+
	st    Y+,      r21     ; (38) Col0
	ld    r21,     Z+
	st    Y+,      r21     ; (42) Col1
	ld    r21,     Z+
	st    Y+,      r21     ; (46) Col2
	ld    r21,     Z+
	std   Y + 35,  r21     ; (50) NextLo
	ld    r21,     Z+
	std   Y + 36,  r21     ; (54) NextHi
	ret                    ; (58)
sp_next_lie:
	std   Y + 0,   ZH
	std   Y + 1,   ZH      ; (16)
	adiw  YL,      5       ; (18)
	WAIT  r21,     36      ; (54)
	ret                    ; (58)



; Sprite modes

#if ((M72_SPRITE_MODES & 0x0001) != 0)
#include "videoMode72_sp0.s"
#endif
#if ((M72_SPRITE_MODES & 0x0002) != 0)
#include "videoMode72_sp1.s"
#endif
#if ((M72_SPRITE_MODES & 0x0004) != 0)
#include "videoMode72_sp2.s"
#endif
#if ((M72_SPRITE_MODES & 0x0008) != 0)
#include "videoMode72_sp3.s"
#endif
#if ((M72_SPRITE_MODES & 0x0010) != 0)
#include "videoMode72_sp4.s"
#endif
#if ((M72_SPRITE_MODES & 0x0020) != 0)
#include "videoMode72_sp5.s"
#endif
#if ((M72_SPRITE_MODES & 0x0040) != 0)
#include "videoMode72_sp6.s"
#endif
#if ((M72_SPRITE_MODES & 0x0080) != 0)
#include "videoMode72_sp7.s"
#endif
#if ((M72_SPRITE_MODES & 0x0100) != 0)
#include "videoMode72_sp8.s"
#endif
#if ((M72_SPRITE_MODES & 0x0200) != 0)
#include "videoMode72_sp9.s"
#endif
#if ((M72_SPRITE_MODES & 0x0400) != 0)
#include "videoMode72_sp10.s"
#endif
#if ((M72_SPRITE_MODES & 0x0800) != 0)
#include "videoMode72_sp11.s"
#endif
#if ((M72_SPRITE_MODES & 0x1000) != 0)
#include "videoMode72_sp12.s"
#endif
#if ((M72_SPRITE_MODES & 0x2000) != 0)
#include "videoMode72_sp13.s"
#endif
#if ((M72_SPRITE_MODES & 0x4000) != 0)
#include "videoMode72_sp14.s"
#endif

; Code table for 2bpp sprites

#include "videoMode72_sp2bpp.s"

; Text mode

#include "videoMode72_txt.s"


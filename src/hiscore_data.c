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


#include "hiscore_data.h"
#include <avr/pgmspace.h>


/** Default high-score table, naturally a bit hacky with the raw bits
 *  representing scores */
static const uint8_t PROGMEM hiscore_data_default[] = {
 0x00U + HISCORE_ASCII2RAW('U'), 0xC0U + HISCORE_ASCII2RAW('z'),
 0x00U + HISCORE_ASCII2RAW('e'), 0x80U, /* 50 days (0x32) */
 0x00U,                          0x00U,
 0x40U,                          0x40U,
 0x00U,                          0x00U, /* 80 pop (0x50) */
 0x00U + HISCORE_ASCII2RAW('D'), 0x80U + HISCORE_ASCII2RAW('3'),
 0x00U + HISCORE_ASCII2RAW('t'), 0xC0U + HISCORE_ASCII2RAW('h'), /* 35 days (0x23) */
 0x00U + HISCORE_ASCII2RAW('A'), 0x00U + HISCORE_ASCII2RAW('d'),
 0x00U + HISCORE_ASCII2RAW('d'), 0xC0U + HISCORE_ASCII2RAW('3'),
 0x40U + HISCORE_ASCII2RAW('r'), 0xC0U, /* 55 pop (0x37) */
 0x00U + HISCORE_ASCII2RAW('D'), 0x40U + HISCORE_ASCII2RAW('a'),
 0x40U + HISCORE_ASCII2RAW('n'), 0x00U + HISCORE_ASCII2RAW('b'), /* 20 days (0x14) */
 0x00U + HISCORE_ASCII2RAW('o'), 0x00U + HISCORE_ASCII2RAW('i'),
 0x00U + HISCORE_ASCII2RAW('d'), 0x80U,
 0x00U,                          0xC0U  /* 35 pop (0x23) */
};

/** Default name */
static const uint8_t PROGMEM hiscore_data_name[] = {
 HISCORE_ASCII2RAW('G'), HISCORE_ASCII2RAW('o'),
 HISCORE_ASCII2RAW('v'), HISCORE_ASCII2RAW('e'),
 HISCORE_ASCII2RAW('r'), HISCORE_ASCII2RAW('n'),
 HISCORE_ASCII2RAW('o'), HISCORE_ASCII2RAW('r'),
 0U, 0U
};



void HiScore_Data_Fill(uint8_t* dest)
{
 memcpy_P(dest, &hiscore_data_default[0], sizeof(hiscore_data_default));
}



void HiScore_Data_FillName(uint8_t* dest)
{
 memcpy_P(dest, &hiscore_data_name[0], sizeof(hiscore_data_name));
}

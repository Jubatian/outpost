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


#ifndef TEXT_H
#define TEXT_H


#include <stdint.h>
#include <stdbool.h>


/** @{ */
/** Texts accessible for output */
#define TEXT_GOLD          0U
#define TEXT_POP           1U
#define TEXT_SWAPS         2U
#define TEXT_TURN          3U
#define TEXT_END           4U
#define TEXT_ENDSEL        5U
#define TEXT_BUYPOP        6U
#define TEXT_BUYPOPSEL     7U
#define TEXT_BUYSWAP       8U
#define TEXT_BUYSWAPSEL    9U
#define TEXT_BUYANYSWAP    10U
#define TEXT_BUYANYSWAPSEL 11U
#define TEXT_GAMEOVER      12U
#define TEXT_SURVIVED      13U
#define TEXT_SURVMONTHS    14U
#define TEXT_DEADPOP       15U
#define TEXT_TITLE         16U
#define TEXT_TITLEDESC1    17U
#define TEXT_TITLEDESC2    18U
#define TEXT_VERSION       19U
/** @} */



/**
 * @brief   Fills in a string, returning its size
 *
 * @param   dest:   Target area to write string to
 * @param   strsel: String selector
 * @return          Length of string produced
 */
uint16_t text_genstring(uint8_t* dest, uint8_t strsel);


/**
 * @brief   Fills in an area
 *
 * @param   dest:   Target area to fill
 * @param   data:   Data to fill with
 * @param   len:    Length to fill in
 */
void text_fill(uint8_t* dest, uint8_t data, uint16_t len);


/**
 * @brief   Convert 16 bits input to BCD
 *
 * @param   val:    Value to convert
 * @return          BCD representation
 */
uint32_t text_bin16bcd(uint16_t val);


/**
 * @brief   Output decimal value with space front padding
 *
 * @param   dest:   Target area to output at
 * @param   val:    16 bits value to output
 * @param   digits: Number of digits to display (space front padding)
 * @return          Number of digits output (always the same as digits)
 */
uint8_t text_decout_spacepad(uint8_t* dest, uint16_t val, uint8_t digits);


/**
 * @brief   Output decimal value with zero front padding
 *
 * @param   dest:   Target area to output at
 * @param   val:    16 bits value to output
 * @param   digits: Number of digits to display (zero front padding)
 * @return          Number of digits output (always the same as digits)
 */
uint8_t text_decout_zeropad(uint8_t* dest, uint16_t val, uint8_t digits);


/**
 * @brief   Output decimal value
 *
 * @param   dest:   Target area to output at
 * @param   val:    16 bits value to output
 * @return          Number of digits output
 */
uint8_t text_decout(uint8_t* dest, uint16_t val);


#endif

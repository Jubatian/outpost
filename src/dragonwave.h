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


#ifndef DRAGONWAVE_H
#define DRAGONWAVE_H


#include <stdint.h>
#include <stdbool.h>



/** Maximum count of dragons */
#define DRAGONWAVE_MAX_DRAGONS  16U


/** Dragon parameters */
typedef struct{
 uint16_t ypos;    /**< Vertical position, 2's complement (negative start) */
 uint8_t  xpos;    /**< Horizontal position */
 uint8_t  dsize;   /**< Size of dragon (0-3) */
 uint8_t  svar;    /**< Strength (relative to size) variant (0-15) */
 uint8_t  flyfr;   /**< Flight frame, 0: glide, 1-255 wing cycle */
 uint8_t  diefr;   /**< Death frame, 0: OK, 1-255 dying, check nonzero for dead */
}dragonwave_dragon_tdef;


/**
 * @brief   Returns storage size required for this component
 *
 * @return         Storage size in bytes
 */
uint_fast16_t DragonWave_Size(void);


/**
 * @brief   Initializes work buffer for dragons
 *
 * Pass it a buffer to use for the structures necessary to track dragons. This
 * storage is only used during the wave, from DragonWave_Setup() until no
 * dragons are left (or later with DragonWave_Setup() a new wave is
 * requested).
 *
 * @param   buf:    RAM buffer to put dragon structures in
 */
void DragonWave_Init(void* buf);


/**
 * @brief   Sets up dragon attack wave
 *
 * Initializes dragons for the wave, positioning them above the playfield,
 * ready to start off. The turn determines the total health and types of
 * dragons which may be created.
 *
 * @param   turn:   Turn to create dragons for
 */
void DragonWave_Setup(uint_fast16_t turn);


/**
 * @brief   Process a dragon movement tick
 */
void DragonWave_Tick(void);


/**
 * @brief   Check whether the wave ended
 *
 * The wave ends when all dragons are dead or removed (using
 * DragonWave_PopArriving()).
 *
 * @return          True if the wave ended
 */
bool DragonWave_IsEnded(void);


/**
 * @brief   Pop off arriving dragon
 *
 * Pops off an arriving dragon (crossed the playfield alive), removing it from
 * the list of dragons.
 *
 * @return          Dragon's size (0-3) or 0xFF if no dragon ready
 */
uint_fast8_t DragonWave_PopArriving(void);


/**
 * @brief   Request current count of dragons
 *
 * Note that dying dragons are included in this count.
 *
 * @return          Number of dragons left
 */
uint_fast8_t DragonWave_Count(void);


/**
 * @brief   Request parameters of a dragon
 *
 * Valid dragon identifiers are up to the returned count. Returns their
 * current parameters relevant outside the module.
 *
 * Note that dragon positions are relative to playfield coordinates, 0:0
 * being the upper left (of the invisible playfield row providing tiles).
 * Adjust correspondingly when displaying them.
 *
 * @param   idx:    Dragon index to query
 * @param   dpars:  Dragon parameters to fill in
 */
void DragonWave_GetDragon(uint_fast8_t idx, dragonwave_dragon_tdef* dpars);


/**
 * @brief   Load all dragon X/Y positions
 *
 * Loads all dragon X & Y positions into target array, Y position first.
 * Returns the count of dragons. Skips dragons which are not currently on
 * the playfield (Y not between 0 and 192), or are dying, so the result of
 * this may be (often) less than the count returned by DragonWave_Count().
 * The list is Y ordered, top to bottom.
 *
 * @param   posbuf: Position buffer, up to 2 * DRAGONWAVE_MAX_DRAGONS.
 * @return          Number of positions returned.
 */
uint_fast8_t DragonWave_ReadPositions(uint8_t* posbuf);


/**
 * @brief   Inflict damage to a single dragon in the proximity of target
 *
 * Tries to find a near enough dragon to inflict damage to.
 *
 * @param   xpos:   Horizontal position of damage source
 * @param   ypos:   Vertical position of damage source
 * @param   dmg:    Damage amount
 * @return          True if a dragon was hit and got damaged by it
 */
bool DragonWave_HitPoint(uint_fast8_t xpos, uint_fast8_t ypos, uint_fast16_t dmg);


/**
 * @brief   Inflict damage in an area to multiple dragons
 *
 * Any dragon sufficiently close is damaged.
 *
 * @param   xpos:   Horizontal position of damage source
 * @param   ypos:   Vertical position of damage source
 * @param   dmg:    Damage amount
 */
void DragonWave_HitSplash(uint_fast8_t xpos, uint_fast8_t ypos, uint_fast16_t dmg);


#endif

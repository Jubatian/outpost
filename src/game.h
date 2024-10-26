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


#ifndef GAME_H
#define GAME_H

#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Resets game
 *
 * Ends the game (Game_Frame() returning false).
 */
void Game_Reset(void);


/**
 * @brief   Starts a new game with a clear state
 *
 * Note that the game uses the random number generator (random.h) which is
 * not reset here.
 */
void Game_Start(void);


/**
 * @brief   Process a game frame
 *
 * Returns true after a game is started with Game_Start(), keeps returning so
 * as long as the game is in progress. Note that scores which can be queried
 * with the functions below remain available regardless of the use of the
 * passed RAM buffer after a game finishes, until a new one is started.
 *
 * @return          True if game is in progess
 */
bool Game_Frame(void);


/**
 * @brief   Score: Number of turns survived
 *
 * @return          Number of turns survived
 */
uint_fast8_t Game_Score_Turns(void);


/**
 * @brief   Score: Population
 *
 * @return          Total population (including dead)
 */
uint_fast16_t Game_Score_Pop(void);


#endif

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


#ifndef TITLE_H
#define TITLE_H

#include <stdint.h>
#include <stdbool.h>



/**
 * @brief   Sets up and starts title display and interface
 */
void Title_Start(void);


/**
 * @brief   Process title sequence frame
 *
 * Returns true after the title screen is started with Title_Start(), keeps
 * returning so until this is complete, exited.
 *
 * @return          True if title screen is in progess
 */
bool Title_Frame(void);


#endif

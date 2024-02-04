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


#include "control_ll.h"
#include <uzebox.h>



/** Previous controller state */
static uint_fast16_t control_ll_prev = 0U;

/** Saved triggers */
static uint_fast8_t  control_ll_trig = 0U;



/**
 * @brief   Collects control flags by Uzebox controller flags
 *
 * @param   uflags: Uzebox flag combination
 * @return          Derived controller flag combination
 */
static uint_fast8_t Control_LL_Convert(uint_fast16_t uflags)
{
 uint_fast8_t rflags = 0U;

 if ((uflags & BTN_UP)     != 0U){ rflags |= CONTROL_LL_UP; }
 if ((uflags & BTN_DOWN)   != 0U){ rflags |= CONTROL_LL_DOWN; }
 if ((uflags & BTN_LEFT)   != 0U){ rflags |= CONTROL_LL_LEFT; }
 if ((uflags & BTN_RIGHT)  != 0U){ rflags |= CONTROL_LL_RIGHT; }
 if ((uflags & BTN_START)  != 0U){ rflags |= CONTROL_LL_MENU; }
 if ((uflags & BTN_SELECT) != 0U){ rflags |= CONTROL_LL_ACTION; }
 if ((uflags & BTN_Y)      != 0U){ rflags |= CONTROL_LL_ACTION; }
 if ((uflags & BTN_B)      != 0U){ rflags |= CONTROL_LL_ACTION; }
 if ((uflags & BTN_SR)     != 0U){ rflags |= CONTROL_LL_ALTERN; }
 if ((uflags & BTN_SL)     != 0U){ rflags |= CONTROL_LL_ALTERN; }
 if ((uflags & BTN_X)      != 0U){ rflags |= CONTROL_LL_ALTERN; }
 if ((uflags & BTN_A)      != 0U){ rflags |= CONTROL_LL_ALTERN; }

 return rflags;
}



uint_fast8_t Control_LL_Get(uint_fast8_t cmask)
{
 uint_fast16_t curr = ReadJoypad(0) | ReadJoypad(1);
 uint_fast16_t press = (curr ^ control_ll_prev) & curr;
 control_ll_prev = curr;

 uint_fast8_t trig = Control_LL_Convert(press);

 uint_fast8_t stor = control_ll_trig;
 trig |= stor;
 stor  = trig & (0xFF ^ cmask);
 control_ll_trig = stor;

 return trig;
}



uint_fast8_t Control_LL_GetHolds(void)
{
 return Control_LL_Convert(control_ll_prev);
}

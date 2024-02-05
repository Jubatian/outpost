/*
 *  Uzebox video mode 72 simple demo
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

#include <uzebox.h>
#include "graphics_bg.h"
#include "palette_ll.h"
#include "game.h"
#include "gameover.h"
#include "title.h"
#include "sound_ll.h"
#include "soundpatch.h"



void reset(void){
 M72_Halt();
}



int main(void){

 /* VRAM start offsets */

 uint8_t* vram = Graphics_BG_GetVRAM();
 for (uint_fast8_t i = 0U; i < 25U; i++){
  m72_rowoff[i] = (u16)(&vram[(u16)(i) * 20U]);
 }
 for (uint_fast8_t i = 25U; i < 32U; i++){
  m72_rowoff[i] = (u16)(&vram[0U]);
 }

 /* Configure mode */

 /* m72_reset = (unsigned int)(&reset); */
 m72_config = 0x14U; /* Sprite mode 1, Border colour expands */

 Palette_LL_Fade(0);

 soundpatch_init();

 /* Main loop */

 Title_Start();
 bool ingame = false;
 bool intitle = true;

 uint_fast8_t stp = 0U;

 while(1){

  /* Run game */

  if (intitle){
   if (!(Title_Frame())){
    Game_Start();
    intitle = false;
    ingame = true;
   }
  }else if (ingame){
   if (!(Game_Frame())){
    GameOver_Start();
    ingame = false;
   }
  }else{
   if (!(GameOver_Frame())){
    Title_Start();
    intitle = true;
   }
  }

  WaitVsync(1);
  soundpatch_tick();

  stp ++;
  if ((stp & 0x3FU) == 0U){
//   soundpatch_play(SOUNDPATCH_CH_0 | SOUNDPATCH_CH_1 | SOUNDPATCH_CH_2, SOUNDPATCH_TEST);
  }
 }

}

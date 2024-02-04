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

 Palette_LL_Fade(255);

 soundpatch_init();

// for (uint_fast8_t chan = 0U; chan < 3U; chan ++){
//  sound_ll_reseteffects(chan);
//  sound_ll_setwaveform(chan, SOUND_LL_WAVE_SINE);
// }

// sound_ll_note(0U, FREQS_A4, 0xFU);
// sound_ll_setfreqsweep(0U, 0x7FFBU);
// sound_ll_setvolsweep(0U, 0x0010U);
// sound_ll_setfreqvib(0U, SOUND_LL_WAVE_DISTSINE, 5U);
// sound_ll_setvolvib(0U, SOUND_LL_WAVE_DISTSINE, 1U);

// sound_ll_setwaveform(1U, SOUND_LL_WAVE_TRIANGLE);
// sound_ll_note(1U, FREQS_A4, 0xFU);
// sound_ll_setfreqsweep(1U, 0x8001U);
// sound_ll_setvolsweep(1U, 0x0010U);

 /* Main loop */

 Game_Start();
 bool ingame = true;
 uint_fast8_t stp = 0U;

 while(1){

  /* Run game */

  if (ingame){
   if (!(Game_Frame())){
    GameOver_Start();
    ingame = false;
   }
  }else{
   if (!(GameOver_Frame())){
    Game_Start();
    ingame = true;
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

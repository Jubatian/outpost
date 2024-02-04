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


#include "game.h"
#include "graphics_bg.h"
#include "grsprite.h"
#include "control_ll.h"
#include "grtext_ll.h"
#include "palette_ll.h"
#include "text.h"
#include "dragonwave.h"
#include "bullet.h"
#include "targeting.h"
#include "town.h"
#include "memsetup.h"
#include "soundpatch.h"



/** Deletion prep time */
#define GAME_DEL_PREP     45U
/** Deletion unit time (adds up for each level) */
#define GAME_DEL_UNIT     30U

/** Gold option select: End turn */
#define GAME_OPT_END      0U
/** Gold option select: Add population */
#define GAME_OPT_POP      1U
/** Gold option select: Add swap */
#define GAME_OPT_SWAP     2U
/** Gold option select: Anyswap */
#define GAME_OPT_ANYSWAP  3U
/** Count of options */
#define GAME_OPT_COUNT    4U

/** Spending limit per purchase (for pop and swaps) */
#define GAME_SPEND_LIMIT  50U

/** Cost of one population (base) */
#define GAME_COST_POP     5U
/** Cost of one swap (base) */
#define GAME_COST_SWAP    3U
/** Cost of anyswap */
#define GAME_COST_ANYSWAP 10U



/** Current town population (0: Game over / not running) */
static uint_fast16_t game_pop = 0U;

/** Remaining swaps in the current turn */
static uint_fast8_t  game_swaps;

/** Turns survived */
static uint_fast16_t game_turns;

/** Current gold */
static uint_fast16_t game_gold;

/** Select or hover cursor mode */
static bool          game_select;

/** Whether in gold options UI */
static bool          game_goldactive;

/** Gold option selector position */
static uint_fast8_t  game_goldselect;

/** Carried over swaps */
static uint_fast8_t  game_swapcarry;

/** Extra swap option usages in turn */
static uint_fast8_t  game_boughtswaps;

/** Extra population option usages throughout the game*/
static uint_fast16_t game_boughtpop;

/** Timeout for dropping an item */
static uint_fast8_t  game_deltout;

/** Maximum time for dropping this item */
static uint_fast8_t  game_maxdeltime;

/** Cursor X position */
static uint_fast8_t  game_xpos;

/** Cursor Y position */
static uint_fast8_t  game_ypos;

/** Anyswap source X position */
static uint_fast8_t  game_xposanyswap;

/** Anyswap source Y position */
static uint_fast8_t  game_yposanyswap;

/** Frame counter */
static uint_fast8_t  game_fctr;

/** Text line count (not rows, for animating the text area) */
static uint_fast8_t  game_textlines;

/** Request start of dragon wave */
static bool          game_startwave;



void Game_Reset(void)
{
 /* No active game */
 game_pop = 0U;
}



void Game_Start(void)
{
 game_pop = 10U;
 game_swaps = 5U;
#ifdef STRESSTEST
 game_turns = 100U;
#else
 game_turns = 0U;
#endif
 game_gold = 0U;
 game_select = false;
 game_goldactive = false;
 game_goldselect = GAME_OPT_END;
 game_swapcarry = 0U;
 game_boughtswaps = 0U;
 game_boughtpop = 0U;
 game_xpos = 0U;
 game_ypos = PLAYFIELD_HEIGHT - 1U;
 game_xposanyswap = 0U;
 game_yposanyswap = 0U;
 game_fctr = 0U;
 game_textlines = 0U;
 game_startwave = false;
 game_maxdeltime = 0U;
 MemSetup(MEMSETUP_GAMESWAP);
 Playfield_Reset();
 Town_Reset();
}



/**
 * @brief   Output numeric data
 *
 * @param   dest:  Destination to output to
 * @param   val:   Value to output
 * @param   dig:   Number of digits
 */
static void Game_DecOut(uint8_t* dest, uint_fast16_t val, uint_fast8_t dig)
{
 uint_fast32_t bcd = text_bin16bcd(val);
 while (dig != 0U){
  dig --;
  uint_fast8_t cchr = (bcd >> (4U * dig)) & 0xFU;
  cchr += '0';
  *dest = cchr;
  dest ++;
 }
}



/**
 * @brief   Gold options user interface
 */
static void Game_GoldUI(void)
{
 game_yposanyswap = 0U; /* Cancel anyswap if re-entering this menu */

 uint_fast8_t selopt = game_goldselect;
 uint_fast8_t optcnt = 0U;
 uint_fast8_t spendlim = GAME_SPEND_LIMIT;
 uint8_t costs[GAME_OPT_COUNT];
 uint8_t opts[GAME_OPT_COUNT];

 uint_fast16_t popcostincr = game_boughtpop / (game_turns + 1U);

 costs[GAME_OPT_END] = 0U;
 costs[GAME_OPT_POP] = GAME_COST_POP + (popcostincr * (GAME_COST_POP / 2U));
 costs[GAME_OPT_SWAP] = GAME_COST_SWAP + (game_boughtswaps * (GAME_COST_SWAP / 2U));
 costs[GAME_OPT_ANYSWAP] = GAME_COST_ANYSWAP;

 if (spendlim > game_gold){
  spendlim = game_gold;
 }

 /* Output available options. Note that selpos is intentionally left zero if
 ** the option is missing, in this case keeping on hitting ACTION should
 ** simply have no effect, retaining the selection (avoids confusion when
 ** intending to keep spending gold on the same option) */

 GrText_LL_SetParams(game_textlines, true, 0xBFU, 0x01U, 0xB7U);
 uint8_t* textarea = GrText_LL_GetRowPtr(0U);
 text_fill(textarea, 0U, 40U);
 uint_fast8_t pos = 0U;
 uint_fast8_t selpos = 0U;

 for (uint_fast8_t optid = 0U; optid < GAME_OPT_COUNT; optid ++){
  if (costs[optid] <= spendlim){
   uint_fast8_t txtsel = TEXT_END + (optid * 2U);
   if (selopt == optid){
    txtsel ++;
    selpos = optcnt;
   }
   opts[optcnt] = optid;
   optcnt ++;
   pos += text_genstring(&textarea[pos], txtsel) + 1U;
  }
 }

 if (selopt != GAME_OPT_END){
  Game_DecOut(&textarea[38U], costs[selopt], 2U);
  if (selopt == GAME_OPT_POP){
   Game_DecOut(&textarea[33U], game_pop, 3U);
  }
  if (selopt == GAME_OPT_SWAP){
   Game_DecOut(&textarea[33U], game_swaps, 3U);
  }
  if ((selopt == GAME_OPT_POP) || (selopt == GAME_OPT_SWAP)){
   textarea[36U] = 0x1EU; /* '<' of arrow */
   textarea[37U] = 0x1FU; /* '=' of arrow */
  }
 }

 /* Handle selections */

 uint_fast8_t ctrl = Control_LL_Get(CONTROL_LL_ALL);

 if (((ctrl & CONTROL_LL_LEFT) != 0U) && (selpos > 0U)){
  selpos --;
  selopt = opts[selpos];
 }
 if (((ctrl & CONTROL_LL_RIGHT) != 0U) && ((selpos + 1U) < optcnt)){
  selpos ++;
  selopt = opts[selpos];
 }
 if (((ctrl & CONTROL_LL_LEFT) != 0U) || ((ctrl & CONTROL_LL_RIGHT) != 0U)){
  if ((optcnt <= selpos) || (opts[selpos] != selopt)){
   selpos = 0U; /* In case ran out of funds, let repositioning on end turn */
   selopt = opts[selpos];
  }
 }
 game_goldselect = selopt;

 if (((ctrl & CONTROL_LL_ACTION) != 0U)){
  uint_fast8_t cost = costs[selopt];
  switch (selopt){
   case GAME_OPT_END:
    game_swapcarry = 4U + (game_pop / 10U);
    if (game_swapcarry > game_swaps){
     game_swapcarry = game_swaps;
    }
    game_swaps = 0U;
    game_startwave = true;
    game_goldactive = false;
    break;
   case GAME_OPT_POP:
    if (cost <= spendlim){
     game_gold -= cost;
     game_pop ++;
     game_boughtpop ++;
    }
    break;
   case GAME_OPT_SWAP:
    if (cost <= spendlim){
     game_gold -= cost;
     game_swaps ++;
     game_boughtswaps ++;
    }
    break;
   case GAME_OPT_ANYSWAP:
    if (cost <= spendlim){
     /* Note: Don't spend the gold here so it may be cancelled */
     game_xposanyswap = game_xpos;
     game_yposanyswap = game_ypos;
     game_select = false;
     game_goldactive = false;
    }
    break;
   default:
    break;
  }
 }

 if (((ctrl & CONTROL_LL_ALTERN) != 0U) || ((ctrl & CONTROL_LL_MENU) != 0U)){
  game_goldactive = false;
 }
}



/**
 * @brief   Main game user interactions
 *
 * @param   pfrep:  Playfield activity report structure
 */
static void Game_PlayfieldUI(playfield_activity_tdef const* pfrep)
{
 uint_fast8_t xpos = game_xpos;
 uint_fast8_t ypos = game_ypos;
 bool         sel  = game_select;

 /* Handle text area */

 GrText_LL_SetParams(game_textlines, true, 0xBFU, 0x01U, 0xB7U);
 uint8_t* textarea = GrText_LL_GetRowPtr(0U);
 text_fill(textarea, 0U, 40U);
 uint_fast8_t pos = 0U;
 pos += text_genstring(&textarea[pos], TEXT_GOLD);
 Game_DecOut(&textarea[pos], game_gold, 4U);
 pos += 6U;
 pos += text_genstring(&textarea[pos], TEXT_SWAPS);
 Game_DecOut(&textarea[pos], game_swaps, 3U);
 pos += 5U;
 pos += text_genstring(&textarea[pos], TEXT_POP);
 Game_DecOut(&textarea[pos], game_pop, 3U);
 pos += 5U;
 pos += text_genstring(&textarea[pos], TEXT_TURN);
 Game_DecOut(&textarea[pos], game_turns, 3U);

 if (pfrep->active){

  /* Active playfield - no interaction, just watch it happening */

  if (sel){
   uint_fast8_t act = Playfield_GetActivity(xpos, ypos);
   if ( (act == PLAYFIELD_ACT_MDEL) ||
        (act == PLAYFIELD_ACT_FALL) ||
        (act == PLAYFIELD_ACT_MATCH) ){
    /* Selection is cancelled if item falls away or matches (non-gold matches
    ** could be maintained, but feels a bit off to me, more consistent if
    ** they always release) */
    sel = false;
   }
  }
  /* Read controllers, stacking up actions to trigger later, matches
  ** however clear this to avoid stacking up too old triggers */
  uint_fast8_t clrmask = 0U;
  if (pfrep->match){
   clrmask = CONTROL_LL_ALL;
  }
  (void)(Control_LL_Get(clrmask));

 }else{

  /* Inactive playfield - interactive phase */

  uint_fast8_t ctrl = Control_LL_Get(CONTROL_LL_ALL);

  uint_fast8_t pypos = ypos;
  uint_fast8_t pxpos = xpos;
  if (((ctrl & CONTROL_LL_ACTION) != 0U)){
   if (game_yposanyswap != 0U){
    if ((game_xposanyswap != xpos) || (game_yposanyswap != ypos)){
     if (game_gold > GAME_COST_ANYSWAP){
      game_gold -= GAME_COST_ANYSWAP; /* Cost applied here (allows cancelling) */
      Playfield_Swap(game_xposanyswap, game_yposanyswap, xpos, ypos);
      game_swaps --;
     }
     game_yposanyswap = 0U;
    }
    sel = false;
   }else{
    sel = !sel;
   }
   if (sel){
    /* Prepare deletion timeout */
    uint_fast8_t dmax;
    switch (Playfield_GetItem(xpos, ypos)){
     case PLAYFIELD_TOWER1:
     case PLAYFIELD_ARROW1:
     case PLAYFIELD_CANNON1:
     case PLAYFIELD_SUPPLY1: dmax = GAME_DEL_PREP + (2U * GAME_DEL_UNIT); break;
     case PLAYFIELD_TOWER2:
     case PLAYFIELD_ARROW2:
     case PLAYFIELD_CANNON2:
     case PLAYFIELD_SUPPLY2: dmax = GAME_DEL_PREP + (3U * GAME_DEL_UNIT); break;
     case PLAYFIELD_TOWER3:
     case PLAYFIELD_ARROW3:
     case PLAYFIELD_CANNON3:
     case PLAYFIELD_SUPPLY3: dmax = GAME_DEL_PREP + (4U * GAME_DEL_UNIT); break;
     case PLAYFIELD_TOWER4:
     case PLAYFIELD_ARROW4:
     case PLAYFIELD_CANNON4:
     case PLAYFIELD_SUPPLY4: dmax = GAME_DEL_PREP + (5U * GAME_DEL_UNIT); break;
     default:                dmax = GAME_DEL_PREP + GAME_DEL_UNIT; break;
    }
    game_maxdeltime = dmax;
    game_deltout = 0U;
   }
  }
  if (((ctrl & CONTROL_LL_ALTERN) != 0U) || ((ctrl & CONTROL_LL_MENU) != 0U)){
   game_goldactive = true;
  }
  if (((ctrl & CONTROL_LL_UP)     != 0U) && (ypos > 1U)){ ypos --; }
  if (((ctrl & CONTROL_LL_DOWN)   != 0U) && (ypos < 6U)){ ypos ++; }
  if (((ctrl & CONTROL_LL_LEFT)   != 0U) && (xpos > 0U)){ xpos --; }
  if (((ctrl & CONTROL_LL_RIGHT)  != 0U) && (xpos < 5U)){ xpos ++; }

  if ((pypos != ypos) || (pxpos != xpos)){
   soundpatch_play(SOUNDPATCH_CH_ALL, SOUNDPATCH_STEP);
  }

  if (sel){
   if (pypos != ypos){ pxpos = xpos; }
   if ((pypos != ypos) || (pxpos != xpos)){
    Playfield_Swap(pxpos, pypos, xpos, ypos);
    soundpatch_play(SOUNDPATCH_CH_ALL, SOUNDPATCH_SWAP);
    game_swaps --;
   }
  }
  if (game_maxdeltime != 0U){
   if ((Control_LL_GetHolds() & CONTROL_LL_ACTION) == 0U){
    if (game_deltout > GAME_DEL_PREP){
     /* Was already in deleting, then cancel the selection */
     sel = false;
    }
    game_maxdeltime = 0U;
   }else{
    /* Deletion possibly in progress */
    if (game_deltout < game_maxdeltime){
     game_deltout ++;
    }else{
     sel = false;
     game_maxdeltime = 0U;
     Playfield_Delete(xpos, ypos);
     game_swaps --;
    }
   }
  }
  if (game_swaps == 0U){
   /* Swaps used up, start dragon wave */
   game_startwave = true;
  }

 }

 uint_fast8_t cframe = game_fctr << 4;
 uint_fast8_t ctyp = GRSPRITE_CURSOR_HOVER;
 if (sel){
  if ((game_maxdeltime <= GAME_DEL_PREP) || (game_deltout <= GAME_DEL_PREP)){
   ctyp = GRSPRITE_CURSOR_SELECT;
  }else{
   ctyp = GRSPRITE_CURSOR_DELETE;
   uint_fast8_t tottime = game_maxdeltime - GAME_DEL_PREP;
   uint_fast8_t curtime = game_deltout - GAME_DEL_PREP;
   cframe = (uint_fast8_t)(((uint_fast16_t)(curtime) << 8) / tottime);
  }
 }
 GrSprite_Cursor(ctyp, cframe, xpos, ypos);
 if (game_yposanyswap != 0U){
  GrSprite_Cursor(GRSPRITE_CURSOR_ANYSWAP, cframe, game_xposanyswap, game_yposanyswap);
 }

 game_xpos = xpos;
 game_ypos = ypos;
 game_select = sel;
}



bool Game_Frame(void)
{
 if (game_pop == 0U){
  return false;
 }

 Palette_LL_FadeIn(4U);
 GrSprite_Reset();

 /* Run playfield logic and corresponding background display */

 playfield_activity_tdef pfreport;
 Playfield_Tick(&pfreport);
 Graphics_BG_DrawPlayfield();
 game_gold += pfreport.gold;
 Town_SetPop(game_pop);
 if (pfreport.match){
  soundpatch_play(SOUNDPATCH_CH_ALL, SOUNDPATCH_MATCH);
 }

 if (game_swaps == 0U){

  /* Process dragon wave if one is progressing */

  if (game_startwave){

   if (!(pfreport.active)){
    MemSetup(MEMSETUP_GAMEWAVE);
    DragonWave_Setup(game_turns);
    game_startwave = false;
   }

  }else if (!DragonWave_IsEnded()){

   DragonWave_Tick();
   Targeting_Tick();
   Bullet_Tick();
   GrSprite_AddDragons();
   GrSprite_AddBullets();
   uint_fast8_t popeat;
   switch (DragonWave_PopArriving()){
    case 0U: popeat =  1U; break;
    case 1U: popeat =  2U; break;
    case 2U: popeat =  6U; break;
    case 3U: popeat = 18U; break;
    default: popeat =  0U; break; /* No dragon */
   }
   if (game_pop > popeat){
    game_pop -= popeat;
   }else{
    game_pop = 0U;
   }
   if (popeat > 0U){
    soundpatch_play(SOUNDPATCH_CH_ALL, SOUNDPATCH_CHOMP);
   }

  }else{

   MemSetup(MEMSETUP_GAMESWAP);
   game_pop ++; /* Population increments at end of turn */
   game_swaps = 4U + (game_pop / 10U) + game_swapcarry;
   game_swapcarry = 0U;
   game_select = false; /* On turn start cursor hovers (no selection) */
   game_boughtswaps = 0U;
   game_turns ++;
  }

  /* Handle text area */

  if (game_textlines > 0U){
   game_textlines --;
  }
  GrText_LL_SetParams(game_textlines, true, 0xBFU, 0x01U, 0xB7U);

 }else{

  if (game_textlines < GrText_LL_GetMaxLines()){
   game_textlines ++;
  }

  if (game_goldactive){
   Game_GoldUI();
  }else{
   Game_PlayfieldUI(&pfreport);
  }
 }

 /* Manage frame counter and end */

 game_fctr ++;

 return (game_pop != 0U);
}



uint_fast16_t Game_Score_Turns(void)
{
 return game_turns;
}

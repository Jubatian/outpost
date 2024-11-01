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


#include "hiscore.h"
#include "nvstore_ll.h"



#if (NVSTORE_LL_SIZE < (HISCORE_NAME_MAX * HISCORE_TABLE_SIZE))
#error "NV Storage size is too small for the score table!"
#endif



void HiScore_DepackRaw(uint8_t const* raw, uint8_t* name)
{
 for (uint_fast8_t pos = 0U; pos < HISCORE_NAME_MAX; pos ++){
  uint8_t databyte = raw[pos] & 0x3FU;
  uint8_t namechar;
  if (databyte == 0U){
   namechar = ' ';
  }else if (databyte < (1U + 26U)){
   namechar = 'a' + (databyte - 1U);
  }else if (databyte < (27U + 26U)){
   namechar = 'A' + (databyte - 27U);
  }else if (databyte < (53U + 10U)){
   namechar = '0' + (databyte - 53U);
  }else{
   namechar = '-';
  }
  name[pos] = namechar;
 }
}



/**
 * @brief   Depacks string from data entry
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to read data from
 * @param   name:   Output name
 */
static void HiScore_DepackName(
    uint8_t const* data, uint_fast8_t entry, uint8_t* name)
{
 if (entry >= HISCORE_TABLE_SIZE){
  return;
 }
 uint_fast8_t dataaddr = entry * HISCORE_NAME_MAX;
 HiScore_DepackRaw(&data[dataaddr], name);
}



/**
 * @brief   Packs string into data entry. Erases entry's score!
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to write data to
 * @param   name:   Input name
 */
static void HiScore_PackName(
    uint8_t* data, uint_fast8_t entry, uint8_t const* name)
{
 if (entry >= HISCORE_TABLE_SIZE){
  return;
 }
 uint_fast8_t dataaddr = entry * HISCORE_NAME_MAX;
 bool nameend = false;
 for (uint_fast8_t pos = 0U; pos < HISCORE_NAME_MAX; pos ++){
  uint8_t namechar;
  if (!nameend){
   namechar = name[pos];
   if (namechar == 0U){
    nameend = true;
   }
  }
  if (nameend){
   namechar = ' ';
  }
  data[dataaddr + pos] = HISCORE_ASCII2RAW(namechar);
 }
}



/**
 * @brief   Copies raw name into data entry. Erases entry's score!
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to write data to
 * @param   raw:    Input raw name
 */
static void HiScore_CopyRaw(
    uint8_t* data, uint_fast8_t entry, uint8_t const* raw)
{
 if (entry >= HISCORE_TABLE_SIZE){
  return;
 }
 uint_fast8_t dataaddr = entry * HISCORE_NAME_MAX;
 for (uint_fast8_t pos = 0U; pos < HISCORE_NAME_MAX; pos ++){
  data[dataaddr + pos] = raw[pos] & 0x3FU;
 }
}



/**
 * @brief   Depacks months survived from data entry
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to read data from
 * @return          Months survived
 */
static uint_fast8_t HiScore_DepackMonths(
    uint8_t const* data, uint_fast8_t entry)
{
 uint_fast8_t months = 0U;
 uint_fast8_t dataaddr = entry * HISCORE_NAME_MAX;
 for (uint_fast8_t pos = 0U; pos < 4U; pos ++){
  months = (months << 2) | (data[dataaddr + pos] >> 6);
 }
 return months;
}



/**
 * @brief   Depacks total pop from data entry
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to read data from
 * @return          Total pop
 */
static uint_fast8_t HiScore_DepackPop(
    uint8_t const* data, uint_fast8_t entry)
{
 uint_fast16_t pop = 0U;
 uint_fast8_t dataaddr = (entry * HISCORE_NAME_MAX) + 4U;
 for (uint_fast8_t pos = 0U; pos < 6U; pos ++){
  pop = (pop << 2) | (data[dataaddr + pos] >> 6);
 }
 return pop;
}



/**
 * @brief   Packs months survived onto data entry
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to read data from
 * @param   months: Months survived
 */
static void HiScore_PackMonths(
    uint8_t* data, uint_fast8_t entry, uint_fast8_t months)
{
 uint_fast8_t dataaddr = entry * HISCORE_NAME_MAX;
 for (uint_fast8_t pos = 0U; pos < 4U; pos ++){
  data[dataaddr + pos] |= months & 0xC0U;
  months <<= 2;
 }
}



/**
 * @brief   Packs total pop onto data entry
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to read data from
 * @param   pop:    Total pop
 */
static void HiScore_PackPop(
    uint8_t* data, uint_fast8_t entry, uint_fast16_t pop)
{
 uint_fast8_t dataaddr = (entry * HISCORE_NAME_MAX) + 4U;
 for (uint_fast8_t pos = 0U; pos < 6U; pos ++){
  data[dataaddr + pos] |= (pop >> 4) & 0xC0U;
  pop <<= 2;
 }
}



/**
 * @brief   Compare two high score entries
 *
 * @param   data:   Stored data to compare scores in
 * @param   entry1: First entry to compare
 * @param   entry2: Second entry to compare
 * @return          Higher entry or entry1 if equal
 */
static uint_fast8_t HiScore_Compare(
    uint8_t* data, uint_fast8_t entry1, uint_fast8_t entry2)
{
 /* The way data is stored, the high two bits of entries can be compared
 ** sequentially to determine which is higher */
 uint_fast8_t pos = 0U;
 uint_fast8_t addr1 = (entry1 * HISCORE_NAME_MAX);
 uint_fast8_t addr2 = (entry2 * HISCORE_NAME_MAX);
 while (pos < HISCORE_NAME_MAX){
  uint_fast8_t byte1 = data[addr1 + pos] & 0xC0U;
  uint_fast8_t byte2 = data[addr2 + pos] & 0xC0U;
  if (byte1 > byte2){
   return entry1;
  }
  if (byte2 > byte1){
   return entry2;
  }
  pos ++;
 }
 return entry1;
}



/**
 * @brief   Get entry by rank
 *
 * @param   data:   Stored data to get from
 * @param   rank:   What rank to get (0: Highest)
 * @return          The entry which has the requested rank
 */
static uint_fast8_t HiScore_GetEntryByRank(
    uint8_t* data, uint_fast8_t rank)
{
 uint_fast8_t first;
 uint_fast8_t mid;
 uint_fast8_t last;
 if (HiScore_Compare(data, 0U, 1U) == 0U){
  first = 0U; /* Might be corrected below */
  if (HiScore_Compare(data, 1U, 2U) == 1U){
   mid = 1U;
   last = 2U;
  }else{
   last = 1U;
   if (HiScore_Compare(data, 0U, 2U) == 0U){
    mid = 2U;
   }else{
    first = 2U;
    mid = 0U;
   }
  }
 }else{
  first = 1U; /* Might be corrected below */
  if (HiScore_Compare(data, 0U, 2U) == 0U){
   mid = 0U;
   last = 2U;
  }else{
   last = 0U;
   if (HiScore_Compare(data, 1U, 2U) == 1U){
    mid = 2U;
   }else{
    first = 2U;
    mid = 1U;
   }
  }
 }
 if (rank == 0U){
  return first;
 }else if (rank == 1U){
  return mid;
 }else{
  return last;
 }
}



/**
 * @brief   Test score against one in the table
 *
 * @param   data:   Stored data
 * @param   entry:  Which entry to test against
 * @param   months: Survived months
 * @param   pop:    Total pop
 * @return          If the provided score is higher or matches, true
 */
static bool HiScore_CompareScore(
    uint8_t* data, uint_fast8_t entry, uint_fast8_t months, uint_fast16_t pop)
{
 uint_fast8_t entrypop = HiScore_DepackPop(data, entry);
 if (entrypop > pop){
  return false;
 }
 if (entrypop == pop){
  if (HiScore_DepackMonths(data, entry) > months){
   return false;
  }
 }
 return true;
}



/**
 * @brief   Read high score data
 *
 * Provides initialization in case the data doesn't exist yet
 *
 * @param   data:   Data buffer to read it into
 */
static void HiScore_ReadData(uint8_t* data)
{
 HiScore_Data_Fill(data);
 NVStore_LL_Read(data);
}



bool HiScore_IsEligible(uint_fast8_t months, uint_fast16_t pop)
{
 uint8_t scoredata[NVSTORE_LL_SIZE];
 HiScore_ReadData(&scoredata[0]);
 uint_fast8_t last = HiScore_GetEntryByRank(&scoredata[0], 0xFFU);
 return HiScore_CompareScore(&scoredata[0], last, months, pop);
}



void HiScore_Send(uint8_t const* name, uint_fast8_t months, uint_fast16_t pop)
{
 uint8_t rawname[HISCORE_NAME_MAX];
 HiScore_PackName(&rawname[0], 0U, name);
 HiScore_SendRaw(&rawname[0], months, pop);
}



void HiScore_SendRaw(uint8_t const* raw, uint_fast8_t months, uint_fast16_t pop)
{
 uint8_t scoredata[NVSTORE_LL_SIZE];
 HiScore_ReadData(&scoredata[0]);
 uint_fast8_t last = HiScore_GetEntryByRank(&scoredata[0], 0xFFU);
 if (!(HiScore_CompareScore(&scoredata[0], last, months, pop))){
  return;
 }
 /* Always the last score is replaced (minimizing NV storage writes), scores
 ** are not in order in the table! */
 HiScore_CopyRaw(&scoredata[0], last, raw);
 HiScore_PackMonths(&scoredata[0], last, months);
 HiScore_PackPop(&scoredata[0], last, pop);
 NVStore_LL_Write(&scoredata[0]);
}



void HiScore_Get(
    uint_fast8_t rank, uint8_t* name, uint_fast8_t* months, uint_fast16_t* pop)
{
 uint8_t scoredata[NVSTORE_LL_SIZE];
 HiScore_ReadData(&scoredata[0]);
 uint_fast8_t entry = HiScore_GetEntryByRank(&scoredata[0], rank);
 HiScore_DepackName(&scoredata[0], entry, name);
 *months = HiScore_DepackMonths(&scoredata[0], entry);
 *pop = HiScore_DepackPop(&scoredata[0], entry);
}

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


#include "nvstore_ll.h"
#include <uzebox.h>


/** Data ID of the game's EEPROM block */
#define NVSTORE_LL_EEPROM_ID  0xF0A0U

/** EEPROM block size */
#define NVSTORE_LL_BLOCKSIZE  (NVSTORE_LL_SIZE + 2U)

/** Count of EEPROM blocks */
#define NVSTORE_LL_BLOCKCOUNT 64U

/** Invalid address */
#define NVSTORE_LL_INVALID    0xFFFFU



/**
 * @brief   Read EEPROM block ID
 *
 * @param   addr:   Address to read block ID from
 * @return          EEPROM block ID
 */
static uint_fast16_t NVStore_LL_ReadID(uint_fast16_t addr)
{
 return ReadEeprom16(addr);
}



static uint_fast16_t NVStore_LL_Locate(bool allocfree)
{
 if (!isEepromFormatted()){
  return NVSTORE_LL_INVALID;
 }
 uint_fast16_t idaddress;
 uint_fast16_t freeaddress;
 bool found = false;
 bool freefound = false;
 for (uint_fast8_t blockidx = 0U; blockidx < NVSTORE_LL_BLOCKCOUNT; blockidx ++){
  uint_fast16_t blockaddress = ((uint_fast16_t)(blockidx)) * NVSTORE_LL_BLOCKSIZE;
  uint_fast16_t id = NVStore_LL_ReadID(blockaddress);
  if (id == NVSTORE_LL_EEPROM_ID){
   idaddress = blockaddress;
   found = true;
   break;
  }
  if (id == EEPROM_FREE_BLOCK){
   freeaddress = blockaddress;
   freefound = true;
  }
 }
 if (!found){
  if ((!freefound) || (!allocfree)){
   return NVSTORE_LL_INVALID;
  }
  WriteEeprom16(freeaddress, NVSTORE_LL_EEPROM_ID);
  idaddress = freeaddress;
 }
 return idaddress + 2U;
}



bool NVStore_LL_Read(uint8_t* data)
{
 uint_fast16_t dataaddress = NVStore_LL_Locate(false);
 if (dataaddress == NVSTORE_LL_INVALID){
  return false;
 }
 ReadEepromBytes(dataaddress, data, NVSTORE_LL_SIZE);
 return true;
}



bool NVStore_LL_Write(uint8_t const* data)
{
 uint_fast16_t dataaddress = NVStore_LL_Locate(true);
 if (dataaddress == NVSTORE_LL_INVALID){
  return false;
 }
 WriteEepromBytes(dataaddress, data, NVSTORE_LL_SIZE);
 return true;
}

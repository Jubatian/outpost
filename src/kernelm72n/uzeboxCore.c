/*
 *  Uzebox Kernel
 *  Copyright (C) 2008-2009 Alec Bourque
 *  Optimized and trimmed to the game by Sandor Zsuga (Jubatian), 2016
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
 *
 *  Uzebox is a reserved trade mark
*/

#include <stdbool.h>
#include <avr/io.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include "uzebox.h"

#include <util/atomic.h>

/* Video modes may redefine stack top to allocate workspace */
#ifndef UZEBOX_STACK_TOP
#define UZEBOX_STACK_TOP 0x10FF
#endif

#define Wait200ns() asm volatile("lpm\n\tlpm\n\t");
#define Wait100ns() asm volatile("lpm\n\t");

//Callbacks defined in each video modes module
extern void DisplayLogo(void);
extern void InitializeVideoMode(void);

extern void initialize_mixer(void); /* soundMixerMiniVSync.s */
extern void ResetAudio(void);

extern unsigned char sync_pulse;
extern unsigned char sync_flags;
extern struct TrackStruct tracks[CHANNELS];
extern volatile unsigned int joypad1_status_lo;
#if (P2_DISABLE == 0)
extern volatile unsigned int joypad2_status_lo;
#endif
extern unsigned char tileheight, textheight;
extern unsigned char line_buffer[];
extern unsigned char render_start;
extern unsigned char playback_start;
extern unsigned char render_lines_count;
extern unsigned char render_lines_count_tmp;
extern unsigned char first_render_line;
extern unsigned char first_render_line_tmp;


const u8 eeprom_format_table[] PROGMEM ={
   (u8)(EEPROM_SIGNATURE),      // (u16)
   (u8)(EEPROM_SIGNATURE>>8),   //
   EEPROM_HEADER_VER,           // (u8)
   EEPROM_BLOCK_SIZE,           // (u8)
   EEPROM_HEADER_SIZE,          // (u8)
   1,                           // (u8) hardwareVersion
   0,                           // (u8) hardwareRevision
   0x38,0x8,                    // (u16) standard uzebox & fuzebox features
   0,0,                         // (u16) extended features
   0,0,0,0,0,0,                 // (u8[6]) MAC
   0,                           // (u8) colorCorrectionType
   0,0,0,0,                     // (u32) game CRC
   0,                           // (u8) bootloader flags
   0,0,0,0,0,0,0,0,0            // (u8[9]) reserved
};



extern void wdt_randomize(void);

void wdt_init(void) __attribute__((naked)) __attribute__((section(".init7")));
void Initialize(void) __attribute__((naked)) __attribute__((section(".init8")));

void wdt_init(void)
{

#if TRUE_RANDOM_GEN == 1
	wdt_randomize();
#endif

    MCUSR = 0;
    wdt_disable();
    return;
}


/**
 * Dynamically sets the rasterizer parameters:
 * firstScanlineToRender = First scanline to render
 * scanlinesToRender     = Total number of vertical lines to render.
 */
void SetRenderingParameters(u8 firstScanlineToRender, u8 scanlinesToRender){
	render_lines_count_tmp=scanlinesToRender;
	first_render_line_tmp=firstScanlineToRender;
}


/*
 * I/O initialization table
 * The io_set macro is used to build an array of register,value pairs.
 * Using an array take less flash than discrete AVR instrustructions.
 */
#define io_set(a,b) ((_SFR_MEM_ADDR(a) & 0xff) + ((b)<<8))

static const u16 io_table[] PROGMEM ={
	io_set(TCCR1B,0x00),	//stop timers
	io_set(TCCR0B,0x00),

	io_set(SPL, UZEBOX_STACK_TOP & 0xFFU),
	io_set(SPH, UZEBOX_STACK_TOP >> 8),

	io_set(DDRC,0xff), 		//video dac

	io_set(DDRD,   (1 << PD7) | (1 << PD6) | (1 << PD4) | (1 << PD1)), // Audio-out, Chip Select, LED, UART TX
	io_set(PORTD,  (1 << PD6) | (1 << PD4) | (1 << PD5) | (1 << PD3) | (1 << PD2) | (1 << PD0)), // Set CS high, LED on, pull-up for all inputs (PD3, PD2 are buttons)

	//setup port A for joypads

	io_set(DDRA,   0x0C), // Set only control lines (CLK, Latch) as outputs
	io_set(PORTA,  0xFB), // Activate pullups on the data lines and unused pins

	/* Set up video timing according to display lines (136 cycles LOW pulses) */

	io_set(TCNT1H, 0),
	io_set(TCNT1L, 0),

	io_set(OCR1AH, (1819U) >> 8),
	io_set(OCR1AL, (1819U) & 0xFFU),
	io_set(OCR1BH, (67U + 4U) >> 8),
	io_set(OCR1BL, (67U + 4U) & 0xFFU),

	io_set(TCCR1B, (1 << WGM12) + (1 << CS10)),    /* CTC mode, use OCR1A for match */
	io_set(TIMSK1, (1 << OCIE1A) | (1 << OCIE1B)), /* Generate interrupt on match */

	//set clock divider counter for AD725 on TIMER0
	//outputs 14.31818Mhz (4FSC)
	io_set(TCCR0A,(1<<COM0A0)+(1<<WGM01)), //toggle on compare match + CTC
	io_set(OCR0A,0), //divide main clock by 2
	io_set(TCCR0B,(1<<CS00)), //enable timer, no pre-scaler

	//set sound PWM on TIMER2
	io_set(TCCR2A,(1<<COM2A1)+(1<<WGM21)+(1<<WGM20)), //Fast PWM
	io_set(OCR2A,0), //duty cycle (amplitude)
	io_set(TCCR2B,(1<<CS20)),  //enable timer, no pre-scaler

	io_set(DDRB,   (1 << SYNC_PIN) | (1 << VIDEOCE_PIN) | (1 << PB3) | (1 << PB7) | (1 << PB5)), // 4FSC, SCK, MOSI
	io_set(PORTB,  (1 << SYNC_PIN) | (1 << VIDEOCE_PIN) | (1 << PB6) | (1 << PB2) | (1 << PB1)), // Set sync & chip enable line to hi, MISO and unused pins pull-up
};


void Initialize(void){

	if(!isEepromFormatted()) FormatEeprom();

	cli();

	/* Reset audio */

	initialize_mixer();

	//The normal music player is entirely removed for this game
	//ResetAudio();

	/* Set video sync parameters so the VBlank initializes proper. */

	sync_flags = 0;
	sync_pulse = 1;
	render_lines_count_tmp = FRAME_LINES;
	first_render_line_tmp = FIRST_RENDER_LINE;

	InitializeVideoMode();

	//Initialize I/O registers
	u16 val;
	u8 *ptr;
	for(u8 j=0;j<(sizeof(io_table)>>1);j++){
		val=pgm_read_word(&io_table[j]);
		ptr=(u8*)(val&0xff);
		*ptr=val>>8;	
	}

	sei();

	DisplayLogo();
}


// Format eeprom, wiping all data to zero
void FormatEeprom(void) {

	// Set sig. so we don't format next time
	for (u8 i = 0; i < sizeof(eeprom_format_table); i++) {
		WriteEeprom(i,pgm_read_byte(&eeprom_format_table[i]));
	}

	// Write free blocks IDs
	for (u16 i = (EEPROM_BLOCK_SIZE*EEPROM_HEADER_SIZE); i < (64*EEPROM_BLOCK_SIZE); i+=EEPROM_BLOCK_SIZE) {
		WriteEeprom16(i, EEPROM_FREE_BLOCK);
	}

}

// Format eeprom, saving data specified in ids
void FormatEeprom2(u16 *ids, u8 count) {
	u8 j;
	u16 id;

	// Set sig. so we don't format next time
	for (u8 i = 0; i < 8; i++) {
		WriteEeprom(i,pgm_read_byte(&eeprom_format_table[i]));
	}

	// Paint unreserved free blocks
	for (int i = EEPROM_HEADER_SIZE; i < 64; i++) {
		id=ReadEeprom(i*EEPROM_BLOCK_SIZE)+(ReadEeprom((i*EEPROM_BLOCK_SIZE)+1)<<8);

		for (j = 0; j < count; j++) {
			if (id == ids[j])
				break;
		}

		if (j == count) {
			WriteEeprom16(i*EEPROM_BLOCK_SIZE,EEPROM_FREE_BLOCK);
		}
	}
}

//returns true if the EEPROM has been setup to work with the kernel.
bool isEepromFormatted(void){
	unsigned id;
	id=ReadEeprom16(0);
	return (id==EEPROM_SIGNATURE);
}

/*
 * Reads the power button status. Works for all consoles. 
 *
 * Returns: true if pressed.
 */
u8 ReadPowerSwitch(void){
	return !((PIND&((1<<PD3)+(1<<PD2)))==((1<<PD3)+(1<<PD2)));
}

/*
 * Write a data block in the specified block id. If the block does not exist, it is created.
 *
 * Returns: 0 on success or error codes
 */
char EepromWriteBlock(struct EepromBlockStruct *block){
	unsigned char i,nextFreeBlock=0;
	unsigned int destAddr=0,id;
	unsigned char *srcPtr=(unsigned char *)block;

	if(!isEepromFormatted()) return EEPROM_ERROR_NOT_FORMATTED;
	if(block->id==EEPROM_FREE_BLOCK || block->id==EEPROM_SIGNATURE) return EEPROM_ERROR_INVALID_BLOCK;

	//scan all blocks and get the adress of that block or the next free one.
	for(i=EEPROM_HEADER_SIZE;i<64;i++){
		id=ReadEeprom16(i*EEPROM_BLOCK_SIZE);
		if(id==block->id){
			destAddr=i*EEPROM_BLOCK_SIZE;
			break;
		}
		if(id==0xffff && nextFreeBlock==0) nextFreeBlock=i;
	}

	if(destAddr==0 && nextFreeBlock==0) return EEPROM_ERROR_FULL;
	if(nextFreeBlock!=0) destAddr=nextFreeBlock*EEPROM_BLOCK_SIZE;

	WriteEepromBytes(destAddr,srcPtr,EEPROM_BLOCK_SIZE);

	return 0;
}

/*
 * Reads a data block in the specified structure.
 *
 * Returns:
 *  0x00 = Success
 *  0x01 = EEPROM_ERROR_INVALID_BLOCK
 *  0x02 = EEPROM_ERROR_FULL
 *  0x03 = EEPROM_ERROR_BLOCK_NOT_FOUND
 *  0x04 = EEPROM_ERROR_NOT_FORMATTED
 */
char EepromReadBlock(unsigned int blockId,struct EepromBlockStruct *block){
	unsigned char i;
	unsigned int destAddr=0xffff,id;
	unsigned char *destPtr=(unsigned char *)block;

	if(!isEepromFormatted()) return EEPROM_ERROR_NOT_FORMATTED;
	if(blockId==EEPROM_FREE_BLOCK) return EEPROM_ERROR_INVALID_BLOCK;

	//scan all blocks and get the adress of that block
	for(i=0;i<32;i++){
		id=ReadEeprom16(i*EEPROM_BLOCK_SIZE);
		if(id==blockId){
			destAddr=i*EEPROM_BLOCK_SIZE;
			break;
		}
	}

	if(destAddr==0xffff) return EEPROM_ERROR_BLOCK_NOT_FOUND;

	ReadEepromBytes(destAddr,destPtr,EEPROM_BLOCK_SIZE);

	return 0;
}

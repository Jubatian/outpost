###############################################################################
# Makefile for the project Outpost
###############################################################################

## General
PROJECT = outpost
GAME    = outpost
INFO    = src/gameinfo.properties
MCU     = atmega644
TARGET  = $(GAME).elf
CC      = avr-gcc
PYTHON  = python3
OUTDIR  = _bin_
OBJDIR  = _obj_
DEPDIR  = _dep_
DIRS    = $(OUTDIR) $(OBJDIR) $(DEPDIR)

## Packrom (.uze)
PACKROM_DIR = .


## Game version string
VERSION_STR = v1.0


## Uzebox kernel settings
KERNEL_DIR = src/kernelm72n
KERNEL_OPTIONS  = -DVIDEO_MODE=72
KERNEL_OPTIONS += -DSOUND_MIXER=MIXER_TYPE_VSYNC
KERNEL_OPTIONS += -DINCLUDE_DEFAULT_WAVES=0
KERNEL_OPTIONS += -DM72_SPRITE_MODES=0x0002
KERNEL_OPTIONS += -DM72_ALIGNED_SEC=.align512

## Options common to compile, link and assembly rules
COMMON = -mmcu=$(MCU)

## Compile options common for all C compilation units.
CFLAGS  = $(COMMON)
CFLAGS += -Wall -gdwarf-2 -std=gnu99 -DF_CPU=28636360UL -Os -fsigned-char
CFLAGS += -ffunction-sections -fno-toplevel-reorder -fno-tree-switch-conversion
CFLAGS += -MMD -MP -MT $(*F).o -MF $(DEPDIR)/$(*F).d
CFLAGS += $(KERNEL_OPTIONS)
CFLAGS += -DVERSION_STR=\"$(VERSION_STR)\"

## Stress testing build
#CFLAGS += -DSTRESSTEST

## Assembly specific flags
ASMFLAGS  = $(COMMON)
ASMFLAGS += $(CFLAGS)
ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

## Linker flags
LDFLAGS  = $(COMMON)
LDFLAGS += -Wl,-Map=$(OUTDIR)/$(GAME).map
LDFLAGS += -Wl,-gc-sections
LDFLAGS += -T src/avr5_tower.x

## Intel Hex file production flags
HEX_FLASH_FLAGS = -R .eeprom


## Objects that must be built in order to link
OBJECTS  = $(OBJDIR)/uzeboxVideoEngineCore.o
OBJECTS += $(OBJDIR)/uzeboxCore.o
OBJECTS += $(OBJDIR)/uzeboxSoundEngineCore.o
OBJECTS += $(OBJDIR)/uzeboxVideoEngine.o

OBJECTS += $(OBJDIR)/fontwaves.o
OBJECTS += $(OBJDIR)/tileset.o
OBJECTS += $(OBJDIR)/spriteset.o
OBJECTS += $(OBJDIR)/dragonmaw.o
OBJECTS += $(OBJDIR)/spritecanvas.o
OBJECTS += $(OBJDIR)/random.o
OBJECTS += $(OBJDIR)/text.o
OBJECTS += $(OBJDIR)/dragonlayout.o
OBJECTS += $(OBJDIR)/dragonwave.o
OBJECTS += $(OBJDIR)/bullet.o
OBJECTS += $(OBJDIR)/targeting.o
OBJECTS += $(OBJDIR)/town.o
OBJECTS += $(OBJDIR)/game.o
OBJECTS += $(OBJDIR)/gameover.o
OBJECTS += $(OBJDIR)/title.o
OBJECTS += $(OBJDIR)/playfield.o
OBJECTS += $(OBJDIR)/graphics_bg.o
OBJECTS += $(OBJDIR)/grsprite.o
OBJECTS += $(OBJDIR)/memsetup.o
OBJECTS += $(OBJDIR)/soundpatch.o
OBJECTS += $(OBJDIR)/palette_ll.o
OBJECTS += $(OBJDIR)/sprite_ll.o
OBJECTS += $(OBJDIR)/grtext_ll.o
OBJECTS += $(OBJDIR)/control_ll.o
OBJECTS += $(OBJDIR)/sound_ll.o
OBJECTS += $(OBJDIR)/$(GAME).o

## Dependencies corresponding with each object
DEPS  = $(DEPDIR)/uzeboxVideoEngineCore.d
DEPS += $(DEPDIR)/uzeboxCore.d
DEPS += $(DEPDIR)/uzeboxSoundEngineCore.d
DEPS += $(DEPDIR)/uzeboxVideoEngine.d

DEPS += $(DEPDIR)/fontwaves.d
DEPS += $(DEPDIR)/tileset.d
DEPS += $(DEPDIR)/spriteset.d
DEPS += $(DEPDIR)/dragonmaw.d
DEPS += $(DEPDIR)/spritecanvas.d
DEPS += $(DEPDIR)/random.d
DEPS += $(DEPDIR)/text.d
DEPS += $(DEPDIR)/dragonlayout.d
DEPS += $(DEPDIR)/dragonwave.d
DEPS += $(DEPDIR)/bullet.d
DEPS += $(DEPDIR)/targeting.d
DEPS += $(DEPDIR)/town.d
DEPS += $(DEPDIR)/game.d
DEPS += $(DEPDIR)/gameover.d
DEPS += $(DEPDIR)/title.d
DEPS += $(DEPDIR)/playfield.d
DEPS += $(DEPDIR)/graphics_bg.d
DEPS += $(DEPDIR)/grsprite.d
DEPS += $(DEPDIR)/memsetup.d
DEPS += $(DEPDIR)/soundpatch.d
DEPS += $(DEPDIR)/palette_ll.d
DEPS += $(DEPDIR)/sprite_ll.d
DEPS += $(DEPDIR)/grtext_ll.d
DEPS += $(DEPDIR)/control_ll.d
DEPS += $(DEPDIR)/sound_ll.d
DEPS += $(DEPDIR)/$(GAME).d

## Include Directories
INCLUDES = -I"$(KERNEL_DIR)"

## Build
all: $(OUTDIR)/$(TARGET) $(OUTDIR)/$(GAME).hex $(OUTDIR)/$(GAME).lss $(OUTDIR)/$(GAME).uze size

## Directories
$(OBJDIR):
	mkdir $(OBJDIR)

$(OUTDIR):
	mkdir $(OUTDIR)

$(DEPDIR):
	mkdir $(DEPDIR)

$(OBJECTS): | $(DIRS)

## Compile Kernel files
$(OBJDIR)/uzeboxVideoEngineCore.o: $(KERNEL_DIR)/uzeboxVideoEngineCore.s $(DEPDIR)/uzeboxVideoEngineCore.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/uzeboxSoundEngineCore.o: $(KERNEL_DIR)/uzeboxSoundEngineCore.s $(DEPDIR)/uzeboxSoundEngineCore.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/uzeboxCore.o: $(KERNEL_DIR)/uzeboxCore.c $(DEPDIR)/uzeboxCore.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/uzeboxVideoEngine.o: $(KERNEL_DIR)/uzeboxVideoEngine.c $(DEPDIR)/uzeboxVideoEngine.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

## Compile game sources
$(OBJDIR)/$(GAME).o: src/main.c $(DEPDIR)/$(GAME).d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/game.o: src/game.c $(DEPDIR)/game.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/gameover.o: src/gameover.c $(DEPDIR)/gameover.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/title.o: src/title.c $(DEPDIR)/title.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/playfield.o: src/playfield.c $(DEPDIR)/playfield.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/dragonwave.o: src/dragonwave.c $(DEPDIR)/dragonwave.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/bullet.o: src/bullet.c $(DEPDIR)/bullet.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/targeting.o: src/targeting.c $(DEPDIR)/targeting.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/town.o: src/town.c $(DEPDIR)/town.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/graphics_bg.o: src/graphics_bg.c $(DEPDIR)/graphics_bg.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/grsprite.o: src/grsprite.c $(DEPDIR)/grsprite.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/memsetup.o: src/memsetup.c $(DEPDIR)/memsetup.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/palette_ll.o: src/palette_ll.c $(DEPDIR)/palette_ll.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/sprite_ll.o: src/sprite_ll.c $(DEPDIR)/sprite_ll.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/grtext_ll.o: src/grtext_ll.c $(DEPDIR)/grtext_ll.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/control_ll.o: src/control_ll.c $(DEPDIR)/control_ll.d
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(OBJDIR)/sound_ll.o: src/sound_ll.s $(DEPDIR)/sound_ll.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/soundpatch.o: src/soundpatch.s $(DEPDIR)/soundpatch.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/spriteset.o: $(OBJDIR)/spriteset.s $(DEPDIR)/spriteset.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/tileset.o: $(OBJDIR)/tileset.s $(DEPDIR)/tileset.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/dragonmaw.o: $(OBJDIR)/dragonmaw.s $(DEPDIR)/dragonmaw.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/fontwaves.o: src/fontwaves.s $(DEPDIR)/fontwaves.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/spritecanvas.o: src/spritecanvas.s $(DEPDIR)/spritecanvas.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/text.o: src/text.s $(DEPDIR)/text.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/dragonlayout.o: src/dragonlayout.s $(DEPDIR)/dragonlayout.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

$(OBJDIR)/random.o: src/random.s $(DEPDIR)/random.d
	$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

## Generate resources
$(OBJDIR)/tileset.s: assets/tileset.png tools/tilegen.py
	$(PYTHON) tools/tilegen_v2.py $< $@

$(OBJDIR)/spriteset.s: assets/spriteset.png tools/spritegen.py
	$(PYTHON) tools/spritegen.py $< $@

$(OBJDIR)/dragonmaw.s: assets/dragonmaw.png tools/image2bppgen.py
	$(PYTHON) tools/image2bppgen.py $< $@ dragonmaw

## Link
$(OUTDIR)/$(TARGET): $(OBJECTS)
	 $(CC) $(LDFLAGS) $(OBJECTS) $(LIBDIRS) $(LIBS) -o $(OUTDIR)/$(TARGET)

$(OUTDIR)/%.hex: $(OUTDIR)/$(TARGET)
	avr-objcopy -O ihex $(HEX_FLASH_FLAGS) $< $@

$(OUTDIR)/%.lss: $(OUTDIR)/$(TARGET)
	avr-objdump -h -S $< > $@

$(OUTDIR)/%.uze: $(OUTDIR)/$(TARGET)
	-$(PACKROM_DIR)/packrom $(OUTDIR)/$(GAME).hex $@ $(INFO)

UNAME := $(shell sh -c 'uname -s 2>/dev/null || echo not')
AVRSIZEFLAGS := -A $(OUTDIR)/${TARGET}
ifneq (,$(findstring MINGW,$(UNAME)))
AVRSIZEFLAGS := -C --mcu=${MCU} $(OUTDIR)/${TARGET}
endif

size: $(OUTDIR)/${TARGET}
	@echo
	@avr-size ${AVRSIZEFLAGS}

## Clean target
.PHONY: clean
clean:
	-rm -rf $(DIRS)

## Dependencies
$(DEPS):

include $(wildcard $(DEPS))

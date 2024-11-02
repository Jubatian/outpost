
Outpost in the Dragon's Maw - Coding Guide
==============================================================================

:Author:    Sandor Zsuga (Jubatian)
:License:   GNU GPLv3 (version 3 of the GNU General Public License)




Overview
------------------------------------------------------------------------------


Provides some information on how this game is built, giving a hopefully
adequate broader understanding than what could be found in code comments.




The build process
------------------------------------------------------------------------------


The Makefile drives the build.

Beyond compiling the sources (C and Assembly), it also generates some of the
assets for which tooling could be made.

These take asset sources (for example a .png image) from the assets
directory, and process them with a Python tool in the tools directory to
generate a resource, usually an Assembly source which would be compiled and
linked into the game.

As of now for generating the .uze file, the packrom executable is required

(TODO: Later likely replaced with a Python tool to eliminate the need of this
native executable which usually would have to be compiled from the Uzebox
repo)




Debugging
------------------------------------------------------------------------------


Options to debug this thing are a bit limited. The CUzebox emulator's memory
heat-map could often be useful to see how much data various structures end up
using.

Otherwise the two registers reserved for debugging in emulators (both Uzem and
CUzebox) can be used, for example as:

*((uint8_t*)(0x3AU)) = var16 & 0xFFU;
*((uint8_t*)(0x39U)) = var16 >> 8;

The emulators also offer measuring intervals between Watchdog Resets (wdr
opcode), which may be used for tweaking performace-sensitive areas.




C language issues
------------------------------------------------------------------------------


On the 8 bits AVR architecture, although it is one of the best 8 bits
architectures for high-level languages, there are some notable caveats when
using the C language with the avr-gcc toolchain. These are described here to
give some rationale of some unusual practices.


Why the -fno-tree-switch-conversion option is required
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The avr-gcc compiler by default at higher optimization levels has this active.

The result of this option, when it determines this optimization could be used
is that it places a jump table in RAM.

The RAM is very limited here, and thus the RAM budget is very easily tipped
over with such a decision (sometimes creating strange, difficult to debug
situations if the result of this is running low of RAM into an unexpected
interference with the stack).

This optimization most of the case wouldn't be missed - branching is fast on
this 8 bits architecture.


No nonzero initialized RAM data
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All RAM data is zero initialized.

The issue here is working around constrained ROM space, while having data
requiring being aligned to 512 byte boundaries.

The aligned data, by linker script, is placed at the end of the ROM space.

The RAM initializers are in a separate section than code (data versus code),
which makes it apparently impossible to locate them in a more suitable place
than the end of the ROM where they would waste an entire 512 byte block.


Using assembly sources for interacting with ROM data
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Although there is support for fetching ROM data (pgmspace.h), due to the
limited instructions and registers used for this, the C compiler doesn't do a
good job coming up with optimal code here (size and performance).

In overall given handling ROM data requires unusual constructs in C anyway,
this was just rather mostly done in assembler.


Pointer arithmetic
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Normally register Y is used to access the Stack, the C compiler is thus
reluctant to make use of it for other purposes. Out of the remaining two
pointer registers, only Z supports displacement.

This becomes an issue in any case requiring displacements, notably (as these
are not directly visible in code) when using wider than 8 bits data or
accessing members of structures.

When the compiler ends up having to use X for these, the code as of current
avr-gcc versions is awful (uses adiw and sbiw to adjust the pointer, without
even recognizing cases where it ends up doing this superfluously or a
post-increment would resolve it better). This is bad both in terms of code
size and performance.

In some areas pointer arithmetic is thus used in ways to work this around,
mostly ensuring one pointer register (Z) is sufficient to do it.


Memory management
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The game uses a simple heap allocator with no free, but with capability to
reset. This is useful for realizing different stages (title screen, main game,
game over screen), allowing building up different memory configurations for
them in a clean manner.


Portability
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The C sources are generally written with the aim of reducing coupling, in most
of them there is no dependency on Uzebox kernel components or specifics of the
AVR architecture.




Python tools
------------------------------------------------------------------------------


The Python tools included (used during the build process) are (reasonably)
simple single-file tools which may be reused in different projects as needed.

As of now their quality may be lacking here and there, likely will be
improved later (for now were mostly just to get the job done).


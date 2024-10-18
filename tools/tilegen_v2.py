#
# Generates Mode 72 background tileset (V2)
#
# By Sandor Zsuga (Jubatian)
#
# Licensed under GNU General Public License version 3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import sys
from PIL import Image
from enum import Enum


print("\nMode 72 background tileset generator, Version 2\n")

if (len(sys.argv) < 3):
    print("Need two arguments:")
    print("- Input image file to generate tileset from")
    print("- Output avr assembly file to generate")
    sys.exit()

tilesetimg = Image.open(sys.argv[1])
palette = tilesetimg.getpalette()

print("Image:  {0}".format(sys.argv[1]))
print("Width:  {0:4d}".format(tilesetimg.width))
print("Height: {0:4d}".format(tilesetimg.height))

if palette is None:
    print("Image must have palette")
    sys.exit()

if (((tilesetimg.width % 8) != 0) or ((tilesetimg.height % 8) != 0)):
    print("Image dimensions must be multiples of 8")
    sys.exit()

outfile = open(sys.argv[2], "w")

pixels = tilesetimg.load()

# Extract tileset into tile rows in left to right, top to bottom order, up to
# 256 tiles, discarding the rest. Colour indices > 16 occurring are also
# discarded (substituted with index 0).

rowidx = [] # Two dimensions, indices of rows (8) belonging to each tile
rowdata = [] # Two diemensions, pixels (8) of each row

for ypos in range(0, tilesetimg.height, 8):
    for xpos in range(0, tilesetimg.width, 8):
        tilerowidx = []
        for row in range(0, 8):
            tilerowdata = []
            for pix in range(0, 8):
                rpix = pixels[xpos + pix, ypos + row]
                if (rpix >= 16):
                    rpix = 0
                tilerowdata.append(rpix)
            tgidx = len(rowdata)
            for idx, rowdataitem in enumerate(rowdata):
                if (tilerowdata == rowdataitem):
                    tgidx = idx
                    break
            if (tgidx == len(rowdata)):
                rowdata.append(tilerowdata)
            tilerowidx.append(tgidx)
        rowidx.append(tilerowidx)

print("Tiles:  {0:4d}".format(len(rowidx)))

# Expand tileset to 256 tiles with Colour 0 tiles (if needed)

if (len(rowidx) < 256):
    tilerowdata = [0] * 8
    tgidx = len(rowdata)
    for idx, rowdataitem in enumerate(rowdata):
        if (tilerowdata == rowdataitem):
            tgidx = idx
            break
    if (tgidx == len(rowdata)):
        rowdata.append(tilerowdata)
    tilerowidx = [tgidx] * 8
    while (len(rowidx) < 256):
        rowidx.append(tilerowidx)



# Operation type for output words

class OpType(Enum):
    FREE = 0
    USED = 1
    HEADJUMP = 2
    HEAD = 3
    TAILJUMP = 4
    TAIL = 5
    COMMONJUMP = 6
    COMMON = 7
    ROWENTRY = 8

# Output word descriptor

class OpDescriptor():
    def __init__(self, optype, pixels = [], opstring = False, label = False, shared = False):
        self.optype = optype
        self.pixels = pixels
        self.opstring = opstring
        self.label = label
        self.shared = shared

# Add a used word. This is to pad out where ops need to go in the output
# assembly

def append_used(ops, opstring = False):
    ops.append(OpDescriptor(OpType.USED, [], opstring))

# Add a head jump (these are part of the 256 word aligned entry jump tables).
# These should always receive 8 pixels. Initializes with no target.

def append_headjump(ops, pixels):
    if (len(pixels) != 8):
        print("PixelLenError\n")
    ops.append(OpDescriptor(OpType.HEADJUMP, pixels))

# Add a tail jump (these are on the end of head blocks). Up to 7 remaining
# pixels. Initializes with no target.

def append_tailjump(ops, pixels):
    ops.append(OpDescriptor(OpType.TAILJUMP, pixels))

# Add a common jump (these are on the end of tail blocks). Up to 6 remaining
# pixels. Initializes with no target.

def append_commonjump(ops, pixels):
    ops.append(OpDescriptor(OpType.COMMONJUMP, pixels))

# Add a head block. Should always have 8 pixels. At least 1 pixel should be
# generated before the tail jump. Tail jump is initialized with no target.
# Count only returns worst case here.

def append_head(ops, pixels, tailatpixel, countonly = False):
    if (countonly):
        return len(ops) + (tailatpixel + 4)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    ops.append(OpDescriptor(OpType.HEAD, pixels, opstring))
    pixels = pixels[1:]
    opstring = "\tout   PIXOUT,  r1\n"
    append_used(ops, opstring)
    if (tailatpixel <= 1):
        append_tailjump(ops, pixels)
        return len(ops)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    append_used(ops, opstring)
    pixels = pixels[1:]
    if (tailatpixel == 2):
        append_tailjump(ops, pixels)
        return len(ops)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    append_used(ops, opstring)
    pixels = pixels[1:]
    if (tailatpixel == 3):
        append_tailjump(ops, pixels)
        return len(ops)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    append_used(ops, opstring)
    pixels = pixels[1:]
    opstring = "\tout   PIXOUT,  r22\n"
    append_used(ops, opstring)
    if (tailatpixel == 4):
        append_tailjump(ops, pixels)
        return len(ops)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    append_used(ops, opstring)
    pixels = pixels[1:]
    if (tailatpixel == 5):
        append_tailjump(ops, pixels)
        return len(ops)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    append_used(ops, opstring)
    pixels = pixels[1:]
    if (tailatpixel == 6):
        append_tailjump(ops, pixels)
        return len(ops)
    opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
    append_used(ops, opstring)
    pixels = pixels[1:]
    opstring = "\tout   PIXOUT,  r23\n"
    append_used(ops, opstring)
    append_tailjump(ops, pixels)
    return len(ops)

# Add a tail block. May have up to 7 pixels. At least 1 pixel should be
# generated before the common jump. Returns what the new ops list lenght
# would be, used for attempting padding space with tails.

def append_tail(ops, pixels, commonatpixel, countonly = False):
    opslen = len(ops)
    if (len(pixels) > 7):
        return opslen
    if (len(pixels) == 7):
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 6):
        if (commonatpixel <= 2):
            opslen += 1
            if (not countonly):
                append_commonjump(ops, pixels)
            return opslen
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 5):
        opslen += 1
        if (not countonly):
            opstring = "\tout   PIXOUT,  r22\n"
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        if (commonatpixel == 3):
            opslen += 1
            if (not countonly):
                append_commonjump(ops, pixels)
            return opslen
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            append_used(ops, opstring)
        pixels = pixels[1:]
    if (len(pixels) == 4):
        if (commonatpixel == 4):
            opslen += 1
            if (not countonly):
                append_commonjump(ops, pixels)
            return opslen
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 3):
        if (commonatpixel == 5):
            opslen += 1
            if (not countonly):
                append_commonjump(ops, pixels)
            return opslen
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 2):
        opslen += 1
        if (not countonly):
            opstring = "\tout   PIXOUT,  r23\n"
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        if (commonatpixel == 6):
            opslen += 1
            if (not countonly):
                append_commonjump(ops, pixels)
            return opslen
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            append_used(ops, opstring)
        pixels = pixels[1:]
    if (len(pixels) == 1):
        if (commonatpixel == 7):
            opslen += 1
            if (not countonly):
                append_commonjump(ops, pixels)
            return opslen
        opslen += 1
        if (not countonly):
            opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
            ops.append(OpDescriptor(OpType.TAIL, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 0):
        opslen += 1
        if (not countonly):
            append_commonjump(ops, pixels)
    return opslen

# Add a common block. May have up to 6 pixels.
# Count only returns worst case here.

def append_common(ops, pixels, countonly = False):
    if (countonly):
        return len(ops) + (len(pixels) + 2 + 30)
    if (len(pixels) > 6):
        return len(ops)
    if (len(pixels) == 6):
        opstring = "\tout   PIXOUT,  r22\n"
        ops.append(OpDescriptor(OpType.COMMON, pixels, opstring))
        opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
        append_used(ops, opstring)
        pixels = pixels[1:]
    if (len(pixels) == 5):
        opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
        ops.append(OpDescriptor(OpType.COMMON, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 4):
        opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
        ops.append(OpDescriptor(OpType.COMMON, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 3):
        opstring = "\tout   PIXOUT,  r23\n"
        ops.append(OpDescriptor(OpType.COMMON, pixels, opstring))
        opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
        append_used(ops, opstring)
        pixels = pixels[1:]
    if (len(pixels) == 2):
        opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
        ops.append(OpDescriptor(OpType.COMMON, pixels, opstring))
        pixels = pixels[1:]
    if (len(pixels) == 1):
        opstring = "\tst    X+,      r{0}\n".format(pixels[0] + 2)
        ops.append(OpDescriptor(OpType.COMMON, pixels, opstring))
        pixels = pixels[1:]
    opstring = "\tout   PIXOUT,  r0\n"
    ops.append(OpDescriptor(OpType.COMMON, [], opstring))
    opstring = "\tbreq  .+26             ; Uses Z flag\n"
    append_used(ops, opstring)
    opstring = "\tpop   r0\n"
    append_used(ops, opstring)
    opstring = "\tdec   r20\n"
    ops.append(OpDescriptor(OpType.ROWENTRY, [], opstring))
    opstring = "\tld    ZL,      Y+\n"
    append_used(ops, opstring)
    opstring = "\tout   PIXOUT,  r0\n"
    append_used(ops, opstring)
    opstring = "\tpop   r0\n"
    append_used(ops, opstring)
    opstring = "\tpop   r21\n"
    append_used(ops, opstring)
    opstring = "\tpop   r1\n"
    append_used(ops, opstring)
    opstring = "\tout   PIXOUT,  r0\n"
    append_used(ops, opstring)
    opstring = "\tpop   r22\n"
    append_used(ops, opstring)
    opstring = "\tpop   r23\n"
    append_used(ops, opstring)
    opstring = "\tpop   r0\n"
    append_used(ops, opstring)
    opstring = "\tout   PIXOUT,  r21\n"
    append_used(ops, opstring)
    opstring = "\tijmp\n"
    append_used(ops, opstring)
    # The BREQ above enters here, exiting from tile row
    opstring = "\tbrts  .+14             ; (1582 / 1621)\n"
    append_used(ops, opstring)
    opstring = "\tmov   r22,     r17\n"
    append_used(ops, opstring)
    opstring = "\tmov   r23,     r17\n"
    append_used(ops, opstring)
    opstring = "\tmovw  r0,      r22\n"
    append_used(ops, opstring)
    opstring = "\tout   PIXOUT,  r17\n"
    append_used(ops, opstring)
    opstring = "\tld    ZL,      Y+\n"
    append_used(ops, opstring)
    opstring = "\tset\n"
    append_used(ops, opstring)
    opstring = "\tijmp\n"
    append_used(ops, opstring)
    # The BRTS above enters here, exiting from tile row
    opstring = "\tsbic  GPR0,    1       ; (1622) Color 0 (bg) loading enabled?\n"
    append_used(ops, opstring)
    opstring = "\tin    r2,      GPR1    ; (1623) If so, load it\n"
    append_used(ops, opstring)
    opstring = "\tsbic  GPR0,    2       ; (1624) Color 15 (border) loading enabled?\n"
    append_used(ops, opstring)
    opstring = "\tin    r17,     GPR1    ; (1625) If so, load it\n"
    append_used(ops, opstring)
    opstring = "\tldi   ZL,      LB_SPR - 1 ; (1626) 254(HI):255(LO): Sprite conf\n"
    append_used(ops, opstring)
    opstring = "\tout   STACKL,  ZL      ; (1627)\n"
    append_used(ops, opstring)
    opstring = "\tret                    ; (1631)\n"
    append_used(ops, opstring)
    return len(ops)

# Generates label string from address

def create_label(address):
    return "bg_jump_{}".format(address)

# Adds a label to an operation (jump target). The label is derived from the
# address.

def add_label(ops, address):
    ops[address].label = create_label(address)

# Adds a relative jump instruction to target address

def add_jump_op(ops, address, target):
    opstring = "\trjmp  {}\n".format(create_label(target))
    ops[address].opstring = opstring



# Count matching pixels at the ends of the two inputs

def count_matching_pixels(pixels1, pixels2):
    matchedcount = 0
    pos1 = len(pixels1)
    pos2 = len(pixels2)
    while ((pos1 > 0) and (pos2 > 0)):
        pos1 -= 1
        pos2 -= 1
        if (pixels1[pos1] != pixels2[pos2]):
            break
        matchedcount += 1
    return matchedcount

# Generate head block to be jumped at from the passed address (of a head
# jump). Scans if it might already be available, if not, then scans both
# existing and not yet resolved heads for possible tail merge options. The new
# head block is then produced accordingly. Either way, the jump gets resolved
# and completed. Pixels can be provided, in which case the passed jump
# location is assumed not being generated yet (use to place heads ahead of the
# jump table). Returns True if success, only relevant if an end size is
# provided to bound the head block.

def gen_head(ops, jumploc, endloc = -1, headpixels = False):
    startaddress = jumploc - 2048
    if (headpixels == False):
        headpixels = ops[jumploc].pixels
    if (startaddress < 0):
        startaddress = 0
    maxtailmatch = 0
    maxtailmatchaddr = False
    # Try already present head blocks first, possibly finding a full match,
    # which case the jump can be directed there. Do this when going ahead as
    # well to shortcut here, avoiding generating the block.
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.HEAD):
            matchcount = count_matching_pixels(ops[address].pixels, headpixels)
            if (matchcount == 8):
                if (jumploc < len(ops)):
                    add_label(ops, address)
                    add_jump_op(ops, jumploc, address)
                return True
    # Check unresolved tail jumps (assuming such jumps can only be further
    # ahead) to see if there might be a suitable tail eventually generated to
    # join with.
    for address in range (jumploc + 1, len(ops)):
        if ((ops[address].optype == OpType.TAILJUMP) and (ops[address].opstring == False)):
            matchcount = count_matching_pixels(ops[address].pixels, headpixels)
            if (matchcount >= maxtailmatch):
                maxtailmatch = matchcount
    # Check other not yet resolved jumps to see what tail may be best to
    # settle for. Full matches are ignored here (as this will then be the
    # first generating the head block which those may use in later jump
    # resolutions).
    for address in range (jumploc + 1, len(ops)):
        if ((ops[address].optype == OpType.HEADJUMP) and (ops[address].opstring == False)):
            matchcount = count_matching_pixels(ops[address].pixels, headpixels)
            if ((matchcount < 8) and (matchcount >= maxtailmatch)):
                maxtailmatch = matchcount
    # Check tails in range for the newly generating head, there might be
    # something suitable already present
    startaddress = len(ops) - (2048 - 11)
    if (startaddress < 0):
        startaddress = 0
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.TAIL):
            matchcount = count_matching_pixels(ops[address].pixels, headpixels)
            if ((matchcount >= maxtailmatch) and (matchcount == len(ops[address].pixels))):
                maxtailmatch = matchcount
                maxtailmatchaddr = address
    # Head block generates assuming the maximum matched tail. Ideally
    # eventually that will be a tail shared, or maybe is already there
    headaddress = len(ops)
    if (endloc >= 0):
        testlen = append_head(ops, headpixels, 8 - maxtailmatch, True)
        if (testlen > endloc):
            return False
    append_head(ops, headpixels, 8 - maxtailmatch)
    if (maxtailmatchaddr != False):
        add_label(ops, maxtailmatchaddr)
        add_jump_op(ops, len(ops) - 1, maxtailmatchaddr)
    if (jumploc < len(ops)):
        add_label(ops, headaddress)
        add_jump_op(ops, jumploc, headaddress)
    return True

# Suggest common block pixels which could be used. This doesn't do anything
# with the opcodes and attributes, only determines the likely best pixels
# which could be used.

def suggest_common_pixels(ops):
    commonpixels = []
    # First scans existing unresolved tails in range, which determine what
    # common block pixels are already needed. Take the longest of this, simply
    # assuming that's it (was an earlier choice anyway!)
    startaddress = len(ops) - 2048
    if (startaddress < 0):
        startaddress = 0
    for address in range (startaddress, len(ops)):
        if ((ops[address].optype == OpType.COMMONJUMP) and (ops[address].opstring == False)):
            if (len(ops[address].pixels) > len(commonpixels)):
                commonpixels = ops[address].pixels.copy()
    # Collect addresses of tail jumps and unresolved head jumps to accelerate
    # scans (unresolved head jumps still need a tail, and by that, a common
    # block eventually, however resolved ones are accounted for by scanning
    # the tails).
    jumps = []
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.TAILJUMP):
            jumps.append(address)
        if ((ops[address].optype == OpType.HEADJUMP) and (ops[address].opstring == False)):
            jumps.append(address)
    # Mark shared jumps to avoid counting them in multiple times for
    # suggesting a common block. A jump is shared if a subsequent jump could
    # contain it (that is, it leads to the same or a longer tail, for head
    # jumps here assume them fitting in)
    for idx, address in enumerate(jumps):
        if (not ops[address].shared):
            for compaddr in jumps[idx + 1:]:
                pixels = ops[address].pixels
                comppixels = ops[compaddr].pixels
                if ((count_matching_pixels(pixels, comppixels)) >= len(pixels)):
                    ops[address].shared = True
                    break
    # Try to find / expand based on unresolved jumps (those tails will need to
    # to be generated eventually!)
    for pixelpos in range (len(commonpixels), 4):
        pixelbuckets = [0] * 16
        for address in jumps:
            if (ops[address].opstring == False):
                pixels = ops[address].pixels
                if (len(pixels) > pixelpos):
                    if ((count_matching_pixels(commonpixels, pixels)) >= pixelpos):
                        if (not ops[address].shared):
                            pixelbuckets[pixels[pixelpos]] += 1
        maxindex = 0
        for bucket in range (1, 16):
            if (pixelbuckets[bucket] > pixelbuckets[maxindex]):
                maxindex = bucket
        if (pixelbuckets[maxindex] <= 1):
            break
        commonpixels.insert(0, maxindex)
    return commonpixels

# Generate tail block to be jumped at from the passed address (of a tail
# jump). Scans if it might be available (it may be a whole or part of an
# existing tail, entry points being generated for all pixels), if not, the
# tail is generated along with either holding off generating a common block or
# joining with one already present. Returns True if success, only relevant if
# an end size is provided to bound the tail block.

def gen_tail(ops, jumploc, endloc = -1):
    startaddress = jumploc - 2048
    if (startaddress < 0):
        startaddress = 0
    # Try already present tail blocks (or entry points within tail blocks)
    # first, hoping to find a match, with that, able to complete the jump.
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.TAIL):
            if (len(ops[address].pixels) == len(ops[jumploc].pixels)):
                matchcount = count_matching_pixels(ops[address].pixels, ops[jumploc].pixels)
                if (matchcount == len(ops[address].pixels)):
                    add_label(ops, address)
                    add_jump_op(ops, jumploc, address)
                    return True
    # Look for a common block in range, matching as many pixels as possible.
    # If found, it will be joined (worst case at the 0 pixel entry point).
    startaddress = len(ops) - (2048 - 10)
    if (startaddress < 0):
        startaddress = 0
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.COMMON):
            matchcount = count_matching_pixels(ops[address].pixels, ops[jumploc].pixels)
            if (matchcount == len(ops[address].pixels)):
                tailaddress = len(ops)
                if (endloc >= 0):
                    testlen = append_tail(ops, ops[jumploc].pixels, 8 - matchcount, True)
                    if (testlen > endloc):
                        return False
                append_tail(ops, ops[jumploc].pixels, 8 - matchcount)
                add_label(ops, address)
                add_jump_op(ops, len(ops) - 1, address)
                add_label(ops, tailaddress)
                add_jump_op(ops, jumploc, tailaddress)
                return True
    # No common block yet, need to guess what it should be, and generate a
    # tail without its common jump resolved.
    commonpixels = suggest_common_pixels(ops)
    matchcount = count_matching_pixels(commonpixels, ops[jumploc].pixels)
    tailaddress = len(ops)
    if (endloc >= 0):
        testlen = append_tail(ops, ops[jumploc].pixels, 8 - matchcount, True)
        if (testlen > endloc):
            return False
    append_tail(ops, ops[jumploc].pixels, 8 - matchcount)
    add_label(ops, tailaddress)
    add_jump_op(ops, jumploc, tailaddress)
    return True

# Generate common block to be jumped at from the passed address (of a common
# jump). Scans if it is already available, if not, generates one according to
# the best suggestion, and joins it (might not be at the first instruction if
# a longer common block is found advisable). Returns True if success, only
# relevant if an end size is provided to bound the common block.

def gen_common(ops, jumploc, endloc = -1):
    startaddress = jumploc - 2048
    if (startaddress < 0):
        startaddress = 0
    # Try already present common blocks (or entry points within common blocks)
    # first, hoping to find a match, with that, able to complete the jump.
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.COMMON):
            if (len(ops[address].pixels) == len(ops[jumploc].pixels)):
                matchcount = count_matching_pixels(ops[address].pixels, ops[jumploc].pixels)
                if (matchcount == len(ops[address].pixels)):
                    add_label(ops, address)
                    add_jump_op(ops, jumploc, address)
                    return True
    # No common block yet, need to guess and generate one, then join into it
    commonpixels = suggest_common_pixels(ops)
    startaddress = len(ops)
    if (endloc >= 0):
        testlen = append_common(ops, commonpixels, True)
        if (testlen > endloc):
            return False
    append_common(ops, commonpixels)
    for address in range (startaddress, len(ops)):
        if (ops[address].optype == OpType.COMMON):
            if (len(ops[address].pixels) == len(ops[jumploc].pixels)):
                matchcount = count_matching_pixels(ops[address].pixels, ops[jumploc].pixels)
                if (matchcount == len(ops[address].pixels)):
                    add_label(ops, address)
                    add_jump_op(ops, jumploc, address)
                    return True
    return True



# Finds next unresolved jump (no effect if already at one)

def find_next_unresolved(ops, startloc):
    currentloc = startloc
    while (currentloc < len(ops)):
        currentop = ops[currentloc]
        if (currentop.opstring == False):
            if (currentop.optype == OpType.HEADJUMP):
                return currentloc
            if (currentop.optype == OpType.TAILJUMP):
                return currentloc
            if (currentop.optype == OpType.COMMONJUMP):
                return currentloc
        currentloc += 1
    return len(ops)

# Resolves next unresolved jump by adding suitable new block

def resolve_next_jump(ops, startloc, endloc = -1):
    startloc = find_next_unresolved(ops, startloc)
    newstartloc = startloc
    newstartsync = True
    while (startloc < len(ops)):
        currentop = ops[startloc]
        if (currentop.optype == OpType.HEADJUMP):
            if (gen_head(ops, startloc, endloc)):
                break
            newstartsync = False
        if (currentop.optype == OpType.TAILJUMP):
            if (gen_tail(ops, startloc, endloc)):
                break
            newstartsync = False
        if (currentop.optype == OpType.COMMONJUMP):
            if (gen_common(ops, startloc, endloc)):
                break
            newstartsync = False
        startloc = find_next_unresolved(ops, startloc + 1)
        if (newstartsync):
            newstartloc = startloc
    return find_next_unresolved(ops, newstartloc)



# Attempt to compile tileset with the passed maximum permitted unresolved
# distance. Returns compiled tileset on success, False on failure. This case a
# more strict limit on maximum unresolved distance may be attempted (the
# tileset might favour generating a burst of items requiring later resolution,
# pushing jumps out of range).

def compile_tileset(rowidx, rowdata, maxunresolveddistance):
    # First unresolved jump's location (might not be at a jump, just tracks to
    # which point jumps were sorted out)
    firstunresolved = 0
    # Annoted opcode words
    ops = []
    # Generate row by row
    for row in range(0, 8):
        jumptableaddress = ((len(ops) + 255) // 256) * 256
        while (firstunresolved < (len(ops) - 512)):
            # Fill in with tails waiting to be generated, deplete them, but
            # avoid going unnecessarily far
            nextunresolved = resolve_next_jump(ops, firstunresolved, jumptableaddress)
            if (nextunresolved == firstunresolved):
                if (firstunresolved < ((jumptableaddress + 256) - maxunresolveddistance)):
                    jumptableaddress += 256
                else:
                    break
            firstunresolved = nextunresolved
            if (firstunresolved < (len(ops) - 2046)):
                return False
        tile = 0
        while (len(ops) < jumptableaddress):
            # Generate some head blocks ahead to pad to boundary
            pixels = rowdata[rowidx[tile][row]]
            if (not gen_head(ops, jumptableaddress + tile, jumptableaddress, pixels)):
                break
            tile += 1
            if (tile == 256):
                break
        while (firstunresolved < len(ops)):
            # Any remaining space is padded with whatever available if possible
            nextunresolved = resolve_next_jump(ops, firstunresolved, jumptableaddress)
            if (nextunresolved == firstunresolved):
                break
            firstunresolved = nextunresolved
        while (len(ops) < jumptableaddress):
            opstring = "\tnop\n" # Last resort: nops
            append_used(ops, opstring)
        print("Row {0} Jump table at {1}".format(row, jumptableaddress))
        for tile in range(0, 256):
            append_headjump(ops, rowdata[rowidx[tile][row]])
        ops[jumptableaddress].label = "tilerow_{0}_map".format(row)
        for tile in range(0, 256):
            # Head blocks normally after the jump table (will detect any match
            # before, including any head generated ahead)
            while (firstunresolved < (len(ops) - maxunresolveddistance)):
                firstunresolved = resolve_next_jump(ops, firstunresolved)
                if (firstunresolved < (len(ops) - 2046)):
                    return False
            gen_head(ops, jumptableaddress + tile)
    while (firstunresolved < len(ops)):
        firstunresolved = resolve_next_jump(ops, firstunresolved)
        if (firstunresolved < (len(ops) - 2046)):
            return False
    return ops



# Attempt compiling tileset, starting with lax attitude towards unresolved
# jumps, tightening if the tileset fails to compile.

maxunresolveddistance = 2040
ops = False
while (True):
    ops = compile_tileset(rowidx, rowdata, maxunresolveddistance)
    if (ops == False):
        print("Failed to compile at max unresolved distance {0}".format(maxunresolveddistance))
        maxunresolveddistance -= 10
    else:
        break
print("Success compiling at max unresolved distance {0}".format(maxunresolveddistance))
print("Size: {0} words / {1} bytes".format(len(ops), len(ops) * 2))

# Here code generation should be complete with all jumps resolved
# Generate an entry label as well

entrypos = 0
while (ops[entrypos].optype != OpType.ROWENTRY):
    entrypos += 1
ops[entrypos].label = "tilerow_entry"

# Generate heading

output = ""
output += ";\n"
output += "; Mode 72 background tileset\n"
output += ";\n"
output += ";\n"
output += "; Number of tile rows: {0}\n".format(len(rowdata))
output += ";\n"
output += "\n"
output += "\n"
output += "#include <avr/io.h>\n"
output += "#define  PIXOUT   _SFR_IO_ADDR(PORTC)\n"
output += "#define  GPR0     _SFR_IO_ADDR(GPIOR0)\n"
output += "#define  GPR1     _SFR_IO_ADDR(GPIOR1)\n"
output += "#define  STACKL   0x3D\n"
output += "#define  LB_SPR   254\n"
output += "#ifndef  M72_ALIGNED_SEC\n"
output += "#define  M72_ALIGNED_SEC .text.align512\n"
output += "#endif\n"
output += "\n"
output += "\n"
output += ".global m72_defpalette\n"
output += ".global m72_deftilerows\n"
output += "\n"
output += "\n"
output += ".section .text\n"
output += "\n"
output += "\n"
output += "\n"
output += "m72_defpalette:\n"
uzepal = []
for idx in range(0, len(palette), 3):
    uzecol = 0
    uzecol += (palette[idx + 0] // 32)
    uzecol += (palette[idx + 1] // 32) * 8
    uzecol += (palette[idx + 2] // 64) * 64
    uzepal.append(uzecol)
for idr in range(0, 16, 8):
    output += "\t.byte"
    for idx in range(0, 7):
        output += " 0x{0:02X},".format(uzepal[idr + idx])
    output += " 0x{0:02X}\n".format(uzepal[idr + 7])
output += "\n"
output += "\n"
output += "\n"
output += "m72_deftilerows:\n"
for idx in range(0, 8):
    output += "\trjmp  tilerow_{0}\n".format(idx)
output += "\n"
for idx in range(0, 8):
    output += "tilerow_{0}:\n".format(idx)
    output += "\tldi   ZH,      hi8(pm(tilerow_{0}_map))\n".format(idx)
    output += "\tout   PIXOUT,  r1      ; ( 599) Pixel 19\n"
    output += "\tjmp   tilerow_entry\n"
    output += "\n"
output += "\n"
output += "\n"
output += ".section M72_ALIGNED_SEC\n"
output += "\n"
output += ".balign 512\n"
output += "\n"
output += "\n"

for currentop in ops:
    if (currentop.label != False):
        output += currentop.label
        output += ":\n"
    if (currentop.opstring == False):
        output += "ERROR\n"
    else:
        output += currentop.opstring
output += "\n"

outfile.write(output)
outfile.close()
tilesetimg.close()

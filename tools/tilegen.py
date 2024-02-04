#
# Generates Mode 72 background tileset
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


print("\nMode 72 background tileset generator\n")

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

if (len(rowdata) < 256):
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

# Add usage markers

rowuhalf = [0] * len(rowdata)
rowusage = [0] * len(rowdata)
for idx, tilerowidx in enumerate(rowidx):
    for row in range(0, 4):
        rowuhalf[tilerowidx[row]] |= 1 # Used in upper half of tiles
        rowusage[tilerowidx[row]] |= 1 << row
    for row in range(4, 8):
        rowuhalf[tilerowidx[row]] |= 2 # Used in lower half of tiles
        rowusage[tilerowidx[row]] |= 1 << row
rowuctr = [0] * 4
for tilerowuse in rowuhalf:
    rowuctr[tilerowuse] += 1
print("Rows:   {0:4d}".format(len(rowdata)))
print("Upper:  {0:4d}".format(rowuctr[1]))
print("Lower:  {0:4d}".format(rowuctr[2]))
print("Shared: {0:4d}".format(rowuctr[3]))

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
output += "\n"
output += "\n"



# Generates common block.
# - no: Number of this block. The first (0) block has the entry point.
# - ext: Accommodate for extra rjmp in rows if set.
def gen_common(no, ext):
    global output
    output += "\n"
    output += "tilerow_common_{0}:\n".format(no)
    output += "\tout   PIXOUT,  r0\n"
    output += "\tbreq  tilerow_exit_c_{0} ; Uses Z flag\n".format(no)
    output += "\tpop   r0\n"
    if (no == 0):
        output += "tilerow_entry:\n"
    output += "\tdec   r20\n"
    output += "\tld    ZL,      Y+\n"
    output += "\tout   PIXOUT,  r0\n"
    output += "\tpop   r0\n"
    output += "\tpop   r21\n"
    output += "\tpop   r1\n"
    output += "\tout   PIXOUT,  r0\n"
    output += "\tpop   r22\n"
    output += "\tpop   r23\n"
    output += "\tpop   r0\n"
    output += "\tout   PIXOUT,  r21\n"
    if not ext:
        output += "\trjmp  .\n"
    output += "\tijmp\n"
    output += "tilerow_exit_c_{0}:\n".format(no)
    output += "\tbrts  tilerow_exit_{0}   ; (1582 / 1621)\n".format(no)
    output += "\tmov   r22,     r17\n"
    output += "\tmov   r23,     r17\n"
    output += "\tmovw  r0,      r22\n"
    output += "\tout   PIXOUT,  r17\n"
    output += "\tld    ZL,      Y+\n"
    output += "\tset\n"
    if not ext:
        output += "\trjmp  .\n"
    output += "\tijmp\n"
    output += "tilerow_exit_{0}:\n".format(no)
    output += "\tsbic  GPR0,    1       ; (1622) Color 0 (bg) loading enabled?\n"
    output += "\tin    r2,      GPR1    ; (1623) If so, load it\n"
    output += "\tsbic  GPR0,    2       ; (1624) Color 15 (border) loading enabled?\n"
    output += "\tin    r17,     GPR1    ; (1625) If so, load it\n"
    output += "\tldi   ZL,      LB_SPR - 1 ; (1626) 254(HI):255(LO): Sprite conf\n"
    output += "\tout   STACKL,  ZL      ; (1627)\n"
    output += "\tret                    ; (1631)\n"
    output += "\n"

# Generates a tile row.
# - blkno: Block number to generate
# - comno: Common block return target
# - data: Row data of 8 pixels
def gen_row(blkno, comno, data):
    global output
    output += "tilerow_block_{0}:\n".format(blkno)
    output += "\tout   PIXOUT,  r1\n"
    output += "\tst    X+,      r{0}\n".format(data[0] + 2)
    output += "\tst    X+,      r{0}\n".format(data[1] + 2)
    output += "\tst    X+,      r{0}\n".format(data[2] + 2)
    output += "\tout   PIXOUT,  r22\n"
    output += "\tst    X+,      r{0}\n".format(data[3] + 2)
    output += "\tst    X+,      r{0}\n".format(data[4] + 2)
    output += "\tst    X+,      r{0}\n".format(data[5] + 2)
    output += "\tout   PIXOUT,  r23\n"
    output += "\tst    X+,      r{0}\n".format(data[6] + 2)
    output += "\tst    X+,      r{0}\n".format(data[7] + 2)
    output += "\trjmp  tilerow_common_{0}\n".format(comno)

# Generates a tile row, separate tail.
# - blkno: Block number to generate
# - tlno: Tail block target
# - data: Row data of 8 pixels
def gen_row_head(blkno, tlno, data):
    global output
    output += "tilerow_block_{0}:\n".format(blkno)
    output += "\tst    X+,      r{0}\n".format(data[0] + 2)
    output += "\tout   PIXOUT,  r1\n"
    output += "\tst    X+,      r{0}\n".format(data[1] + 2)
    output += "\tst    X+,      r{0}\n".format(data[2] + 2)
    output += "\tst    X+,      r{0}\n".format(data[3] + 2)
    output += "\tout   PIXOUT,  r22\n"
    output += "\tst    X+,      r{0}\n".format(data[4] + 2)
    output += "\tst    X+,      r{0}\n".format(data[5] + 2)
    output += "\trjmp  tilerow_tail_{0}\n".format(tlno)

# Generates a tile row tail.
# - tlno: Tail number to generate
# - comno: Common block return target
# - data: Tail data of 2 pixels
def gen_row_tail(tlno, comno, data):
    global output
    output += "tilerow_tail_{0}:\n".format(tlno)
    output += "\tout   PIXOUT,  r23\n"
    output += "\tst    X+,      r{0}\n".format(data[0] + 2)
    output += "\tst    X+,      r{0}\n".format(data[1] + 2)
    output += "\trjmp  tilerow_common_{0}\n".format(comno)

# Generates a jump extender
# - extno: Extender number to generate
# - blkno: Block number to target
def gen_row_ext(extno, blkno):
    global output
    output += "tilerow_ext_{0}:\n".format(extno)
    output += "\trjmp  tilerow_block_{0}\n".format(blkno)

# Generates a block jump
# - blkno: Block number to target
def gen_jump_block(blkno):
    global output
    output += "\trjmp  tilerow_block_{0}\n".format(blkno)

# Generates an extender jump
# - extno: Extender number to target
def gen_jump_ext(extno):
    global output
    output += "\trjmp  tilerow_ext_{0}\n".format(extno)

# Generate row jump table entry point
# - no: Row number to generate for
def gen_row_entry(no):
    global output
    output += "tilerow_{0}_map:\n".format(no)

# Outputs alignment marker
def gen_alignment():
    global output
    output += "\n.balign 512\n\n"

# Outputs newline
def gen_newline():
    global output
    output += "\n"



# Smallest generator, no extended jumps
# - Row0 jump table (512b)
# - Row1 jump table (512b)
# - Row2 jump table (512b)
# - Row3 jump table (512b)
# - Up to 82 tile rows + Common block (2048b)
# - Row4 jump table (512b)
# - Row5 jump table (512b)
# - Row6 jump table (512b)
# - Row7 jump table (512b)
def generator0():
    global output
    global rowdata
    global rowidx
    if (len(rowdata) > 82):
        return False

    print("Using Generator 0 (Up to 82 rows)")

    gen_alignment()
    for row in range(0, 4):
        gen_row_entry(row)
        for idx in range(0, 256):
            gen_jump_block(rowidx[idx][row])
    gen_newline()

    for idx, tilerowdata in enumerate(rowdata):
        gen_row(idx, 0, tilerowdata)
    gen_newline()

    gen_common(0, False)

    gen_alignment()
    for row in range(4, 8):
        gen_row_entry(row)
        for idx in range(0, 256):
            gen_jump_block(rowidx[idx][row])

    return True



# Mid generator with no extended jumps
# - Up to 82 upper tile rows + Common block (2048b)
# - Row0 jump table (512b)
# - Row1 jump table (512b)
# - Row2 jump table (512b)
# - Row3 jump table (512b)
# - Up to 82 shared tile rows + Common block (2048b)
# - Row4 jump table (512b)
# - Row5 jump table (512b)
# - Row6 jump table (512b)
# - Row7 jump table (512b)
# - Up to 82 lower tile rows + Common block (2048b)
def generator1():
    global output
    global rowdata
    global rowidx
    global rowuhalf
    global rowuctr
    if (len(rowdata) > (82 * 3)):
        return False
    if (rowuctr[3] > 82):
        return False # Too many shared rows
    if ((rowuctr[3] + rowuctr[1]) > (82 * 2)):
        return False # Too many upper rows
    if ((rowuctr[3] + rowuctr[2]) > (82 * 2)):
        return False # Too many lower rows

    # TODO (Would be nice for smaller data)

    return False



# Large generator with tail sharing
# Aims to share between adjacent rows only if possible, repeats blocks if
# necessary.
# - Row0 jump table (512b)
# - Tile rows (and tails) belonging to Row0 and 1 (up to 3584b)
# - Row1 jump table (512b)
# - ...
# Tiles belonging to Row1, and not Row0 are only used until filling to the
# next 512b boundary.
def generator2():
    global output
    global rowdata
    global rowidx
    global rowusage

    print("Using Generator 2 (Large data)")

    tails = []
    rowtails = []
    for idx, tilerowdata in enumerate(rowdata):
        tailidx = len(tails)
        for tid, tail in enumerate(tails):
            if (tilerowdata[6:8] == tail):
                tailidx = tid
                break
        if (tailidx == len(tails)):
            tails.append(tilerowdata[6:8])
        rowtails.append(tailidx)

    print("Tails:  {0:4d}".format(len(tails)))

    rowpool = []
    tailpool = []

    for row in range(0, 8):
        prowuse = [False] * len(rowdata)
        # Mark tile rows which definitely appear in the previous one, so can
        # be fetched off from there instead of generating them anew
        for idx in rowpool:
            prowuse[idx] = True
        # Gather rows belonging here
        rowpool = []
        tailpool = []
        for idx, rowuse in enumerate(rowusage):
            if ((rowuse & (1 << row)) != 0):
                if not prowuse[idx]:
                    rowpool.append(idx)
                    tailfound = False
                    for tail in tailpool:
                        if (tail == rowtails[idx]):
                            tailfound = True
                            break
                    if not tailfound:
                        tailpool.append(rowtails[idx])
        # Fill up the 512 byte bank with next row's blocks
        totbase = (1 - (row % 2)) * 64 # Common block included?
        totsize = totbase + (len(rowpool) * 18) + (len(tailpool) * 8)
        next512 = ((totsize + 511) // 512) * 512
        for idx, rowuse in enumerate(rowusage):
            if (totsize > (next512 - 26)):
                break
            if ((rowuse & (1 << row)) == 0) and ((rowuse & (1 << (row + 1))) != 0):
                if not prowuse[idx]:
                    rowpool.append(idx)
                    tailfound = False
                    for tail in tailpool:
                        if (tail == rowtails[idx]):
                            tailfound = True
                            break
                    if not tailfound:
                        tailpool.append(rowtails[idx])
                    totsize = totbase + (len(rowpool) * 18) + (len(tailpool) * 8)
        msg = "Row{0}:   {1:4d}b;  Rows/Tails: {2:3d}/{3:3d}"
        print(msg.format(row, totsize + 512, len(rowpool), len(tailpool)))
        # Generate output
        gen_alignment()
        gen_row_entry(row)
        rowid = (row * 10000)
        for idx in range(0, 256):
            ridx = rowidx[idx][row]
            if (prowuse[ridx]):
                ridx += (rowid - 10000) # Block in prev. row
            else:
                ridx += rowid # Block is in the row proper
            gen_jump_block(ridx)
        gen_newline()

        if (totbase != 0):
            for idx in rowpool:
                gen_row_head(rowid + idx, rowid + rowtails[idx], rowdata[idx])
            for idx in tailpool:
                gen_row_tail(rowid + idx, row, tails[idx])
            gen_common(row, True)
        else:
            for idx in tailpool:
                gen_row_tail(rowid + idx, row - 1, tails[idx])
            for idx in rowpool:
                gen_row_head(rowid + idx, rowid + rowtails[idx], rowdata[idx])
        gen_newline()

    return True



# Generate tileset choosing best (smallest) generator

if generator0():
    pass
elif generator2():
    pass
else:
    print("Couldn't find suitable generator for this")
    sys.exit()

outfile.write(output)
outfile.close()
tilesetimg.close()

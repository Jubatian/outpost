#
# Generates 2bpp variable height sprites, useful for Mode 72
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


print("\n2bpp variable height sprite set generator\n")

if (len(sys.argv) < 3):
    print("Need two arguments:")
    print("- Input image file to generate sprite set from")
    print("- Output avr assembly file to generate")
    sys.exit()

spritesetimg = Image.open(sys.argv[1])
palette = spritesetimg.getpalette()

print("Image ......: {0}".format(sys.argv[1]))
print("Width ......: {0:4d}".format(spritesetimg.width))
print("Height .....: {0:4d}".format(spritesetimg.height))

if palette is None:
    print("Image must have palette")
    sys.exit()

# Try to determine type of sprites in the image, 8/12/16 pixels wide. Each
# sprite column contains a guide pixel bar on the left, so 9/13/17 pixels make
# a sprite column. Try the wider ones first (more likely than a lot of 8px
# wide sprite columns).

sprwidth = 0
sprcols = 0
if ((spritesetimg.width % 17) == 0):
    sprwidth = 16
elif ((spritesetimg.width % 13) == 0):
    sprwidth = 12
elif ((spritesetimg.width % 9) == 0):
    sprwidth = 8
else:
    print("Image width doesn't resolve to a suitable sprite width");
    sys.exit()

sprcols = spritesetimg.width // (sprwidth + 1)

print("Sprite Width: {0:4d}".format(sprwidth));
print("Columns ....: {0:4d}".format(sprcols));

# Extract sprite set in top to bottom, left to right order

sheights = [] # One dimension, sprite heights
sdata = [] # Two dimensions, sprite data
pixels = spritesetimg.load()

for xpos in range(0, spritesetimg.width, sprwidth + 1):
    ypos = 0
    height = 0
    insprite = False
    while (ypos < spritesetimg.height):
        if insprite:
            while (ypos < spritesetimg.height):
                if (pixels[xpos, ypos] == 0):
                    break
                ypos += 1
                height += 1
            insprite = False
            # Add the sprite
            sdataitem = []
            for spry in range(ypos - height, ypos):
                for sprx in range(xpos + 1, xpos + sprwidth + 1):
                    rpix = pixels[sprx, spry]
                    if (rpix >= 4):
                        rpix = 0
                    sdataitem.append(rpix);
            sdata.append(sdataitem)
            sheights.append(height)
        else:
            while (ypos < spritesetimg.height):
                if (pixels[xpos, ypos] != 0):
                    break
                ypos += 1
            height = 0
            insprite = True

if (len(sheights) == 0):
    print("No sprites found in input image");
    sys.exit()

print("Sprite Count: {0:4d}".format(len(sheights)))

outfile = open(sys.argv[2], "w")

# Generate heading

output = ""
output += ";\n"
output += "; 2bpp sprite set\n"
output += ";\n"
output += ";\n"
output += "; Number of sprites: {0}\n".format(len(sheights))
output += ";\n"
output += "\n"
output += "\n"
output += ".global spriteset_getdataptr\n"
output += ".global spriteset_getheight\n"
output += "\n"
output += "\n"
output += ".section .text\n"
output += "\n"
output += "\n"
output += "\n"
output += ";\n"
output += "; Return data pointer (r25:r24) to given sprite (r24)\n"
output += ";\n"
output += "spriteset_getdataptr:\n"
output += "\tldi   ZH,      hi8(spriteptr_list)\n"
output += "\tldi   ZL,      lo8(spriteptr_list)\n"
output += "\tldi   r25,     0\n"
output += "\tadd   ZL,      r24\n"
output += "\tadc   ZH,      r25\n"
output += "\tadd   ZL,      r24\n"
output += "\tadc   ZH,      r25\n"
output += "\tlpm   r24,     Z+\n"
output += "\tlpm   r25,     Z+\n"
output += "\tret\n"
output += "\n"
output += ";\n"
output += "; Return sprite height (r24) to given sprite (r24)\n"
output += ";\n"
output += "spriteset_getheight:\n"
output += "\tldi   ZH,      hi8(spriteheight_list)\n"
output += "\tldi   ZL,      lo8(spriteheight_list)\n"
output += "\tldi   r25,     0\n"
output += "\tadd   ZL,      r24\n"
output += "\tadc   ZH,      r25\n"
output += "\tlpm   r24,     Z+\n"
output += "\tret\n"
output += "\n"
output += "\n"
output += "\n"
output += "spriteptr_list:\n"

# List of sprite pointers (Little Endian)

for idx in range(0, len(sheights)):
    ostr = "\t.byte lo8(spritedata_{0:04X}), hi8(spritedata_{1:04X})\n"
    output += ostr.format(idx, idx)

output += "\n"
output += "\n"
output += "spriteheight_list:\n"

# List of sprite heights

for height in sheights:
    ostr = "\t.byte {0}\n"
    output += ostr.format(height)

# Ensure correct alignment in case program code follows

output += "\n.balign 2\n"

output += "\n"
output += "\n"
output += "; Sprite data needs to be in low ROM area\n"
output += "\n"
output += ".section .progmem\n"
output += "\n"
output += "\n"

# Generate sprite data

for idx, sdataitem in enumerate(sdata):
    output += "spritedata_{0:04X}:\n".format(idx)
    output += "\t.byte "
    accum = 0
    obyte = 0
    comma = False
    for pix in sdataitem:
        obyte = (obyte << 2) | pix;
        accum += 1
        if (accum >= 4):
            if (comma):
                output += ", "
            output += "0x{0:02X}".format(obyte)
            accum = 0
            obyte = 0
            comma = True
    output += "\n"

outfile.write(output)
outfile.close()
spritesetimg.close()

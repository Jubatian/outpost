#
# Generates 1bpp font as used in several video modes. This is a simple
# generator with no options to configure output, could be improved, did not
# care much as I needed to weave the audio waves with it manually.
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


print("\n1bpp font generator\n")

if (len(sys.argv) < 3):
    print("Need two arguments:")
    print("- Input image file to generate font from")
    print("- Output avr assembly file to generate")
    sys.exit()

img = Image.open(sys.argv[1])
palette = img.getpalette()

print("Image ......: {0}".format(sys.argv[1]))
print("Width ......: {0:4d}".format(img.width))
print("Height .....: {0:4d}".format(img.height))

if palette is None:
    print("Image must have palette")
    sys.exit()

bytewidth = 0
if ((img.width % 8) == 0):
    bytewidth = img.width // 8
else:
    print("Image width needs to be a multiple of 8!");
    sys.exit()

rowcount = 0
if ((img.height % 8) == 0):
    rowcount = img.height // 8
else:
    print("Image height needs to be a multiple of 8!");
    sys.exit()

charcount = bytewidth * rowcount
if (charcount > 256):
    print("At most 256 characters are supported!");
    sys.exit()

outfile = open(sys.argv[2], "w")

# Generate heading

output = ""
output += ";\n"
output += "; 1bpp font image of {0} characters\n".format(charcount)
output += ";\n"
output += "\n"
output += "\n"
output += ".global m72_charrom_data\n"
output += "\n"
output += "\n"
output += ".section .align512\n"
output += "\n"
output += "\n"
output += "\n"
output += "m72_charrom_data:\n"

# Generate image data

pixels = img.load()

for row in range(0, 8):
    comma = False
    for tile in range(0, 256):
        if ((tile % 16) == 0):
            output += "\n\t.byte "
            comma = False
        obyte = 0
        if (tile < charcount):
            posx = (tile % bytewidth) * 8
            posy = row + (tile // bytewidth) * 8
            for bit in range(0, 8):
                rpix = pixels[posx + bit, posy]
                if (rpix > 0):
                    rpix = 1
                obyte |= rpix << bit
        if (comma):
            output += ", "
        output += "0x{0:02X}".format(obyte)
        comma = True
    output += "\n"

outfile.write(output)
outfile.close()
img.close()

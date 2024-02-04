#
# Generates 2bpp images for inclusion as data.
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


print("\n2bpp image generator\n")

if (len(sys.argv) < 4):
    print("Need three arguments:")
    print("- Input image file to generate sprite set from")
    print("- Output avr assembly file to generate")
    print("- Image name to use for identifiers")
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
if ((img.width % 4) == 0):
    bytewidth = img.width // 4
else:
    print("Image width needs to be a multiple of 4!");
    sys.exit()

outfile = open(sys.argv[2], "w")
imgname = sys.argv[3]

# Generate heading

output = ""
output += ";\n"
output += "; 2bpp image {0}\n".format(imgname)
output += "; {0} x {1} pixels\n".format(img.width, img.height)
output += "; {0} bytes\n".format(bytewidth * img.height)
output += ";\n"
output += "\n"
output += "\n"
output += ".global img_{0}_getdataptr\n".format(imgname)
output += ".global img_{0}_getwidth\n".format(imgname)
output += ".global img_{0}_getheight\n".format(imgname)
output += ".global img_{0}_getpixel\n".format(imgname)
output += ".global img_{0}_getbyte\n".format(imgname)
output += "\n"
output += "\n"
output += ".section .text\n"
output += "\n"
output += "\n"
output += "\n"
output += ";\n"
output += "; Return data pointer (r25:r24) to image\n"
output += ";\n"
output += "img_{0}_getdataptr:\n".format(imgname)
output += "\tldi   r25,     hi8(img_{0}_data)\n".format(imgname)
output += "\tldi   r24,     lo8(img_{0}_data)\n".format(imgname)
output += "\tret\n"
output += "\n"
output += "\n"
output += "\n"
output += ";\n"
output += "; Return image width in pixels (r24)\n"
output += ";\n"
output += "img_{0}_getwidth:\n".format(imgname)
output += "\tldi   r24,     0x{0:02X}\n".format(img.width)
output += "\tret\n"
output += "\n"
output += "\n"
output += "\n"
output += ";\n"
output += "; Return image height in pixels (r24)\n"
output += ";\n"
output += "img_{0}_getheight:\n".format(imgname)
output += "\tldi   r24,     0x{0:02X}\n".format(img.height)
output += "\tret\n"
output += "\n"
output += "\n"
output += "\n"
output += ";\n"
output += "; Return pixel at position X (r24): Y (r22), into r24\n"
output += ";\n"
output += "img_{0}_getpixel:\n".format(imgname)
output += "\tldi   ZH,      hi8(img_{0}_data)\n".format(imgname)
output += "\tldi   ZL,      lo8(img_{0}_data)\n".format(imgname)
output += "\tldi   r25,     0x{0:02X}\n".format(bytewidth)
output += "\tmul   r22,     r25\n"
output += "\tadd   ZL,      r0\n"
output += "\tadc   ZH,      r1\n"
output += "\tldi   r25,     1\n"
output += "\tlsr   r24\n"
output += "\tbrcc  .+2\n"
output += "\tldi   r25,     4\n"
output += "\tlsr   r24\n"
output += "\tbrcc  .+2\n"
output += "\tswap  r25\n"
output += "\tadd   ZL,      r24\n"
output += "\tldi   r24,     0\n"
output += "\tadc   ZH,      r24\n"
output += "\tlpm   r0,      Z\n"
output += "\tmul   r0,      r25\n"
output += "\tlsl   r0\n"
output += "\trol   r24\n"
output += "\tlsl   r0\n"
output += "\trol   r24\n"
output += "\teor   r1,      r1\n"
output += "\tret\n"
output += "\n"
output += "\n"
output += "\n"
output += ";\n"
output += "; Return byte at byte position X (r24): Y (r22), into r24\n"
output += ";\n"
output += "img_{0}_getbyte:\n".format(imgname)
output += "\tldi   ZH,      hi8(img_{0}_data)\n".format(imgname)
output += "\tldi   ZL,      lo8(img_{0}_data)\n".format(imgname)
output += "\tldi   r25,     0x{0:02X}\n".format(bytewidth)
output += "\tmul   r22,     r25\n"
output += "\tadd   ZL,      r0\n"
output += "\tadc   ZH,      r1\n"
output += "\teor   r1,      r1\n"
output += "\tadd   ZL,      r24\n"
output += "\tadc   ZH,      r1\n"
output += "\tlpm   r24,     Z\n"
output += "\tret\n"
output += "\n"
output += "\n"
output += "\n"
output += "img_{0}_data:\n".format(imgname)

# Generate image data

pixels = img.load()

for posy in range(0, img.height):
    output += "\t.byte "
    comma = False
    for posbytex in range(0, bytewidth):
        obyte = 0
        for pospixelx in range(0, 4):
            rpix = pixels[(posbytex * 4) + pospixelx, posy]
            if (rpix >= 4):
                rpix = 0
            obyte = (obyte << 2) | rpix
        if (comma):
            output += ", "
        output += "0x{0:02X}".format(obyte)
        comma = True
    output += "\n"

outfile.write(output)
outfile.close()
img.close()

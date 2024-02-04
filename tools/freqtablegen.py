#
# Generates frequency table definition set as step sizes through 65536
# fractions (256 byte waveform with 8 fractional bits).
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


print("\nFrequency table generator\n")

if (len(sys.argv) < 3):
    print("Need two arguments:")
    print("- Sampling frequency in Hz (0: Uses NTSC line freq. of 15734Hz)")
    print("- Output .h file to generate")
    sys.exit()

freq = int(sys.argv[1])
outfile = open(sys.argv[2], "w")
if (freq == 0):
    freq = 15734

# Generate heading

output = ""
output += "\n"
output += "/* Frequency definitions for 128 MIDI notes, 256 byte sample size\n"
output += "** {0}Hz sampling frequency */\n".format(freq)
output += "\n"
output += "#ifndef FREQS_H\n"
output += "#define FREQS_H\n"
output += "\n"

# Frequencies in 1/1000th Hz units for the first 12 notes (Oops, second Midi
# octave, will just divide by 2 to work it out).

notefreqs = []
notefreqs.append(16351) # C0
notefreqs.append(17324) # Db0
notefreqs.append(18354) # D0
notefreqs.append(19445) # Eb0
notefreqs.append(20602) # E0
notefreqs.append(21827) # F0
notefreqs.append(23125) # Gb0
notefreqs.append(24500) # G0
notefreqs.append(25957) # Ab0
notefreqs.append(27500) # A0
notefreqs.append(29135) # Bb0
notefreqs.append(30868) # B0

notenames = []
notenames.append("C")
notenames.append("Db")
notenames.append("D")
notenames.append("Eb")
notenames.append("E")
notenames.append("F")
notenames.append("Gb")
notenames.append("G")
notenames.append("Ab")
notenames.append("A")
notenames.append("Bb")
notenames.append("B")

# Generate 128 definitions

freqpos = 0
freqmul = 1
octave = 0
for note in range(0, 128):
    step = (notefreqs[freqpos] * freqmul) * 65536
    step = (((step + (freq // 2)) // freq) + 1000) // 2000
    output += "#define FREQS_{0}{1}  ".format(notenames[freqpos], octave)
    if (len(notenames[freqpos]) < 2):
        output += " "
    if (octave < 10):
        output += " "
    output +="{0}\n".format(step)
    freqpos += 1
    if (freqpos >= 12):
        freqpos = 0
        freqmul *= 2
        octave += 1

output += "\n"
output += "#endif"
output += "\n"

outfile.write(output)
outfile.close()

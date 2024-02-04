/*
 *  Uzebox Kernel - Mode 72, 2bpp sprite code blocks
 *  Copyright (C) 2017 Sandor Zsuga (Jubatian)
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



.section M72_ALIGNED_SEC
.balign 512



;
; Code block macro
;
; A code block looks like as follows
;
;	st    X+,      r3/r4/r5   ; or adiw XL, 1 for transparency
;	st    X+,      r3/r4/r5   ; or adiw XL, 1 for transparency
;	st    X+,      r3/r4/r5   ; or adiw XL, 1 for transparency
;	st    X+,      r3/r4/r5   ; or adiw XL, 1 for transparency
;	ret
;
.macro SP2BLK c0, c1, c2, c3
.if     ((\c0) == 1)
	st    X+,      r3
.elseif ((\c0) == 2)
	st    X+,      r4
.elseif ((\c0) == 3)
	st    X+,      r5
.else
	adiw  XL,      1
.endif
.if     ((\c1) == 1)
	st    X+,      r3
.elseif ((\c1) == 2)
	st    X+,      r4
.elseif ((\c1) == 3)
	st    X+,      r5
.else
	adiw  XL,      1
.endif
.if     ((\c2) == 1)
	st    X+,      r3
.elseif ((\c2) == 2)
	st    X+,      r4
.elseif ((\c2) == 3)
	st    X+,      r5
.else
	adiw  XL,      1
.endif
.if     ((\c3) == 1)
	st    X+,      r3
.elseif ((\c3) == 2)
	st    X+,      r4
.elseif ((\c3) == 3)
	st    X+,      r5
.else
	adiw  XL,      1
.endif
	ret
.endm



;
; Mirrored jump table: lowest bits encode first pixel
;
m72_sp2bpp_mir:
	rjmp  sp2bpp_0000
	rjmp  sp2bpp_1000
	rjmp  sp2bpp_2000
	rjmp  sp2bpp_3000
	rjmp  sp2bpp_0100
	rjmp  sp2bpp_1100
	rjmp  sp2bpp_2100
	rjmp  sp2bpp_3100
	rjmp  sp2bpp_0200
	rjmp  sp2bpp_1200
	rjmp  sp2bpp_2200
	rjmp  sp2bpp_3200
	rjmp  sp2bpp_0300
	rjmp  sp2bpp_1300
	rjmp  sp2bpp_2300
	rjmp  sp2bpp_3300
	rjmp  sp2bpp_0010
	rjmp  sp2bpp_1010
	rjmp  sp2bpp_2010
	rjmp  sp2bpp_3010
	rjmp  sp2bpp_0110
	rjmp  sp2bpp_1110
	rjmp  sp2bpp_2110
	rjmp  sp2bpp_3110
	rjmp  sp2bpp_0210
	rjmp  sp2bpp_1210
	rjmp  sp2bpp_2210
	rjmp  sp2bpp_3210
	rjmp  sp2bpp_0310
	rjmp  sp2bpp_1310
	rjmp  sp2bpp_2310
	rjmp  sp2bpp_3310
	rjmp  sp2bpp_0020
	rjmp  sp2bpp_1020
	rjmp  sp2bpp_2020
	rjmp  sp2bpp_3020
	rjmp  sp2bpp_0120
	rjmp  sp2bpp_1120
	rjmp  sp2bpp_2120
	rjmp  sp2bpp_3120
	rjmp  sp2bpp_0220
	rjmp  sp2bpp_1220
	rjmp  sp2bpp_2220
	rjmp  sp2bpp_3220
	rjmp  sp2bpp_0320
	rjmp  sp2bpp_1320
	rjmp  sp2bpp_2320
	rjmp  sp2bpp_3320
	rjmp  sp2bpp_0030
	rjmp  sp2bpp_1030
	rjmp  sp2bpp_2030
	rjmp  sp2bpp_3030
	rjmp  sp2bpp_0130
	rjmp  sp2bpp_1130
	rjmp  sp2bpp_2130
	rjmp  sp2bpp_3130
	rjmp  sp2bpp_0230
	rjmp  sp2bpp_1230
	rjmp  sp2bpp_2230
	rjmp  sp2bpp_3230
	rjmp  sp2bpp_0330
	rjmp  sp2bpp_1330
	rjmp  sp2bpp_2330
	rjmp  sp2bpp_3330
	rjmp  sp2bpp_0001
	rjmp  sp2bpp_1001
	rjmp  sp2bpp_2001
	rjmp  sp2bpp_3001
	rjmp  sp2bpp_0101
	rjmp  sp2bpp_1101
	rjmp  sp2bpp_2101
	rjmp  sp2bpp_3101
	rjmp  sp2bpp_0201
	rjmp  sp2bpp_1201
	rjmp  sp2bpp_2201
	rjmp  sp2bpp_3201
	rjmp  sp2bpp_0301
	rjmp  sp2bpp_1301
	rjmp  sp2bpp_2301
	rjmp  sp2bpp_3301
	rjmp  sp2bpp_0011
	rjmp  sp2bpp_1011
	rjmp  sp2bpp_2011
	rjmp  sp2bpp_3011
	rjmp  sp2bpp_0111
	rjmp  sp2bpp_1111
	rjmp  sp2bpp_2111
	rjmp  sp2bpp_3111
	rjmp  sp2bpp_0211
	rjmp  sp2bpp_1211
	rjmp  sp2bpp_2211
	rjmp  sp2bpp_3211
	rjmp  sp2bpp_0311
	rjmp  sp2bpp_1311
	rjmp  sp2bpp_2311
	rjmp  sp2bpp_3311
	rjmp  sp2bpp_0021
	rjmp  sp2bpp_1021
	rjmp  sp2bpp_2021
	rjmp  sp2bpp_3021
	rjmp  sp2bpp_0121
	rjmp  sp2bpp_1121
	rjmp  sp2bpp_2121
	rjmp  sp2bpp_3121
	rjmp  sp2bpp_0221
	rjmp  sp2bpp_1221
	rjmp  sp2bpp_2221
	rjmp  sp2bpp_3221
	rjmp  sp2bpp_0321
	rjmp  sp2bpp_1321
	rjmp  sp2bpp_2321
	rjmp  sp2bpp_3321
	rjmp  sp2bpp_0031
	rjmp  sp2bpp_1031
	rjmp  sp2bpp_2031
	rjmp  sp2bpp_3031
	rjmp  sp2bpp_0131
	rjmp  sp2bpp_1131
	rjmp  sp2bpp_2131
	rjmp  sp2bpp_3131
	rjmp  sp2bpp_0231
	rjmp  sp2bpp_1231
	rjmp  sp2bpp_2231
	rjmp  sp2bpp_3231
	rjmp  sp2bpp_0331
	rjmp  sp2bpp_1331
	rjmp  sp2bpp_2331
	rjmp  sp2bpp_3331
	rjmp  sp2bpp_0002
	rjmp  sp2bpp_1002
	rjmp  sp2bpp_2002
	rjmp  sp2bpp_3002
	rjmp  sp2bpp_0102
	rjmp  sp2bpp_1102
	rjmp  sp2bpp_2102
	rjmp  sp2bpp_3102
	rjmp  sp2bpp_0202
	rjmp  sp2bpp_1202
	rjmp  sp2bpp_2202
	rjmp  sp2bpp_3202
	rjmp  sp2bpp_0302
	rjmp  sp2bpp_1302
	rjmp  sp2bpp_2302
	rjmp  sp2bpp_3302
	rjmp  sp2bpp_0012
	rjmp  sp2bpp_1012
	rjmp  sp2bpp_2012
	rjmp  sp2bpp_3012
	rjmp  sp2bpp_0112
	rjmp  sp2bpp_1112
	rjmp  sp2bpp_2112
	rjmp  sp2bpp_3112
	rjmp  sp2bpp_0212
	rjmp  sp2bpp_1212
	rjmp  sp2bpp_2212
	rjmp  sp2bpp_3212
	rjmp  sp2bpp_0312
	rjmp  sp2bpp_1312
	rjmp  sp2bpp_2312
	rjmp  sp2bpp_3312
	rjmp  sp2bpp_0022
	rjmp  sp2bpp_1022
	rjmp  sp2bpp_2022
	rjmp  sp2bpp_3022
	rjmp  sp2bpp_0122
	rjmp  sp2bpp_1122
	rjmp  sp2bpp_2122
	rjmp  sp2bpp_3122
	rjmp  sp2bpp_0222
	rjmp  sp2bpp_1222
	rjmp  sp2bpp_2222
	rjmp  sp2bpp_3222
	rjmp  sp2bpp_0322
	rjmp  sp2bpp_1322
	rjmp  sp2bpp_2322
	rjmp  sp2bpp_3322
	rjmp  sp2bpp_0032
	rjmp  sp2bpp_1032
	rjmp  sp2bpp_2032
	rjmp  sp2bpp_3032
	rjmp  sp2bpp_0132
	rjmp  sp2bpp_1132
	rjmp  sp2bpp_2132
	rjmp  sp2bpp_3132
	rjmp  sp2bpp_0232
	rjmp  sp2bpp_1232
	rjmp  sp2bpp_2232
	rjmp  sp2bpp_3232
	rjmp  sp2bpp_0332
	rjmp  sp2bpp_1332
	rjmp  sp2bpp_2332
	rjmp  sp2bpp_3332
	rjmp  sp2bpp_0003
	rjmp  sp2bpp_1003
	rjmp  sp2bpp_2003
	rjmp  sp2bpp_3003
	rjmp  sp2bpp_0103
	rjmp  sp2bpp_1103
	rjmp  sp2bpp_2103
	rjmp  sp2bpp_3103
	rjmp  sp2bpp_0203
	rjmp  sp2bpp_1203
	rjmp  sp2bpp_2203
	rjmp  sp2bpp_3203
	rjmp  sp2bpp_0303
	rjmp  sp2bpp_1303
	rjmp  sp2bpp_2303
	rjmp  sp2bpp_3303
	rjmp  sp2bpp_0013
	rjmp  sp2bpp_1013
	rjmp  sp2bpp_2013
	rjmp  sp2bpp_3013
	rjmp  sp2bpp_0113
	rjmp  sp2bpp_1113
	rjmp  sp2bpp_2113
	rjmp  sp2bpp_3113
	rjmp  sp2bpp_0213
	rjmp  sp2bpp_1213
	rjmp  sp2bpp_2213
	rjmp  sp2bpp_3213
	rjmp  sp2bpp_0313
	rjmp  sp2bpp_1313
	rjmp  sp2bpp_2313
	rjmp  sp2bpp_3313
	rjmp  sp2bpp_0023
	rjmp  sp2bpp_1023
	rjmp  sp2bpp_2023
	rjmp  sp2bpp_3023
	rjmp  sp2bpp_0123
	rjmp  sp2bpp_1123
	rjmp  sp2bpp_2123
	rjmp  sp2bpp_3123
	rjmp  sp2bpp_0223
	rjmp  sp2bpp_1223
	rjmp  sp2bpp_2223
	rjmp  sp2bpp_3223
	rjmp  sp2bpp_0323
	rjmp  sp2bpp_1323
	rjmp  sp2bpp_2323
	rjmp  sp2bpp_3323
	rjmp  sp2bpp_0033
	rjmp  sp2bpp_1033
	rjmp  sp2bpp_2033
	rjmp  sp2bpp_3033
	rjmp  sp2bpp_0133
	rjmp  sp2bpp_1133
	rjmp  sp2bpp_2133
	rjmp  sp2bpp_3133
	rjmp  sp2bpp_0233
	rjmp  sp2bpp_1233
	rjmp  sp2bpp_2233
	rjmp  sp2bpp_3233
	rjmp  sp2bpp_0333
	rjmp  sp2bpp_1333
	rjmp  sp2bpp_2333
	rjmp  sp2bpp_3333



;
; Normal jump table: highest bits encode first pixel
;
m72_sp2bpp_nor:
	rjmp  sp2bpp_0000
	rjmp  sp2bpp_0001
	rjmp  sp2bpp_0002
	rjmp  sp2bpp_0003
	rjmp  sp2bpp_0010
	rjmp  sp2bpp_0011
	rjmp  sp2bpp_0012
	rjmp  sp2bpp_0013
	rjmp  sp2bpp_0020
	rjmp  sp2bpp_0021
	rjmp  sp2bpp_0022
	rjmp  sp2bpp_0023
	rjmp  sp2bpp_0030
	rjmp  sp2bpp_0031
	rjmp  sp2bpp_0032
	rjmp  sp2bpp_0033
	rjmp  sp2bpp_0100
	rjmp  sp2bpp_0101
	rjmp  sp2bpp_0102
	rjmp  sp2bpp_0103
	rjmp  sp2bpp_0110
	rjmp  sp2bpp_0111
	rjmp  sp2bpp_0112
	rjmp  sp2bpp_0113
	rjmp  sp2bpp_0120
	rjmp  sp2bpp_0121
	rjmp  sp2bpp_0122
	rjmp  sp2bpp_0123
	rjmp  sp2bpp_0130
	rjmp  sp2bpp_0131
	rjmp  sp2bpp_0132
	rjmp  sp2bpp_0133
	rjmp  sp2bpp_0200
	rjmp  sp2bpp_0201
	rjmp  sp2bpp_0202
	rjmp  sp2bpp_0203
	rjmp  sp2bpp_0210
	rjmp  sp2bpp_0211
	rjmp  sp2bpp_0212
	rjmp  sp2bpp_0213
	rjmp  sp2bpp_0220
	rjmp  sp2bpp_0221
	rjmp  sp2bpp_0222
	rjmp  sp2bpp_0223
	rjmp  sp2bpp_0230
	rjmp  sp2bpp_0231
	rjmp  sp2bpp_0232
	rjmp  sp2bpp_0233
	rjmp  sp2bpp_0300
	rjmp  sp2bpp_0301
	rjmp  sp2bpp_0302
	rjmp  sp2bpp_0303
	rjmp  sp2bpp_0310
	rjmp  sp2bpp_0311
	rjmp  sp2bpp_0312
	rjmp  sp2bpp_0313
	rjmp  sp2bpp_0320
	rjmp  sp2bpp_0321
	rjmp  sp2bpp_0322
	rjmp  sp2bpp_0323
	rjmp  sp2bpp_0330
	rjmp  sp2bpp_0331
	rjmp  sp2bpp_0332
	rjmp  sp2bpp_0333
	rjmp  sp2bpp_1000
	rjmp  sp2bpp_1001
	rjmp  sp2bpp_1002
	rjmp  sp2bpp_1003
	rjmp  sp2bpp_1010
	rjmp  sp2bpp_1011
	rjmp  sp2bpp_1012
	rjmp  sp2bpp_1013
	rjmp  sp2bpp_1020
	rjmp  sp2bpp_1021
	rjmp  sp2bpp_1022
	rjmp  sp2bpp_1023
	rjmp  sp2bpp_1030
	rjmp  sp2bpp_1031
	rjmp  sp2bpp_1032
	rjmp  sp2bpp_1033
	rjmp  sp2bpp_1100
	rjmp  sp2bpp_1101
	rjmp  sp2bpp_1102
	rjmp  sp2bpp_1103
	rjmp  sp2bpp_1110
	rjmp  sp2bpp_1111
	rjmp  sp2bpp_1112
	rjmp  sp2bpp_1113
	rjmp  sp2bpp_1120
	rjmp  sp2bpp_1121
	rjmp  sp2bpp_1122
	rjmp  sp2bpp_1123
	rjmp  sp2bpp_1130
	rjmp  sp2bpp_1131
	rjmp  sp2bpp_1132
	rjmp  sp2bpp_1133
	rjmp  sp2bpp_1200
	rjmp  sp2bpp_1201
	rjmp  sp2bpp_1202
	rjmp  sp2bpp_1203
	rjmp  sp2bpp_1210
	rjmp  sp2bpp_1211
	rjmp  sp2bpp_1212
	rjmp  sp2bpp_1213
	rjmp  sp2bpp_1220
	rjmp  sp2bpp_1221
	rjmp  sp2bpp_1222
	rjmp  sp2bpp_1223
	rjmp  sp2bpp_1230
	rjmp  sp2bpp_1231
	rjmp  sp2bpp_1232
	rjmp  sp2bpp_1233
	rjmp  sp2bpp_1300
	rjmp  sp2bpp_1301
	rjmp  sp2bpp_1302
	rjmp  sp2bpp_1303
	rjmp  sp2bpp_1310
	rjmp  sp2bpp_1311
	rjmp  sp2bpp_1312
	rjmp  sp2bpp_1313
	rjmp  sp2bpp_1320
	rjmp  sp2bpp_1321
	rjmp  sp2bpp_1322
	rjmp  sp2bpp_1323
	rjmp  sp2bpp_1330
	rjmp  sp2bpp_1331
	rjmp  sp2bpp_1332
	rjmp  sp2bpp_1333
	rjmp  sp2bpp_2000
	rjmp  sp2bpp_2001
	rjmp  sp2bpp_2002
	rjmp  sp2bpp_2003
	rjmp  sp2bpp_2010
	rjmp  sp2bpp_2011
	rjmp  sp2bpp_2012
	rjmp  sp2bpp_2013
	rjmp  sp2bpp_2020
	rjmp  sp2bpp_2021
	rjmp  sp2bpp_2022
	rjmp  sp2bpp_2023
	rjmp  sp2bpp_2030
	rjmp  sp2bpp_2031
	rjmp  sp2bpp_2032
	rjmp  sp2bpp_2033
	rjmp  sp2bpp_2100
	rjmp  sp2bpp_2101
	rjmp  sp2bpp_2102
	rjmp  sp2bpp_2103
	rjmp  sp2bpp_2110
	rjmp  sp2bpp_2111
	rjmp  sp2bpp_2112
	rjmp  sp2bpp_2113
	rjmp  sp2bpp_2120
	rjmp  sp2bpp_2121
	rjmp  sp2bpp_2122
	rjmp  sp2bpp_2123
	rjmp  sp2bpp_2130
	rjmp  sp2bpp_2131
	rjmp  sp2bpp_2132
	rjmp  sp2bpp_2133
	rjmp  sp2bpp_2200
	rjmp  sp2bpp_2201
	rjmp  sp2bpp_2202
	rjmp  sp2bpp_2203
	rjmp  sp2bpp_2210
	rjmp  sp2bpp_2211
	rjmp  sp2bpp_2212
	rjmp  sp2bpp_2213
	rjmp  sp2bpp_2220
	rjmp  sp2bpp_2221
	rjmp  sp2bpp_2222
	rjmp  sp2bpp_2223
	rjmp  sp2bpp_2230
	rjmp  sp2bpp_2231
	rjmp  sp2bpp_2232
	rjmp  sp2bpp_2233
	rjmp  sp2bpp_2300
	rjmp  sp2bpp_2301
	rjmp  sp2bpp_2302
	rjmp  sp2bpp_2303
	rjmp  sp2bpp_2310
	rjmp  sp2bpp_2311
	rjmp  sp2bpp_2312
	rjmp  sp2bpp_2313
	rjmp  sp2bpp_2320
	rjmp  sp2bpp_2321
	rjmp  sp2bpp_2322
	rjmp  sp2bpp_2323
	rjmp  sp2bpp_2330
	rjmp  sp2bpp_2331
	rjmp  sp2bpp_2332
	rjmp  sp2bpp_2333
	rjmp  sp2bpp_3000
	rjmp  sp2bpp_3001
	rjmp  sp2bpp_3002
	rjmp  sp2bpp_3003
	rjmp  sp2bpp_3010
	rjmp  sp2bpp_3011
	rjmp  sp2bpp_3012
	rjmp  sp2bpp_3013
	rjmp  sp2bpp_3020
	rjmp  sp2bpp_3021
	rjmp  sp2bpp_3022
	rjmp  sp2bpp_3023
	rjmp  sp2bpp_3030
	rjmp  sp2bpp_3031
	rjmp  sp2bpp_3032
	rjmp  sp2bpp_3033
	rjmp  sp2bpp_3100
	rjmp  sp2bpp_3101
	rjmp  sp2bpp_3102
	rjmp  sp2bpp_3103
	rjmp  sp2bpp_3110
	rjmp  sp2bpp_3111
	rjmp  sp2bpp_3112
	rjmp  sp2bpp_3113
	rjmp  sp2bpp_3120
	rjmp  sp2bpp_3121
	rjmp  sp2bpp_3122
	rjmp  sp2bpp_3123
	rjmp  sp2bpp_3130
	rjmp  sp2bpp_3131
	rjmp  sp2bpp_3132
	rjmp  sp2bpp_3133
	rjmp  sp2bpp_3200
	rjmp  sp2bpp_3201
	rjmp  sp2bpp_3202
	rjmp  sp2bpp_3203
	rjmp  sp2bpp_3210
	rjmp  sp2bpp_3211
	rjmp  sp2bpp_3212
	rjmp  sp2bpp_3213
	rjmp  sp2bpp_3220
	rjmp  sp2bpp_3221
	rjmp  sp2bpp_3222
	rjmp  sp2bpp_3223
	rjmp  sp2bpp_3230
	rjmp  sp2bpp_3231
	rjmp  sp2bpp_3232
	rjmp  sp2bpp_3233
	rjmp  sp2bpp_3300
	rjmp  sp2bpp_3301
	rjmp  sp2bpp_3302
	rjmp  sp2bpp_3303
	rjmp  sp2bpp_3310
	rjmp  sp2bpp_3311
	rjmp  sp2bpp_3312
	rjmp  sp2bpp_3313
	rjmp  sp2bpp_3320
	rjmp  sp2bpp_3321
	rjmp  sp2bpp_3322
	rjmp  sp2bpp_3323
	rjmp  sp2bpp_3330
	rjmp  sp2bpp_3331
	rjmp  sp2bpp_3332
	rjmp  sp2bpp_3333


;
; Code blocks
;
sp2bpp_0000:
	SP2BLK 0,0,0,0
sp2bpp_0001:
	SP2BLK 0,0,0,1
sp2bpp_0002:
	SP2BLK 0,0,0,2
sp2bpp_0003:
	SP2BLK 0,0,0,3
sp2bpp_0010:
	SP2BLK 0,0,1,0
sp2bpp_0011:
	SP2BLK 0,0,1,1
sp2bpp_0012:
	SP2BLK 0,0,1,2
sp2bpp_0013:
	SP2BLK 0,0,1,3
sp2bpp_0020:
	SP2BLK 0,0,2,0
sp2bpp_0021:
	SP2BLK 0,0,2,1
sp2bpp_0022:
	SP2BLK 0,0,2,2
sp2bpp_0023:
	SP2BLK 0,0,2,3
sp2bpp_0030:
	SP2BLK 0,0,3,0
sp2bpp_0031:
	SP2BLK 0,0,3,1
sp2bpp_0032:
	SP2BLK 0,0,3,2
sp2bpp_0033:
	SP2BLK 0,0,3,3
sp2bpp_0100:
	SP2BLK 0,1,0,0
sp2bpp_0101:
	SP2BLK 0,1,0,1
sp2bpp_0102:
	SP2BLK 0,1,0,2
sp2bpp_0103:
	SP2BLK 0,1,0,3
sp2bpp_0110:
	SP2BLK 0,1,1,0
sp2bpp_0111:
	SP2BLK 0,1,1,1
sp2bpp_0112:
	SP2BLK 0,1,1,2
sp2bpp_0113:
	SP2BLK 0,1,1,3
sp2bpp_0120:
	SP2BLK 0,1,2,0
sp2bpp_0121:
	SP2BLK 0,1,2,1
sp2bpp_0122:
	SP2BLK 0,1,2,2
sp2bpp_0123:
	SP2BLK 0,1,2,3
sp2bpp_0130:
	SP2BLK 0,1,3,0
sp2bpp_0131:
	SP2BLK 0,1,3,1
sp2bpp_0132:
	SP2BLK 0,1,3,2
sp2bpp_0133:
	SP2BLK 0,1,3,3
sp2bpp_0200:
	SP2BLK 0,2,0,0
sp2bpp_0201:
	SP2BLK 0,2,0,1
sp2bpp_0202:
	SP2BLK 0,2,0,2
sp2bpp_0203:
	SP2BLK 0,2,0,3
sp2bpp_0210:
	SP2BLK 0,2,1,0
sp2bpp_0211:
	SP2BLK 0,2,1,1
sp2bpp_0212:
	SP2BLK 0,2,1,2
sp2bpp_0213:
	SP2BLK 0,2,1,3
sp2bpp_0220:
	SP2BLK 0,2,2,0
sp2bpp_0221:
	SP2BLK 0,2,2,1
sp2bpp_0222:
	SP2BLK 0,2,2,2
sp2bpp_0223:
	SP2BLK 0,2,2,3
sp2bpp_0230:
	SP2BLK 0,2,3,0
sp2bpp_0231:
	SP2BLK 0,2,3,1
sp2bpp_0232:
	SP2BLK 0,2,3,2
sp2bpp_0233:
	SP2BLK 0,2,3,3
sp2bpp_0300:
	SP2BLK 0,3,0,0
sp2bpp_0301:
	SP2BLK 0,3,0,1
sp2bpp_0302:
	SP2BLK 0,3,0,2
sp2bpp_0303:
	SP2BLK 0,3,0,3
sp2bpp_0310:
	SP2BLK 0,3,1,0
sp2bpp_0311:
	SP2BLK 0,3,1,1
sp2bpp_0312:
	SP2BLK 0,3,1,2
sp2bpp_0313:
	SP2BLK 0,3,1,3
sp2bpp_0320:
	SP2BLK 0,3,2,0
sp2bpp_0321:
	SP2BLK 0,3,2,1
sp2bpp_0322:
	SP2BLK 0,3,2,2
sp2bpp_0323:
	SP2BLK 0,3,2,3
sp2bpp_0330:
	SP2BLK 0,3,3,0
sp2bpp_0331:
	SP2BLK 0,3,3,1
sp2bpp_0332:
	SP2BLK 0,3,3,2
sp2bpp_0333:
	SP2BLK 0,3,3,3
sp2bpp_1000:
	SP2BLK 1,0,0,0
sp2bpp_1001:
	SP2BLK 1,0,0,1
sp2bpp_1002:
	SP2BLK 1,0,0,2
sp2bpp_1003:
	SP2BLK 1,0,0,3
sp2bpp_1010:
	SP2BLK 1,0,1,0
sp2bpp_1011:
	SP2BLK 1,0,1,1
sp2bpp_1012:
	SP2BLK 1,0,1,2
sp2bpp_1013:
	SP2BLK 1,0,1,3
sp2bpp_1020:
	SP2BLK 1,0,2,0
sp2bpp_1021:
	SP2BLK 1,0,2,1
sp2bpp_1022:
	SP2BLK 1,0,2,2
sp2bpp_1023:
	SP2BLK 1,0,2,3
sp2bpp_1030:
	SP2BLK 1,0,3,0
sp2bpp_1031:
	SP2BLK 1,0,3,1
sp2bpp_1032:
	SP2BLK 1,0,3,2
sp2bpp_1033:
	SP2BLK 1,0,3,3
sp2bpp_1100:
	SP2BLK 1,1,0,0
sp2bpp_1101:
	SP2BLK 1,1,0,1
sp2bpp_1102:
	SP2BLK 1,1,0,2
sp2bpp_1103:
	SP2BLK 1,1,0,3
sp2bpp_1110:
	SP2BLK 1,1,1,0
sp2bpp_1111:
	SP2BLK 1,1,1,1
sp2bpp_1112:
	SP2BLK 1,1,1,2
sp2bpp_1113:
	SP2BLK 1,1,1,3
sp2bpp_1120:
	SP2BLK 1,1,2,0
sp2bpp_1121:
	SP2BLK 1,1,2,1
sp2bpp_1122:
	SP2BLK 1,1,2,2
sp2bpp_1123:
	SP2BLK 1,1,2,3
sp2bpp_1130:
	SP2BLK 1,1,3,0
sp2bpp_1131:
	SP2BLK 1,1,3,1
sp2bpp_1132:
	SP2BLK 1,1,3,2
sp2bpp_1133:
	SP2BLK 1,1,3,3
sp2bpp_1200:
	SP2BLK 1,2,0,0
sp2bpp_1201:
	SP2BLK 1,2,0,1
sp2bpp_1202:
	SP2BLK 1,2,0,2
sp2bpp_1203:
	SP2BLK 1,2,0,3
sp2bpp_1210:
	SP2BLK 1,2,1,0
sp2bpp_1211:
	SP2BLK 1,2,1,1
sp2bpp_1212:
	SP2BLK 1,2,1,2
sp2bpp_1213:
	SP2BLK 1,2,1,3
sp2bpp_1220:
	SP2BLK 1,2,2,0
sp2bpp_1221:
	SP2BLK 1,2,2,1
sp2bpp_1222:
	SP2BLK 1,2,2,2
sp2bpp_1223:
	SP2BLK 1,2,2,3
sp2bpp_1230:
	SP2BLK 1,2,3,0
sp2bpp_1231:
	SP2BLK 1,2,3,1
sp2bpp_1232:
	SP2BLK 1,2,3,2
sp2bpp_1233:
	SP2BLK 1,2,3,3
sp2bpp_1300:
	SP2BLK 1,3,0,0
sp2bpp_1301:
	SP2BLK 1,3,0,1
sp2bpp_1302:
	SP2BLK 1,3,0,2
sp2bpp_1303:
	SP2BLK 1,3,0,3
sp2bpp_1310:
	SP2BLK 1,3,1,0
sp2bpp_1311:
	SP2BLK 1,3,1,1
sp2bpp_1312:
	SP2BLK 1,3,1,2
sp2bpp_1313:
	SP2BLK 1,3,1,3
sp2bpp_1320:
	SP2BLK 1,3,2,0
sp2bpp_1321:
	SP2BLK 1,3,2,1
sp2bpp_1322:
	SP2BLK 1,3,2,2
sp2bpp_1323:
	SP2BLK 1,3,2,3
sp2bpp_1330:
	SP2BLK 1,3,3,0
sp2bpp_1331:
	SP2BLK 1,3,3,1
sp2bpp_1332:
	SP2BLK 1,3,3,2
sp2bpp_1333:
	SP2BLK 1,3,3,3
sp2bpp_2000:
	SP2BLK 2,0,0,0
sp2bpp_2001:
	SP2BLK 2,0,0,1
sp2bpp_2002:
	SP2BLK 2,0,0,2
sp2bpp_2003:
	SP2BLK 2,0,0,3
sp2bpp_2010:
	SP2BLK 2,0,1,0
sp2bpp_2011:
	SP2BLK 2,0,1,1
sp2bpp_2012:
	SP2BLK 2,0,1,2
sp2bpp_2013:
	SP2BLK 2,0,1,3
sp2bpp_2020:
	SP2BLK 2,0,2,0
sp2bpp_2021:
	SP2BLK 2,0,2,1
sp2bpp_2022:
	SP2BLK 2,0,2,2
sp2bpp_2023:
	SP2BLK 2,0,2,3
sp2bpp_2030:
	SP2BLK 2,0,3,0
sp2bpp_2031:
	SP2BLK 2,0,3,1
sp2bpp_2032:
	SP2BLK 2,0,3,2
sp2bpp_2033:
	SP2BLK 2,0,3,3
sp2bpp_2100:
	SP2BLK 2,1,0,0
sp2bpp_2101:
	SP2BLK 2,1,0,1
sp2bpp_2102:
	SP2BLK 2,1,0,2
sp2bpp_2103:
	SP2BLK 2,1,0,3
sp2bpp_2110:
	SP2BLK 2,1,1,0
sp2bpp_2111:
	SP2BLK 2,1,1,1
sp2bpp_2112:
	SP2BLK 2,1,1,2
sp2bpp_2113:
	SP2BLK 2,1,1,3
sp2bpp_2120:
	SP2BLK 2,1,2,0
sp2bpp_2121:
	SP2BLK 2,1,2,1
sp2bpp_2122:
	SP2BLK 2,1,2,2
sp2bpp_2123:
	SP2BLK 2,1,2,3
sp2bpp_2130:
	SP2BLK 2,1,3,0
sp2bpp_2131:
	SP2BLK 2,1,3,1
sp2bpp_2132:
	SP2BLK 2,1,3,2
sp2bpp_2133:
	SP2BLK 2,1,3,3
sp2bpp_2200:
	SP2BLK 2,2,0,0
sp2bpp_2201:
	SP2BLK 2,2,0,1
sp2bpp_2202:
	SP2BLK 2,2,0,2
sp2bpp_2203:
	SP2BLK 2,2,0,3
sp2bpp_2210:
	SP2BLK 2,2,1,0
sp2bpp_2211:
	SP2BLK 2,2,1,1
sp2bpp_2212:
	SP2BLK 2,2,1,2
sp2bpp_2213:
	SP2BLK 2,2,1,3
sp2bpp_2220:
	SP2BLK 2,2,2,0
sp2bpp_2221:
	SP2BLK 2,2,2,1
sp2bpp_2222:
	SP2BLK 2,2,2,2
sp2bpp_2223:
	SP2BLK 2,2,2,3
sp2bpp_2230:
	SP2BLK 2,2,3,0
sp2bpp_2231:
	SP2BLK 2,2,3,1
sp2bpp_2232:
	SP2BLK 2,2,3,2
sp2bpp_2233:
	SP2BLK 2,2,3,3
sp2bpp_2300:
	SP2BLK 2,3,0,0
sp2bpp_2301:
	SP2BLK 2,3,0,1
sp2bpp_2302:
	SP2BLK 2,3,0,2
sp2bpp_2303:
	SP2BLK 2,3,0,3
sp2bpp_2310:
	SP2BLK 2,3,1,0
sp2bpp_2311:
	SP2BLK 2,3,1,1
sp2bpp_2312:
	SP2BLK 2,3,1,2
sp2bpp_2313:
	SP2BLK 2,3,1,3
sp2bpp_2320:
	SP2BLK 2,3,2,0
sp2bpp_2321:
	SP2BLK 2,3,2,1
sp2bpp_2322:
	SP2BLK 2,3,2,2
sp2bpp_2323:
	SP2BLK 2,3,2,3
sp2bpp_2330:
	SP2BLK 2,3,3,0
sp2bpp_2331:
	SP2BLK 2,3,3,1
sp2bpp_2332:
	SP2BLK 2,3,3,2
sp2bpp_2333:
	SP2BLK 2,3,3,3
sp2bpp_3000:
	SP2BLK 3,0,0,0
sp2bpp_3001:
	SP2BLK 3,0,0,1
sp2bpp_3002:
	SP2BLK 3,0,0,2
sp2bpp_3003:
	SP2BLK 3,0,0,3
sp2bpp_3010:
	SP2BLK 3,0,1,0
sp2bpp_3011:
	SP2BLK 3,0,1,1
sp2bpp_3012:
	SP2BLK 3,0,1,2
sp2bpp_3013:
	SP2BLK 3,0,1,3
sp2bpp_3020:
	SP2BLK 3,0,2,0
sp2bpp_3021:
	SP2BLK 3,0,2,1
sp2bpp_3022:
	SP2BLK 3,0,2,2
sp2bpp_3023:
	SP2BLK 3,0,2,3
sp2bpp_3030:
	SP2BLK 3,0,3,0
sp2bpp_3031:
	SP2BLK 3,0,3,1
sp2bpp_3032:
	SP2BLK 3,0,3,2
sp2bpp_3033:
	SP2BLK 3,0,3,3
sp2bpp_3100:
	SP2BLK 3,1,0,0
sp2bpp_3101:
	SP2BLK 3,1,0,1
sp2bpp_3102:
	SP2BLK 3,1,0,2
sp2bpp_3103:
	SP2BLK 3,1,0,3
sp2bpp_3110:
	SP2BLK 3,1,1,0
sp2bpp_3111:
	SP2BLK 3,1,1,1
sp2bpp_3112:
	SP2BLK 3,1,1,2
sp2bpp_3113:
	SP2BLK 3,1,1,3
sp2bpp_3120:
	SP2BLK 3,1,2,0
sp2bpp_3121:
	SP2BLK 3,1,2,1
sp2bpp_3122:
	SP2BLK 3,1,2,2
sp2bpp_3123:
	SP2BLK 3,1,2,3
sp2bpp_3130:
	SP2BLK 3,1,3,0
sp2bpp_3131:
	SP2BLK 3,1,3,1
sp2bpp_3132:
	SP2BLK 3,1,3,2
sp2bpp_3133:
	SP2BLK 3,1,3,3
sp2bpp_3200:
	SP2BLK 3,2,0,0
sp2bpp_3201:
	SP2BLK 3,2,0,1
sp2bpp_3202:
	SP2BLK 3,2,0,2
sp2bpp_3203:
	SP2BLK 3,2,0,3
sp2bpp_3210:
	SP2BLK 3,2,1,0
sp2bpp_3211:
	SP2BLK 3,2,1,1
sp2bpp_3212:
	SP2BLK 3,2,1,2
sp2bpp_3213:
	SP2BLK 3,2,1,3
sp2bpp_3220:
	SP2BLK 3,2,2,0
sp2bpp_3221:
	SP2BLK 3,2,2,1
sp2bpp_3222:
	SP2BLK 3,2,2,2
sp2bpp_3223:
	SP2BLK 3,2,2,3
sp2bpp_3230:
	SP2BLK 3,2,3,0
sp2bpp_3231:
	SP2BLK 3,2,3,1
sp2bpp_3232:
	SP2BLK 3,2,3,2
sp2bpp_3233:
	SP2BLK 3,2,3,3
sp2bpp_3300:
	SP2BLK 3,3,0,0
sp2bpp_3301:
	SP2BLK 3,3,0,1
sp2bpp_3302:
	SP2BLK 3,3,0,2
sp2bpp_3303:
	SP2BLK 3,3,0,3
sp2bpp_3310:
	SP2BLK 3,3,1,0
sp2bpp_3311:
	SP2BLK 3,3,1,1
sp2bpp_3312:
	SP2BLK 3,3,1,2
sp2bpp_3313:
	SP2BLK 3,3,1,3
sp2bpp_3320:
	SP2BLK 3,3,2,0
sp2bpp_3321:
	SP2BLK 3,3,2,1
sp2bpp_3322:
	SP2BLK 3,3,2,2
sp2bpp_3323:
	SP2BLK 3,3,2,3
sp2bpp_3330:
	SP2BLK 3,3,3,0
sp2bpp_3331:
	SP2BLK 3,3,3,1
sp2bpp_3332:
	SP2BLK 3,3,3,2
sp2bpp_3333:
	SP2BLK 3,3,3,3

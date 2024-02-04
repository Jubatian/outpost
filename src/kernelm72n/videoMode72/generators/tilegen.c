/*
**  Converts GIMP header to Uzebox Mode 72 tiles assembly source.
**
**  By Sandor Zsuga (Jubatian)
**
**  Licensed under GNU General Public License version 3.
**
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
**  ---
**
**  The input image must be n x 8 (width x height) where 'n' is a multiple of
**  8. It must have 16 colors or less. Color index 0 is the bg. color (one of
**  the per scanline replaceable colors), color index 15 is the border color
**  (also optionally per scanline replaceable).
**
**  Produces result onto standard output, redirect into a ".s" file to get it
**  proper.
**
**  It analyzes the tileset and attempts to generate a compressed result. It
**  always produces a full 256 tile set, unused tiles will reproduce tile 0.
*/



/*  The GIMP header to use */
#include "tileset.h"


#include <stdio.h>
#include <stdlib.h>



/* Tile row structure: describes a tile row */

typedef struct{
 unsigned int  pix;    /* The 8 tile row pixels (in 8 nybbles, high nybble left) */
 unsigned int  ucnt;   /* Usage count */
 unsigned int  uflg;   /* Usage flags: bit 0: lower half use, 1: upper half use */
                       /* During generation, bit 2 marks a row used (generated) */
}tilerow_t;



/* Packs 8 4bpp pixels into a 32 bit value */
static unsigned int packpx(unsigned char* px)
{
 return ((px[0] & 0xFU) << 28) |
        ((px[1] & 0xFU) << 24) |
        ((px[2] & 0xFU) << 20) |
        ((px[3] & 0xFU) << 16) |
        ((px[4] & 0xFU) << 12) |
        ((px[5] & 0xFU) <<  8) |
        ((px[6] & 0xFU) <<  4) |
        ((px[7] & 0xFU)      );
}



/* Reads a pixel from the packed format */
static unsigned int readpx(unsigned int pix, unsigned int no)
{
 return (pix >> (28 - ((no & 7U) << 2))) & 0xFU;
}



/* Generates tile row common code block. If ext is set, assumes extra rjmp
** blocks, otherwise no such blocks. */
static void gen_common(unsigned int no, unsigned int ext)
{
 printf("\n");
 printf("tilerow_common_%u:\n", no);
 printf("\tout   PIXOUT,  r0\n");
 printf("\tbreq  tilerow_exit_c_%u ; Uses Z flag\n", no);
 printf("\tpop   r0\n");
 printf("tilerow_entry_%u:\n", no);
 printf("\tdec   r20\n");
 printf("\tld    ZL,      Y+\n");
 printf("\tout   PIXOUT,  r0\n");
 printf("\tpop   r0\n");
 printf("\tpop   r21\n");
 printf("\tpop   r1\n");
 printf("\tout   PIXOUT,  r0\n");
 printf("\tpop   r22\n");
 printf("\tpop   r23\n");
 printf("\tpop   r0\n");
 printf("\tout   PIXOUT,  r21\n");
 if (ext == 0U){ printf("\trjmp  .\n"); }
 printf("\tijmp\n");
 printf("tilerow_exit_c_%u:\n", no);
 printf("\tbrts  tilerow_exit_%u   ; (1582 / 1621)\n", no);
 printf("\tmov   r22,     r17\n");
 printf("\tmov   r23,     r17\n");
 printf("\tmovw  r0,      r22\n");
 printf("\tout   PIXOUT,  r17\n");
 printf("\tld    ZL,      Y+\n");
 printf("\tset\n");
 if (ext == 0U){ printf("\trjmp  .\n"); }
 printf("\tijmp\n");
 printf("tilerow_exit_%u:\n", no);
 printf("\tsbic  GPR0,    1       ; (1622) Color 0 (bg) loading enabled?\n");
 printf("\tin    r2,      GPR1    ; (1623) If so, load it\n");
 printf("\tsbic  GPR0,    2       ; (1624) Color 15 (border) loading enabled?\n");
 printf("\tin    r17,     GPR1    ; (1625) If so, load it\n");
 printf("\tldi   ZL,      LB_SPR - 1 ; (1626) 254(HI):255(LO): Sprite conf\n");
 printf("\tout   STACKL,  ZL      ; (1627)\n");
 printf("\tret                    ; (1631)\n");
 printf("\n");
}



/* Generates tile row map. If ext is set, assumes jumping to a second rjmp
** which reaches the tile. half specifies upper (0) / lower (1) half, only
** used if ext is set. */
static void gen_rowmap(unsigned int no, unsigned int half, unsigned int* rows, unsigned int ext)
{
 unsigned int i;

 printf("\n");
 printf(".balign 512\n");
 printf("tilerow_%u_map:\n", no);

 if (ext != 0U){

  for (i = 0U; i < 256U; i ++){
   printf("\trjmp  tilerow_block_%u_j%u\n", rows[i], half);
  }

 }else{

  for (i = 0U; i < 256U; i ++){
   printf("\trjmp  tilerow_block_%u\n", rows[i]);
  }

 }

 printf("\n");
}



/* Generates a transfer jump for extended modes. */
static void gen_transfer(unsigned int rowno, unsigned int jno)
{
 printf("tilerow_block_%u_j%u:\n", rowno, jno);
 printf("\trjmp  tilerow_block_%u\n", rowno);
}



/* Generates a tile row. */
static void gen_row(unsigned int rowno, unsigned int pix, unsigned int jno)
{
 printf("tilerow_block_%u:\n", rowno);
 printf("\tout   PIXOUT,  r1\n");
 printf("\tst    X+,      r%u\n", readpx(pix, 0U) + 2U);
 printf("\tst    X+,      r%u\n", readpx(pix, 1U) + 2U);
 printf("\tst    X+,      r%u\n", readpx(pix, 2U) + 2U);
 printf("\tout   PIXOUT,  r22\n");
 printf("\tst    X+,      r%u\n", readpx(pix, 3U) + 2U);
 printf("\tst    X+,      r%u\n", readpx(pix, 4U) + 2U);
 printf("\tst    X+,      r%u\n", readpx(pix, 5U) + 2U);
 printf("\tout   PIXOUT,  r23\n");
 printf("\tst    X+,      r%u\n", readpx(pix, 6U) + 2U);
 printf("\tst    X+,      r%u\n", readpx(pix, 7U) + 2U);
 printf("\trjmp  tilerow_common_%u\n", jno);
}




int main(void)
{
 unsigned int  tcnt = width / 8U;
 unsigned int  i;
 unsigned int  j;
 unsigned int  r;
 unsigned int  pix;
 unsigned char pal[16];
 unsigned int  rowmap[8][256]; /* Tile row mapping for each tile */
 tilerow_t     rows[2048];     /* All tile rows */
 unsigned int  rowc  = 0U;     /* Count of tile rows */
 unsigned int  rowcu = 0U;     /* Count of tile rows with upper half only usage */
 unsigned int  rowcl = 0U;     /* Count of tile rows with lower half only usage */
 unsigned int  rowca = 0U;     /* Count of tile rows with both half usage */
 unsigned int  amode = 0U;     /* Code tile assembly generator */
 unsigned int  bucket[5][256]; /* Row buckets for sorting rows for a generator mode */
 unsigned int  bsize[5] = {0, 0, 0, 0, 0};

 /* Basic tests */

 if ((width & 0x7U) != 0U){
  fprintf(stderr, "Input width must be a multiple of 8!\n");
  return 1;
 }
 if (tcnt > 256U){
  fprintf(stderr, "Input must have 256 or less tiles!\n");
  return 1;
 }


 /* Create palette (pulling down input colors to Uzebox BBGGGRRR format) */

 for (i = 0U; i < 16U; i++){
  pal[i] =
      ((((unsigned char)(header_data_cmap[i][0])) >> 5) << 0) |
      ((((unsigned char)(header_data_cmap[i][1])) >> 5) << 3) |
      ((((unsigned char)(header_data_cmap[i][2])) >> 6) << 6);
 }


 /* Process input into rows and row usage maps */

 for (i = 0U; i < tcnt; i ++){

  for (j = 0U; j < 8U; j ++){

   pix = packpx((unsigned char *)(&header_data[(j * tcnt * 8U) + (i * 8)]));

   for (r = 0U; r < rowc; r ++){
    if (pix == rows[r].pix){ break; } /* Found matching row: reuse */
   }

   if (r == rowc){ /* New row */
    rows[r].pix  = pix;
    rows[r].ucnt = 0U;
    rows[r].uflg = 0U;
    rowc ++;
   }

   rows[r].ucnt ++;
   if (j < 4U){ rows[r].uflg |= 2U; } /* Use in tile upper half */
   else       { rows[r].uflg |= 1U; } /* Use in tile lower half */

   rowmap[j][i] = r;

  }

 }

 /* Extra tiles: just replicate tile 0 (don't add extra usage for these, no
 ** point in the stats, this is just for generating full jump tables). */

 for (i = tcnt; i < 256U; i ++){

  for (j = 0U; j < 8U; j ++){

   rowmap[j][i] = rowmap[j][0];

  }

 }

 /* Count upper / lower half only tiles */

 for (i = 0U; i < rowc; i ++){

  if      (rows[i].uflg == 2U){ rowcu ++; }
  else if (rows[i].uflg == 1U){ rowcl ++; }
  else if (rows[i].uflg == 3U){ rowca ++; }
  else                        { fprintf(stderr, "Internal error, abort\n"); return 1; }

 }


 /* Select generator */

 if (rowc <= 82U){

  /* Smallest: Up to 82 shared rows */
  amode = 0U;

 }else if ( (rowca <= 85U) &&
            ((rowcl + rowca) <= 167) &&
            ((rowcu + rowca) <= 167) ){

  /* Still fits in a mode without the extra rjmp tables */
  amode = 1U;

 }else if ( (rowca <= 149U) &&
            ((rowcl + rowca) <= 426U) &&
            ((rowcu + rowca) <= 426U) ){

  /* Needs a large mode */
  amode = 5U;

 }else{

  /* Too many rows: Currently not supported */
  fprintf(stderr, "Error: Too many tile rows! (%u shared, %u upper, %u lower, %u total)\n", rowca, rowcu, rowcl, rowc);
  return 1;

 }


 /* Start generating assembly file, statistics */

 printf("\n");
 printf(";\n");
 printf("; Mode 72 tileset of %u tiles\n", tcnt);
 printf(";\n");
 printf(";\n");
 printf("; Total number of tile rows: %4u\n", rowc);
 printf("; Shared rows .............: %4u\n", rowca);
 printf("; Upper half only rows ....: %4u\n", rowcu);
 printf("; Lower half only rows ....: %4u\n", rowcl);
 printf(";\n");
 printf("; Chosen generator mode ...: %4u\n", amode);
 printf(";\n");
 printf("\n");
 printf("\n");
 printf("#include <avr/io.h>\n");
 printf("#define  PIXOUT   _SFR_IO_ADDR(PORTC)\n");
 printf("#define  GPR0     _SFR_IO_ADDR(GPIOR0)\n");
 printf("#define  GPR1     _SFR_IO_ADDR(GPIOR1)\n");
 printf("#define  STACKL   0x3D\n");
 printf("#define  LB_SPR   254\n");
 printf("#ifndef  M72_ALIGNED_SEC\n");
 printf("#define  M72_ALIGNED_SEC .text.align512\n");
 printf("#endif\n");
 printf("\n");
 printf("\n");
 printf(".global m72_defpalette\n");
 printf(".global m72_deftilerows\n");
 printf("\n");
 printf("\n");
 printf(".section .text\n");
 printf("\n");
 printf("\n");
 printf("\n");
 printf("m72_defpalette:\n");
 printf("\t.byte");
 for (i = 0U; i < 7U; i++){ printf(" 0x%02X,", pal[i + 0U]); }
 printf(" 0x%02X\n", pal[ 7U]);
 printf("\t.byte");
 for (i = 0U; i < 7U; i++){ printf(" 0x%02X,", pal[i + 8U]); }
 printf(" 0x%02X\n", pal[15U]);
 printf("\n");
 printf("\n");
 printf("\n");
 printf("m72_deftilerows:\n");

 for (i = 0U; i < 8U; i ++){
  printf("\trjmp  tilerow_%u\n", i);
 }

 printf("\n");

 for (i = 0U; i < 8U; i ++){
  printf("tilerow_%u:\n", i);
  printf("\tldi   ZH,      hi8(pm(tilerow_%u_map))\n", i);
  printf("\tout   PIXOUT,  r1      ; ( 599) Pixel 19\n");
  printf("\tjmp   tilerow_entry_0\n");
  printf("\n");
 }

 printf("\n");
 printf("\n");
 printf(".section M72_ALIGNED_SEC\n");
 printf("\n");
 printf("\n");
 printf("\n");


 /* Create by generator */

 switch (amode){



  case 0U:

   /* Generate 4 tile row maps */

   gen_rowmap(0, 0, &(rowmap[0][0]), 0);
   gen_rowmap(1, 0, &(rowmap[1][0]), 0);
   gen_rowmap(2, 0, &(rowmap[2][0]), 0);
   gen_rowmap(3, 0, &(rowmap[3][0]), 0);

   /* Generate middle region */

   for (i = 0U; i < rowc; i ++){
    gen_row(i, rows[i].pix, 0);
   }
   gen_common(0, 0);

   /* Generate 4 tile row maps */

   gen_rowmap(4, 0, &(rowmap[4][0]), 0);
   gen_rowmap(5, 0, &(rowmap[5][0]), 0);
   gen_rowmap(6, 0, &(rowmap[6][0]), 0);
   gen_rowmap(7, 0, &(rowmap[7][0]), 0);

   break;



  case 1U:

   /*
   ** Prepare: Fill in buckets. Organization:
   **
   ** 1: Upper half, 82 blocks
   ** 2: Shared, 85 blocks
   ** 3: Lower half, 82 blocks
   */

   /* First put all shared tiles in the shared bucket */

   for (i = 0U; i < rowc; i ++){
    if ((rows[i].uflg & 0x7U) == 3U){  /* Not yet used & Both upper & lower usage */
     bucket[2][bsize[2]] = i;
     bsize[2] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* For the remaining slots in the shared bucket, fill in rows from either
   ** upper or lower half, whichever has more. */

   for (i = 0U; i < rowc; i ++){
    if (bsize[2] >= 85U){ break; }     /* Full */
    if ( ( ((rows[i].uflg & 0x7U) == 1U) &&
           (rowcl >  rowcu) ) ||
         ( ((rows[i].uflg & 0x7U) == 2U) &&
           (rowcl <= rowcu) ) ){
     bucket[2][bsize[2]] = i;
     bsize[2] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* If there are still slots remaining, fill them with whatever row still
   ** available */

   for (i = 0U; i < rowc; i ++){
    if (bsize[2] >= 85U){ break; }     /* Full */
    if ((rows[i].uflg & 0x4U) == 0U){  /* Not yet used */
     bucket[2][bsize[2]] = i;
     bsize[2] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Populate top row bucket */

   for (i = 0U; i < rowc; i ++){
    if ((rows[i].uflg & 0x7U) == 2U){  /* Not yet used & upper half */
     bucket[1][bsize[1]] = i;
     bsize[1] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Populate bottom row bucket */

   for (i = 0U; i < rowc; i ++){
    if ((rows[i].uflg & 0x7U) == 1U){  /* Not yet used & lower half */
     bucket[3][bsize[3]] = i;
     bsize[3] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Generate top block */

   printf("\n");
   printf(".balign 512\n");
   printf("\n");

   for (i = 0U; i < bsize[1]; i ++){
    gen_row(bucket[1][i], rows[bucket[1][i]].pix, 0);
   }
   gen_common(0, 0);

   /* Generate 4 tile row maps */

   gen_rowmap(0, 0, &(rowmap[0][0]), 0);
   gen_rowmap(1, 0, &(rowmap[1][0]), 0);
   gen_rowmap(2, 0, &(rowmap[2][0]), 0);
   gen_rowmap(3, 0, &(rowmap[3][0]), 0);

   /* Generate middle region */

   for (i = 0U; i < bsize[2]; i ++){
    gen_row(bucket[2][i], rows[bucket[2][i]].pix, 1);
   }

   /* Generate 4 tile row maps */

   gen_rowmap(4, 0, &(rowmap[4][0]), 0);
   gen_rowmap(5, 0, &(rowmap[5][0]), 0);
   gen_rowmap(6, 0, &(rowmap[6][0]), 0);
   gen_rowmap(7, 0, &(rowmap[7][0]), 0);

   /* Generate bottom block */

   gen_common(1, 0);
   for (i = 0U; i < bsize[3]; i ++){
    gen_row(bucket[3][i], rows[bucket[3][i]].pix, 1);
   }

   break;



  case 5U:

   /*
   ** Prepare: Fill in buckets. Organization:
   **
   ** 0: Upper half, 149 + 64 blocks
   ** 1: Upper half, 64 blocks (below the upper half jump tables)
   ** 2: Shared, 149 blocks
   ** 3: Lower half, 64 blocks (above the lower half jump tables)
   ** 4: Lower half, 149 + 64 blocks
   */

   /* First put all shared tiles in the shared bucket */

   for (i = 0U; i < rowc; i ++){
    if ((rows[i].uflg & 0x7U) == 3U){  /* Not yet used & Both upper & lower usage */
     bucket[2][bsize[2]] = i;
     bsize[2] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* For the remaining slots in the shared bucket, fill in rows from either
   ** upper or lower half, whichever has more. */

   for (i = 0U; i < rowc; i ++){
    if (bsize[2] >= 149U){ break; }    /* Full */
    if ( ( ((rows[i].uflg & 0x7U) == 1U) &&
           (rowcl >  rowcu) ) ||
         ( ((rows[i].uflg & 0x7U) == 2U) &&
           (rowcl <= rowcu) ) ){
     bucket[2][bsize[2]] = i;
     bsize[2] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* If there are still slots remaining, fill them with whatever row still
   ** available */

   for (i = 0U; i < rowc; i ++){
    if (bsize[2] >= 149U){ break; }    /* Full */
    if ((rows[i].uflg & 0x4U) == 0U){  /* Not yet used */
     bucket[2][bsize[2]] = i;
     bsize[2] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Populate top row bucket below the upper half jump tables */

   for (i = 0U; i < rowc; i ++){
    if (bsize[1] >= 64U){ break; }     /* Full */
    if ((rows[i].uflg & 0x7U) == 2U){  /* Not yet used & upper half */
     bucket[1][bsize[1]] = i;
     bsize[1] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Populate remaining upper half slots if any */

   for (i = 0U; i < rowc; i ++){
    if ((rows[i].uflg & 0x7U) == 2U){  /* Not yet used & upper half */
     bucket[0][bsize[0]] = i;
     bsize[0] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Populate bottom row bucket above the lower half jump tables */

   for (i = 0U; i < rowc; i ++){
    if (bsize[3] >= 64U){ break; }     /* Full */
    if ((rows[i].uflg & 0x7U) == 1U){  /* Not yet used & lower half */
     bucket[3][bsize[3]] = i;
     bsize[3] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Populate remaining lower half slots if any */

   for (i = 0U; i < rowc; i ++){
    if ((rows[i].uflg & 0x7U) == 1U){  /* Not yet used & lower half */
     bucket[4][bsize[4]] = i;
     bsize[4] ++;
     rows[i].uflg |= 4U;
    }
   }

   /* Generate top block if its bucket contains anything */

   if (bsize[0] != 0U){

    printf("\n");
    printf(".balign 512\n");
    printf("\n");

    j = bsize[0];
    if (j > 149U){ j = 149U; }

    for (i = 0U; i < j; i ++){
     gen_row(bucket[0][i], rows[bucket[0][i]].pix, 0);
    }

    printf("\n");
    printf(".balign 512\n");
    printf("\n");

    for (i = 0U; i < bsize[0]; i ++){
     gen_transfer(bucket[0][i], 0);
    }
    gen_common(0, 1);

    for (i = j; i < bsize[0]; i ++){
     gen_row(bucket[0][i], rows[bucket[0][i]].pix, 0);
    }

   }

   /* Generate 4 tile row maps */

   gen_rowmap(0, 0, &(rowmap[0][0]), 1);
   gen_rowmap(1, 0, &(rowmap[1][0]), 1);
   gen_rowmap(2, 0, &(rowmap[2][0]), 1);
   gen_rowmap(3, 0, &(rowmap[3][0]), 1);

   /* Generate middle region */

   for (i = 0U; i < bsize[1]; i ++){
    gen_row(bucket[1][i], rows[bucket[1][i]].pix, 1);
   }

   printf("\n");
   printf(".balign 512\n");
   printf("\n");

   for (i = 0U; i < bsize[1]; i ++){
    gen_transfer(bucket[1][i], 0);
   }
   for (i = 0U; i < bsize[2]; i ++){
    gen_transfer(bucket[2][i], 0);
   }
   gen_common(1, 1);

   for (i = 0U; i < bsize[2]; i ++){
    gen_row(bucket[2][i], rows[bucket[2][i]].pix, 1);
   }

   printf("\n");
   printf(".balign 512\n");
   printf("\n");

   for (i = 0U; i < bsize[2]; i ++){
    gen_transfer(bucket[2][i], 1);
   }
   for (i = 0U; i < bsize[3]; i ++){
    gen_transfer(bucket[3][i], 1);
   }
   gen_common(2, 1);

   for (i = 0U; i < bsize[3]; i ++){
    gen_row(bucket[3][i], rows[bucket[3][i]].pix, 2);
   }

   /* Generate 4 tile row maps */

   gen_rowmap(4, 1, &(rowmap[4][0]), 1);
   gen_rowmap(5, 1, &(rowmap[5][0]), 1);
   gen_rowmap(6, 1, &(rowmap[6][0]), 1);
   gen_rowmap(7, 1, &(rowmap[7][0]), 1);

   /* Generate bottom block if its bucket contains anything */

   if (bsize[4] != 0U){

    printf("\n");
    printf(".balign 512\n");
    printf("\n");

    j = bsize[4];
    if (j > 64U){ j = 64U; }

    for (i = 0U; i < j; i ++){
     gen_row(bucket[4][i], rows[bucket[4][i]].pix, 3);
    }

    printf("\n");
    printf(".balign 512\n");
    printf("\n");

    for (i = 0U; i < bsize[4]; i ++){
     gen_transfer(bucket[4][i], 1);
    }
    gen_common(3, 1);

    for (i = j; i < bsize[4]; i ++){
     gen_row(bucket[4][i], rows[bucket[4][i]].pix, 3);
    }

   }

   break;



  default:

   fprintf(stderr, "Error: Unimplemented generator (%u)\n", amode);
   return 1;

 }


 return 0;
}

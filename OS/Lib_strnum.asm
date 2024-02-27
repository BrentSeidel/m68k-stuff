|------------------------------------------------------------------------------
| Title      : Library String<->Number Routines
| Written by : Brent Seidel
| Date       : 4-Feb-2024
| Description: Common library routines for converting between strings and numbers
|------------------------------------------------------------------------------
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
|==============================================================================
|  Library section.  Common routines go here.
|
    .section LIB_SECT,#execinstr,#alloc
|
|------------------------------------------------------------------------------
|  Convert numbers to string
|  Inputs: Number to convert (long)
|          Address of destination string (long)
|          Conversion flags (word)
|   Conversion flags:
|       0-1: Size (00-Byte, 01-Word, 10-Long)
|         2: Sign (0-unsigned, 1-signed)
|         3: Lead (0-no leading characters, 1-leading zeros)
|         4: Negative (internal use only)
|       5-7: Unused
|      8-15: Unused
|  Stack:
|    16(A6) - Flags (Word)
|    12(A6) - Address of destination (long)
|     8(A6) - Number to convert (long)
|     4(A6) - Old PC (long)
|      (A6) - Old A6
|   -18(A6) - Conversion buffer
|   Registers:
|       D0 - Number to convert
|       D1 - Conversion flags
|       D2 - Scratch
|       D3 - Max size of result
|       D4 - Fill character
|       A0 - Address of buffer
|       A1 - Index into conversion table
|
|  Convert a number to an octal string
|
    .sbttl OCTSTR - Convert number to a string of octal digits
OCTSTR:
    .global OCTSTR
    link %A6,#-20
    movem.l %D0-%D3/%A0-%A1,-(%SP)
    move.l 8(%A6),%D0    |  Number to convert
    move.w 16(%A6),%D1   |  Conversion flags
    lea -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
    move.l %D1,%D2       |  Get size field
    and.b #3,%D2
    bne 1f
    and.l #0xFF,%D0      |  Byte size
    move.w #3,%D3        |  Number of characters
    btst #2,%D1          |  Check if signed
    beq 3f
    tst.b %D0            |  Check if positive or negative
    bpl 3f
    bset #4,%D1          |  Set flag for negative
    neg.b %D0
    bra 3f
1:
    subq.b #1,%D2
    bne 2f
    and.l #0xFFFF,%D0    |  Word size
    move.w #6,%D3
    btst #2,%D1          |  Check if signed
    beq 3f
    tst.w %D0            |  Check if positive or negative
    bpl 3f
    bset #4,%D1          |  Set flag for negative
    neg.w %D0
    bra 3f
2:
    move.w #11,%D3       |  Long size
    btst #2,%D1          |  Check if signed
    beq 3f
    tst.l %D0            |  Check if positive or negative
    bpl 3f
    bset #4,%D1          |  Set flag for negative
    neg.l %D0
3:
    |
    |  Conversion loop
    |
OCT.CVT:
    move.l %D0,%D2
    and.l #7,%D2
    move.l %D2,%A1
    move.b NUMTBL(%A1),-(%A0)
    LSR.L #3,%D0
    bne 2f               |  If not zero, keep looping
    btst #3,%D1
    beq 3f               |  If no leading zeros, exit
2:
    dbf %D3,OCT.CVT
    bra 4f
3:
    SUBQ.B #1,%D3
4:
    |
    |  Check for adding negative sign
    |
    btst #2,%D1
    beq OCT.OUT          |  Not signed
    btst #4,%D1
    beq OCT.OUT          |  Not negative
    move.b #'-',-(%A0)
    |
    |  Move to destination
    |
OCT.OUT:
    move.l %A0,%D2       |  Pointer to start of string
    move.l %A0,%A1
    lea -2(%A6),%A0      |  Address of end of conversion buffer
    move.l %A0,%D3
    sub.l %D2,%D3        |  Length of converted string
    move.l 12(%A6),%A0   |  Address of destination
    move.w (%A0),%D2     |  Max size of destination
    cmp.w %D3,%D2
    bge 2f
    move.w %D2,%D3
2:
    move.w %D3,2(%A0)   |  Set length of destination
    subq.l #1,%D3
    addq.l #4,%A0       |  Point to start of text part of string
3:
    move.b (%A1)+,(%A0)+
    dbf %D3,3b
    |
    |  Cleanup and return
    |
    movem.l (%SP)+,%D0-%D3/%A0-%A1
    unlk %A6
    rts
|
|  Convert a number to a decimal string
|
    .sbttl DECSTR - Convert number to a string of decimal digits
DECSTR:
    .global DECSTR
    link %A6,#-20
    movem.l %D0-%D3/%A0-%A1,-(%SP)
    move.l 8(%A6),%D0    |  Number to convert
    move.w 16(%A6),%D1   |  Conversion flags
    lea -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
    move.l %D1,%D2       |  Get size field
    and.b #3,%D2
    bne 1f
    and.l #0xFF,%D0      |  Byte size
    move.w #3,%D3        |  Number of characters
    btst #2,%D1          |  Check if signed
    beq 3f
    tst.b %D0            |  Check if positive or negative
    bpl 3f
    bset #4,%D1          |  Set flag for negative
    neg.b %D0
    BRA 3f
1:
    subq.b #1,%D2
    bne 2f
    and.l #0xFFFF,%D0    |  Word size
    move.w #5,%D3        |  Number of characters
    btst #2,%D1          |  Check if signed
    beq 3f
    tst.w %D0            |  Check if positive or negative
    bpl 3f
    bset #4,%D1          |  Set flag for negative
    neg.w %D0
    bra 3f
2:                       |  Long size
    move.w #10,%D3       |  Number of characters
    btst #2,%D1          |  Check if signed
    beq DEC.LONG         |  Not signed
    tst.l %D0            |  Check if positive or negative
    bpl DEC.LONG         |  Positive
    bset #4,%D1          |  Set flag for negative
    neg.l %D0
    bra DEC.LONG         |  Use BCD conversion for longs.
3:
    clr.l %D2
    move.l %D2,%A1       |  Can't directly clear A registers.
    |
    |  Conversion loop.  Some updates will be needed here
    |  since the DIVU instruction only allows a 16 bit quotient.
    |  This may cause overflow for 32 bit numbers.
    |
DEC.CVT:
    move.l %D0,%D2
    divu #10,%D2         |  Quotient is in lower 16 bits, remainder
    swap %D2
    move.w %D2,%A1       |  Get remainder
    move.b NUMTBL(%A1),-(%A0)
    clr.w %D2
    swap %D2
    move.l %D2,%D0       |  Put quotient back into D0
    bne 2f               |  If not zero, keep looping
    btst #3,%D1
    beq 3f               |  If no leading zeros, exit
2:
    dbf %D3,DEC.CVT
    bra 4f
3:
    subq.b #1,%D3
DEC.SIGN:
    |
    |  Check for adding negative sign
    |
    btst #2,%D1
    beq DEC.OUT           |  Not signed
    btst #4,%D1
    beq DEC.OUT           |  Not negative
    move.b #'-',-(%A0)
    |
    |  Move to destination
    |
DEC.OUT:
    move.l %A0,%D2       |  Pointer to start of string
    move.l %A0,%A1
    lea -2(%A6),%A0      |  Address of end of conversion buffer
    move.l %A0,%D3
    sub.l %D2,%D3        |  Length of converted string
    move.l 12(%A6),%A0   |  Address of destination
    move.w (%A0),%D2     |  Max size of destination
    cmp.w %D3,%D2
    bge 2f
    move.w %D2,%D3
2:
    move.w %D3, 2(%A0)   |  Set length of destination
    subq.l #1,%D3
    addq.l #4,%A0        |  Point to start of text part of string
3:
    move.b (%A1)+,(%A0)+
    dbf %D3,3b
    |
    |  Cleanup and return
    |
    movem.l (%SP)+,%D0-%D3/%A0-%A1
    unlk %A6
    rts
|
|  Long decimal conversion requires using the long to BCD routine since
|  the basic 68000 doesn't have a full 32 bit divider.
|
DEC.LONG:
    move.l %D0,-(%SP)
    subq.l #8,%SP
    bsr LONG_BCD
    move.l (%SP)+,%D0
    move.l (%SP)+,%D2
    addq.l #4,%SP
    move.l %D4,-(%SP)
    |
    |  Move the BCD digits to the conversion buffer
    |  %D0 is BCD MSW
    |  %D1 is conversion flags
    |  %D2 is BCD LSW
    |  %D3 is length (10)
    |  %D4 is scratch
    |  %A0 is pointer to conversion buffer
    |  %A1 is index into number table
    |
1:
    move.l %D2,%D4       |  Get digit
    and.l #15,%D4
    move.l %D4,%A1
    move.b NUMTBL(%A1),-(%A0)
    lsr.l #1,%D0         |  Shift digit out
    roxr.l #1,%D2
    lsr.l #1,%D0
    roxr.l #1,%D2
    lsr.l #1,%D0
    roxr.l #1,%D2
    lsr.l #1,%D0
    roxr.l #1,%D2
    tst.l %D2            |  Check for zero remaining
    bne 0f
    tst.l %D0
    bne 0f
    btst #3,%D1          |  Check for leading zeros
    beq 2f
0:
   dbf %D3,1b
2:
    move.l (%SP)+,%D4
    bra DEC.SIGN
|
|  Convert a number to an hexidecimal string
|
    .sbttl HEXSTR - Convert number to a string of hexidecimal digits
HEXSTR:
    .global HEXSTR
    link %A6,#-20
    movem.l %D0-%D3/%A0-%A1,-(%SP)
    move.l 8(%A6),%D0    |  Number to convert
    move.w 16(%A6),%D1   |  Conversion flags
    lea -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
    move.l %D1,%D2       |  Get size field
    and.b #3,%D2
    bne 1f
    and.l #0xFF,%D0      |  Byte size
    move.w #2,%D3        |  Number of characters
    btst #2,%D1          |  Check if signed
    beq 3f
    tst.b %D0            |  Check if positive or negative
    bpl 3f
    bset #4,%D1          |  Set flag for negative
    neg.b %D0
    bra 3f
1:
    subq.b #1,%D2
    bne 2f
    and.l #0xFFFF,%D0   |  Word size
    move.w #4,%D3
    btst #2,%D1         |  Check if signed
    beq 3f
    tst.w %D0           |  Check if positive or negative
    bpl 3f
    bset #4,%D1         |  Set flag for negative
    neg.w %D0
    bra 3f
2:
    move.w #8,%D3       |  Long size
    btst #2,%D1         |  Check if signed
    beq 3f
    tst.l %D0           |  Check if positive or negative
    bpl 3f
    bset #4,%D1         |  Set flag for negative
    neg.l %D0
3:
    |
    |  Conversion loop
    |
HEX.CVT:
    move.l %D0,%D2
    and.l #15,%D2
    move.l %D2,%A1
    move.b NUMTBL(%A1),-(%A0)
    lsr.l #4,%D0
    bne 2f               |  If not zero, keep looping
    btst #3,%D1
    beq 3f               |  If no leading zeros, exit
2:
    dbf %D3,HEX.CVT
    bra 4f
3:
    subq.b #1,%D3
4:
    |
    |  Check for adding negative sign
    |
    btst #2,%D1
    beq HEX.OUT           |  Not signed
    btst #4,%D1
    beq HEX.OUT           |  Not negative
    move.b #'-',-(%A0)
    |
    |  Move to destination
    |
HEX.OUT:
    move.l %A0,%D2       |  Pointer to start of string
    move.l %A0,%A1
    lea -2(%A6),%A0      |  Address of end of conversion buffer
    move.l %A0,%D3
    sub.l %D2,%D3        |  Length of converted string
    move.l 12(%A6),%A0   |  Address of destination
    move.w (%A0),%D2     |  Max size of destination
    cmp.w %D3,%D2
    bge 2f
    move.w %D2,%D3
2:
    move.w %D3, 2(%A0)   |  Set length of destination
    subq.l #1,%D3
    addq.l #4,%A0        |  Point to start of text part of string
3:
    move.b (%A1)+,(%A0)+
    dbf %D3,3b
    |
    |  Cleanup and return
    |
    movem.l (%SP)+,%D0-%D3/%A0-%A1
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Convert a long to BCD using the double dabble algorithm, see
|  https://en.wikipedia.org/wiki/Double_dabble
|  This is mainly intended to be used for converting longs to decimal
|  strings, but may have other uses.  It would not be needed for 68k
|  family members that have a full 32 bit divider.
|
|  The calling sequence is:
|  move.l long,-(%SP)
|  subq.l #8,%SP  |  Space for BCD
|  jsr LONG_BCD
|  move.l (%SP)+,bcd_msw
|  move.l (%SP)+,bcd_lsw
|  addq.l #4,%SP
|
    .sbttl LONG_BCD - Convert a long to BCD
LONG_BCD:
    .global LONG_BCD
    link %A6,#0
    movem.l %D0-%D6,-(%SP)
    clr.l %D0            |  BCD MSW
    clr.l %D1            |  BCD LSW
    clr.l %D6            |  Zero
    move.l 16(%A6),%D2   |  Long to convert
    move.w #31,%D3       |  Number of bits to process, minus 1
BCD.LOOP:
    |
    |  Make adjustments as needed
    |
    moveq.l #3,%D5
    move.l %D1,%D4       |  Digit 0
    and.l #0xF,%D4       |  Isolate digit
    cmp.l #5, %D4        |  Check if 5 or greater
    blt 0f
    add.l %D5,%D1        |  Add 3, if so.
    addx.l %D6,%D0       |  Make sure carry is propagated
0:
    move.l %D1,%D4       |  Digit 1
    lsl.l #4,%D5
    and.l #0xF0,%D4
    cmp.l #0x50,%D4
    blt 1f
    add.l %D5,%D1
    addx.l %D6,%D1
1:
    move.l %D1,%D4       |  Digit 2
    lsl.l #4,%D5
    and.l #0xF00,%D4
    cmp.l #0x500,%D4
    blt 2f
    add.l %D5,%D1
    addx.l %D6,%D1
2:
    move.l %D1,%D4       |  Digit 3
    lsl.l #4,%D5
    and.l #0xF000,%D4
    cmp.l #0x5000,%D4
    blt 3f
    add.l %D5,%D1
    addx.l %D6,%D1
3:
    move.l %D1,%D4       |  Digit 4
    lsl.l #4,%D5
    and.l #0xF0000,%D4
    cmp.l #0x50000,%D4
    blt 4f
    add.l %D5,%D1
    addx.l %D6,%D1
4:
    move.l %D1,%D4       |  Digit 5
    lsl.l #4,%D5
    and.l #0xF00000,%D4
    cmp.l #0x500000,%D4
    blt 5f
    add.l %D5,%D1
    addx.l %D6,%D1
5:
    move.l %D1,%D4       |  Digit 6
    lsl.l #4,%D5
    and.l #0xF000000,%D4
    cmp.l #0x5000000,%D4
    blt 6f
    add.l %D5,%D1
    addx.l %D6,%D1
6:
    move.l %D1,%D4       |  Digit 7
    lsl.l #4,%D5
    and.l #0xF0000000,%D4
    cmp.l #0x50000000,%D4
    blt 7f
    add.l %D5,%D1
    addx.l %D6,%D1
7:
    move.l %D0,%D4       |  Digit 8
    moveq.l #3,%D5
    and.l #0xF,%D4
    cmp.l #0x5,%D4
    blt 8f
    add.l %D5,%D0
8:
    |
    |  For a 32 bit long, digit 8 can only be a maximum of 4, so no need
    |  to check it.
    |
    move #0,%CCR         |  Make sure all the flags are clear for the shift
    roxl.l #1,%D2        |  Shift bits one place
    roxl.l #1,%D1
    roxl.l #1,%D0
    dbf %D3,BCD.LOOP

    move.l %D0,8(%A6)   |  Move the BCD values to the stack
    move.l %D1,12(%A6)
    movem.l (%SP)+,%D0-%D6
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Convert strings to numbers
|
|  The following routines convert strings containing digits to
|  numbers.  Conversion stop when an invalid digit is detected.
|  The results are always returned as a long word (32 bits).
|  The calling sequence is:
|  move.l str, -(%SP)
|  jsr strxxx
|  move.l (%SP)+, num
|
|  Octal conversion
|
    .sbttl STROCT - Convert a string of octal digits to a number
STROCT:
    .global STROCT
    link %A6,#0
    movem.l %D0-%D3/%A0,-(%SP)
    clr.l %D0              |  Accumulator for number
    clr.l %D1              |  Size of string
    clr.l %D2              |  Flag for negative
    clr.l %D3              |  Character to convert
    move.l 8(%A6),%A0      |  Address of string
    move.w 2(%A0),%D1      |  Length of string
    tst.w %D1              |  Check for zero length
    beq 1f                 |  If so, just return 0
    lea 4(%A0),%A0         |  Address of string buffer
    cmp.b #'-',(%A0)       |  Is first character a dash (negative)
    bne 2f
      bset #0,%D2          |  Set a flag to indicate negative
      addq.l #1,%A0
      subq.l #1,%D1
2:
    move.b (%A0)+,%D3
    sub.b #'0',%D3
    bmi 1f                 |  Check for out of range characters
    cmp.b #8,%D3
    bge 1f
    lsl.l #3,%D0           |  Shift accumulator and
    add.l %D3,%D0          |  add new digit
    subq.w #1,%D1          |  Check for end of string
    bne 2b                 |  Loop until reached
|
|  Cleanup and return
|
1:
    btst #0,%D2            |  Check for negative
    beq 3f
      neg.l %D0
3:
    move.l %D0,8(%A6)
    movem.l (%SP)+,%D0-%D3/%A0
    unlk %A6
    rts
|
|  Decimal Conversion
|
    .sbttl STRDEC - Convert a string of decimal digits to a number
STRDEC:
    .global STRDEC
    link %A6,#0
    movem.l %D0-%D4/%A0,-(%SP)
    clr.l %D0              |  Accumulator for number
    clr.l %D1              |  Size of string
    clr.l %D2              |  Flag for negative
    clr.l %D3              |  Character to convert
    move.l 8(%A6),%A0      |  Address of string
    move.w 2(%A0),%D1      |  Length of string
    tst.w %D1              |  Check for zero length
    beq 1f                 |  If so, just return 0
    lea 4(%A0),%A0         |  Address of string buffer
    cmp.b #'-',(%A0)       |  Is first character a dash (negative)
    bne 2f
      bset #0,%D2          |  Set a flag to indicate negative
      addq.l #1,%A0
      subq.l #1,%D1
2:
    move.b (%A0)+,%D3
    sub.b #'0',%D3
    bmi 1f                 |  Check for out of range characters
    cmp.b #10,%D3
    bge 1f
    move.l %D0,%D4         |  Multiply by 10 without a 32 bit MUL instruction
    lsl.l #3,%D0
    lsl.l #1,%D4
    add.l %D4,%D0
    add.l %D3,%D0          |  Add in the next digit
    subq.w #1,%D1
    bne 2b
1:
    btst #0,%D2            |  Check for negative
    beq 3f
      neg.l %D0
3:
    move.l %D0,8(%A6)
    movem.l (%SP)+,%D0-%D4/%A0
    unlk %A6
    rts
|
|  Hexiecimal Conversion
|
    .sbttl STRHEX - Convert a string of hexidecimal digits to a number
STRHEX:
    .global STRHEX
    link %A6,#0
    movem.l %D0-%D3/%A0,-(%SP)
    clr.l %D0              |  Accumulator for number
    clr.l %D1              |  Size of string
    clr.l %D2              |  Flag for negative
    clr.l %D3              |  Character to convert
    move.l 8(%A6),%A0      |  Address of string
    move.w 2(%A0),%D1      |  Length of string
    tst.w %D1              |  Check for zero length
    beq 1f                 |  If so, just return 0
    lea 4(%A0),%A0         |  Address of string buffer
    cmp.b #'-',(%A0)       |  Is first character a dash (negative)
    bne 2f
      bset #0,%D2          |  Set a flag to indicate negative
      addq.l #1,%A0
      subq.l #1,%D1
2:
    move.b (%A0)+,%D3
    sub.b #'0',%D3
    bmi 1f                 |  Check for out of range characters
    cmp.b #10,%D3
    blt 4f
    sub.b #'A'-'0',%D3
    bmi 1f
    cmp.b #6,%D3
    bge 1f
    add.b #10,%D3
4:
    lsl.l #4,%D0           |  Shift accumulator and
    add.l %D3,%D0          |  add new digit
    subq.w #1,%D1          |  Check for end of string
    bne 2b                 |  Loop until reached
|
|  Cleanup and return
|
1:
    btst #0,%D2            |  Check for negative
    beq 3f
      neg.l %D0
3:
    move.l %D0,8(%A6)
    movem.l (%SP)+,%D0-%D3/%A0
    unlk %A6
    rts
|

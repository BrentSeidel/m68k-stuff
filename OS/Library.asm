|-----------------------------------------------------------
| Title      : Library Routines
| Written by : Brent Seidel
| Date       : 4-Feb-2024
| Description: Common library routines for OS and users
|-----------------------------------------------------------
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
|==============================================================================
|  Library data section.  Common data and data for library routines go here.
|  Note that all of this data should be readonly.
|
    .section LIB_DATA,#alloc
    TEXT NEWLINE,"\r\n"
    .global NEWLINE
    TEXT LIBMSG,"Error calling library - check addressing modes.\r\n"
NUMTBL:                 |  Table for converting between numbers and ASCII strings
    .ascii "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ"
|==============================================================================
|  Library section.  Common routines go here.
|
    .section LIB_SECT,#execinstr,#alloc
|
|  Jump table for library routines.
LIBTBL:
    .global LIBTBL,OCTSTR,DECSTR,HEXSTR
    .long LIBERR
    .long OCTSTR
    .long DECSTR
    .long HEXSTR
    .long STROCT
    .long STRDEC
    .long STRHEX
    .long GETSTR
    .long FIND_CHRSTR
    .long CHR_STR
    .long LONG_BCD
|
|  Error message to catch some jump table errors
|
LIBERR:
    PRINT #LIBMSG
    RTS
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
    LINK %A6,#-20
    MOVEM.L %D0-%D3/%A0-%A1,-(%SP)
    MOVE.L 8(%A6),%D0    |  Number to convert
    MOVE.W 16(%A6),%D1   |  Conversion flags
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
    MOVE.L %D1,%D2       |  Get size field
    AND.B #3,%D2
    bne 1f
    AND.L #0xFF,%D0      |  Byte size
    MOVE #3,%D3          |  Number of characters
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.B %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.B %D0
    bra 3f
1:
    SUBQ.B #1,%D2
    bne 2f
    AND.L #0xFFFF,%D0    |  Word size
    MOVE #6,%D3
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.W %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.W %D0
    bra 3f
2:
    MOVE #11,%D3         |  Long size
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.L %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.L %D0
3:
    |
    |  Conversion loop
    |
OCT.CVT:
    MOVE.L %D0,%D2
    AND.L #7,%D2
    MOVE.L %D2,%A1
    MOVE.B NUMTBL(%A1),-(%A0)
    LSR.L #3,%D0
    bne 2f
    BTST #3,%D1
    beq 3f
2:
    dbf %D3,OCT.CVT
    bra 4f
3:
    SUBQ.B #1,%D3
4:
    |
    |  Check for adding negative sign
    |
    BTST #2,%D1
    beq OCT.OUT          |  Not signed
    BTST #4,%D1
    beq OCT.OUT          |  Not negative
    MOVE.B #'-',-(%A0)
    |
    |  Move to destination
    |
OCT.OUT:
    MOVE.L %A0,%D2       |  Pointer to start of string
    MOVE.L %A0,%A1
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    MOVE.L %A0,%D3
    SUB.L %D2,%D3        |  Length of converted string
    MOVE.L 12(%A6),%A0   |  Address of destination
    MOVE.W (%A0),%D2     |  Max size of destination
    CMP.W %D3,%D2
    bge 2f
    MOVE.W %D2,%D3
2:
    MOVE.W %D3,2(%A0)   |  Set length of destination
    SUBQ.L #1,%D3
    ADDQ.L #4,%A0       |  Point to start of text part of string
3:
    MOVE.B (%A1)+,(%A0)+
    dbf %D3,3b
    |
    |  Cleanup and return
    |
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A1
    UNLK %A6
    RTS
|
|  Convert a number to a decimal string
|
    .sbttl DECSTR - Convert number to a string of decimal digits
DECSTR:
    LINK %A6,#-20
    MOVEM.L %D0-%D3/%A0-%A1,-(%SP)
    MOVE.L 8(%A6),%D0    |  Number to convert
    MOVE.W 16(%A6),%D1   |  Conversion flags
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
    MOVE.L %D1,%D2       |  Get size field
    AND.B #3,%D2
    bne 1f
    AND.L #0xFF,%D0      |  Byte size
    move.w #3,%D3        |  Number of characters
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.B %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.B %D0
    BRA 3f
1:
    SUBQ.B #1,%D2
    bne 2f
    AND.L #0xFFFF,%D0    |  Word size
    move.w #5,%D3        |  Number of characters
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.W %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.W %D0
    bra 3f
2:                       |  Long size
    move.w #10,%D3       |  Number of characters
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.L %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.L %D0
3:
    CLR.L %D2
    MOVE.L %D2,%A1       |  Can't directly clear A registers.
    |
    |  Conversion loop.  Some updates will be needed here
    |  since the DIVU instruction only allows a 16 bit quotient.
    |  This may cause overflow for 32 bit numbers.
    |
DEC.CVT:
    MOVE.L %D0,%D2
    DIVU #10,%D2         |  Quotient is in lower 16 bits, remainder
    SWAP %D2
    MOVE.W %D2,%A1       |  Get remainder
    MOVE.B NUMTBL(%A1),-(%A0)
    CLR.W %D2
    SWAP %D2
    MOVE.L %D2,%D0       |  Put quotient back into D0
    bne 2f
    BTST #3,%D1
    beq 3f
2:
    dbf %D3,DEC.CVT
    bra 4f
3:
    SUBQ.B #1,%D3
4:
    |
    |  Check for adding negative sign
    |
    BTST #2,%D1
    beq DEC.OUT           |  Not signed
    BTST #4,%D1
    beq DEC.OUT           |  Not negative
    MOVE.B #'-',-(%A0)
    |
    |  Move to destination
    |
DEC.OUT:
    MOVE.L %A0,%D2       |  Pointer to start of string
    MOVE.L %A0,%A1
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    MOVE.L %A0,%D3
    SUB.L %D2,%D3        |  Length of converted string
    MOVE.L 12(%A6),%A0   |  Address of destination
    MOVE.W (%A0),%D2     |  Max size of destination
    CMP.W %D3,%D2
    bge 2f
    MOVE.W %D2,%D3
2:
    MOVE.W %D3, 2(%A0)   |  Set length of destination
    SUBQ.L #1,%D3
    ADDQ.L #4,%A0        |  Point to start of text part of string
3:
    MOVE.B (%A1)+,(%A0)+
    dbf %D3,3b
    |
    |  Cleanup and return
    |
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A1
    UNLK %A6
    RTS
|
|  Convert a number to an hexidecimal string
|
    .sbttl HEXSTR - Convert number to a string of hexidecimal digits
HEXSTR:
    LINK %A6,#-20
    MOVEM.L %D0-%D3/%A0-%A1,-(%SP)
    MOVE.L 8(%A6),%D0    |  Number to convert
    MOVE.W 16(%A6),%D1   |  Conversion flags
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
    MOVE.L %D1,%D2       |  Get size field
    AND.B #3,%D2
    bne 1f
    AND.L #0xFF,%D0      |  Byte size
    MOVE #2,%D3          |  Number of characters
    BTST #2,%D1          |  Check if signed
    beq 3f
    TST.B %D0            |  Check if positive or negative
    bpl 3f
    BSET #4,%D1          |  Set flag for negative
    NEG.B %D0
    bra 3f
1:
    SUBQ.B #1,%D2
    bne 2f
    AND.L #0xFFFF,%D0   |  Word size
    MOVE #4,%D3
    BTST #2,%D1         |  Check if signed
    beq 3f
    TST.W %D0           |  Check if positive or negative
    bpl 3f
    BSET #4,%D1         |  Set flag for negative
    NEG.W %D0
    bra 3f
2:
    MOVE #8,%D3         |  Long size
    BTST #2,%D1         |  Check if signed
    beq 3f
    TST.L %D0           |  Check if positive or negative
    bpl 3f
    BSET #4,%D1         |  Set flag for negative
    NEG.L %D0
3:
    |
    |  Conversion loop
    |
HEX.CVT:
    MOVE.L %D0,%D2
    AND.L #15,%D2
    MOVE.L %D2,%A1
    MOVE.B NUMTBL(%A1),-(%A0)
    LSR.L #4,%D0
    bne 2f
    BTST #3,%D1
    beq 3f
2:
    dbf %D3,HEX.CVT
    bra 4f
3:
    SUBQ.B #1,%D3
4:
    |
    |  Check for adding negative sign
    |
    BTST #2,%D1
    beq HEX.OUT           |  Not signed
    BTST #4,%D1
    beq HEX.OUT           |  Not negative
    MOVE.B #'-',-(%A0)
    |
    |  Move to destination
    |
HEX.OUT:
    MOVE.L %A0,%D2       |  Pointer to start of string
    MOVE.L %A0,%A1
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    MOVE.L %A0,%D3
    SUB.L %D2,%D3        |  Length of converted string
    MOVE.L 12(%A6),%A0   |  Address of destination
    MOVE.W (%A0),%D2     |  Max size of destination
    CMP.W %D3,%D2
    bge 2f
    MOVE.W %D2,%D3
2:
    MOVE.W %D3, 2(%A0)   |  Set length of destination
    SUBQ.L #1,%D3
    ADDQ.L #4,%A0        |  Point to start of text part of string
3:
    MOVE.B (%A1)+,(%A0)+
    dbf %D3,3b
    |
    |  Cleanup and return
    |
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A1
    UNLK %A6
    RTS
|
|------------------------------------------------------------------------------
|  Convert a long to BCD using the double dabble algorithm, see
|  https://en.wikipedia.org/wiki/Double_dabble
|  This is mainly intended to be used for converting longs to decimal
|  strings, but may have other uses.  It would not be needed for 68k
|  family members that have a full 32 bit divider.
|
|
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
|  JSR strxxx
|  move.l (%SP)+, num
|
|  Octal conversion
|
    .sbttl STROCT - Convert a string of octal digits to a number
STROCT:
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
      neg %D0
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
      neg %D0
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
      neg %D0
3:
    move.l %D0,8(%A6)
    movem.l (%SP)+,%D0-%D3/%A0
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Other string operations
|
|  Find character in string.  This searches a string for a specified
|  character.  If found, the location of the character is returned.  If
|  not found, an invalid location (> 0xFFFF) is returned.  The character
|  is passed in as a long to give space for the location to be returned.
|  Calling sequence:
|  move.l string,-(%SP)
|  move.l char,-(%SP)
|  jsr FIND_CHRSTR
|  move.l (%SP)+,location
|  addq.l #4,%SP
|
    .sbttl FIND_CHRSTR - Finds a character in a string
FIND_CHRSTR:
    link %A6,#0
    movem.l %D0-%D2/%A0-%A1,-(%SP)
    clr.l %D2              |  Position counter
    move.l 8(%A6),%D0      |  Character
    move.l 12(%A6),%A0     |  String
    clr.l %D1
    move.w 2(%A0),%D1      |  Get string size
    addq.l #4,%A0          |  Point to buffer to search
0:
    cmp.b (%A0)+,%D0
    beq 1f
    addq.l #1,%D2
    dbf %D1,0b
    move.l #0x10000,%D2
1:
    move.l %D2,8(%A6)
    movem.l (%SP)+,%D0-%D2/%A0-%A1
    unlk %A6
    rts
|
|  Convert a character to a string.  It is called with a character and
|  the address of the string on the stack.  It is assumed that the string
|  has a maximum length greater than zero.  The result is a string of
|  length one containing the character.  Previous contents of the string
|  are lost.
|  Calling sequence:
|  move.l string,-(%SP)
|  move.w char,-(%SP)
|  jsr CHR_STR
|  addq.l %6,%SP
|
    .sbttl CHR_STR - Convert a character to a string
CHR_STR:
    link %A6,#0
    movem.l %D0/%A0,-(%SP)
    move.w 8(%A6),%D0
    move.l 10(%A6),%A0
    move.w #1,2(%A0)
    move.b %D0,4(%A0)
    movem.l (%SP)+,%D0/%A0
    unlk %A6
    rts
|------------------------------------------------------------------------------
|  I/O operations
|
|
|  Get a string from the console.  This is the bounded string data structure.
|  The string is terminated by the structure begin full or a CR or LF entered
|  on the console.
|  Input: 4(%SP) contains the base address of the string structure.
|  Other registers used:
|     D0  Contains received character
|     D1  Max length of string (count down)
|     D2  Max length of string (fixed)
|     D3  Size of string
|     A0  Address of string
|     A1  Saved address of string
|
    .sbttl GETSTR - Gets a string from the console
GETSTR:
    .global GETSTR
    link %A6,#0
    movem.l %D0-%D3/%A0-%A1,-(%SP)
    move.l 8(%A6),%A0   |  Get address of string structure
    move.l %A0,%A1      |  Also save it in A1
    clr.l %D1
    clr.l %D3
    move.w (%A1),%D1    |  Maximum size of string
    move.l %D1,%D2
    addq.l #4,%A0       |  Point to buffer
0:
    move.w #SYS_GETC,-(%SP)
    trap #0             |  System call to get character
    move.w (%SP)+,%D0   |  Get the returned character
    cmp.b #CR,%D0       |  Check for carriage return
    beq 3f
    cmp.b #LF,%D0       |  Check for linefeed
    beq 3f
    cmp.b #BS,%D0       |  Check for backspace
    beq 1f
    cmp.b #DEL,%D0      |  Check for delete
    beq 1f
    move.b %D0,(%A0)+
    PUTC %D0            |  Echo the character
    addq.l #1,%D3
    dbf %D1,0b
1:                      |  Handle backspace/delete
    cmp.w %D1,%D2
    beq 2f              |  Check if string is empty
    subq.l #1,%A0       |  Move pointer back
    addq.l #1,%D1       |  Move counter up
    subq.l #1,%D3       |  Move size back
    PUTC #BS            |  Update display
    PUTC #SPACE
    PUTC #BS
    bra 0b
2:
    PUTC #BELL
    bra 0b
3:
    PUTC #CR
    PUTC #LF
    move.w %D3,2(%A1)   |  Set received size of string
    movem.l (%SP)+,%D0-%D3/%A0-%A1
    unlk %A6
    rts

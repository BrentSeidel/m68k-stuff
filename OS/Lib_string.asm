|------------------------------------------------------------------------------
| Title      : Library String Routines
| Written by : Brent Seidel
| Date       : 4-Feb-2024
| Description: Common library routines for string operations
|------------------------------------------------------------------------------
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
|==============================================================================
|  Library section.  Common routines go here.
|
    .section LIB_SECT,#execinstr,#alloc
|
|------------------------------------------------------------------------------
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
    .global FIND_CHRSTR
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
|------------------------------------------------------------------------------
|  Convert a character to a string.  It is called with a character and
|  the address of the string on the stack.  It is assumed that the string
|  has a maximum length greater than zero.  The result is a string of
|  length one containing the character.  Previous contents of the string
|  are lost.
|  Calling sequence:
|  move.l string,-(%SP)
|  move.w char,-(%SP)
|  jsr CHR_STR
|  addq.l #6,%SP
|
    .sbttl CHR_STR - Convert a character to a string
CHR_STR:
    .global CHR_STR
    link %A6,#0
    movem.l %D0/%A0,-(%SP)
    move.w 8(%A6),%D0
    move.l 10(%A6),%A0
    move.w #1,2(%A0)
    move.b %D0,4(%A0)
    movem.l (%SP)+,%D0/%A0
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Fills a string with a specified number of characters.  It is called
|  with a string, character, and the number of times to include the
|  character.  If the number of characters specified is greater than the
|  maximum size of the string, that will be used instead.
|  Calling sequence:
|  move.l string,-(%SP)
|  move.w count,-(%SP)
|  move.w char,-(%SP)
|  jsr FILL_CHR
|  addq.l #8,%SP
|
    .sbttl FILL_CHR - Returns a string of repeating characters
FILL_CHR:
    .global FILL_CHR
    link %A6,#0
    movem.l %D0-%D1/%A0,-(%SP)
    move.w 8(%A6),%D0       |  Character
    move.w 10(%A6),%D1      |  Count of characters
    move.l 12(%A6),%A0      |  Address of string
    tst.w %D1               |  Check for count of 0
    bne 3f
    clr.w 2(%A0)            |  If so, set string to empty
    bra 2f
3:
    cmp.w (%A0),%D1         |  Compare count with max size
    blt 0f
    move.w (%A0),%D1
0:
    move.w %D1,2(%A0)
    addq.l #4,%A0           |  Point to string buffer
    subq.w #1,%D1           |  Adjust count
1:
    move.b %D0,(%A0)+
    dbf %D1,1b
2:
    movem.l (%SP)+,%D0-%D1/%A0
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Return the character at a specific location in a string.  If the location
|  is greater than the string length, a out of range character is returned.
|  Calling sequence:
|  move.l string,-(%SP)
|  move.w position,-(%SP)
|  jsr STR_CHAR
|  move.w (%SP)+,character
|  addq.l #4,%SP
|
    .sbttl STR_CHAR - Returns a specified character from a string
STR_CHAR:
    .global STR_CHAR
    link %A6,#0
    movem.l %D1/%A0,-(%SP)
    clr.l %D1
    move.w 8(%A6),%D1       |  Character position
    move.l 10(%A6),%A0      |  Address of string
    addq.l #2,%A0           |  Point to string length
    cmp.w (%A0),%D1
    blt 0f
    move.w #0x100,8(%A6)
    bra 1f
0:
    addq.l #2,%A0           |  Point to start of buffer
    add.l %D1,%A0           |  Point to character
    move.b (%A0),%D1
    and.l #0xFF,%D1
    move.w %D1,8(%A6)
1:
    movem.l (%SP)+,%D1/%A0
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Trim any trailing whitespace from a string.  Whitespace is considered
|  to be any character less than 33 or greater than 126.  It is called
|  with a string and the string is modified in place.
|  Calling sequence:
|  move.l string,-(%SP)
|  jsr TRIM_TS
|  addq.l #4,%SP
|
    .sbttl TRIM_TS - Trim trailing whitespace from a string
TRIM_TS:
    .global TRIM_TS
    link %A6,#0
    movem.l %D0-%D1/%A1,-(%SP)
    move.l 8(%A6),%A0
    clr.l %D0
    move.w 2(%A0),%D0       |  Get string length
    beq 0f                  |  Do nothing for zero length
    addq.l #4,%A0           |  Point to start of string buffer
    add.l %D0,%A0           |  Point to end of string buffer
1:
    move.b -(%A0),%D1       |  Get character
    cmp.b #33,%D1
    blt 2f
    cmp.b #127,%D1
    blt 0f
2:
    dbf %D0,1b
0:
    move.l 8(%A6),%A0
    move.w %D0,2(%A0)
    movem.l (%SP)+,%D0-%D1/%A0
    unlk %A6
    rts
|
|  Trim any trailing zeros from a string.  This is similar to TRIM_LS.
|  It is called with a string and the string is modified in place.
|  Calling sequence:
|  move.l string,-(%SP)
|  jsr TRIM_TZ
|  addq.l #4,%SP
|
    .sbttl TRIM_TZ - Trim trailing zeros from a string
TRIM_TZ:
    .global TRIM_TZ
    link %A6,#0
    movem.l %D0-%D1/%A1,-(%SP)
    move.l 8(%A6),%A0       |  Address of string
    clr.l %D0
    move.w 2(%A0),%D0       |  Get string length
    beq 0f                  |  Do nothing for zero length
    addq.l #4,%A0           |  Point to start of string buffer
    add.l %D0,%A0           |  Point to end of string buffer
1:
    move.b -(%A0),%D1       |  Get character
    cmpb #'0',%D1
    bne 0f
    dbf %D0,1b
0:
    move.l 8(%A6),%A0
    move.w %D0,2(%A0)
    movem.l (%SP)+,%D0-%D1/%A0
    unlk %A6
    rts
|
|  Modifies the passed string to remove any whitespace at the beginning
|  of the string.  Similar to TRIMTS
|  Calling sequence:
|  move.l string,-(%SP)
|  jsr TRIM_LS
|  addq.l #4,%SP
|
   .sbttl TRIM_LS - Trim leading whitespace from a string
TRIM_LS:
    .global TRIM_LS
    link %A6,#0
    movem.l %D0-%D1/%A0-%A1,-(%SP)
    move.l 8(%A6),%A0       |  Address of string
    move.l %A0,%A1          |  Copy string address
    clr.l %D0
    move.w 2(%A0),%D0       |  Get string length
    beq 0f                  |  Do nothing if zero length
    addq.l #4,%A0           |  Point to start of string buffer
1:
    move.b (%A0)+,%D1       |  Get character to test
    cmp.b #33,%D1
    blt 2f
    cmp.b #127,%D1
    blt 3f
2:
    dbf %D0,1b
    move.w #0,2(%A1)        |  If no characters found, string length is zero.
    bne 0f
3:
    subq.l #1,%A0           |  Move back to point to the new first character
    move.w %D0,2(%A1)       |  Save updated length
    addq.l #4,%A1           |  Point to start of string buffer
4:
    move.b (%A0)+,(%A1)+    |  Shift characters to start
    dbf %D0,4b
0:
    movem.l (%SP)+,%D0-%D1/%A0-%A1
    unlk %A6
    rts
|
|  Modifies the passed string to remove any zeros at the beginning
|  of the string.  Similar to TRIMTS
|  Calling sequence:
|  move.l string,-(%SP)
|  jsr TRIM_LZ
|  addq.l #4,%SP
|
   .sbttl TRIM_LZ - Trim leading zeros from a string
TRIM_LZ:
    .global TRIM_LZ
    link %A6,#0
    movem.l %D0-%D1/%A0-%A1,-(%SP)
    move.l 8(%A6),%A0       |  Address of string
    move.l %A0,%A1          |  Copy string address
    clr.l %D0
    move.w 2(%A0),%D0       |  Get string length
    beq 0f                  |  Do nothing if zero length
    addq.l #4,%A0           |  Point to start of string buffer
1:
    move.b (%A0)+,%D1       |  Get character to test
    cmpb #'0',%D1
    bne 3f
    dbf %D0,1b
    move.w #0,2(%A1)        |  If no characters found, string length is zero.
    bne 0f
3:
    subq.l #1,%A0           |  Move back to point to the new first character
    move.w %D0,2(%A1)       |  Save updated length
    addq.l #4,%A1           |  Point to start of string buffer
4:
    move.b (%A0)+,(%A1)+    |  Shift characters to start
    dbf %D0,4b
0:
    movem.l (%SP)+,%D0-%D1/%A0-%A1
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Converts a string to upper case in place.
|  Calling sequence:
|  move.l string,-(%SP)
|  jsr STR_UPCASE
|  addq #x,%SP
|
    .sbttl STR_UPCASE - Convert a string to upper case in place
STR_UPCASE:
    .global STR_UPCASE
    link %A6,#0
    movem.l %D0-%D1/%A0,-(%SP)
    move.l 8(%A6),%A0       |  Get address of string
    move.w 2(%A0),%D1       |  Length of string
    addq.l #4,%A0           |  Move to start of string buffer.
0:
    move.b (%A0),%D0
    cmp.b #'a',%D0
    blt 1f
    cmp.b #'z',%D0
    bgt 1f
    sub.b #'a'-'A',%D0
    move.b %D0,(%A0)
1:
    addq.l #1,%A0
    dbf %D1,0b
    movem.l (%SP)+,%D0-%D1/%A0
    unlk %A6
    rts
|
|  Converts a string to lower case in place.
|  Calling sequence:
|  move.l string,-(%SP)
|  jsr STR_LOCASE
|  addq #x,%SP
|
    .sbttl STR_LOCASE - Convert a string to lower case in place
STR_LOCASE:
    .global STR_LOCASE
    link %A6,#0
    movem.l %D0-%D1/%A0,-(%SP)
    move.l 8(%A6),%A0       |  Get address of string
    move.w 2(%A0),%D1       |  Length of string
    addq.l #4,%A0           |  Move to start of string buffer.
0:
    move.b (%A0),%D0
    cmp.b #'A',%D0
    blt 1f
    cmp.b #'Z',%D0
    bgt 1f
    add.b #'a'-'A',%D0
    move.b %D0,(%A0)
1:
    addq.l #1,%A0
    dbf %D1,0b
    movem.l (%SP)+,%D0-%D1/%A0
    unlk %A6
    rts

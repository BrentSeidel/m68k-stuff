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
|
|------------------------------------------------------------------------------
|  Copy one string to another.  If the destination is not long enough,
|  the string is truncated.  Any old contents in the destination are
|  overwritten.
|  Calling sequence:
|  move.l source,-(%SP)
|  move.l destination,-(%SP)
|  jsr STR_COPY
|  addq.l #8,%SP
|
    .sbttl STR_COPY - Copy one string to another.
STR_COPY:
    .global STR_COPY
    link %A6,#0
    movem.l %D0/%A0-%A1,-(%SP)
    move.l 8(%A6),%A1       |  Destination string
    move.l 12(%A6),%A0      |  Source address
    move.w 2(%A0),%D0       |  Source length
    cmp.w (%A1),%D0         |  Compare with destination size
    blt 0f
    move.w (%A1),%D0        |  Use whichever is smaller
0:
    move.w %D0,2(%A1)       |  Set destination size
    addq.l #4,%A0           |  Point to string buffers
    addq.l #4,%A1
1:
    move.b (%A0)+,(%A1)+    |  Copy the string
    dbf %D0,1b
    movem.l (%SP)+,%D0/%A0-%A1
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Appends the source string to the destination string.  The result is
|  truncated to the maximum length of the destination, if needed.
|  Calling sequence:
|  move.l source,-(%SP)
|  move.l destination,-(%SP)
|  jsr STR_APPEND
|  addq.l #8,%SP
|
    .sbttl STR_APPEND - Append one string to another
STR_APPEND:
    .global STR_APPEND
    link %A6,#0
    movem.l %D0-%D2/%A0-%A1,-(%SP)
    clr.l %D0
    clr.l %D1
    clr.l %D2
    move.l 8(%A6),%A1       |  Destination string
    move.l 12(%A6),%A0      |  Source string
    move.w 2(%A0),%D0       |  Get source length
    beq 0f                  |  Exit if zero
    move.w (%A1),%D1        |  Max size of destination
    move.w 2(%A1),%D2       |  Length of destination
    sub.w %D2,%D1           |  Bytes remaining in destination
    beq 0f                  |  Exit if none remaining
    cmp.w %D0,%D1           |  Adjust length, if needed
    bge 1f
    move.w %D1,%D0
1:
    move.w %D2,%D1
    add.w %D0,%D1           |  Final length
    move.w %D1,2(%A1)       |  Set final length
    addq.l #4,%A0           |  Point to start of source buffer
    addq.l #4,%A1           |  Point to start of destintation buffer
    add.l %D2,%A1           |  Point to end of destination buffer
2:
    move.b (%A0)+,(%A1)+
    dbf %D0,2b
0:
    movem.l (%SP)+,%D0-%D2/%A0-%A1
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  This routine extracts a substring from one string and copies it to
|  another string.  It is called with four parameters, the source and
|  destination string, the starting character, and the number of
|  characters to copy.  If the starting character is beyond the end of
|  the source string, no characters will be copied.  If the last character
|  (start plus count) is beyond the end of the source, copying will only
|  happen to the end.  If the destination string is smaller than the amount
|  to be copied, it will be truncated to the size of the destination.
|  Calling sequence:
|  move.l source,-(%SP)
|  move.l dest,-(%SP)
|  move.w start,-(%SP)
|  move.w count,-(%SP)
|  jsr SUB_STR
|  addq.l #6,%SP
|  addq.l #6,%SP
|
    .sbttl STR_SUBSTR - Generalized substring routine
STR_SUBSTR:
    .global STR_SUBSTR
    link %A6,#0
    movem.l %D0-%D2/%A0-%A1,-(%SP)
    clr.l %D0
    clr.l %D1
    clr.l %D2
    move.w 8(%A6),%D0       |  Count of bytes
    beq 0f                  |  If no bytes to transfer, do nothing
    move.w 10(%A6),%D1      |  Starting location
    move.l 12(%A6),%A0      |  Destination string
    move.l 16(%A6),%A1      |  Source string
    move.w 2(%A1),%D2
    cmp.w %D1,%D2           |  Compare starting location with length
    blt 0f                  |  If start after length, do nothing
    sub.w %D1,%D2           |  How many bytes in string after start
    cmp.w %D0,%D2           |  Is length greater than remainder
    bge 1f
    move.w %D2,%D0          |  Reduce count, if necessary
1:
    move.w (%A0),%D2        |  Get destination max size
    cmp.w %D0,%D2           |  Compare count with destination length
    bge 2f
    move.w %D2,%D0          |  Reduce count, if necessary
2:
    move.w %D0,2(%A0)       |  Set size of destination string
    addq.l #4,%A0           |  Point to start of source buffer
    addq.l #4,%A1           |  Point to start of destination buffer
    add.l %D1,%A1           |  Point to start of substring
3:
    move.b (%A1)+,(%A0)+
    dbf %D0,3b
0:
    movem.l (%SP)+,%D0-%D2/%A0-%A1
    unlk %A6
    rts
|
|------------------------------------------------------------------------------
|  Compare if two string are equal.  The result is returned on the stack,
|  where 0 indicates equality and 1 difference.  Different lengths of
|  strings are not equal.  At some point, this may be extended to test
|  ordering of the strings.
|  Calling sequence:
|  move.l str1,-(%SP)
|  move.l str2,-(%SP)
|  jsr STR_EQ
|  addq.l #6,%SP
|  tst.w (%SP)+
    .sbttl STR_EQ - Tests if two string are equal or not
STR_EQ:
    .global STR_EQ
    link %A6,#0
    movem.l %D0/%A0-%A1,-(%SP)
    move.l 8(%A6),%A0       |  String 2
    move.l 12(%A6),%A1      |  String 1
    clr.l %D0
    move.w 2(%A0),%D0       |  Length of string 2
    cmp.w 2(%A1),%D0        |  Compare the length
    bne 2f
    addq.l #4,%A0
    addq.l #4,%A1
    subq.w #1,%D0           |  Adjust count for loop
0:
    cmp.b (%A0)+,(%A1)+
    bne 2f
    dbf %D0,0b
1:
    clr.w 14(%A6)           |  Equal
    bra 3f
2:
    move.w #1,14(%A6)       |  Not equal
3:
    movem.l (%SP)+,%D0/%A0-%A1
    unlk %A6
    rts


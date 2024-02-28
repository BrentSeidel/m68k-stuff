|------------------------------------------------------------------------------
| Title      : Library Routines
| Written by : Brent Seidel
| Date       : 4-Feb-2024
| Description: Common library routines for OS and users
|------------------------------------------------------------------------------
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
    .global NUMTBL
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
    .long FILL_CHR
    .long STR_CHAR
    .long TRIM_TS
    .long TRIM_TZ
    .long TRIM_LS
    .long TRIM_LZ
    .long STR_UPCASE
    .long STR_LOCASE
    .long STR_COPY
    .long STR_APPEND
    .long STR_SUBSTR
    .long STR_EQ
|
|  Error message to catch some jump table errors
|
LIBERR:
    PRINT #LIBMSG
    RTS
|
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

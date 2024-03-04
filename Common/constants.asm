|
|  Common constants for both OS and user tasks
|
.nolist
|
|
|  Constants for ASCII characters
|
    .equ BELL,   7      |  Ring the bell
    .equ BS,     8      |  Back space
    .equ TAB,    9      |  Horizontal tab
    .equ LF,    10      |  Line feed
    .equ CR,    13      |  Carriage return
    .equ ESC,   27      |  Escape
    .equ SPACE, 32      |  Space
    .equ LT,    60      |  Less than '<'
    .equ GT,    62      |  Greater than '>'
    .equ DEL,  127      |  Delete
|
|  Codes for system calls
|    0 - Exit.  Exits the program and does not return
|    1 - Put string.  Prints the string referenced in the argument
|    2 - Get string.  Gets text to the string referenced in the argument
|   16 - Sleep for the number of clock ticks in the argument
|   64 - Shutdown
|
    .equ SYS_EXIT,      0 |  End the current task
    .equ SYS_PUTS,      1 |  Send a string to the console
    .equ SYS_GETC,      2 |  Get a character from the console
    .equ SYS_PUTC,      3 |  Send a character to the console
    .equ SYS_SLEEP,    16 |  Suspend current task for a number of clock ticks
    .equ SYS_SUTDOWN,  64 |  Shutdown the system
|
|  Library entry point
|
    .equ LIBTBL,0x5000
|
|  Library jump table offsets
|
    .equ LIB_OCTSTR,   1*4
    .equ LIB_DECSTR,   2*4
    .equ LIB_HEXSTR,   3*4
    .equ LIB_STROCT,   4*4
    .equ LIB_STRDEC,   5*4
    .equ LIB_STRHEX,   6*4
    .equ LIB_GETSTR,   7*4
    .equ LIB_FINDCHR,  8*4
    .equ LIB_CHRSTR,   9*4
    .equ LIB_LONGBCD, 10*4
    .equ LIB_FILLCHR, 11*4
    .equ LIB_CHARAT,  12*4
    .equ LIB_TRIMTS,  13*4
    .equ LIB_TRIMTZ,  14*4
    .equ LIB_TRIMLS,  15*4
    .equ LIB_TRIMLZ,  16*4
    .equ LIB_UPCASE,  17*4
    .equ LIB_LOCASE,  18*4
    .equ LIB_STRCP,   19*4
    .equ LIB_STRAPP,  20*4
    .equ LIB_SUBSTR,  21*4
    .equ LIB_STREQ,   22*4
.list


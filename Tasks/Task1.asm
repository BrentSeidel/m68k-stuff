|-----------------------------------------------------------
| Title      : Task 1
| Written by : Brent Seidel
| Date       : 8-Feb-2024
| Description: Module for task #1
|-----------------------------------------------------------
    .title Example Task 1
    .include "../Common/Constants.asm"
    .include "../Common/Macros.asm"
|
    .section CODE_SECT,#execinstr,#alloc
|
START:                  |  first instruction of program
   .global START
|
|  Test octal conversion
|
    move.l #NUMBER,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_STROCT(%A0),%A0
    jsr (%A0)
    move.l (%SP)+,%D0
|
|  Test hexidecimal conversion
|
    move.l #NUMBER,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_STRHEX(%A0),%A0
    jsr (%A0)
    move.l (%SP)+,%D0
|
|  Test decimal conversion
|
    move.l #NUMBER,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_STRDEC(%A0),%A0
    jsr (%A0)
    move.l (%SP)+,%D0
|
|  Print some messages
|
    PRINT #MSG1
    NUMSTR_B #255,#INSTR,#0,10
    PRINT #CVT1
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #20
|
    NUMSTR_W #60000,#INSTR,#4,10
    PRINT #CVT2
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #20
|
    NUMSTR_L #1000000,#INSTR,#8,16
    PRINT #CVT3
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #20
|
    PRINT #MSG2
    PRINT #TXT1
    SLEEP #2
|
|  Print a prompt and get some text
|
    PRINT #PROMPT
    INPUT #INSTR
    PRINT #NEWLINE
|
|  Echo it back out
|
    PRINT #INSTR
    PRINT #NEWLINE
|
|  Exit the program
|
    MOVE.W #SYS_EXIT,-(%SP)    |  Exit function code
    TRAP #0
    BRA .               |  If exit doesn't work, wait in an infinite loop
|==============================================================================
|  Data section for main code
|
    .section DATA_SECT,#write,#alloc

    STRING INSTR,0x100
    TEXT PROMPT,"> "
    TEXT MSG1,"68000 Assembly language test program.\r\n"
    TEXT MSG2,"Simulated 68000 written in Ada\r\n"
    TEXT TXT1,"Enter some text at the prompt below:\r\n"
    TEXT CVT1,"255 in decimal is "
    TEXT CVT2,"60000 in signed decimal is "
    TEXT CVT3,"1000000 in hexidecimal is "
    TEXT STAK,"Current SP is "
    TEXT NEWLINE,"\r\n"
    TEXT NUMBER,"1234567890ABCDEF"
    .end  START              |  last line of source


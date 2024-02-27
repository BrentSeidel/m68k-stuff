|------------------------------------------------------------------------------
| Title      : Task 1
| Written by : Brent Seidel
| Date       : 8-Feb-2024
| Description: Module for task #1
|------------------------------------------------------------------------------
    .title Example Task 1
    .include "../Common/Constants.asm"
    .include "../Common/Macros.asm"
|
    .section CODE_SECT,#execinstr,#alloc
|
START:                  |  first instruction of program
   .global START
|
|  Misc testing
|
    CHAR_AT #MSG1,#10,%D0
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
    NUMSTR_L #12345678,#INSTR,#8,10
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
    STR_COPY #MSG4,#STR1
    STR_APPEND #INSTR,#STR1
    STR_APPEND #CLOSE,#STR1
    PRINT #STR1
|
|  Trim the string
|
    STR_TRIM LS,#INSTR
    STR_TRIM LZ,#INSTR
    STR_TRIM TS,#INSTR
    STR_TRIM TZ,#INSTR
    STR_UPCASE #INSTR
    STR_LOCASE #INSTR
    PRINT #MSG5
    PRINT #INSTR
    PRINT #CLOSE
|
|  Find first space in string
|
    FINDCAHR #INSTR,#SPACE,%D0
|
    NUMSTR_W %D0,#INSTR,#0,10
    PRINT #MSG3
    PRINT #INSTR
    PRINT #NEWLINE
0:
    FILLCHAR #INSTR,%D0,#'*'
    PRINT #INSTR
    PRINT #NEWLINE
    dbf %D0,0b
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
    STRING STR1,0x100
    STRING STR2,0x100
    TEXT PROMPT,"> "
    TEXT MSG1,"68000 Assembly language test program.\r\n"
    TEXT MSG2,"Simulated 68000 written in Ada\r\n"
    TEXT TXT1,"Enter some text at the prompt below:\r\n"
    TEXT CVT1,"255 in decimal is "
    TEXT CVT2,"60000 in signed decimal is "
    TEXT CVT3,"12345678 in decimal is "
    TEXT MSG3,"First space is at character position "
    TEXT STAK,"Current SP is "
    TEXT MSG4,"Before trimming is <"
    TEXT MSG5,"After trimming is <"
    TEXT CLOSE,">\r\n"
    TEXT NEWLINE,"\r\n"
    TEXT NUMBER,"1234567890ABCDEF"
    .end  START              |  last line of source


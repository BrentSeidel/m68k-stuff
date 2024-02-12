#-----------------------------------------------------------
# Title      : Task 1
# Written by : Brent Seidel
# Date       : 8-Feb-2024
# Description: Module for task #1
#-----------------------------------------------------------
    .title Example Task 1
    .INCLUDE "../Common/Macros.asm"
#
#  Library entry points
#
    .EQU LIBTBL,0x4000
#
    .SECTION CODE_SECT,#execinstr,#alloc
#
TASK1:                  |  first instruction of program
   .global TASK1
#
#  Print some messages
#
    NUMSTR_B #255,#INSTR,#0,10
    PRINT #CVT1
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #2
#
    NUMSTR_W #60000,#INSTR,#4,10
    PRINT #CVT2
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #2
#
    NUMSTR_L #1000000,#INSTR,#8,16
    PRINT #CVT3
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #2
#
    PRINT #MSG1
    PRINT #MSG2
    PRINT #TXT1
    SLEEP #2
#
#  Print a prompt
#
    PRINT #PROMPT
#
#  Get some text
#
    INPUT #INSTR
    PRINT #NEWLINE
#
#  Echo it back out
#
    PRINT #INSTR
    PRINT #NEWLINE
#
#  Exit the program
#
    MOVE.W #0,-(SP)     |  Exit function code
    TRAP #0
    BRA .               |  If exit doesn't work, wait in an infinite loop
#==============================================================================
#  Data section for main code
#
    .SECTION DATA_SECT,#write,#alloc

    STRING INSTR,0x100
    TEXT PROMPT,"> "
    TEXT MSG1,"68000 Assembly language test program.\r\n"
    TEXT MSG2,"Simulated 68000 written in Ada\r\n"
    TEXT TXT1,"Enter some text at the prompt below:\r\n"
    TEXT CVT1,"255 in decimal is "
    TEXT CVT2,"60000 in signed decimal is "
    TEXT CVT3,"1000000 in hexidecimal is "
    TEXT NEWLINE,"\r\n"
    .global INSTR,PROMPT,MSG1,MSG2,TXT1,CVT1,CVT2,CVT3,NEWLINE
    .END                |  last line of source


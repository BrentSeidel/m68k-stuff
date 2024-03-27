|------------------------------------------------------------------------------
| Title      : Task 2
| Written by : Brent Seidel
| Date       : 2-Feb-2024
| Description: Module for task #2
|------------------------------------------------------------------------------
    .title Example Task 1
    .include "../Common/constants.asm"
    .INCLUDE "../Common/Macros.asm"
|
    .section CODE_SECT,#execinstr,#alloc
|
TASK2:                  |  first instruction of program
|
|  Print header message and initialize
|
    PRINT #MSG1
    CLR.L %D0
    MOVEQ.L #1,%D1
|
LOOP:
    ADD.L %D1,%D0
    NUMSTR_L %D0,#INSTR,#8,10
    PRINT #INSTR
    PRINT #NEWLINE
|
    ADD.L %D0,%D1
    NUMSTR_L %D1,#INSTR,#8,10
    PRINT #INSTR
    PRINT #NEWLINE
|
   JMP LOOP
|
|  Exit the program
|
    move.w #0,-(%SP)    |  Exit function code
    TRAP #0
    BRA .               |  If exit doesn't work, wait in an infinite loop
#==============================================================================
#  Data section for main code
#
    .section DATA_SECT,#write,#alloc

    STRING INSTR,0x100
    TEXT MSG1,"Computing Fibonacci Numbers\r\n"
    TEXT NEWLINE,"\r\n"
    .end                |  last line of source


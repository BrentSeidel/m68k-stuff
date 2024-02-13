|-----------------------------------------------------------
| Title      : Task 1
| Written by : Brent Seidel
| Date       : 8-Feb-2024
| Description: Module for task #1
|-----------------------------------------------------------
    .title Example Task 1
    .include "../Common/Macros.asm"
|
.macro putsp
    move.l %SP,%a2
    NUMSTR_L %A2,#INSTR,#8,16
    PRINT #STAK
    PRINT #INSTR
    PRINT #NEWLINE
.endm
|
    .section CODE_SECT,#execinstr,#alloc
|
START:                  |  first instruction of program
   .global START
|
|  Print some messages
|
|    putsp
    NUMSTR_B #255,#INSTR,#0,10
    PRINT #CVT1
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #20
|
|    putsp
    NUMSTR_W #60000,#INSTR,#4,10
    PRINT #CVT2
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #20
|
|    putsp  |  Stack is wrong here
    NUMSTR_L #1000000,#INSTR,#8,16
    PRINT #CVT3
    PRINT #INSTR
    PRINT #NEWLINE
    SLEEP #20
|
|    putsp
    PRINT #MSG1
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
|    putsp
|
|  Exit the program
|
    MOVE.W #SYS_EXIT,-(%SP)    |  Exit function code
    TRAP #0
|    putsp
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
    .end  START              |  last line of source


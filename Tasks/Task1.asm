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
|  Print header messages
|
    PRINT #MSG1
    PRINT #MSG2
|
|  Command processing loop
|
CLI_LOOP:
    PRINT #PROMPT
    INPUT #INSTR
    STR_TRIM LS,#INSTR
    STR_TRIM TS,#INSTR
    STR_LEN #INSTR,%D0
    tst.w %D0
    beq CLI_LOOP
    FINDCHAR #INSTR,#SPACE,%D0
    cmp.l #0x10000,%D0
    beq 1f
    STR_SUBSTR #INSTR,#STR1,#0,%D0
    bra 2f
1:
    STR_COPY #INSTR,#STR1
2:
    STR_UPCASE #STR1
    PRINT #MSG3
    PRINT #STR1
    PRINT #END_MSG
|
|  Check command
|
    STR_EQ #STR1,#CMD1
    beq SQUARE
    STR_EQ #STR1,#CMD2
    beq TRIANGLE
    STR_EQ #STR1,#CMD3
    beq EXIT_PROGRAM
|
    PRINT #ERR1              |  Command not recognized
    bra CLI_LOOP
|
SQUARE:
    PRINT #MSG5
    addq.w #1,%D0
    STR_LEN #INSTR,%D1
    STR_SUBSTR #INSTR,#STR2,%D0,%D1
    STR_TRIM LS,#STR2
    PRINT #MSG4
    PRINT #STR2
    PRINT #END_MSG
    STRNUM #STR2,%D0,10
    FILLCHAR #INSTR,%D0,#'*'
0:
    PRINT #INSTR
    PRINT #NEWLINE
    dbf %D0,0b
    bra CLI_LOOP
|
TRIANGLE:
    PRINT #MSG6
    addq.w #1,%D0
    STR_LEN #INSTR,%D1
    STR_SUBSTR #INSTR,#STR2,%D0,%D1
    STR_TRIM LS,#STR2
    PRINT #MSG4
    PRINT #STR2
    PRINT #END_MSG
    STRNUM #STR2,%D0,10
0:
    FILLCHAR #INSTR,%D0,#'*'
    PRINT #INSTR
    PRINT #NEWLINE
    dbf %D0,0b
    bra CLI_LOOP
|
EXIT_PROGRAM:
    PRINT #BYE
    move.w #SYS_SUTDOWN,-(%SP)
    trap #0
    bra .               |  If exit doesn't work, wait in an infinite loop
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
    TEXT MSG3,"Command given is <"
    TEXT MSG4,"Command arguments are <"
    TEXT MSG5,"Printing a square\r\n"
    TEXT MSG6,"Printing a triangle\r\n"
    TEXT END_MSG,">\r\n"
    TEXT ERR1,"Uncrecognized command.\r\n"
    TEXT CMD1,"SQR"
    TEXT CMD2,"TRI"
    TEXT CMD3,"END"
    TEXT BYE,"Good-bye!\r\n"
    .end  START              |  last line of source


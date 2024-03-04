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
    .equ INSTR,-0x108       |  Space for 0x100 byte string
    .equ STR1,INSTR-0x108   |  Space for 0x100 byte string
    .equ STR2,INSTR-0x108   |  Space for 0x100 byte string
    .equ FRAME_END,STR2     |  Stack frame size
|
START:
    .global START
    LINK %A6,#FRAME_END
|
|  Initialize stack variables
|
    lea INSTR(%A6),%A1       |  Address of stack allocated INSTR
    MAKE_STR %A1,#0x100
    lea STR1(%A6),%A2        |  Address of stack allocated STR1
    MAKE_STR %A2,#0x100
    lea STR2(%A6),%A3        |  Address of stack allocated STR2
    MAKE_STR %A3,#0x100
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
    INPUT %A1
    STR_TRIM LS,%A1
    STR_TRIM TS,%A1
    STR_LEN %A1,%D0
    tst.w %D0
    beq CLI_LOOP
    FINDCHAR %A1,#SPACE,%D0
    cmp.l #0x10000,%D0
    beq 1f
    STR_SUBSTR %A1,%A2,#0,%D0
    bra 2f
1:
    STR_COPY %A1,%A2
2:
    STR_UPCASE %A2
    PRINT #MSG3
    PRINT %A2
    PRINT #END_MSG
|
|  Check command
|
    STR_EQ %A2,#CMD1
    beq SQUARE
    STR_EQ %A2,#CMD2
    beq TRIANGLE
    STR_EQ %A2,#CMD3
    beq EXIT_PROGRAM
|
    PRINT #ERR1              |  Command not recognized
    bra CLI_LOOP
|
SQUARE:
    PRINT #MSG5
    addq.w #1,%D0
    STR_LEN %A1,%D1
    STR_SUBSTR %A1,%A3,%D0,%D1
    STR_TRIM LS,%A3
    PRINT #MSG4
    PRINT %A3
    PRINT #END_MSG
    STRNUM %A3,%D0,10
    FILLCHAR %A1,%D0,#'*'
0:
    PRINT %A1
    PRINT #NEWLINE
    dbf %D0,0b
    bra CLI_LOOP
|
TRIANGLE:
    PRINT #MSG6
    addq.w #1,%D0
    STR_LEN %A1,%D1
    STR_SUBSTR %A1,%A3,%D0,%D1
    STR_TRIM LS,%A3
    PRINT #MSG4
    PRINT %A3
    PRINT #END_MSG
    STRNUM %A3,%D0,10
0:
    FILLCHAR %A1,%D0,#'*'
    PRINT %A1
    PRINT #NEWLINE
    dbf %D0,0b
    bra CLI_LOOP
|
EXIT_PROGRAM:
    PRINT #BYE              |  Print closing message
    unlk %A6                |  Clean up stack
    rts                     |  Return to CLI
|    move.w #SYS_SUTDOWN,-(%SP)
|    trap #0
|    bra .               |  If exit doesn't work, wait in an infinite loop
|==============================================================================
|  Data section for main code
|
    .section DATA_SECT,#write,#alloc

|    STRING STR1,0x100
|    STRING STR2,0x100
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


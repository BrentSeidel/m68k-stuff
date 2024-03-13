|------------------------------------------------------------------------------
| Title      : Task 3
| Written by : Brent Seidel
| Date       : 6-Mar-2024
| Description: Module for task #3
|------------------------------------------------------------------------------
    .title Example Task 1
    .include "../Common/Constants.asm"
    .include "../Common/Macros.asm"
    .include "../OS/OS-Macros.asm"
|==============================================================================
|  Data section.
    .section CODE_SECT,#execinstr,#alloc
|
|  This is a bit of a hack until the O/S provides a way to get these values.
|
    .equ MAXTASK, 4
    .equ TASKTBL,0x31b8
    .equ CURRTASK,0x31b6
|
|  Start of program
|
START:
    LINK %A6,#0
|
|  Print header messages
|
LOOP:
    PRINT #HOME_CLEAR
    PRINT #MSG1

    PRINT #STAT0
    move.w #MAXTASK,%D0
    subq.w #1,%D0
    clr.l %D1
    clr.l %D2
0:
    NUMSTR_W %D1,#STR1,#0,10
    PRINT #STR1
    cmp.w CURRTASK,%D1
    bne 2f
    PRINT #STAT_CURR
    bra 1f
2:
    move.l %D2,%A5
    move.l TASKTBL(%A5),%A5
    tst.l TCB_STAT0(%A5)
    beq 3f
    bsr STAT_DECODE
    bra 1f
3:
    PRINT #STAT_READY
1:
    addq.l #1,%D1
    addq.l #4,%D2
    dbf %D0,0b
|
    PRINT #STR_NEWLINE
    SLEEP #10
    bra LOOP
|
|------------------------------------------------------------------------------
|  Decode status flags
|
STAT_DECODE:
    btst #TCB_FLG_IO,TCB_STAT0(%A5)
    beq 1f
    PRINT #STAT_IO_WAIT
    bra 0f
1:
    btst #TCB_FLG_SLEEP,TCB_STAT0(%A5)
    beq 2f
    PRINT #STAT_SLEEP
    move.l TCB_SLEEP(%A5),%D2
    NUMSTR_L %D2,#STR1,#0,10
    PRINT #STR1
    PRINT #NEWLINE
    bra 0f
2:
    btst #TCB_FLG_EXIT,TCB_STAT0(%A5)
    beq 3f
    PRINT #STAT_TERMINATE
    bra 0f
3:
    btst #TCB_FLG_CTRLC,TCB_STAT0(%A5)
    beq 4f
    PRINT #STAT_CTRLC
    bra 0f
4:
    PRINT #STAT_UNKNOWN
0:
    rts                     |  Return to main loop
|==============================================================================
|  Data section for main code
|
    .section DATA_SECT,#write,#alloc

    TEXT HOME_CLEAR,"\x1b[H\x1b[J"
    TEXT PROMPT,"> "
    TEXT MSG1,"O/S68K System Status\r\n"
    TEXT STAT0,"Task status:\r\n"
    TEXT STAT_READY,"  Ready\r\n"
    TEXT STAT_IO_WAIT,"  I/O Wait\r\n"
    TEXT STAT_SLEEP,"  Sleep  "
    TEXT STAT_TERMINATE,"  Task terminated\r\n"
    TEXT STAT_CTRLC, "  Ctrl-C\r\n"
    TEXT STAT_UNKNOWN,"  Unknown wait\r\n"
    TEXT STAT_CURR,"  Current\r\n"
    TEXT STR_NEWLINE,"\r\n"
    STRING STR1,0x100
    .end                    |  last line of source


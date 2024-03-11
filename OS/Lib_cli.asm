|------------------------------------------------------------------------------
| Title      : Common CLI
| Written by : Brent Seidel
| Date       : 1-Mar-2024
| Description: Common command line interpreter for the operating system
|------------------------------------------------------------------------------
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
    .include "OS-Macros.asm"
|==============================================================================
|  Data section.
|
    .section LIB_DATA,#alloc
    TEXT OS_HEADER,"OS68K early development version.\r\n"
    .global OS_HEADER
    TEXT PROMPT,"OS> "
    .global PROMPT
    TEXT ERR_COMMAND,"Unrecognized command <"
    TEXT ERR_NOSLEEP,"Sleep time not given.\r\n"
    TEXT MSG_END,">\r\n"
    TEXT STR_NEWLINE,"\r\n"
    TEXT CMD_START,"START"
    TEXT CMD_SHUTDOWN,"SHUTDOWN"
    TEXT CMD_STATUS,"STATUS"
    TEXT CMD_SLEEP,"SLEEP"
    TEXT CMD_SEND,"SEND"
    TEXT BYE,"System shutting down - Good-bye.\r\n"
    TEXT STAT0,"Task status:\r\n"
    TEXT STAT_READY,"  Ready\r\n"
    TEXT STAT_IO_WAIT,"  I/O Wait\r\n"
    TEXT STAT_SLEEP,"  Sleep  "
    TEXT STAT_TERMINATE,"  Task terminated\r\n"
    TEXT STAT_UNKNOWN,"  Unknown wait\r\n"
    TEXT STAT_CURR,"  Current\r\n"
    TEXT TICKS," ticks\r\n"
|
|  Code section.
|
    .section CLI_SECT,#execinstr,#alloc
CLI_ENTRY:
    .global CLI_ENTRY
|
|  Initialization, get the current task number and use it to determine
|  the initial SP.  Each task is allocated one megabyte of space.  The
|  task entry point is at the first address and the stack is initialized
|  to the last address (first address of the next task).
    clr.l %D0
    move.w CURRTASK,%D0
    beq TASK0               |  Task 0 shouldn't really use the CLI.
    addq.l #1,%D0
    move.w #20,%D1          |  Shift count 20 bits is one megabyte
    lsl.l %D1,%D0
    move.l %D0,%SP          |  Set the user stack pointer
|
|  Now that the stack is initialized, setup some stack space for strings.
|
    .equ INSTR,-0x108       |  Space for 0x100 byte string
    .equ VERB,INSTR-0x108   |  Space for 0x100 byte string
    .equ STR2,VERB-0x108    |  Space for 0x100 byte string
    .equ FRAME_END,STR2     |  Stack frame size
    link %A6,#FRAME_END
|
|  Initialize stack variables
|
    lea INSTR(%A6),%A1       |  Address of stack allocated INSTR
    MAKE_STR %A1,#0x100
    lea VERB(%A6),%A2        |  Address of stack allocated VERB
    MAKE_STR %A2,#0x100
    lea STR2(%A6),%A3        |  Address of stack allocated STR2
    MAKE_STR %A3,#0x100
|
|  Print out the header message
|
    PRINT #OS_HEADER
|
|  Command loop
|
CMD_LOOP:
    PRINT #PROMPT
    INPUT %A1
    STR_TRIM LS,%A1
    STR_TRIM TS,%A1
    STR_LEN %A1,%D0
    tst.w %D0
    beq CMD_LOOP            |  If empty input, do go back to the prompt
    FINDCHAR %A1,#SPACE,%D0
    cmp.l #0x10000,%D0
    beq 1f
    STR_SUBSTR %A1,%A2,#0,%D0
    bra 2f
1:
    STR_COPY %A1,%A2
2:
    STR_UPCASE %A2
|
|  Check commands
|
    STR_EQ %A2,#CMD_START
    beq START_COMMAND
    STR_EQ %A2,#CMD_SHUTDOWN
    beq SHUTDOWN_COMMAND
    STR_EQ %A2,#CMD_STATUS
    beq STATUS_COMMAND
    STR_EQ %A2,#CMD_SLEEP
    beq SLEEP_COMMAND
    STR_EQ %A2,#CMD_SEND
    beq SEND_COMMAND
|
|  Command not found
|
    PRINT #ERR_COMMAND
    PRINT %A2
    PRINT #MSG_END
    bra CMD_LOOP
|
|  Special processing for task 0.  Clear stack and jump to the null task
|
TASK0:
    unlk %A6
    jmp NULLTASK
|
|  Process commands
|
|  Start task program
|
START_COMMAND:              |  Determine entry point for the current task
    clr.l %D0
    move.w CURRTASK,%D0
    move.w #20,%D1
    lsl.l %D1,%D0
    move.l #CMD_LOOP,-(%SP) |  Save so that a RTS can go back to the command loop
    move.l %D0,%A0
    jmp (%A0)               |  Jump to task entry point
|
|  Shutdown the system
|
SHUTDOWN_COMMAND:
    PRINT #BYE
    move.w #SYS_SUTDOWN,-(%SP)
    trap #0
    bra .               |  If exit doesn't work, wait in an infinite loop
|
|  Display some status information
|
STATUS_COMMAND:
    PRINT #STAT0
    move.w #MAXTASK,%D0
    subq.w #1,%D0
    clr.l %D1
    clr.l %D2
0:
    NUMSTR_W %D1,%A3,#0,10
    PRINT %A3
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
    PRINT #STR_NEWLINE
    bra CMD_LOOP

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
    NUMSTR_L %D2,%A3,#0,10
    PRINT %A3
    PRINT #NEWLINE
    bra 0f
2:
    btst #TCB_FLG_EXIT,TCB_STAT0(%A5)
    beq 3f
    PRINT #STAT_TERMINATE
    bra 0f
3:
    PRINT #STAT_UNKNOWN
0:
    rts
|
|  Sleep for a specified number of ticks
|
SLEEP_COMMAND:
    FINDCHAR %A1,#SPACE,%D0
    cmp.l #0x10000,%D0
    beq 1f
    STR_LEN %A1,%D1
    STR_SUBSTR %A1,%A3,%D0,%D1
    STR_TRIM LS,%A3
    STRNUM %A3,%D0,10
    SLEEP %D0
    bra 0f
1:
    PRINT #ERR_NOSLEEP
0:
    bra CMD_LOOP
|
|  Send a message to all terminal interfaces.  Used for test purposes.
|
SEND_COMMAND:
    FINDCHAR %A1,#SPACE,%D0
    cmp.l #0x10000,%D0
    beq 1f
    STR_LEN %A1,%D1
    STR_SUBSTR %A1,%A3,%D0,%D1
    STR_TRIM LS,%A3
    move.l #TTYTBL,%A2
    move.w TTYCNT,%D0
    subq.w #1,%D0
    move.l %A3,%A0
0:
    move.l (%A2)+,%A1
    move.l #NEWLINE,%A0
    bsr WRITESTR
    move.l %A3,%A0
    bsr WRITESTR
    move.l #NEWLINE,%A0
    bsr WRITESTR
    dbf %D0,0b
1:
    bra CMD_LOOP

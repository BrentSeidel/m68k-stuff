|------------------------------------------------------------------------------
| Title      : Common CLI
| Written by : Brent Seidel
| Date       : 1-Mar-2024
| Description: Common command line interpreter for the operating system
|------------------------------------------------------------------------------
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
|==============================================================================
|  Data section.
|
    .section LIB_DATA,#alloc
    TEXT OS_HEADER,"OS68K early development version.\r\n"
    .global OS_HEADER
    TEXT PROMPT,"OS> "
    .global PROMPT
    TEXT ERR_COMMAND,"Unrecognized command <"
    TEXT MSG_END,">\r\n"
    TEXT CMD_START,"START"
    TEXT CMD_SHUTDOWN,"SHUTDOWN"
    TEXT CMD_STATUS,"STATUS"
    TEXT BYE,"System shutting down - Good-bye.\r\n"
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
    LINK %A6,#FRAME_END
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
START_COMMAND:              |  Determine entry point for the current task
    clr.l %D0
    move.w CURRTASK,%D0
    move.w #20,%D1
    lsl.l %D1,%D0
    move.l #CMD_LOOP,-(%SP) |  Save so that a RTS can go back to the command loop
    move.l %D0,%A0
    jmp (%A0)               |  Jump to task entry point
SHUTDOWN_COMMAND:
    PRINT #BYE
    move.w #SYS_SUTDOWN,-(%SP)
    trap #0
    bra .               |  If exit doesn't work, wait in an infinite loop
STATUS_COMMAND:
    bra CMD_LOOP


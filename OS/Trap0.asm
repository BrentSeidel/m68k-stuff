|-----------------------------------------------------------
| Title      : TRAP0 Handler
| Written by : Brent Seidel
| Date       : 6-Feb-2024
| Description: Handler for TRAP0 exceptions
|-----------------------------------------------------------
    .title Handler for TRAP0 exceptions
    .section OS_SECT,#execinstr,#alloc
    .include "OS-Macros.asm"
    .include "../Common/constants.asm"
|
|  Handler for Trap 0.
|  **  Note that this should never be used from supervisor mode
|
|  This is the general user entry point for OS type actions.  It
|  is used by pushing the appropriate arguments onto the stack,
|  then the function number, and executing the instruction.
|  These are called from a user mode program to supervisor mode:
|  The user stack frame looks like:
|
| 2(USP) Function dependent arguments
| 0(USP) Function number (word)
|
|  The function status is returned in the function number on the stack.
|  0 - Success.
|  Other codes will be added here
|  65535 - Undefined function
|
|  Defined functions are:
|    0 - Exit.  Exits the program and does not return
|    1 - Put string.  Prints the string referenced in the argument
|    2 - Get string.  Gets text to the string referenced in the argument
|   16 - Sleep for the number of clock ticks in the argument
|   64 - Shutdown
|
TRAP0HANDLE:
   .global TRAP0HANDLE
ARG1 = 2
    move #0x2700,%SR
    bsr CTXSAVE
    movem.l %D0/%A0-%A1,-(%SP)
    move.l %USP,%A1    |  A1 has the USP value

    move.w (%A1),%D0   |  Get function number
    cmp.w #SYS_EXIT, %D0
    beq EXITP          |  Go to function 0 - exit
    cmp.w #SYS_PUTS,%D0
    beq PUTS           |  Go to function 1 - putstr
    cmp.w #SYS_GETC,%D0
    beq GETC           |  Go to function 2 - getc
    cmp.w #SYS_PUTC,%D0
    beq PUTC           |  Go to function 3 - putc
    cmp.w #SYS_SLEEP,%D0
    beq SLEEP          |  Go to function 16 - sleep
    cmp.w #SYS_SUTDOWN,%D0
    beq SHUTDOWN       |  Go to function 64 - shutdown
|
    move.w #0xFFFF,(%A1)   |  Undefined function
|
|  Common Trap 0 exit
|
EXITT0:
    movem.l (%SP)+,%D0/%A0-%A1
    rte
|
|------------------------------------------------------------------------------
EXITP:                    |  Exit program
    GET_TCB %A0
    bset #2,TCB_STAT0(%A0) |  Set task terminated bit
    movem.l (%SP)+,%D0/%A0-%A1
    jmp SCHEDULE
|
|------------------------------------------------------------------------------
PUTS:                     |  Put a string to the console
   .global PUTS
    move.l ARG1(%A1),%A0  |  Get string address
    bsr PUTSTR
    clr.w (%A1)           |  Set status to success
    bra EXITT0
|------------------------------------------------------------------------------
PUTC:                     |  Put a character to the console
   .global PUTC
    MOVE.W ARG1(%A1),%D0  |  Get character to send
    BSR PUTCHAR
    CLR.W (%A1)           |  Set status to success
    BRA EXITT0
|
|------------------------------------------------------------------------------
GETC:                         |  Read a character from the console
    .global GETC
    GET_TCB %A0
    move.l TCB_CON(%A0),%A0   |  Get console device
    bsr GETCHAR
    cmp.w #0x100,%D0          |  Check if character is ready
    bne 0f
    GET_TCB %A0
    bset #0,TCB_STAT0(%A0)    |  Set task I/O wait status
    subq.l #2,TCB_PC(%A0)     |  Backup PC so TRAP will be retried
    movem.l (%SP)+,%D0/%A0-%A1
    jmp SCHEDULE
0:
    move.w %D0,(%A1)          |  Otherwise return character in status
    bra EXITT0
|
|------------------------------------------------------------------------------
SLEEP:
   .global SLEEP
    CLR.L %D0
    MOVE.L %D0,%A0            |  Clear upper bits of A0
    MOVE.L ARG1(%A1),%D0      |  Get sleep time in ticks
    GET_TCB %A0
    MOVE.L %D0,TCB_SLEEP(%A0) |  Set sleep time
    BSET #1,TCB_STAT0(%A0)    |  Set sleep status bit
    MOVEM.L (%SP)+,%D0/%A0-%A1
    JMP SCHEDULE
|
|------------------------------------------------------------------------------
SHUTDOWN:
   .global SHUTDOWN
    bra CLEANUP


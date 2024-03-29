|------------------------------------------------------------------------------
| Title      : TRAP0 Handler
| Written by : Brent Seidel
| Date       : 6-Feb-2024
| Description: Handler for TRAP0 exceptions
|------------------------------------------------------------------------------
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
|  Note that registers %D0, %A0, and %A1 are saved and restored by the
|  trap handler.  Context is also saved on trap entry, though it is not
|  needed in all cases.
|
TRAP0HANDLE:
   .global TRAP0HANDLE
ARG1 = 2
    move #0x2700,%SR
    bsr CTXSAVE
    movem.l %D0/%A0-%A1,-(%SP)
    move.l %USP,%A1         |  A1 has the USP value

    move.w (%A1),%D0        |  Get function number
    cmp.w #SYS_EXIT, %D0
    beq EXITP               |  Go to function 0 - exit
    cmp.w #SYS_PUTS,%D0
    beq PUTS                |  Go to function 1 - putstr
    cmp.w #SYS_GETC,%D0
    beq GETC                |  Go to function 2 - getc
    cmp.w #SYS_PUTC,%D0
    beq PUTC                |  Go to function 3 - putc
    cmp.w #SYS_SLEEP,%D0
    beq SLEEP               |  Go to function 16 - sleep
    cmp.w #SYS_SUTDOWN,%D0
    beq SHUTDOWN            |  Go to function 64 - shutdown
    cmp.w #SYS_KERDATA,%D0
    beq KERNEL_DATA         |  Go to function 65 - Get kernel data
|
    move.w #0xFFFF,(%A1)    |  Undefined function
|
|  Common Trap 0 exit
|
EXITT0:
    movem.l (%SP)+,%D0/%A0-%A1
    rte
|
|------------------------------------------------------------------------------
EXITP:                      |  Exit program
    GET_TCB %A0
    bset #TCB_FLG_EXIT,TCB_STAT0(%A0) |  Set task terminated bit
    movem.l (%SP)+,%D0/%A0-%A1
    jmp SCHEDULE
|
|------------------------------------------------------------------------------
PUTS:                       |  Put a string to the console
   .global PUTS
    move.l ARG1(%A1),%A0    |  Get string address
    GET_TCB %A1
    move.l TCB_CON(%A1),%A1 |  Get console for current task
    move.l %D0,-(%SP)
    move.l %A1,%D0          |  See if console is defined
    bne 1f
    move.l TTYTBL(%A1),%A1  |  use first entry in DCB table
1:
    move.l (%SP)+,%D0
    bsr WRITESTR
    move.l %USP,%A1         |  A1 has the USP value
    clr.w (%A1)             |  Set status to success
    bra EXITT0
|
|------------------------------------------------------------------------------
PUTC:                       |  Put a character to the console
   .global PUTC
    move.w ARG1(%A1),%D0    |  Get character to send
    GET_TCB %A1
    move.l TCB_CON(%A1),%A1 |  Get console for current task
    move.l %A1,%D1          |  See if console is defined
    bne 1f
    move.l TTYTBL(%A1),%A1  |  use first entry in DCB table
1:
    bsr PUTCHAR
    move.l %USP,%A1         |  A1 has the USP value
    clr.w (%A1)             |  Set status to success
    bra EXITT0
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
    bset #TCB_FLG_IO,TCB_STAT0(%A0) |  Set task I/O wait status
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
    BSET #TCB_FLG_SLEEP,TCB_STAT0(%A0)    |  Set sleep status bit
    MOVEM.L (%SP)+,%D0/%A0-%A1
    JMP SCHEDULE
|
|------------------------------------------------------------------------------
SHUTDOWN:
   .global SHUTDOWN
    bra CLEANUP
|
|------------------------------------------------------------------------------
|  Returns selected kernel data.  This can be used to avoid having to
|  edit and rebuild software when kernel locations change.  The parameter
|  is a longword indicating what data is to be retrieved.  It will be
|  replaced by the requested data.  A word value of 0xFFFE is returned
|  in the function selector position to indicate unknown information.
KERNEL_DATA:
    move.l ARG1(%A1),%D0    |  Get data request
    cmp.l #KER_CLOCK,%D0
    beq 1f
    cmp.l #KER_MAXTSK,%D0
    beq 2f
    cmp.l #KER_CURRTSK,%D0
    beq 3f
    cmp.l #KER_TASKTBL,%D0
    beq 4f
    move.w #0xFFFE,(%A1)
    bra EXITT0
1:                          |  Get clock count
    move.l CLKCOUNT,ARG1(%A1)
    clr.w (%A1)
    bra EXITT0
2:
    move.l #MAXTASK,ARG1(%A1)
    clr.w (%A1)
    bra EXITT0
3:
    clr.l %D0
    move.w CURRTASK,%D0
    move.l %D0,ARG1(%A1)
    clr.w (%A1)
    bra EXITT0
4:
    move.l #TASKTBL,ARG1(%A1)
    clr.w (%A1)
    bra EXITT0

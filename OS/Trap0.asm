|-----------------------------------------------------------
| Title      : TRAP0 Handler
| Written by : Brent Seidel
| Date       : 6-Feb-2024
| Description: Handler for TRAP0 exceptions
|-----------------------------------------------------------
    .title Handler for TRAP0 exceptions
    .section OS_SECT,#execinstr,#alloc
    .include "OS-Macros.asm"
    .include "../Common/Macros.asm"
|
|  Handler for Trap 0
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
    MOVE #0x2700,%SR
    BSR CTXSAVE
    LINK %A6,#0
    MOVEM.L %D0/%A0-%A1,-(%SP)
    MOVE.L %USP,%A1    |  A1 has the USP value

    MOVE.W (%A1),%D0   |  Get function number
    CMP.W #SYS_EXIT, %D0
    BEQ EXITP          |  Go to function 0 code (exit)
    CMP.W #SYS_PUTS,%D0
    BEQ PUTS           |  Go to function 1 code (putstr)
    CMP.W #SYS_GETS,%D0
    BEQ GETS           |  Go to function 2 code (getstr)
    CMP.W #SYS_SLEEP,%D0
    BEQ SLEEP          |  Go to function 16 code (sleep)
    CMP.W #SYS_SUTDOWN,%D0
    BEQ SHUTDOWN       |  Go to function 64 code (shutdown)
|
    MOVE.W #0xFFFF,(%A1)   |  Undefined function
|
|  Common Trap 0 exit
|
EXITT0:
    MOVEM.L (%SP)+,%D0/%A0-%A1
    UNLK %A6
    RTE
|
EXITP:                    |  Exit program
    MOVE.L #0,%A0
    MOVE.W CURRTASK,%A0
    ADD.L %A0,%A0
    ADD.L %A0,%A0
    MOVE.L TASKTBL(%A0),%A0
    BSET #4,TCB_STAT0(%A0) |  Set task terminated bit
    JMP SCHEDULE
|
PUTS:                     |  Put a string to the console
    MOVE.L ARG1(%A1),%A0  |  Get string address
    BSR PUTSTR
    CLR.W (%A1)           |  Set status to success
    BRA EXITT0
|
GETS:                     |  Read a string from the console
    MOVE.L ARG1(%A1),%A0  |  Get string address
    BSR GETSTR
    CLR.W (%A1)           |  Set status to success
    BRA EXITT0
|
SLEEP:
    CLR.L %D0
    MOVE.L %D0,%A0          |  Clear upper bits of A0
    MOVE.L ARG1(%A1),%D0    |  Get sleep time in ticks
    MOVE.W CURRTASK,%A0
    ADD.L %A0,%A0
    ADD.L %A0,%A0
    MOVE.L TASKTBL(%A0),%A0   |  Get pointer to current task data block
    MOVE.L %D0,TCB_SLEEP(%A0) |  Set sleep time
    BSET #1,TCB_STAT0(%A0)    |  Set sleep status bit
    JMP SCHEDULE
|
SHUTDOWN:
    BRA CLEANUP


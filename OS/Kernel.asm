|------------------------------------------------------------------------------
| Title      : Console I/O
| Written by : Brent Seidel
| Date       : 31-Jan-2024
| Description: Operating System for simulated 68000
|------------------------------------------------------------------------------
    .title Operating System Kernel
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
    .include "OS-Macros.asm"
|==============================================================================
|  Exception Vectors
|
|    .section VSECT,#write,#alloc
|    .long NULLVEC
|    .long SUPSTK
|    .rept 0x100-2       |  Can't use .fill with a relocatable symbol
|    .long NULLVEC       |  Initialize all vectors to point to uninialized
|    .endr               |  vector handler.  These may be updated later.
|==============================================================================
|  Addresses for hardware I/O ports
|
    .section HW_PORTS,#write,#alloc
CLKSTAT:               |  Clock status and control
    .dc.b 0
CLKRATE:               |  Clock interval
    .dc.b 0
TTY0BASE:
    .dc.b 0            |  Console status (LSB indicates data ready to read)
    .dc.b 0            |  Console data
TTY1BASE:
    .dc.b 0            |  Console status (LSB indicates data ready to read)
    .dc.b 0            |  Console data
TTY2BASE:
    .dc.b 0            |  Console status (LSB indicates data ready to read)
    .dc.b 0            |  Console data
|==============================================================================
|  Hardware Abstraction Layer section
|
    .section HW_SECT,#execinstr,#alloc
|
|  Prints a string to the console.
|  Input: Address of string in A0.
|  Output: A0 unchanged.
|
PUTSTR:
    .global PUTSTR
    MOVEM.L %D0/%A0-%A1,-(%SP)
    GET_TCB %A1
    MOVE.L TCB_CON(%A1),%A1   |  Pointer to console device block
    MOVE.L DCB_PORT(%A1),%A1
    addq.l #2,%A0           |  Point to string size
    CLR.L %D0
    move.w (%A0)+,%D0       |  Get length of string
    beq 1f                  |  Do nothing if zero length
    SUBQ.W #1,%D0

0:
    MOVE.B (%A0)+,1(%A1)
    DBF %D0,0b
1:
    MOVEM.L (%SP)+,%D0/%A0-%A1
    RTS
|
|  Put a single character to the console.
|  Input: Character in D0.B
|  Output: None
|
PUTCHAR:
    .global PUTCHAR
    MOVE.L %A1,-(%SP)
    GET_TCB %A1
    MOVE.L TCB_CON(%A1),%A1   |  Pointer to console device block
    MOVE.L DCB_PORT(%A1),%A1
    MOVE.B %D0,1(%A1)
    MOVE.L (%SP)+,%A1
    RTS
|
|  Get a single character from the console.  Checks the DCB buffer to
|  see if it is empty or not.  If not, returns the next character,
|  otherwise returns 0x100.
|  Input: Device control block address in A0
|  Output: Character, or 0x100 (if no character) in D0.W
|
GETCHAR:
    .global GETCHAR
    movem.l %D1-%D2/%A1,-(%SP)
    btst #DCB_BUFF_EMPTY,DCB_FLAG0(%A0)
    beq 0f                      |  If buffer is empty, return invalid character
      move.w #0x100,%D0
      movem.l (%SP)+,%D1-%D2/%A1
      rts
0:
    clr.l %D0                   |  Make sure unused bits are cleared
    clr.l %D1
    clr.l %D2
    move.b DCB_FILL(%A0),%D1    |  Get fill pointer
    move.b DCB_EMPTY(%A0),%D2   |  Get empty pointer
    lea DCB_BUFFER(%A0),%A1     |  Get buffer pointer
    add.l %D2,%A1
    move.b (%A1),%D0            |  Get character
    addq.b #1,%D2
    move.b %D2,DCB_EMPTY(%A0)   |  Update empty pointer
    bclr #DCB_BUFF_FULL,DCB_FLAG0(%A0)
    cmp.b %D1,%D2               |  Check if buffer is now empty
    bne 1f
      bset #DCB_BUFF_EMPTY,DCB_FLAG0(%A0)
1:
    movem.l (%SP)+,%D1-%D2/%A1
    rts
|
|------------------------------------------------------------------------------
|  Process receiving a character.  Called from interrupt service routine
|  with A0 pointing to the DCB.  It loops, reading characters, until no
|  more are ready.
RX_CHAR:
    movem.l %D0-%D1/%A1-%A2,-(%SP)
    clr.l %D0
    clr.l %d1
    move.b DCB_FILL(%A0),%D0    |  Fill pointer
    move.b DCB_EMPTY(%A0),%D1   |  Empty pointer
    lea DCB_BUFFER(%A0),%A1     |  Pointer to buffer
    move.l DCB_PORT(%A0),%A2    |  I/O port address
1:
    btst #0,(%A2)               |  Check if character ready
    beq 0f
    add.l %D0,%A1               |  Add offset to base address
    move.b 1(%A2),(%A1)         |  Move data from port to buffer
    addq.b #1,%D0               |  Increment fill pointer
    move.b %D0,DCB_FILL(%A0)    |  Write it back to DCB
    bclr #DCB_BUFF_EMPTY,DCB_FLAG0(%A0) |  Clear empty flag
    cmp.b %D0,%D1               |  Did fill pointer reach empty pointer
    bne 1b
    bset #DCB_BUFF_FULL,DCB_FLAG0(%A0) | Set full flag
    addq.b #1,%D1               |  Increment empty pointer
    move.b %D1,DCB_EMPTY(%A0)   |  Write it back to DCB
    bra 1b
0:
    movem.l (%SP)+,%D0-%D1/%A1-%A2
    rts
|
|------------------------------------------------------------------------------
TTY0HANDLE:            |  65-TTY0 handler
    move.l %A0,-(%SP)
    move.l #TASKTBL,%A0
    move.l 4(%A0),%A0       |  Get TCB for task 1
    bclr #TCB_FLG_IO,TCB_STAT0(%A0) |  Clear the console wait bit
    move.l TCB_CON(%A0),%A0 |  Get console DCB for task 1
    bsr RX_CHAR
    move.l (%SP)+,%A0
    rte
|
|------------------------------------------------------------------------------
TTY1HANDLE:            |  66-TTY1 handler
    move.l %A0,-(%SP)
    move.l #TASKTBL,%A0
    move.l 8(%A0),%A0       |  Get TCB for task 2
    bclr #TCB_FLG_IO,TCB_STAT0(%A0) |  Clear the console wait bit
    move.l TCB_CON(%A0),%A0 |  Get console DCB for task 2
    bsr RX_CHAR
    move.l (%SP)+,%A0
    rte
|
|------------------------------------------------------------------------------
TTY2HANDLE:            |  67-TTY2 handler
    move.l %A0,-(%SP)
    move.l #TASKTBL,%A0
    move.l 12(%A0),%A0       |  Get TCB for task 3
    bclr #TCB_FLG_IO,TCB_STAT0(%A0) |  Clear the console wait bit
    move.l TCB_CON(%A0),%A0 |  Get console DCB for task 3
    bsr RX_CHAR
    move.l (%SP)+,%A0
    rte
|==============================================================================
|  Operating system data.  This includes data for exception handlers and
|  hardware abstraction layer.
|
    .section OS_DATA,#write,#alloc
CLKCOUNT:
    .word 0             |  This gets incremented once per clock tick
    TEXT ODDADDR,"odd address encountered at "
    TEXT ILLEXP,"Illegal instruction encountered at "
    TEXT PRIVEXP,"Privilege violation encountered at "
    TEXT UNINITIALIZED,"Uninitialized exception encountered at "
    TEXT TIMESG,"Elapsed time is "
    STRING OSTXT,0x100
|
|  Table for tasks/threads/whatever you want to call them.
|  There are places for up to 16 possible tasks (including the null
|  task that runs when no other task can).
|
    .equ MAXTASK, 4
    .global MAXTASK
CURRTASK:
    .global CURRTASK
    .dc.w 1
TASKTBL:
    .global TASKTBL
    .dc.l TCB0          |  Task 0 (null task)
    .dc.l TCB1          |  Task 1
    .dc.l TCB2          |  Task 2
    .dc.l TCB3          |  Task 3
    .dc.l 0             |  No task 4
    .dc.l 0             |  No task 5
    .dc.l 0             |  No task 6
    .dc.l 0             |  No task 7
    .dc.l 0             |  No task 8
    .dc.l 0             |  No task 9
    .dc.l 0             |  No task 10
    .dc.l 0             |  No task 11
    .dc.l 0             |  No task 12
    .dc.l 0             |  No task 13
    .dc.l 0             |  No task 14
    .dc.l 0             |  No task 15
|
|  The task data contains the data for context switching and other task
|  related data.
|
TCB0: TCB NULLTASK,USRSTK,0
TCB1: TCB CLI_ENTRY,0x200000,TTY0DEV
TCB2: TCB CLI_ENTRY,0x300000,TTY1DEV
TCB3: TCB CLI_ENTRY,0x400000,TTY2DEV
|
|  Table for TTY devices.  The device number indexes to a pointer to the device
|  data.
|
TTYCNT:
    .dc.w 3             | Number of TTY devices available
TTYTBL:
    .dc.l TTY0DEV
    .dc.l TTY1DEV
    .dc.l TTY2DEV
|
|  Data for TTY devices.  These consists of device port addresses, a
|   driver index, a fill pointer, an empty pointer and a 256 byte buffer.
|
TTY0DEV: DCB TTY0BASE,0,TCB1
TTY1DEV: DCB TTY1BASE,1,TCB2
TTY2DEV: DCB TTY2BASE,2,TCB3
|==============================================================================
|  Operating system, such as it is.
|
    .section OS_SECT,#execinstr,#alloc
INIT:
    .global INIT
|
|  Setup the stack pointers
|
    move.l #SUPSTK,%SP  |  Setup the supervisor stack
|
|  Setup the exception handlers
|
    SET_VECTOR  #3,#ODDADDRHANDLE
    SET_VECTOR  #4,#ILLINSTHANDLE
    SET_VECTOR  #8,#PRIVHANDLE
    SET_VECTOR #32,#TRAP0HANDLE
    SET_VECTOR #64,#CLOCKHANDLE
    SET_VECTOR #65,#TTY0HANDLE
    SET_VECTOR #66,#TTY1HANDLE
    SET_VECTOR #67,#TTY2HANDLE
|
|  Start the clock
|
    move.b #1,CLKRATE  |  Rate is 10 times a second
    move.b #1,CLKSTAT  |  Enable the clock (0 - disable, 1 - enable)
|
|  Enable TTY interrupts
|
    move.b #0x14,TTY0BASE
    move.b #0x14,TTY1BASE
    move.b #0x14,TTY2BASE
|
|  Run the user program
|
    move.w #1,CURRTASK
    subq.l #6,%SP      |  Move stack pointer down to setup for a RTE
    jmp CTXREST        |  Start task 1
|
|  Cleanup - stop the clock and any other necessary stuff before
|  stopping.
|
CLEANUP:
    .global CLEANUP
    CLR.B CLKSTAT      |  Stop the clock
    NUMSTR_L CLKCOUNT,#OSTXT,#0,10
    MOVE.L #TIMESG,%A0
    JSR PUTSTR
    MOVE #OSTXT,%A0
    JSR PUTSTR
    MOVE #NEWLINE,%A0
    JSR PUTSTR
    STOP #0x2000
    BRA .
|
|------------------------------------------------------------------------------
|  The null task.  Use this when no other task can be run
|
NULLTASK:
    .global NULLTASK
    MOVE.L #0x1000,%A0
0:
    TST (%A0)+
    CMP.L #0x00FFFF00,%A0
    BEQ NULLTASK
    BRA 0b
|------------------------------------------------------------------------------
|
|  Set an exception vector
|  Input: A0 is the address of the handler
|         D0 is the vector number
|
SETVEC:
    MOVE.L %A1,-(%SP)
    MOVE.L %D0,-(%SP)
    ASL.L #2,%D0         |  Multiply by 4 to get address in table
    MOVE.L %D0,%A1
    MOVE.L %A0,(%A1)      |  Set the vector
    MOVE.L (%SP)+,%D0
    MOVE.L (%SP)+,%A1
    RTS
|
|------------------------------------------------------------------------------
|  Save and restore context.
|  NOTE: It is assumed that the user programs are operating in user
|        mode and the operating system is in supervisor mode.
|
|  Saving a context should be done as the first thing in processing
|  an exception that may cause a context switch.  It should be called
|  using a JSR and will return to the normal processing.
|
CTXSAVE:
    .global CTXSAVE
    MOVE.L %A6,-(%SP)    |  A6 is used to get a pointer to the task data area
    |
    |  At this point, the stack is:
    |   0(SP) -> A6
    |   4(SP) -> PSW
    |   6(SP) -> PC for return
    |
    GET_TCB %A6
    MOVE.W 8(%SP),(%A6)          |  Save PSW
    MOVE.L 10(%SP),TCB_PC(%A6)   |  Save PC
    MOVEM.L %D0-%D7/%A0-%A5,TCB_D0(%A6) |  Most registers are now saved
    MOVE.L %USP,%A0
    MOVE.L (%SP)+,TCB_A6(%A6)    |  Save A6
    MOVE.L %A0,TCB_SP(%A6)       |  Save USP
    move.l TCB_A0(%A6),%A0       |  Restore A0
    move.l TCB_A6(%A6),%A6       |  Restore A6
    RTS
|
|------------------------------------------------------------------------------
|  Schedule which task to run next
|  Look for the next task in the table that has status cleared.
|  Start with the next task after the current task, looping back
|  around to task 1.  If no task is found, use task 0.  After the
|  scheduling is done, it falls through to context restore and runs
|  the next task.
|
|  Note that registers do not need to be saved since they will all be
|  overwritten by the context restore.
|
SCHEDULE:
    .global SCHEDULE
    CLR.L %D0
    CLR.L %D1
    MOVE.W CURRTASK,%D0     |  Current task number
    tst.w %D0               |  Check if the current task is the null task
    BNE 0f
    MOVEQ.L #1,%D0          |  If current task is 0, set it to 1
    move.w %D0,CURRTASK     |  Update memory as it is used later
0:
    MOVE.W #MAXTASK,%D1
    SUBQ.W #1,%D1           |  Max task number
    cmp.w %D0,%D1           |  Check if current task is max task
    bne 1f                  |  If not, start loop to find next task
    moveq.l #1,%D0          |  Otherwise, wrap to start of list
    BRA 4f
1:                          |  Loop to scan through task table
    ADDQ.L #1,%D0
4:
    MOVE.L %D0,%A0
    ADD.L %A0,%A0
    ADD.L %A0,%A0           |  Multiply by four to use as index
    MOVE.L TASKTBL(%A0),%A0 |  Address of task block
    beq 2f                  |  If no task block, end of table is reached.
                            |  Just use task 0.
    TST.L TCB_STAT0(%A0)
    BEQ 3f                  |  Found a task to select
    CMP.W CURRTASK,%D0
    BEQ 2f                  |  No candidate was found
    CMP.W %D0,%D1           |  Check for end of list
    BNE 1b                  |  Loop, if not
    moveq.l #1,%D0          |  Go back to check task 1, if so
    bra 4b
2:
    CLR.L %D0               |  If no task found, use task 0
3:
    MOVE.W %D0,CURRTASK     |  Set the new current task and ...
|
|  Restoring a context is does as the last thing and takes the place
|  of the RTE in exception processing.
|
CTXREST:
    GET_TCB %A6
    MOVE.L TCB_SP(%A6),%A0    |  Get the user stack pointer
    MOVE.L %A0,%USP           |  Set user stack pointer
    MOVE.W (%A6),(%SP)        |  Put PSW on stack
    MOVE.L TCB_PC(%A6),2(%SP) |  Put PC on stack
    MOVEM.L TCB_D0(%A6),%D0-%D7/%A0-%A6
    RTE                       |  Carry on
|
|------------------------------------------------------------------------------
|  Exception vectors
|
NULLVEC:                |  All vectors initialized to this.
    .global NULLVEC
    MOVE.L 2(%SP),%A0
    NUMSTR_L %A0,#OSTXT,#8,16
    MOVE.L #UNINITIALIZED,%A0
    JSR PUTSTR          |  Print message
    MOVE.L #OSTXT,%A0
    JSR PUTSTR
    MOVE.L #NEWLINE,%A0
    JSR PUTSTR
    JMP CLEANUP
|
|------------------------------------------------------------------------------
ODDADDRHANDLE:         |  3-Odd address error handler
    MOVE.L 2(%SP),%A0
    NUMSTR_L %A0,#OSTXT,#8,16
    MOVE.L #ODDADDR,%A0
    JSR PUTSTR
    MOVE.L #OSTXT,%A0
    JSR PUTSTR
    MOVE.L #NEWLINE,%A0
    JSR PUTSTR
    JMP CLEANUP
|
|------------------------------------------------------------------------------
ILLINSTHANDLE:         |  4-Illegal instruction handler
    MOVE.L 2(%SP),%A0
    NUMSTR_L %A0,#OSTXT,#8,16
    MOVE.L #ILLEXP,%A0
    JSR PUTSTR
    MOVE.L #OSTXT,%A0
    JSR PUTSTR
    MOVE.L #NEWLINE,%A0
    JSR PUTSTR
    JMP CLEANUP
|
|------------------------------------------------------------------------------
PRIVHANDLE:            |  8-Privilege violation handler
    MOVE.L 2(%SP),%A0
    NUMSTR_L %A0,#OSTXT,#8,16
    MOVE.L #PRIVEXP,%A0
    JSR PUTSTR
    MOVE.L #OSTXT,%A0
    JSR PUTSTR
    MOVE.L #NEWLINE,%A0
    JSR PUTSTR
    JMP CLEANUP
|
|  TRAP0-15 handlers go here 32-47 are in an external file.
|
|------------------------------------------------------------------------------
CLOCKHANDLE:            |  64-Clock handler
    MOVE #0x2700,%SR
    ADDQ.L #1,CLKCOUNT
1:                      | Adjust the sleep timers
    MOVEM.L %D0-%D1/%A0-%A1,-(%SP)
    MOVE.L #MAXTASK,%D0
    SUBQ.L #1,%D0
    MOVE.L #TASKTBL,%A0
2:
    MOVE.L (%A0)+,%A1
    btst #TCB_FLG_SLEEP,TCB_STAT0(%A1)
    BEQ 3f              |  If sleep flag is not set
    subq.l #1,TCB_SLEEP(%A1)
    BNE 3f              |  If count has not reached zero
    bclr #TCB_FLG_SLEEP,TCB_STAT0(%A1) |  Clear sleep flag
3:
    DBF %D0,2b
    MOVEM.L (%SP)+,%D0-%D1/%A0-%A1
    BTST #13,(%SP)       |  Check if privilege bit is set
    BNE 0f               |  Only try context switching in
    BSR CTXSAVE          |  user mode
    JMP SCHEDULE
0:
    RTE
|==============================================================================
| Setup the stack sections
|
    .section USR_STACK,#write,#alloc
    .fill 0x100,4,0
USRSTK:
|==============================================================================
    .section OS_STACK,#write,#alloc
    .fill 0x100,4,0
SUPSTK:
    .global SUPSTK

    .end INIT           |  Start at INIT entry point


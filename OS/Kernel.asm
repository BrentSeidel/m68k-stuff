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
|
|==============================================================================
|  Addresses for hardware I/O ports
|  Since there is actually no data defined for this section, it is not
|  allocated.
|
    .section HW_PORTS,#write
CLKSTAT:                |  Clock status and control
    .dc.b 0
CLKRATE:                |  Clock interval
    .dc.b 0
TTY0BASE:
    .dc.b 0             |  Console status (LSB indicates data ready to read)
    .dc.b 0             |  Console data
TTY1BASE:
    .dc.b 0             |  Console status (LSB indicates data ready to read)
    .dc.b 0             |  Console data
TTY2BASE:
    .dc.b 0             |  Console status (LSB indicates data ready to read)
    .dc.b 0             |  Console data
MUX0BASE:
    .dc.b 0             |  Ready register
    .dc.b 0             |  Control/status
    .dc.b 0             |  Channel 0 data
    .dc.b 0             |  Channel 1 data
    .dc.b 0             |  Channel 2 data
    .dc.b 0             |  Channel 3 data
    .dc.b 0             |  Channel 4 data
    .dc.b 0             |  Channel 5 data
    .dc.b 0             |  Channel 6 data
    .dc.b 0             |  Channel 7 data
|
|==============================================================================
|  Hardware Abstraction Layer section
|
    .section HW_SECT,#execinstr,#alloc
|
|------------------------------------------------------------------------------
|  Prints a string to a console for kernel messages.
|  Input: Address of string in A0.
|  Output: A0 unchanged.
|
KPUTSTR:
    .global kPUTSTR
    movem.l %D0/%A0-%A1,-(%SP)
    GET_TCB %A1
    move.l TCB_CON(%A1),%A1 |  Pointer to device block
    move.l %A1,%D1          |  See if console is defined
    bne 1f
    move.l TTYTBL(%A1),%A1  |  use first entry in DCB table
1:
    cmp.w #DRV_SLTTY,DCB_DRIVER(%A1)
    beq SLTTYPUTS
    cmp.w #DRV_MXTTY,DCB_DRIVER(%A1)
    beq MXTTYPUTS
    stop #0                 |  Driver not found
|
|------------------------------------------------------------------------------
|  Writes a string to a TTY.
|  Input: Address of string in A0.
|         Address of DCB for TTY in %A1
|  Output: A0 unchanged.
|
WRITESTR:
    .global WRITESTR
    movem.l %D0/%A0-%A1,-(%SP)
    cmp.w #DRV_SLTTY,DCB_DRIVER(%A1)
    beq SLTTYPUTS
    cmp.w #DRV_MXTTY,DCB_DRIVER(%A1)
    beq MXTTYPUTS
    stop #0                 |  Driver not found
|
|------------------------------------------------------------------------------
|  Put a single character to a TTY.
|  Input: Character in D0.B
|         Address of DCB for TTY in %A1
|  Output: None
|
PUTCHAR:
    .global PUTCHAR
    cmp.w #DRV_SLTTY,DCB_DRIVER(%A1)
    beq SLTTYPUTC
    cmp.w #DRV_MXTTY,DCB_DRIVER(%A1)
    beq MXTTYPUTC
    stop #0                 |  Driver not found
|
|------------------------------------------------------------------------------
|  Get a single character from the console.  Checks the DCB buffer to
|  see if it is empty or not.  If not, returns the next character,
|  otherwise returns 0x100.
|  Input: Device control block address in A0
|  Output: Character, or 0x100 (if no character) in D0.W
|
GETCHAR:
    .global GETCHAR
    movem.l %D1-%D2/%A1,-(%SP)
    cmp.w #DRV_SLTTY,DCB_DRIVER(%A0)
    beq SLTTYGETC
    cmp.w #DRV_MXTTY,DCB_DRIVER(%A0)
    beq MXTTYGETC
    stop #0                 |  Driver not found
|
|==============================================================================
|  Device specific operations for a single line TTY interface
|
|  Sends a single character to the single line TTY device pointed to
|  by %A1.
|
SLTTYPUTC:
    move.l DCB_PORT(%A1),%A1
    move.b %D0,1(%A1)
    rts
|
|------------------------------------------------------------------------------
|  Sends a string to the single line TTY device pointed to by %A1
|
SLTTYPUTS:
    move.l DCB_PORT(%A1),%A1
    addq.l #2,%A0           |  Point to string size
    clr.l %D0
    move.w (%A0)+,%D0       |  Get length of string
    beq 1f                  |  Do nothing if zero length
    subq.w #1,%D0
0:
    move.b (%A0)+,1(%A1)
    dbf %D0,0b
1:
    movem.l (%SP)+,%D0/%A0-%A1
    rts
|
|------------------------------------------------------------------------------
|  Gets a character from the single line TTY device pointed to by %A0
|
SLTTYGETC:
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
|  Perform any device and DCB initializations needed.  Address of DCB
|  passed in in %A0.
|
SLTTYINIT:
    move.b #0,DCB_FILL(%A0)     |  Clear buffer pointers
    move.b #0,DCB_EMPTY(%A0)
    move.b #2,DCB_FLAG0(%A0)    |  Set flag to indicate empty buffer
    move.l DCB_PORT(%A0),%A0
    move.b #0x14,(%A0)       |  Reset interface and enable interrupts
    rts
|
|------------------------------------------------------------------------------
|  Handlers for single line TTY interrupts.  Each device has its own
|  interrupt.
|
TTY0HANDLE:            |  65-TTY0 handler
    movem.l %D0-%D2/%A0-%A3,-(%SP)
    move.l #TTY0DEV,%A0     |  DCB for TTY0
    bra SLTTYRX_CHAR
|
|------------------------------------------------------------------------------
TTY1HANDLE:            |  66-TTY1 handler
    movem.l %D0-%D2/%A0-%A3,-(%SP)
    move.l #TTY1DEV,%A0
    bra SLTTYRX_CHAR
|
|------------------------------------------------------------------------------
TTY2HANDLE:            |  67-TTY2 handler
    movem.l %D0-%D2/%A0-%A3,-(%SP)
    move.l #TTY2DEV,%A0
    bra SLTTYRX_CHAR
|
|------------------------------------------------------------------------------
|  Common end to single line TTY interrupt service routines.  Entered with
|  %A0 pointing to the DCB.  It loops, reading characters, until no
|  more are ready.
|
SLTTYRX_CHAR:
    move.l DCB_OWN(%A0),%D0 |  Get TCB for TTY
    beq 2f                  |  Skip status bit if no TCB
    move.l %D0,%A3
    bclr #TCB_FLG_IO,TCB_STAT0(%A3) |  Clear the console wait bit
2:
    clr.l %D0
    clr.l %D1
    move.b DCB_FILL(%A0),%D0    |  Fill pointer
    move.b DCB_EMPTY(%A0),%D1   |  Empty pointer
    move.l DCB_PORT(%A0),%A2    |  I/O port address
1:
    btst #0,(%A2)               |  Check if character ready
    beq 0f
    lea DCB_BUFFER(%A0),%A1     |  Pointer to buffer
    add.l %D0,%A1               |  Add offset to base address
    move.b 1(%A2),%D2           |  Read data from port
    |
    |  Checks for special control character like CTRL-C can be added here.
    |
    cmp.b #ETX,%D2              |  Check for CTRL-C
    bne 3f
    clr.b DCB_EMPTY(%A0)        |  Clear the DCB buffer
    clr.b DCB_FILL(%A0)
    clr.l %D0
    clr.l %D1
    bset #DCB_BUFF_EMPTY,DCB_FLAG0(%A0)  |  Set buffer empty flag
    bclr #DCB_BUFF_FULL,DCB_FLAG0(%A0)   |  Clear buffer full flag
    move.l DCB_OWN(%A0),%D2     |  Check if TCB attached to DCB
    beq 1b
    bset #TCB_FLG_CTRLC,TCB_STAT0(%A3)   |  If so, set CTRL-C flag
    bra 1b
3:
    move.b %D2,(%A1)            |  Write data to buffer
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
    movem.l (%SP)+,%D0-%D2/%A0-%A3
    rte
|
|==============================================================================
|  Device specific operations for 8 channel TTY multiplexer interface interface
|
|  Sends a string to the multiplexed TTY device pointed to by %A1
|
MXTTYPUTC:
    move.l %D1,-(%SP)
    clr.l %D1
    move.w DCB_UNIT(%A1),%D1
    move.l DCB_PORT(%A1),%A1
    add.l %D1,%A1
    move.b %D0,2(%A1)
|    move.l (%SP)+,%A1
    move.l (%SP)+,%D1
    rts
|
|  Sends a string to the multiplexed TTY device pointed to by %A1
|
MXTTYPUTS:
    move.l %D1,-(%SP)
    clr.l %D1
    move.w DCB_UNIT(%A1),%D1
    move.l DCB_PORT(%A1),%A1
    add.l %D1,%A1           |  Get address of channel's port
    addq.l #2,%A0           |  Point to string size
    clr.l %D0
    move.w (%A0)+,%D0       |  Get length of string
    beq 1f                  |  Do nothing if zero length
    subq.w #1,%D0
0:
    move.b (%A0)+,2(%A1)
    dbf %D0,0b
1:
    move.l (%SP)+,%D1
    movem.l (%SP)+,%D0/%A0-%A1
    rts
|
|------------------------------------------------------------------------------
|  This is the same code as the SLTTYGETC function.  It's separated just
|  in case interface specific changes are needed.  The major differences
|  would be in the *RX_CHAR function.
|  Gets a character from the single line TTY device pointed to by %A0
|
MXTTYGETC:
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
|  Do any initializations required.  Write 3 to the status register to reset
|  the device and enable interrupts.  %A0 contains the address of the base
|  DCB for the mux.
|
MXTTYINIT:
    move.l DCB_PORT(%A0),%A0    |  Get base I/O address
    move.b #3,1(%A0)            |  Reset and enable interrupts
    rts
|
|------------------------------------------------------------------------------
|  Handle interrupts.  Currently only interrupts on character RX.  This
|  does device specific things necessary for each multiplexer and then
|  passes control to common receive code.
|
MUX0HANDLE:
    movem.l %D0-%D3/%A0-%A4,-(%SP)
    move.l #3,%D0
    bra MXTTYRX_CHAR
|
|------------------------------------------------------------------------------
|  Common receive code for multiplexer receive.  This is called with
|  %D0 containing the index into the device table of the base mux device.
|
|  The basic process is
|  Set channel to 0
|  loop
|    Loop
|      If data ready for channel then
|        Read byte
|        Add byte to buffer for channel
|      end if
|      Exit if no more data
|    end loop
|    Increment channel
|    Exit if channel is 8
|  end loop
|
|  Register usage
|    %A0 - DCB address
|    %A1 - Base I/O port address
|    %A2 - DCB buffer pointer
|    %A3 - TCB of owning task
|    %A4 - Address in TTYTBL (points to DCB address)
|    %D0 - Entry number in DCB table
|    %D1 - DCB fill pointer
|    %D2 - DCB empty pointer
|    %D3 - Character read
|
MXTTYRX_CHAR:
    lsl.l #2,%D0
    move.l #TTYTBL,%A4
    add.l %D0,%A4               |  Get address in TTY table of base mux device
    move.l (%A4),%A0            |  Get first DCB
    move.l DCB_PORT(%A0),%A1    |  Base port address
    move.l DCB_OWN(%A0),%A3     |  TCB of owning task, if any
    clr.l %D0                   |  Channel 0
0:
    btst %D0,(%A1)
    beq 3f                      |  If no data ready, check the next channel
    move.l %A3,%D1              |  Test if TCB is zero (we're clearing %D1 anyway)
    beq 5f                      |  Skip if TCB is zero
    bclr #TCB_FLG_IO,TCB_STAT0(%A3) |  Clear the console wait bit
5:
    clr.l %D1
    clr.l %D2
    move.b DCB_FILL(%A0),%D1    |  Fill pointer
    move.b DCB_EMPTY(%A0),%D2   |  Empty pointer
    lea DCB_BUFFER(%A0),%A2     |  Pointer to buffer
    add.l %D1,%A2               |  Add offset to base address
    move.b 2(%A1,%D0),%D3       |  Read data from the channel
    |
    |  Checks for special control character like CTRL-C can be added here.
    |
    cmp.b #ETX,%D3              |  Check for CTRL-C
    bne 2f
    clr.b DCB_EMPTY(%A0)        |  Clear the DCB buffer
    clr.b DCB_FILL(%A0)
    clr.l %D1
    clr.l %D2
    bset #DCB_BUFF_EMPTY,DCB_FLAG0(%A0)  |  Set buffer empty flag
    bclr #DCB_BUFF_FULL,DCB_FLAG0(%A0)   |  Clear buffer full flag
    move.l DCB_OWN(%A0),%D3     |  Check if TCB attached to DCB
    beq 0b
    bset #TCB_FLG_CTRLC,TCB_STAT0(%A3)   |  If so, set CTRL-C flag
    bra 0b
2:
    move.b %D3,(%A2)            |  Write data to buffer
    addq.b #1,%D1               |  Increment fill pointer
    move.b %D1,DCB_FILL(%A0)    |  Write it back to DCB
    bclr #DCB_BUFF_EMPTY,DCB_FLAG0(%A0) |  Clear empty flag
    cmp.b %D1,%D2               |  Did fill pointer reach empty pointer
    bne 0b
    bset #DCB_BUFF_FULL,DCB_FLAG0(%A0) | Set full flag
    addq.b #1,%D2               |  Increment empty pointer
    move.b %D2,DCB_EMPTY(%A0)   |  Write it back to DCB
    bra 0b                      |  Loop until no data for channel
3:
    addq.l #1,%D0               |  Go to next channel
    cmp.b #8,%D0                |  Check if done
    beq 4f                      |  If so, exit
    addq.l #4,%A4               |  Move down the TTY table
    move.l (%A4),%A0            |  Get next DCB
    move.l DCB_OWN(%A0),%A3     |  Get owning TCB, if any.
    bra 0b
4:
    movem.l (%SP)+,%D0-%D3/%A0-%A4
    rte
|
|==============================================================================
|  Operating system data.  This includes data for exception handlers and
|  hardware abstraction layer.
|
    .section OS_DATA,#write,#alloc
CLKCOUNT:
    .global CLKCOUNT
    dc.l 0             |  This gets incremented once per clock tick
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
    .equ MAXTASK, 6
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
    .dc.l TCB4          |  Task 4
    .dc.l TCB5          |  Task 5
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
TCB4: TCB CLI_ENTRY,0x500000,MUX0DEV
TCB5: TCB CLI_ENTRY,0x500000,MUX1DEV
|
|  Table for TTY devices.  The device number indexes to a pointer to the device
|  data.  Note that entries for a mux must be kept together and in channel
|  order.
|
TTYCNT:
    .global TTYCNT
    .dc.w 11            | Number of TTY devices available
TTYTBL:
    .global TTYTBL
    .dc.l TTY0DEV
    .dc.l TTY1DEV
    .dc.l TTY2DEV
    .dc.l MUX0DEV       |  All devices for a mux must be together in order
    .dc.l MUX1DEV
    .dc.l MUX2DEV
    .dc.l MUX3DEV
    .dc.l MUX4DEV
    .dc.l MUX5DEV
    .dc.l MUX6DEV
    .dc.l MUX7DEV
|
|  Data for TTY devices.  These consists of device port addresses, a
|   driver index, a fill pointer, an empty pointer and a 256 byte buffer.
|
TTY0DEV: DCB TTY0BASE,0,DRV_SLTTY,TCB1
TTY1DEV: DCB TTY1BASE,1,DRV_SLTTY,TCB2
TTY2DEV: DCB TTY2BASE,2,DRV_SLTTY,TCB3
MUX0DEV: DCB MUX0BASE,0,DRV_MXTTY,TCB4
MUX1DEV: DCB MUX0BASE,1,DRV_MXTTY,TCB5
MUX2DEV: DCB MUX0BASE,2,DRV_MXTTY,0
MUX3DEV: DCB MUX0BASE,3,DRV_MXTTY,0
MUX4DEV: DCB MUX0BASE,4,DRV_MXTTY,0
MUX5DEV: DCB MUX0BASE,5,DRV_MXTTY,0
MUX6DEV: DCB MUX0BASE,6,DRV_MXTTY,0
MUX7DEV: DCB MUX0BASE,7,DRV_MXTTY,0
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
|
|  Initialize clock
|
    SET_VECTOR #64,#CLOCKHANDLE
    move.b #1,CLKRATE  |  Rate is 10 times a second
    move.b #1,CLKSTAT  |  Enable the clock (0 - disable, 1 - enable)
|
|  Initialize single line TTYs
|
    SET_VECTOR #65,#TTY0HANDLE
    move.l #TTY0DEV,%A0
    bsr SLTTYINIT
    SET_VECTOR #66,#TTY1HANDLE
    move.l #TTY1DEV,%A0
    bsr SLTTYINIT
    SET_VECTOR #67,#TTY2HANDLE
    move.l #TTY2DEV,%A0
    bsr SLTTYINIT
|
|  Initialize multi-line multiplexer
|
    SET_VECTOR #68,#MUX0HANDLE
    move.l #MUX0DEV,%A0
    bsr MXTTYINIT
|
|  Start multitasking...
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
    bsr KPUTSTR
    MOVE #OSTXT,%A0
    bsr KPUTSTR
    MOVE #NEWLINE,%A0
    bsr KPUTSTR
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
    tst.w (%A0)+
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
    btst #TCB_FLG_CTRLC,TCB_STAT0(%A0)
    beq 5f
    clr.l TCB_STAT0(%A0)    |  Clear all status flags
    move.l #CLI_ENTRY,TCB_PC(%A0)
5:
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
    move.l 2(%SP),%A1
    NUMSTR_L %A1,#OSTXT,#8,16
    MOVE.L #UNINITIALIZED,%A0
    bsr KPUTSTR          |  Print message
    MOVE.L #OSTXT,%A0
    bsr KPUTSTR
    MOVE.L #NEWLINE,%A0
    bsr KPUTSTR
    bra CLEANUP
|
|------------------------------------------------------------------------------
ODDADDRHANDLE:         |  3-Odd address error handler
    move.l 2(%SP),%A1
    NUMSTR_L %A1,#OSTXT,#8,16
    MOVE.L #ODDADDR,%A0
    bsr KPUTSTR
    MOVE.L #OSTXT,%A0
    bsr KPUTSTR
    MOVE.L #NEWLINE,%A0
    bsr KPUTSTR
    bra CLEANUP
|
|------------------------------------------------------------------------------
ILLINSTHANDLE:         |  4-Illegal instruction handler
    move.l 2(%SP),%A1
    NUMSTR_L %A1,#OSTXT,#8,16
    MOVE.L #ILLEXP,%A0
    bsr KPUTSTR
    MOVE.L #OSTXT,%A0
    bsr KPUTSTR
    MOVE.L #NEWLINE,%A0
    bsr KPUTSTR
    bra CLEANUP
|
|------------------------------------------------------------------------------
PRIVHANDLE:            |  8-Privilege violation handler
    move.l 2(%SP),%A1
    NUMSTR_L %A1,#OSTXT,#8,16
    MOVE.L #PRIVEXP,%A0
    bsr KPUTSTR
    MOVE.L #OSTXT,%A0
    bsr KPUTSTR
    MOVE.L #NEWLINE,%A0
    bsr KPUTSTR
    bra CLEANUP
|
|  TRAP0-15 handlers go here 32-47 are in an external file.
|
|------------------------------------------------------------------------------
CLOCKHANDLE:            |  64-Clock handler
    MOVE #0x2700,%SR
    ADDQ.L #1,CLKCOUNT
1:                      |  Scan through the task table
    MOVEM.L %D0-%D1/%A0-%A1,-(%SP)
    MOVE.L #MAXTASK,%D0
    SUBQ.L #1,%D0
    MOVE.L #TASKTBL,%A0
2:                      | Adjust the sleep timers
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
    bra SCHEDULE
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


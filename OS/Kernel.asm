|-----------------------------------------------------------
| Title      : Console I/O
| Written by : Brent Seidel
| Date       : 31-Jan-2024
| Description: Operating System for simulated 68000
|-----------------------------------------------------------
    .title Operating System Kernel
    .include "../Common/constants.asm"
    .include "../Common/Macros.asm"
    .include "OS-Macros.asm"
|==============================================================================
|  Exception Vectors
|
    .section VSECT,#write,#alloc
    .word NULLVEC
    .word SUPSTK
    .rept 0x100-2       |  Can't use .fill with a relocatable symbol
    .long NULLVEC       |  Initialize all vectors to point to uninialized
    .endr               |  vector handler.  These may be updated later.
|==============================================================================
|  Addresses for hardware I/O ports
|
    .section HW_PORTS,#write,#alloc
CLKSTAT:               |  Clock status and control
    .byte 0
CLKRATE:               |  Clock interval
    .byte 0
TTY0STAT:              |  Console status (LSB indicates data ready to read)
    .byte 0
TTY0DAT:               |  Console data
    .byte 0
TTY1STAT:              |  Console status (LSB indicates data ready to read)
    .byte 0
TTY1DAT:               |  Console data
    .byte 0
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
    MOVE.L #0,%A1
    MOVE.W CURRTASK,%A1
    ADD.L %A1,%A1
    ADD.L %A1,%A1
    MOVE.L TASKTBL(%A1),%A1   |  Pointer to current TCB
    MOVE.L TCB_CON(%A1),%A1   |  Pointer to console device
    MOVE.L (%A1),%A1
    ADDQ #2,%A0
    CLR.L %D0
    MOVE.W (%A0)+,%D0      |  Get length of string
    SUBQ.W #1,%D0
0:
    MOVE.B (%A0)+,(%A1)
    DBF %D0,0b
    MOVEM.L (%SP)+,%D0/%A0-%A1
    RTS
|
|  Put a single character to the console.
|  Input: Character in D0.B
|  Output: None
|
PUTC:
    MOVE.L %A1,-(%SP)
    MOVE.L #0,%A1
    MOVE.W CURRTASK,%A1
    ADD.L %A1,%A1
    ADD.L %A1,%A1
    MOVE.L TASKTBL(%A1),%A1   |  Pointer to current TCB
    MOVE.L TCB_CON(%A1),%A1   |  Pointer to console device
    MOVE.L (%A1),%A1
    MOVE.B %D0,(%A1)
    MOVE.L (%SP)+,%A1
    RTS
|
|  Get a single character from the console.  This waits
|  until a character is ready before returning.
|  Input: None
|  Output: Character in D0.B
|
GETC:
    BTST #0,TTY0STAT
    BEQ GETC             |  Wait for bit 0 to be set
    MOVE.B TTY0DAT,%D0
    RTS
|
|  Get a string from the console.  This is the bounded string data structure.
|  The string is terminated by the structure begin full or a CR or LF entered
|  on the console.
|  Input: A0 contains the base address of the string structure.
|     D0  Contains received character
|     D1  Max length of string (count down)
|     D2  Max length of string (fixed)
|     D3  Size of string
|     A0  Address of string
|     A1  Pointer to TTY device structure
|     A2  Saved address of string
|
|  This will probably mostly get moved into the library section so that
|  most of it runs under user mode.  This will allow it to be interrupted.
|
GETSTR:
    .global GETSTR
    MOVEM.L %D0-%D3/%A0-%A2,-(%SP)
    MOVE.L %A0,%A2
    CLR.L %D1
    CLR.L %D3
    MOVE.W (%A0),%D1    |  Size of string
    MOVE.L TTY0DEV,%A1  |  TTY Data port
    MOVE.L %D1,%D2
    ADDQ.L #4,%A0       |  Point to buffer
0:
    BSR GETC
    CMP.B #CR,%D0       |  Check for carriage return
    BEQ 3f
    CMP.B #LF,%D0       |  Check for linefeed
    BEQ 3f
    CMP.B #BS,%D0       |  Check for backspace
    BEQ 1f
    CMP.B #DEL,%D0      |  Check for delete
    BEQ 1f
    MOVE.B %D0,(%A0)+
    BSR PUTC            |  Echo the character
    ADDQ.L #1,%D3
    DBF %D1,0b
1:                      |  Handle backspace/delete
    CMP.W %D1,%D2
    BEQ 2f              |  Check if string is empty
    SUBQ.L #1,%A0       |  Move pointer back
    ADDQ.L #1,%D1       |  Move counter up
    SUBQ.L #1,%D3       |  Move size back
    MOVE.B #BS,(%A1)    |  Update display
    MOVE.B #SP,(%A1)
    MOVE.B #BS,(%A1)
    BRA 0b
2:
    MOVE.B #BELL,(%A1)  |  Just ring the bell
    BRA 0b
3:
    MOVE.B #CR,(%A1)    |  Carriage return
    MOVE.B #LF,(%A1)    |  Line-feed
    MOVE.L %A2,%A0
    MOVE.W %D3,2(%A0)
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A2
    RTS
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
|  Table for tasks/threads/whatever you want to call them
|
    .equ MAXTASK, 3
CURRTASK:
    .global CURRTASK
    .hword 1
TASKTBL:
    .global TASKTBL
    .long TCB0
    .long TCB1
    .long TCB2
|
|  The task data contains the data for context switching and other task
|  related data.
|
TCB0: TCB NULLTASK,USRSTK,0
TCB1: TCB 0x100000,0x200000,TTY0DEV
TCB2: TCB 0x200000,0x300000,TTY1DEV
|
|  Table for TTY devices.  The device number indexes to a pointer to the device
|  data.
|
TTYCNT:
    .word 2             | Number of TTY devices available
TTYTBL:
    .long TTY0DEV
    .long TTY1DEV
|
|  Data for TTY0 device.  This consists of device port addresses, a driver index,
|  a fill pointer, an empty pointer and a 256 byte buffer.
|
TTY0DEV:
    .long TTY0DAT       |  Data port
    .long TTY0STAT      |  Status port
    .hword 1            |  Driver index (used to select driver)
    .byte 0             |  Buffer fill pointer
    .byte 0             |  Buffer empty pointer
    .space 0x100,0      |  Data buffer
TTY1DEV:
    .long TTY1DAT       |  Data port
    .long TTY1STAT      |  Status port
    .hword 1            |  Driver index (used to select driver)
    .byte 0             |  Buffer fill pointer
    .byte 0             |  Buffer empty pointer
    .space 0x100,0      |  Data buffer
|==============================================================================
|  Operating system, such as it is.
|
    .section OS_SECT,#execinstr,#alloc
INIT:
    .global INIT
|
|  Setup the stack pointers
|
    MOVE.L #SUPSTK,%SP  |  Setup the supervisor stack
|
|  Setup the exception handlers
|
    MOVE.L #3,%D0       |  Odd address error exception
    MOVE.L #ODDADDRHANDLE,%A0
    BSR SETVEC
    MOVE.L #4,%D0       |  Illegal Instruction exception
    MOVE.L #ILLINSTHANDLE,%A0
    BSR SETVEC
    MOVE.L #8,%D0       |  Privilege violation exception
    MOVE.L #PRIVHANDLE,%A0
    BSR SETVEC
    MOVE.L #32,%D0      |  TRAP #0 exception
    MOVE.L #TRAP0HANDLE,%A0
    BSR SETVEC
    MOVE.L #64,%D0      |  Clock interrupt
    MOVE.L #CLOCKHANDLE,%A0
    BSR SETVEC
    MOVE.L #65,%D0      |  TTY0 interrupt
    MOVE.L #TTY0HANDLE,%A0
    BSR SETVEC
|
|  Start the clock
|
    MOVE.B #1,CLKRATE  |  Rate is 10 times a second
    MOVE.B #1,CLKSTAT  |  Enable the clock (0 - disable, 1 - enable)
|
|  Enable TTY0 interrupts
|
    MOVE.B #12,TTY0STAT
|
|  Set the SR to enable interrupts
|
    MOVE #0x2000,%SR
|
|  Run the user program
|
    MOVE.W #1,CURRTASK
    SUBQ.L #6,%SP      |  Move stack pointer down to setup for a RTE
    JMP CTXREST        |  Start task 1
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
|  The null task.  Use this when no other task can be run
|
NULLTASK:
    MOVE.L #0x1000,%A0
0:
    TST (%A0)+
    CMP.L #0x00FFFF00,%A0
    BEQ NULLTASK
    BRA 0b
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
    MOVE.L #0,%A6
    MOVE.W CURRTASK,%A6
    ADD.L %A6,%A6
    ADD.L %A6,%A6            |  Multiply task number by four to index
    MOVE.L TASKTBL(%A6),%A6  |  into task table.
    MOVE.W 8(%SP),(%A6)      |  Save PSW
    MOVE.L 10(%SP),TCB_PC(%A6)    |  Save PC
    MOVEM.L %D0-%D7/%A0-%A5,TCB_D0(%A6) |  Most registers are now saved
    MOVE.L %USP,%A0
    MOVE.L %A6,%A1
    MOVE.L (%SP)+,TCB_A6(%A6)    |  Save A6
    MOVE.L %A0,TCB_SP(%A6)       |  Save USP
    RTS
|
|  Schedule which task to run next
|  Look for the next task in the table that has status cleared.
|  Start with the next task after the current task, looping back
|  around to task 1.  If no task is found, use task 0.
|
SCHEDULE:
    .global SCHEDULE
    MOVE #0x2700,%SR
    MOVEM.L %D0-%D1/%A0-%A1,-(%SP)
    CLR.L %D0
    CLR.L %D1
    MOVE.W CURRTASK,%D0     |  Current task number
    TST.W %D0
    BNE 0f
    MOVEQ.L #1,%D0          |  If current task is 0, set it to 1
    MOVE.W %D0,CURRTASK
0:
    MOVE.W #MAXTASK,%D1
    SUBQ.W #1,%D1           |  Max task number
    CMP.W %D0,%D1
    BNE 1f
    MOVEQ.L #1,%D0          |  Wrap to start of list
    BRA 4f
1:
    ADDQ.L #1,%D0
4:
    MOVE.L %D0,%A0
    ADD.L %A0,%A0
    ADD.L %A0,%A0           |  Multiply by four to use as index
    MOVE.L TASKTBL(%A0),%A0 |  Address of task block
    TST.L TCB_STAT0(%A0)
    BEQ 3f                  |  Found a task to select
    CMP.W CURRTASK,%D0
    BEQ 2f                  |  No candidate was found
    CMP.W %D0,%D1
    BNE 1b
    ADDQ.L #1,%D0           |  Point to next task
    BRA 1b
2:
    CLR.L %D0               |  If no task found, use task 0
3:
    MOVE.W %D0,CURRTASK     |  Set the new current task
    MOVEM.L (%SP)+,%D0-%D1/%A0-%A1
|    JMP CTXREST            |  After scheduling, the next thing is to
                            |  restore context and start the task.
|
|  Restoring a context is does as the last thing and takes the place
|  of the RTE in exception processing.
|
CTXREST:
    MOVE.L #0,%A6
    MOVE.W CURRTASK,%A6
    ADD.L %A6,%A6            |  Multiply task number by four to index
    ADD.L %A6,%A6            |  into task table
    MOVE.L TASKTBL(%A6),%A6  |  Get pointer to current task table
    MOVE.L TCB_SP(%A6),%A0       |  Get the user stack pointer
    MOVE.L %A0,%USP          |  Set user stack pointer
    MOVE.W (%A6),(%SP)       |  Put PSW on stack
    MOVE.L TCB_PC(%A6),2(%SP)     |  Put PC on stack
    MOVEM.L TCB_D0(%A6),%D0-%D7/%A0-%A6
    RTE                    |  Carry on
|
|  Exception vectors
|
NULLVEC:                |  All vectors initialized to this.
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
CLOCKHANDLE:           |  64-Clock handler
    MOVE #0x2700,%SR
    BTST #13,(%SP)      |  Check if privilege bit is set
    BNE 0f
    BSR CTXSAVE        |  Only try context switching in
    ADDQ.L #1,CLKCOUNT |  user mode
    BSR 1f
    JMP SCHEDULE
0:
    ADDQ.L #1,CLKCOUNT
    BSR 1f
    RTE
|
|  Adjust sleep timers
|
1:
    MOVEM.L %D0-%D1/%A0-%A1,-(%SP)
    MOVE.L #MAXTASK,%D0
    SUBQ.L #1,%D0
    MOVE.L #TASKTBL,%A0
2:
    MOVE.L (%A0)+,%A1
    BTST #1,70(%A1)
    BEQ 3f             |  If sleep flag is not set
    SUBQ.L #1,74(%A1)
    BNE 3f             |  If count has not reached zero
    BCLR #1,70(%A1)    |  Clear sleep flag
3:
    DBF %D0,2b
    MOVEM.L (%SP)+,%D0-%D1/%A0-%A1
    RTS
|
TTY0HANDLE:            |  65-TTY0 handler
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

    .end INIT           |  Start at INIT entry point


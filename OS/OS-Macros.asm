#-----------------------------------------------------------
# Title      : OS-Macros.S68
# Written by : Brent Seidel
# Date       : 11-Feb-2024
# Description: A collection of operating system macros and definitions
#-----------------------------------------------------------
#
#  ***  This is not a stand-alone file.  It gets included into
#  ***  other assembly language programs.
|
|  Macro to define a Task Control Block.  By using a macro, we can ensure
|  that TCBs are defined consistently.
|
|  The task data block contains the following items
|  PSW
|  PC
|  Registers D0-D7, A0-A7
|  Task status (byte/bit)
|    0/0 - I/O wait
|    0/1 - Sleep
|    0/2 - Task terminated
|  Task sleep timer
|  Task console device
|
|  Note that since the bit instructions only work on a single byte the
|  bits above are indicated by byte/bit.  The status word can still be
|  compared with zero using a TST.L instruction.
|
.macro TCB entry,stack,console
    .hword 0            | PSW (0)
    .long \entry        | PC  (2)
    .long 0             | D0 (use MOVEM.L to save registers here) (6)
    .long 0             | D1 (10)
    .long 0             | D2 (14)
    .long 0             | D3 (18)
    .long 0             | D4 (22)
    .long 0             | D5 (26)
    .long 0             | D6 (30)
    .long 0             | D7 (34)
    .long 0             | A0 (38)
    .long 0             | A1 (42)
    .long 0             | A2 (46)
    .long 0             | A3 (50)
    .long 0             | A4 (54)
    .long 0             | A5 (58)
    .long 0             | A6 (62)
    .long \stack        | SP (needs to be saved separately) (66)
    .long 0             | Task status (70)
    .long 0             | Sleep timer (74)
    .long \console      | Console device (78)
.endm
|
|  Define offsets into TCB
|
    .equ TCB_PSW,    0
    .equ TCB_PC,     2
    .equ TCB_D0,     6
    .equ TCB_D1,    10
    .equ TCB_D2,    14
    .equ TCB_D3,    18
    .equ TCB_D4,    22
    .equ TCB_D5,    26
    .equ TCB_D6,    30
    .equ TCB_D7,    34
    .equ TCB_A0,    38
    .equ TCB_A1,    42
    .equ TCB_A2,    46
    .equ TCB_A3,    50
    .equ TCB_A4,    54
    .equ TCB_A5,    58
    .equ TCB_A6,    62
    .equ TCB_SP,    66
    .equ TCB_STAT0, 70
    .equ TCB_STAT1, 71
    .equ TCB_STAT2, 72
    .equ TCB_STAT3, 73
    .equ TCB_SLEEP, 74
    .equ TCB_CON,   78
|
|  Define TCB flags
|
   .equ TCB_FLG_IO,    0
   .equ TCB_FLG_SLEEP, 1
   .equ TCB_FLG_EXIT,  2
|
|  Get the TCB for the current task.  The address of the TCB is left in
|  the specified address register.
|
.macro GET_TCB reg
    move.l #0,\reg            |  Ensure that high bits are cleared
    move.w CURRTASK,\reg      |  Get current task number
    add.l \reg,\reg
    add.l \reg,\reg           |  Multiply by 4
    move.l TASKTBL(\reg),\reg |  Index into TCB table
.endm
|
|  Define a Device Control Block.
|  Currently, the only device controlled by a DCB is the console interfaces.
|  This will likely evolve once more devices are defined.
|  The defined flags are:
|  byte/bit - Meaning
|     0/0 - Buffer full
|     0/1 - Buffer empty
|
.macro DCB base,unit
    .long \base         |  Data port
    .byte 2             |  Flag word 0 (4)  Buffer empty flag is set
    .byte 0             |  Flag word 1 (5)
    .byte 0             |  Flag word 2 (6)
    .byte 0             |  Flag word 3 (7)
    .hword \unit        |  Unit number (8)
    .hword 1            |  Driver index (used to select driver) (10)
    .byte 0             |  Buffer fill pointer (12)
    .byte 0             |  Buffer empty pointer (13)
    .space 0x100,0      |  Data buffer (14)
.endm
|
|  Offsets into DCB
|
    .equ DCB_PORT,      0
    .equ DCB_FLAG0,     4
    .equ DCB_FLAG1,     5
    .equ DCB_FLAG2,     6
    .equ DCB_FLAG3,     7
    .equ DCB_UNIT,      8
    .equ DCB_DRIVER,   10
    .equ DCB_FILL,     12
    .equ DCB_EMPTY,    13
    .equ DCB_BUFFER,   14
|
|  Define DCB flags
|
    .equ DCB_BUFF_FULL,  0
    .equ DCB_BUFF_EMPTY, 1
|
|  Set an exception vector.  Registers %D0 and %A0 are used.
|
.macro SET_VECTOR num,handler
    move.l \num,%D0      |  TTY0 interrupt
    move.l \handler,%A0
    bsr SETVEC
.endm

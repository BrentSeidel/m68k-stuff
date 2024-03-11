|------------------------------------------------------------------------------
| Title      : OS-Macros.S68
| Written by : Brent Seidel
| Date       : 11-Feb-2024
| Description: A collection of operating system macros and definitions
|------------------------------------------------------------------------------
.nolist
|
|  ***  This is not a stand-alone file.  It gets included into
|  ***  other assembly language programs.
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
    .dc.w 0             | PSW (0)
    .dc.l \entry        | PC  (2)
    .dc.l 0             | D0 (use MOVEM.L to save registers here) (6)
    .dc.l 0             | D1 (10)
    .dc.l 0             | D2 (14)
    .dc.l 0             | D3 (18)
    .dc.l 0             | D4 (22)
    .dc.l 0             | D5 (26)
    .dc.l 0             | D6 (30)
    .dc.l 0             | D7 (34)
    .dc.l 0             | A0 (38)
    .dc.l 0             | A1 (42)
    .dc.l 0             | A2 (46)
    .dc.l 0             | A3 (50)
    .dc.l 0             | A4 (54)
    .dc.l 0             | A5 (58)
    .dc.l 0             | A6 (62)
    .dc.l \stack        | SP (needs to be saved separately) (66)
    .dc.l 0             | Task status (70)
    .dc.l 0             | Sleep timer (74)
    .dc.l \console      | Console device (78)
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
.macro DCB base,unit,driver,owner
    .dc.l \owner        |  Owning TCB (0)
    .dc.l \base         |  Data port (4)
    .dc.b 2             |  Flag word 0 (4)  Buffer empty flag is set
    .dc.b 0             |  Flag word 1 (5)
    .dc.b 0             |  Flag word 2 (6)
    .dc.b 0             |  Flag word 3 (7)
    .dc.w \unit         |  Unit number (8)
    .dc.w \driver       |  Driver index (used to select driver) (10)
    .dc.b 0             |  Buffer fill pointer (12)
    .dc.b 0             |  Buffer empty pointer (13)
    .space 0x100,0      |  Data buffer (14)
.endm
|
|  Offsets into DCB
|
    .equ DCB_OWN,       0
    .equ DCB_PORT,      4
    .equ DCB_FLAG0,     8
    .equ DCB_FLAG1,     9
    .equ DCB_FLAG2,    10
    .equ DCB_FLAG3,    11
    .equ DCB_UNIT,     12
    .equ DCB_DRIVER,   14
    .equ DCB_FILL,     16
    .equ DCB_EMPTY,    17
    .equ DCB_BUFFER,   18
|
|  Define DCB flags
|
    .equ DCB_BUFF_FULL,  0
    .equ DCB_BUFF_EMPTY, 1
|
|  Defined driver numbers
|
   .equ DRV_SLTTY, 1        |  Single channel TTY interface
   .equ DRV_MXTTY, 2        |  8 Channel TTY multiplexter
|
|  Set an exception vector.  Registers %D0 and %A0 are used.
|
.macro SET_VECTOR num,handler
    move.l \num,%D0         |  Interrupt number
    move.l \handler,%A0     |  Handler address
    bsr SETVEC
.endm
.list

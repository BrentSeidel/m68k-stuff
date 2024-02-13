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
|  Task status (bits)
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
    .equ TCB_A6,    62
    .equ TCB_SP,    66
    .equ TCB_STAT0, 70
    .equ TCB_STAT1, 71
    .equ TCB_STAT2, 72
    .equ TCB_STAT3, 73
    .equ TCB_SLEEP, 74
    .equ TCB_CON,   78

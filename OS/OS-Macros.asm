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
|  The first part of the TCB (through the stack pointer) is used to store
|  the task's context.  The rest stores other task status.
|
.macro TCB entry,stack
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
    .long 0             | Console device (78)
.endm


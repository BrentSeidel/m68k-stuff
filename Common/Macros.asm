|-----------------------------------------------------------
| Title      : Macros.S68
| Written by : Brent Seidel
| Date       : 2-Feb-2024
| Description: A collection of macros and definitions
|-----------------------------------------------------------
|
|------------------------------------------------------------------------------
|
|  Strings are a data structure as follows:
|  Word: Max size of string
|  Word: Current size of string
|  Bytes: Text of the string
|
|------------------------------------------------------------------------------
|  String definition macros
|
|  Define space for a string.  The first argument is
|  the label, the second is the maximum size.
|
.macro STRING label,size
    .align 2
\label: .hword \size
    .hword 0
    .space \size,0
.endm
|
|  Define a string with text.  The first argument is
|  the label.  The second is the text.  Enclose the text
|  with quotation marks ("").
|
.macro TEXT label,string
    .align 2
\label: .hword 0f-\label-4
    .hword 0f-\label-4
    .ascii "\string"
0:
.endm
|------------------------------------------------------------------------------
|  Number conversion macros
|
|  Convert a number to a string.  Called as
|   NUMSTR.x <number>,<string>,<flags>,<base>
|       <base> is the conversion base and can be 8, 10, or 16
#
.macro NUMSTR_B num,str,flag,base
    move.l %A0,-(%SP)
    move.l #LIBTBL,%A0
    move.w \flag,-(%SP)
    move.l \str,-(%SP)    |  String
    move.l \num,-(%SP)    |  Number
    .if \base-8
    .else
      move.l LIB_OCTSTR(%A0),%A0
    .endif
    .if \base-10
    .else
      move.l LIB_DECSTR(%A0),%A0
    .endif
    .if \base-16
    .else
      move.l LIB_HEXSTR(%A0),%A0
    .endif
    JSR (%A0)
    addq.l #8,%SP       |  Clean 10 bytes off the stack.
    addq.l #2,%SP       |  Max ADDQ is 8
    move.l (%SP)+,%A0
.endm
.macro NUMSTR_W num,str,flag,base
    move.l %A0,-(%SP)
    move.l #LIBTBL,%A0
    move.w \flag+1,-(%SP)
    move.l \str,-(%SP)    |  String
    move.l \num,-(%SP)    |  Number
    .if \base-8
    .else
      move.l LIB_OCTSTR(%A0),%A0
    .endif
    .if \base-10
    .else
      move.l LIB_DECSTR(%A0),%A0
    .endif
    .if \base-16
    .else
      move.l LIB_HEXSTR(%A0),%A0
    .endif
    JSR (%A0)
    addq.l #8,%SP       |  Clean 10 bytes off the stack.
    addq.l #2,%SP       |  Max ADDQ is 8
    move.l (%SP)+,%A0
.endm
.macro NUMSTR_L num,str,flag,base
    move.l %A0,-(%SP)
    move.l #LIBTBL,%A0
    move.w \flag+2,-(%SP)
    move.l \str,-(%SP)    |  String
    move.l \num,-(%SP)    |  Number
    .if \base-8
    .else
      move.l LIB_OCTSTR(%A0),%A0
    .endif
    .if \base-10
    .else
      move.l LIB_DECSTR(%A0),%A0
    .endif
    .if \base-16
    .else
      move.l LIB_HEXSTR(%A0),%A0
    .endif
    JSR (%A0)
    addq.l #8,%SP       |  Clean 10 bytes off the stack.
    addq.l #2,%SP       |  Max ADDQ is 8
    move.l (%SP)+,%A0
.endm
|------------------------------------------------------------------------------
|  String manipulation macros
|
|  Get the max size of a string.
|   STRMAX <string>,<destination>
|  Note that A0 cannot be used as a destination since it's save and restored
|
.macro STRMAX str,dest
    move.l %A0,-(%SP)    |  Save A0 since it is used
    move.l \str,%A0
    move.w (%A0),\dest
    move.l (%SP)+,%A0
.endm
|
|  Get the current length of a string
|   STRLEN <string>,<destination>
|  Note that A0 cannot be used as a destination since it's save and restored
|
.macro STRLEN str,dest
    move.l %A0,-(SP)    |  Save A0 since it is used
    move.l \str,%A0
    move.w 2(%A0),\dest
    move.l (%SP)+,%A0
.endm
|------------------------------------------------------------------------------
|  I/O Macros
|
|  Print a string
|
.macro PRINT str
    move.l \str,-(%SP)
    move.w #SYS_PUTS,-(%SP)    |  Code to print a string
    trap #0
    addq.l #6,%SP
.endm
|
|  Print a character
|
.macro PUTC char
    move.w \char,-(%SP)
    move.w #SYS_PUTC,-(%SP)    |  Code to print a string
    trap #0
    addq.l #4,%SP
.endm
|
|  Get a string
|
.macro INPUT str
    move.l %A0,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_GETSTR(%A0),%A0
    move.l \str,-(%SP)
    jsr (%A0)
    addq.l #4,%SP
    move.l (%SP)+,%A0
.endm
|------------------------------------------------------------------------------
|  System function macros
|
|  Suspend a task for the specified number of clock ticks
|
.macro SLEEP ticks
    move.l \ticks,-(%SP)
    move.w #SYS_SLEEP,-(%SP)
    trap #0
    addq.l #6,%SP
.endm


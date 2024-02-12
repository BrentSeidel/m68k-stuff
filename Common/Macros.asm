#-----------------------------------------------------------
# Title      : Macros.S68
# Written by : Brent Seidel
# Date       : 2-Feb-2024
# Description: A collection of macros and definitions
#-----------------------------------------------------------
#
#  ***  This is not a stand-alone file.  It gets included into
#  ***  other assembly language programs.
#
#
#  Constants for ASCII characters
#
    .equ BELL,  7      |  Ring the bell
    .equ BS,    8      |  Back space
    .equ TAB,   9      |  Horizontal tab
    .equ LF,   10      |  Line feed
    .equ CR,   13      |  Carriage return
    .equ SP,   32      |  Space
    .equ LT,   60      |  Less than '<'
    .equ GT,   62      |  Greater than '>'
    .equ DEL, 127      |  Delete
#
#  Strings are a data structure as follows:
#  Word: Max size of string
#  Word: Current size of string
#  Bytes: Text of the string
#
#  Macros
#
#  Define space for a string.  The first argument is
#  the label, the second is the maximum size.
#
.macro STRING label,size
    .align 2
\label: .hword \size
    .hword 0
    .space \size,0
.endm
#
#  Define a string with text.  The first argument is
#  the label.  The second is the text.  Enclose the text
#  with <>.  Note that the text also needs to be surrounded
#  by ''.  The text can also include bytes.
#
.macro TEXT label,string
    .align 2
\label: .hword 0f-\label-4
    .hword 0f-\label-4
    .ascii "\string"
0:
.endm
#
#  Convert a number to a string.  Called as
#   NUMSTR.x <number>,<string>,<flags>,<base>
#       <base> is the conversion base and can be 8, 10, or 16
#
.macro NUMSTR_B num,str,flag,base
    MOVE.L %A0,-(%SP)
    MOVE.L #LIBTBL,%A0
    MOVE.W \flag,-(%SP)
    MOVE.L \str,-(%SP)    |  String
    MOVE.L \num,-(%SP)    |  Number
    .if \base-8
    .else
      JSR (%A0)
    .endif
    .if \base-10
    .else
      JSR 4(%A0)
    .endif
    .if \base-16
    .else
      JSR 8(%A0)
    .endif
    ADDQ.L #8,%SP       |  Clean 10 bytes off the stack.
    ADDQ.L #2,%SP       |  Max ADDQ is 8
    MOVE.L (%SP)+,%A0
.endm
.macro NUMSTR_W num,str,flag,base
    MOVE.L %A0,-(SP)
    MOVE.L #LIBTBL,%A0
    MOVE.W \flag+1,-(%SP)
    MOVE.L \str,-(%SP)    |  String
    MOVE.L \num,-(%SP)    |  Number
    .if \base-8
    .else
      JSR (%A0)
    .endif
    .if \base-10
    .else
      JSR 4(%A0)
    .endif
    .if \base-16
    .else
      JSR 8(%A0)
    .endif
    ADDQ.L #8,%SP       |  Clean 10 bytes off the stack.
    ADDQ.L #2,%SP       |  Max ADDQ is 8
    MOVE.L (%SP)+,%A0
.endm
.macro NUMSTR_L num,str,flag,base
    MOVE.L %A0,-(%SP)
    MOVE.L #LIBTBL,%A0
    MOVE.W \flag+2,-(%SP)
    MOVE.L \str,-(%SP)    |  String
    MOVE.L \num,-(%SP)    |  Number
    .if \base-8
    .else
      JSR (%A0)
    .endif
    .if \base-10
    .else
      JSR 4(%A0)
    .endif
    .if \base-16
    .else
      JSR 8(%A0)
    .endif
    ADDQ.L #8,%SP       |  Clean 10 bytes off the stack.
    ADDQ.L #2,%SP       |  Max ADDQ is 8
    MOVE.L (%SP)+,%A0
.endm
#
#  Get the max size of a string.
#   STRMAX <string>,<destination>
#
.macro STRMAX str,dest
    MOVE.L %A0,-(%SP)    |  Save A0 since it is used
    MOVE.L \str,%A0
    MOVE.W (%A0),\dest
    MOVE.L (%SP)+,%A0
.endm
#
#  Get the current length of a string
#   STRLEN <string>,<destination>
#
.macro STRLEN str,dest
    MOVE.L %A0,-(SP)    |  Save A0 since it is used
    MOVE.L \str,%A0
    MOVE.W 2(%A0),\dest
    MOVE.L (%SP)+,%A0
.endm
#
#  Print a string
#
.macro PRINT str
    MOVE.L \str,-(%SP)
    MOVE.W #1,-(%SP)    |  Code to print a string
    TRAP #0
    ADDQ.L #6,%SP
.endm
#
#  Get a string
#
.macro INPUT str
    MOVE.L \str,-(%SP)
    MOVE.W #2,-(%SP)    |  Code to get a string
    TRAP #0
    ADDQ.L #6,%SP
.endm
#
#  Suspend a task for the specified number of clock ticks
#
.macro SLEEP ticks
    MOVE.L \ticks,-(%SP)
    MOVE.W #16,-(%SP)
    TRAP #0
    ADDQ.L #6,%SP
.endm


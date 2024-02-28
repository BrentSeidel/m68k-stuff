|------------------------------------------------------------------------------
| Title      : Macros.S68
| Written by : Brent Seidel
| Date       : 2-Feb-2024
| Description: A collection of macros and definitions
|------------------------------------------------------------------------------
.nolist
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
|   NUMSTR_B <number>,<string>,<flags>,<base>
|   NUMSTR_W <number>,<string>,<flags>,<base>
|   NUMSTR_L <number>,<string>,<flags>,<base>
|       <base> is the conversion base and can be 8, 10, or 16
|  Note that A0 cannot be used as a destination since it's saved and restored
|
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
    jsr (%A0)
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
    jsr (%A0)
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
    jsr (%A0)
    addq.l #8,%SP       |  Clean 10 bytes off the stack.
    addq.l #2,%SP       |  Max ADDQ is 8
    move.l (%SP)+,%A0
.endm
|
|  Convert string to number.  Called as
|   STRNUM <string>,<number>,<base>
|
.macro STRNUM str,num,base
    move.l %A0,-%(SP)
    move.l #LIBTBL,%A0
    move.l \str,-(%SP)
    .if \base-8
    .else
      move.l LIB_STROCT(%A0),%A0
    .endif
    .if \base-10
    .else
      move.l LIB_STRDEC(%A0),%A0
    .endif
    .if \base-16
    .else
      move.l LIB_STRHEX(%A0),%A0
    .endif
    jsr (%A0)
    move.l (%SP)+,\num
    move.l (%SP)+,%A0
.endm
|------------------------------------------------------------------------------
|  String manipulation macros
|
|  Get the max size of a string.
|   STRMAX <string>,<destination>
|  Note that A0 cannot be used as a destination since it's savedd and restored
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
|  Note that A0 cannot be used as a destination since it's saved and restored
|
.macro STRLEN str,dest
    move.l %A0,-(SP)    |  Save A0 since it is used
    move.l \str,%A0
    move.w 2(%A0),\dest
    move.l (%SP)+,%A0
.endm
|
|  Find a character in a string
|   FINDCHAR <string to search>,<character to find>,<destination for position>
|  Note that A0 cannot be used as a destination since it's saved and restored
|
.macro FINDCAHR str,char,pos
    move.l %A0,-(%SP)
    move.l \str,-(%SP)
    move.l \char,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_FINDCHR(%A0),%A0
    jsr (%A0)
    move.l (%SP)+,\pos
    addq.l #4,%SP
    move.l (%SP)+,%A0
.endm
|
|  Fill a string with a specified count of characters.
|   FILLCHAR <string>,<character>,<count of characters>
|  Note that A0 cannot be used as a destination since it's saved and restored
|
.macro FILLCHAR str,count,char
    move.l %A0,-(%SP)
    move.l \str,-(%SP)
    move.w \count,-(%SP)
    move.w \char,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_FILLCHR(%A0),%A0
    jsr (%A0)
    addq.l #8,%SP
    move.l (%SP)+,%A0
.endm
|
|  Return the character at the specified position in a string
|   CHARAT <string>,<position>,<character>
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro CHAR_AT str,pos,char
    move.l %A0,-(%SP)
    move.l \str,-(%SP)
    move.w \pos,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_CHARAT(%A0),%A0
    jsr (%A0)
    move.w (%SP)+,\char
    addq.l #4,%SP
    move.l (%SP)+,%A0
.endm
|
|  Macros for trimming leading/trailing zeros and spaces
|   STR_TRIM <type>,<string>
|  where type is one of TS,TZ,LS,LZ
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro STR_TRIM type,str
    move.l %A0,-(%SP)
    move.l \str,-(%SP)
    .ifc TS,\type
      move.l #LIBTBL,%A0
      move.l LIB_TRIMTS(%A0),%A0
      jsr (%A0)
    .endif
    .ifc TZ,\type
      move.l #LIBTBL,%A0
      move.l LIB_TRIMTZ(%A0),%A0
      jsr (%A0)
    .endif
    .ifc LS,\type
      move.l #LIBTBL,%A0
      move.l LIB_TRIMLS(%A0),%A0
      jsr (%A0)
    .endif
    .ifc LZ,\type
      move.l #LIBTBL,%A0
      move.l LIB_TRIMLZ(%A0),%A0
      jsr (%A0)
    .endif
    addq.l #4,%SP
    move.l (%SP)+,%A0
.endm
|
|  Macro to convert string to uppercase
|   STR_UPCASE <str>
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro STR_UPCASE str
    move.l %A0,-(%SP)
    move.l \str,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_UPCASE(%A0),%A0
    jsr (%A0)
    addq.l #4,%SP
    move.l (%SP)+,%A0
.endm
|
|  Macro to convert string to lowercase
|   STR_LOCASE <str>
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro STR_LOCASE str
    move.l %A0,-(%SP)
    move.l \str,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_LOCASE(%A0),%A0
    jsr (%A0)
    addq.l #4,%SP
    move.l (%SP)+,%A0
.endm
|
|  Macro to copy a string
|   STR_COPY <source>,<destination>
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro STR_COPY source,destination
    move.l %A0,-(%SP)
    move.l \source,-(%SP)
    move.l \destination,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_STRCP(%A0),%A0
    jsr (%A0)
    addq.l #8,%SP
    move.l (%SP)+,%A0
.endm
|
|  Macro to append a string to another
|   STR_APPEND <source>,<destination>
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro STR_APPEND source,destination
    move.l %A0,-(%SP)
    move.l \source,-(%SP)
    move.l \destination,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_STRAPP(%A0),%A0
    jsr (%A0)
    addq.l #8,%SP
    move.l (%SP)+,%A0
.endm
|
|  Macro to extract a substring from a string.
|  SRT_SUBSTR <source>,<destination>,<start>,<count>
|  Note that A0 cannot be used as a destination since it's saved and restored
.macro STR_SUBSTR source,dest,start,count
    move.l %A0,-(%SP)
    move.l \source,-(%SP)
    move.l \dest,-(%SP)
    move.w \start,-(%SP)
    move.w \count,-(%SP)
    move.l #LIBTBL,%A0
    move.l LIB_SUBSTR(%A0),%A0
    jsr (%A0)
    addq.l #6,%SP
    addq.l #6,%SP
    move.l (%SP)+,%A0
.endm
|
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
.list


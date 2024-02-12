|-----------------------------------------------------------
| Title      : Library Routines
| Written by : Brent Seidel
| Date       : 4-Feb-2024
| Description: Common library routines for OS and users
|-----------------------------------------------------------
    .include "../Common/Macros.asm"
|==============================================================================
|  Library data section.  Common data and data for library routines go here.
|  Note that all of this data should be readonly.
|
    .section LIB_DATA,#alloc
    TEXT NEWLINE,"\r\n"
    .global NEWLINE
NUMTBL:                 |  Table for converting between numbers and ASCII strings
    .ascii "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ"
|==============================================================================
|  Library section.  Common routines would go here.
|
    .section LIB_SECT,#execinstr,#alloc
|
|  Jump table for library routines.
LIBTBL:
    .global LIBTBL
    DC.L OCTSTR
    DC.L DECSTR
    DC.L HEXSTR
|
|------------------------------------------------------------------------------
|  Convert numbers to string
|  Inputs: Number to convert (long)
|          Address of destination string (long)
|          Conversion flags (word)
|   Conversion flags:
|       0-1: Size (00-Byte, 01-Word, 10-Long)
|         2: Sign (0-unsigned, 1-signed)
|         3: Lead (0-no leading characters, 1-leading zeros)
|         4: Negative (internal use only)
|       5-7: Unused
|      8-15: Unused
|  Stack:
|    16(A6) - Flags (Word)
|    12(A6) - Address of destination (long)
|     8(A6) - Number to convert (long)
|     4(A6) - Old PC (long)
|      (A6) - Old A6
|   -18(A6) - Conversion buffer
|   Registers:
|       D0 - Number to convert
|       D1 - Conversion flags
|       D2 - Scratch
|       D3 - Max size of result
|       D4 - Fill character
|       A0 - Address of buffer
|       A1 - Index into conversion table
|
|  Convert a number to an octal string
|
OCTSTR:
    LINK %A6,#-20
    MOVEM.L %D0-%D3/%A0-%A1,-(%SP)
    MOVE.L 8(%A6),%D0    |  Number to convert
    MOVE.W 16(%A6),%D1   |  Conversion flags
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
OCT.SIZE:
    MOVE.L %D1,%D2       |  Get size field
    AND.B #3,%D2
    BNE OCT.N1
    AND.L #0xFF,%D0      |  Byte size
    MOVE #3,%D3          |  Number of characters
    BTST #2,%D1          |  Check if signed
    BEQ OCT.N3
    TST.B %D0            |  Check if positive or negative
    BPL OCT.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.B %D0
    BRA OCT.N3
OCT.N1:
    SUBQ.B #1,%D2
    BNE OCT.N2
    AND.L #0xFFFF,%D0    |  Word size
    MOVE #6,%D3
    BTST #2,%D1          |  Check if signed
    BEQ OCT.N3
    TST.W %D0            |  Check if positive or negative
    BPL OCT.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.W %D0
    BRA OCT.N3
OCT.N2:
    MOVE #11,%D3         |  Long size
    BTST #2,%D1          |  Check if signed
    BEQ OCT.N3
    TST.L %D0            |  Check if positive or negative
    BPL OCT.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.L %D0
OCT.N3:
    |
    |  Conversion loop
    |
OCT.L1:
    MOVE.L %D0,%D2
    AND.L #7,%D2
    MOVE.L %D2,%A1
    MOVE.B NUMTBL(%A1),-(%A0)
    LSR.L #3,%D0
    BNE OCT.L2
    BTST #3,%D1
    BEQ OCT.L3
OCT.L2:
    DBF %D3,OCT.L1
    BRA OCT.L4
OCT.L3:
    SUBQ.B #1,%D3
OCT.L4:
    |
    |  Check for adding negative sign
    |
    BTST #2,%D1
    BEQ OCT.D1            |  Not signed
    BTST #4,%D1
    BEQ OCT.D1            |  Not negative
    MOVE.B #'-',-(%A0)
    |
    |  Move to destination
    |
OCT.D1:
    MOVE.L %A0,%D2       |  Pointer to start of string
    MOVE.L %A0,%A1
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    MOVE.L %A0,%D3
    SUB.L %D2,%D3        |  Length of converted string
    MOVE.L 12(%A6),%A0   |  Address of destination
    MOVE.W (%A0),%D2     |  Max size of destination
    CMP.W %D3,%D2
    BGE OCT.D2
    MOVE.W %D2,%D3
OCT.D2:
    MOVE.W %D3,2(%A0)   |  Set length of destination
    SUBQ.L #1,%D3
    ADDQ.L #4,%A0       |  Point to start of text part of string
OCT.D3:
    MOVE.B (%A1)+,(%A0)+
    DBF %D3,OCT.D3
    |
    |  Cleanup and return
    |
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A1
    UNLK %A6
    RTS
|
|  Convert a number to a decimal string
|
DECSTR:
    LINK %A6,#-20
    MOVEM.L %D0-%D3/%A0-%A1,-(%SP)
    MOVE.L 8(%A6),%D0    |  Number to convert
    MOVE.W 16(%A6),%D1   |  Conversion flags
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
DEC.SIZE:
    MOVE.L %D1,%D2       |  Get size field
    AND.B #3,%D2
    BNE DEC.N1
    AND.L #0xFF,%D0      |  Byte size
    MOVE #3,%D3          |  Number of characters
    BTST #2,%D1          |  Check if signed
    BEQ DEC.N3
    TST.B %D0            |  Check if positive or negative
    BPL DEC.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.B %D0
    BRA DEC.N3
DEC.N1:
    SUBQ.B #1,%D2
    BNE DEC.N2
    AND.L #0xFFFF,%D0    |  Word size
    MOVE #5,%D3
    BTST #2,%D1          |  Check if signed
    BEQ DEC.N3
    TST.W %D0            |  Check if positive or negative
    BPL DEC.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.W %D0
    BRA DEC.N3
DEC.N2:
    MOVE #10,%D3         |  Long size
    BTST #2,%D1          |  Check if signed
    BEQ DEC.N3
    TST.L %D0            |  Check if positive or negative
    BPL DEC.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.L %D0
DEC.N3:
    CLR.L %D2
    MOVE.L %D2,%A1       |  Can't directly clear A registers.
    |
    |  Conversion loop.  Some updates will be needed here
    |  since the DIVU instruction only allows a 16 bit quotient.
    |  This may cause overflow for 32 bit numbers.
    |
DEC.L1:
    MOVE.L %D0,%D2
    DIVU #10,%D2         |  Quotient is in lower 16 bits, remainder
    SWAP %D2
    MOVE.W %D2,%A1       |  Get remainder
    MOVE.B NUMTBL(%A1),-(%A0)
    CLR.W %D2
    SWAP %D2
    MOVE.L %D2,%D0       |  Put quotient back into D0
    BNE DEC.L2
    BTST #3,%D1
    BEQ DEC.L3
DEC.L2:
    DBF %D3,DEC.L1
    BRA DEC.L4
DEC.L3:
    SUBQ.B #1,%D3
DEC.L4:
    |
    |  Check for adding negative sign
    |
    BTST #2,%D1
    BEQ DEC.D1            |  Not signed
    BTST #4,%D1
    BEQ DEC.D1            |  Not negative
    MOVE.B #'-',-(%A0)
    |
    |  Move to destination
    |
DEC.D1:
    MOVE.L %A0,%D2       |  Pointer to start of string
    MOVE.L %A0,%A1
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    MOVE.L %A0,%D3
    SUB.L %D2,%D3        |  Length of converted string
    MOVE.L 12(%A6),%A0   |  Address of destination
    MOVE.W (%A0),%D2     |  Max size of destination
    CMP.W %D3,%D2
    BGE DEC.D2
    MOVE.W %D2,%D3
DEC.D2:
    MOVE.W %D3, 2(%A0)   |  Set length of destination
    SUBQ.L #1,%D3
    ADDQ.L #4,%A0       |  Point to start of text part of string
DEC.D3:
    MOVE.B (%A1)+,(%A0)+
    DBF %D3,DEC.D3
    |
    |  Cleanup and return
    |
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A1
    UNLK %A6
    RTS
|
|  Convert a number to an hexidecimal string
|
HEXSTR:
    LINK %A6,#-20
    MOVEM.L %D0-%D3/%A0-%A1,-(%SP)
    MOVE.L 8(%A6),%D0    |  Number to convert
    MOVE.W 16(%A6),%D1   |  Conversion flags
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    |
    |  Check conversion size
    |
HEX.SIZE:
    MOVE.L %D1,%D2       |  Get size field
    AND.B #3,%D2
    BNE HEX.N1
    AND.L #0xFF,%D0      |  Byte size
    MOVE #2,%D3          |  Number of characters
    BTST #2,%D1          |  Check if signed
    BEQ HEX.N3
    TST.B %D0            |  Check if positive or negative
    BPL HEX.N3
    BSET #4,%D1          |  Set flag for negative
    NEG.B %D0
    BRA HEX.N3
HEX.N1:
    SUBQ.B #1,%D2
    BNE HEX.N2
    AND.L #0xFFFF,%D0   |  Word size
    MOVE #4,%D3
    BTST #2,%D1         |  Check if signed
    BEQ HEX.N3
    TST.W %D0           |  Check if positive or negative
    BPL HEX.N3
    BSET #4,%D1         |  Set flag for negative
    NEG.W %D0
    BRA HEX.N3
HEX.N2:
    MOVE #8,%D3         |  Long size
    BTST #2,%D1         |  Check if signed
    BEQ HEX.N3
    TST.L %D0           |  Check if positive or negative
    BPL HEX.N3
    BSET #4,%D1         |  Set flag for negative
    NEG.L %D0
HEX.N3:
    |
    |  Conversion loop
    |
HEX.L1:
    MOVE.L %D0,%D2
    AND.L #15,%D2
    MOVE.L %D2,%A1
    MOVE.B NUMTBL(%A1),-(%A0)
    LSR.L #4,%D0
    BNE HEX.L2
    BTST #3,%D1
    BEQ HEX.L3
HEX.L2:
    DBF %D3,HEX.L1
    BRA HEX.L4
HEX.L3:
    SUBQ.B #1,%D3
HEX.L4:
    |
    |  Check for adding negative sign
    |
    BTST #2,%D1
    BEQ HEX.D1            |  Not signed
    BTST #4,%D1
    BEQ HEX.D1            |  Not negative
    MOVE.B #'-',-(%A0)
    |
    |  Move to destination
    |
HEX.D1:
    MOVE.L %A0,%D2       |  Pointer to start of string
    MOVE.L %A0,%A1
    LEA -2(%A6),%A0      |  Address of end of conversion buffer
    MOVE.L %A0,%D3
    SUB.L %D2,%D3        |  Length of converted string
    MOVE.L 12(%A6),%A0   |  Address of destination
    MOVE.W (%A0),%D2     |  Max size of destination
    CMP.W %D3,%D2
    BGE HEX.D2
    MOVE.W %D2,%D3
HEX.D2:
    MOVE.W %D3, 2(%A0)   |  Set length of destination
    SUBQ.L #1,%D3
    ADDQ.L #4,%A0       |  Point to start of text part of string
HEX.D3:
    MOVE.B (%A1)+,(%A0)+
    DBF %D3,HEX.D3
    |
    |  Cleanup and return
    |
    MOVEM.L (%SP)+,%D0-%D3/%A0-%A1
    UNLK %A6
    RTS
|------------------------------------------------------------------------------


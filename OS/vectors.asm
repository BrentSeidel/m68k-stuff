|-----------------------------------------------------------
| Title      : Vectors
| Written by : Brent Seidel
| Date       : 15-Feb-2024
| Description: Exception Vector table for simulated 68000
|-----------------------------------------------------------
    .title Exception Vector table
|==============================================================================
|  Exception Vectors
|
    .section VSECT,#write,#alloc
    .long NULLVEC
    .long SUPSTK
    .rept 0x100-2       |  Can't use .fill with a relocatable symbol
    .long NULLVEC       |  Initialize all vectors to point to uninialized
    .endr               |  vector handler.  These may be updated later.

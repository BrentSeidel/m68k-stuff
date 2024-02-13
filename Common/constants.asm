|
|  Common constants for both OS and user tasks
|
||
|  Constants for ASCII characters
|
    .equ BELL,  7      |  Ring the bell
    .equ BS,    8      |  Back space
    .equ TAB,   9      |  Horizontal tab
    .equ LF,   10      |  Line feed
    .equ CR,   13      |  Carriage return
    .equ SP,   32      |  Space
    .equ LT,   60      |  Less than '<'
    .equ GT,   62      |  Greater than '>'
    .equ DEL, 127      |  Delete
|
|  Codes for system calls
|    0 - Exit.  Exits the program and does not return
|    1 - Put string.  Prints the string referenced in the argument
|    2 - Get string.  Gets text to the string referenced in the argument
|   16 - Sleep for the number of clock ticks in the argument
|   64 - Shutdown
|
    .equ SYS_EXIT, 0    |  End the current task
    .equ SYS_PUTS, 1    |  Send a string to the console
    .equ SYS_GETS, 2    |  Get a string from the console
    .equ SYS_SLEEP, 16  |  Suspend current task for a number of clock ticks
    .equ SYS_SUTDOWN, 64 |  Shutdown the system
|
|  Library entry point
|
    .equ LIBTBL,0x4000
|

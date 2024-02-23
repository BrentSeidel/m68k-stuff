# Assembly Language Stuff for the M68000 CPU

Now that I have a [68000 simulator](https://github.com/BrentSeidel/Sim-CPU)
running, I needed some software for it.  So, I decided to try writing a
simple multitasking operating system that can run a few tasks.  The first
goal is to have something that will blink the lights on the [Pi Mainframe](https://github.com/BrentSeidel/Sim-CPU)
in interesting patterns.  The second goal is to learn a bit about how
to write an operating system kernel and provide services.  The third
goal is maybe to have something uself.

## Current status
### Multitasking is Working
Currently three tasks are defined:
1. The background null tasks which runs when all other tasks are blocked.  It
is part of the operating system.
2. A task used to test various routines
3. A task that just prints Fibonacci numbers that always runs.  It provides
an obvious indication if the systems stalls.

Tasks can be suspended for sleeping or waiting for input to occur.

Tasks are scheduled in a round-robin fashion on each clock tick, or whenever
a task gets suspended.  The null task is only scheduled when no other task
can be run.

### Working on the Library
The system library provides a bunch of services to both the operating system
and the user tasks.  It provides things like:
* String to number (and vice-versa) conversions for octal, decimal, and
hexidecimal for byte, word, and long number.
* String input
* String functions to assist in parsing string (in work)

## Future Plans
Future plans include the following (subject to change)
* Implement mass storage with a filesystem (possibilities include MS-DOS,
CP/M, Minix, or other).
* Add a CLI to the library

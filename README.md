# Assembly Language Stuff for the M68000 CPU

Now that I have a [68000 simulator](https://github.com/BrentSeidel/Sim-CPU)
running, I needed some software for it.  So, I decided to try writing a
simple multitasking operating system that can run a few tasks.  The first
goal is to have something that will blink the lights on the [Pi Mainframe](https://github.com/BrentSeidel/Sim-CPU)
in interesting patterns.  The second goal is to learn a bit about how
to write an operating system kernel and provide services.  The third
goal is maybe to have something uself.

## Background
Way back in the 1980s, I first encountered a multiuser operating system
in the form of RSTS/E and later VAX/VMS.  I had a dream of writing my own
operating system (BOS for Brent's Operating Systems).  This didn't happen.
However, some ideas and things that I've picked up over the years may
show up here.

Currently, I am calling this OS-68000 (or OS68k for short) until I can
come up with a better name.

## Current status
### Multitasking is Working
Currently five tasks are defined:
1. The background null tasks which runs when all other tasks are blocked.  It
is part of the operating system.
2. A task used to test various routines.
3. A task that just prints Fibonacci numbers that always runs.  It provides
an obvious indication if the systems stalls.
4. A task that provides a system status indication.
5. Another Fibonacci task to load the system.

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
* String functions to assist in parsing string
* A basic command line interpreter that is shared between all tasks

## Future Plans
Future plans include the following (subject to change)
* Implement mass storage with a filesystem (possibilities include MS-DOS,
CP/M, Minix, or other).
* Add message passing to the OS kernel.
* Add a buffer pool.  This will probably be needed to support other things.

### Hardware
I'd like to design and build a 680x0 based computer.  This probably won't
happen due to the time and cost required, but would be an interesting
project...

## License

This project is licensed using GPL 3.0+.  I don't expect anyone to actually
be interested in using this commercially, but if you wish to use this with
a different license, contact the author (me).

I expect this to be of most use for people interested in operating systems.

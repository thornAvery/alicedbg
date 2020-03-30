# Alice Debugger Project

**Please note that this is still is very early development!**

The alicedbg project aims to be an easy-to-use, simple debugger, object dumper,
and profiler.

_Why not just use GDB?_ One might ask.

_Why not make one myself?_ I asked myself.

Personal Goals:

- [ ] Make a usable Text UI close to a professional debugger
- [ ] Debug an application on my Raspberry Pi 3B+ and my Purism Librem 5
- [ ] Disassemble ARM instructions with the Intel syntax
- [ ] Embed, as a library, into an embedded HTTP server to provide a local WebUI
- [ ] Make a disassembly as a service

## Support Matrix

### Debugger Support

| Platform | OS | CRT | Debugging core |
|---|---|---|:-:|
| x86 | Windows 7 and up | Microsoft (+WOW64) | ✔️ |
| | Linux | Glibc | ✔️* |
| ARM | Windows 10 | Microsoft |  |
| | Linux | Glibc | Planned! |

\* Currently unstable

### Disassembler Support

| Platform | ~% | Extensions | Notes |
|---|---|---|---|
| x86-32 | 60 | x87, MMX, SSE (2, 3, 4.1, 4.2, 4a), AES, SHA, VMX, SVM, SMX, WAITPKG | Still adding |
| x86-64 | 0 | | Waiting on x86-32 |
| arm-t32 | 0 | | Waiting on x86-64 |
| arm-a32 | 0 | | Waiting on x86-64 |
| arm-a64 | 0 | | Waiting on x86-64 |
| riscv-32 | 1 | RVC 2.0, RV32I 2.1 | |
| webasm | 0 | | Planned |

### Object Dump Support

| Type | ~% | Extensions | Notes |
|---|---|---|---|
| Binary | 50 | Far from perfect |
| MZ | 0 | | |
| LE | 0 | | |
| NE | 0 | | |
| PE | 15 | PE32-ROM, PE32, PE32+ | |
| ELF | 0 | | |
| Mach-O | 0 | | |

## FAQ

### Why D?

I love the D programming language for so many reason I could go on forever
talking about it, so I'll just say that I love it for its practical approach.

### What about the GC?

The project is compiled with the BetterC mode, so no druntime and no GC. The
functions are also marked with a C extern so that hopefully C programs (or
others) use its functions as a library (static or dynamically).

# Usage

The command-line interface processes items from left to right and was inspired
from the ffmpeg project (-option value).

The default operating mode is the debugger with the Text UI.

| Option | Possible values | Default | Description |
|---|---|---|---|
| `-ui` | `tui`, `loop`, `tcp-json` | `tui` | Debugger user interface |
| `-dstyle` | `intel`, `nasm`, `att` | Platform dependant | (Disassembler) Syntax style |
| `-mode` | `debugger`, `dump`, `profile` | `debugger` | Operating mode |

### UI: tui

The Text UI is currently in development.

### UI: loop

The loop UI is the simplest implementation, featuring simple output on
exceptions. On an exception, a prompt asks if you wish to continue,
step, or quit.

```
-------------------------------------
* EXCEPTION #0: BREAKPOINT (0x80000003)
* PID=1768 TID=9288
> 7FF8B9FF2DBC / cc / int3
     RIP=00007ff8b9ff2dbd  RFLAGS=00000246
     RAX=0000000000000000     RBX=0000000000000010
     RCX=00007ff8b9fbfc04     RDX=0000000000000000
     RSP=000000445dcff0a0     RBP=0000000000000000
     RSI=00007ff8ba04d100     RDI=000000445dbaf000

Action [S=Step,C=Continue,Q=Quit]
```

Which features the exception counter, process ID, thread ID, short exception
messsage, OS-specific code, memory location, a brief disassembly (when
available), and register list (when available).

# Build Instructions

## With DUB

DUB often comes with a D compiler and is recommended to build the project. A
compiler can be chosen with the `--compiler=` option. I try to support DMD,
GDC, and LDC as much as possible.

Do note that the `betterC` mode is activated for normal builds and
documentation. Unittesting (and the rest) uses the druntime library so any
Phobos functions may be used.

| Build type | Command |
|---|---|
| Debug | `dub build` |
| Release | `dub build -b release-nobounds` |
| AFL Fuzz | `dub build -b afl` |

## With make

Planned.

## Manually

It's still possible to compile the project by referencing every source files.
The `-betterC` switch is optional, but recommended.

## Notes on fuzzing
In order to preform a fuzz, ldc version 1.0.0 or newer and AFL 2.50 or newer
are required, additionally the LLVM version that ldc and the library
`afl-llvm-pass.so` have been built with must be the same.

To fuzz, export the environment variable `AFL_ROOT` to the location where
`afl-llvm-pass.so` is located, then build with `dub -d afl`.

Then create two directories, `findings` and `testcases`, after that populate
`testcases` with files you wish to test with. It takes the files in this
directory and applies various transformations to them in order to explore new
code paths and attempt to find crashes, so it's important that all of these
input files be valid and correct.

After that, to fuzz, simply run
`afl-fuzz -i testcases -o findings ./alicedbg --DRT-trapExceptions=0 <OPTIONS> @@`
where `<OPTIONS>` are the various alicedbg options you wish to test with.

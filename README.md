# Li8Z

Hey, this is **Li8Z**, an attempt at implementing a Chip-8 emulator in Zig. I
was inspired to try this project thanks to my
[buddy](https://github.com/kevin-nel). The project will be heavily guided by
this beautiful [guide](https://github.com/aquova/chip8-book). When I feel the
project is complete I will tag a release, until then thank you for reading and
hope you are well.

The project is in a decent place right now, as you can load roms and play them.
Audio and controls work, with a few games experiencing some issues. For reference
this is tictactoe running on the emulator.

![tictactoe](./public/game_window.png)

## Building

Though I tried to keep the project as zig only as possible, due to the immaturity
of the language I had to rely a bit on some C libraries, in particular
[raylib](https://www.raylib.com/) and [miniaudio](https://miniaud.io/) (through
a zig wrapper by
[zig-gamedev](https://github.com/zig-gamedev/zig-gamedev/tree/main/libs/zaudio)).

The `bootstrap.sh` and `boostrap.ps1` scripts are provided to pull the correct
packages and use them appropriately for the project. As builds are often tried
against the latest unstable version of zig, raylib is now built by the
bootstrapper using `cmake` and `ninja` as they guarantee reliability during a
tumultuous zig development cycle. After the script succeeds, you can build the

```bash
zig build --release=safe
```

The built binary can then be found in `zig-out/bin/li8z` and requires an
argument that is the path to the rom you would like to play. For testing you can
simply run:

```bash
zig build run -- /path/to/rom
```

In order to run the emulator without interacting with the binary yourself. The
zig build system does have an install option, although it is at your own
discretion as the emulator is still a work in progress.

The bug present that affected some games when building in release mode have
been solved, so you may build in your preferred release mode with confidence.
The web port of the emulator is still largely incomplete and the use of a
typescript backend for the final implementation has not been finalized.

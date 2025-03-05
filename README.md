# Li8Z
![logo][./public/li8z-icon.png]

Hey, this is **Li8Z**, an attempt at implementing a Chip-8 emulator in Zig. I
was inspired to try this project thanks to my
[buddy](https://github.com/kevontheweb). The project will be heavily guided by
this beautiful [guide](https://github.com/aquova/chip8-book).

The project is in a decent place right now, as you can load roms and play them.
Audio and controls work, with a few games experiencing some issues. For reference
this is tictactoe running on the emulator.

![tictactoe](./public/game_window.png)

## Building

Though I tried to keep the project as zig only as possible, due to the immaturity
of the language I had to rely a bit on some C libraries, in particular
[raylib](https://www.raylib.com/), [raygui](https://github.com/raysan5/raygui), [tinyfiledialogs](http://git.code.sf.net/p/tinyfiledialogs/code) and [miniaudio](https://miniaud.io/) (through
a zig wrapper by
[zig-gamedev](https://github.com/zig-gamedev/zig-gamedev/tree/main/libs/zaudio)).

### Desktop Version

#### Dependencies

Before running the bootstrap scripts, you'll need to install some prerequisites:

**Windows:**
- Git: Download from https://git-scm.com/download/win
- CMake: Download from https://cmake.org/download/
- Ninja: Install via `winget install Ninja-build.Ninja` or download from GitHub releases
- Visual Studio Build Tools (or full Visual Studio) with C++ support

**Linux:**
```bash
# Debian/Ubuntu
sudo apt-get install git cmake ninja-build gcc

# Fedora
sudo dnf install git cmake ninja-build gcc

# Arch
sudo pacman -S git cmake ninja gcc
```

**macOS:**
```bash
# Using Homebrew
brew install git cmake ninja
```

For additional dependencies required by raylib (like X11 development libraries on Linux), please refer to the [raylib wiki](https://github.com/raysan5/raylib/wiki).

The `bootstrap.sh` and `boostrap.ps1` scripts are provided to pull the correct
packages and use them appropriately for the project. As builds are often tried
against the latest unstable version of zig (currently v0.14.0-dev.3445+), raylib is now built by the
bootstrapper using `cmake` and `ninja` as they guarantee reliability during a
tumultuous zig development cycle. After the script succeeds, you can build the
emulator with:

```bash
zig build --release=safe
```

The built binary can be found in `zig-out/bin/li8z`. You can run the desktop version with:

```bash
zig build desktop
```

This will launch the emulator with a user interface where you can:
1. Select a ROM file using the file picker
2. Start the game using the Start button

### Web Version

The emulator can also be run in a web browser using WebAssembly. Requirements:
- Python 3.13+ (for the development server)
- Modern web browser with WebAssembly support

To build and run the web version:

```bash
# Build the WebAssembly module
zig build wasm

# Start the development server
./serve.sh

# Visit http://localhost:8080/web/ in your browser
```

## Controls

Both desktop and web versions use the same keyboard layout:
```
1 2 3 4  →  1 2 3 C
Q W E R  →  4 5 6 D
A S D F  →  7 8 9 E
Z X C V  →  A 0 B F
```

## Status

The bug present that affected some games when building in release mode has
been solved, so you may build in your preferred release mode with confidence.
The web port of the emulator is now functional with full support for:
- ROM loading
- Display output
- Keyboard input
- Sound (at 5% volume by default)

For roms to play I recommend checking out [here](https://github.com/kripod/chip8-roms), there's a nice collection of classics as well as some general programs to test out the emulator.

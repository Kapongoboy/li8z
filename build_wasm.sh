#!/bin/bash

# Compile C code to WASM using Emscripten
emcc src/backend.c \
    -o web/li8z.js \
    -s WASM=1 \
    -s EXPORTED_FUNCTIONS='["_createEmulator", "_loadROM", "_emuTick", "_emuTickTimers", "_emuKeypress", "_getScreenPtr"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s "ENVIRONMENT='web'" \
    -O2 
// Memory management helpers
let emulator;
let screenArray;

// Initialize the WASM module
async function initWasm() {
    try {
        // Wait for Emscripten to initialize
        await new Promise(resolve => {
            Module.onRuntimeInitialized = () => resolve();
        });

        // Create wrapper functions
        const api = {
            createEmulator: Module.cwrap('createEmulator', 'number', []),
            loadROM: Module.cwrap('loadROM', null, ['number', 'array', 'number']),
            emuTick: Module.cwrap('emuTick', null, ['number']),
            emuTickTimers: Module.cwrap('emuTickTimers', 'boolean', ['number']),
            emuKeypress: Module.cwrap('emuKeypress', null, ['number', 'number', 'boolean']),
            getScreenPtr: Module.cwrap('getScreenPtr', 'number', ['number']),
        };

        // Create emulator instance
        emulator = api.createEmulator();
        
        // Get screen buffer pointer
        const screenPtr = api.getScreenPtr(emulator);
        screenArray = new Uint8Array(Module.HEAPU8.buffer, screenPtr, 64 * 32);
        
        // Store API for later use
        window.Li8zAPI = api;
        
        console.log('WASM module initialized successfully');
        return true;
    } catch (error) {
        console.error('Failed to initialize WASM module:', error);
        return false;
    }
}

// Helper to read strings from WASM memory
function readString(ptr, len) {
    const view = new Uint8Array(memory.buffer, ptr, len);
    return new TextDecoder().decode(view);
}

// Helper to write strings to WASM memory
function writeString(str) {
    const bytes = new TextEncoder().encode(str);
    const ptr = exports.allocateString(bytes.length);
    const view = new Uint8Array(memory.buffer, ptr, bytes.length);
    view.set(bytes);
    return { ptr, len: bytes.length };
}

// Helper to load ROM data
function loadROM(romData) {
    const romArray = new Uint8Array(memory.buffer, 0, romData.length);
    romArray.set(romData);
    exports.loadROM(emulator, romArray.byteOffset, romData.length);
}

// Export the API
export const Li8z = {
    init: initWasm,
    
    loadROM: (romData) => {
        window.Li8zAPI.loadROM(emulator, romData, romData.length);
    },

    tick: () => {
        window.Li8zAPI.emuTick(emulator);
    },

    tickTimers: () => {
        return window.Li8zAPI.emuTickTimers(emulator);
    },

    keypress: (key, pressed) => {
        window.Li8zAPI.emuKeypress(emulator, key, pressed);
    },

    getScreen: () => {
        return screenArray;
    }
};

// Auto-initialize when the script is loaded
Li8z.init().catch(console.error);

function draw() {
    const screen = Li8z.getScreen();
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // Calculate pixel size to scale up the display
    const pixelWidth = canvas.width / 64;
    const pixelHeight = canvas.height / 32;
    
    ctx.fillStyle = '#fff';
    for (let y = 0; y < 32; y++) {
        for (let x = 0; x < 64; x++) {
            if (screen[x + y * 64]) {
                ctx.fillRect(
                    x * pixelWidth, 
                    y * pixelHeight, 
                    pixelWidth, 
                    pixelHeight
                );
            }
        }
    }
} 
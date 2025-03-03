// Memory management helpers
let memory;
let exports;
let emulator;
let screenArray;

// Initialize the WASM module
async function initWasm() {
    try {
        const response = await fetch('/zig-out/bin/li8z-web.wasm');
        const wasmBytes = await response.arrayBuffer();
        
        const importObject = {
            env: {
                memory: new WebAssembly.Memory({ 
                    initial: 17,  // ~1.1MB = 17 pages (64KB per page)
                    maximum: 17
                }),
            }
        };
        
        const wasmModule = await WebAssembly.instantiate(wasmBytes, importObject);
        exports = wasmModule.instance.exports;
        memory = importObject.env.memory;
        
        // Debug: log available exports
        console.log('Available exports:', Object.keys(exports));
        
        // Create emulator instance
        emulator = exports.initEmulator();
        if (!emulator) throw new Error("Failed to create emulator");
        
        // Get screen buffer pointer
        const screenPtr = exports.getScreenPtr(emulator);
        screenArray = new Uint8Array(memory.buffer, screenPtr, exports.getScreenWidth() * exports.getScreenHeight());
        
        // Set random seed
        const seed = BigInt(Math.floor(Math.random() * Number.MAX_SAFE_INTEGER));
        exports.setSeed(seed);
        
        console.log('WASM module initialized successfully');
        return true;
    } catch (error) {
        console.error('Failed to initialize WASM module:', error);
        console.error('Error details:', error.message);
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
        const romArray = new Uint8Array(memory.buffer, 0, romData.length);
        romArray.set(romData);
        exports.loadROM(emulator, romArray.byteOffset, romData.length);
    },

    tick: () => {
        exports.tickEmulator(emulator);
    },

    tickTimers: () => {
        return exports.tickTimers(emulator);
    },

    keypress: (key, pressed) => {
        exports.keyPress(emulator, key, pressed);
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
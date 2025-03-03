#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define SCREEN_WIDTH 64
#define SCREEN_HEIGHT 32

#define RAM_SIZE 4096
#define NUM_REGS 16
#define STACK_SIZE 16
#define NUM_KEYS 16
#define FONTSET_SIZE 80
#define START_ADDR 0x200

static const uint8_t FONTSET[FONTSET_SIZE] = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
};

typedef struct {
    uint16_t pc;
    uint8_t ram[RAM_SIZE];
    bool screen[SCREEN_WIDTH * SCREEN_HEIGHT];
    uint8_t v_reg[NUM_REGS];
    uint16_t i_reg;
    uint16_t sp;
    uint16_t stack[STACK_SIZE];
    bool keys[NUM_KEYS];
    uint8_t dt;
    uint8_t st;
} Emu;

// Helper function for addition with overflow detection
static void add_with_overflow(uint8_t a, uint8_t b, uint8_t* result, uint8_t* carry) {
    uint16_t sum = (uint16_t)a + (uint16_t)b;
    *result = (uint8_t)sum;
    *carry = (sum > 0xFF) ? 1 : 0;
}

// Helper function for subtraction with borrow detection
static void sub_with_borrow(uint8_t a, uint8_t b, uint8_t* result, uint8_t* borrow) {
    *borrow = (a < b) ? 1 : 0;
    *result = a - b;
}

// Helper function for random number generation
static uint8_t random_byte(void) {
    return (uint8_t)(rand() & 0xFF);
}

// Forward declarations
static void execute(Emu* emu, uint16_t op);
static uint16_t fetch(Emu* emu);
static void push(Emu* emu, uint16_t val);
static uint16_t pop(Emu* emu);

// Initialize a new emulator
Emu* createEmulator(void) {
    // Seed random number generator
    srand((unsigned int)time(NULL));
    
    Emu* emu = (Emu*)malloc(sizeof(Emu));
    if (emu == NULL) {
        return NULL;
    }
    
    // Initialize emulator state
    emu->pc = START_ADDR;
    memset(emu->ram, 0, RAM_SIZE);
    memset(emu->screen, 0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(bool));
    memset(emu->v_reg, 0, NUM_REGS);
    emu->i_reg = 0;
    emu->sp = 0;
    memset(emu->stack, 0, STACK_SIZE * sizeof(uint16_t));
    memset(emu->keys, 0, NUM_KEYS * sizeof(bool));
    emu->dt = 0;
    emu->st = 0;
    
    // Load fontset into memory
    memcpy(emu->ram, FONTSET, FONTSET_SIZE);
    
    return emu;
}

// Free emulator resources
void destroyEmulator(Emu* emu) {
    if (emu != NULL) {
        free(emu);
    }
}

// Reset emulator to initial state
void resetEmulator(Emu* emu) {
    emu->pc = START_ADDR;
    emu->i_reg = 0;
    emu->sp = 0;
    emu->dt = 0;
    emu->st = 0;
    
    memset(emu->screen, 0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(bool));
    memset(emu->v_reg, 0, NUM_REGS);
    memset(emu->stack, 0, STACK_SIZE * sizeof(uint16_t));
    memset(emu->keys, 0, NUM_KEYS * sizeof(bool));
    memset(emu->ram, 0, RAM_SIZE);
    
    // Reload fontset
    memcpy(emu->ram, FONTSET, FONTSET_SIZE);
}

// Load ROM data into emulator memory
void loadROM(Emu* emu, const uint8_t* data, size_t length) {
    if (length > RAM_SIZE - START_ADDR) {
        length = RAM_SIZE - START_ADDR;  // Prevent buffer overflow
    }
    memcpy(&emu->ram[START_ADDR], data, length);
}

// Push value onto the stack
static void push(Emu* emu, uint16_t val) {
    if (emu->sp < STACK_SIZE) {
        emu->stack[emu->sp] = val;
        emu->sp++;
    }
}

// Pop value from the stack
static uint16_t pop(Emu* emu) {
    if (emu->sp > 0) {
        emu->sp--;
        return emu->stack[emu->sp];
    }
    return 0;  // Stack underflow
}

// Fetch the next opcode
static uint16_t fetch(Emu* emu) {
    uint16_t higher_byte = emu->ram[emu->pc];
    uint16_t lower_byte = emu->ram[emu->pc + 1];
    uint16_t op = (higher_byte << 8) | lower_byte;
    emu->pc += 2;
    return op;
}

// Process a single CPU cycle
void emuTick(Emu* emu) {
    uint16_t op = fetch(emu);
    execute(emu, op);
}

// Update timers, return true if sound timer is active
bool emuTickTimers(Emu* emu) {
    bool beep = false;
    
    if (emu->dt > 0) {
        emu->dt--;
    }
    
    if (emu->st > 0) {
        if (emu->st == 1) {
            beep = true;
        }
        emu->st--;
    }
    
    return beep;
}

// Handle key press/release
void emuKeypress(Emu* emu, size_t key, bool pressed) {
    if (key < NUM_KEYS) {
        emu->keys[key] = pressed;
    }
}

// Get pointer to screen buffer
bool* getScreenPtr(Emu* emu) {
    return emu->screen;
}

// Execute a single opcode
static void execute(Emu* emu, uint16_t op) {
    uint8_t digit1 = (op & 0xF000) >> 12;
    uint8_t digit2 = (op & 0x0F00) >> 8;
    uint8_t digit3 = (op & 0x00F0) >> 4;
    uint8_t digit4 = (op & 0x000F);
    
    // Skip if opcode is 0
    if (op == 0) return;
    
    // Decode and execute opcode
    switch (digit1) {
        case 0x0:
            if (digit2 == 0 && digit3 == 0xE) {
                if (digit4 == 0) {
                    // 00E0: Clear screen
                    memset(emu->screen, 0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(bool));
                } else if (digit4 == 0xE) {
                    // 00EE: Return from subroutine
                    uint16_t ret_addr = pop(emu);
                    emu->pc = ret_addr;
                }
            }
            break;
            
        case 0x1:
            // 1NNN: Jump to address NNN
            emu->pc = op & 0xFFF;
            break;
            
        case 0x2:
            // 2NNN: Call subroutine at NNN
            push(emu, emu->pc);
            emu->pc = op & 0xFFF;
            break;
            
        case 0x3:
            // 3XNN: Skip next instruction if VX == NN
            if (emu->v_reg[digit2] == (op & 0xFF)) {
                emu->pc += 2;
            }
            break;
            
        case 0x4:
            // 4XNN: Skip next instruction if VX != NN
            if (emu->v_reg[digit2] != (op & 0xFF)) {
                emu->pc += 2;
            }
            break;
            
        case 0x5:
            // 5XY0: Skip next instruction if VX == VY
            if (digit4 == 0 && emu->v_reg[digit2] == emu->v_reg[digit3]) {
                emu->pc += 2;
            }
            break;
            
        case 0x6:
            // 6XNN: Set VX = NN
            emu->v_reg[digit2] = op & 0xFF;
            break;
            
        case 0x7:
            // 7XNN: Add NN to VX (no carry flag)
            emu->v_reg[digit2] += op & 0xFF;
            break;
            
        case 0x8:
            switch (digit4) {
                case 0x0:
                    // 8XY0: Set VX = VY
                    emu->v_reg[digit2] = emu->v_reg[digit3];
                    break;
                    
                case 0x1:
                    // 8XY1: Set VX = VX OR VY
                    emu->v_reg[digit2] |= emu->v_reg[digit3];
                    break;
                    
                case 0x2:
                    // 8XY2: Set VX = VX AND VY
                    emu->v_reg[digit2] &= emu->v_reg[digit3];
                    break;
                    
                case 0x3:
                    // 8XY3: Set VX = VX XOR VY
                    emu->v_reg[digit2] ^= emu->v_reg[digit3];
                    break;
                    
                case 0x4: {
                    // 8XY4: Set VX = VX + VY, set VF = carry
                    uint8_t result, carry;
                    add_with_overflow(emu->v_reg[digit2], emu->v_reg[digit3], &result, &carry);
                    emu->v_reg[digit2] = result;
                    emu->v_reg[0xF] = carry;
                    break;
                }
                
                case 0x5: {
                    // 8XY5: Set VX = VX - VY, set VF = NOT borrow
                    uint8_t result, borrow;
                    sub_with_borrow(emu->v_reg[digit2], emu->v_reg[digit3], &result, &borrow);
                    emu->v_reg[digit2] = result;
                    emu->v_reg[0xF] = borrow ? 0 : 1;
                    break;
                }
                
                case 0x6:
                    // 8XY6: Set VX = VX SHR 1, set VF = least significant bit
                    emu->v_reg[0xF] = emu->v_reg[digit2] & 0x1;
                    emu->v_reg[digit2] >>= 1;
                    break;
                    
                case 0x7: {
                    // 8XY7: Set VX = VY - VX, set VF = NOT borrow
                    uint8_t result, borrow;
                    sub_with_borrow(emu->v_reg[digit3], emu->v_reg[digit2], &result, &borrow);
                    emu->v_reg[digit2] = result;
                    emu->v_reg[0xF] = borrow ? 0 : 1;
                    break;
                }
                
                case 0xE:
                    // 8XYE: Set VX = VX SHL 1, set VF = most significant bit
                    emu->v_reg[0xF] = (emu->v_reg[digit2] >> 7) & 0x1;
                    emu->v_reg[digit2] <<= 1;
                    break;
            }
            break;
            
        case 0x9:
            // 9XY0: Skip next instruction if VX != VY
            if (digit4 == 0 && emu->v_reg[digit2] != emu->v_reg[digit3]) {
                emu->pc += 2;
            }
            break;
            
        case 0xA:
            // ANNN: Set I = NNN
            emu->i_reg = op & 0xFFF;
            break;
            
        case 0xB:
            // BNNN: Jump to address NNN + V0
            emu->pc = (op & 0xFFF) + emu->v_reg[0];
            break;
            
        case 0xC:
            // CXNN: Set VX = random byte AND NN
            emu->v_reg[digit2] = random_byte() & (op & 0xFF);
            break;
            
        case 0xD: {
            // DXYN: Display n-byte sprite at (VX, VY), set VF = collision
            uint8_t x_coord = emu->v_reg[digit2];
            uint8_t y_coord = emu->v_reg[digit3];
            uint8_t num_rows = digit4;
            bool flipped = false;
            
            for (int y_line = 0; y_line < num_rows; y_line++) {
                uint16_t addr = emu->i_reg + y_line;
                uint8_t pixels = emu->ram[addr];
                
                for (int x_line = 0; x_line < 8; x_line++) {
                    if ((pixels & (0x80 >> x_line)) != 0) {
                        uint8_t x = (x_coord + x_line) % SCREEN_WIDTH;
                        uint8_t y = (y_coord + y_line) % SCREEN_HEIGHT;
                        size_t idx = x + SCREEN_WIDTH * y;
                        
                        if (emu->screen[idx]) {
                            flipped = true;
                        }
                        
                        emu->screen[idx] = !emu->screen[idx];
                    }
                }
            }
            
            emu->v_reg[0xF] = flipped ? 1 : 0;
            break;
        }
        
        case 0xE:
            if (digit3 == 0x9 && digit4 == 0xE) {
                // EX9E: Skip next instruction if key with value VX is pressed
                uint8_t key = emu->v_reg[digit2];
                if (key < NUM_KEYS && emu->keys[key]) {
                    emu->pc += 2;
                }
            } else if (digit3 == 0xA && digit4 == 0x1) {
                // EXA1: Skip next instruction if key with value VX is not pressed
                uint8_t key = emu->v_reg[digit2];
                if (key < NUM_KEYS && !emu->keys[key]) {
                    emu->pc += 2;
                }
            }
            break;
            
        case 0xF:
            switch ((digit3 << 4) | digit4) {
                case 0x07:
                    // FX07: Set VX = delay timer value
                    emu->v_reg[digit2] = emu->dt;
                    break;
                    
                case 0x0A: {
                    // FX0A: Wait for a key press, store key value in VX
                    bool pressed = false;
                    for (int i = 0; i < NUM_KEYS; i++) {
                        if (emu->keys[i]) {
                            emu->v_reg[digit2] = i;
                            pressed = true;
                            break;
                        }
                    }
                    
                    if (!pressed) {
                        // Repeat this instruction
                        emu->pc -= 2;
                    }
                    break;
                }
                
                case 0x15:
                    // FX15: Set delay timer = VX
                    emu->dt = emu->v_reg[digit2];
                    break;
                    
                case 0x18:
                    // FX18: Set sound timer = VX
                    emu->st = emu->v_reg[digit2];
                    break;
                    
                case 0x1E:
                    // FX1E: Set I = I + VX
                    emu->i_reg += emu->v_reg[digit2];
                    break;
                    
                case 0x29:
                    // FX29: Set I = location of sprite for digit VX
                    emu->i_reg = emu->v_reg[digit2] * 5;
                    break;
                    
                case 0x33: {
                    // FX33: Store BCD representation of VX in memory at I, I+1, I+2
                    uint8_t value = emu->v_reg[digit2];
                    emu->ram[emu->i_reg] = value / 100;
                    emu->ram[emu->i_reg + 1] = (value / 10) % 10;
                    emu->ram[emu->i_reg + 2] = value % 10;
                    break;
                }
                
                case 0x55:
                    // FX55: Store registers V0 through VX in memory starting at I
                    for (int i = 0; i <= digit2; i++) {
                        emu->ram[emu->i_reg + i] = emu->v_reg[i];
                    }
                    break;
                    
                case 0x65:
                    // FX65: Read registers V0 through VX from memory starting at I
                    for (int i = 0; i <= digit2; i++) {
                        emu->v_reg[i] = emu->ram[emu->i_reg + i];
                    }
                    break;
            }
            break;
    }
}

const random = () => {
  return Math.floor(Math.random() * (255))
}

export const SCREEN_WIDTH = 64
export const SCREEN_HEIGHT = 32

const RAM_SIZE = 4096;
const NUM_REGS = 16;
const STACK_SIZE = 16;
const NUM_KEYS = 16;
const FONTSET = new Uint8Array([
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
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
])

export class Emu {
  private pc: number;
  private ram: Uint8Array;
  private screen: boolean[];
  private v_reg: Uint8Array;
  private i_reg: number;
  private sp: number;
  private stack: Uint16Array;
  private keys: Array<boolean>;
  private dt: number;
  private st: number;

  constructor() {
    this.ram = new Uint8Array(RAM_SIZE);
    this.ram.set(FONTSET, 0);
    this.v_reg = new Uint8Array(NUM_REGS);
    this.i_reg = 0;
    this.pc = 0x200;
    this.stack = new Uint16Array(STACK_SIZE);
    this.sp = 0;
    this.dt = 0;
    this.st = 0;
    this.keys = new Array<boolean>(NUM_KEYS);
    this.screen = new Array<boolean>(SCREEN_WIDTH * SCREEN_HEIGHT);
  }

  getDisplay(): boolean[] {
    return this.screen;
  }

  keypress(idx: number, pressed: boolean) {
    this.keys[idx] = pressed;
  }

  load(data: Uint8Array){
    this.ram.set(data, 0x200);
  }

  private push(val: number) {
    this.stack[this.sp] = val
  }

  private pop(): number {
    this.sp -= 1
    return this.stack[this.sp]
  }

  reset() {
    this.pc = 0x200
    this.i_reg = 0
    this.sp = 0
    this.dt = 0
    this.st = 0
    this.screen.fill(false)
    this.v_reg.fill(0)
    this.stack.fill(0)
    this.keys.fill(false)
    this.ram.fill(0)
    this.ram.set(FONTSET, 0)
  }

  tick() {
    const op = this.fetch()
    this.execute(op)
  }

  execute(op: number) {
      const digit1 = (op & 0xF000) >> 12;
      const digit2 = (op & 0x0F00) >> 8;
      const digit3 = (op & 0x00F0) >> 4;
      const digit4 = (op & 0x000F);

      if ((digit1 == 0) && (digit2 == 0) && (digit3 == 0) && (digit4 == 0)) return;

      if ((digit1 == 0) && (digit2 == 0) && (digit3 == 0xE) && (digit4 == 0)) {
          this.screen.fill(false);
      } else if ((digit1 == 0) && (digit2 == 0) && (digit3 == 0xE) && (digit4 == 0xE)) {
          const ret_addr = this.pop();
          this.pc = ret_addr;
      } else if ((digit1 == 1)) {
          const nnn = op & 0xFFF;
          this.pc = nnn;
      } else if ((digit1 == 2)) {
          const nnn = op & 0xFFF;
          this.push(this.pc);
          this.pc = nnn;
      } else if ((digit1 == 3)) {
          const x = digit2;
          const nn = op & 0xFF;
          if (this.v_reg[x] == nn) {
              this.pc += 2;
          }
      } else if ((digit1 == 4)) {
          const x = digit2;
          const nn = op & 0xFF;
          if (this.v_reg[x] != nn) {
              this.pc += 2;
          }
      } else if ((digit1 == 5) && (digit4 == 0)) {
          const x = digit2;
          const y = digit3;
          if (this.v_reg[x] == this.v_reg[y]) {
              this.pc += 2;
          }
      } else if ((digit1 == 6)) {
          const x = digit2;
          const nn = op & 0xFF;
          this.v_reg[x] = nn;
      } else if ((digit1 == 7)) {
          const x= digit2;
          const nn = op & 0xFF;
          const nn_u8 = nn;
          const result = this.v_reg[x] + nn_u8;
          this.v_reg[x] = result > 255 ? result - 256 : result;
      } else if ((digit1 == 8) && (digit4 == 0)) {
          const x = digit2;
          const y = digit3;
          this.v_reg[x] = this.v_reg[y];
      } else if ((digit1 == 8) && (digit4 == 1)) {
          const x = digit2;
          const y = digit3;
          this.v_reg[x] |= this.v_reg[y];
      } else if ((digit1 == 8) && (digit4 == 2)) {
          const x = digit2;
          const y = digit3;
          this.v_reg[x] &= this.v_reg[y];
      } else if ((digit1 == 8) && (digit4 == 3)) {
          const x = digit2;
          const y = digit3;
          this.v_reg[x] ^= this.v_reg[y];
      } else if ((digit1 == 8) && (digit4 == 4)) {
          const x = digit2;
          const y = digit3;
          const tmp = this.v_reg[x] + this.v_reg[y];
          const result = tmp > 255 ? [tmp - 256, 1] : [tmp, 0];
          this.v_reg[x] = result[0];
          this.v_reg[0xF] = result[1];
      } else if ((digit1 == 8) && (digit4 == 5)) {
          const x = digit2;
          const y = digit3;
          const tmp = this.v_reg[x] - this.v_reg[y];
          const result = tmp < 0 ? [tmp + 256, 0] : [tmp, 1];
          this.v_reg[x] = result[0];
          this.v_reg[0xF] = result[1];
      } else if ((digit1 == 8) && (digit4 == 6)) {
          const x = digit2;
          this.v_reg[0xF] = this.v_reg[x] & 0x1;
          this.v_reg[x] >>= 1;
      } else if ((digit1 == 8) && (digit4 == 7)) {
          const x = digit2;
          const y = digit3;
          const tmp = this.v_reg[y] - this.v_reg[x];
          const result = tmp < 0 ? [tmp + 256, 0] : [tmp, 1];
          this.v_reg[x] = result[0];
          this.v_reg[0xF] = result[1];
      } else if ((digit1 == 8) && (digit4 == 0xE)) {
          const x = digit2;
          this.v_reg[0xF] = (this.v_reg[x] >> 7) & 0x1;
          this.v_reg[x] <<= 1;
      } else if ((digit1 == 9) && (digit4 == 0)) {
          const x = digit2;
          const y = digit3;
          if (this.v_reg[x] != this.v_reg[y]) {
              this.pc += 2;
          }
      } else if (digit1 == 0xA) {
          const nnn = op & 0xFFF;
          this.i_reg = nnn;
      } else if (digit1 == 0xB) {
          const nnn = op & 0xFFF;
          this.pc = nnn + this.v_reg[0];
      } else if (digit1 == 0xC) {
          const x = digit2;
          const nn = op & 0xFF;
          const nn_u8 = nn;
          this.v_reg[x] = random() & nn_u8;
      } else if (digit1 == 0xD) {
          const x_coord = this.v_reg[digit2];
          const y_coord = this.v_reg[digit3];
          const num_rows = digit4;
          var flipped = false;

          for (let y_line = 0; y_line < num_rows; y_line++) {
              const addr = this.i_reg + y_line;
              const pixels = this.ram[addr];

              for (let x_line = 0; x_line < 8; x_line++) {
                  const x_line_trunc = x_line;
                  if ((pixels & (0b1000_0000 >> x_line_trunc)) != 0) {
                      const x = (x_coord + x_line) % SCREEN_WIDTH;
                      const y = (y_coord + y_line) % SCREEN_HEIGHT;
                      const idx = x + SCREEN_WIDTH * y;
                      flipped = flipped || this.screen[idx];
                      this.screen[idx] = this.screen[idx] != true;
                  }
              }
          }

          if (flipped) {
              this.v_reg[0xF] = 1;
          } else {
              this.v_reg[0xF] = 0;
          }
      } else if ((digit1 == 0xE) && (digit3 == 9) && (digit4 == 0xE)) {
          const x= digit2;
          const vx = this.v_reg[x];
          const key = this.keys[vx];
          if (key) {
              this.pc += 2;
          }
      } else if ((digit1 == 0xE) && (digit3 == 0xA) && (digit4 == 1)) {
          const x= digit2;
          const vx = this.v_reg[x];
          const key = this.keys[vx];
          if (!key) {
              this.pc += 2;
          }
      } else if ((digit1 == 0xF) && (digit3 == 0) && (digit4 == 7)) {
          const x= digit2;
          this.v_reg[x] = this.dt;
      } else if ((digit1 == 0xF) && (digit3 == 0) && (digit4 == 0xA)) {
          const x= digit2;
          var pressed = false;
          for (let i = 0; i < NUM_KEYS; i++) {
              if (this.keys[i]) {
                  this.v_reg[x] = i;
                  pressed = true;
                  break;
              }
          }

          if (!pressed) {
              this.pc -= 2;
          }
      } else if ((digit1 == 0xF) && (digit3 == 1) && (digit4 == 8)) {
          const x= digit2;
          this.st = this.v_reg[x];
      } else if ((digit1 == 0xF) && (digit3 == 1) && (digit4 == 0xE)) {
          const x= digit2;
          const vx = this.v_reg[x];
          const result = this.i_reg + vx;
          this.i_reg = result > 0xFFFF ? result - 0xFFFF : result;
      } else if ((digit1 == 0xF) && (digit3 == 2) && (digit4 == 9)) {
          const x= digit2;
          const c = this.v_reg[x];
          this.i_reg = c * 5;
      } else if ((digit1 == 0xF) && (digit3 == 3) && (digit4 == 3)) {
          const x= digit2;
          const vx = this.v_reg[x];

          const hundreds = vx/ 100.0;
          const tens = (vx/ 10.0)% 10.0;
          const ones = vx/ 10.0;

          this.ram[this.i_reg] = hundreds;
          this.ram[this.i_reg + 1] = tens;
          this.ram[this.i_reg + 2] = ones;
      } else if ((digit1 == 0xF) && (digit3 == 5) && (digit4 == 5)) {
          const x= digit2;
          const i= this.i_reg;
          for (let idx = 0; idx < x + 1; idx++){
              this.ram[i + idx] = this.v_reg[idx];
          }
      } else if ((digit1 == 0xF) && (digit3 == 6) && (digit4 == 5)) {
          const x= digit2;
          const i= this.i_reg;
          for (let idx = 0; idx < x + 1; idx++){
              this.v_reg[idx] = this.ram[i + idx];
          }
      }
      return;
  }

  fetch(): number {
      const higher_byte = this.ram[this.pc];
      const lower_byte = this.ram[this.pc + 1];
      const op = (higher_byte << 8) | lower_byte;
      this.pc += 2;
      return op;
  }

  tickTimers(): boolean {
    let beep = false
    if (this.dt > 0 ) this.dt  -= 1

    if (this.st > 0){
      if (this.st == 1) {
        beep = true
      }
      this.st -= 1;
    }
    return beep;
  }
}

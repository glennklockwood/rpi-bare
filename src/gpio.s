//*****************************************************************************
//
// GPIO controller registers:
//
// Number | Address | Name    | Description             | Domain
// -------|---------|---------|-------------------------|----------------
// 00     | r0 +  0 | GPFSEL0 | GPIO Function Select 0  | for pins 0-9
// 01     | r0 +  4 | GPFSEL1 | GPIO Function Select 1  | for pins 10-19
// 02     | r0 +  8 | GPFSEL2 | GPIO Function Select 2  | for pins 20-29
// 03     | r0 + 12 | GPFSEL3 | GPIO Function Select 3  | for pins 30-39
// 04     | r0 + 16 | GPFSEL4 | GPIO Function Select 4  | for pins 40-49
// 05     | r0 + 20 | GPFSEL5 | GPIO Function Select 5  | for pins 50-54
// 07     | r0 + 28 | GPSET0  | GPIO Pin Output Set 0   | for pins 0-31
// 08     | r0 + 32 | GPSET1  | GPIO Pin Output Set 1   | for pins 32-54
// 10     | r0 + 40 | GPCLR0  | GPIO Pin Output Clear 0 | for pins 0-31
// 11     | r0 + 44 | GPCLR1  | GPIO Pin Output Clear 1 | for pins 32-54
//
//*****************************************************************************

//*****************************************************************************
// GetGpioAddress
//
// Inputs:
//  None
//
// Outputs:
//  r0: address of GPIO controller base address
//*****************************************************************************
.globl GetGpioAddress
GetGpioAddress:

// Store 0x20200000 in r0; this is the base address of the GPIO controller
ldr r0, =0x20200000

// Copy value in lr to pc
//
//   lr = address of code that issued the branch that got us into this function
//   pc = always contains address of next instruction to be run
//
// so this just returns from this function
mov pc, lr


//*****************************************************************************
// SetGpioFunction
//
// Inputs:
//  r0 (0-53): pin number
//  r1 (000-111): command code
//
// Outputs:
//  None
//*****************************************************************************
.globl SetGpioFunction
SetGpioFunction:

// Compare r0 to 53; store result in current program status register (CPSR)
cmp r0, #53

// cmpls: compare r1 to 7 if CPSR is "lower or same"
cmpls r1, #7

// movhi: mov if CPSR is "higher"
// this will bail out if this function if r0 > 53 or if r1 > 7
movhi pc, lr

// Copy link register on to stack
push {lr}

// Copy input (pin number) from r0 to r2 to preserve it (we know that we won't
// otherwise modify r2 in this function)
mov r2, r0

// branch to another function (this is why we saved lr and copied r0 out of the way)
bl GetGpioAddress

functionLoop$:
  cmp r2, #9    // r2 = pin number
  subhi r2, #10 // if r2 > 9, subtract ten from r2
  addhi r0, #4  // if r2 > 9, also add 4 to r0 (which started as the base address)
  bhi functionLoop$ // if r2 > 9, loop
// r0 now contains the address pointing to the correct GPFSEL register

// Multiply r2 (pin number) by three
//
// Equivalent to
//    mov r3, r2
//    add r2, r3
//    add r2, r3
//
// Syntax of add: add Rd, Rn, Operand2
//   Rd = result
//   Rn = first operand
//   Operand2 = second operand
add r2, r2, lsl #1
// so this adds r2 to lsl r2, #1, then stores it in r2?

// logical shift left shift r1 (the 3-bit command code) by r2 (3 * pin number)
lsl r1, r2

// write contents of r1 into address given in r0 (which is the GPFSEL address)
str r1, [r0]

// pop the top of the stack (from our last push, which was lr) into pc
pop {pc}

//*****************************************************************************
// SetGpio
//
// Inputs:
//   r0 (0-53): pin number
//   r1 (0|1): set (1) or clear (0) given pin
//
// Outputs:
//   None
//*****************************************************************************
.globl SetGpio
SetGpio:

/* .req = alias pinNum to r0 */
pinNum .req r0
pinVal .req r1

cmp pinNum, #53
movhi pc, lr    // bail if pinNum > 53
push {lr}

mov r2, pinNum  // copy input value r0 to r2 so we can use r0 for output
.unreq pinNum   // unalias pinNum since we just moved it from r0 to r2
pinNum .req r2  // re-alias pinNum to r2
bl GetGpioAddress
gpioAddr .req r0

pinBank .req r3
lsr pinBank, pinNum, #5 // pinBank = pinNum / 32
lsl pinBank, #2         // pinBank = pinBank * 4
add gpioAddr, pinBank   // gpioAddr = gpioAddr + pinBank
.unreq pinBank
// at this point, gpioAddr is the base address shifted by either 0 or 4 bytes
// depending on whether or not the pin of interest is in the first 32 pins or
// second 32 pins

and pinNum, #31         // pinNum = pinNum % 32 (or pinNum = pinNum && 0b11111)
setBit .req r3
mov setBit, #1          // setBit = 1
lsl setBit, pinNum      // setBit = setBit << pinNum
.unreq pinNum

teq pinVal, #0          // compare pinVal to 0
.unreq pinVal
streq setBit, [gpioAddr, #40] // if pinVal == 0, store setBit in GPCLR register
strne setBit, [gpioAddr, #28] // if pinVal != 0, store setbit in GPSET register
.unreq setBit
.unreq gpioAddr

pop {pc}

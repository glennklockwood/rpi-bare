.section .data
.align 2
facecolor:
.hword 0xFFFF

.align 4
gfxAddr:
.int 0

////////////////////////////////////////////////////////////////////////////////
// SetFaceColor: Sets global facecolor setting.  If facecolor is more than
// 2 bytes, do nothing.  Recall that 16-bit encoding is RRRRRGGG GGGBBBBB
//
// Inputs:
//   r0: 2-byte color code to set facecolor
//
// Outputs:
//   r0: 2-byte color code set to facecolor
////////////////////////////////////////////////////////////////////////////////
.section .text
.globl SetFaceColor
SetFaceColor:
cmp r0, #0x10000
movhs pc, lr // check that input r0 is <= 0xFFFF

ldr r1, =facecolor

strh r0, [r1]  // store r0 in address pointed to by r1
mov pc, lr

////////////////////////////////////////////////////////////////////////////////
// SetGfxAddr: Sets global frame buffer descriptor (questionnaire) address
//
// Inputs:
//   r0: address of frame buffer descriptor address
//
// Outputs:
//   r0: address of frame buffer descriptor address
////////////////////////////////////////////////////////////////////////////////
.globl SetGfxAddr
SetGfxAddr:
ldr r1, =gfxAddr
str r0, [r1] // store r0 in address pointed to by r1
mov pc, lr

////////////////////////////////////////////////////////////////////////////////
// DrawPixel: Sets the state of a single pixel in a frame buffer
//
// Inputs:
//   r0: x coordinate of pixel
//   r1: y coordinate of pixel
//
// Outputs:
//   None
////////////////////////////////////////////////////////////////////////////////
.globl DrawPixel
DrawPixel:
px .req r0
py .req r1

// Load in gfxAddr - fbdAddr = frame buffer descriptior (questionnaire) address
fbdAddr .req r2
ldr fbdAddr, =gfxAddr
ldr fbdAddr, [fbdAddr]

// Check x, y coordinates less than width, height
width .req r3
ldr width, [fbdAddr, #0]
cmp px, width
movhs pc, lr

height .req r4
ldr height, [fbdAddr, #4]
cmp py, height
movhs pc, lr
.unreq height

// Compute address of pixel to write
// (x + y * width) * bitDensity

// rename fbdAddr to fbAddr after turning it into the pointer to the frame
// buffer itself
ldr fbdAddr, [fbdAddr, #32]
fbAddr .req fbdAddr
.unreq fbdAddr

// MLA{S}{cond} Rd, Rn, Rm, Ra
// Rd - the destination register.
// Rn, Rm - registers holding the values to be multiplied
// Ra - is a register holding the value to be added
mla px, py, width, px // px = py * width + px
.unreq width
.unreq py
add fbAddr, px, lsl #1 // multiply by 2 since 2 bytes per pixel
.unreq px

// Load in facecolor
fg .req r3
ldr fg, =facecolor // load address to facecolor as full-word register
ldrh fg, [fg]      // load facecolor itself as a half-word

// Store it at the address
strh fg, [fbAddr] // copy facecolor into pixel address in frame buffer
.unreq fg
.unreq fbAddr

mov pc, lr

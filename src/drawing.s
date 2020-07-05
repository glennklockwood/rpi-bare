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

////////////////////////////////////////////////////////////////////////////////
// DrawLine: Draws a line using Bresenham's Algorithm.  Stolen from 
// https://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/screen02.html
//
// Inputs:
//   r0: x coordinate of line start
//   r1: y coordinate of line start
//   r2: x coordinate of line end
//   r3: y coordinate of line end
//
// Outputs:
//   None
////////////////////////////////////////////////////////////////////////////////
.globl DrawLine
DrawLine:
push {r4,r5,r6,r7,r8,r9,r10,r11,r12,lr}
x0 .req r9
x1 .req r10
y0 .req r11
y1 .req r12

mov x0,r0
mov x1,r2
mov y0,r1
mov y1,r3

dx .req r4
dyn .req r5 /* Note that we only ever use -deltay, so I store its negative for speed. (hence dyn) */
sx .req r6
sy .req r7
err .req r8

cmp x0,x1
subgt dx,x0,x1
movgt sx,#-1
suble dx,x1,x0
movle sx,#1

cmp y0,y1
subgt dyn,y1,y0
movgt sy,#-1
suble dyn,y0,y1
movle sy,#1

add err,dx,dyn
add x1,sx
add y1,sy

pixelLoop$:
    teq x0,x1
    teqne y0,y1
    popeq {r4,r5,r6,r7,r8,r9,r10,r11,r12,pc}

    mov r0,x0
    mov r1,y0
    bl DrawPixel

    cmp dyn, err,lsl #1
    addle err,dyn
    addle x0,sx

    cmp dx, err,lsl #1
    addge err,dx
    addge y0,sy

    b pixelLoop$

.unreq x0
.unreq x1
.unreq y0
.unreq y1
.unreq dx
.unreq dyn
.unreq sx
.unreq sy
.unreq err

.section .data
.align 2
facecolor:
.hword 0xFFFF

.align 4
gfxAddr:
.int 0

.align 4
font:
.incbin "font1.bin"

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
//   NOTE: I thought you could get away without the sub and just use 
//     ldr height, [fbdAddr, #4]
//     cmp py, height
//     movhs py, height
//   This does NOT work.  I don't understand why.
height .req r3
ldr height, [fbdAddr, #4]
sub height, #1
cmp py, height
movhi pc, lr
.unreq height

width .req r3
ldr width, [fbdAddr, #0]
sub width, #1
cmp px, width
movhi pc, lr
add width, #1 // add back the 1 we subtracted so we can use it below

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

////////////////////////////////////////////////////////////////////////////////
// DrawChar: Draws a character 
//
// Inputs:
//   r0: character to draw
//   r1: x coordinate
//   r2: y coordinate
//
// Outputs:
//   None
////////////////////////////////////////////////////////////////////////////////
.globl DrawChar
DrawChar:
char .req r0

cmp char, #127

movhi r0, #0
movhi r1, #0
movhi pc, lr // on invalid input, zero out r0, r1 and return

push {r4, r5, r6, r7, r8, lr}

x .req r4
y .req r5
charAddr .req r6

mov x, r1
mov y, r2

ldr charAddr, =font
// charAddr = char * 16 + fontAddr
// mla charAddr, char, #16, fontAddr
add charAddr, char, lsl #4
.unreq char

// raster in y sixteen times
rowLoop$:
    bits .req r7
    bit .req r8
    ldrb bits, [charAddr] // load a single byte from the 4-byte charAddr
    mov bit, #8 // all characters are 8 pixels wide

    // raster in x eight times
    bitLoop$:
        subs bit, #1 // subtract and compare to zero
        blt bitLoopEnd$ // break if we've visited every pixel in this row

        // reminder: bits is  0b00000000
        // character is up to 0b01111111
        // so we shift into the eighth field (0x100) and examine that one 
        lsl bits, #1
        tst bits, #0x100 // reminder: tst = logical and; 0x100 = 256
        beq bitLoop$ // unless the bit at 0x100 is set, don't draw anything

        add r0, x, bit
        mov r1, y
        bl DrawPixel // draw pixel at x + bit, y

        teq bit, #0 // bit XOR 0
        bne bitLoop$ // if bit is not zero, keep drawing (I don't understand this)

    bitLoopEnd$:
    .unreq bit
    .unreq bits

    // draw the next row of bits in y for this character
    add y, #1
    add charAddr, #1

    // look for when our charAddr's four lowest-order bits are all 0; this
    // signifies that we have overflowed past the 256 bits of any valid
    // character (or we were passed the null character, in which case there's
    // nothing to draw anyway)
    tst charAddr, #0b1111
    bne rowLoop$
.unreq x
.unreq y
.unreq charAddr

width .req r0
height .req r1
mov width, #8
mov height, #16

pop {r4, r5, r6, r7, r8, pc}
.unreq width
.unreq height

////////////////////////////////////////////////////////////////////////////////
// DrawString: Draws a string of characters
//
// Inputs:
//   r0: address to start of string in memory
//   r1: length of string, in characters
//   r2: x coordinate to begin drawing string
//   r3: y coordinate to begin drawing string
//
// Outputs:
//   None
////////////////////////////////////////////////////////////////////////////////
.globl DrawString
DrawString:
x .req r4
y .req r5
x0 .req r6
string .req r7
length .req r8
char .req r9
push {r4, r5, r6, r7, r8, r9, lr}

mov string, r0
mov x, r2
mov x0, x
mov y, r3
mov length, r1

stringLoop$:
    subs length, #1
    blt stringLoopEnd$ // if (length--) < 0, stop drawing

    ldrb char, [string] // load byte from address pointed to by string into char
    add string, #1 // move string address to that of the next character

    // draw the character we just ldrb'ed on the framebuffer
    mov r0, char
    mov r1, x
    mov r2, y
    bl DrawChar
    cwidth .req r0
    cheight .req r1

    // handle newline character
    teq char, #'\n'
    moveq x, x0  // if char == '\n', reset x to 0
    addeq y, cheight // and increment y by one row
    beq stringLoop$

    /// handle tab characters
    // if not a tab, just move cursor right by one and resume
    teq char, #'\t'
    addne x, cwidth
    bne stringLoop$

    // if a tab, move cursor right by 4
    add cwidth, cwidth, lsl #2 // cwidth = cwidth + cwidth * 4
    x1 .req r1
    mov x1, x0

    stringLoopTab$:
        add x1, cwidth
        cmp x, x1
        bge stringLoopTab$
    mov x, x1
    .unreq x1

    b stringLoop$

stringLoopEnd$:
.unreq cwidth
.unreq cheight

pop {r4, r5, r6, r7, r8, r9, pc}
.unreq x
.unreq y
.unreq x0
.unreq string
.unreq length

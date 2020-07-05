.section .init
.globl _start
_start:

bl display

.section .text
////////////////////////////////////////////////////////////////////////////////
// Main routine to draw on our screen
////////////////////////////////////////////////////////////////////////////////
.globl display
display:
mov sp, #0x8000 // gives us 0x8000 - 0x100 bytes of memory for our stack

width .req r0
height .req r1
bitDepth .req r2
mov width, #1024
mov height, #768
mov bitDepth, #16
.unreq width
.unreq height
.unreq bitDepth
bl InitFrameBuffer

result .req r0
teq result, #0
.unreq result
bne noError$

    gpioPin .req r0
    gpioCmd .req r1
    mov gpioPin, #47
    mov gpioCmd, #0b001
    bl SetGpioFunction

    mov gpioPin, #47
    mov gpioCmd, #1
    bl SetGpio
    .unreq gpioPin
    .unreq gpioCmd

    error$:
    b error$ // lock it up in the event of an error

noError$:
result .req r0
fbInfoAddr .req r4
mov fbInfoAddr, result // no error = r0 contains a valid questionnaire address
.unreq result

// raster loop
color .req r0
y .req r1
x .req r2
fbAddr .req r3
mov color, #0
render$:
    // fbInfoAddr + 32 = location of fb address filled out by the GPU
    ldr fbAddr, [fbInfoAddr, #32] 

    mov y, #768
    drawRow$:
        mov x, #1024
        drawPixel$:
            // "strh reg,[dest] stores low half-word in reg at the address given by dest"
            // so copy the lower two bytes of color into the framebuffer
            strh color, [fbAddr]
            add fbAddr, #2 // +2 since each pixel uses 2 bytes in 16-bit color mode
            sub x, #1 // move left by one position
            teq x, #0
            bne drawPixel$ // keep going until we hit x = 0
        sub y, #1 // move up by one position
        add color, #1 // let this overflow
        teq y, #0
        bne drawRow$ // keep going until we hit y = 0

    b render$
.unreq color
.unreq x
.unreq y
.unreq fbAddr
.unreq fbInfoAddr

////////////////////////////////////////////////////////////////////////////////
// InitFrameBuffer - Sends a memory address of a questionnaire to the GPU
// requesting the GPU use its contents to configure a framebuffer, then fill out
// a few missing fields (including the address to a frame buffer to which we can
// write).  Leaves a message of 0 in the mailbox on success, or nonzero on
// failure.
// 
// Inputs:
//   r0: width
//   r1: height
//   r2: bit depth
//
// Outputs:
//   r0: address to our filled-out questionnaire or 0 on failure
////////////////////////////////////////////////////////////////////////////////
.globl InitFrameBuffer
InitFrameBuffer:

width .req r0
height .req r1
bitDepth .req r2
cmp width, #4096
cmpls height, #4096 // if width <= 4096
cmpls bitDepth, #32 // if height <= 4096

movhi r0, #0 // if bitDepth > 32, r0 = 0
movhi pc, lr

fbInfoAddr .req r3
push {lr}

// write inputted frame buffer params into FrameBufferQuestionnaire
ldr fbInfoAddr, =FrameBufferQuestionnaire
str width, [fbInfoAddr, #0]
str height, [fbInfoAddr, #4]
str width, [fbInfoAddr, #8]
str height, [fbInfoAddr, #12]
str bitDepth, [fbInfoAddr, #20]
.unreq width
.unreq height
.unreq bitDepth

// Prepare input args for MailboxWrite
mov r0, fbInfoAddr // r0 now equals the address of our questionnaire
add r0, #0x40000000 // magic number to add to the questionnaire address to make GPU not use cache
// re: above magic number, this is equivalent to adding
//      0b01000000 00000000 00000000 00000000
// I don't understand how mangling a pointer encodes a special message to the
// GPU unless addresses never use these highest-order bits.  Maybe since the
// payload can only be 28 bits, the payload is shifted right by 4 bits, leaving
// the uppermost 4 bits empty for special flags?
mov r1, #1 // use channel 1
bl MailboxWrite

// Prepare input args for MailboxRead
mov r0, #1
bl MailboxRead

// if we read zero from the mailbox (message success)
result .req r0
teq result, #0 
movne result, #0 // if MailboxRead returned nonzero, set result to nonzero
popne {pc} // if MailboxRead returned nonzero, break

mov result, fbInfoAddr // return filled-out questionnaire address

pop {pc}
.unreq result
.unreq fbInfoAddr


////////////////////////////////////////////////////////////////////////////////
// Frame buffer
////////////////////////////////////////////////////////////////////////////////
.section .data
.align 4
.globl FrameBufferQuestionnaire
FrameBufferQuestionnaire:
.int 1024   //  #0 in: physical width
.int 768    //  #4 in: physical height
.int 1024   //  #8 in: virtual width
.int 768    // #12 in: virtual height
.int 0      // #16 out: number of bytes on each row of fb (pitch)
.int 16     // #20 in: bit depth
.int 0      // #24 in: x offset to begin drawing (x)
.int 0      // #28 in: y offset to begin drawing (y)
.int 0      // #32 out: pointer to frame buffer
.int 0      // #36 out: size in bytes of frame buffer

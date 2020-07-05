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

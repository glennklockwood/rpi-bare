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
bl SetGfxAddr
mov fbInfoAddr, result // no error = r0 contains a valid questionnaire address
.unreq result

// raster loop
x .req r5
y .req r6
color .req r7
mov color, #0x0
render$:
    mov r0, fbInfoAddr

    mov y, #768
    drawRow$:
        mov x, #1024
        drawPixel$:
            mov r0, x
            mov r1, y
            bl DrawPixel
            sub x, #1 // move left by one position
            teq x, #0
            bne drawPixel$ // keep going until we hit x = 0
        sub y, #1 // move up by one position

        add color, #1
        lsl color, #16 // mask off upper half of word
        lsr color, #16 // mask off upper half of word

        mov r0, color
        bl SetFaceColor

        teq y, #0
        bne drawRow$ // keep going until we hit y = 0

    b render$

.unreq color
.unreq x
.unreq y
.unreq fbInfoAddr

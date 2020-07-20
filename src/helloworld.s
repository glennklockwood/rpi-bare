.section .init
.globl _start
_start:

bl display

.section .data
.align 4
printmsg:
.incbin "helloworld.bin"

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
mov fbInfoAddr, r0
bl SetGfxAddr

ldr r0, =printmsg
mov r1, #22
mov r2, #0
mov r3, #0

bl DrawString

loop$:
    b loop$

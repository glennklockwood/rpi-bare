.section .init
.globl _start
_start:

bl picasso

.section .text
////////////////////////////////////////////////////////////////////////////////
// Main routine to draw on our screen
////////////////////////////////////////////////////////////////////////////////
.globl picasso
picasso:
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
.unreq fbInfoAddr

// 2. Set four registers to 0. One will be the last random number, one will be
//    the colour, one will be the last x co-ordinate and one will be the last y
//    co-ordinate.
lastRand .req r5
color .req r6
lastx .req r7
lasty .req r8
mov lastRand, #0
mov color, #0
mov lastx, #0
mov lasty, #0

drawLoop$:
    nextx .req r9
    nexty .req r10

    // 3. Generate next x coord, using last random number as input
    mov r0, lastRand
    bl random
    mov nextx, r0 
    // 4. Generate next y coord, using x coordinate as input
    bl random
    mov nexty, r0
    // 5. Update last random number to contain the y-coordinate
    mov lastRand, nexty

    // 6. Set color, then increment the colour. If it goes above 0xFFFF, reset to 0.
    mov r0, color
    bl SetFaceColor
    add color, #1
    lsl color, #16
    lsr color, #16

    // 7. Convert x, y to a number between 0 and 1023 by using a logical shift right of 22
    lsr nextx, #22
    lsr nexty, #22

    // 8. Check the y coordinate is on the screen. Valid y coordinates are between 0 and 767. If not, go back to 3.
    cmp nexty, #768
    bhs drawLoop$

    // 9. Draw line from last x and y to the current x and y
    mov r0, lastx
    mov r1, lasty
    mov r2, nextx
    mov r3, nexty
    bl DrawLine

    // 10. Update last x and y to current ones
    mov lastx, nextx
    mov lasty, nexty
    .unreq nextx
    .unreq nexty

    // 11. Loop
    b drawLoop$

.unreq lastRand
.unreq color
.unreq lastx
.unreq lasty

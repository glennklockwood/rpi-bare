.section .init
.globl _start
_start:

bl printf

.section .text
printf:
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

mov r4, #0 // ascii character to print
loop$:
    ldr r0, =format // r0 = address of format string
    mov r1, #formatEnd-format // r1 = length of 'format'
    ldr r2, =formatEnd // r2 = address of end of format string; where output should be written in memory
    lsr r3, r4, #4 // r3 = r4 / 4 (each character is 4 bytes wide in the ascii map)
    push {r3} // updates sp to be sp - #4
    push {r3} // updates sp to be sp - #4
    push {r3} // updates sp to be sp - #4
    push {r3} // updates sp to be sp - #4

    bl FormatString
    add sp, #16 // pop last four values off top of stack

    // build input arguments to DrawString
    mov r1, r0  // r0 = length of formatted string
    ldr r0, =formatEnd // r0 = formatted string
    mov r2, #0 // r2 = x position to display string = 0
    mov r3, r4 // r3 = y position to display string

    cmp r3, #768-16 // if we're about to print beyond the last row
    subhi r3, #768 // reset back to topmost y position (row 0)
    addhi r2, #256 // and shift x to next column over (2nd col starts at 256th x pixel)

    // if we're still beyond the last row, we'll have to print to third col, so
    cmp r3, #768-16 // if we're about to print beyond the last row
    subhi r3, #768 // reset back to topmost y position (row 0)
    addhi r2, #256 // and shift x to next column over (3rd col starts at 512th x pixel)

    // if we're STILL beyond hte last row, we're in the fourth column, so
    cmp r3, #768-16 // if we're about to print beyond the last row
    subhi r3, #768 // reset back to topmost y position (row 0)
    addhi r2, #256 // and shift x to next column over (4rd col starts at 768th x pixel)

    // draw the string
    bl DrawString

    add r4, #16 // move to the next character
    b loop$

.section .data
format:
.ascii "%d=0b%b=0x%x=0%o='%c'"
formatEnd:

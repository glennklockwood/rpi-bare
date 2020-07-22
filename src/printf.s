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

mov r4, #0
loop$:
ldr r0, =format
mov r1, #formatEnd-format
ldr r2, =formatEnd
lsr r3, r4, #4
push {r3}
push {r3}
push {r3}
push {r3}
bl FormatString
add sp, #16

mov r1, r0
ldr r0, =formatEnd
mov r2, #0
mov r3, r4

cmp r3, #768-16
subhi r3, #768
addhi r2, #256
cmp r3, #768-16
subhi r3, #768
addhi r2, #256
cmp r3, #768-16
subhi r3, #768
addhi r2, #256

bl DrawString

add r4, #16
b loop$

.section .data
format:
.ascii "%d=0b%b=0x%x=0%o='%c'"
formatEnd:

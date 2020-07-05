// Main code to blink patterns on the Raspberry Pi's LED

.section .text
.globl blink
blink:
mov sp, #0x8000 // gives us 0x8000 - 0x100 bytes of memory for our stack

// load data
ptrn .req r4
ledPinNum .req r6
delayTime .req r7
ldr ptrn, =pattern  // pattern is a memory address
ldr ledPinNum, =pin
ldr delayTime, =delay

ldr ptrn, [ptrn]    // now pattern is the contents of the memory address
ldr ledPinNum, [ledPinNum]
ldr delayTime, [delayTime]

// set function of pinNum 47 to function 001 (output)
pinNum .req r0
pinFunc .req r1
mov pinNum, ledPinNum
mov pinFunc, #1
bl SetGpioFunction
.unreq pinNum
.unreq pinFunc

seq .req r5
mov seq, #0

loop$:
    pinNum .req r0
    pinVal .req r1
    mov pinNum, ledPinNum
    mov pinVal, #1      // r1 = 1
    lsl pinVal, seq     // r1 = r1 << seq
    and pinVal, ptrn    // r1 = r1 && ptrn

    bl SetGpio

    add seq, #1
    and seq, #31

    .unreq pinNum
    .unreq pinVal

    waitTime .req r0
    mov waitTime, delayTime
    bl WaitMicroSecs
    .unreq waitTime

b loop$

.unreq ledPinNum
.unreq delayTime
.unreq seq
.unreq ptrn

////////////////////////////////////////////////////////////////////////////////
// Non-executable data
////////////////////////////////////////////////////////////////////////////////
.section .data
.align 2    // align to 2**2 bytes (32-bit boundaries) because ldr only operates on 32-bit boundaries
pattern:
.int 0b10101000011101110111000010101000
pin:
.int 47
delay:
.int 250000

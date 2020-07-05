/* 
 * Blinking the ACT LED on a Raspberry Pi board
 *
 * GPIO controller registers:
 *
 * Number | Address | Name    | Description             | Domain
 * -------|---------|---------|-------------------------|----------------
 * 00     | r0 +  0 | GPFSEL0 | GPIO Function Select 0  | for pins 0-9
 * 01     | r0 +  4 | GPFSEL1 | GPIO Function Select 1  | for pins 10-19
 * 02     | r0 +  8 | GPFSEL2 | GPIO Function Select 2  | for pins 20-29
 * 03     | r0 + 12 | GPFSEL3 | GPIO Function Select 3  | for pins 30-39
 * 04     | r0 + 16 | GPFSEL4 | GPIO Function Select 4  | for pins 40-49
 * 05     | r0 + 20 | GPFSEL5 | GPIO Function Select 5  | for pins 50-54
 * 07     | r0 + 28 | GPSET0  | GPIO Pin Output Set 0   | for pins 0-31
 * 08     | r0 + 32 | GPSET1  | GPIO Pin Output Set 1   | for pins 32-54
 * 10     | r0 + 40 | GPCLR0  | GPIO Pin Output Clear 0 | for pins 0-31
 * 11     | r0 + 44 | GPCLR1  | GPIO Pin Output Clear 1 | for pins 32-54
 *
 */
.section .init
.globl _start
_start:

b main

////////////////////////////////////////////////////////////////////////////////
// Main code
////////////////////////////////////////////////////////////////////////////////
.section .text
main:
mov sp, #0x8000 // gives us 0x8000 - 0x100 bytes of memory for our stack

ledPinNum .req r6
mov ledPinNum, #47

delayTime .req r7
ldr delayTime, =250000

// set function of pinNum 47 to function 001 (output)
pinNum .req r0
pinFunc .req r1
mov pinNum, ledPinNum
mov pinFunc, #1
bl SetGpioFunction
.unreq pinNum
.unreq pinFunc

// load data
ptrn .req r4
ldr ptrn, =pattern  // pattern is a memory address
ldr ptrn, [ptrn]    // now pattern is the contents of the memory address

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
.int 0b11111111101010100010001000101010

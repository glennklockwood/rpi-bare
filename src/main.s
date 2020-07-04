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

.section .text
main:
mov sp, #0x8000 // gives us 0x8000 - 0x100 bytes of memory for our stack

// set function of pinNum 47 to function 001
pinNum .req r0
pinFunc .req r1
mov pinNum, #47
mov pinFunc, #1
bl SetGpioFunction
.unreq pinNum
.unreq pinFunc

// 
pinNum .req r0
pinVal .req r1
mov pinNum, #47
mov pinVal, #1
bl SetGpio
.unreq pinNum
.unreq pinVal

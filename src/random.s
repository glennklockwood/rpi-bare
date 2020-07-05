////////////////////////////////////////////////////////////////////////////////
// Random: generate pseudorandom number sequence
//
// Inputs:
//   r0: last number in sequence
//
// Outputs:
//   r0: next number in sequence
////////////////////////////////////////////////////////////////////////////////
.globl random
random:

a .req r1
c .req r2
xn .req r3

// Uses a = 0xEF00, b = (0xEF00 + 1) % 4, c = 73
//   so a = 0xEF00, b = 1, c = 73
mov a, #0xEF00
mov xn, r0

// and therefore xnn = a*xn*xn + xn + 73
mul a, xn
mul a, xn
add a, xn
.unreq xn

add r0, a, #73 // r0 = a * xn**2 + xn + 73
.unreq a

mov pc, lr

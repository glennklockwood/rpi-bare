// GetTimerAddress
// Inputs:
//   None
//
// Outputs:
//   r0: base address of timer
.globl GetTimerAddress
GetTimerAddress:
ldr r0, =0x20003000
mov pc, lr

// GetTimeStamp
// 
// Inputs:
//   None
// Outputs:
//   r0: least significant 32 bits of the timestamp
//   r1: most sigifnicaint 32 bits of the timestamp
.globl GetTimeStamp
GetTimeStamp:
push {lr}

bl GetTimerAddress

// load the register at r0 + 4 and r0 + 4 + 4 into r0 and r1
// from the datasheet
//   r0 + 4 = system timer counter lower 32 bits
//   r0 + 8 = system timer counter upper 32 bits
ldrd r0, r1, [r0, #4]

pop {pc}

// WaitMicroSecs
//
// Stores timer when entering the function, then loops and compares the
// difference between the current timer and the original timer to see if it is
// larger than the specified duration.  When it is, resume execution.
// Currently only looks at the lower four bytes of the counter register, meaning
// r0 can only go up to 2**32 microseconds (4295 seconds).  If longer timers
// are needed, this needs to compare all 8 bytes of the counter register.
//
// Inputs:
//   r0: number of microseconds to wait before turning
//
// Outputs:
//   None
.globl WaitMicroSecs
WaitMicroSecs:
delay .req r2
mov delay, r0 // store delay in r2, freeing up r0
push {lr}

bl GetTimeStamp // r0 is now the current timestamp (up to 2**32 microseconds)
start .req r3
mov start, r0 // r3 is now the initial timestamp

loop$:
  bl GetTimeStamp
  elapsed .req r1
  sub elapsed, r0, start // elapsed = start - r0
  cmp elapsed, delay     // compare elapsed, delay
  .unreq elapsed
  bls loop$     // if elapsed < delay, goto loop$

.unreq delay
.unreq start

pop {pc}

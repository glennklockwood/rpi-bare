////////////////////////////////////////////////////////////////////////////////
// InitFrameBuffer - Sends a memory address of a questionnaire to the GPU
// requesting the GPU use its contents to configure a framebuffer, then fill out
// a few missing fields (including the address to a frame buffer to which we can
// write).  Leaves a message of 0 in the mailbox on success, or nonzero on
// failure.
// 
// Inputs:
//   r0: width
//   r1: height
//   r2: bit depth
//
// Outputs:
//   r0: address to our filled-out questionnaire or 0 on failure
////////////////////////////////////////////////////////////////////////////////
.globl InitFrameBuffer
InitFrameBuffer:

width .req r0
height .req r1
bitDepth .req r2
cmp width, #4096
cmpls height, #4096 // if width <= 4096
cmpls bitDepth, #32 // if height <= 4096

movhi r0, #0 // if bitDepth > 32, r0 = 0
movhi pc, lr

fbInfoAddr .req r3
push {lr}

// write inputted frame buffer params into FrameBufferQuestionnaire
ldr fbInfoAddr, =FrameBufferQuestionnaire
str width, [fbInfoAddr, #0]
str height, [fbInfoAddr, #4]
str width, [fbInfoAddr, #8]
str height, [fbInfoAddr, #12]
str bitDepth, [fbInfoAddr, #20]
.unreq width
.unreq height
.unreq bitDepth

// Prepare input args for MailboxWrite
mov r0, fbInfoAddr // r0 now equals the address of our questionnaire
add r0, #0x40000000 // magic number to add to the questionnaire address to make GPU not use cache
// re: above magic number, this is equivalent to adding
//      0b01000000 00000000 00000000 00000000
// I don't understand how mangling a pointer encodes a special message to the
// GPU unless addresses never use these highest-order bits.  Maybe since the
// payload can only be 28 bits, the payload is shifted right by 4 bits, leaving
// the uppermost 4 bits empty for special flags?
mov r1, #1 // use channel 1
bl MailboxWrite

// Prepare input args for MailboxRead
mov r0, #1
bl MailboxRead

// if we read zero from the mailbox (message success)
result .req r0
teq result, #0 
movne result, #0 // if MailboxRead returned nonzero, set result to nonzero
popne {pc} // if MailboxRead returned nonzero, break

mov result, fbInfoAddr // return filled-out questionnaire address

pop {pc}
.unreq result
.unreq fbInfoAddr


////////////////////////////////////////////////////////////////////////////////
// Frame buffer
////////////////////////////////////////////////////////////////////////////////
.section .data
.align 4
.globl FrameBufferQuestionnaire
FrameBufferQuestionnaire:
.int 1024   //  #0 in: physical width
.int 768    //  #4 in: physical height
.int 1024   //  #8 in: virtual width
.int 768    // #12 in: virtual height
.int 0      // #16 out: number of bytes on each row of fb (pitch)
.int 16     // #20 in: bit depth
.int 0      // #24 in: x offset to begin drawing (x)
.int 0      // #28 in: y offset to begin drawing (y)
.int 0      // #32 out: pointer to frame buffer
.int 0      // #36 out: size in bytes of frame buffer

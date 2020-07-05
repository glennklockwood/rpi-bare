// Communicate with the GPU on the BMC2835
// 
// Mailbox 0 is used for negotiating the framebuffer

// Address  | Size    | Name          | Description                 | R/W
// ---------|---------|---------------|-----------------------------|----
// 2000B880 | 4 bytes | Read          | Receiving mail              | R
// 2000B890 | 4 bytes | Poll          | Receive without retrieving  | R
// 2000B894 | 4 bytes | Sender        | Sender information          | R
// 2000B898 | 4 bytes | Status        | Information                 | R
// 2000B89C | 4 bytes | Configuration | Settings                    | RW
// 2000B8A0 | 4 bytes | Write         | Sending mail                | W


// GetMailboxBase: gets base address of GPU mailbox registers
.globl GetMailboxBase
GetMailboxBase:
ldr r0, =0x2000B880
mov pc, lr

// MailboxWrite: writes value to a mailbox channel
//
// The mailbox interface accepts writes in a 32-bit buffer of the form
//
//    MSB                             LSB
//    xxxxxxxx xxxxxxxx xxxxxxxx xxxxyyyy
//
// where x encodes a payload value and y encodes the channel number
//
// Inputs:
//   r0: message to write into mailbox
//   r1: mailbox channel to write
//
// Outputs:
//   None
.globl MailboxWrite
MailboxWrite:

// 1. Validate inputs
// lowest 4 bits of value are always 0 (this is where mailbox id goes)
value .req r0
channel .req r1
tst value, #0b1111 // cmp (r0 && 0b1111), 0
movne pc, lr
// mailbox channel <= 15
cmp channel, #15 // (channel must be 1-15)
movhi pc, lr
.unreq value

// Use GetMailboxBase to retrieve the address
value .req r2
mov value, r0
push {lr}
bl GetMailboxBase
mailbox .req r0

// wait until the status register's top bit is 0
wait1$:
  status .req r3
  ldr status, [mailbox, #0x18]
  // test the most significant bit of the status register
  tst status, #0b10000000000000000000000000000000
  .unreq status
  bne wait1$
    
// combine the value to write (28 MSBs) and the channel id (4 LSBs)
add value, channel // value = value + channel
.unreq channel

// Write to the write register (offset by 0x20 from base)
str value, [mailbox, #0x20]
.unreq value
.unreq mailbox

pop {pc}

// MailboxRead: reads one message from mailbox channel
//
// Inputs:
//   r0: mailbox channel to read
//
// Outputs:
//   r0: contents of mailbox channel
//
.globl MailboxRead
MailboxRead:
// validate input 
cmp r0, #15
movhi pc, lr

// retrieve base address
channel .req r1
mov channel, r0
push {lr}
bl GetMailboxBase
mailbox .req r0

// wait for 30th bit of status field to be zero 
rightmail$:
  wait2$:
    status .req r2
    ldr status, [mailbox, #0x18] // mailbox + 0x18 = status register
    tst status, #0b00100000000000000000000000000000
    .unreq status
    bne wait2$

  // read from the Read field and look for the mailbox we want
  mail .req r2
  ldr mail, [mailbox, #0] // mailbox + 0x0 = Read register

  inchan .req r3
  and inchan, mail, #0b1111 // inchan = 1 if lowest four bits of inchan are all 0
  teq inchan, channel // if inchan == channel
  .unreq inchan
  bne rightmail$ // if mailbox has contents for a channel we don't care about, wait

// return the result
and r0, mail, #0b11111111111111111111111111110000 // mask off channel id
.unreq mail

pop {pc}


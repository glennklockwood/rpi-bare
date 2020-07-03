Write code that directly runs on the ARM SoC on Raspberry Pi.  Does not involve
using an operating system.

## Prerequisites

I am using a separate Raspberry Pi as my build environment.  Any Linux host
should do though.

    # apt install gcc-arm-none-eabi

This code is also hard-coded to run on a Raspberry Pi Model B+.

## Acknowledgments and References

This code is inspired by the [Baking Pi OS Development][] online course.
However that course assumes an older model Raspberry Pi which has some GPIOs
wired differently than how they are done in all newer models, so this code has
been updated to reflect that.

Other references:

- [BCM2835 Datasheet](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2835/BCM2835-ARM-Peripherals.pdf)

[Baking Pi OS Development]: https://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/ok01.html

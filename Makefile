.PHONY: blink install

# toolchain prefix to use
ARM_TOOLCHAIN ?= arm-none-eabi

# build directory
BUILD  = build

# source directory
SOURCE = src

# location of SD card to flash
SDCARD = /dev/sda1

TARGET = kernel
LINKER = kernel.ld

ALL_OBJECTS := $(patsubst $(SOURCE)/%.s,$(BUILD)/%.o,$(wildcard $(SOURCE)/*.s))

blink: OBJECTS = build/blink.o  build/gpio.o build/timer.o
blink: $(TARGET).img $(TARGET).list

display: OBJECTS = build/display.o build/framebuffer.o build/mailbox.o build/gpio.o
display: $(TARGET).img $(TARGET).list

# flash the new kernel image on to the SD card
install: $(TARGET).img
	sudo bash -c 'mount $(SDCARD) /mnt && cp -v $(TARGET).img /mnt/ && md5sum $(TARGET).img /mnt/$(TARGET).img && umount /mnt'

# build the kernel image
$(TARGET).img: $(BUILD)/$(TARGET).elf
	$(ARM_TOOLCHAIN)-objcopy $< -O binary $@
	touch $@

# build the listing file
$(TARGET).list: $(BUILD)/$(TARGET).elf
	$(ARM_TOOLCHAIN)-objdump -d $< > $@

# build the elf file
$(BUILD)/$(TARGET).elf: $(ALL_OBJECTS) $(LINKER)
	$(ARM_TOOLCHAIN)-ld --no-undefined $(OBJECTS) -Map $(TARGET).map -o $@ -T $(LINKER)

# compile assembly source
$(BUILD)/%.o: $(SOURCE)/%.s
	test -d "$(BUILD)" || mkdir -p "$(BUILD)"
	$(ARM_TOOLCHAIN)-as -I $(SOURCE)/ $< -o $@

# Rule to clean files.
clean:
	-rm -rf $(BUILD)
	-rm -f $(TARGET).img
	-rm -f $(TARGET).list
	-rm -f $(TARGET).map

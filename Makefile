# take your pick, pretty much any toolchain will do
CROSS_COMPILE = arm-none-eabi-
CROSS_COMPILE = arm-linux-gnueabihf-

CC = ${CROSS_COMPILE}gcc
CXX = ${CROSS_COMPILE}g++
OBJCOPY = ${CROSS_COMPILE}objcopy

target_flags = -mcpu=cortex-a8
ifdef use_fpu
# note that you need to enable it in the cpu before executing any C/C++ code
# compiled with these flags.
target_flags += -mfpu=neon -mfloat-abi=hard
else
target_flags += -mfloat-abi=soft
endif

# common for C/C++
ccflags += -Wall -Wextra -O -g
ccflags += -static -ffreestanding -fbuiltin
ifdef no_thumb
ccflags += -marm
else
ccflags += -mthumb
endif

CFLAGS = ${target_flags} ${ccflags}
CXXFLAGS = ${target_flags} ${ccflags}
ASFLAGS = ${target_flags} ${flags}
ifndef no_thumb
ASFLAGS += -Wa,-mthumb
endif

LDFLAGS = -static -nostartfiles
LDFLAGS += -Wl,--build-id=none


all :: demo.elf demo.bin demo.MLO demo.img

clean ::
	${RM} *.elf *.bin *.MLO *.img *.o

demo.elf: demo.ld *.S *.h
	${LINK.S} -T ${^:%.h=} ${LOADLIBES} ${LDLIBS} ${OUTPUT_OPTION}


%.bin: %.elf
	${OBJCOPY} -O binary $< $@

%.MLO: %.bin
	bin/mk-gpimage 0x402f0400 $< $@

%.img: %.MLO
	cp extra/raw-mmc-header.img $@
	dd if=$< of=$@ iflag=fullblock conv=sync seek=1 status=none
	echo 'label: dos' | sfdisk --quiet $@

.DELETE_ON_ERROR:

TARGET=nomx
HAL=1
CPPSRC=$(wildcard *.cpp)
CSRC=$(wildcard *.c)
CPP=arm-none-eabi-g++
CC=arm-none-eabi-gcc
AS=arm-none-eabi-gcc -x assembler-with-cpp
LD=arm-none-eabi-ld
CP=arm-none-eabi-objcopy
SZ=arm-none-eabi-size
HEX=$(CP) -O ihex
BIN=$(CP) -O binary -S
BUILDDIR=build

# Names: 1st used for system_stm32fxyyy.c file, 2nd for driver directory, 3rd for specific HAL device header file and startup assembly file
CUBEDIR=cube
arch_short=stm32f3xx
ARCH_short=STM32F3xx
arch_specific=stm32f302x8
MCU=-mcpu=cortex-m4 -mthumb
DEFS = -DSTM32F302x8
OPT = -Og
LDSCRIPT = STM32F302R6Tx_FLASH.ld

INCLUDE= -I. -I$(CUBEDIR)/Drivers/CMSIS/Device/ST/$(ARCH_short)/Include -I$(CUBEDIR)/Drivers/CMSIS/Core/Include -I$(CUBEDIR)/Drivers/CMSIS/Include
ifeq ($(HAL),1)
HALDIR=$(CUBEDIR)/Drivers/$(ARCH_short)_HAL_Driver
HALINCLDIR=$(HALDIR)/Inc
HALSRCDIR=$(HALDIR)/Src
INCLUDE += -I$(HALINCLDIR)
HALMODULES = cortex tim tim_ex gpio dac dma rcc 
HALOBJS = $(arch_short)_hal.o $(patsubst %,$(arch_short)_hal_%.o,$(HALMODULES))
endif

ASFLAGS=$(MCU) -Wall -fdata-sections -ffunction-sections
CFLAGS=$(MCU) $(OPT) $(INCLUDE) $(DEFS)
ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif
# I don't bother adding the fine-grained Makefile dependencies
#CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"
CPPFLAGS=$(CFLAGS)

OBJS=$(CPPSRC:.cpp=.obj) $(CSRC:.c=.o) startup_$(arch_specific).o system_$(arch_short).o $(HALOBJS)
BUILDOBJS=$(patsubst %,$(BUILDDIR)/%,$(OBJS))

LIBS=-lc -lm -lnosys
LIBDIR=
LDFLAGS=$(MCU) -specs=nosys.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(TARGET).map,--cref

all: $(TARGET).bin

clean:
	$(RM) -rf *.d *.o *.obj *.map $(TARGET).elf $(TARGET).hex $(TARGET).bin build/*

flash:
	$(FLASH) write $(TARGET).elf 0x8000000

$(TARGET).hex: $(TARGET).elf
	$(HEX) $< $@

$(TARGET).bin: $(TARGET).elf
	$(BIN) $< $@

$(TARGET).elf: $(BUILDOBJS)
	$(CC) $(LDFLAGS) -o $@ $^
	$(SZ) $@

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/%.obj: %.cpp $(BUILDDIR)
	$(CPP) $(CPPFLAGS) -o $@ -c $<

$(BUILDDIR)/%.o: %.c $(BUILDDIR)
	$(CC) $(CFLAGS) -o $@ -c $<

$(BUILDDIR)/%.o: %.s $(BUILDDIR)
	$(AS) $(ASFLAGS) -o $@ -c $<

$(BUILDDIR)/%.o: $(HALSRCDIR)/%.c
	$(CC) $(CFLAGS) -o $@ -c $<

.PHONY: clean all flash



CPPSRC=
CSRC=$(shell ls *.c)
OBJS=$(CSRC:.cpp=.obj) $(CPPSRC:.c=.o) startup_stm32f302x8.o system_stm32f3xx.o
CPP=arm-none-eabi-g++
CC=arm-none-eabi-gcc
AS=arm-none-eabi-gcc -x assembler-with-cpp
LD=arm-none-eabi-ld
CP=arm-none-eabi-objcopy
SZ=arm-none-eabi-size
HEX=$(CP) -O ihex
BIN=$(CP) -O binary -S
CUBE=cube

MCU=-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard

INCLUDE= -I$(CUBE)/Drivers/CMSIS/Device/ST/STM32F3xx/Include -I$(CUBE)/Drivers/CMSIS/Core/Include -I$(CUBE)/Drivers/CMSIS/Include
DEFS = -DSTM32F302x8

ASFLAGS=$(MCU) -c -Wall -fdata-sections -ffunction-sections
CFLAGS=$(MCU) $(INCLUDE) $(DEFS)
CPPFLAGS=$(MCU) $(INCLUDE) $(DEFS)
ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif
CFLAGS += -Og -MMD -MP -MF"$(@:%.o=%.d)"

LDSCRIPT = STM32F302R6Tx_FLASH.ld
LIBS=-lc -lm -lnosys
LIBDIR=
LDFLAGS=$(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=nohal.map,--cref -Wl,--gc-sections

all: nohal.hex

clean:
	$(RM) -rf *.d *.o *.obj *.map nohal.elf nohal.hex

nohal.hex: nohal.elf
	$(HEX) $< $@

nohal.bin: nohal.elf
	$(BIN) $< $@

nohal.elf: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $<
	$(SZ) $@

%.obj: %.cpp
	$(CPP) $(CPPFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ -c $<




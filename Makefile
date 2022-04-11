CC=arm-none-eabi-gcc
CFLAGS=-g
ASFLAGS=-mcpu=cortex-m3 -mthumb
LDFLAGS=-ffreestanding -nostdlib -nostartfiles -Tlink.x

all: firmware

clean:
	rm -f firmware *.o

firmware: interrupt.o rcc.o start.o uart.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.S
	$(CC) $(CFLAGS) $(ASFLAGS) -c -o $@ $<

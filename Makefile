CC=arm-none-eabi-gcc
CFLAGS=-g
ASFLAGS=-mcpu=cortex-m3 -mthumb
LDFLAGS=-ffreestanding -nostdlib -nostartfiles -Tlink.x

all: firmware

clean:
	rm -f firmware *.o

firmware: interrupt.o start.o rcc.o uart.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.s
	$(CC) $(CFLAGS) $(ASFLAGS) -c -o $@ $<
